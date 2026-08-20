/// Cheap script-based language guess — no ML, no network, just a Unicode
/// range check. Deliberately coarse (Arabic-script vs. Latin-script) rather
/// than a real language classifier: good enough to route free text to the
/// right keyword set in `CompanionChatEngine`, not meant as a general NLP
/// tool. Extend the range list here, not with a new dependency, if a third
/// script (e.g. Amharic's Ge'ez block) needs its own bucket later.
library;

/// Arabic script block (covers Arabic, Persian/Urdu-shared letters, and the
/// Quranic combining marks already handled by `arabic_normalize.dart`).
final _arabicRange = RegExp(r'[؀-ۿݐ-ݿ]');

/// Best-guess language code for [text] — 'ar' if it contains any
/// Arabic-script character, otherwise 'en'. Empty/whitespace-only input
/// returns null (nothing to detect).
String? detectScriptLanguage(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  return _arabicRange.hasMatch(trimmed) ? 'ar' : 'en';
}
