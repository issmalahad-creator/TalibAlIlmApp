import 'package:hijri/hijri_calendar.dart';

void initHijriLocale() {
  HijriCalendar.setLocal('ar');
}

/// Hijri year-month key, e.g. "1447-01" — used as the DB grouping key
/// everywhere a "month" is stored (activities, goals, reading progress,
/// quiz results, submission queue).
String currentHijriMonthKey() {
  final h = HijriCalendar.now();
  return _monthKey(h.hYear, h.hMonth);
}

String hijriMonthKeyForDate(DateTime date) {
  final h = HijriCalendar.fromDate(date);
  return _monthKey(h.hYear, h.hMonth);
}

/// Full Hijri date string, e.g. "1447-01-15" — used as the per-entry date.
String hijriDateStringForDate(DateTime date) {
  final h = HijriCalendar.fromDate(date);
  return '${_monthKey(h.hYear, h.hMonth)}-${h.hDay.toString().padLeft(2, '0')}';
}

String _monthKey(int year, int month) =>
    '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

/// Converts a stored Hijri date string ("1447-01-15") plus an optional
/// "HH:mm" time back to a real Gregorian [DateTime] — needed to schedule a
/// local notification at that moment.
DateTime gregorianFromHijriDateTime(String hijriDate, String? time) {
  final parts = hijriDate.split('-');
  final year = int.tryParse(parts[0]) ?? HijriCalendar.now().hYear;
  final month = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;
  final day = int.tryParse(parts.length > 2 ? parts[2] : '') ?? 1;
  final gregorian = HijriCalendar().hijriToGregorian(year, month, day);
  var hour = 9;
  var minute = 0;
  if (time != null && time.contains(':')) {
    final t = time.split(':');
    hour = int.tryParse(t[0]) ?? 9;
    minute = int.tryParse(t.length > 1 ? t[1] : '0') ?? 0;
  }
  return DateTime(gregorian.year, gregorian.month, gregorian.day, hour, minute);
}

/// Arabic label for a month key, e.g. "1447-01" -> "محرم 1447".
String hijriMonthLabel(String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length != 2) return monthKey;
  final year = int.tryParse(parts[0]) ?? 0;
  final month = int.tryParse(parts[1]) ?? 1;
  final h = HijriCalendar()
    ..hYear = year
    ..hMonth = month
    ..hDay = 1;
  return '${h.getLongMonthName()} $year';
}

/// Gregorian DateTime for 09:00 local time, [daysBefore] days before the end
/// of the current Hijri month. Used to schedule the "report deadline is
/// approaching" reminder.
DateTime hijriMonthEndReminderDateTime({int daysBefore = 3}) {
  final h = HijriCalendar.now();
  var reminderHijriDay = h.lengthOfMonth - daysBefore;
  if (reminderHijriDay < 1) reminderHijriDay = 1;
  final gregorian = HijriCalendar().hijriToGregorian(h.hYear, h.hMonth, reminderHijriDay);
  return DateTime(gregorian.year, gregorian.month, gregorian.day, 9, 0);
}
