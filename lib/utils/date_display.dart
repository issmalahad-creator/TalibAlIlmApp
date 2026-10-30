import 'package:intl/intl.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
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

  final lang = LanguagePreferenceService.currentLanguage;
  if (!CalendarPreferenceService.useGregorian) {
    return '$day ${hijriMonthName(month, lang)} $year ${basicText('hijri_era_suffix', lang)}';
  }

  final gregorian = gregorianFromHijriDateTime(hijriDate, null);
  // Gregorian month names come from intl, which only holds the locales the
  // app's localization delegates loaded (not Hausa or Somali) — English then.
  try {
    return DateFormat('d MMMM yyyy', lang).format(gregorian);
  } catch (_) {
    return DateFormat('d MMMM yyyy', 'en').format(gregorian);
  }
}
