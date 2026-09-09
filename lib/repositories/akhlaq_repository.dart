import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/akhlaq.dart';
import '../services/akhlaq/akhlaq_content.dart';
import '../services/akhlaq/akhlaq_engine.dart';

/// AKHLAQ — the store for a virtue slice.
///
/// Content is read from `AkhlaqContent` (a bundled asset). Only the
/// student's own training data is in SQLite (v61: `akhlaq_attempt`,
/// `akhlaq_sr_state`, `akhlaq_progress`, `akhlaq_meta`). All scoring is
/// done by the pure functions in `akhlaq_engine.dart`.
class AkhlaqRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  static String ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<AkhlaqSlice?> slice() => AkhlaqContent.instance.load();

  // ── SR seed ─────────────────────────────────────────────────────────

  /// Make sure every subskill of the slice has an SR row (due today), so
  /// the first `todayPlan` isn't empty. Idempotent.
  Future<void> ensureSrSeed({DateTime? now}) async {
    final s = await slice();
    if (s == null) return;
    final db = await _db;
    final existing = {
      for (final r in await db.query('akhlaq_sr_state', columns: ['subskill']))
        r['subskill'] as String,
    };
    final today = ymd(now ?? DateTime.now());
    final b = db.batch();
    for (final sk in s.subskills) {
      if (existing.contains(sk.slug)) continue;
      b.insert('akhlaq_sr_state', {
        'subskill': sk.slug,
        'track': 'S',
        'interval_days': 1,
        'ease': 2.3,
        'difficulty': 1,
        'due_date': today,
        'last_quality': 0,
      });
    }
    await b.commit(noResult: true);
  }

  // ── attempts ────────────────────────────────────────────────────────

  Future<List<AkhlaqAttempt>> attempts({String? subskill}) async {
    final db = await _db;
    final rows = await db.query(
      'akhlaq_attempt',
      where: subskill == null ? null : 'subskill = ?',
      whereArgs: subskill == null ? null : [subskill],
      orderBy: 'answered_at DESC',
    );
    return rows.map(_attemptFromRow).toList();
  }

  AkhlaqAttempt _attemptFromRow(Map<String, Object?> r) => AkhlaqAttempt(
        id: (r['id'] as num).toInt(),
        subskill: r['subskill'] as String,
        scenarioId: r['scenario_id'] as String,
        chosenKey: r['chosen_ord'] as String,
        verdict: r['verdict'] as String,
        quality: (r['quality'] as num).toInt(),
        difficulty: (r['difficulty'] as num).toInt(),
        dimScore: {
          for (final e in ((jsonDecode((r['dim_score'] ?? '{}') as String))
                  as Map)
              .entries)
            e.key.toString(): (e.value as num).toInt(),
        },
        answeredAt: (r['answered_at'] as num).toInt(),
      );

  /// Record an answered scenario, advance SR for each of its subskills, and
  /// recompute the training indicator. Returns the score for the feedback
  /// layer. `now` overridable for tests.
  Future<DimScore> recordAttempt({
    required AkhlaqScenario scenario,
    required String chosenKey,
    DateTime? now,
  }) async {
    final opt = scenario.optionByKey(chosenKey);
    if (opt == null) {
      throw ArgumentError('scenario ${scenario.id} has no option $chosenKey');
    }
    final score = evaluateOption(opt);
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final db = await _db;

    for (final sub in scenario.subskills) {
      await db.insert('akhlaq_attempt', {
        'subskill': sub,
        'scenario_id': scenario.id,
        'chosen_ord': chosenKey,
        'verdict': score.verdict,
        'quality': score.quality,
        'difficulty': scenario.difficulty,
        'dim_score': jsonEncode(score.dims),
        'answered_at': at,
      });

      // advance SR
      final prev = await _srFor(db, sub);
      final recent = await attempts(subskill: sub);
      final stable = recent.length >= 4 &&
          recent.take(4).every((a) => a.verdict != 'baid');
      final next = scheduleNext(prev, score.quality,
          today: now ?? DateTime.now(), stableRun: stable);
      await db.insert(
        'akhlaq_sr_state',
        {
          'subskill': next.subskill,
          'track': next.track,
          'interval_days': next.intervalDays,
          'ease': next.ease,
          'difficulty': next.difficulty,
          'due_date': next.dueDate,
          'last_quality': next.lastQuality,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // recompute indicator
      final prog =
          rollSubskillTrend(subskill: sub, attempts: recent);
      await db.insert(
        'akhlaq_progress',
        {
          'subskill': sub,
          'trend': prog.trend,
          'attempts': prog.attempts,
          'band': prog.band,
          'weak_dimension': prog.weakDimension,
          'updated_at': at,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return score;
  }

  // ── SR state ────────────────────────────────────────────────────────

  Future<AkhlaqSrState> _srFor(DatabaseExecutor db, String subskill) async {
    final r = await db.query('akhlaq_sr_state',
        where: 'subskill = ?', whereArgs: [subskill], limit: 1);
    if (r.isEmpty) return AkhlaqSrState(subskill: subskill);
    final row = r.first;
    return AkhlaqSrState(
      subskill: subskill,
      track: row['track'] as String,
      intervalDays: (row['interval_days'] as num).toInt(),
      ease: (row['ease'] as num).toDouble(),
      difficulty: (row['difficulty'] as num).toInt(),
      dueDate: row['due_date'] as String,
      lastQuality: (row['last_quality'] as num).toInt(),
    );
  }

  Future<List<AkhlaqSrState>> srStates() async {
    final db = await _db;
    final rows = await db.query('akhlaq_sr_state', orderBy: 'due_date ASC');
    return [for (final r in rows) await _srFor(db, r['subskill'] as String)];
  }

  // ── progress (training indicator, not a verdict) ────────────────────

  Future<List<AkhlaqProgress>> progressAll() async {
    final db = await _db;
    final rows = await db.query('akhlaq_progress');
    return [
      for (final r in rows)
        AkhlaqProgress(
          subskill: r['subskill'] as String,
          trend: (r['trend'] as num).toDouble(),
          attempts: (r['attempts'] as num).toInt(),
          band: r['band'] as String,
          weakDimension: r['weak_dimension'] as String?,
        ),
    ];
  }

  // ── focus of the week ──────────────────────────────────────────────

  Future<String?> focusSubskill() async {
    final db = await _db;
    final r = await db.query('akhlaq_meta',
        where: "k = 'focus'", limit: 1);
    return r.isEmpty ? null : r.first['v'] as String?;
  }

  Future<void> setFocusSubskill(String? subskill) async {
    final db = await _db;
    if (subskill == null) {
      await db.delete('akhlaq_meta', where: "k = 'focus'");
      return;
    }
    await db.insert('akhlaq_meta', {'k': 'focus', 'v': subskill},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── today's plan ──────────────────────────────────────────────────

  Future<List<TrainingItem>> todayPlan({DateTime? now}) async {
    final s = await slice();
    if (s == null) return const [];
    await ensureSrSeed(now: now);
    return todayPlanFor(
      states: await srStates(),
      attempts: await attempts(),
      slice: s,
      today: now ?? DateTime.now(),
      focusSubskill: await focusSubskill(),
    );
  }
}

/// Thin re-export so callers don't import the engine directly.
List<TrainingItem> todayPlanFor({
  required List<AkhlaqSrState> states,
  required List<AkhlaqAttempt> attempts,
  required AkhlaqSlice slice,
  required DateTime today,
  String? focusSubskill,
}) =>
    todayPlan(
      states: states,
      attempts: attempts,
      slice: slice,
      today: today,
      focusSubskill: focusSubskill,
    );
