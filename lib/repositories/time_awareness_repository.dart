import 'package:hijri/hijri_calendar.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';

/// One day's structured time entry. Purely self-reported, like every other
/// subjective input in this app — the student types what they honestly did,
/// the app only does the arithmetic on top of that, never infers or
/// measures anything on its own.
class DailyTimeEntry {
  final double? hoursSlept;
  final double? hoursWasted;
  final double? hoursStudied;
  final double? hoursWorked;
  final String? note;
  const DailyTimeEntry({this.hoursSlept, this.hoursWasted, this.hoursStudied, this.hoursWorked, this.note});

  /// A full night's rest is neither benefit nor loss (Ismail's explicit
  /// instruction: "اجعل النوم ... لم يضيع ولم يستفد"). Sleep *beyond* this
  /// is counted toward wasted time — also his explicit instruction ("حتى
  /// كثرة النوم يعتبر ضياع"). 8 hours is a reasonable, commonly-cited full
  /// night's rest, not a medical claim — documented as a heuristic like
  /// every other round-number design choice in this app (session-phase
  /// ratios, etc.), adjustable later if Ismail wants a different cap.
  static const sleepCapHours = 8.0;

  double get _slept => (hoursSlept ?? 0).clamp(0, 24);
  double get _wasted => (hoursWasted ?? 0).clamp(0, 24);
  double get _studied => (hoursStudied ?? 0).clamp(0, 24);
  double get _worked => (hoursWorked ?? 0).clamp(0, 24);

  bool get hasAnyEntry => hoursSlept != null || hoursWasted != null || hoursStudied != null || hoursWorked != null;

  /// Study and work are the two categories Ismail explicitly named as
  /// time "قدّمه لآخرته" (put forward for the Hereafter) — halal work
  /// providing for oneself/family is legitimately rewarded effort in
  /// Islam, not secular-only time, so it counts here alongside study.
  double get benefitedHours => (_studied + _worked).clamp(0, 24);

  double get excessSleepHours => (_slept - sleepCapHours).clamp(0, 24);

  double get accountedHours => (_slept + _wasted + _studied + _worked).clamp(0, 24);

  /// Ismail's explicit closing principle: "الباقي ضائع" — hours not
  /// entered under any category are counted as lost time too, same as
  /// explicitly-logged waste. Nothing is credited as benefit by default.
  double get unaccountedHours => (24 - accountedHours).clamp(0, 24);

  double get wastedHours => (_wasted + excessSleepHours + unaccountedHours).clamp(0, 24);
}

/// Sum of benefited/wasted hours across every logged day in a period.
class TimePeriodTotals {
  final double benefitedHours;
  final double wastedHours;
  const TimePeriodTotals(this.benefitedHours, this.wastedHours);
}

/// "محاسبة الوقت" — purely self-reported, like every other subjective
/// self-rating in this app. No inference, no automatic tracking of how
/// hours were "actually" spent — only what the student honestly enters.
class TimeAwarenessRepository {
  /// Hours in the current Hijri year — the Hijri calendar this app is
  /// built around throughout (see `hijri_date.dart`), not the Gregorian
  /// year, so this stays consistent with how every other date in the app
  /// is stored/reasoned about. A Hijri year is 354 or 355 days depending
  /// on the year; 354 is used as the standard round figure quoted in
  /// Islamic time-awareness contexts.
  static const hijriYearDays = 354;
  static const hoursPerYear = hijriYearDays * 24;

