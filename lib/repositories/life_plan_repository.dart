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

  Future<List<LifePillar>> pillars({bool includeArchived = false}) async {
    await ensureSeeded();
    final db = await _db;
    final rows = await db.query('life_pillars',
        where: includeArchived ? null : 'archived = 0',
        orderBy: 'sort ASC, key ASC');
    return rows.map(LifePillar.fromRow).toList();
  }

  Future<List<LifeSlot>> slots({bool includeArchived = false}) async {
    await ensureSeeded();
    final db = await _db;
    final rows = await db.query('life_slots',
        where: includeArchived ? null : 'archived = 0',
        orderBy: 'sort ASC, start_min ASC');
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

  // ── authoring (L6-DYN #1) ────────────────────────────────────────────
  //
  // The plan is the user's to shape, not a frozen copy of the sheet. All
  // writes are local + immediate. Deletes are **soft** (`archived = 1`) so
  // past progress and old ticks stay meaningful; a hard delete is offered
  // only for a custom row that was never ticked.

  static const _pillarCols = {
    'key', 'label', 'emoji', 'target_text', 'cadence', 'weekly_target',
    'sort', 'color', 'archived'
  };
  static const _slotCols = {
    'slot_no', 'start_min', 'end_min', 'activity', 'mihwar', 'pillar_key',
    'sort', 'archived'
  };

  Future<void> upsertPillar(LifePillar p) async {
    final db = await _db;
    final row = {
      for (final e in p.toRow().entries)
        if (_pillarCols.contains(e.key)) e.key: e.value,
    };
    await db.insert('life_pillars', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// A fresh key for a user-made pillar: `custom_1`, `custom_2`, … (never
  /// collides with a seed key or an archived one).
  Future<String> newPillarKey() async {
    final db = await _db;
    final rows = await db.query('life_pillars', columns: ['key']);
    final used = {for (final r in rows) r['key'] as String};
    var n = 1;
    while (used.contains('custom_$n')) {
      n++;
    }
    return 'custom_$n';
  }

  Future<void> setPillarArchived(String key, bool archived) async {
    final db = await _db;
    await db.update('life_pillars', {'archived': archived ? 1 : 0},
        where: 'key = ?', whereArgs: [key]);
    if (archived) {
      // a retired pillar must not keep pointing slots at itself
      await db.update('life_slots', {'pillar_key': null},
          where: 'pillar_key = ?', whereArgs: [key]);
    }
  }

  /// True only for a user-made pillar with no slot pointing at it and no
  /// historical tick under any such slot — safe to remove outright.
  Future<bool> canHardDeletePillar(String key) async {
    if (!key.startsWith('custom_')) return false;
    final db = await _db;
    final slotUse = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM life_slots WHERE pillar_key = ?', [key]));
    return (slotUse ?? 0) == 0;
  }

  Future<void> hardDeletePillar(String key) async {
    if (!await canHardDeletePillar(key)) {
      await setPillarArchived(key, true);
      return;
    }
    final db = await _db;
    await db.delete('life_pillars', where: 'key = ?', whereArgs: [key]);
  }

  /// Persist a new `sort` for each key, in the given order (0-based).
  Future<void> reorderPillars(List<String> keysInOrder) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (var i = 0; i < keysInOrder.length; i++) {
        await txn.update('life_pillars', {'sort': i},
            where: 'key = ?', whereArgs: [keysInOrder[i]]);
      }
    });
  }

  /// Insert or update a slot. `slotNo <= 0` means "new" — a stable id is
  /// allocated as `max(slot_no) + 1` (archived rows included, so an id is
  /// never reused and old ticks can't be reattached).
  Future<int> upsertSlot(LifeSlot s) async {
    final db = await _db;
    var no = s.slotNo;
    if (no <= 0) {
      no = (Sqflite.firstIntValue(await db.rawQuery(
                  'SELECT MAX(slot_no) FROM life_slots')) ??
              0) +
          1;
    }
    final row = {
      for (final e in s.copyWith().toRow().entries)
        if (_slotCols.contains(e.key)) e.key: e.value,
    }..['slot_no'] = no;
    await db.insert('life_slots', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return no;
  }

  Future<void> setSlotArchived(int slotNo, bool archived) async {
    final db = await _db;
    await db.update('life_slots', {'archived': archived ? 1 : 0},
        where: 'slot_no = ?', whereArgs: [slotNo]);
  }

  Future<bool> canHardDeleteSlot(int slotNo) async {
    final db = await _db;
    final ticks = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM life_day_slots WHERE slot_no = ?', [slotNo]));
    return (ticks ?? 0) == 0;
  }

  Future<void> hardDeleteSlot(int slotNo) async {
    if (!await canHardDeleteSlot(slotNo)) {
      await setSlotArchived(slotNo, true);
      return;
    }
    final db = await _db;
    await db.delete('life_slots', where: 'slot_no = ?', whereArgs: [slotNo]);
  }

  Future<void> reorderSlots(List<int> slotNosInOrder) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (var i = 0; i < slotNosInOrder.length; i++) {
        await txn.update('life_slots', {'sort': i},
            where: 'slot_no = ?', whereArgs: [slotNosInOrder[i]]);
      }
    });
  }

  /// Wipe the structure and re-seed Ismail's original 7 pillars + 23 slots.
  /// Ticks are **kept** (they key on `date`+`slot_no`); any that no longer
  /// match a live slot simply stop counting. Notes/meta untouched.
  Future<void> resetStructureToSeed() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('life_pillars');
      await txn.delete('life_slots');
      final b = txn.batch();
      for (final p in kLifePillars) {
        b.insert('life_pillars', p.toRow());
      }
      for (final s in kLifeSlots) {
        b.insert('life_slots', s.toRow());
      }
      await b.commit(noResult: true);
    });
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

  // ── weekly review ────────────────────────────────────────────────────

  /// «ملخص الأسبوع» (L5) — the last 7 days (ending today) composed into one
  /// struct so the review screen does no arithmetic. Pillar standings are
  /// always "last 7 days vs the 7 before", relative to today.
  Future<LifeWeekSummary> weeklyReview() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threshold =
        double.tryParse(await meta('streak_threshold') ?? '') ?? 0.6;

    // one query covers both the shown week and the prior week (for the delta)
    final pcts = await dayPercents(
        ymd(today.subtract(const Duration(days: 13))), ymd(today));

    final days = <({DateTime date, double pct})>[];
    var hit = 0;
    for (var i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final p = pcts[ymd(d)] ?? 0.0;
      days.add((date: d, pct: p));
      if (p >= threshold) hit++;
    }
    final thisAvg = days.fold<double>(0, (s, e) => s + e.pct) / 7;
    var prevSum = 0.0;
    for (var i = 13; i >= 7; i--) {
      prevSum += pcts[ymd(today.subtract(Duration(days: i)))] ?? 0.0;
    }

    final ps = await pillars();
    final trend = await pillarMomentumTrend();
    final pillarWeeks = [
      for (final p in ps)
        LifePillarWeek(
          key: p.key,
          label: p.label,
          emoji: p.emoji,
          now: trend[p.key]?.now ?? 0.0,
          prev: trend[p.key]?.prev ?? 0.0,
          slipping: trend[p.key]?.slipping ?? false,
        ),
    ]..sort((a, b) => b.now.compareTo(a.now));

    final db = await _db;
    final noteRows = await db.query('life_day_notes',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [ymd(today.subtract(const Duration(days: 6))), ymd(today)],
        orderBy: 'date DESC');
    final notes = noteRows
        .map(LifeDayNote.fromRow)
        .where((n) => n.note.isNotEmpty || n.tomorrowGoal.isNotEmpty)
        .toList();

    return LifeWeekSummary(
      fromDate: ymd(today.subtract(const Duration(days: 6))),
      toDate: ymd(today),
      days: days,
      avgPercent: thisAvg,
      prevAvgPercent: prevSum / 7,
      daysHitThreshold: hit,
      streak: await streak(),
      pillars: pillarWeeks,
      notes: notes,
    );
  }

  // ── cycle rollover ritual ────────────────────────────────────────────

  Future<int> cycleLen() async =>
      int.tryParse(await meta('cycle_len') ?? '') ?? 90;

  /// The oldest *completed* cycle that still hasn't had its rollover
  /// ritual, or null. Cycle N completes the moment `dayIndex` hits N·len;
  /// cycles are acknowledged in order via [markCycleReviewed]. A cycle is
  /// a milestone, never an end — the ritual is reflect + evolve + carry on.
  Future<int?> pendingCycleReview() async {
    final len = await cycleLen();
    if (len <= 0) return null;
    final completed = (await dayIndex()) ~/ len;
    if (completed < 1) return null;
    final lastReviewed =
        int.tryParse(await meta('last_cycle_reviewed') ?? '') ?? 0;
    return completed > lastReviewed ? lastReviewed + 1 : null;
  }

  Future<void> markCycleReviewed(int cycle) async {
    final lastReviewed =
        int.tryParse(await meta('last_cycle_reviewed') ?? '') ?? 0;
    if (cycle > lastReviewed) {
      await setMeta('last_cycle_reviewed', '$cycle');
    }
  }

  Future<String?> cycleNote(int cycle) => meta('cycle_note_$cycle');

  Future<void> saveCycleNote(int cycle, String note) =>
      setMeta('cycle_note_$cycle', note);

  /// Roll-up of one completed cycle [n] (1-based) — its date range, average
  /// day %, total blocks ticked, and per-pillar done counts.
  Future<LifeCycleSummary> cycleSummary(int n) async {
    final len = await cycleLen();
    final start = await startDate();
    final cStart = DateTime(start.year, start.month, start.day)
        .add(Duration(days: (n - 1) * len));
    final cEnd = cStart.add(Duration(days: len - 1));
    final fromYmd = ymd(cStart);
    final toYmd = ymd(cEnd);

    final pcts = await dayPercents(fromYmd, toYmd);
    var sum = 0.0;
    for (var i = 0; i < len; i++) {
      sum += pcts[ymd(cStart.add(Duration(days: i)))] ?? 0.0;
    }

    final db = await _db;
    final blocksDone = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM life_day_slots '
          'WHERE done = 1 AND date BETWEEN ? AND ?',
          [fromYmd, toYmd],
        )) ??
        0;
    final byPillarRows = await db.rawQuery(
      'SELECT s.pillar_key AS k, COUNT(*) AS c '
      'FROM life_day_slots d JOIN life_slots s ON s.slot_no = d.slot_no '
      'WHERE d.done = 1 AND d.date BETWEEN ? AND ? AND s.pillar_key IS NOT NULL '
      'GROUP BY s.pillar_key ORDER BY c DESC',
      [fromYmd, toYmd],
    );

    return LifeCycleSummary(
      cycle: n,
      fromDate: fromYmd,
      toDate: toYmd,
      lengthDays: len,
      avgPercent: len == 0 ? 0 : sum / len,
      blocksDone: blocksDone,
      byPillarDone: {
        for (final r in byPillarRows)
          r['k'] as String: (r['c'] as num).toInt(),
      },
    );
  }
}
