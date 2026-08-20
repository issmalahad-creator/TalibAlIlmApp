import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_surahs.dart';
import '../repositories/adhkar_repository.dart';
import '../repositories/completion_goal_repository.dart';
import '../repositories/companion_memory_repository.dart';
import '../repositories/journey_plan_repository.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/quran_reading_session_repository.dart';
import '../repositories/quran_search_repository.dart';
import '../screens/adhkar_category_screen.dart';
import '../utils/arabic_normalize.dart';
import '../utils/fuzzy_match.dart' as fuzzy;
import 'companion_chat_engine.dart';
import 'companion_context_tracker.dart';
import 'companion_navigation_registry.dart';
import 'language_preference_service.dart';

/// "اذا ضغط يفتح واذا لم اضغط... يكون طبيعي... ما يفتح تلقائي" (Ismail,
/// 2026-08-18) — a reply can offer an "open the full screen" action, but
/// the session NEVER navigates on its own; it only ever hands back a
/// builder for the UI to push when the student actually taps the button.
/// `actionLabel`/`actionBuilder` are both null for the overwhelming
/// majority of replies (plain text, no screen to open).
class CompanionChatReply {
  final String text;
  final String? actionLabel;
  final WidgetBuilder? actionBuilder;
  const CompanionChatReply(this.text, {this.actionLabel, this.actionBuilder});
}

/// Wires the stateless `CompanionChatEngine` to real memory and real app
/// data. Three things the pure engine can't do on its own, all requested
/// directly by Ismail on 2026-08-18:
///
/// 1. "اريد ان يتذكره ويكون صديقه" — remembers the student's name
///    (`CompanionMemoryRepository`) and logs every exchange so it stops
///    greeting them as a stranger every message.
/// 2. "يخبره عن انجازاته والمتبقي... وكم من الوقت استثمر وعليه الزياده" —
///    a `progress_report` reply built entirely from real, already-tracked
///    data (`JourneyPlanRepository`'s mastery/hizb/schedule-status,
///    `QuranReadingSessionRepository`'s lifetime minutes) — never a
///    fabricated number.
/// 3. Runs in whichever UI language is active
///    (`LanguagePreferenceService`), falling back to Arabic content where a
///    language isn't authored yet.
///
/// Deliberately NOT included yet: "لم يفتح الكتاب الفلاني" / detecting a
/// specific neglected book or unused feature. That needs a genuine
/// last-used-at tracker across personal books and every module — no such
/// tracking exists anywhere in the app today (checked `PersonalBookRepository`
/// and `ActivityRepository` directly; neither records per-item last-touched
/// timestamps). Building it well is its own step, not a shortcut bolted on
/// here — queued in QURAN_COMPANION_ROADMAP.md §4.36 rather than guessed.
class CompanionChatSession {
  final CompanionChatEngine _engine;
  final CompanionMemoryRepository _memory;
  final JourneyPlanRepository _journeyRepo;
  final QuranReadingSessionRepository _readingRepo;
  final QuranReadingRepository _quranRepo;
  final AdhkarRepository _adhkarRepo;

  CompanionChatSession({
    CompanionChatEngine? engine,
    CompanionMemoryRepository? memory,
    JourneyPlanRepository? journeyRepo,
    QuranReadingSessionRepository? readingRepo,
    QuranReadingRepository? quranRepo,
    AdhkarRepository? adhkarRepo,
  })  : _engine = engine ?? CompanionChatEngine(),
        _memory = memory ?? CompanionMemoryRepository(),
        _journeyRepo = journeyRepo ?? JourneyPlanRepository(),
        _readingRepo = readingRepo ?? QuranReadingSessionRepository(),
        _quranRepo = quranRepo ?? QuranReadingRepository(),
        _adhkarRepo = adhkarRepo ?? AdhkarRepository();

  static final _arNamePattern = RegExp('اسمي\\s+([؀-ۿ]{2,25})');
  static final _enNamePattern = RegExp(r"my name is\s+([a-zA-Z]{2,25})", caseSensitive: false);

  static const _progressKeywordsAr = ['انجازاتي', 'كم انجزت', 'تقدمي', 'وين وصلت', 'كم بقي', 'كم استثمرت'];
  static const _progressKeywordsEn = ['my progress', 'how much have i done', 'what\'s left', 'how much time have i'];

  static const _recognitionKeywordsAr = ['هل تعرفني', 'تعرفني', 'من انا', 'تتذكرني', 'هل تتذكرني'];
  static const _recognitionKeywordsEn = ['do you know me', 'who am i', 'do you remember me'];

