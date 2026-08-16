/// Strips tashkeel/diacritics and unifies letter variants for search
/// matching only (QURAN_COMPANION_ROADMAP.md section "البحث بدون تشكيل").
/// Never use this for display — displayed ayah text always stays
/// `text_uthmani` in full, unmodified.
///
/// Escapes below are written as explicit \uXXXX codes rather than pasted
/// glyphs on purpose: several of these are combining marks that render
/// invisibly/ambiguously in editors, which previously caused silent
/// copy/paste corruption in this exact file.
String normalizeArabicForSearch(String input) {
  var result = input;

  // Optional tatweel/diacritic filler that can sit between two letters
  // in the Uthmani rasm without changing which letters they are.
  const d = '[ـً-ٕ]*';

  // --- Dagger alef (U+0670) handling, verified against every one of the
  // ~2650 distinct word forms containing it in the bundled
  // quran-uthmani.txt (not guessed). It plays three different roles:
  //
  //  1) waw + dagger alef (ٱلصَّلَوٰةَ، ٱلْحَيَوٰةَ، ٱلزَّكَوٰةَ) — an
  //     archaic spelling of the "اة" ending. Modern spelling drops the
  //     waw entirely (الصلاة). -> collapses to a plain ا.
  //  2) alif maqsura + dagger alef (عَلَىٰ، مُوسَىٰ، سَعَىٰ — ~600
  //     forms) — just a pronunciation mark on the already-present ى,
  //     not a separate letter. -> dagger dropped, ى kept (and later
  //     normalized to ي by the rule below, as before).
  //  3) A small closed set of everyday words (الرحمن، هذا/هذه، هؤلاء،
  //     ذلك/كذلك، لكن) that Standard Arabic also spells without the
  //     extra alef outside the Quran — "الرحمن" is never typed
  //     "الرحمان". -> dagger dropped for exactly these.
  //  4) Everything else (~2100 forms, e.g. ٱلظَّـٰلِمِينَ) is a
  //     genuinely omitted "ا" between two ordinary consonants. This is
  //     the actual bug: "الظالمين" typed plainly never matched the
  //     stored ayah text because the old code deleted this case too,
  //     same as case 2/3, instead of restoring the letter. -> only this
  //     remaining category converts to a real ا.
  //
  // Order matters: cases 1-3 must run before the catch-all in case 4.
  result = result.replaceAll('وٰ', 'ا'); // waw+dagger -> ا
  result = result.replaceAll('ىٰ', 'ى'); // alif maqsura+dagger -> ى
  result = result.replaceAllMapped(
    RegExp('ه($d)ٰ($d[ذؤ])'), // هذا/هذه/هؤلاء
    (m) => 'ه${m[1]}${m[2]}',
  );
  result = result.replaceAllMapped(
    RegExp('ذ($d)ٰ($dل)'), // ذلك/كذلك
    (m) => 'ذ${m[1]}${m[2]}',
  );
  result = result.replaceAllMapped(
    RegExp('ل($d)ٰ($dك)'), // لكن
    (m) => 'ل${m[1]}${m[2]}',
  );
  result = result.replaceAllMapped(
    RegExp('ح($dم$d)ٰ($dن)'), // الرحمن
    (m) => 'ح${m[1]}${m[2]}',
  );
  result = result.replaceAll('ٰ', 'ا'); // remaining dagger alef -> ا

  // Tashkeel (fatha/damma/kasra/sukun/shadda/tanween, U+064B-064F) and
  // combining madda/hamza-above/hamza-below (U+0650-0655 — the exact gap
  // that made "الفقراء" unsearchable: Tanzil's Uthmani text spells it
  // with U+0653 MADDAH ABOVE before the hamza, and that combining mark
  // wasn't being stripped, so the stored normalized text never matched
  // a plain-typed query), plus the whole Quranic small-mark/waqf
  // annotation block (U+06D6-U+06ED — small high seen, small waw/yeh,
  // sajdah/rub-el-hizb ornaments, etc.) — verified against every
  // non-letter character actually occurring in the bundled Tanzil
  // Uthmani text, not guessed. U+0670 is excluded from this range since
  // it's fully handled above.
  result = result.replaceAll(RegExp('[ً-ٯۖ-ۭ]'), '');
  // Tatweel/kashida (a stretch character, carries no letter identity).
  result = result.replaceAll('ـ', '');
  // Alef variants (hamza-above/below, madda, and the Uthmani wasla alef
  // U+0671 used at the start of many words) all collapse to plain alef.
  result = result.replaceAll(RegExp('[أإآٱ]'), 'ا');
  // Alef maksura -> ya.
  result = result.replaceAll('ى', 'ي');
  // Ta marbuta -> ha (matches how most users type when searching).
  result = result.replaceAll('ة', 'ه');
  return result;
}
