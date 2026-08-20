import 'package:shared_preferences/shared_preferences.dart';

/// Single on/off toggle for the 5 daily prayer-time notifications — kept
/// separate from `AdhkarNotificationPrefs` since prayer times aren't
/// per-category, just one global switch for now (per-prayer granularity
/// can grow later, same "حبة حبة" pattern as everything else this
/// session).
class PrayerNotificationPrefs {
  static const _enabledKey = 'prayer_notifications_enabled';

  // 2026-08-17: real audio, CC0-licensed (Wikimedia Commons, "Beautiful
  // adhan.ogg" — see LICENSED_CONTENT_SOURCES.md for the full verification
  // record). Defaults off since it changes an existing, expected sound —
  // `notification_service.dart` routes to a second notification channel
  // when this is true (Android locks a channel's sound at creation, so
  // toggling can't just change the existing channel's `sound:` param).
  static const _adhanSoundKey = 'prayer_notifications_adhan_sound';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<bool> useAdhanSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adhanSoundKey) ?? false;
  }

  Future<void> setUseAdhanSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adhanSoundKey, value);
  }
}
