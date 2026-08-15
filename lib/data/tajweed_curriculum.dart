/// Tajweed curriculum, 3 tiers — QURAN_COMPANION_ROADMAP.md Phase 11
/// (Ismail's request 2026-08-15). The rules themselves (makharij, noon
/// sakinah rules, madd types, etc.) are universally-taught facts about
/// correct Quranic recitation — identical across every Tajweed teacher
/// and textbook — not copyrighted expression from any single source.
/// Written as original explanations for this app.
///
/// The two classical texts referenced (`recommendedTajweedResources`) —
/// Tuhfat al-Atfal (Sulayman Al-Jamzuri, 18th century, the standard
/// beginner Tajweed poem) and Al-Muqaddimah Al-Jazariyyah (Ibn al-Jazari,
/// d. 833 AH, the most authoritative classical Tajweed text) — are cited
/// by title/author for learners who want the traditional memorized-poem
/// route; their actual verses are NOT reproduced here, same citation-only
/// pattern as the Arabic curriculum's recommended resources.
library;

class TajweedRule {
  final String titleAr;
  final String titleEn;
  final String explanationEn;
  final String exampleAr;
  final String exampleNote;
  const TajweedRule({
    required this.titleAr,
    required this.titleEn,
    required this.explanationEn,
    required this.exampleAr,
    required this.exampleNote,
  });
}

class TajweedTier {
  final String key;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final List<TajweedRule> rules;
  const TajweedTier({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.rules,
  });
}

class TajweedResource {
  final String titleAr;
  final String titleEn;
  final String authorAr;
  final String noteAr;
  const TajweedResource({required this.titleAr, required this.titleEn, required this.authorAr, required this.noteAr});
}

const recommendedTajweedResources = [
  TajweedResource(
    titleAr: 'تحفة الأطفال',
    titleEn: 'Tuhfat al-Atfal',
    authorAr: 'سليمان الجمزوري (القرن الثامن عشر الميلادي)',
    noteAr: 'منظومة شعرية قصيرة (٦١ بيتًا) هي المدخل التقليدي الأول لعلم التجويد عند طلاب العلم منذ قرون — تُحفظ غيبًا في أغلب حلقات التحفيظ.',
  ),
  TajweedResource(
    titleAr: 'المقدمة الجزرية',
    titleEn: 'Al-Muqaddimah Al-Jazariyyah',
    authorAr: 'الإمام ابن الجزري (٧٥١-٨٣٣هـ)',
    noteAr: 'المرجع الكلاسيكي الأعلى مكانة في علم التجويد وعلوم القراءات، أوسع وأعمق من تحفة الأطفال — الخطوة التالية بعد إتقان الأساسيات.',
  ),
];