  static const _continuationCuesAr = ['كم', 'باقي', 'وكم', 'ايش'];
  static const _continuationCuesEn = ['how much', 'what about', 'and how'];

  static const _tafsirKeywordsAr = ['فسرها', 'فسر هذه الاية', 'تفسير الاية', 'ما معنى هذه الاية', 'اشرح الاية', 'وش تفسيرها'];
  static const _tafsirKeywordsEn = ['explain this ayah', 'what does this verse mean', 'tafsir this ayah', 'explain this verse'];

  static const _adhkarAnchorsAr = ['اذكار', 'ادعية'];
  static const _adhkarAnchorsEn = ['adhkar', 'remembrance'];

  /// occasion key → Arabic label, same mapping `adhkar_screen.dart` already
  /// uses for its own occasion subheaders — reused rather than duplicated
  /// so "السفر" always means the same real grouping in both places.
  static const _occasionLabelsAr = {
    'travel': 'السفر',
    'funeral': 'الجنازة والمرض',
    'hajj': 'الحج والعمرة',
    'food': 'الطعام والصيام',
  };

  static const _tafsirTriggersOrdered = ['فسر لي', 'تفسير', 'اشرح', 'فسر'];
  static const _tafsirGenericRemainders = ['', 'ها', 'هذه الايه', 'هذه الآية', 'الايه', 'الآية', 'هذه', 'ايه', 'آية'];

  static const _navigationTriggersOrdered = ['اذهب الى', 'خذني الى', 'وديني الى', 'افتح لي', 'روح الى', 'افتح', 'روح'];

  static const _tafsirSourceCommandCuesAr = ['استخدم تفسير', 'غير التفسير', 'غيّر التفسير', 'اريد تفسير'];
  static const _tafsirSourceListCuesAr = ['ما هي التفاسير', 'ايش التفاسير المتوفرة', 'التفاسير المتوفرة'];
  static const _tafsirSourcePrefKey = 'companion_preferred_tafsir_source';

  /// In-memory only — "context" scoped to this screen's lifetime, not
  /// persisted. Lets a short follow-up like "وكم باقي؟" after a progress
  /// report still resolve correctly instead of hitting the generic
  /// fallback, without pretending to understand pronouns/references in
  /// general (that's a much bigger feature than one bounded heuristic).
  String? _lastIntentId;

  /// A first bubble shown when the chat screen opens, BEFORE the student
  /// types anything — "لم يرحب بي عندما عدت له" (Ismail, 2026-08-18): the
  /// screen used to sit empty until the student typed first, so a name it
  /// already remembered from a previous visit never actually got used
  /// until asked. Reads memory only, logs nothing (it's not a reply to a
  /// message the student sent).
  Future<String> greetingForOpen({String? lang}) async {
    final effectiveLang = lang ?? LanguagePreferenceService.currentLanguage;
    final storedName = await _memory.getName();
    if (storedName != null) {
      return effectiveLang == 'en' ? 'Welcome back, $storedName! How can I help today?' : 'أهلًا بعودتك يا $storedName! كيف أقدر أساعدك اليوم؟';
    }
    return effectiveLang == 'en'
        ? 'Hi! I\'m your companion here. Tell me your name if you\'d like me to remember it.'
        : 'أهلًا! أنا رفيقك هنا. أخبرني باسمك إن أحببت أن أتذكره.';
  }

