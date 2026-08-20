import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide text-size preference — 100_IDEAS_FOR_IMPROVEMENT.md #6, useful
/// for older users. `ValueNotifier` (not the static-cache-only pattern
/// `LanguagePreferenceService`/`CalendarPreferenceService` use) since this
/// one needs to rebuild the whole `MaterialApp` live when changed, not just
/// be read once per screen build.
class TextScalePreferenceService {
  static const _prefsKey = 'app_text_scale';
  static const defaultScale = 1.0;

  /// Presets, not a free slider — a slider invites false precision for
  /// something that only needs "a bit bigger"/"a bit smaller".
  static const presets = [0.85, 1.0, 1.15, 1.3];
  // Not `const`: Dart disallows `double` keys in const maps (no primitive
  // equality guarantee), so this is a plain final map instead.
  static final presetLabels = {0.85: 'صغير', 1.0: 'عادي', 1.15: 'كبير', 1.3: 'أكبر'};

  static final ValueNotifier<double> scaleNotifier = ValueNotifier(defaultScale);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    scaleNotifier.value = prefs.getDouble(_prefsKey) ?? defaultScale;
  }

  static Future<void> setScale(double scale) async {
    scaleNotifier.value = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, scale);
  }
}
