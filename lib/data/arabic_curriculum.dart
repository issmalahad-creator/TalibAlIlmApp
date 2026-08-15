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
/// METHODOLOGY (researched 2026-08-15 before writing this file, per
/// Ismail's explicit request): real, widely-used non-native Arabic
/// curricula — the Madinah Arabic Course (Dr. V. Abdur Rahim, the
/// official Islamic University of Madinah course, sequences grammar
/// alongside Quranic/hadith vocabulary from lesson one) and Al-'Arabiyyah
/// Bayna Yadayk (Dr. Abdul Rahman Al-Fawzan, adopted by 12+ institutions)
/// — informed the STAGE SEQUENCING here (alphabet → reading mechanics →
/// vocabulary → grammar → text comprehension), which is standard
/// pedagogical structure, not copyrighted expression. Stage 3's content
/// is grounded in real Quranic-corpus word-frequency research: the ~100
/// most frequent words cover roughly half of the Quran's running text,
/// and ~500 words cover roughly 85% — so vocabulary here is taught by
/// frequency tier rather than by conversational topic (greetings/food/
/// weather, as general MSA courses do), since this app's goal is
/// Quranic comprehension specifically, not general conversation.
/// `recommendedResources` points learners to the real textbooks above
/// for a fuller, structured course — citation, not reproduction.
///
/// HONEST SCOPE (first pass, not the whole curriculum): Stages 1-3 are
/// populated. Stages 4-5 are outlined with real lesson titles so the
/// roadmap is visible and "شهاداتي" can show the full staged structure,
/// but their actual lesson content is not written yet — each unpopulated
/// stage says so honestly in the UI rather than silently appearing empty.
library;

class RecommendedResource {
  final String titleAr;
  final String titleEn;
  final String authorAr;
  final String noteAr;
  const RecommendedResource({required this.titleAr, required this.titleEn, required this.authorAr, required this.noteAr});
}

const recommendedResources = [
  RecommendedResource(
    titleAr: 'دروس اللغة العربية (سلسلة المدينة)',
    titleEn: 'Arabic Course for English-Speaking Students (Madinah Arabic Course)',
    authorAr: 'د. عبد الرحيم الطاهر (الجامعة الإسلامية بالمدينة المنورة)',
    noteAr: 'ثلاثة مجلدات، المنهج الرسمي للجامعة الإسلامية بالمدينة، يمزج القواعد بمفردات قرآنية وحديثية من الدرس الأول — متاح مجانًا على الإنترنت.',
  ),
  RecommendedResource(
    titleAr: 'العربية بين يديك',
    titleEn: "Al-'Arabiyyah Bayna Yadayk (Arabic Between Your Hands)",
    authorAr: 'د. عبدالرحمن الفوزان وآخرون',
    noteAr: 'سلسلة من 4 مستويات، معتمدة في أكثر من 12 جامعة ومعهدًا عالميًا، تنمّي المهارات الأربع (استماع، كلام، قراءة، كتابة) من الصفر.',
  ),
];

class HarakatLesson {
  final String symbolAr;
  final String nameAr;
  final String explanationEn;
  final String exampleAr;
  const HarakatLesson({required this.symbolAr, required this.nameAr, required this.explanationEn, required this.exampleAr});
}

