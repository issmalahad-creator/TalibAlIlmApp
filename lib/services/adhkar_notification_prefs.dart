import 'package:shared_preferences/shared_preferences.dart';

/// Per-category adhkar reminder settings — Ismail's 2026-08-17 request:
/// morning/evening/sleep reminders should default to real prayer times
/// (Fajr/Asr/Isha), but be editable or hideable per category. Same
/// per-instance-class, per-key style as `AdhkarReadingPrefs`. `customHour`
/// null means "use the live prayer-time default" — an explicit int means
/// the student overrode it manually.
class AdhkarNotificationPrefs {
  static const _categories = ['morning', 'evening', 'sleep'];

  Future<bool> isEnabled(String category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('adhkar_notif_${category}_enabled') ?? true;
  }

  Future<void> setEnabled(String category, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhkar_notif_${category}_enabled', value);
  }

  Future<int?> customHour(String category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('adhkar_notif_${category}_hour');
  }

  Future<void> setCustomHour(String category, int? hour) async {
    final prefs = await SharedPreferences.getInstance();
    if (hour == null) {
      await prefs.remove('adhkar_notif_${category}_hour');
    } else {
      await prefs.setInt('adhkar_notif_${category}_hour', hour);
    }
  }

  List<String> get categories => _categories;
}