  Future<CompanionChatReply> send(String userText, {String? lang}) async {
    final effectiveLang = lang ?? LanguagePreferenceService.currentLanguage;
    final trimmed = userText.trim();
    if (trimmed.isEmpty) return CompanionChatReply(_fallback(effectiveLang));

    final introducedName = _tryExtractName(trimmed, effectiveLang);
    if (introducedName != null) {
      await _memory.setName(introducedName);
      await _memory.logMessage(trimmed, 'name_intro');
      return CompanionChatReply(effectiveLang == 'en'
          ? 'Nice to meet you, $introducedName! I\'ll remember your name from now on.'
          : 'تشرفت بك يا $introducedName! سأتذكر اسمك من الآن.');
    }

    if (_matchesRecognitionRequest(trimmed, effectiveLang)) {
      final storedName = await _memory.getName();
      await _memory.logMessage(trimmed, 'recognition_check');
      if (storedName != null) {
        return CompanionChatReply(effectiveLang == 'en' ? 'Of course — you\'re $storedName.' : 'بالتأكيد — أنت $storedName.');
      }
      return CompanionChatReply(effectiveLang == 'en'
          ? 'You haven\'t told me your name yet — say "my name is ..." and I\'ll remember it.'
          : 'لم تخبرني باسمك بعد — قل "اسمي ..." وسأتذكره من الآن.');
    }

    if (effectiveLang != 'en') {
      final navigationReply = _tryNavigate(trimmed);
      if (navigationReply != null) {
        await _memory.logMessage(trimmed, 'navigation');
        return navigationReply;
      }
    }

    if (_matchesProgressRequest(trimmed, effectiveLang)) {
      final reply = await _buildProgressReport(effectiveLang);
      await _memory.logMessage(trimmed, 'progress_report');
      _lastIntentId = 'progress_report';
      return CompanionChatReply(reply);
    }

    if (effectiveLang != 'en' && _tafsirSourceListCuesAr.any((c) => normalizeArabicForSearch(trimmed).contains(normalizeArabicForSearch(c)))) {
      await _memory.logMessage(trimmed, 'tafsir_source_list');
      return CompanionChatReply(_listTafsirSources());
    }

    if (effectiveLang != 'en' && _tafsirSourceCommandCuesAr.any((c) => normalizeArabicForSearch(trimmed).contains(normalizeArabicForSearch(c)))) {
      final reply = await _trySetTafsirSource(trimmed);
      await _memory.logMessage(trimmed, 'tafsir_source_change');
      return CompanionChatReply(reply);
    }

    final looksLikeTafsir = _matchesKeywords(trimmed, effectiveLang, _tafsirKeywordsAr, _tafsirKeywordsEn) ||
        (effectiveLang != 'en' && ['فسر', 'تفسير', 'اشرح'].any((w) => normalizeArabicForSearch(trimmed).contains(w))) ||
        (effectiveLang == 'en' && ['explain', 'tafsir', 'meaning of'].any((w) => trimmed.toLowerCase().contains(w)));
    if (looksLikeTafsir) {
      final textResult =
          effectiveLang == 'en' ? await _tryTafsirTextSearchEnglish(trimmed) : await _tryTafsirTextSearch(trimmed);
      final reply = textResult ?? await _buildTafsirReply(effectiveLang);
      await _memory.logMessage(trimmed, 'tafsir_lookup');
      return CompanionChatReply(reply);
    }

    final looksLikeAdhkar = effectiveLang == 'en'
        ? _adhkarAnchorsEn.any((a) => trimmed.toLowerCase().contains(a))
        : _adhkarAnchorsAr.any((a) => normalizeArabicForSearch(trimmed).contains(normalizeArabicForSearch(a))) ||
            _matchesBareOccasionOrCategory(trimmed);
    if (looksLikeAdhkar) {
      final reply = await _buildAdhkarReplyForQuery(effectiveLang, trimmed);
      await _memory.logMessage(trimmed, 'adhkar_request');
      return reply;
    }

    final (intentId, response) = _engine.match(trimmed, lang: effectiveLang);
    if (response == null) {
      // Context carry-over: a short follow-up ("وكم باقي؟") right after a
      // progress report almost always still means "progress" — reuse it
      // rather than falling straight to the generic honest fallback.
      if (_lastIntentId == 'progress_report' && _looksLikeContinuation(trimmed, effectiveLang)) {
        final reply = await _buildProgressReport(effectiveLang);
        await _memory.logMessage(trimmed, 'progress_report');
        return CompanionChatReply(reply);
      }
      await _memory.logMessage(trimmed, null);
      return CompanionChatReply(_fallback(effectiveLang));
    }

    await _memory.logMessage(trimmed, intentId);
    _lastIntentId = intentId;

    if (intentId == 'greeting') {
      final storedName = await _memory.getName();
      if (storedName != null) {
        return CompanionChatReply(effectiveLang == 'en' ? 'Hey $storedName! $response' : 'يا $storedName، $response');
      }
    }
    return CompanionChatReply(response);
  }

