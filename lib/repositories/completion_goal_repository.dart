import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../l10n/basic_translations.dart';
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

  /// §2.3 grain 3.1 — an optional user-chosen display name. Null for every
  /// goal created before this field existed, and for goals whose creator
  /// left the field at its suggested default without changing it (the
  /// wizard still sends that suggested text through, so a non-null [name]
  /// here always reflects something the user saw and kept/typed) — falls
  /// back to [displayLabel]/[displayLabelFor] when null.
  final String? name;

  /// §2.3 grain 3.1 — an optional explicit index into the fixed 5-colour
  /// tab palette (`kKhatmTabColors`). Null means "not chosen" — the caller
  /// (`_GoalCard`) falls back to the existing cyclic-by-creation-order
  /// colour, unchanged for every goal created before this field existed.
  final int? colorIndex;

  /// §2.3 field 4 grain "partial range" — an optional juz-derived page
  /// range for `quran_reading`/`quran_memorization` goals only. Both null
  /// for every book-type goal and every goal created before this field
  /// existed, meaning "the whole mushaf" (implicitly page 1..totalUnits) —
  /// [CompletionGoalRepository.statusFor] is the only place that needs to
  /// know about these; everywhere else just keeps reading [totalUnits].
  final int? startUnit;
  final int? endUnit;

  CompletionGoal({
    required this.id,
    required this.contentType,
    this.bookRef,
    required this.totalUnits,
    required this.startDate,
    required this.targetDate,
    required this.dailyTarget,
    required this.status,
    this.name,
    this.colorIndex,
    this.startUnit,
    this.endUnit,
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

  /// Same as [displayLabel] but translated for the two Quran plan types
  /// (UI-chrome feature names). Specific book/curriculum titles (Zad
  /// al-Ma'ad, Madarij, al-Wasitiyyah, al-Arbain) stay Arabic — they're
  /// real classical-text titles, not chrome. A user-set [name] wins over
  /// both when present (grain 3.1).
  String displayLabelFor(String lang) {
    final n = name;
    if (n != null && n.trim().isNotEmpty) return n;
    return switch ((contentType, bookRef)) {
      ('quran_reading', _) => basicText('goal_quran_reading_label', lang),
      ('quran_memorization', _) => basicText('goal_quran_memorization_label', lang),
      _ => displayLabel,
    };
  }

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
    String? name,
    int? colorIndex,
    int? startUnit,
    int? endUnit,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final start = todayDate();
    final days = _daysBetween(start, targetDate).clamp(1, 100000);
    // §2.3 field 4 — a set range overrides the passed totalUnits (which the
    // caller, for a ranged goal, computed the same way anyway) so this stays
    // the one place total_units is derived from a range.
    final effectiveTotalUnits = (startUnit != null && endUnit != null) ? (endUnit - startUnit + 1) : totalUnits;
    final dailyTarget = effectiveTotalUnits / days;
    final id = await db.insert('completion_goals', {
      'content_type': contentType,
      'book_ref': bookRef,
      'total_units': effectiveTotalUnits,
      'start_date': start,
      'target_date': targetDate,
      'daily_target': dailyTarget,
      'status': 'active',
      'name': name,
      'color_index': colorIndex,
      'start_unit': startUnit,
      'end_unit': endUnit,
    });
    return CompletionGoal(
      id: id,
      contentType: contentType,
      bookRef: bookRef,
      totalUnits: effectiveTotalUnits,
      startDate: start,
      targetDate: targetDate,
      dailyTarget: dailyTarget,
      status: 'active',
      name: name,
      colorIndex: colorIndex,
      startUnit: startUnit,
      endUnit: endUnit,
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
    final rawPosition = await _currentPosition(goal);
    // §2.3 field 4 — `_currentPosition` is always an absolute mushaf page
    // (matches how the reader/`quran_reading_progress` already think, and
    // how a future "أتممت الورد" write would naturally read the reader's
    // current page). For a ranged goal that page is normalized here, once,
    // to "progress within this goal's own total_units" — the only
    // conversion point, so `CompletionGoalStatus.currentPosition` keeps
    // meaning exactly what every other reader of it (the card's "X من Y",
    // its %, the notification KPI) already assumes.
    final position = goal.startUnit != null
        ? (rawPosition - goal.startUnit! + 1).clamp(0, goal.totalUnits)
        : rawPosition;
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

  /// KHATM_SYSTEM_AND_STYLE_REFERENCE.md §2 (Ismail, 2026-09-16) — this used
  /// to read live from whichever *global* tracker matched the goal's
  /// content_type (`quran_reading_progress`, `memorization_progress`, a
  /// book's own progress table...). Those tables aren't owned by this
  /// feature — `quran_reading_progress` alone backs the mushaf reader's own
  /// "continue reading" position across 10 other files, plus
  /// `WirdRepository`'s independent "read today" check — so two
  /// simultaneous completion goals for the same content_type always showed
  /// identical progress (both reading the one shared value), and this
  /// method writing to those tables would have silently affected those
  /// unrelated features too. A completion goal now owns its progress in
  /// `completion_goal_progress`, keyed by its own id, entirely separate
  /// from every global tracker — see `recordProgress` for the write side.
  /// No row yet (a goal created before this migration's one-time backfill,
  /// edge case aside) simply reads as 0, same as "just started".
  Future<int> _currentPosition(CompletionGoal goal) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('completion_goal_progress', where: 'goal_id = ?', whereArgs: [goal.id], limit: 1);
    return rows.isEmpty ? 0 : (rows.first['last_position'] as int? ?? 0);
  }

  /// "أتممت الورد" — the one write path for a completion goal's own
  /// progress. Writes *only* to `completion_goal_progress` for this
  /// `goalId` — deliberately never touches `quran_reading_progress`,
  /// `memorization_progress`, or any other global tracker, so marking a
  /// goal's daily portion done here never moves the mushaf reader's
  /// "continue reading" bookmark (or any other unrelated feature), and
  /// reading a page in the mushaf never advances a goal's own progress
  /// either — the two concepts stay fully independent until a future
  /// explicit decision links them. Upserts, so calling it again for the
  /// same goal just corrects/advances the position rather than erroring.
  Future<void> recordProgress(int goalId, int position) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'completion_goal_progress',
      {'goal_id': goalId, 'last_position': position, 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
        name: row['name'] as String?,
        colorIndex: row['color_index'] as int?,
        startUnit: row['start_unit'] as int?,
        endUnit: row['end_unit'] as int?,
      );

  int _daysBetween(String hijriFrom, String hijriTo) {
    final from = gregorianFromHijriDateTime(hijriFrom, null);
    final to = gregorianFromHijriDateTime(hijriTo, null);
    return to.difference(from).inDays;
  }
}
