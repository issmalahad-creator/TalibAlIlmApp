import 'package:shared_preferences/shared_preferences.dart';

/// The student's chosen UI language — QURAN_COMPANION_ROADMAP.md Phase 10.
/// Deliberately scoped to "the basics" only (navigation/hub labels, common
/// actions), per Ismail's own framing: "ترجم ما استطعت الأساسيات، أما
/// المتعمق عليه أن يتعلم العربية" (translate what you can of the basics;
/// for deep content, they should learn Arabic). Deep Islamic content
/// (Quran study, tafsir, adhkar, fiqh, adab) stays Arabic-only by design —
/// this preference never touches it. Same load-once-into-a-static-cache
/// pattern as `CalendarPreferenceService`.
class LanguagePreferenceService {
  static const _prefsKey = 'app_ui_language';
  static const defaultLanguage = 'ar';
  static String currentLanguage = defaultLanguage;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    currentLanguage = prefs.getString(_prefsKey) ?? defaultLanguage;
  }

  static Future<void> setLanguage(String code) async {
    currentLanguage = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }
}
