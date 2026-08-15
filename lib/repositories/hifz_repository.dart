import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

/// Deliberately minimal — Ismail asked for something simple that just helps
/// a self-studying memorizer stay consistent, not a full Hifz-academy
/// system with plans/spaced-repetition/teacher dashboards. Two tables:
/// which Surahs are marked memorized, and which days the student "checked
/// in" (used for the streak).
class HifzRepository {
  Future<Set<int>> memorizedSurahNumbers() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('hifz_surah_status', where: 'memorized = 1');
    return rows.map((r) => r['surah_number'] as int).toSet();
  }

  Future<void> setMemorized(int surahNumber, bool memorized, String todayHijri) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'hifz_surah_status',
      {'surah_number': surahNumber, 'memorized': memorized ? 1 : 0, 'memorized_date': memorized ? todayHijri : null},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> checkIn(String todayHijri) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('hifz_daily_log', {'date': todayHijri}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> hasCheckedInToday(String todayHijri) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('hifz_daily_log', where: 'date = ?', whereArgs: [todayHijri]);
    return rows.isNotEmpty;
  }

  /// All checked-in dates (Hijri `YYYY-MM-DD` strings), newest first — used
  /// to compute the current streak (consecutive-day logic lives in the
  /// screen since it needs the Hijri calendar helpers).
  Future<List<String>> allCheckInDates() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('hifz_daily_log', orderBy: 'date DESC');
    return rows.map((r) => r['date'] as String).toList();
  }
}
