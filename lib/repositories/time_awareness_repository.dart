import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';

class TimeAwarenessEntry {
  final double? hoursWellSpent;
  final String? note;
  const TimeAwarenessEntry({this.hoursWellSpent, this.note});
}

/// "محاسبة الوقت" — purely self-reported, like every other subjective
/// self-rating in this app. No inference, no automatic tracking of how
/// hours were "actually" spent — only what the student honestly writes.
class TimeAwarenessRepository {
  /// Hours in the current Hijri year — the Hijri calendar this app is
  /// built around throughout (see `hijri_date.dart`), not the Gregorian
  /// year, so this stays consistent with how every other date in the app
  /// is stored/reasoned about. A Hijri year is 354 or 355 days depending
  /// on the year; 354 is used as the standard round figure quoted in
  /// Islamic time-awareness contexts.
  static const hijriYearDays = 354;
  static const hoursPerYear = hijriYearDays * 24;

  Future<TimeAwarenessEntry> todayEntry() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('time_awareness_log', where: 'log_date = ?', whereArgs: [todayDate()], limit: 1);
    if (rows.isEmpty) return const TimeAwarenessEntry();
    return TimeAwarenessEntry(
      hoursWellSpent: rows.first['hours_well_spent'] as double?,
      note: rows.first['note'] as String?,
    );
  }

  Future<void> saveToday(double? hoursWellSpent, String? note) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'time_awareness_log',
      {'log_date': todayDate(), 'hours_well_spent': hoursWellSpent, 'note': note},
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
}
