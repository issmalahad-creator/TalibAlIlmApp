import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

/// The 6 areas "رسالتي" assesses — deliberately limited to pillars that
/// already have a real, navigable screen (see [areaScreenTargets] in
/// `mission_screen.dart`), not a theoretical/aspirational list.
const placementAreas = ['quran', 'hadith', 'aqeedah', 'arabic', 'tajweed', 'adhkar'];

const placementAreaLabels = {
  'quran': 'القرآن',
  'hadith': 'الحديث',
  'aqeedah': 'العقيدة',
  'arabic': 'العربية',
  'tajweed': 'التجويد',
  'adhkar': 'الأذكار',
};

class AreaRating {
  final String area;
  final int rating; // 1-5, self-reported, never AI-judged
  final bool interest;
  AreaRating({required this.area, required this.rating, required this.interest});
}

class StudentMission {
  final int? dailyMinutes;
  final String? oneYearGoal;
  StudentMission({this.dailyMinutes, this.oneYearGoal});
}

/// "رسالتي" (إيكيغاي طالب العلم) — Ismail's 2026-08-17 request, an
/// expansion of the already-approved "اختبار تحديد المستوى" (Batch 2 of
/// the "الدماغ الذي يربط" plan) to also capture interest and a one-year
/// mission, not just a bare skill rating. Purely self-reported data, no
/// AI judgment — same discipline as `salah_self_assessment`.
class PlacementRepository {
  Future<bool> hasCompleted() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('placement_ratings', limit: 1);
    return rows.isNotEmpty;
  }

  Future<List<AreaRating>> allRatings() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('placement_ratings');
    return rows
        .map((r) => AreaRating(
              area: r['area'] as String,
              rating: r['rating'] as int,
              interest: (r['interest'] as int) == 1,
            ))
        .toList();
  }

  Future<StudentMission> mission() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('student_mission', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return StudentMission();
    return StudentMission(
      dailyMinutes: rows.first['daily_minutes'] as int?,
      oneYearGoal: rows.first['one_year_goal'] as String?,
    );
  }

  Future<void> saveAssessment({
    required Map<String, int> ratings,
    required Set<String> interests,
    required int dailyMinutes,
    String? oneYearGoal,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final date = todayDate();
    final batch = db.batch();
    for (final area in placementAreas) {
      final rating = ratings[area];
      if (rating == null) continue;
      batch.insert(
        'placement_ratings',
        {'area': area, 'rating': rating, 'interest': interests.contains(area) ? 1 : 0, 'assessed_date': date},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    batch.insert(
      'student_mission',
      {'id': 1, 'daily_minutes': dailyMinutes, 'one_year_goal': oneYearGoal, 'assessed_date': date},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await batch.commit(noResult: true);
  }

  Future<void> reset() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('placement_ratings');
    await db.delete('student_mission');
  }

  /// Deterministic, no AI: a simple average-of-ratings threshold, offered
  /// to the student as a suggestion only — never written silently.
  String suggestedLevel(List<AreaRating> ratings) {
    if (ratings.isEmpty) return 'beginner';
    final avg = ratings.map((r) => r.rating).reduce((a, b) => a + b) / ratings.length;
    if (avg <= 2) return 'beginner';
    if (avg <= 3.5) return 'intermediate';
    return 'advanced';
  }
}