const harakatLessons = [
  HarakatLesson(symbolAr: 'بَ', nameAr: 'الفتحة', explanationEn: 'A short "a" sound after the letter', exampleAr: 'بَ = "ba"'),
  HarakatLesson(symbolAr: 'بُ', nameAr: 'الضمة', explanationEn: 'A short "u" sound after the letter', exampleAr: 'بُ = "bu"'),
  HarakatLesson(symbolAr: 'بِ', nameAr: 'الكسرة', explanationEn: 'A short "i" sound after the letter', exampleAr: 'بِ = "bi"'),
  HarakatLesson(symbolAr: 'بْ', nameAr: 'السكون', explanationEn: 'No vowel sound at all — the letter is "closed"', exampleAr: 'بْ = "b" (no vowel)'),
  HarakatLesson(symbolAr: 'بَا', nameAr: 'مدّ بالألف', explanationEn: 'A long "aa" sound (fatha followed by alif)', exampleAr: 'بَا = "baa"'),
  HarakatLesson(symbolAr: 'بُو', nameAr: 'مدّ بالواو', explanationEn: 'A long "oo" sound (damma followed by waw)', exampleAr: 'بُو = "boo"'),
  HarakatLesson(symbolAr: 'بِي', nameAr: 'مدّ بالياء', explanationEn: 'A long "ee" sound (kasra followed by ya)', exampleAr: 'بِي = "bee"'),
  HarakatLesson(symbolAr: 'بَنْ', nameAr: 'تنوين الفتح', explanationEn: 'Doubled fatha at a word\'s end — adds an "n" sound: "an"', exampleAr: 'بًا = "ban"'),
  HarakatLesson(symbolAr: 'بُنْ', nameAr: 'تنوين الضم', explanationEn: 'Doubled damma at a word\'s end — adds an "n" sound: "un"', exampleAr: 'بٌ = "bun"'),
  HarakatLesson(symbolAr: 'بِنْ', nameAr: 'تنوين الكسر', explanationEn: 'Doubled kasra at a word\'s end — adds an "n" sound: "in"', exampleAr: 'بٍ = "bin"'),
  HarakatLesson(symbolAr: 'بّ', nameAr: 'الشدّة', explanationEn: 'Doubles the letter\'s sound (it\'s pronounced twice/held)', exampleAr: 'بَّ = "bba"'),
];

class VocabWord {
  final String wordAr;
  final String meaningEn;
  final String tier; // 'tier1' | 'tier2' | 'tier3'
  const VocabWord({required this.wordAr, required this.meaningEn, required this.tier});
}

