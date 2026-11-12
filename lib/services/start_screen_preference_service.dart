import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the app opens on: the muṣḥaf (default since 2026-11-12, Ismail:
/// «تطبيقي الرئيسية المصحف، المزايا في النافذة الجانبية») or the old
/// dashboard Home with its bottom tabs. Either way every section stays in
/// the side menu. A `ValueNotifier` so `MainShell` switches live when the
/// setting changes.
class StartScreenPreferenceService {
  static const prefsKey = 'start_screen';
  static const mushaf = 'mushaf';
  static const home = 'home';

  static final ValueNotifier<String> notifier = ValueNotifier(mushaf);

  static bool get startsOnMushaf => notifier.value != home;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getString(prefsKey) ?? mushaf;
  }

  static Future<void> set(String value) async {
    notifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, value);
  }
}
