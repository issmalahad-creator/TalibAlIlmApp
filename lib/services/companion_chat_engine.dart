import 'dart:math';

import '../utils/arabic_normalize.dart';
import '../utils/fuzzy_match.dart' as fuzzy;

/// "محادثة الرفيق" — QURAN_COMPANION_ROADMAP.md §4.36, Ismail's 2026-08-18
/// request for a companion the student can actually type to, without any
/// real language model (cloud or local). Pure keyword/intent matching, same
/// spirit as `companion_engine.dart`: every response is pre-written, this
/// only picks which one applies. No generation, no hallucination risk, no
/// dependency heavier than Dart itself — runs identically on any phone.
///
/// Matching is deliberately simple and inspectable: normalize the input
/// (reusing `normalizeArabicForSearch` for Arabic — the same
/// diacritic/letter-variant stripping already trusted for Quran search;
/// plain lowercase/trim for other languages), then score each intent by how
/// many of its keywords appear as a substring. Highest score wins; ties
/// keep whichever intent was checked first (catalog order = priority, same
/// explicit-order philosophy as `companion_engine.dart`'s if-chain).
///
/// Language support ("باي لغه كانت هل هاذا ممكن" — Ismail, 2026-08-18): yes,
/// architecturally — each intent carries a keyword/response set per
/// language code, matching `LanguagePreferenceService.frameworkSupportedLanguages`.
/// Content is only authored for 'ar' and 'en' so far; requesting any other
/// language code falls back to 'ar' rather than failing silently. Filling
/// in the remaining languages is the same "حبة حبة" sweep already used for
/// the rest of the app's UI strings — a follow-up step, not guessed now.
class CompanionIntent {
  final String id;
  final Map<String, List<String>> keywordsByLang;
  final Map<String, List<String>> responsesByLang;
  const CompanionIntent({required this.id, required this.keywordsByLang, required this.responsesByLang});

  List<String> keywordsFor(String lang) => keywordsByLang[lang] ?? keywordsByLang['ar']!;
  List<String> responsesFor(String lang) => responsesByLang[lang] ?? responsesByLang['ar']!;
}

/// Confidence below this never gets a response — the "لم أفهم" honest
/// fallback fires instead of guessing off a coincidental single-word
/// overlap (root cause of the "كم أنجزت" → wrong-intent bug found live on
/// Ismail's device, 2026-08-18 — the fix there was per-callsite; this is
/// the general-purpose version of the same fix, built into the engine
/// itself). 1.0 = full keyword/phrase match, 0.6 = fuzzy-only match (typo
/// tolerance), 0 = nothing.
const _confidenceThreshold = 0.6;

/// Each inner list is one concept; the first word is the canonical form
/// every other word in the group collapses to before matching. Deliberately
/// small and scoped to concepts already used by the current catalog — not a
/// general-purpose Arabic thesaurus, which would need native-speaker review
/// to build responsibly.
const _arabicSynonymGroups = [
  ['انجزت', 'خلصت', 'سويت', 'حققت', 'كملت'],
  ['باقي', 'تبقى', 'متبقي', 'متبقية'],
  ['تقدمي', 'تقدم'],
];

const _arabicNegationWords = {'لا', 'ما', 'لم', 'لن', 'مو', 'مب', 'ليس', 'مش'};

class CompanionChatEngine {
  final List<CompanionIntent> intents;
  final Random _random;
  CompanionChatEngine({List<CompanionIntent>? intents, Random? random})
      : intents = intents ?? defaultCompanionIntents,
        _random = random ?? Random();

  /// Returns a response, or null if nothing matched clearly enough — the
  /// caller decides what an honest "didn't understand" message looks like,
  /// same "say nothing rather than guess" rule as `companion_engine.dart`.
  String? respond(String userText, {String lang = 'ar'}) => match(userText, lang: lang).$2;

  /// The matched intent's id for [userText], or null — used by the session
  /// wrapper to log history without duplicating the matching logic.
  String? matchIntentId(String userText, {String lang = 'ar'}) => match(userText, lang: lang).$1;

