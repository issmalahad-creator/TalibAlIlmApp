import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The student's chosen UI language — QURAN_COMPANION_ROADMAP.md Phase 10,
/// rebuilt 2026-08-17 after Ismail reported that changing the language
/// "only affects a few elements". Investigated directly — three real bugs,
/// not one design flaw:
///
/// 1. `load()` was never actually called anywhere in the app (not even in
///    `main()`), so the saved preference never got read back — every
///    launch silently reset to Arabic regardless of what was chosen.
/// 2. `MaterialApp`'s own `locale`/`supportedLocales`/`Directionality` in
///    `main.dart` were hardcoded to Arabic/RTL always, completely
///    independent of this service — so even a working preference could
///    never affect the app's real locale or text direction.
/// 3. `currentLanguage` was a plain static field, read once into a `final`
///    in `home_screen.dart`'s `State` — so it never refreshed after a
///    change made on another screen without a full app restart.
///
/// All three fixed: `languageNotifier` (same reactive pattern as
/// `TextScalePreferenceService.scaleNotifier` — the one other preference
/// in this app that already needed to rebuild the whole `MaterialApp`
/// live) drives `main.dart`'s locale/direction directly, `load()` is now
/// called from `main()`, and screens read the notifier's value instead of
/// caching a stale copy.
///
/// Scope is UNCHANGED and deliberate: "الأساسيات" only (navigation/hub
/// labels, common actions), per Ismail's own original framing — "ترجم ما
/// استطعت الأساسيات، أما المتعمق عليه أن يتعلم العربية" (translate what
/// you can of the basics; for deep content, they should learn Arabic).
/// Deep Islamic content (Quran study, tafsir, adhkar, fiqh, adab) stays
/// Arabic-only by design, or gets a REAL licensed translation via the
/// separate multi-language tafsir library (QuranEnc-sourced) — not a
/// machine-translated UI-string lookup, which would be inappropriate for
/// scholarly religious content.
class LanguagePreferenceService {
  static const _prefsKey = 'app_ui_language';
  static const defaultLanguage = 'ar';

  static final ValueNotifier<String> languageNotifier = ValueNotifier(defaultLanguage);

  /// Kept for the handful of call sites that read a plain value rather
  /// than listening to [languageNotifier] — always mirrors its value.
  static String get currentLanguage => languageNotifier.value;

  /// Flutter's own Material/Widgets/Cupertino localizations (confirmed by
  /// reading `flutter_localizations`' generated locale list directly, not
  /// assumed) cover these 10 of the app's 13 offered languages plus
  /// English. Hausa/Somali have no framework-level translation — the
  /// app's own `basicText()` labels still work perfectly for them, but
  /// `MaterialApp`'s built-in chrome (date pickers, etc.) falls back to
  /// English rather than silently erroring.
  static const frameworkSupportedLanguages = {'ar', 'en', 'am', 'bn', 'fa', 'fr', 'id', 'ms', 'sw', 'tr', 'ur'};

  /// RTL languages among the ones this app offers.
  static const rtlLanguages = {'ar', 'ur', 'fa'};

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    languageNotifier.value = prefs.getString(_prefsKey) ?? defaultLanguage;
  }

  static Future<void> setLanguage(String code) async {
    languageNotifier.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }
}
