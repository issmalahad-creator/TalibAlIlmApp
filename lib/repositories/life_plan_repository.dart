import 'package:sqflite/sqflite.dart';

import '../data/life_plan_seed.dart';
import '../db/database_helper.dart';
import '../models/life_plan.dart';

/// «مُحرّك الحياة» — L1 (`docs/LIFE_ENGINE.md`). The continuous daily engine
/// over `life_pillars` / `life_slots` / `life_day_slots` (migration v55).
///
/// Nothing here is bounded to 90 days: the day number is `date − startDate`,
/// progress is rolling windows, and the streak tolerates a miss. Local
/// sqflite is the source of truth for ticks (offline‑first); the Sheet /
/// Supabase bridges (L6/L7) layer on top without changing this contract.
class LifePlanRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String today() => ymd(DateTime.now());

  static DateTime parseYmd(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  // ── seed / meta ──────────────────────────────────────────────────────

  Future<void> ensureSeeded() async {
    final db = await _db;
    final n = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM life_pillars'));
    if ((n ?? 0) > 0) return;
    await db.transaction((txn) async {
      final b = txn.batch();
      for (final p in kLifePillars) {
        b.insert('life_pillars', p.toRow());
      }
      for (final s in kLifeSlots) {
        b.insert('life_slots', s.toRow());
      }
      b.insert('life_meta', {'k': 'start_date', 'v': today()});
      b.insert('life_meta', {'k': 'cycle_len', 'v': '90'});
      b.insert('life_meta', {'k': 'streak_threshold', 'v': '0.6'});
      b.insert('life_meta', {'k': 'grace_per_week', 'v': '1'});
      await b.commit(noResult: true);
    });
  }

  Future<String?> meta(String key) async {
    final db = await _db;
    final r = await db.query('life_meta',
        columns: ['v'], where: 'k = ?', whereArgs: [key], limit: 1);
    return r.isEmpty ? null : r.first['v'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    final db = await _db;
    await db.insert('life_meta', {'k': key, 'v': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DateTime> startDate() async {
    final s = await meta('start_date');
    if (s == null) {
      await ensureSeeded();
      return parseYmd((await meta('start_date')) ?? today());
    }
    return parseYmd(s);
  }

  Future<int> dayIndex([DateTime? on]) async {
    final start = await startDate();
    final d = on ?? DateTime.now();
    return DateTime(d.year, d.month, d.day)
        .difference(DateTime(start.year, start.month, start.day))
        .inDays;
  }

  // ── structure ────────────────────────────────────────────────────────

  Future<List<LifePillar>> pillars() async {
    await ensureSeeded();
    final db = await _db;
    final rows = await db.query('life_pillars', orderBy: 'sort ASC, key ASC');
    return rows.map(LifePillar.fromRow).toList();
  }

  Future<List<LifeSlot>> slots() async {
    await ensureSeeded();
    final db = await _db;
    final rows = await db.query('life_slots', orderBy: 'sort ASC, start_min ASC');
    return rows.map(LifeSlot.fromRow).toList();
  }

  /// The slot whose window contains `now` (local), or null (before/after the
  /// day, or in a gap).
  Future<LifeSlot?> currentSlot([DateTime? now]) async {
    final t = now ?? DateTime.now();
    final m = t.hour * 60 + t.minute;
    for (final s in await slots()) {
      if (s.containsMinute(m)) return s;
    }
    return null;
  }

  // ── ticks ────────────────────────────────────────────────────────────

  Future<Set<int>> doneSlots(String date) async {
    final db = await _db;
    final rows = await db.query('life_day_slots',
        columns: ['slot_no'],
        where: 'date = ? AND done = 1',
        whereArgs: [date]);
    return {for (final r in rows) (r['slot_no'] as num).toInt()};
  }

  Future<void> setSlotDone(String date, int slotNo, bool done) async {
    final db = await _db;
    await db.insert(
      'life_day_slots',
      {
        'date': date,
        'slot_no': slotNo,
        'done': done ? 1 : 0,
        'done_at': done ? DateTime.now().millisecondsSinceEpoch : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> toggleSlot(String date, int slotNo) async {
    final cur = await doneSlots(date);
    final next = !cur.contains(slotNo);
    await setSlotDone(date, slotNo, next);
    return next;
  }

  // ── progress ─────────────────────────────────────────────────────────

  Future<LifeDayProgress> progress(String date) async {
    final all = await slots();
    final done = await doneSlots(date);
    final byPillar = <String, ({int done, int total})>{};
    for (final s in all) {
      if (!s.isTracked) continue;
      final k = s.pillarKey!;
      final cur = byPillar[k] ?? (done: 0, total: 0);
      byPillar[k] = (
        done: cur.done + (done.contains(s.slotNo) ? 1 : 0),
        total: cur.total + 1,
      );
    }
    return LifeDayProgress(
      date: date,
      dayIndex: await dayIndex(parseYmd(date)),
      doneCount: all.where((s) => done.contains(s.slotNo)).length,
      totalCount: all.length,
      doneSlotNos: done,
      byPillar: {
        for (final e in byPillar.entries)
          e.key: e.value.total == 0 ? 0.0 : e.value.done / e.value.total,
      },
    );
  }

  /// Whole‑day percent for every date in `[from, to]` (inclusive), in ONE
  /// query — for the heatmap. Dates with no ticks are 0. Keys are `ymd`.
  Future<Map<String, double>> dayPercents(String from, String to) async {
    final total = (await slots()).length;
    if (total == 0) return {};
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT date, COUNT(*) AS c FROM life_day_slots '
      'WHERE done = 1 AND date BETWEEN ? AND ? GROUP BY date',
      [from, to],
    );
    final out = <String, double>{};
    for (final r in rows) {
      out[r['date'] as String] = ((r['c'] as num).toInt()) / total;
    }
    return out;
  }

  /// Per‑pillar momentum now (last 7 days) vs the previous 7 — L3 forecast.
  /// `{key: (now, prev, slipping)}` where `slipping` marks a real drop.
  Future<Map<String, ({double now, double prev, bool slipping})>>
      pillarMomentumTrend() async {
    final ps = await pillars();
    final today = DateTime.now();
    Future<Map<String, double>> windowAvg(int offset) async {
      final acc = {for (final p in ps) p.key: 0.0};
      for (var i = 0; i < 7; i++) {
        final byP = (await progress(
                ymd(today.subtract(Duration(days: offset + i)))))
            .byPillar;
        for (final p in ps) {
          acc[p.key] = acc[p.key]! + (byP[p.key] ?? 0.0);
        }
      }
      return {for (final p in ps) p.key: acc[p.key]! / 7};
    }

    final now = await windowAvg(0);
    final prev = await windowAvg(7);
    return {
      for (final p in ps)
        p.key: (
          now: now[p.key]!,
          prev: prev[p.key]!,
          slipping: now[p.key]! < prev[p.key]! * 0.6 ||
              (prev[p.key]! >= 0.3 && now[p.key]! < 0.3),
        ),
    };
  }

  /// Average whole‑day percent over the last [days] days ending today.
  Future<double> rollingAverage(int days) async {
    final now = DateTime.now();
    var sum = 0.0;
    for (var i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      sum += (await progress(ymd(d))).percent;
    }
    return days == 0 ? 0 : sum / days;
  }

  /// Consecutive days (ending today, or yesterday if today is still empty)
  /// at or above `streak_threshold`. A sub‑threshold day costs one "grace";
  /// more than `grace_per_week` graces inside any trailing 7‑day window
  /// breaks the streak.
  Future<int> streak() async {
    final threshold =
        double.tryParse(await meta('streak_threshold') ?? '') ?? 0.6;
    final gracePerWeek =
        int.tryParse(await meta('grace_per_week') ?? '') ?? 1;
    final now = DateTime.now();
    final startIdx =
        (await progress(ymd(now))).doneCount > 0 ? 0 : 1; // skip an empty today
    var count = 0;
    final graceDates = <int>[];
    for (var i = startIdx; i < 400; i++) {
      final d = now.subtract(Duration(days: i));
      final pct = (await progress(ymd(d))).percent;
      if (pct >= threshold) {
        count++;
        continue;
      }
      // a miss — spend a grace if this week still has one
      graceDates.removeWhere((g) => g > i + 6);
      if (graceDates.length < gracePerWeek) {
        graceDates.add(i);
        count++;
        continue;
      }
      break;
    }
    return count;
  }

  /// Per‑pillar momentum over the last 7 days — recent days weighted more
  /// (7,6,…,1). 0..1. Lets L3 forecast "this pillar is slipping".
  Future<Map<String, double>> pillarMomentum() async {
    final ps = await pillars();
    final now = DateTime.now();
    final acc = {for (final p in ps) p.key: 0.0};
    final wsum = {for (final p in ps) p.key: 0.0};
    for (var i = 0; i < 7; i++) {
      final w = (7 - i).toDouble();
      final byP = (await progress(ymd(now.subtract(Duration(days: i))))).byPillar;
      for (final p in ps) {
        acc[p.key] = acc[p.key]! + w * (byP[p.key] ?? 0.0);
        wsum[p.key] = wsum[p.key]! + w;
      }
    }
    return {
      for (final p in ps)
        p.key: wsum[p.key] == 0 ? 0.0 : acc[p.key]! / wsum[p.key]!,
    };
  }

  // ── reflection ───────────────────────────────────────────────────────

  Future<LifeDayNote?> note(String date) async {
    final db = await _db;
    final r = await db.query('life_day_notes',
        where: 'date = ?', whereArgs: [date], limit: 1);
    return r.isEmpty ? null : LifeDayNote.fromRow(r.first);
  }

  Future<void> saveNote(String date,
      {String? note, String? tomorrowGoal, int? mood}) async {
    final db = await _db;
    final prev = await this.note(date);
    await db.insert(
      'life_day_notes',
      {
        'date': date,
        'note': note ?? prev?.note ?? '',
        'tomorrow_goal': tomorrowGoal ?? prev?.tomorrowGoal ?? '',
        'mood': mood ?? prev?.mood,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