  /// "افتح القبلة" — offers a real "open" button, never navigates on its
  /// own ("اذا ضغط يفتح واذا لم اضغط... ما يفتح تلقائي", Ismail,
  /// 2026-08-18 — an explicit correction: this used to push the screen
  /// immediately just from the text arriving, which was wrong; now it only
  /// ever hands back a builder for the UI to push on an actual tap).
  /// Matches only real, named screens in `companionNavigationTargets` — no
  /// guessing an unlisted feature into existence. Returns null (letting the
  /// message fall through to normal matching) when the text doesn't start
  /// with a navigation trigger at all, so an ordinary sentence that happens
  /// to contain "افتح" isn't hijacked into a failed-navigation reply.
  CompanionChatReply? _tryNavigate(String rawText) {
    final trimmed = rawText.trim();
    final normalizedTrimmed = normalizeArabicForSearch(trimmed);
    String? remainder;
    for (final trigger in _navigationTriggersOrdered) {
      final normTrigger = normalizeArabicForSearch(trigger);
      if (!normalizedTrimmed.startsWith(normTrigger)) continue;
      final triggerWordCount = trigger.split(RegExp(r'\s+')).length;
      final rawWords = trimmed.split(RegExp(r'\s+'));
      remainder = rawWords.length > triggerWordCount ? rawWords.sublist(triggerWordCount).join(' ') : '';
      break;
    }
    if (remainder == null || remainder.trim().isEmpty) return null;

    final normalizedRemainder = normalizeArabicForSearch(remainder);
    for (final target in companionNavigationTargets) {
      final matches = target.names.any((name) {
        final normName = normalizeArabicForSearch(name);
        return normalizedRemainder.contains(normName) || normName.contains(normalizedRemainder);
      });
      if (!matches) continue;
      return _navigateTo(target);
    }

    // Closest-match fallback — a typo in the feature name ("القبله" missing
    // its alef, say) shouldn't fail exact matching and then just give up.
    // Requires EVERY word of the remainder to fuzzy-match some word in the
    // target's name (same conservative all-words rule
    // `companion_chat_engine.dart` uses for its own fuzzy matching) so a
    // single ambiguous short word can't misfire an unrelated navigation.
    final remainderWords = normalizedRemainder.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    for (final target in companionNavigationTargets) {
      final fuzzyMatches = target.names.any((name) {
        final nameWords = normalizeArabicForSearch(name).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        return nameWords.isNotEmpty && remainderWords.every((rw) => nameWords.any((nw) => fuzzy.isFuzzyMatch(nw, rw)));
      });
      if (fuzzyMatches) return _navigateTo(target);
    }
    // No registered screen matched — return null (not an error message) so
    // the message still gets a chance against the adhkar/tafsir content
    // handlers downstream (e.g. "افتح لي اذكار السفر" should reach the
    // adhkar handler, not dead-end here just because "اذكار" isn't a
    // navigation target). Only the final fallback says "لم أفهم" if truly
    // nothing matches anywhere.
    return null;
  }

  CompanionChatReply _navigateTo(CompanionNavigationTarget target) {
    return CompanionChatReply(
      'وجدت "${target.displayName}" — هل تفتحها؟',
      actionLabel: 'افتح ${target.displayName}',
      actionBuilder: target.builder,
    );
  }

