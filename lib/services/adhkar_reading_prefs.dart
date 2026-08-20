import 'package:shared_preferences/shared_preferences.dart';

/// Per-device reading comfort settings for the adhkar reading screen only
/// (font size + dark background) — Ismail's 2026-08-16 request after sharing
/// screenshots of a reference app's reading controls (share/A-/A+/night
/// toggle). Screen-local rather than app-wide like `CalendarPreferenceService`
/// since only `AdhkarCategoryScreen` reads it; loaded async per screen-open
/// instead of at app startup to avoid touching `main.dart`'s boot sequence.
class AdhkarReadingPrefs {
  static const _fontScaleKey = 'adhkar_reading_font_scale';
  static const _darkKey = 'adhkar_reading_dark';
  static const minScale = 0.85;
  static const maxScale = 1.4;

  Future<double> fontScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontScaleKey) ?? 1.0;
  }

  Future<void> setFontScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, value.clamp(minScale, maxScale));
  }

  Future<bool> darkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, value);
  }
}
