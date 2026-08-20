import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class QuranReadingSessionStatus {
  final int? targetMinutes;
  final int completedMinutes;
  final bool completed;
  const QuranReadingSessionStatus({this.targetMinutes, this.completedMinutes = 0, this.completed = false});
}

/// Daily Quran-reading minutes target/countdown — backs the "كم دقيقة
/// ستقرأ القرآن اليوم" countdown on `quran_reading_screen.dart` and the
/// day-over-day "gym coach" comparison Ismail asked for (2026-08-17):
/// small, sustainable, but every day.
class QuranReadingSessionRepository {
  Future<QuranReadingSessionStatus> today() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quran_reading_minutes_log', where: 'date = ?', whereArgs: [todayDate()], limit: 1);
    if (rows.isEmpty) return const QuranReadingSessionStatus();
    final row = rows.first;
    return QuranReadingSessionStatus(
      targetMinutes: row['target_minutes'] as int,
      completedMinutes: row['completed_minutes'] as int,
      completed: (row['completed'] as int) == 1,
    );
  }

  Future<void> setTargetMinutes(int minutes) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'quran_reading_minutes_log',
      {'date': todayDate(), 'target_minutes': minutes, 'completed_minutes': 0, 'completed': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> recordCompletion(int minutes) async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();
    final existing = await db.query('quran_reading_minutes_log', where: 'date = ?', whereArgs: [today], limit: 1);
    final target = existing.isEmpty ? minutes : existing.first['target_minutes'] as int;
    await db.insert(
      'quran_reading_minutes_log',
      {'date': today, 'target_minutes': target, 'completed_minutes': minutes, 'completed': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// The most recent PRIOR day with a completed session — skips back past
  /// any gap days rather than only checking literally yesterday, so a
  /// student returning after a day off still gets a real comparison
  /// instead of always landing on "أول مرة".
  /// Total minutes ever logged as completed — powers the companion chat's
  /// honest "how much time have you invested" report (QURAN_COMPANION_ROADMAP.md
  /// §4.36), real data, not estimated.
  Future<int> lifetimeMinutes() async {
    final db = await DatabaseHelper.instance.database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COALESCE(SUM(completed_minutes), 0) FROM quran_reading_minutes_log WHERE completed = 1'),
    );
    return result ?? 0;
  }

  Future<int?> lastCompletedMinutes() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'quran_reading_minutes_log',
      where: 'completed = 1 AND date < ?',
      whereArgs: [todayDate()],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['completed_minutes'] as int;
  }
}
