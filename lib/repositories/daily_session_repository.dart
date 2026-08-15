import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class DailySessionStatus {
  final bool didReading;
  final bool didNewMemorization;
  final bool didReview;
  const DailySessionStatus({this.didReading = false, this.didNewMemorization = false, this.didReview = false});

  factory DailySessionStatus.fromMap(Map<String, Object?> map) => DailySessionStatus(
        didReading: (map['did_reading'] as int? ?? 0) == 1,
        didNewMemorization: (map['did_new_memorization'] as int? ?? 0) == 1,
        didReview: (map['did_review'] as int? ?? 0) == 1,
      );

  bool get allDone => didReading && didNewMemorization && didReview;
}

/// "جلسة اليوم" tracking for the 3 steps that currently have real data
/// behind them — QURAN_COMPANION_ROADMAP.md section 6.
class DailySessionRepository {
  Future<DailySessionStatus> today() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('daily_session_log', where: 'date = ?', whereArgs: [todayDate()], limit: 1);
    if (rows.isEmpty) return const DailySessionStatus();
    return DailySessionStatus.fromMap(rows.first);
  }

  Future<void> markStep({bool? reading, bool? newMemorization, bool? review}) async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();
    final existing = await db.query('daily_session_log', where: 'date = ?', whereArgs: [today], limit: 1);
    final current = existing.isEmpty ? const DailySessionStatus() : DailySessionStatus.fromMap(existing.first);
    await db.insert(
      'daily_session_log',
      {
        'date': today,
        'did_reading': (reading ?? current.didReading) ? 1 : 0,
        'did_new_memorization': (newMemorization ?? current.didNewMemorization) ? 1 : 0,
        'did_review': (review ?? current.didReview) ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