  /// Matches [userText] and returns both which intent matched and the
  /// chosen response — the single source of truth `respond`/`matchIntentId`
  /// both read from, so a caller needing both never scores the catalog twice.
  (String? intentId, String? response) match(String userText, {String lang = 'ar'}) {
    final (id, confidence) = matchWithConfidence(userText, lang: lang);
    if (id == null || confidence < _confidenceThreshold) return (null, null);
    final intent = intents.firstWhere((i) => i.id == id);
    final responses = intent.responsesFor(lang);
    return (id, responses[_random.nextInt(responses.length)]);
  }

  /// Two-layer matching (Ismail's 2026-08-18 "محرك فهم نوايا متعدد
  /// الطبقات" request, scoped to what's honestly buildable without a real
  /// ML model): (1) exact phrase/substring containment — score 1.0; (2)
  /// fuzzy word-level matching via edit distance — score 0.6, catches
  /// typos like "تعبن" for "تعبان" without needing every misspelling
  /// listed as its own keyword. "Semantic similarity" (understanding
  /// unrelated-looking phrases mean the same thing without shared words)
  /// deliberately stops here rather than reaching for embeddings — that
  /// needs a real model, which breaks the "no AI, runs on any phone"
  /// constraint this whole feature exists under. The honest equivalent
  /// within that constraint is a bigger curated keyword/phrase list per
  /// intent, grown from real usage (`companion_chat_log`) — not a hidden
  /// similarity model.
  (String? intentId, double confidence) matchWithConfidence(String userText, {String lang = 'ar'}) {
    // Scans in catalog order with a strict `>` so ties resolve to whichever
    // intent appears first in `intents` — same deterministic tie-break as
    // before this method existed. `List.sort` isn't guaranteed stable, so
    // `debugScores()`'s sorted view is for display only, never for this
    // decision.
    final scores = _scoreAllIntents(userText, lang);
    if (scores.isEmpty) return (null, 0);
    String? bestId;
    var bestScore = 0.0;
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestId = entry.key;
      }
    }
    return (bestId, bestScore);
  }

  /// Every intent's raw score for [userText], highest first — the debug
  /// view (`CompanionDebugScreen`) reads this directly so what it shows is
  /// never a re-implementation that could drift from the real matcher, only
  /// a different view of the exact same computation `match()` uses.
  List<MapEntry<String, double>> debugScores(String userText, {String lang = 'ar'}) {
    final scores = _scoreAllIntents(userText, lang);
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  Map<String, double> _scoreAllIntents(String userText, String lang) {
    final normalized = _normalize(userText.trim(), lang);
    if (normalized.isEmpty) return {};
    final inputWords = normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    final scores = <String, double>{};
    for (final intent in intents) {
      var intentScore = 0.0;
      for (final keyword in intent.keywordsFor(lang)) {
        final normKeyword = _normalize(keyword, lang);
        final kwWords = normKeyword.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        final keywordScore = kwWords.length == 1
            ? _scoreSingleWordKeyword(kwWords.first, inputWords, lang)
            : _scoreMultiWordKeyword(normalized, normKeyword, kwWords, inputWords);
        if (keywordScore > intentScore) intentScore = keywordScore;
      }
      scores[intent.id] = intentScore;
    }
    return scores;
  }

  /// A single-word keyword ("تعبان", "انجزت") is checked against every
  /// input word at its own position, exact first then fuzzy — and negation
  /// is checked at THAT position for either kind of match. This is the fix
  /// for a real bug found live on Ismail's device (2026-08-18): the
  /// previous version only guarded the exact-match path, so a negated exact
  /// match ("ما انجزت") fell through to the fuzzy branch — which finds
  /// "انجزت" in the input regardless of the "ما" right before it — and
  /// matched anyway. Multi-word phrase keywords are handled separately
  /// (`_scoreMultiWordKeyword`) since some are deliberately negation-shaped
  /// already (e.g. "ما اقدر احفظ").
  double _scoreSingleWordKeyword(String keyword, List<String> inputWords, String lang) {
    for (var i = 0; i < inputWords.length; i++) {
      final isExact = inputWords[i] == keyword;
      final isFuzzy = !isExact && fuzzy.isFuzzyMatch(inputWords[i], keyword);
      if (!isExact && !isFuzzy) continue;
      if (_isNegatedAt(inputWords, i, lang)) continue;
      return isExact ? 1.0 : 0.6;
    }
    return 0.0;
  }

  double _scoreMultiWordKeyword(String normalized, String normKeyword, List<String> kwWords, List<String> inputWords) {
    if (normalized.contains(normKeyword)) return 1.0;
    final allWordsFuzzyMatched = kwWords.every((kw) => inputWords.any((w) => fuzzy.isFuzzyMatch(w, kw)));
    return allWordsFuzzyMatched ? 0.6 : 0.0;
  }

  /// True if a negation word appears in the 2 words immediately before
  /// `inputWords[index]`.
  bool _isNegatedAt(List<String> inputWords, int index, String lang) {
    if (lang != 'ar' || index == 0) return false;
    final start = index - 2 < 0 ? 0 : index - 2;
    return inputWords.sublist(start, index).any(_arabicNegationWords.contains);
  }

  /// Collapses runs of the same letter repeated 3+ times ("مراااحب" →
  /// "مراحب") before the rest of normalization runs — cheap, real coverage
  /// gain for emphatic/informal typing, kept local to this file rather than
  /// folded into `normalizeArabicForSearch` (that function is shared with
  /// Quran search, where this behavior isn't relevant and shouldn't be
  /// risked).
  String _normalize(String text, String lang) {
    final collapsed = text.replaceAllMapped(RegExp(r'(.)\1{2,}'), (m) => m.group(1)!);
    final base = lang == 'ar' ? normalizeArabicForSearch(collapsed) : collapsed.toLowerCase();
    return lang == 'ar' ? _applyArabicSynonyms(base) : base;
  }

  /// Small, curated synonym layer (Arabic only — the language we can
  /// actually vouch for) covering concepts already present in the catalog,
  /// not a blind blanket dictionary. Each group's words are replaced with
  /// the group's first entry before matching, so e.g. "خلصت"/"سويت" reach
  /// the same keyword as "انجزت" without every intent needing every
  /// synonym listed separately.
  String _applyArabicSynonyms(String normalizedText) {
    var result = normalizedText;
    for (final group in _arabicSynonymGroups) {
      final canonical = group.first;
      for (final variant in group.skip(1)) {
        result = result.replaceAll(RegExp('\\b$variant\\b'), canonical);
      }
    }
    return result;
  }
}