  bool _looksLikeContinuation(String text, String lang) {
    final normalized = lang == 'en' ? text.toLowerCase() : normalizeArabicForSearch(text);
    final wordCount = normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount > 4) return false;
    final cues = lang == 'en' ? _continuationCuesEn : _continuationCuesAr;
    return cues.any((c) => normalized.contains(lang == 'en' ? c : normalizeArabicForSearch(c)));
  }

  String? _tryExtractName(String text, String lang) {
    final match = lang == 'en' ? _enNamePattern.firstMatch(text) : _arNamePattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  /// Normalizes the same way `CompanionChatEngine` does before comparing —
  /// without this, hamza/diacritic variants (e.g. "كم أنجزت" typed with a
  /// hamza vs. this list's plain "كم انجزت") silently failed to match and
  /// fell through to the regular engine instead, which DOES normalize and
  /// so matched "انجزت" against the unrelated `accomplishment` intent.
  /// Caught live on Ismail's device 2026-08-18.
  bool _matchesProgressRequest(String text, String lang) {
    final normalized = lang == 'en' ? text.toLowerCase() : normalizeArabicForSearch(text);
    final keywords = lang == 'en' ? _progressKeywordsEn : _progressKeywordsAr;
    return keywords.any((k) => normalized.contains(lang == 'en' ? k : normalizeArabicForSearch(k)));
  }

  bool _matchesRecognitionRequest(String text, String lang) {
    final normalized = lang == 'en' ? text.toLowerCase() : normalizeArabicForSearch(text);
    final keywords = lang == 'en' ? _recognitionKeywordsEn : _recognitionKeywordsAr;
    return keywords.any((k) => normalized.contains(lang == 'en' ? k : normalizeArabicForSearch(k)));
  }

  bool _matchesKeywords(String text, String lang, List<String> arKeywords, List<String> enKeywords) {
    final normalized = lang == 'en' ? text.toLowerCase() : normalizeArabicForSearch(text);
    final keywords = lang == 'en' ? enKeywords : arKeywords;
    return keywords.any((k) => normalized.contains(lang == 'en' ? k : normalizeArabicForSearch(k)));
  }

  /// "لو كنا في القرآن وحبينا نسئل عن آية وتفسيرها" (Ismail, 2026-08-18) —
  /// pulls the REAL tafsir already stored in `tafsir_entries` for the last
  /// ayah the student tapped (`CompanionContextTracker`), never generated
  /// text. Honest fallback if no ayah context is set yet — asking without
  /// having opened an ayah first is a real, expected case, not an error.
  Future<String> _buildTafsirReply(String lang) async {
    final ayah = CompanionContextTracker.instance.currentAyah.value;
    if (ayah == null) {
      return lang == 'en'
          ? 'Open an ayah in the Quran reading screen and tap it first, then ask me to explain it.'
          : 'افتح آية في شاشة قراءة القرآن واضغط عليها أولًا، ثم اسألني عن تفسيرها.';
    }
    final (surah, ayahNum) = ayah;
    final source = await _preferredTafsirSource();
    final text = await _quranRepo.tafsirForAyah(surah, ayahNum, source);
    if (text == null || text.isEmpty) {
      return lang == 'en' ? 'No tafsir available for this ayah in the current source yet.' : 'لا يتوفر تفسير لهذه الآية في المصدر الحالي بعد.';
    }
    final surahName = quranSurahs.firstWhere((s) => s.number == surah).name;
    final othersNote = await _availableOtherSourcesNote(surah, ayahNum, source, lang);
    return (lang == 'en' ? 'Tafsir of $surahName, ayah $ayahNum:\n\n$text' : 'تفسير سورة $surahName، آية $ayahNum:\n\n$text') + othersNote;
  }

  /// "اضف اذا استطاع ان ياتي بالتفسيرات المتاحه وانا اختار" (Ismail,
  /// 2026-08-18) — after showing one tafsir, checks which OTHER real
  /// Arabic sources also have non-empty content for this exact ayah (a few
  /// extra `tafsirForAyah` lookups — cheap, bounded to
  /// `_arabicTafsirSources.length`) and names them, so the student can ask
  /// for a specific one ("استخدم تفسير ..." then ask again) instead of only
  /// ever seeing whichever source happens to be preferred. Never invents
  /// availability — only lists a source after actually finding real text
  /// for it.
  Future<String> _availableOtherSourcesNote(int surah, int ayah, String currentSource, String lang) async {
    final others = <String>[];
    for (final candidate in _arabicTafsirSources) {
      if (candidate.$1 == currentSource) continue;
      final text = await _quranRepo.tafsirForAyah(surah, ayah, candidate.$1);
      if (text != null && text.isNotEmpty) others.add(candidate.$2);
    }
    if (others.isEmpty) return '';
    return lang == 'en'
        ? '\n\nAlso available for this ayah: ${others.join(', ')}. Say "استخدم تفسير <name>" then ask again to see it.'
        : '\n\nمتوفر أيضًا لهذه الآية: ${others.join('، ')}. اكتب "استخدم تفسير <الاسم>" ثم اسألني مجددًا لعرضه.';
  }

  /// Arabic-only tafsir sources — matches this chat's Arabic-first content
  /// scope; the other-language sources in `tafsirSources` are for the
  /// reading screen's own picker, not this command.
  static final _arabicTafsirSources = QuranSearchRepository.tafsirSources.where((s) => s.$3 == 'ar').toList();

  Future<String> _preferredTafsirSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tafsirSourcePrefKey) ?? QuranSearchRepository.defaultTafsirSource;
  }

  String _listTafsirSources() {
    final names = _arabicTafsirSources.map((s) => '• ${s.$2}').join('\n');
    return 'التفاسير المتوفرة حاليًا:\n\n$names\n\nقل مثلًا "استخدم تفسير السعدي" لتغيير التفسير.';
  }

  /// "استخدم تفسير ابن كثير" — matches the requested name against real
  /// tafsir sources actually present in `tafsir_entries` (via
  /// `QuranSearchRepository.tafsirSources`), never invents a source. No
  /// fuzzy/AI guessing here — plain substring match against real display
  /// names, honest "not found" otherwise.
  Future<String> _trySetTafsirSource(String text) async {
    final normalized = normalizeArabicForSearch(text);
    for (final source in _arabicTafsirSources) {
      final normalizedName = normalizeArabicForSearch(source.$2);
      // Match on any distinguishing word in the display name (≥3 letters,
      // skips generic words like "تفسير") rather than requiring the whole
      // name verbatim, so "استخدم تفسير السعدي" matches "تفسير السعدي".
      final nameWords = normalizedName.split(RegExp(r'\s+')).where((w) => w.length >= 3 && w != 'تفسير');
      if (nameWords.any((w) => normalized.contains(w))) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tafsirSourcePrefKey, source.$1);
        return 'تم — سأستخدم "${source.$2}" من الآن عند طلب التفسير.';
      }
    }
    return 'لم أتعرف على هذا المصدر. ${_listTafsirSources()}';
  }

  /// True for a SHORT bare message ("السفر") that names a real adhkar
  /// occasion directly, with no "اذكار"/"ادعية" anchor word — exactly the
  /// pattern Ismail hit live (typed "اذكار السفر" then, in a follow-up,
  /// just "السفر" alone). Restricted to <=3 words so an ordinary sentence
  /// that happens to contain "الصباح" doesn't misfire.
  bool _matchesBareOccasionOrCategory(String text) {
    final normalized = normalizeArabicForSearch(text);
    final wordCount = normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount > 3) return false;
    return _occasionLabelsAr.values.any((label) => normalized.contains(normalizeArabicForSearch(label)));
  }

  /// "اعطني اذكار الصباح" / "اذكار السفر" / bare "السفر" — real content
  /// from `AdhkarRepository`, never invented. Generalized 2026-08-18 (was
  /// hardcoded to morning/evening only — Ismail's live test showed "اذكار
  /// السفر" and bare "السفر" both fell through to the honest fallback):
  /// tries a direct category-title match first (covers "الصباح"/"المساء",
  /// which really are category titles), then falls back to the same
  /// occasion grouping (travel/funeral/hajj/food) `adhkar_screen.dart`
  /// already uses, since occasions can span more than one category.
  Future<CompanionChatReply> _buildAdhkarReplyForQuery(String lang, String rawText) async {
    var query = normalizeArabicForSearch(rawText);
    for (final anchor in [..._adhkarAnchorsAr, ..._adhkarAnchorsEn]) {
      final normAnchor = normalizeArabicForSearch(anchor);
      final idx = query.indexOf(normAnchor);
      if (idx != -1) {
        query = query.substring(idx + normAnchor.length).trim();
        break;
      }
    }
    if (query.isEmpty) query = normalizeArabicForSearch(rawText);

    final categories = await _adhkarRepo.allCategories();
    final titleMatches = categories.where((c) {
      final t = normalizeArabicForSearch(c.title);
      return query.isNotEmpty && (t.contains(query) || query.contains(t));
    }).toList();
    if (titleMatches.length == 1) return _formatAdhkarCategory(lang, titleMatches.first);

    for (final entry in _occasionLabelsAr.entries) {
      if (!query.contains(normalizeArabicForSearch(entry.value))) continue;
      final occasionMatches = categories.where((c) => c.occasion == entry.key).toList();
      if (occasionMatches.isEmpty) continue;
      if (occasionMatches.length == 1) return _formatAdhkarCategory(lang, occasionMatches.first);
      final names = occasionMatches.map((c) => '• ${c.title}').join('\n');
      return CompanionChatReply(lang == 'en'
          ? 'Found several categories for "${entry.value}":\n\n$names\n\nName one exactly and I\'ll show it.'
          : 'وجدت عدة فئات لـ"${entry.value}":\n\n$names\n\nاكتب اسم إحداها بالضبط لأعرضها لك.');
    }

    final queryWords = query.split(RegExp(r'\s+')).where((w) => w.length >= 3).toList();
    if (queryWords.isNotEmpty) {
      AdhkarCategory? closest;
      var bestOverlap = 0;
      for (final category in categories) {
        final titleWords = normalizeArabicForSearch(category.title).split(RegExp(r'\s+')).toSet();
        final overlap = queryWords.where((qw) => titleWords.any((tw) => fuzzy.isFuzzyMatch(tw, qw))).length;
        if (overlap > bestOverlap) {
          bestOverlap = overlap;
          closest = category;
        }
      }
      if (closest != null && bestOverlap > 0) {
        final reply = await _formatAdhkarCategory(lang, closest);
        final note = lang == 'en' ? 'Closest match — "${closest.title}":\n\n' : 'أقرب ما وجدته — "${closest.title}":\n\n';
        return CompanionChatReply(note + reply.text, actionLabel: reply.actionLabel, actionBuilder: reply.actionBuilder);
      }
    }

    return CompanionChatReply(lang == 'en' ? 'I couldn\'t find that adhkar category.' : 'لم أجد هذه الفئة من الأذكار.');
  }

  Future<CompanionChatReply> _formatAdhkarCategory(String lang, AdhkarCategory category) async {
    final items = await _adhkarRepo.itemsFor(category.id);
    if (items.isEmpty) {
      return CompanionChatReply(lang == 'en' ? 'This category has no items yet.' : 'هذه الفئة لا تحتوي أذكارًا بعد.');
    }
    const previewCount = 3;
    final preview = items.take(previewCount).map((i) => '• ${i.text}').join('\n\n');
    final remaining = items.length - previewCount;
    final buffer = StringBuffer(preview);
    if (remaining > 0) {
      buffer.write(lang == 'en' ? '\n\n...and $remaining more.' : '\n\n...و$remaining ذكرًا آخر.');
    }
    return CompanionChatReply(
      buffer.toString(),
      actionLabel: lang == 'en' ? 'Open "${category.title}"' : 'افتح "${category.title}"',
      actionBuilder: (context) => AdhkarCategoryScreen(category: category),
    );
  }

  /// "فسر الحمدلله رب العالمين" — searches the ACTUAL Quran text for
  /// whatever the student typed or pasted after a tafsir trigger word,
  /// reusing `QuranSearchRepository.search()` (the same engine
  /// `quran_search_screen.dart` uses), and returns real tafsir for the
  /// matched ayah — never a generated explanation. Returns null (letting
  /// the caller fall back to the tapped-ayah context path) when the
  /// remainder is empty or a generic filler like "هذه الآية" rather than
  /// actual searchable text — "فسر لي ايه" alone isn't a text query.
  Future<String?> _tryTafsirTextSearch(String rawText) async {
    final trimmed = rawText.trim();
    String? remainder;
    for (final trigger in _tafsirTriggersOrdered) {
      final normTrigger = normalizeArabicForSearch(trigger);
      if (!normalizeArabicForSearch(trimmed).startsWith(normTrigger)) continue;
      final triggerWordCount = trigger.split(RegExp(r'\s+')).length;
      final rawWords = trimmed.split(RegExp(r'\s+'));
      remainder = rawWords.length > triggerWordCount ? rawWords.sublist(triggerWordCount).join(' ') : '';
      break;
    }
    if (remainder == null) return null;
    final normalizedRemainder = normalizeArabicForSearch(remainder);
    if (normalizedRemainder.length < 3) return null;
    if (_tafsirGenericRemainders.any((f) => normalizedRemainder == normalizeArabicForSearch(f))) return null;

    final source = await _preferredTafsirSource();
    final searchRepo = QuranSearchRepository();
    final results = await searchRepo.search(remainder, tafsirSource: source);

    // Exact match failing shouldn't mean "لم أفهم" — try the closest real
    // ayah instead, and say plainly that it's an approximation.
    var approximate = false;
    var best = results.isNotEmpty ? _mostSpecificResult(results) : null;
    if (best == null) {
      best = await searchRepo.closestMatch(remainder, tafsirSource: source);
      approximate = best != null;
    }
    if (best == null) return null;

    CompanionContextTracker.instance.setCurrentAyah(best.surah, best.ayah);
    final tafsirText = best.tafsir;
    final prefix = approximate ? 'أقرب آية وجدتها — سورة ${best.surahName}، آية ${best.ayah}' : 'سورة ${best.surahName}، آية ${best.ayah}';
    if (tafsirText == null || tafsirText.isEmpty) {
      return '$prefix — لكن لا يتوفر تفسير لها في المصدر الحالي.';
    }
    final othersNote = await _availableOtherSourcesNote(best.surah, best.ayah, source, 'ar');
    return '$prefix:\n\n$tafsirText$othersNote';
  }

  /// When a substring query matches several ayat, the shortest matching
  /// ayah is the most specific/precise hit — a long ayah "contains" the
  /// query almost incidentally among far more unrelated words, while a
  /// short ayah that contains it is dominated by the query itself. Same
  /// precision-over-recall principle real search engines use when ranking
  /// multiple exact matches, applied as a simple length tie-break rather
  /// than full relevance scoring (this app's whole corpus is 6,236 ayat —
  /// a proper TF-IDF/BM25 index would be solving a problem this small
  /// dataset doesn't have).
  QuranSearchResult _mostSpecificResult(List<QuranSearchResult> results) {
    return results.reduce((a, b) => a.textUthmani.length <= b.textUthmani.length ? a : b);
  }

  /// English mirror of `_tryTafsirTextSearch` — searches the REAL English
  /// translation text already stored in `tafsir_entries` (source
  /// 'english_rwwad', the same QuranEnc-sourced content `tafsirSources`
  /// already lists) instead of the Arabic Quran text, so an English query
  /// actually has words in common with what it's being matched against.
  Future<String?> _tryTafsirTextSearchEnglish(String rawText) async {
    final trimmed = rawText.trim();
    const triggers = ['explain this ', 'explain ', 'tafsir ', 'meaning of '];
    String? remainder;
    for (final trigger in triggers) {
      if (!trimmed.toLowerCase().startsWith(trigger)) continue;
      remainder = trimmed.substring(trigger.length).trim();
      break;
    }
    if (remainder == null || remainder.length < 3) return null;

    const source = 'english_rwwad';
    final searchRepo = QuranSearchRepository();
    final results = await searchRepo.searchTranslationText(remainder, source);

    var approximate = false;
    var best = results.isNotEmpty ? _mostSpecificResult(results) : null;
    if (best == null) {
      best = await searchRepo.closestTranslationMatch(remainder, source);
      approximate = best != null;
    }
    if (best == null) return null;

    CompanionContextTracker.instance.setCurrentAyah(best.surah, best.ayah);
    final text = best.tafsir;
    final prefix = approximate ? 'Closest match — ${best.surahName}, ayah ${best.ayah}' : '${best.surahName}, ayah ${best.ayah}';
    if (text == null || text.isEmpty) return '$prefix — no translation available.';
    return '$prefix:\n\n$text';
  }

  Future<String> _buildProgressReport(String lang) async {
    final status = await _journeyRepo.status();
    final minutes = await _readingRepo.lifetimeMinutes();
    if (status == null) {
      return lang == 'en'
          ? 'You haven\'t set up a memorization journey yet — start one from "رحلتي" and I\'ll be able to track your progress here.'
          : 'ما عندك رحلة حفظ محددة بعد — أنشئها من "رحلتي" وبعدها أقدر أتابع لك تقدمك هنا.';
    }

    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final scheduleWord = switch (status.goalStatus.scheduleStatus) {
      ScheduleStatus.ahead => lang == 'en' ? 'ahead of schedule' : 'متقدم عن الخطة',
      ScheduleStatus.onTrack => lang == 'en' ? 'right on track' : 'على المسار الصحيح',
      ScheduleStatus.behind => lang == 'en' ? 'behind schedule' : 'متأخر عن الخطة',
    };

    if (lang == 'en') {
      final buffer = StringBuffer()
        ..writeln('Here\'s where you stand:')
        ..writeln('• Mastered ${status.masteredPages} of ${status.totalPages} pages (${status.masteryPercent.toStringAsFixed(1)}%)')
        ..writeln('• ${status.hizbCompleted} of ${status.hizbTotal} hizb complete')
        ..writeln('• Time invested reading: ${hours}h ${mins}m')
        ..write('• You\'re $scheduleWord');
      if (status.goalStatus.scheduleStatus == ScheduleStatus.behind) {
        buffer.write(' — a bit more time daily would bring you back on pace.');
      } else {
        buffer.write('.');
      }
      return buffer.toString();
    }

    final buffer = StringBuffer()
      ..writeln('هذا وضعك الحالي:')
      ..writeln('• أتقنت ${status.masteredPages} من ${status.totalPages} صفحة (${status.masteryPercent.toStringAsFixed(1)}٪)')
      ..writeln('• ${status.hizbCompleted} من ${status.hizbTotal} حزب مكتمل')
      ..writeln('• الوقت المستثمر في القراءة: $hours ساعة و$mins دقيقة')
      ..write('• أنت $scheduleWord');
    if (status.goalStatus.scheduleStatus == ScheduleStatus.behind) {
      buffer.write(' — زيادة بسيطة في وقتك اليومي كافية لتعود للمسار.');
    } else {
      buffer.write('.');
    }
    return buffer.toString();
  }

  String _fallback(String lang) =>
      lang == 'en' ? 'I didn\'t quite understand that, but I\'m here.' : 'لم أفهم تمامًا، لكن أنا هنا.';
}
