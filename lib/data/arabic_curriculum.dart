/// Arabic-learning curriculum for non-native speakers —
/// QURAN_COMPANION_ROADMAP.md Phase 10b (Ismail's request 2026-08-15).
/// Distinct audience from the planned 5و (Noorani Qaida — children
/// learning to read); this is staged for ADULT non-native learners,
/// building toward reading and understanding the Quran's own Arabic.
///
/// Original content written directly for this app — the letters, their
/// names, and standard pronunciation are basic linguistic facts (like an
/// alphabet chart), not a translation of any specific textbook.
///
/// HONEST SCOPE (first pass, not the whole curriculum): only Stage 1
/// (the alphabet) is fully populated. Stages 2-5 are outlined with real
/// lesson titles so the roadmap is visible and "شهاداتي" can show the
/// full staged structure, but their actual lesson content is not written
/// yet — each unpopulated stage says so honestly in the UI rather than
/// silently appearing empty.
library;

class ArabicLetter {
  final String letter;
  final String nameAr;
  final String nameEn;
  final String pronunciationEn;
  final String exampleWordAr;
  final String exampleWordEn;
  const ArabicLetter({
    required this.letter,
    required this.nameAr,
    required this.nameEn,
    required this.pronunciationEn,
    required this.exampleWordAr,
    required this.exampleWordEn,
  });
}

const arabicAlphabet = [
  ArabicLetter(letter: 'ا', nameAr: 'ألف', nameEn: 'Alif', pronunciationEn: 'A long "aa" sound, like in "father"', exampleWordAr: 'أَب', exampleWordEn: 'father'),
  ArabicLetter(letter: 'ب', nameAr: 'باء', nameEn: 'Ba', pronunciationEn: 'Like English "b"', exampleWordAr: 'بَيت', exampleWordEn: 'house'),
  ArabicLetter(letter: 'ت', nameAr: 'تاء', nameEn: 'Ta', pronunciationEn: 'Like English "t"', exampleWordAr: 'تُفَّاح', exampleWordEn: 'apple'),
  ArabicLetter(letter: 'ث', nameAr: 'ثاء', nameEn: 'Tha', pronunciationEn: 'Like "th" in "think"', exampleWordAr: 'ثَعْلَب', exampleWordEn: 'fox'),
  ArabicLetter(letter: 'ج', nameAr: 'جيم', nameEn: 'Jeem', pronunciationEn: 'Like English "j"', exampleWordAr: 'جَمَل', exampleWordEn: 'camel'),
  ArabicLetter(letter: 'ح', nameAr: 'حاء', nameEn: 'Ha', pronunciationEn: 'A breathy "h", from deep in the throat (no English equivalent)', exampleWordAr: 'حَليب', exampleWordEn: 'milk'),
  ArabicLetter(letter: 'خ', nameAr: 'خاء', nameEn: 'Kha', pronunciationEn: 'Like the "ch" in Scottish "loch"', exampleWordAr: 'خُبز', exampleWordEn: 'bread'),
  ArabicLetter(letter: 'د', nameAr: 'دال', nameEn: 'Dal', pronunciationEn: 'Like English "d"', exampleWordAr: 'دَار', exampleWordEn: 'house/home'),
  ArabicLetter(letter: 'ذ', nameAr: 'ذال', nameEn: 'Dhal', pronunciationEn: 'Like "th" in "this"', exampleWordAr: 'ذَهَب', exampleWordEn: 'gold'),
  ArabicLetter(letter: 'ر', nameAr: 'راء', nameEn: 'Ra', pronunciationEn: 'A rolled/trilled "r"', exampleWordAr: 'رَجُل', exampleWordEn: 'man'),
  ArabicLetter(letter: 'ز', nameAr: 'زاي', nameEn: 'Zay', pronunciationEn: 'Like English "z"', exampleWordAr: 'زَيت', exampleWordEn: 'oil'),
  ArabicLetter(letter: 'س', nameAr: 'سين', nameEn: 'Seen', pronunciationEn: 'Like English "s"', exampleWordAr: 'سَمَاء', exampleWordEn: 'sky'),
  ArabicLetter(letter: 'ش', nameAr: 'شين', nameEn: 'Sheen', pronunciationEn: 'Like English "sh"', exampleWordAr: 'شَمس', exampleWordEn: 'sun'),
  ArabicLetter(letter: 'ص', nameAr: 'صاد', nameEn: 'Sad', pronunciationEn: 'An emphatic/heavy "s", pronounced further back in the mouth', exampleWordAr: 'صَبَاح', exampleWordEn: 'morning'),
  ArabicLetter(letter: 'ض', nameAr: 'ضاد', nameEn: 'Dad', pronunciationEn: 'An emphatic/heavy "d" — a sound distinctive to Arabic', exampleWordAr: 'ضَوء', exampleWordEn: 'light'),
  ArabicLetter(letter: 'ط', nameAr: 'طاء', nameEn: 'Ta (emphatic)', pronunciationEn: 'An emphatic/heavy "t"', exampleWordAr: 'طَعَام', exampleWordEn: 'food'),
  ArabicLetter(letter: 'ظ', nameAr: 'ظاء', nameEn: 'Dha (emphatic)', pronunciationEn: 'An emphatic/heavy "th" (as in "this")', exampleWordAr: 'ظُهر', exampleWordEn: 'noon'),
  ArabicLetter(letter: 'ع', nameAr: 'عين', nameEn: '\'Ayn', pronunciationEn: 'A tight throat sound with no English equivalent — practice with audio', exampleWordAr: 'عَين', exampleWordEn: 'eye'),
  ArabicLetter(letter: 'غ', nameAr: 'غين', nameEn: 'Ghayn', pronunciationEn: 'Like a French/German guttural "r" (gargled sound)', exampleWordAr: 'غَيم', exampleWordEn: 'cloud'),
  ArabicLetter(letter: 'ف', nameAr: 'فاء', nameEn: 'Fa', pronunciationEn: 'Like English "f"', exampleWordAr: 'فِيل', exampleWordEn: 'elephant'),
  ArabicLetter(letter: 'ق', nameAr: 'قاف', nameEn: 'Qaf', pronunciationEn: 'A deep "k" sound made further back in the throat', exampleWordAr: 'قَمَر', exampleWordEn: 'moon'),
  ArabicLetter(letter: 'ك', nameAr: 'كاف', nameEn: 'Kaf', pronunciationEn: 'Like English "k"', exampleWordAr: 'كِتَاب', exampleWordEn: 'book'),
  ArabicLetter(letter: 'ل', nameAr: 'لام', nameEn: 'Lam', pronunciationEn: 'Like English "l"', exampleWordAr: 'لَيل', exampleWordEn: 'night'),
  ArabicLetter(letter: 'م', nameAr: 'ميم', nameEn: 'Meem', pronunciationEn: 'Like English "m"', exampleWordAr: 'مَاء', exampleWordEn: 'water'),
  ArabicLetter(letter: 'ن', nameAr: 'نون', nameEn: 'Noon', pronunciationEn: 'Like English "n"', exampleWordAr: 'نَار', exampleWordEn: 'fire'),
  ArabicLetter(letter: 'ه', nameAr: 'هاء', nameEn: 'Ha (light)', pronunciationEn: 'Like English "h"', exampleWordAr: 'هِلَال', exampleWordEn: 'crescent moon'),
  ArabicLetter(letter: 'و', nameAr: 'واو', nameEn: 'Waw', pronunciationEn: 'Like English "w", or a long "oo" as a vowel', exampleWordAr: 'وَرد', exampleWordEn: 'flower/rose'),
  ArabicLetter(letter: 'ي', nameAr: 'ياء', nameEn: 'Ya', pronunciationEn: 'Like English "y", or a long "ee" as a vowel', exampleWordAr: 'يَد', exampleWordEn: 'hand'),
];