const tajweedTiers = [
  TajweedTier(
    key: 'basic',
    titleAr: 'المستوى الأساسي',
    titleEn: 'Basic Tier',
    descriptionAr: 'مخارج الحروف، وأحكام النون الساكنة والتنوين.',
    rules: [
      TajweedRule(
        titleAr: 'مخارج الحروف (نظرة عامة)',
        titleEn: 'Articulation Points (Makharij al-Huruf)',
        explanationEn: 'Every Arabic letter is pronounced from a specific point in the mouth/throat. The 5 main regions are: الجوف (the open mouth/throat cavity — for long vowels), الحلق (the throat, in 3 zones — for ء ه ع ح غ خ), اللسان (the tongue, the largest group of letters), الشفتان (the two lips — for ب م و ف), and الخيشوم (the nasal cavity — for ghunnah/nasalization). Getting the articulation point right is what makes recitation clear rather than slurred.',
        exampleAr: 'الحلق: ء هـ (أقصى الحلق) — ع ح (وسط الحلق) — غ خ (أدنى الحلق)',
        exampleNote: 'Throat letters, from deepest to shallowest',
      ),
      TajweedRule(
        titleAr: 'الإظهار الحلقي',
        titleEn: 'Izhar (Clear Pronunciation)',
        explanationEn: 'When a ن ساكنة (silent noon) or tanween is followed by one of the 6 throat letters (ء هـ ع ح غ خ), it is pronounced clearly and fully, with no merging or nasalization into the next letter.',
        exampleAr: 'مَنْ آمَنَ',
        exampleNote: 'The noon is pronounced clearly before أ',
      ),
      TajweedRule(
        titleAr: 'الإدغام',
        titleEn: 'Idgham (Merging)',
        explanationEn: 'When ن ساكنة/tanween is followed by one of 6 letters (ي ر م ل و ن, remembered by the word يرملون), the noon sound merges into the next letter instead of being pronounced separately. Some of these letters merge WITH nasalization (ghunnah) — ي ن م و — and some WITHOUT — ر ل.',
        exampleAr: 'مِن رَّبِّهِمْ',
        exampleNote: 'The noon merges into the ر with no nasalization',
      ),
      TajweedRule(
        titleAr: 'الإقلاب',
        titleEn: 'Iqlab (Conversion)',
        explanationEn: 'When ن ساكنة/tanween is followed specifically by ب, the noon sound converts into a light م sound (with nasalization), and a small م mark is written above it in most Mushaf printings.',
        exampleAr: 'مِن بَعْدِ',
        exampleNote: 'Pronounced closer to "mim ba\'di"',
      ),
      TajweedRule(
        titleAr: 'الإخفاء الحقيقي',
        titleEn: 'Ikhfa (Concealment)',
        explanationEn: 'When ن ساكنة/tanween is followed by any of the remaining 15 letters (not covered by the three rules above), the noon sound is partially concealed — pronounced neither fully clear nor fully merged, with a light nasal hum held for about 2 counts.',
        exampleAr: 'مِن تَحْتِهَا',
        exampleNote: 'The noon is softened/nasalized before ت, not pronounced sharply',
      ),
    ],
  ),
  TajweedTier(
    key: 'intermediate',
    titleAr: 'المستوى المتوسط',
    titleEn: 'Intermediate Tier',
    descriptionAr: 'أحكام الميم الساكنة، القلقلة، وتفخيم/ترقيق اللام والراء.',
    rules: [
      TajweedRule(
        titleAr: 'الإخفاء الشفوي',
        titleEn: 'Ikhfa Shafawi (Labial Concealment)',
        explanationEn: 'When م ساكنة (silent meem) is followed by ب, it is lightly concealed with nasalization — the lips barely touch.',
        exampleAr: 'تَرْمِيهِم بِحِجَارَةٍ',
        exampleNote: 'The meem before ب is softened, not fully closed',
      ),
      TajweedRule(
        titleAr: 'الإدغام الشفوي',
        titleEn: 'Idgham Shafawi (Labial Merging)',
        explanationEn: 'When م ساكنة is followed by another م, the two merge into one held meem sound with nasalization.',
        exampleAr: 'لَهُم مَّا',
        exampleNote: 'One held "mm" sound, not two separate meems',
      ),
      TajweedRule(
        titleAr: 'الإظهار الشفوي',
        titleEn: 'Izhar Shafawi (Labial Clarity)',
        explanationEn: 'When م ساكنة is followed by any letter OTHER than ب or م, it is pronounced clearly with lips closing normally — no nasalization or merging.',
        exampleAr: 'أَنْعَمْتَ عَلَيْهِمْ',
        exampleNote: 'The meem is pronounced plainly before ع',
      ),
      TajweedRule(
        titleAr: 'القلقلة',
        titleEn: 'Qalqalah (Echoing Bounce)',
        explanationEn: 'Five letters (ق ط ب ج د, remembered by قطب جد) get a slight echoing/bouncing sound when they carry a sukoon (no vowel), especially at the end of a word or a stop.',
        exampleAr: 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقْ',
        exampleNote: 'The ق and ب both get a light bounce',
      ),
      TajweedRule(
        titleAr: 'تفخيم وترقيق اللام',
        titleEn: 'Tafkheem/Tarqeeq of Laam',
        explanationEn: 'The ل in the word اللَّه ("Allah") is pronounced HEAVY (تفخيم — with the back of the tongue raised) when preceded by a fatha or damma, and LIGHT (ترقيق) when preceded by a kasra. Every other Arabic ل is always light.',
        exampleAr: 'قَالَ اللَّهُ (heavy) — بِسْمِ اللَّهِ (light)',
        exampleNote: 'Compare the "L" sound before/after a kasra',
      ),
      TajweedRule(
        titleAr: 'تفخيم وترقيق الراء',
        titleEn: 'Tafkheem/Tarqeeq of Ra',
        explanationEn: 'The ر is HEAVY by default (when it carries fatha or damma, or is preceded by one), and LIGHT when it carries or is preceded by a kasra — with several detailed exceptions learned with practice.',
        exampleAr: 'رَبَّنَا (heavy) — مِن رِزْقِ (light)',
        exampleNote: 'The heavy ر is pronounced with more depth/roundness',
      ),
    ],
  ),
  TajweedTier(
    key: 'advanced',
    titleAr: 'المستوى المتقدم',
    titleEn: 'Advanced Tier',
    descriptionAr: 'أنواع المدّ، وأحكام الوقف — يوصى بمتابعتها مع متن التحفة والمقدمة الجزرية.',
    rules: [
      TajweedRule(
        titleAr: 'المد الطبيعي',
        titleEn: 'Madd Tabee\'i (Natural Elongation)',
        explanationEn: 'The basic elongation of alif/waw/ya as long vowels, held for exactly 2 counts — the baseline every other madd type is measured against.',
        exampleAr: 'قَالَ — يَقُولُ — قِيلَ',
        exampleNote: '2 counts each',
      ),
      TajweedRule(
        titleAr: 'المد المتصل',
        titleEn: 'Madd Muttasil (Connected Elongation)',
        explanationEn: 'When a madd letter is immediately followed by a hamza in the SAME word, the elongation is obligatorily extended to 4-5 counts.',
        exampleAr: 'السَّمَاءِ — جَاءَ',
        exampleNote: '4-5 counts, hamza right after the madd letter',
      ),
      TajweedRule(
        titleAr: 'المد المنفصل',
        titleEn: 'Madd Munfasil (Separated Elongation)',
        explanationEn: 'When a word ends in a madd letter and the NEXT word begins with a hamza, the elongation is extended to 4-5 counts (with some flexibility depending on the reciter\'s chosen riwayah/transmission).',
        exampleAr: 'يَا أَيُّهَا — فِي أَنفُسِكُمْ',
        exampleNote: '4-5 counts, hamza starts the next word',
      ),
      TajweedRule(
        titleAr: 'المد اللازم',
        titleEn: 'Madd Lazim (Necessary Elongation)',
        explanationEn: 'When a madd letter is followed by a permanent sukoon (in every reading, not just when stopping), the elongation is held for the full 6 counts — the longest madd.',
        exampleAr: 'الضَّالِّينَ — الحَاقَّةُ',
        exampleNote: '6 counts, always — this sukoon never changes',
      ),
      TajweedRule(
        titleAr: 'المد العارض للسكون',
        titleEn: 'Madd \'Aarid lis-Sukoon (Temporary Elongation on Stopping)',
        explanationEn: 'When you stop (waqf) at a word ending in a madd letter followed by a letter that would normally carry a vowel, the elongation may be held for 2, 4, or 6 counts (the reciter\'s choice) — but only because you chose to stop there.',
        exampleAr: 'الرَّحِيمِ (stopping here) — نَسْتَعِينُ (stopping here)',
        exampleNote: '2, 4, or 6 counts — only when stopping',
      ),
      TajweedRule(
        titleAr: 'علامات الوقف',
        titleEn: 'Waqf (Stopping) Symbols',
        explanationEn: 'Mushaf printings mark where stopping is preferred, required, or forbidden using small symbols above the text: م (must stop), لا (must not stop), ج (stopping permitted either way), صلى (better to continue), قلى (better to stop).',
        exampleAr: 'م — لا — ج — صلى — قلى',
        exampleNote: 'Learn to recognize these symbols while reading any Mushaf',
      ),
    ],
  ),
];
