import 'package:shared_preferences/shared_preferences.dart';

/// Whether dates are DISPLAYED in Gregorian instead of Hijri — a pure UI
/// preference for students more used to the Gregorian calendar. Every date
/// stored/keyed in the database stays Hijri throughout the app regardless
/// of this setting (that's the schema's primary-key format in many tables —
/// changing it would be a much bigger, riskier migration than this feature
/// warrants); this only controls what `formatDateForDisplay`
/// (`utils/date_display.dart`) renders back to the student. Loaded once at
/// startup into a static cache so every screen can read it synchronously
/// instead of threading a Future through every date-formatting call site —
/// same pattern as `initHijriLocale()`.
class CalendarPreferenceService {
  static const _prefsKey = 'use_gregorian_calendar';
  static bool useGregorian = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    useGregorian = prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> setUseGregorian(bool value) async {
    useGregorian = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}
