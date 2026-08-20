import 'package:shared_preferences/shared_preferences.dart';

/// Global "quiet hours" window (2026-08-17 reliability pass) — when
/// enabled, any reminder that would otherwise schedule inside [startHour,
/// endHour) is pushed to [endHour] instead. Disabled by default (no
/// behavior change for students who never touch this setting). Deliberately
/// a single global window, not per-notification-type — same "smallest
/// thing that solves the real ask" judgment as every other prefs class
/// this session (`AdhkarNotificationPrefs`, `PrayerNotificationPrefs`).
///
/// Only shifts the *scheduled* hour going forward — it cannot recall an
/// alarm the OS already fired before quiet hours were turned on, and
/// prayer-time notifications (tied to real prayer times, not a pickable
/// hour) are intentionally NOT affected — silencing an adhan-adjacent
/// notification would defeat its purpose.
class QuietHoursPrefs {
  static const _enabledKey = 'quiet_hours_enabled';
  static const _startHourKey = 'quiet_hours_start';
  static const _endHourKey = 'quiet_hours_end';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<int> startHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_startHourKey) ?? 22;
  }

  Future<int> endHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_endHourKey) ?? 6;
  }

  Future<void> setWindow(int startHour, int endHour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startHourKey, startHour);
    await prefs.setInt(_endHourKey, endHour);
  }
}

/// Pure function, no prefs/DB access — given an hour and a quiet window
/// (which may wrap past midnight, e.g. 22→6), returns the hour a reminder
/// should actually fire at. Extracted standalone so it's directly testable
/// without mocking `SharedPreferences`.
int applyQuietHours({required int hour, required bool quietEnabled, required int quietStart, required int quietEnd}) {
  if (!quietEnabled) return hour;
  final inWindow = quietStart <= quietEnd
      ? hour >= quietStart && hour < quietEnd
      : hour >= quietStart || hour < quietEnd; // wraps past midnight
  return inWindow ? quietEnd : hour;
}
