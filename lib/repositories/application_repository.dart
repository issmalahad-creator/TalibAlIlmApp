import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class PracticalLesson {
  final int id;
  final int surah;
  final String lessonText;
  final String valueTag;
  PracticalLesson({required this.id, required this.surah, required this.lessonText, required this.valueTag});
}

/// "مطبّق" — Phase 3 of QURAN_COMPANION_ROADMAP.md section 4.8. Purely
/// self-reported ("طبّقتها اليوم") — never verified or graded, same
/// principle as every other pillar in this app.
class ApplicationRepository {
  /// Lessons for surahs the student has actually started memorizing (any
  /// station) — never surfaces a lesson for content they haven't touched.
  Future<List<PracticalLesson>> availableLessons() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT l.id, l.surah, l.lesson_text, l.value_tag
      FROM practical_lessons l
      WHERE EXISTS (
        SELECT 1 FROM memorization_units u
        JOIN memorization_progress p ON p.unit_id = u.id
        WHERE l.surah BETWEEN u.surah_start AND u.surah_end AND p.status != 'not_started'
      )
      ORDER BY l.surah
    ''');
    return rows
        .map((r) => PracticalLesson(id: r['id'] as int, surah: r['surah'] as int, lessonText: r['lesson_text'] as String, valueTag: r['value_tag'] as String))
        .toList();
  }

  Future<void> logApplication(int lessonId, {String? reflection}) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('application_log', {
      'lesson_id': lessonId,
      'applied_date': todayDate(),
      'user_reflection': reflection,
    });
  }

  Future<bool> hasAppliedToday() async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM application_log WHERE applied_date = ?', [todayDate()]),
    );
    return (count ?? 0) > 0;
  }

  /// Most-focused value tags this month — powers the "سجل تطبيقي" stats.
  Future<Map<String, int>> valueFocusThisMonth() async {
    final db = await DatabaseHelper.instance.database;
    final month = todayDate().substring(0, 7); // Hijri YYYY-MM prefix.
    final rows = await db.rawQuery('''
      SELECT l.value_tag, COUNT(*) AS cnt FROM application_log a
      JOIN practical_lessons l ON l.id = a.lesson_id
      WHERE a.applied_date LIKE ?
      GROUP BY l.value_tag ORDER BY cnt DESC
    ''', ['$month%']);
    return {for (final r in rows) r['value_tag'] as String: r['cnt'] as int};
  }
}
