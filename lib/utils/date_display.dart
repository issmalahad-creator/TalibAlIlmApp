import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../services/calendar_preference_service.dart';
import 'hijri_date.dart';

/// Renders a stored Hijri date string ("1447-01-15") for display, honoring
/// the student's Hijri/Gregorian display preference
/// (`CalendarPreferenceService`) — storage stays Hijri-keyed everywhere
/// regardless of this setting, only the rendered text changes.
String formatDateForDisplay(String hijriDate) {
  final parts = hijriDate.split('-');
  if (parts.length < 3) return hijriDate;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return hijriDate;

  if (!CalendarPreferenceService.useGregorian) {
    final h = HijriCalendar()
      ..hYear = year
      ..hMonth = month
      ..hDay = day;
    return '$day ${h.getLongMonthName()} $year هـ';
  }

  final gregorian = gregorianFromHijriDateTime(hijriDate, null);
  return DateFormat('d MMMM yyyy', 'ar').format(gregorian);
}