/// Grouped by Quranic-corpus frequency tier (see the file-level doc
/// comment for the research this is grounded in) rather than by
/// conversational topic — tier 1 alone (~20 of the ~100 highest-
/// frequency words) already appears in a large share of Quranic verses.
const quranicVocabulary = [
  // Tier 1 — extremely high frequency (particles, core nouns/verbs)
  VocabWord(wordAr: 'اللَّه', meaningEn: 'Allah / God', tier: 'tier1'),
  VocabWord(wordAr: 'مِن', meaningEn: 'from', tier: 'tier1'),
  VocabWord(wordAr: 'فِي', meaningEn: 'in', tier: 'tier1'),
  VocabWord(wordAr: 'عَلَى', meaningEn: 'on / upon', tier: 'tier1'),
  VocabWord(wordAr: 'إِلَى', meaningEn: 'to / towards', tier: 'tier1'),
  VocabWord(wordAr: 'الَّذِينَ', meaningEn: 'those who (plural)', tier: 'tier1'),
  VocabWord(wordAr: 'الَّذِي', meaningEn: 'who / which (singular)', tier: 'tier1'),
  VocabWord(wordAr: 'مَا', meaningEn: 'what / that which / not', tier: 'tier1'),
  VocabWord(wordAr: 'لَا', meaningEn: 'no / not', tier: 'tier1'),
  VocabWord(wordAr: 'إِنَّ', meaningEn: 'indeed / verily', tier: 'tier1'),
  VocabWord(wordAr: 'أَن', meaningEn: 'that (introducing a clause)', tier: 'tier1'),
  VocabWord(wordAr: 'كَانَ', meaningEn: 'he/it was', tier: 'tier1'),
  VocabWord(wordAr: 'قَالَ', meaningEn: 'he said', tier: 'tier1'),
  VocabWord(wordAr: 'رَبّ', meaningEn: 'Lord', tier: 'tier1'),
  VocabWord(wordAr: 'يَوْم', meaningEn: 'day', tier: 'tier1'),
  VocabWord(wordAr: 'النَّاس', meaningEn: 'mankind / people', tier: 'tier1'),
  VocabWord(wordAr: 'هُوَ', meaningEn: 'he / it', tier: 'tier1'),
  VocabWord(wordAr: 'هُم', meaningEn: 'they', tier: 'tier1'),
  VocabWord(wordAr: 'كُلّ', meaningEn: 'every / all', tier: 'tier1'),
  VocabWord(wordAr: 'بَيْن', meaningEn: 'between', tier: 'tier1'),
  // Tier 2 — high frequency (places, key concepts)
  VocabWord(wordAr: 'الْأَرْض', meaningEn: 'the earth', tier: 'tier2'),
  VocabWord(wordAr: 'السَّمَاء', meaningEn: 'the sky / heaven', tier: 'tier2'),
  VocabWord(wordAr: 'عَبْد', meaningEn: 'servant / slave (of God)', tier: 'tier2'),
  VocabWord(wordAr: 'رَحْمَة', meaningEn: 'mercy', tier: 'tier2'),
  VocabWord(wordAr: 'عَذَاب', meaningEn: 'punishment', tier: 'tier2'),
  VocabWord(wordAr: 'جَنَّة', meaningEn: 'garden / paradise', tier: 'tier2'),
  VocabWord(wordAr: 'نَار', meaningEn: 'fire', tier: 'tier2'),
  VocabWord(wordAr: 'إِيمَان', meaningEn: 'faith / belief', tier: 'tier2'),
  VocabWord(wordAr: 'صَلَاة', meaningEn: 'prayer', tier: 'tier2'),
  VocabWord(wordAr: 'صَبْر', meaningEn: 'patience', tier: 'tier2'),
  VocabWord(wordAr: 'قَلْب', meaningEn: 'heart', tier: 'tier2'),
  VocabWord(wordAr: 'نَفْس', meaningEn: 'soul / self', tier: 'tier2'),
  VocabWord(wordAr: 'كِتَاب', meaningEn: 'book / scripture', tier: 'tier2'),
  VocabWord(wordAr: 'رَسُول', meaningEn: 'messenger', tier: 'tier2'),
  VocabWord(wordAr: 'نَبِيّ', meaningEn: 'prophet', tier: 'tier2'),
  VocabWord(wordAr: 'قَوْم', meaningEn: 'a people / nation', tier: 'tier2'),
  VocabWord(wordAr: 'بَيْت', meaningEn: 'house', tier: 'tier2'),
  VocabWord(wordAr: 'مَاء', meaningEn: 'water', tier: 'tier2'),
  VocabWord(wordAr: 'عِلْم', meaningEn: 'knowledge', tier: 'tier2'),
  VocabWord(wordAr: 'حَقّ', meaningEn: 'truth / right', tier: 'tier2'),
  // Tier 3 — supporting frequency (body/senses, daily concepts)
  VocabWord(wordAr: 'خَيْر', meaningEn: 'good / goodness', tier: 'tier3'),
  VocabWord(wordAr: 'شَيْء', meaningEn: 'thing', tier: 'tier3'),
  VocabWord(wordAr: 'أَخ', meaningEn: 'brother', tier: 'tier3'),
  VocabWord(wordAr: 'ابْن', meaningEn: 'son', tier: 'tier3'),
  VocabWord(wordAr: 'عَيْن', meaningEn: 'eye', tier: 'tier3'),
  VocabWord(wordAr: 'يَد', meaningEn: 'hand', tier: 'tier3'),
  VocabWord(wordAr: 'وَجْه', meaningEn: 'face', tier: 'tier3'),
  VocabWord(wordAr: 'سَمْع', meaningEn: 'hearing', tier: 'tier3'),
  VocabWord(wordAr: 'بَصَر', meaningEn: 'sight', tier: 'tier3'),
  VocabWord(wordAr: 'مَوْت', meaningEn: 'death', tier: 'tier3'),
  VocabWord(wordAr: 'حَيَاة', meaningEn: 'life', tier: 'tier3'),
  VocabWord(wordAr: 'حَمْد', meaningEn: 'praise', tier: 'tier3'),
  VocabWord(wordAr: 'سَلَام', meaningEn: 'peace', tier: 'tier3'),
  VocabWord(wordAr: 'رِزْق', meaningEn: 'provision / sustenance', tier: 'tier3'),
  VocabWord(wordAr: 'خَلْق', meaningEn: 'creation', tier: 'tier3'),
  VocabWord(wordAr: 'مَلَك', meaningEn: 'angel', tier: 'tier3'),
  VocabWord(wordAr: 'شَيْطَان', meaningEn: 'devil / satan', tier: 'tier3'),
  VocabWord(wordAr: 'دُنْيَا', meaningEn: 'this worldly life', tier: 'tier3'),
  VocabWord(wordAr: 'آخِرَة', meaningEn: 'the hereafter', tier: 'tier3'),
  VocabWord(wordAr: 'هُدَى', meaningEn: 'guidance', tier: 'tier3'),
];

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

