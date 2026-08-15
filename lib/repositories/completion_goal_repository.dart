import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';

class CompletionGoal {
  final int id;
  final String contentType; // 'quran_reading' | 'quran_memorization' | 'book'
  final String? bookRef; // null for Quran, else 'zad_almaad' | 'madarij' | 'wasitiyyah' | 'nawawi_hadith'
  final int totalUnits;
  final String startDate;
  final String targetDate;
  final double dailyTarget;
  final String status;
  CompletionGoal({
    required this.id,
    required this.contentType,
    this.bookRef,
    required this.totalUnits,
    required this.startDate,
    required this.targetDate,
    required this.dailyTarget,
    required this.status,
  });

  /// For 'personal_book' goals, `bookRef` is the personal_books.id — the
  /// title itself isn't stored here (it can change/be deleted), so callers
  /// needing a friendly personal-book label should look it up themselves;
  /// this getter covers every *other* content type directly.
  String get displayLabel => switch ((contentType, bookRef)) {
        ('quran_reading', _) => 'ختمة قراءة القرآن',
        ('quran_memorization', _) => 'ختم حفظ القرآن',
        (_, 'zad_almaad') => 'زاد المعاد',
        (_, 'madarij') => 'مدارج السالكين',
        (_, 'wasitiyyah') => 'العقيدة الواسطية',
        (_, 'nawawi_hadith') => 'الأربعين النووية',
        ('personal_book', _) => 'كتاب من مكتبتي',
        _ => bookRef ?? contentType,
      };

  /// The unit this goal's daily target is counted in — used to render the
  /// "15 صفحة اليوم"-style KPI on both the goal card and its reminder
  /// notification (section 4.15's per-page/per-unit KPI requirement).
  String get unitLabel => switch ((contentType, bookRef)) {
        ('quran_reading', _) => 'صفحة',
        ('personal_book', _) => 'صفحة',
        ('quran_memorization', _) => 'صفحة',
        (_, 'zad_almaad') => 'فصلًا',
        (_, 'madarij') => 'قسمًا',
        (_, 'wasitiyyah') => 'فقرة',
        (_, 'nawawi_hadith') => 'حديثًا',
        _ => 'وحدة',
      };
}

enum ScheduleStatus { ahead, onTrack, behind }

class CompletionGoalStatus {
  final CompletionGoal goal;
  final int currentPosition;
  final int remaining;
  final int daysLeft;
  final double recalculatedDailyTarget;
  final ScheduleStatus scheduleStatus;
  CompletionGoalStatus({
    required this.goal,
    required this.currentPosition,
    required this.remaining,
    required this.daysLeft,
    required this.recalculatedDailyTarget,
    required this.scheduleStatus,
  });
}

/// "خطة الختم" — QURAN_COMPANION_ROADMAP.md section 4.15. One generalized
/// planner for Quran reading, Quran memorization, or any book. Position is
/// never stored redundantly here — always read live from the real progress
/// table for that content, so it can never drift out of sync.
class CompletionGoalRepository {
  Future<CompletionGoal> create({
    required String contentType,
    String? bookRef,
    required int totalUnits,
    required String targetDate,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final start = todayDate();
    final days = _daysBetween(start, targetDate).clamp(1, 100000);
    final dailyTarget = totalUnits / days;
    final id = await db.insert('completion_goals', {
      'content_type': contentType,
      'book_ref': bookRef,
      'total_units': totalUnits,
      'start_date': start,
      'target_date': targetDate,
      'daily_target': dailyTarget,
      'status': 'active',
    });
    return CompletionGoal(
      id: id,
      contentType: contentType,
      bookRef: bookRef,
      totalUnits: totalUnits,
      startDate: start,
      targetDate: targetDate,
      dailyTarget: dailyTarget,
      status: 'active',
    );
  }

  Future<List<CompletionGoal>> activeGoals() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('completion_goals', where: "status = 'active'");
    return rows.map(_toGoal).toList();
  }

  Future<void> abandon(int goalId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('completion_goals', {'status': 'abandoned'}, where: 'id = ?', whereArgs: [goalId]);
  }

