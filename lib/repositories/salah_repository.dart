import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';

enum PrayerStatus { onTime, jamaah, late, missed }

extension on PrayerStatus {
  String get dbValue => switch (this) {
        PrayerStatus.onTime => 'on_time',
        PrayerStatus.jamaah => 'jamaah',
        PrayerStatus.late => 'late',
        PrayerStatus.missed => 'missed',
      };
}

PrayerStatus? _statusFromDb(String? value) => switch (value) {
      'on_time' => PrayerStatus.onTime,
      'jamaah' => PrayerStatus.jamaah,
      'late' => PrayerStatus.late,
      'missed' => PrayerStatus.missed,
      _ => null,
    };

const salahPrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

const salahAssessmentDimensions = [
  'muhafazah', // المحافظة على الصلوات
  'onTime', // الصلاة في الوقت
  'jamaah', // الجماعة
  'khushu', // الخشوع
  'rawatib', // السنن الرواتب
  'adhkar', // أذكار الصلاة
  'understanding', // فهم ما تُقرأ
];

/// "إقامة الصلاة" — daily prayer tracking + weekly self-assessment.
/// Deliberately non-judgmental throughout: a missed prayer is just a row
/// with status='missed', never a "streak broken" event or a shamed
/// counter, matching this app's non-punitive principle. `khushu` (and
/// every other assessment dimension) is ALWAYS a number the student picks
/// for themselves — this repository has no logic that infers or scores
/// khushu; the app is not in a position to judge a worshipper's inward
/// state and never claims to.
class SalahRepository {
  Future<Map<String, PrayerStatus?>> statusesForDate(String hijriDate) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('salah_log', where: 'log_date = ?', whereArgs: [hijriDate]);
    final byPrayer = {for (final r in rows) r['prayer'] as String: _statusFromDb(r['status'] as String)};
    return {for (final p in salahPrayerKeys) p: byPrayer[p]};
  }

  Future<Map<String, PrayerStatus?>> statusesForToday() => statusesForDate(todayDate());

  Future<void> setStatus(String prayer, PrayerStatus status, {String? date}) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'salah_log',
      {'log_date': date ?? todayDate(), 'prayer': prayer, 'status': status.dbValue},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearStatus(String prayer, {String? date}) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('salah_log', where: 'log_date = ? AND prayer = ?', whereArgs: [date ?? todayDate(), prayer]);
  }

  /// The hijri date string for the Saturday starting the current week —
  /// used as a stable weekly bucket key for self-assessment.
  String currentWeekStart() {
    final now = DateTime.now();
    final daysSinceSaturday = (now.weekday % 7); // DateTime.saturday == 6, Sunday == 7%7=0
    final saturday = now.subtract(Duration(days: daysSinceSaturday));
    return hijriDateStringForDate(saturday);
  }

  Future<Map<String, int>> assessmentFor(String weekStart) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('salah_self_assessment', where: 'week_start = ?', whereArgs: [weekStart]);
    final byDimension = {for (final r in rows) r['dimension'] as String: r['rating'] as int};
    return {for (final d in salahAssessmentDimensions) d: byDimension[d] ?? 0};
  }

  Future<void> setRating(String weekStart, String dimension, int rating) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'salah_self_assessment',
      {'week_start': weekStart, 'dimension': dimension, 'rating': rating},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// A simple weekly count of on-time/jamaah prayers out of the 35
  /// possible (5 prayers x 7 days) — purely descriptive, no judgment
  /// language, for the weekly summary view.
  Future<(int completed, int total)> weeklyCompletionCount(String weekStart) async {
    final db = await DatabaseHelper.instance.database;
    final startGregorian = gregorianFromHijriDateTime(weekStart, null);
    final dates = List.generate(7, (i) => hijriDateStringForDate(startGregorian.add(Duration(days: i))));
    final placeholders = List.filled(dates.length, '?').join(',');
    final count = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM salah_log WHERE log_date IN ($placeholders) AND status IN ('on_time', 'jamaah')",
      dates,
    ));
    return (count ?? 0, dates.length * salahPrayerKeys.length);
  }

  /// Per-day, per-prayer status for the current week — the "weekly report"
  /// grid Ismail's original design asked for, showing the tracker's own
  /// daily data at a glance instead of only a single aggregate number.
  /// Days are ordered Saturday→Friday to match `currentWeekStart`.
  Future<List<(String date, Map<String, PrayerStatus?> statuses)>> weeklyGrid(String weekStart) async {
    final startGregorian = gregorianFromHijriDateTime(weekStart, null);
    final dates = List.generate(7, (i) => hijriDateStringForDate(startGregorian.add(Duration(days: i))));
    return [for (final d in dates) (d, await statusesForDate(d))];
  }

  Future<Set<String>> readLessonKeys() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('salah_library_progress');
    return rows.map((r) => r['lesson_key'] as String).toSet();
  }

  Future<void> markLessonRead(String lessonKey) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'salah_library_progress',
      {'lesson_key': lessonKey, 'read_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