class GrammarConcept {
  final String titleAr;
  final String titleEn;
  final String explanationEn;
  final String exampleAr;
  final String exampleEn;
  const GrammarConcept({
    required this.titleAr,
    required this.titleEn,
    required this.explanationEn,
    required this.exampleAr,
    required this.exampleEn,
  });
}

/// Sequenced the way Madinah Arabic Course / Bayna Yadayk introduce basic
/// grammar (parts of speech → gender/number → pronouns → sentence
/// structure → possession → prepositions → verb tenses) — standard
/// pedagogical order, written here in original explanations.
const grammarConcepts = [
  GrammarConcept(
    titleAr: 'الاسم والفعل والحرف',
    titleEn: 'Noun, Verb, and Particle',
    explanationEn: 'Every Arabic word is one of three types: اسم (noun — a person/thing/place, e.g. كِتَاب "book"), فِعل (verb — an action, e.g. كَتَبَ "he wrote"), or حَرْف (particle — a small connecting word like فِي "in" that never changes form).',
    exampleAr: 'كِتَاب (اسم) — كَتَبَ (فعل) — فِي (حرف)',
    exampleEn: 'book (noun) — he wrote (verb) — in (particle)',
  ),
  GrammarConcept(
    titleAr: 'المذكر والمؤنث',
    titleEn: 'Masculine and Feminine',
    explanationEn: 'Every Arabic noun is either masculine (مذكر) or feminine (مؤنث). Most feminine nouns end in ة (taa marbuta). This affects the form of adjectives and verbs that go with the noun.',
    exampleAr: 'مُسْلِم (مذكر) — مُسْلِمَة (مؤنث)',
    exampleEn: 'a Muslim man (masculine) — a Muslim woman (feminine)',
  ),
  GrammarConcept(
    titleAr: 'المفرد والمثنى والجمع',
    titleEn: 'Singular, Dual, and Plural',
    explanationEn: 'Arabic has THREE number forms, not just two: مفرد (singular, one), مثنى (dual, exactly two — ends in ـَان), and جمع (plural, three or more).',
    exampleAr: 'كِتَاب (مفرد) — كِتَابَان (مثنى) — كُتُب (جمع)',
    exampleEn: 'one book (singular) — two books (dual) — books (plural)',
  ),
  GrammarConcept(
    titleAr: 'الضمائر المنفصلة',
    titleEn: 'Detached Pronouns',
    explanationEn: 'These stand alone as the subject of a sentence, similar to "I / you / he" in English — but Arabic distinguishes gender and dual number too.',
    exampleAr: 'أَنَا، أَنْتَ، أَنْتِ، هُوَ، هِيَ، نَحْنُ، أَنْتُمْ، هُم',
    exampleEn: 'I, you (m.), you (f.), he, she, we, you (pl.), they',
  ),
  GrammarConcept(
    titleAr: 'اسم الإشارة',
    titleEn: 'Demonstratives ("this/that")',
    explanationEn: 'Words that point to something, matching its gender.',
    exampleAr: 'هَذَا كِتَاب — هَذِهِ سَاعَة',
    exampleEn: 'This is a book — This is a watch (feminine noun)',
  ),
  GrammarConcept(
    titleAr: 'الجملة الاسمية',
    titleEn: 'The Nominal Sentence',
    explanationEn: 'Arabic\'s most basic sentence type has no verb "to be" — you simply place a subject (مبتدأ) next to its description (خبر), and "is/are" is understood.',
    exampleAr: 'الْبَيْتُ كَبِيرٌ',
    exampleEn: 'The house [is] big',
  ),
  GrammarConcept(
    titleAr: 'الإضافة',
    titleEn: 'The Possessive Construct (Idafa)',
    explanationEn: 'To show possession ("the X of Y"), two nouns are placed directly next to each other — no separate word for "of".',
    exampleAr: 'كِتَابُ الطَّالِبِ',
    exampleEn: 'the student\'s book (literally: book-of the-student)',
  ),
  GrammarConcept(
    titleAr: 'حروف الجر',
    titleEn: 'Prepositions',
    explanationEn: 'Small particles that come before a noun and never change form. Already familiar from Stage 3\'s vocabulary: مِن، فِي، عَلَى، إِلَى.',
    exampleAr: 'فِي الْبَيْتِ — عَلَى الْأَرْضِ',
    exampleEn: 'in the house — on the earth',
  ),
  GrammarConcept(
    titleAr: 'الفعل الماضي',
    titleEn: 'The Past Tense Verb',
    explanationEn: 'Describes a completed action. The verb\'s ending changes depending on who did the action (a suffix is added, unlike English which mostly doesn\'t change).',
    exampleAr: 'كَتَبَ (هو) — كَتَبَتْ (هي) — كَتَبْتُ (أنا)',
    exampleEn: 'he wrote — she wrote — I wrote',
  ),
  GrammarConcept(
    titleAr: 'الفعل المضارع',
    titleEn: 'The Present Tense Verb',
    explanationEn: 'Describes an ongoing or habitual action. Unlike the past tense, the CHANGE happens at the beginning of the verb (a prefix), not just the end.',
    exampleAr: 'يَكْتُبُ (هو) — تَكْتُبُ (هي) — أَكْتُبُ (أنا)',
    exampleEn: 'he writes — she writes — I write',
  ),
];

