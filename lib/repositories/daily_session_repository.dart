import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class DailySessionStatus {
  final bool didReading;
  final bool didNewMemorization;
  final bool didReview;
  final bool didUnderstanding;
  final bool didApplication;
  final bool didQuiz;
  const DailySessionStatus({
    this.didReading = false,
    this.didNewMemorization = false,
    this.didReview = false,
    this.didUnderstanding = false,
    this.didApplication = false,
    this.didQuiz = false,
  });

  factory DailySessionStatus.fromMap(Map<String, Object?> map) => DailySessionStatus(
        didReading: (map['did_reading'] as int? ?? 0) == 1,
        didNewMemorization: (map['did_new_memorization'] as int? ?? 0) == 1,
        didReview: (map['did_review'] as int? ?? 0) == 1,
        didUnderstanding: (map['did_understanding'] as int? ?? 0) == 1,
        didApplication: (map['did_application'] as int? ?? 0) == 1,
        didQuiz: (map['did_quiz'] as int? ?? 0) == 1,
      );

  bool get allDone => didReading && didNewMemorization && didReview && didUnderstanding && didApplication && didQuiz;
}

/// "جلسة اليوم" tracking — all 6 designed steps (قراءة/حفظ جديد/مراجعة/
/// فهم/تطبيق/اختبار) have real data behind them as of Phase 3's
/// completion. QURAN_COMPANION_ROADMAP.md section 6.
class DailySessionRepository {
  Future<DailySessionStatus> today() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('daily_session_log', where: 'date = ?', whereArgs: [todayDate()], limit: 1);
    if (rows.isEmpty) return const DailySessionStatus();
    return DailySessionStatus.fromMap(rows.first);
  }

  /// End-of-session self-reflection from the guided session flow (Phase 14
  /// Sub-phase B) — purely descriptive, never auto-changes anything by
  /// itself. `رحلتي` reads the recent trend via [recentDifficulties] to
  /// *suggest* revisiting the pace, same non-punitive "offer, don't force"
  /// principle as the rest of this app.
  Future<void> recordSessionReflection(int minutesPlanned, String difficulty, String? note) async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();
    final existing = await db.query('daily_session_log', where: 'date = ?', whereArgs: [today], limit: 1);
    final current = existing.isEmpty ? const DailySessionStatus() : DailySessionStatus.fromMap(existing.first);
    await db.insert(
      'daily_session_log',
      {
        'date': today,
        'did_reading': current.didReading ? 1 : 0,
        'did_new_memorization': current.didNewMemorization ? 1 : 0,
        'did_review': current.didReview ? 1 : 0,
        'did_understanding': current.didUnderstanding ? 1 : 0,
        'did_application': current.didApplication ? 1 : 0,
        'did_quiz': current.didQuiz ? 1 : 0,
        'session_minutes_planned': minutesPlanned,
        'session_difficulty': difficulty,
        'session_note': note,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// The last [limit] recorded difficulty ratings, most recent first —
  /// used to build a gentle re-planning suggestion (never a silent
  /// automatic change) on the رحلتي dashboard.
  Future<List<String>> recentDifficulties({int limit = 5}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'daily_session_log',
      where: 'session_difficulty IS NOT NULL',
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map((r) => r['session_difficulty'] as String).toList();
  }

  Future<void> markStep({
    bool? reading,
    bool? newMemorization,
    bool? review,
    bool? understanding,
    bool? application,
    bool? quiz,
  }) async {
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
        'did_understanding': (understanding ?? current.didUnderstanding) ? 1 : 0,
        'did_application': (application ?? current.didApplication) ? 1 : 0,
        'did_quiz': (quiz ?? current.didQuiz) ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
