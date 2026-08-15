import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';
import 'completion_goal_repository.dart';
import 'memorization_repository.dart';

class JourneyPlan {
  final String level; // 'beginner' | 'intermediate' | 'advanced'
  final String? personalCommitmentText;
  JourneyPlan({required this.level, this.personalCommitmentText});
}

class JourneyStatus {
  final JourneyPlan plan;
  final CompletionGoal goal;
  final CompletionGoalStatus goalStatus;
  final int dayNumber; // "اليوم 143"
  final int masteredPages;
  final int totalPages;
  final double masteryPercent;
  final MemorizationUnit? nextRecommendedUnit;
  JourneyStatus({
    required this.plan,
    required this.goal,
    required this.goalStatus,
    required this.dayNumber,
    required this.masteredPages,
    required this.totalPages,
    required this.masteryPercent,
    required this.nextRecommendedUnit,
  });
}

/// "رحلتي" — QURAN_COMPANION_ROADMAP.md §4.7, rebuilt 2026-08-16 to close a
/// real gap Ismail flagged: the pace used to be a number computed once at
/// setup and frozen forever. It now rides entirely on
/// `CompletionGoalRepository` (§4.15's already-adaptive planner, live
/// ahead/on-track/behind + reschedule) via a `completion_goals` row with
/// `content_type: 'quran_memorization'` — that engine already existed and
/// already supported this content type, it just had no UI pointed at it.
/// `journey_plan` (the DB table) now only stores the level and the
/// personal-commitment text; the pace itself lives entirely in the goal.
class JourneyPlanRepository {
  static const _totalPages = 604;
  final _goalRepo = CompletionGoalRepository();
  final _memoRepo = MemorizationRepository();

  Future<CompletionGoal?> _activeGoal() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'completion_goals',
      where: "content_type = 'quran_memorization' AND status = 'active'",
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return CompletionGoal(
      id: r['id'] as int,
      contentType: r['content_type'] as String,
      bookRef: r['book_ref'] as String?,
      totalUnits: r['total_units'] as int,
      startDate: r['start_date'] as String,
      targetDate: r['target_date'] as String,
      dailyTarget: r['daily_target'] as double,
      status: r['status'] as String,
    );
  }

  Future<JourneyPlan?> get() async {
    final goal = await _activeGoal();
    if (goal == null) return null;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('journey_plan', where: 'id = 1', limit: 1);
    return JourneyPlan(
      level: rows.isEmpty ? 'beginner' : (rows.first['level'] as String? ?? 'beginner'),
      personalCommitmentText: rows.isEmpty ? null : rows.first['personal_commitment_text'] as String?,
    );
  }

  Future<JourneyPlan> create({
    required double targetYears,
    required String level,
    String? personalCommitmentText,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final start = todayDate();
    final totalDays = (targetYears * 365).clamp(30, 365 * 60).round();
    final targetDate = _addDays(start, totalDays);

    final existing = await _activeGoal();
    if (existing != null) await _goalRepo.abandon(existing.id);
    await _goalRepo.create(contentType: 'quran_memorization', totalUnits: _totalPages, targetDate: targetDate);
    await db.insert(
      'journey_plan',
      {'id': 1, 'level': level, 'personal_commitment_text': personalCommitmentText},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return JourneyPlan(level: level, personalCommitmentText: personalCommitmentText);
  }

  Future<void> updateCommitment(String? text) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('journey_plan', {'personal_commitment_text': text}, where: 'id = 1');
  }

  /// "أكمل بالوتيرة الحالية" — keeps today's daily target, pushes the
  /// target date out to whatever it actually takes at that pace. No
  /// judgment language; this is just re-anchoring from today.
  Future<void> extendAtCurrentPace(CompletionGoal goal, int remaining) async {
    final daysNeeded = (remaining / goal.dailyTarget).ceil().clamp(1, 365 * 60);
    final newTarget = _addDays(todayDate(), daysNeeded);
    await _goalRepo.reschedule(goal.id, newTarget);
  }

  /// The other reschedule option, "كثّف للوصول للهدف الأصلي", needs no
  /// method at all: the intensified pace IS
  /// `CompletionGoalStatus.recalculatedDailyTarget` below, already computed
  /// live against the existing target date — the UI just shows that number.
  Future<JourneyStatus?> status() async {
    final plan = await get();
    final goal = await _activeGoal();
    if (plan == null || goal == null) return null;

    final goalStatus = await _goalRepo.statusFor(goal);
    final dayNumber = _daysBetween(goal.startDate, todayDate()) + 1;

    final db = await DatabaseHelper.instance.database;
    final mastered = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM memorization_progress WHERE status = 'established'"),
        ) ??
        0;
    final nextUnit = await _memoRepo.nextRecommendedUnit();

    return JourneyStatus(
      plan: plan,
      goal: goal,
      goalStatus: goalStatus,
      dayNumber: dayNumber,
      masteredPages: mastered,
      totalPages: _totalPages,
      masteryPercent: mastered / _totalPages * 100,
      nextRecommendedUnit: nextUnit,
    );
  }

  int _daysBetween(String hijriFrom, String hijriTo) {
    final from = gregorianFromHijriDateTime(hijriFrom, null);
    final to = gregorianFromHijriDateTime(hijriTo, null);
    return to.difference(from).inDays;
  }

  String _addDays(String hijriDate, int days) {
    final dt = gregorianFromHijriDateTime(hijriDate, null).add(Duration(days: days));
    return hijriDateStringForDate(dt);
  }
}