class WordGloss {
  final String wordAr;
  final String meaningEn;
  const WordGloss({required this.wordAr, required this.meaningEn});
}

class QuranicAyahLesson {
  final int ayahNumber;
  final String textAr;
  final List<WordGloss> words;
  const QuranicAyahLesson({required this.ayahNumber, required this.textAr, required this.words});
}

class QuranicTextLesson {
  final String surahNameAr;
  final String surahNameEn;
  final int surahNumber;
  final List<QuranicAyahLesson> ayat;
  const QuranicTextLesson({required this.surahNameAr, required this.surahNameEn, required this.surahNumber, required this.ayat});
}

/// Stage 5: direct application on two of the shortest, most widely known
/// surahs — word-by-word breakdowns written originally for this app,
/// reusing Stage 3's vocabulary wherever the same word appears. The ayah
/// text itself is the same verbatim Tanzil Uthmani text (CC-BY 3.0)
/// already bundled and imported into this app's `quran_ayat` table
/// earlier in this project — not new/separately-sourced content.
const quranicTextLessons = [
  QuranicTextLesson(
    surahNameAr: 'سورة الفاتحة',
    surahNameEn: 'Al-Fatihah (The Opening)',
    surahNumber: 1,
    ayat: [
      QuranicAyahLesson(ayahNumber: 1, textAr: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', words: [
        WordGloss(wordAr: 'بِسْمِ', meaningEn: 'in the name of'),
        WordGloss(wordAr: 'اللَّهِ', meaningEn: 'Allah'),
        WordGloss(wordAr: 'الرَّحْمَٰنِ', meaningEn: 'the Most Merciful'),
        WordGloss(wordAr: 'الرَّحِيمِ', meaningEn: 'the Especially Merciful'),
      ]),
      QuranicAyahLesson(ayahNumber: 2, textAr: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', words: [
        WordGloss(wordAr: 'الْحَمْدُ', meaningEn: 'all praise'),
        WordGloss(wordAr: 'لِلَّهِ', meaningEn: 'is for Allah'),
        WordGloss(wordAr: 'رَبِّ', meaningEn: 'Lord of'),
        WordGloss(wordAr: 'الْعَالَمِينَ', meaningEn: 'all the worlds'),
      ]),
      QuranicAyahLesson(ayahNumber: 3, textAr: 'الرَّحْمَٰنِ الرَّحِيمِ', words: [
        WordGloss(wordAr: 'الرَّحْمَٰنِ', meaningEn: 'the Most Merciful'),
        WordGloss(wordAr: 'الرَّحِيمِ', meaningEn: 'the Especially Merciful'),
      ]),
      QuranicAyahLesson(ayahNumber: 4, textAr: 'مَالِكِ يَوْمِ الدِّينِ', words: [
        WordGloss(wordAr: 'مَالِكِ', meaningEn: 'Master/Owner of'),
        WordGloss(wordAr: 'يَوْمِ', meaningEn: 'the Day of'),
        WordGloss(wordAr: 'الدِّينِ', meaningEn: 'Judgment/Recompense'),
      ]),
      QuranicAyahLesson(ayahNumber: 5, textAr: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', words: [
        WordGloss(wordAr: 'إِيَّاكَ', meaningEn: 'You alone'),
        WordGloss(wordAr: 'نَعْبُدُ', meaningEn: 'we worship'),
        WordGloss(wordAr: 'وَإِيَّاكَ', meaningEn: 'and You alone'),
        WordGloss(wordAr: 'نَسْتَعِينُ', meaningEn: 'we ask for help'),
      ]),
      QuranicAyahLesson(ayahNumber: 6, textAr: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', words: [
        WordGloss(wordAr: 'اهْدِنَا', meaningEn: 'guide us'),
        WordGloss(wordAr: 'الصِّرَاطَ', meaningEn: 'the path'),
        WordGloss(wordAr: 'الْمُسْتَقِيمَ', meaningEn: 'the straight'),
      ]),
      QuranicAyahLesson(ayahNumber: 7, textAr: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ', words: [
        WordGloss(wordAr: 'صِرَاطَ الَّذِينَ', meaningEn: 'the path of those'),
        WordGloss(wordAr: 'أَنْعَمْتَ عَلَيْهِمْ', meaningEn: 'You have favored'),
        WordGloss(wordAr: 'غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ', meaningEn: 'not of those who have earned [Your] anger'),
        WordGloss(wordAr: 'وَلَا الضَّالِّينَ', meaningEn: 'nor of those who are astray'),
      ]),
    ],
  ),
  QuranicTextLesson(
    surahNameAr: 'سورة الإخلاص',
    surahNameEn: 'Al-Ikhlas (Sincerity)',
    surahNumber: 112,
    ayat: [
      QuranicAyahLesson(ayahNumber: 1, textAr: 'قُلْ هُوَ اللَّهُ أَحَدٌ', words: [
        WordGloss(wordAr: 'قُلْ', meaningEn: 'say'),
        WordGloss(wordAr: 'هُوَ اللَّهُ', meaningEn: 'He is Allah'),
        WordGloss(wordAr: 'أَحَدٌ', meaningEn: 'One'),
      ]),
      QuranicAyahLesson(ayahNumber: 2, textAr: 'اللَّهُ الصَّمَدُ', words: [
        WordGloss(wordAr: 'اللَّهُ', meaningEn: 'Allah'),
        WordGloss(wordAr: 'الصَّمَدُ', meaningEn: 'the Eternal Refuge (depended upon by all, dependent on none)'),
      ]),
      QuranicAyahLesson(ayahNumber: 3, textAr: 'لَمْ يَلِدْ وَلَمْ يُولَدْ', words: [
        WordGloss(wordAr: 'لَمْ يَلِدْ', meaningEn: 'He does not beget'),
        WordGloss(wordAr: 'وَلَمْ يُولَدْ', meaningEn: 'nor is He begotten'),
      ]),
      QuranicAyahLesson(ayahNumber: 4, textAr: 'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ', words: [
        WordGloss(wordAr: 'وَلَمْ يَكُن لَّهُ', meaningEn: 'and there is not for Him'),
        WordGloss(wordAr: 'كُفُوًا أَحَدٌ', meaningEn: 'any equivalent/equal'),
      ]),
    ],
  ),
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
    isBuilt: true,
  ),
  CurriculumStage(
    key: 'vocabulary',
    titleAr: 'المرحلة ٣: أكثر كلمات القرآن تكرارًا',
    titleEn: 'Stage 3: Most Frequent Quranic Words',
    descriptionAr: 'أهم المفردات مرتبة حسب تكرارها في القرآن — أول ١٠٠ كلمة تغطي نحو نصف نص القرآن تقريبًا.',
    isBuilt: true,
  ),
  CurriculumStage(
    key: 'grammar',
    titleAr: 'المرحلة ٤: القواعد الأساسية',
    titleEn: 'Stage 4: Basic Grammar',
    descriptionAr: 'الاسم والفعل، المذكر والمؤنث، الضمائر، وتركيب الجملة البسيطة.',
    isBuilt: true,
  ),
  CurriculumStage(
    key: 'quranic_comprehension',
    titleAr: 'المرحلة ٥: فهم لغة القرآن',
    titleEn: 'Stage 5: Quranic-Arabic Comprehension',
    descriptionAr: 'تطبيق ما سبق على سورتين قصيرتين معروفتين، كلمة بكلمة: الفاتحة والإخلاص.',
    isBuilt: true,
  ),
];
