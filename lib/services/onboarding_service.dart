import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-launch tutorial has been shown, so it only ever
/// appears automatically once. The help icon on the Home screen can still
/// re-open it any time in "review mode" without touching this flag.
class OnboardingService {
  static const _key = 'has_seen_onboarding';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