class CurriculumStage {
  final String key;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final bool isBuilt;
  const CurriculumStage({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.isBuilt,
  });
}

const curriculumStages = [
  CurriculumStage(
    key: 'alphabet',
    titleAr: 'المرحلة ١: الحروف والنطق',
    titleEn: 'Stage 1: Alphabet & Pronunciation',
    descriptionAr: 'الحروف الثمانية والعشرون، أسماؤها، وكيفية نطقها، مع كلمة مثال لكل حرف.',
    isBuilt: true,
  ),
  CurriculumStage(
    key: 'reading_basics',
    titleAr: 'المرحلة ٢: القراءة الأساسية',
    titleEn: 'Stage 2: Basic Reading',
    descriptionAr: 'الحركات (الفتحة، الضمة، الكسرة)، التنوين، السكون، والمدّ — تكوين المقاطع والكلمات البسيطة.',
    isBuilt: false,
  ),
  CurriculumStage(
    key: 'vocabulary',
    titleAr: 'المرحلة ٣: المفردات الأساسية',
    titleEn: 'Stage 3: Basic Vocabulary',
    descriptionAr: 'كلمات شائعة مصنّفة بالموضوع: التحية، الأسرة، الأرقام، الوقت، مصطلحات إسلامية أساسية.',
    isBuilt: false,
  ),
  CurriculumStage(
    key: 'grammar',
    titleAr: 'المرحلة ٤: القواعد الأساسية',
    titleEn: 'Stage 4: Basic Grammar',
    descriptionAr: 'الاسم والفعل، المذكر والمؤنث، الضمائر، وتركيب الجملة البسيطة.',
    isBuilt: false,
  ),
  CurriculumStage(
    key: 'quranic_comprehension',
    titleAr: 'المرحلة ٥: فهم لغة القرآن',
    titleEn: 'Stage 5: Quranic-Arabic Comprehension',
    descriptionAr: 'تطبيق ما سبق على مفردات وتراكيب قرآنية شائعة، بدءًا بقراءة آيات قصيرة وفهمها مباشرة.',
    isBuilt: false,
  ),
];
