/// Strips tashkeel/diacritics and unifies letter variants for search
/// matching only (QURAN_COMPANION_ROADMAP.md section "البحث بدون تشكيل").
/// Never use this for display — displayed ayah text always stays
/// `text_uthmani` in full, unmodified.
String normalizeArabicForSearch(String input) {
  var result = input;
  // Tashkeel (fatha/damma/kasra/sukun/shadda/tanween, U+064B-064F),
  // combining madda/hamza-above/hamza-below (U+0653-0655 — the exact gap
  // that made "الفقراء" unsearchable: Tanzil's Uthmani text spells it
  // ا + ٓ(U+0653 MADDAH ABOVE) + ء, and that combining mark wasn't being
  // stripped, so the stored normalized text never matched a plain-typed
  // query), the dagger alef (U+0670), and the whole Quranic
  // small-mark/waqf-annotation block (U+06D6-U+06ED — small high seen,
  // small waw/yeh, sajdah/rub-el-hizb ornaments, etc.) — verified against
  // every non-letter character actually occurring in the bundled Tanzil
  // Uthmani text, not guessed.
  result = result.replaceAll(RegExp(r'[ً-ٰٕۖ-ۭ]'), '');
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