  /// Re-anchors the plan from today at the same total_units, keeping the
  /// same target_date if still in the future, or extending it — used by
  /// the "أعِد جدولة الخطة" option. No punishment framing: this just makes
  /// today the new start point.
  Future<void> reschedule(int goalId, String newTargetDate) async {
    final db = await DatabaseHelper.instance.database;
    final goal = (await db.query('completion_goals', where: 'id = ?', whereArgs: [goalId], limit: 1)).first;
    final position = await _currentPosition(CompletionGoal(
      id: goalId,
      contentType: goal['content_type'] as String,
      bookRef: goal['book_ref'] as String?,
      totalUnits: goal['total_units'] as int,
      startDate: goal['start_date'] as String,
      targetDate: goal['target_date'] as String,
      dailyTarget: goal['daily_target'] as double,
      status: goal['status'] as String,
    ));
    final remaining = (goal['total_units'] as int) - position;
    final today = todayDate();
    final days = _daysBetween(today, newTargetDate).clamp(1, 100000);
    await db.update(
      'completion_goals',
      {'start_date': today, 'target_date': newTargetDate, 'daily_target': remaining / days},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<CompletionGoalStatus> statusFor(CompletionGoal goal) async {
    final position = await _currentPosition(goal);
    final remaining = (goal.totalUnits - position).clamp(0, goal.totalUnits);
    final daysLeft = _daysBetween(todayDate(), goal.targetDate);
    final recalculated = daysLeft > 0 ? remaining / daysLeft : remaining.toDouble();

    ScheduleStatus schedule;
    if (remaining == 0) {
      schedule = ScheduleStatus.onTrack;
    } else if (recalculated > goal.dailyTarget * 1.15) {
      schedule = ScheduleStatus.behind;
    } else if (recalculated < goal.dailyTarget * 0.85) {
      schedule = ScheduleStatus.ahead;
    } else {
      schedule = ScheduleStatus.onTrack;
    }

    return CompletionGoalStatus(
      goal: goal,
      currentPosition: position,
      remaining: remaining,
      daysLeft: daysLeft,
      recalculatedDailyTarget: recalculated,
      scheduleStatus: schedule,
    );
  }

  /// Whether the student has touched this goal's content today — powers
  /// the daily reminder notification (section 4.15's "لم تقرأ اليوم"):
  /// only fires/stays scheduled if this is false.
  Future<bool> hasProgressedToday(CompletionGoal goal) async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();
    switch (goal.contentType) {
      case 'quran_reading':
        final rows = await db.query('quran_reading_progress', where: 'id = 1', limit: 1);
        return rows.isNotEmpty && rows.first['last_read_date'] == today;
      case 'quran_memorization':
        final count = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM memorization_progress WHERE memorized_date = ? OR last_review_date = ?",
          [today, today],
        ));
        return (count ?? 0) > 0;
      case 'personal_book':
        final rows = await db.query('book_bookmarks', where: 'book_key = ?', whereArgs: ['personal_${goal.bookRef}'], limit: 1);
        return rows.isNotEmpty && rows.first['last_updated_date'] == today;
      case 'book':
        final table = switch (goal.bookRef) {
          'zad_almaad' => ('zad_almaad_progress', 'read_date'),
          'madarij' => ('madarij_progress', 'read_date'),
          'wasitiyyah' => ('wasitiyyah_progress', 'memorized_date'),
          'nawawi_hadith' => ('hadith_progress', 'memorized_date'),
          _ => null,
        };
        if (table == null) return false;
        final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ${table.$1} WHERE ${table.$2} = ?', [today]));
        return (count ?? 0) > 0;
      default:
        return false;
    }
  }

  Future<int> _currentPosition(CompletionGoal goal) async {
    final db = await DatabaseHelper.instance.database;
    switch (goal.contentType) {
      case 'quran_reading':
        final rows = await db.query('quran_reading_progress', where: 'id = 1', limit: 1);
        return rows.isEmpty ? 0 : (rows.first['last_page'] as int? ?? 0);
      case 'quran_memorization':
        return Sqflite.firstIntValue(
              await db.rawQuery("SELECT COUNT(*) FROM memorization_progress WHERE status != 'not_started'"),
            ) ??
            0;
      case 'personal_book':
        // Reuses the existing book_bookmarks tracking already maintained by
        // BookViewerScreen (flutter_pdfview's own page callbacks) — no new
        // position-tracking needed for this content type at all.
        final rows = await db.query('book_bookmarks', where: 'book_key = ?', whereArgs: ['personal_${goal.bookRef}'], limit: 1);
        return rows.isEmpty ? 0 : (rows.first['last_page'] as int? ?? 0);
      case 'book':
        final table = switch (goal.bookRef) {
          'zad_almaad' => ('zad_almaad_progress', 'read_done'),
          'madarij' => ('madarij_progress', 'read_done'),
          'wasitiyyah' => ('wasitiyyah_progress', 'memorized'),
          'nawawi_hadith' => ('hadith_progress', 'memorized'),
          _ => null,
        };
        if (table == null) return 0;
        return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ${table.$1} WHERE ${table.$2} = 1')) ?? 0;
      default:
        return 0;
    }
  }

  CompletionGoal _toGoal(Map<String, Object?> row) => CompletionGoal(
        id: row['id'] as int,
        contentType: row['content_type'] as String,
        bookRef: row['book_ref'] as String?,
        totalUnits: row['total_units'] as int,
        startDate: row['start_date'] as String,
        targetDate: row['target_date'] as String,
        dailyTarget: row['daily_target'] as double,
        status: row['status'] as String,
      );

  int _daysBetween(String hijriFrom, String hijriTo) {
    final from = gregorianFromHijriDateTime(hijriFrom, null);
    final to = gregorianFromHijriDateTime(hijriTo, null);
    return to.difference(from).inDays;
  }
}