/// Starter catalog — real, common things a student might actually type,
/// not an exhaustive list. Expanded in later increments based on real use,
/// not guessed upfront (matches the roadmap's own "خطوة قوية كل يوم" plan).
const defaultCompanionIntents = <CompanionIntent>[
  CompanionIntent(
    id: 'greeting',
    keywordsByLang: {
      'ar': [
        'السلام عليكم', 'مرحبا', 'هلا', 'صباح الخير', 'مساء الخير', 'هاي',
        'كيف حالك', 'اهلا وسهلا', 'صباح النور', 'مساء النور', 'هلا والله',
      ],
      'en': ['hello', 'hi', 'salam', 'good morning', 'good evening', 'hey'],
    },
    responsesByLang: {
      'ar': [
        'وعليكم السلام ورحمة الله 🤍 كيف حالك مع القرآن اليوم؟',
        'أهلًا بك! جاهز لخطوة جديدة اليوم؟',
        'حياك الله — أخبرني كيف يومك؟',
      ],
      'en': [
        'Wa alaikum salam 🤍 How are you doing with the Quran today?',
        'Hey! Ready for a new step today?',
        'Welcome — tell me how your day is going.',
      ],
    },
  ),
  CompanionIntent(
    id: 'tiredness',
    keywordsByLang: {
      'ar': ['تعبان', 'متعب', 'مرهق', 'ما عندي طاقة', 'كسلان', 'مافي رغبة', 'خمول', 'ماعندي حيل', 'منهك', 'تعبت كثير'],
      'en': ['tired', 'exhausted', 'no energy', 'lazy', 'burnt out'],
    },
    responsesByLang: {
      'ar': [
        'التعب طبيعي جدًا — لا تحاول تعويض كل شيء اليوم، خطوة صغيرة تكفي.',
        'لا بأس أن تكون متعبًا. حتى صفحة واحدة اليوم خير من لا شيء.',
        'استرح قليلًا إن احتجت — القرآن لن يهرب منك، والاستمرار المعتدل أهم من الاندفاع.',
      ],
      'en': [
        'Being tired is completely normal — don\'t try to make up for everything today, a small step is enough.',
        'It\'s okay to be tired. Even one page today is better than none.',
        'Rest if you need to — steady, moderate effort beats a rushed burst every time.',
      ],
    },
  ),
  CompanionIntent(
    id: 'memorization_difficulty',
    keywordsByLang: {
      'ar': [
        'صعب احفظ', 'ما اقدر احفظ', 'نسيت', 'صعوبة في الحفظ', 'ما يثبت معي',
        'بنسى بسرعة', 'يصعب علي الحفظ', 'ما يرسخ', 'احفظ وانسى',
      ],
      'en': ['hard to memorize', 'can\'t memorize', 'i forgot', 'struggling to memorize'],
    },
    responsesByLang: {
      'ar': [
        'النسيان جزء طبيعي من الحفظ — المراجعة المتكررة هي ما يثبّت، لا الحفظ نفسه.',
        'جرّب تقسيم الصفحة لمقاطع أصغر وتكرار كل مقطع لوحده قبل ربطها.',
        'لا تقارن نفسك بغيرك — كل شخص له وتيرته، والثبات أهم من السرعة.',
      ],
      'en': [
        'Forgetting is a normal part of memorizing — repeated review is what makes it stick, not the first memorization.',
        'Try splitting the page into smaller chunks and repeating each one before connecting them.',
        'Don\'t compare yourself to others — everyone has their own pace, and consistency matters more than speed.',
      ],
    },
  ),
  CompanionIntent(
    id: 'missed_day',
    keywordsByLang: {
      'ar': ['فاتني', 'ما سويت', 'قصرت', 'تاخرت', 'ما التزمت', 'ما فتحت المصحف', 'فوت يوم', 'ما راجعت اليوم', 'نسيت اسمع وردي'],
      'en': ['i missed', 'i didn\'t do it', 'i fell behind', 'i skipped'],
    },
    responsesByLang: {
      'ar': [
        'يوم فائت لا ينهي المسيرة — عد اليوم بخطوة، هذا كل ما يهم.',
        'لا تجلد نفسك — استمرار بسيط بعد الانقطاع أفضل من التوقف تمامًا.',
        'كل واحد يفوته يوم أحيانًا — المهم أنك رجعت الآن.',
      ],
      'en': [
        'One missed day doesn\'t end the journey — come back today with a step, that\'s all that matters.',
        'Don\'t be hard on yourself — a small return beats stopping completely.',
        'Everyone misses a day sometimes — what matters is that you\'re back now.',
      ],
    },
  ),
  CompanionIntent(
    id: 'gratitude',
    keywordsByLang: {
      'ar': ['الحمد لله', 'شكرا', 'بارك الله فيك', 'جزاك الله خير', 'ممتن', 'تسلم', 'الله يعطيك العافية', 'مشكور', 'ربي يبارك فيك'],
      'en': ['thank you', 'thanks', 'grateful', 'alhamdulillah'],
    },
    responsesByLang: {
      'ar': [
        'وإياك — بارك الله فيك ووفّقك.',
        'الحمد لله دائمًا على كل نعمة، وأنت من يبذل الجهد.',
        'جزاك الله خيرًا على همتك.',
      ],
      'en': [
        'You\'re welcome — may Allah bless your effort.',
        'Alhamdulillah, always. You\'re the one putting in the work.',
        'Glad to help — keep that momentum going.',
      ],
    },
  ),
  CompanionIntent(
    id: 'motivation_request',
    keywordsByLang: {
      'ar': ['حفزني', 'شجعني', 'اريد حافز', 'ادعمني', 'ما عندي همة', 'حمسني', 'ادفعني للاستمرار', 'خلني اكمل', 'ابي همة'],
      'en': ['motivate me', 'encourage me', 'i need motivation', 'support me'],
    },
    responsesByLang: {
      'ar': [
        'كل آية تحفظها اليوم تبقى معك — لا يضيع مجهودك مهما بدا صغيرًا.',
        'أنت أقرب لهدفك من أمس، حتى لو لم تشعر بذلك الآن.',
        'ابدأ بخطوة واحدة فقط — الهمّة تأتي مع البدء أحيانًا لا قبله.',
      ],
      'en': [
        'Every verse you memorize today stays with you — your effort is never wasted, however small it feels.',
        'You\'re closer to your goal than you were yesterday, even if it doesn\'t feel that way.',
        'Just start with one small step — motivation often comes after starting, not before.',
      ],
    },
  ),
  CompanionIntent(
    id: 'accomplishment',
    keywordsByLang: {
      'ar': ['انجزت', 'خلصت', 'فرحان', 'سعيد اليوم', 'حفظت', 'انهيت وردي', 'تمت المراجعة', 'فخور بنفسي'],
      'en': ['i finished', 'i did it', 'happy today', 'i memorized'],
    },
    responsesByLang: {
      'ar': [
        'ما شاء الله! أحسنت — واصل على هذا الطريق.',
        'إنجاز حقيقي، بارك الله فيك.',
        'هذا بالضبط ما يبني الاستمرار — تستحق أن تفخر بنفسك.',
      ],
      'en': [
        'MashaAllah! Well done — keep going on this path.',
        'That\'s a real accomplishment, may Allah bless you.',
        'This is exactly what builds consistency — you should be proud.',
      ],
    },
  ),
  CompanionIntent(
    id: 'who_are_you',
    keywordsByLang: {
      'ar': ['مين انت', 'شنو انت', 'من انت', 'ايش انت', 'ايش وظيفتك', 'وش دورك هنا', 'عرفني عن نفسك'],
      'en': ['who are you', 'what are you'],
    },
    responsesByLang: {
      'ar': [
        'أنا رفيق طالب العلم — مساعد بسيط داخل التطبيق، كل ردودي مكتوبة مسبقًا وليست ذكاءً اصطناعيًا، فقط لأتابعك وأشجعك.',
      ],
      'en': [
        'I\'m the Talib Al-Ilm companion — a simple in-app assistant. My replies are pre-written, not real AI, just here to keep track of you and encourage you.',
      ],
    },
  ),
  CompanionIntent(
    id: 'distress',
    keywordsByLang: {
      'ar': [
        'ما اقدر اكمل', 'افكر اترك', 'يئست', 'ملل', 'تعبت نفسيا', 'ضعيف', 'احساس بالضعف', 'ضعف',
        'بدي اتوقف', 'زهقت', 'حاسس اني ما اقدر', 'ملل من الروتين',
      ],
      'en': [
        'i can\'t continue',
        'thinking of quitting',
        'i give up',
        'bored',
        'i\'m done',
        'i feel weak',
        'i feel low',
      ],
    },
    responsesByLang: {
      'ar': [
        'المشاعر هذه طبيعية في أي رحلة طويلة — لا تعني أنك فاشل، فقط تحتاج راحة أو تعديل الوتيرة.',
        'لا بأس أن تبطئ بدل أن تتوقف تمامًا — قلّل الوتيرة إن احتجت.',
        'أنت لست وحدك في هذا الشعور — كثيرون يمرون به ويستمرون. خطوة صغيرة اليوم كافية.',
        'حاول ثلاثة أشياء بسيطة: القليل من الرياضة لتنشيط جسمك، آيات تقرأها بتمهل، واستغفار متكرر — غالبًا يخفف هذا الشعور تدريجيًا.',
      ],
      'en': [
        'These feelings are normal on any long journey — they don\'t mean you\'ve failed, just that you need rest or a pace change.',
        'It\'s okay to slow down instead of stopping completely — ease the pace if you need to.',
        'You\'re not alone in this feeling — many go through it and keep going. One small step today is enough.',
        'Try three simple things: a bit of exercise to wake your body up, a few verses read slowly, and repeated istighfar — this often eases the feeling gradually.',
      ],
    },
  ),
  CompanionIntent(
    id: 'general_advice',
    keywordsByLang: {
      'ar': ['انصحني', 'اعطني نصيحة', 'وصية', 'نصيحة لي', 'ايش تنصحني', 'علمني شي', 'قول لي شي مفيد', 'ذكرني بشي جميل', 'اعطني حكمة'],
      'en': ['advise me', 'give me advice', 'any advice', 'advice for me'],
    },
    responsesByLang: {
      'ar': [
        'ابتعد عن رفقاء السوء قدر استطاعتك — الصاحب ساحب، والرفقة الصالحة تعينك على الثبات.',
        'حافظ على صلاة الجماعة ما استطعت — فيها أجر عظيم وتذكير يومي بالله.',
        'الزم الصدق دائمًا ولو كان صعبًا — الصدق يهدي إلى الخير، ويورث القلب طمأنينة.',
        'بادر لمساعدة من حولك ولو بأمر بسيط — والصدقة تطفئ غضب الرب ولو كانت يسيرة.',
        'ارحم من حولك — الراحمون يرحمهم الرحمن، وأعظم الناس من يعامل غيره بلين ورفق.',
      ],
      'en': [
        'Stay away from bad company as much as you can — companions pull you toward them, and righteous company helps you stay steady.',
        'Try to keep up with praying in congregation — it carries great reward and a daily reminder of Allah.',
        'Hold on to honesty always, even when it\'s hard — truthfulness leads to goodness and gives the heart peace.',
        'Look for small ways to help those around you — even a modest act of charity carries real weight.',
        'Be merciful to those around you — the merciful are shown mercy, and the best people treat others with gentleness.',
      ],
    },
  ),
  CompanionIntent(
    id: 'about_app',
    keywordsByLang: {
      'ar': [
        'ما هذا التطبيق', 'ايش هذا البرنامج', 'شنو هذا التطبيق', 'وش البرنامج', 'ايش هالتطبيق',
        'وش فايدة التطبيق', 'ليش احمل هذا التطبيق', 'اشرح لي التطبيق',
      ],
      'en': ['what is this app', 'what does this app do'],
    },
    responsesByLang: {
      'ar': ['طالب العلم تطبيق يساعدك تحفظ وتراجع القرآن وتتابع أذكارك وأهدافك — بدون إنترنت وبدون إعلانات.'],
      'en': [
        'Talib Al-Ilm helps you memorize and review the Quran and track your daily remembrance and goals — no internet, no ads.',
      ],
    },
  ),
  CompanionIntent(
    id: 'memorization_howto',
    keywordsByLang: {
      'ar': [
        'كيف احفظ', 'كيف اقدر احفظ', 'طريقة الحفظ', 'كيف ابدا الحفظ', 'كيف احفظ القران',
        'افضل طريقة للحفظ', 'ساعدني احفظ', 'نصائح للحفظ', 'كيف اثبت المحفوظ',
      ],
      'en': ['how do i memorize', 'how to memorize', 'how do i start memorizing'],
    },
    responsesByLang: {
      'ar': [
        'ابدأ بصفحة أو نصف صفحة يوميًا وكرّرها عدة مرات قبل الانتقال — القليل المتكرر أفضل من الكثير المنسي.',
        'اربط الحفظ بوقت ثابت كل يوم ولو خمس دقائق — الثبات أهم من الكمية.',
        'راجع القديم يوميًا ولو قليلًا — الحفظ بدون مراجعة يتسرب بسرعة مهما كان متقنًا.',
      ],
      'en': [
        'Start with a page or half a page daily and repeat it several times before moving on — a little, often, beats a lot, forgotten.',
        'Tie memorization to a fixed time each day, even five minutes — consistency matters more than quantity.',
        'Review the old material daily, even briefly — memorization fades fast without review, no matter how solid it felt.',
      ],
    },
  ),
];
