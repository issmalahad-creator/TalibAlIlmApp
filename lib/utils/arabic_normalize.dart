/// Strips tashkeel/diacritics and unifies letter variants for search
/// matching only (QURAN_COMPANION_ROADMAP.md section "البحث بدون تشكيل").
/// Never use this for display — displayed ayah text always stays
/// `text_uthmani` in full, unmodified.
String normalizeArabicForSearch(String input) {
  var result = input;
  // Tashkeel: fatha, damma, kasra, sukun, shadda, the three tanween marks,
  // and the small "dagger" alef used throughout the Uthmani script.
  result = result.replaceAll(RegExp(r'[ً-ْٰ]'), '');
  // Tatweel/kashida (a stretch character, carries no letter identity).
  result = result.replaceAll('ـ', '');
  // Alef variants (hamza-above/below, madda, and the Uthmani wasla alef
  // ٱ used at the start of many words) all collapse to plain alef.
  result = result.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
  // Alef maksura -> ya.
  result = result.replaceAll('ى', 'ي');
  // Ta marbuta -> ha (matches how most users type when searching).
  result = result.replaceAll('ة', 'ه');
  return result;
}
