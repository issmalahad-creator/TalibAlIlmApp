import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';

class JourneyPlan {
  final String startDate; // hijri
  final double targetYears;
  final String level; // 'beginner' | 'intermediate' | 'advanced'
  final double dailyNewPages; // full computed pace, post-trial-week
  final bool trialWeekActive;
  final String? personalCommitmentText;
  JourneyPlan({
    required this.startDate,
    required this.targetYears,
    required this.level,
    required this.dailyNewPages,
    required this.trialWeekActive,
    this.personalCommitmentText,
  });
}

class JourneyStatus {
  final JourneyPlan plan;
  final int dayNumber; // "اليوم 143"
  final bool onTrialWeek;
  final double currentDailyPace; // half of dailyNewPages during the trial week
  final int masteredPages;
  final int totalPages;
  final double masteryPercent;
  JourneyStatus({
    required this.plan,
    required this.dayNumber,
    required this.onTrialWeek,
    required this.currentDailyPace,
    required this.masteredPages,
    required this.totalPages,
    required this.masteryPercent,
  });
}

/// "رحلتي" — QURAN_COMPANION_ROADMAP.md §4.7. A SMART-wizard-computed pace
/// (target years + current level -> a daily-pages target), softened by a
/// lighter "trial first week" before the full computed pace applies
/// (pattern borrowed from real goal-setting apps, see the roadmap section
/// for the research). `personal_commitment_text` is purely a self-written
/// reminder the student sets for themselves — the app only ever displays
/// it back to them, never enforces or acts on it (§1's "no punishment from
/// the app itself" principle).
class JourneyPlanRepository {
  static const _trialWeekDays = 7;
  static const _totalPages = 604;

  Future<JourneyPlan?> get() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('journey_plan', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return _toPlan(rows.first);
  }

  Future<JourneyPlan> create({
    required double targetYears,
    required String level,
    String? personalCommitmentText,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final start = todayDate();
    final totalDays = (targetYears * 365).clamp(30, 365 * 60);
    final dailyNewPages = _totalPages / totalDays;

    await db.insert(
      'journey_plan',
      {
        'id': 1,
        'start_date': start,
        'target_years': targetYears,
        'level': level,
        'daily_new_pages': dailyNewPages,
        'trial_week_active': 1,
        'personal_commitment_text': personalCommitmentText,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return JourneyPlan(
      startDate: start,
      targetYears: targetYears,
      level: level,
      dailyNewPages: dailyNewPages,
      trialWeekActive: true,
      personalCommitmentText: personalCommitmentText,
    );
  }

  Future<void> updateCommitment(String? text) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('journey_plan', {'personal_commitment_text': text}, where: 'id = 1');
  }

  Future<JourneyStatus?> status() async {
    final plan = await get();
    if (plan == null) return null;
    final db = await DatabaseHelper.instance.database;

    final dayNumber = _daysBetween(plan.startDate, todayDate()) + 1;
    final onTrialWeek = dayNumber <= _trialWeekDays;
    final currentPace = onTrialWeek ? plan.dailyNewPages / 2 : plan.dailyNewPages;

    final mastered = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM memorization_progress WHERE status = 'established'"),
        ) ??
        0;

    return JourneyStatus(
      plan: plan,
      dayNumber: dayNumber,
      onTrialWeek: onTrialWeek,
      currentDailyPace: currentPace,
      masteredPages: mastered,
      totalPages: _totalPages,
      masteryPercent: mastered / _totalPages * 100,
    );
  }

  JourneyPlan _toPlan(Map<String, Object?> row) => JourneyPlan(
        startDate: row['start_date'] as String,
        targetYears: row['target_years'] as double,
        level: row['level'] as String,
        dailyNewPages: row['daily_new_pages'] as double,
        trialWeekActive: (row['trial_week_active'] as int) == 1,
        personalCommitmentText: row['personal_commitment_text'] as String?,
      );

  int _daysBetween(String hijriFrom, String hijriTo) {
    final from = gregorianFromHijriDateTime(hijriFrom, null);
    final to = gregorianFromHijriDateTime(hijriTo, null);
    return to.difference(from).inDays;
  }
}