  Future<DailyTimeEntry> todayEntry() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('time_awareness_log', where: 'log_date = ?', whereArgs: [todayDate()], limit: 1);
    if (rows.isEmpty) return const DailyTimeEntry();
    return _entryFromRow(rows.first);
  }

  DailyTimeEntry _entryFromRow(Map<String, Object?> row) => DailyTimeEntry(
        hoursSlept: row['hours_slept'] as double?,
        hoursWasted: row['hours_wasted'] as double?,
        hoursStudied: row['hours_studied'] as double?,
        hoursWorked: row['hours_worked'] as double?,
        note: row['note'] as String?,
      );

  Future<void> saveToday(DailyTimeEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'time_awareness_log',
      {
        'log_date': todayDate(),
        'hours_slept': entry.hoursSlept,
        'hours_wasted': entry.hoursWasted,
        'hours_studied': entry.hoursStudied,
        'hours_worked': entry.hoursWorked,
        // Derived, kept in sync so the pre-existing recent-days trend view
        // (which reads this column) keeps working without changes.
        'hours_well_spent': entry.hasAnyEntry ? entry.benefitedHours : null,
        'note': entry.note,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// The last [limit] days' entries, most recent first — for a light
  /// trend view, purely descriptive.
  Future<List<(String date, double? hours)>> recentEntries({int limit = 7}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'time_awareness_log',
      where: 'hours_well_spent IS NOT NULL',
      orderBy: 'log_date DESC',
      limit: limit,
    );
    return rows.map((r) => (r['log_date'] as String, r['hours_well_spent'] as double?)).toList();
  }

  /// Days elapsed so far in the current Hijri year — for "لقد مضى منها
  /// X ساعة". Approximate (uses the `hijri` package's own month/day
  /// fields, no leap-month precision needed for an awareness stat).
  int daysElapsedThisHijriYear() {
    final today = hijriDateStringForDate(DateTime.now());
    final parts = today.split('-');
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    // Approximate: alternating 30/29-day months, standard for this kind
    // of round-figure awareness stat (not a fiqh/prayer-time calculation).
    final daysPerMonthApprox = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];
    var elapsed = day;
    for (var m = 1; m < month; m++) {
      elapsed += daysPerMonthApprox[m - 1];
    }
    return elapsed;
  }

  /// The Hijri date string for the Saturday starting the current week —
  /// same convention as `SalahRepository.currentWeekStart()`.
  String _currentWeekStartDate() {
    final now = DateTime.now();
    final daysSinceSaturday = now.weekday % 7; // DateTime.saturday == 6, Sunday == 7%7=0
    return hijriDateStringForDate(now.subtract(Duration(days: daysSinceSaturday)));
  }

  String _currentMonthStartDate() {
    final h = HijriCalendar.now();
    return '${h.hYear.toString().padLeft(4, '0')}-${h.hMonth.toString().padLeft(2, '0')}-01';
  }

  String _currentYearStartDate() {
    final h = HijriCalendar.now();
    return '${h.hYear.toString().padLeft(4, '0')}-01-01';
  }

  Future<TimePeriodTotals> _totalsSince(String sinceHijriDate) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('time_awareness_log', where: 'log_date >= ?', whereArgs: [sinceHijriDate]);
    var benefited = 0.0;
    var wasted = 0.0;
    for (final row in rows) {
      final entry = _entryFromRow(row);
      if (!entry.hasAnyEntry) continue;
      benefited += entry.benefitedHours;
      wasted += entry.wastedHours;
    }
    return TimePeriodTotals(benefited, wasted);
  }

  Future<TimePeriodTotals> weekTotals() => _totalsSince(_currentWeekStartDate());
  Future<TimePeriodTotals> monthTotals() => _totalsSince(_currentMonthStartDate());
  Future<TimePeriodTotals> yearTotals() => _totalsSince(_currentYearStartDate());

  /// Whole-hours remaining until local midnight tonight.
  int hoursRemainingToday() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return midnight.difference(now).inHours;
  }

  /// Whole days remaining in the current week (Saturday-start, so Friday
  /// is the last day — same convention as `SalahRepository`).
  int daysRemainingThisWeek() {
    final now = DateTime.now();
    final daysSinceSaturday = now.weekday % 7;
    return 6 - daysSinceSaturday;
  }

  /// Whole days remaining in the current Hijri month.
  int daysRemainingThisMonth() {
    final h = HijriCalendar.now();
    return h.lengthOfMonth - h.hDay;
  }

  /// Whole days remaining in the current Hijri year.
  int daysRemainingThisYear() => hijriYearDays - daysElapsedThisHijriYear();
}
