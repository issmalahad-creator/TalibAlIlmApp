import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/quran_book_cache.dart';
import '../repositories/quran_corpus_repository.dart';
import '../repositories/quran_reading_repository.dart';
import 'ayah_notebook_screen.dart';
import '../repositories/quran_search_repository.dart';
import '../services/language_preference_service.dart';
import '../services/text_scale_preference_service.dart';
import '../theme/app_theme.dart';
import 'usul/usul_tree_screen.dart';

/// Domain → its title key, shared by the "العلوم المرتبطة" cards and reader
/// (`AyahCorpusPanel` in corpus_panels.dart uses the same keys for its
/// quick-card section titles, so the two views always agree on labels).
const Map<String, String> _uloomDomainLabelKeys = {
  'asbab': 'ql_asbab',
  'iraab': 'ql_iraab_prose',
  'nasekh': 'ql_nasekh',
  'ghareeb': 'ql_ghareeb_ayah',
  'notes': 'ql_faidah',
  'similar': 'ql_mutashabihat',
  'sayings': 'ql_athar',
};

/// "دراسة الآية" — QURAN_COMPANION_ROADMAP.md Phase 72, unified per
/// `docs/quran/TAFSIR_UNIFIED_ARCHITECTURE.md` (2026-09-11). Turns one
/// ayah into a study hub: **every** real tafsir/translation source
/// available for it as cards — the 5 legacy `tafsir_entries` Arabic
/// editions AND the 122 bundled corpus tafsir books (`quran_tafsir_book` /
/// `QuranBookCache`), grouped under «تفاسير», kept visually separate from
/// the ~42 language "translation-tafsir" entries under «ترجمات» — a full
/// reader with prev/next-ayah swipe, and a side-by-side comparison of 2-4
/// sources. Deterministic only — every word shown here is a real stored
/// text (`tafsir_entries` or a bundled corpus asset); nothing is
/// generated or summarized by AI, matching Ismail's explicit "لا AI، كله
/// رياضيات" rule for anything student-facing.
class AyahStudyScreen extends StatefulWidget {
  final int surah;
  final int ayah;
  /// When set, opens straight into the reader for this `tafsir_entries`
  /// source instead of the card list — backs the reading screen's
  /// "الترجمة" shortcut (2026-08-25: Ismail wanted picking a language to
  /// jump directly to that translation, not through the full source list
  /// every time).
  final String? initialSource;
  /// When set, opens straight into the reader for this bundled corpus
  /// tafsir book (`quran_tafsir_book.id`) — backs the Ayah Knowledge
  /// Surface's tafsir panel «التفسير كاملًا» button, so the exact book the
  /// student was reading in the quick card is what opens here (2026-09-11
  /// fix: this used to be silently discarded, always reopening on the 5
  /// legacy Arabic editions regardless of which of the 122 bundled books
  /// was actually selected).
  final int? initialBookId;
  /// Opens straight into "العلوم المرتبطة" instead of التفسير والترجمة —
  /// used by the Ayah Knowledge Surface's «توسّع في صفحة الآية» when it's
  /// reached from the uloom tab, so the button actually lands on the
  /// content the user was reading (asbab/iraab/nasekh/ghareeb/notes/
  /// similar/sayings), not the unrelated tafsir list.
  final AyahStudyFamily? initialFamily;
  const AyahStudyScreen({
    super.key,
    required this.surah,
    required this.ayah,
    this.initialSource,
    this.initialBookId,
    this.initialFamily,
  });

  @override
  State<AyahStudyScreen> createState() => _AyahStudyScreenState();
}

enum _StudyMode { cards, reader, compare }

/// تفسير/ترجمة (existing) vs العلوم المرتبطة (سبب النزول وما حولها) — two
/// independent card→reader flows sharing the same banner/nav/sepia/font
/// controls. No compare mode for uloom: comparing classical asbāb accounts
/// isn't the same operation as comparing tafsir editions.
enum AyahStudyFamily { tafsirTranslation, uloom }

class _AyahStudyScreenState extends State<AyahStudyScreen> {
  final _repo = QuranReadingRepository();
  final _corpusRepo = QuranCorpusRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};
  static final _sourceLabels = {for (final s in QuranSearchRepository.tafsirSources) s.$1: s.$2};

  late int _surah = widget.surah;
  late int _ayah = widget.ayah;
  QuranAyahText? _currentAyah;
  List<AyahTafsirEntry> _entries = [];
  List<AyahCorpusEntry> _uloomEntries = [];
  Map<int, int> _asbabSurahCoverage = {};
  bool _loading = true;

  // The bundled corpus tafsir book catalog (System B — 122 bundled + ~27
  // online-mirror books). Loaded once; doesn't change per ayah.
  List<Map<String, Object?>> _tafsirBooks = [];

  late AyahStudyFamily _family = widget.initialFamily ?? AyahStudyFamily.tafsirTranslation;
  late _StudyMode _mode = widget.initialSource != null || widget.initialBookId != null
      ? _StudyMode.reader
      : _StudyMode.cards;
  late String? _readerSource = widget.initialSource;
  late int? _readerBookId = widget.initialBookId;
  String? _readerUloomId;
  final Set<String> _compareSelection = {};

  bool _bookTextLoading = false;
  String? _bookText;
  bool _bookMirror = false;

  bool _sepia = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadBooks();
    if (_readerBookId != null) _loadBookText();
  }

  Future<void> _loadBooks() async {
    final books = await _corpusRepo.tafsirBooks();
    if (!mounted) return;
    setState(() => _tafsirBooks = books);
  }

  Future<void> _loadBookText() async {
    final id = _readerBookId;
    if (id == null) return;
    setState(() {
      _bookTextLoading = true;
      _bookText = null;
      _bookMirror = false;
    });
    final e = await QuranBookCache.instance.tafsirEntry(id, _surah, _ayah);
    if (!mounted) return;
    setState(() {
      _bookTextLoading = false;
      if (e == null) {
        _bookText = null;
      } else if (e['mirror'] == true) {
        _bookMirror = true;
      } else {
        _bookText = '${e['text'] ?? ''}';
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ayahText = await _repo.ayahAt(_surah, _ayah);
    final entries = await _repo.tafsirEntriesForAyah(_surah, _ayah);
    final uloomEntries = await _corpusRepo.corpusEntriesForAyah(_surah, _ayah);
    final asbabCoverage = await _corpusRepo.asbabCoverageForSurah(_surah);
    if (!mounted) return;
    // The DB query has no ORDER BY (SQLite's row order is otherwise
    // unspecified), so card order would be unpredictable run to run
    // without this — sort by each source's fixed position in
    // `tafsirSources`, the same stable catalog order the language/source
    // pickers elsewhere in the app already use (Arabic entries listed
    // first there too, so this naturally keeps Arabic tafsir on top).
    final sourceOrder = {for (var i = 0; i < QuranSearchRepository.tafsirSources.length; i++) QuranSearchRepository.tafsirSources[i].$1: i};
    entries.sort((a, b) => (sourceOrder[a.source] ?? 999).compareTo(sourceOrder[b.source] ?? 999));
    setState(() {
      _currentAyah = ayahText;
      _entries = entries;
      _uloomEntries = uloomEntries;
      _asbabSurahCoverage = asbabCoverage;
      _loading = false;
      // A source that no longer has an entry on the new ayah (the
      // Ibn Ashur/Al-Kahf gap, or any other real gap) drops the reader
      // back to the card list instead of showing a stale/blank source.
      if (_readerSource != null && !entries.any((e) => e.source == _readerSource)) {
        _mode = _StudyMode.cards;
        _readerSource = null;
      }
      if (_readerUloomId != null && !uloomEntries.any((e) => e.id == _readerUloomId)) {
        _mode = _StudyMode.cards;
        _readerUloomId = null;
      }
    });
  }

  Future<void> _goToAyah(Future<QuranAyahText?> Function(int, int) fetch) async {
    final next = await fetch(_surah, _ayah);
    if (next == null || !mounted) return;
    setState(() {
      _surah = next.surah;
      _ayah = next.ayah;
    });
    await _load();
    if (_readerBookId != null) await _loadBookText();
  }

  void _openReader(String source) {
    setState(() {
      _mode = _StudyMode.reader;
      _readerSource = source;
      _readerBookId = null;
    });
  }

  void _openBookReader(int bookId) {
    setState(() {
      _mode = _StudyMode.reader;
      _readerBookId = bookId;
      _readerSource = null;
    });
    _loadBookText();
  }

  void _openUloomReader(String entryId) {
    setState(() {
      _mode = _StudyMode.reader;
      _readerUloomId = entryId;
    });
  }

  void _switchFamily(AyahStudyFamily family) {
    if (_family == family) return;
    setState(() {
      _family = family;
      _mode = _StudyMode.cards;
      _readerSource = null;
      _readerBookId = null;
      _readerUloomId = null;
      _compareSelection.clear();
    });
  }

  void _toggleCompareSelection(String source) {
    setState(() {
      if (_compareSelection.contains(source)) {
        _compareSelection.remove(source);
      } else if (_compareSelection.length < 4) {
        _compareSelection.add(source);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: _sepia ? const Color(0xFFF5EEDC) : AppColors.background,
        appBar: AppBar(
          title: Text(
            _currentAyah == null
                ? basicText('ayah_study_title', lang)
                : '${_surahNames[_surah] ?? _surah} • $_ayah',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            // «شجرة أصول التفسير» for this ayah (USUL_TAFSIR_TREE.md U3).
            IconButton(
              tooltip: basicText('usul_tree_title', lang),
              icon: const Icon(Icons.account_tree_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UsulTreeScreen(surah: _surah, ayah: _ayah)),
              ),
            ),
            IconButton(
              tooltip: basicText('ayah_notebook_open_action', lang),
              icon: const Icon(Icons.auto_stories_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AyahNotebookScreen(surah: _surah, ayah: _ayah)),
              ),
            ),
            IconButton(
              tooltip: basicText('font_size_tooltip', lang),
              icon: const Icon(Icons.text_fields_rounded),
              onPressed: _pickFontSize,
            ),
            IconButton(
              tooltip: basicText('sepia_mode_tooltip', lang),
              icon: Icon(_sepia ? Icons.wb_sunny : Icons.wb_sunny_outlined),
              onPressed: () => setState(() => _sepia = !_sepia),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _AyahBanner(ayah: _currentAyah, sepia: _sepia),
                  _FamilySwitcher(family: _family, lang: lang, onSelect: _switchFamily),
                  Expanded(
                    child: _family == AyahStudyFamily.uloom
                        ? switch (_mode) {
                            _StudyMode.reader => _UloomReaderView(
                                entryId: _readerUloomId,
                                entries: _uloomEntries,
                                sepia: _sepia,
                                lang: lang,
                                onBackToCards: () => setState(() {
                                  _mode = _StudyMode.cards;
                                  _readerUloomId = null;
                                }),
                              ),
                            _StudyMode.cards || _StudyMode.compare => _UloomCardsView(
                                entries: _uloomEntries,
                                asbabSurahCoverage: _asbabSurahCoverage,
                                lang: lang,
                                onOpenReader: _openUloomReader,
                              ),
                          }
                        : switch (_mode) {
                            _StudyMode.cards => _CardsView(
                                entries: _entries,
                                tafsirBooks: _tafsirBooks,
                                sourceLabels: _sourceLabels,
                                lang: lang,
                                onOpenReader: _openReader,
                                onOpenBookReader: _openBookReader,
                                onStartCompare: () => setState(() => _mode = _StudyMode.compare),
                              ),
                            _StudyMode.reader => _readerBookId != null
                                ? _BookReaderView(
                                    book: _tafsirBooks.firstWhere(
                                        (b) => b['id'] == _readerBookId,
                                        orElse: () => const {}),
                                    loading: _bookTextLoading,
                                    text: _bookText,
                                    mirror: _bookMirror,
                                    sepia: _sepia,
                                    lang: lang,
                                    onBackToCards: () => setState(() {
                                      _mode = _StudyMode.cards;
                                      _readerBookId = null;
                                    }),
                                  )
                                : _ReaderView(
                                    source: _readerSource!,
                                    entries: _entries,
                                    sourceLabels: _sourceLabels,
                                    sepia: _sepia,
                                    lang: lang,
                                    onBackToCards: () => setState(() {
                                      _mode = _StudyMode.cards;
                                      _readerSource = null;
                                    }),
                                  ),
                            _StudyMode.compare => _CompareView(
                                entries: _entries,
                                tafsirBooks: _tafsirBooks,
                                sourceLabels: _sourceLabels,
                                selection: _compareSelection,
                                lang: lang,
                                surah: widget.surah,
                                ayah: widget.ayah,
                                onToggle: _toggleCompareSelection,
                                onBackToCards: () => setState(() {
                                  _mode = _StudyMode.cards;
                                  _compareSelection.clear();
                                }),
                              ),
                          },
                  ),
                  if (_mode != _StudyMode.compare)
                    _AyahNavBar(
                      lang: lang,
                      onPrevious: () => _goToAyah(_repo.previousAyah),
                      onNext: () => _goToAyah(_repo.nextAyah),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickFontSize() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 8,
            children: TextScalePreferenceService.presets.map((scale) {
              final selected = TextScalePreferenceService.scaleNotifier.value == scale;
              return ChoiceChip(
                label: Text(TextScalePreferenceService.presetLabels[scale] ?? '$scale'),
                selected: selected,
                onSelected: (_) {
                  TextScalePreferenceService.setScale(scale);
                  setSheetState(() {});
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _AyahBanner extends StatelessWidget {
  final QuranAyahText? ayah;
  final bool sepia;
  const _AyahBanner({required this.ayah, required this.sepia});

  @override
  Widget build(BuildContext context) {
    if (ayah == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      color: sepia ? const Color(0xFFEDE3C8) : AppColors.primaryLight,
      child: Text(
        ayah!.text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 22, height: 1.9, color: AppColors.textDark),
      ),
    );
  }
}

class _AyahNavBar extends StatelessWidget {
  final String lang;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  const _AyahNavBar({required this.lang, required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(basicText('previous_ayah_action', lang)),
            ),
            TextButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(basicText('next_ayah_action', lang)),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ),
      ),
    );
  }
}

/// Switches between the two independent card→reader flows this screen
/// hosts. Kept to two chips only (no icon-only tabs) so the label itself
/// — not an icon the user has to learn — says what's behind each.
class _FamilySwitcher extends StatelessWidget {
  final AyahStudyFamily family;
  final String lang;
  final void Function(AyahStudyFamily) onSelect;
  const _FamilySwitcher({required this.family, required this.lang, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(basicText('ql_family_tafsir_translation', lang)),
            selected: family == AyahStudyFamily.tafsirTranslation,
            onSelected: (_) => onSelect(AyahStudyFamily.tafsirTranslation),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(basicText('ql_related_sciences', lang)),
            selected: family == AyahStudyFamily.uloom,
            onSelected: (_) => onSelect(AyahStudyFamily.uloom),
          ),
        ],
      ),
    );
  }
}

/// Groups every real tafsir/translation source into two clearly-labelled
/// sections instead of one flat, mixed list — the fix for "مخلوط
/// بترجمات": `entries` with `language == 'ar'` (the 5 legacy Arabic
/// `tafsir_entries` editions) plus every bundled `tafsirBooks` row (the
/// 122+ corpus tafsir books) are real exegesis and go under «تفاسير»;
/// every other-language `entries` row is a literal translation and goes
/// under «ترجمات». Compare mode stays scoped to `entries` only (comparing
/// full classical tomes side by side is a different, heavier operation —
/// `docs/quran/TAFSIR_UNIFIED_ARCHITECTURE.md §5` scopes this explicitly
/// rather than silently limiting it).
class _CardsView extends StatelessWidget {
  final List<AyahTafsirEntry> entries;
  final List<Map<String, Object?>> tafsirBooks;
  final Map<String, String> sourceLabels;
  final String lang;
  final void Function(String source) onOpenReader;
  final void Function(int bookId) onOpenBookReader;
  final VoidCallback onStartCompare;
  const _CardsView({
    required this.entries,
    required this.tafsirBooks,
    required this.sourceLabels,
    required this.lang,
    required this.onOpenReader,
    required this.onOpenBookReader,
    required this.onStartCompare,
  });

  @override
  Widget build(BuildContext context) {
    final arabicTafsir = entries.where((e) => e.language == 'ar').toList();
    final translations = entries.where((e) => e.language != 'ar').toList();

    if (arabicTafsir.isEmpty && tafsirBooks.isEmpty && translations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(basicText('no_tafsir_sources_for_ayah', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        if (entries.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: onStartCompare,
              icon: const Icon(Icons.compare_arrows_rounded, size: 18),
              label: Text(basicText('compare_tafsirs_action', lang)),
            ),
          ),
        if (arabicTafsir.isNotEmpty || tafsirBooks.isNotEmpty) ...[
          _SectionHeader(basicText('ql_tafsir_section', lang)),
          ...arabicTafsir.map((e) => _EntryCard(entry: e, sourceLabels: sourceLabels, lang: lang, onTap: () => onOpenReader(e.source))),
          ...tafsirBooks.map((b) => _BookCard(book: b, lang: lang, onTap: () => onOpenBookReader(b['id'] as int))),
        ],
        if (translations.isNotEmpty) ...[
          _SectionHeader(basicText('ql_translation_section', lang)),
          ...translations.map((e) => _EntryCard(entry: e, sourceLabels: sourceLabels, lang: lang, onTap: () => onOpenReader(e.source))),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Text(title,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryDark)),
      );
}

class _EntryCard extends StatelessWidget {
  final AyahTafsirEntry entry;
  final Map<String, String> sourceLabels;
  final String lang;
  final VoidCallback onTap;
  const _EntryCard({required this.entry, required this.sourceLabels, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          title: Row(
            children: [
              Expanded(child: Text(sourceLabels[entry.source] ?? entry.source, style: const TextStyle(fontWeight: FontWeight.w700))),
              // Several sources share an identical organizational label
              // across languages (e.g. several "Rowwad Translation
              // Center" editions) — without this tag those cards would
              // be indistinguishable by title alone.
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                child: Text(QuranSearchRepository.languageLabels[entry.language] ?? entry.language, style: const TextStyle(fontSize: 10.5, color: AppColors.primaryDark)),
              ),
            ],
          ),
          subtitle: Text(
            entry.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.6),
          ),
          trailing: (entry.footnote?.trim().isNotEmpty ?? false)
              // A real explanatory note (not the literal text itself) is
              // attached to this ayah for this source — surfaced here so
              // the student knows before opening the reader, not just
              // discovered inside it (docs/quran/
              // TAFSIR_UNIFIED_ARCHITECTURE.md §5).
              ? const Icon(Icons.sticky_note_2_outlined, size: 18, color: AppColors.primaryDark)
              : const Icon(Icons.chevron_left_rounded),
          onTap: onTap,
        ),
      );
}

/// One bundled corpus tafsir book — metadata only (name/author/year), no
/// text preview: fetching all 122+ books' text just to render this list
/// would mean 122+ gz-asset reads per screen open, against
/// `QuranBookCache`'s on-demand-LRU(4) design (`docs/quran/
/// TAFSIR_UNIFIED_ARCHITECTURE.md §3`). Full text loads lazily, only for
/// the one book actually opened.
class _BookCard extends StatelessWidget {
  final Map<String, Object?> book;
  final String lang;
  final VoidCallback onTap;
  const _BookCard({required this.book, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bundled = book['bundled'] == 1;
    final author = '${book['author'] ?? ''}';
    final year = '${book['year'] ?? ''}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text('${book['name'] ?? book['short'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700))),
            if (!bundled)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                child: Text(basicText('ql_online', lang), style: const TextStyle(fontSize: 10.5, color: AppColors.primaryDark)),
              ),
          ],
        ),
        subtitle: (author.isEmpty && year.isEmpty)
            ? null
            : Text(
                [author, year].where((s) => s.isNotEmpty).join(' — '),
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _ReaderView extends StatelessWidget {
  final String source;
  final List<AyahTafsirEntry> entries;
  final Map<String, String> sourceLabels;
  final bool sepia;
  final String lang;
  final VoidCallback onBackToCards;
  const _ReaderView({
    required this.source,
    required this.entries,
    required this.sourceLabels,
    required this.sepia,
    required this.lang,
    required this.onBackToCards,
  });

  @override
  Widget build(BuildContext context) {
    final entry = entries.where((e) => e.source == source).firstOrNull;
    return ValueListenableBuilder<double>(
      valueListenable: TextScalePreferenceService.scaleNotifier,
      builder: (context, scale, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onBackToCards,
                  icon: const Icon(Icons.list_alt_outlined, size: 18),
                  label: Text(basicText('all_sources_action', lang)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(sourceLabels[source] ?? source,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (entry != null)
                        Text(QuranSearchRepository.languageLabels[entry.language] ?? entry.language,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    entry?.text ?? basicText('no_tafsir_for_this_ayah', lang),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 15.5 * scale, height: 1.9, color: AppColors.textDark),
                  ),
                  // A separate, clearly-labelled layer — never merged into
                  // the translation/tafsir text above it (same separation
                  // principle as AKHLAQ_TRANSLATION_MODEL.md's source/
                  // translation/explanation layers).
                  if (entry?.footnote?.trim().isNotEmpty ?? false) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    Text(basicText('ql_footnote_section', lang),
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.primaryDark)),
                    const SizedBox(height: 6),
                    Text(
                      entry!.footnote!,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 14 * scale, height: 1.8, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full reader for one bundled corpus tafsir book (System B) — the
/// destination that used to be unreachable: tapping «التفسير كاملًا» in
/// the quick-card panel now lands here with the SAME book still open,
/// full untruncated text, not the unrelated 5-source legacy list.
class _BookReaderView extends StatelessWidget {
  final Map<String, Object?> book;
  final bool loading;
  final String? text;
  final bool mirror;
  final bool sepia;
  final String lang;
  final VoidCallback onBackToCards;
  const _BookReaderView({
    required this.book,
    required this.loading,
    required this.text,
    required this.mirror,
    required this.sepia,
    required this.lang,
    required this.onBackToCards,
  });

  @override
  Widget build(BuildContext context) {
    final author = '${book['author'] ?? ''}';
    return ValueListenableBuilder<double>(
      valueListenable: TextScalePreferenceService.scaleNotifier,
      builder: (context, scale, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onBackToCards,
                  icon: const Icon(Icons.list_alt_outlined, size: 18),
                  label: Text(basicText('all_sources_action', lang)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${book['name'] ?? book['short'] ?? ''}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (author.isNotEmpty)
                        Text(author,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      mirror
                          ? basicText('ql_tafsir_mirror', lang)
                          : (text?.trim().isNotEmpty ?? false)
                              ? text!
                              : basicText('no_tafsir_for_this_ayah', lang),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 15.5 * scale, height: 1.9, color: AppColors.textDark),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// "العلوم المرتبطة" card list — one card per [AyahCorpusEntry] (سبب النزول ·
/// إعراب من الكتب · ناسخ · غريب الآية · فوائد · متشابهات · آثار), full text
/// behind each tap via [_UloomReaderView]. When two books both discuss the
/// same ayah's أسباب النزول, each is its own card — never merged, never
/// silently picked (mirrors how multiple tafsir editions are already
/// separate cards, not one combined text).
class _UloomCardsView extends StatelessWidget {
  final List<AyahCorpusEntry> entries;
  final Map<int, int> asbabSurahCoverage;
  final String lang;
  final void Function(String entryId) onOpenReader;
  const _UloomCardsView({
    required this.entries,
    required this.asbabSurahCoverage,
    required this.lang,
    required this.onOpenReader,
  });

  @override
  Widget build(BuildContext context) {
    final hasAsbab = entries.any((e) => e.domain == 'asbab');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        if (!hasAsbab)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              basicText(
                asbabSurahCoverage.isNotEmpty ? 'ql_asbab_not_for_ayah' : 'ql_asbab_not_for_surah',
                lang,
              ),
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.7),
            ),
          ),
        if (entries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(basicText('ql_no_data_element', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          ...entries.map((e) {
            final domainLabel = basicText(_uloomDomainLabelKeys[e.domain] ?? e.domain, lang);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.label.isNotEmpty ? e.label : domainLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (e.label.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                        child: Text(domainLabel, style: const TextStyle(fontSize: 10.5, color: AppColors.primaryDark)),
                      ),
                  ],
                ),
                subtitle: Text(
                  e.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.6),
                ),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => onOpenReader(e.id),
              ),
            );
          }),
      ],
    );
  }
}

class _UloomReaderView extends StatelessWidget {
  final String? entryId;
  final List<AyahCorpusEntry> entries;
  final bool sepia;
  final String lang;
  final VoidCallback onBackToCards;
  const _UloomReaderView({
    required this.entryId,
    required this.entries,
    required this.sepia,
    required this.lang,
    required this.onBackToCards,
  });

  @override
  Widget build(BuildContext context) {
    final entry = entries.where((e) => e.id == entryId).firstOrNull;
    return ValueListenableBuilder<double>(
      valueListenable: TextScalePreferenceService.scaleNotifier,
      builder: (context, scale, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onBackToCards,
                  icon: const Icon(Icons.list_alt_outlined, size: 18),
                  label: Text(basicText('all_sources_action', lang)),
                ),
                const SizedBox(width: 8),
                if (entry != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          entry.label.isNotEmpty ? entry.label : basicText(_uloomDomainLabelKeys[entry.domain] ?? entry.domain, lang),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (entry.author != null)
                          Text(entry.author!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                entry?.text ?? basicText('ql_no_data_element', lang),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 15.5 * scale, height: 1.9, color: AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One comparable source in the picker — either a legacy `tafsir_entries`
/// row (`text` set synchronously) or a bundled corpus book (`bookId` set;
/// its ayah text is fetched on demand via `QuranBookCache`, same as the
/// single-source reader already does for these 122 books).
class _CompareSource {
  final String key;
  final String label;
  final String? text;
  final int? bookId;
  const _CompareSource({required this.key, required this.label, this.text, this.bookId});
}

class _CompareView extends StatelessWidget {
  final List<AyahTafsirEntry> entries;
  final List<Map<String, Object?>> tafsirBooks;
  final Map<String, String> sourceLabels;
  final Set<String> selection;
  final String lang;
  final int surah;
  final int ayah;
  final void Function(String key) onToggle;
  final VoidCallback onBackToCards;
  const _CompareView({
    required this.entries,
    required this.tafsirBooks,
    required this.sourceLabels,
    required this.selection,
    required this.lang,
    required this.surah,
    required this.ayah,
    required this.onToggle,
    required this.onBackToCards,
  });

  @override
  Widget build(BuildContext context) {
    // Same grouping as the cards view (TAFSIR_UNIFIED_ARCHITECTURE.md):
    // Arabic tafsir_entries + the 122 bundled corpus books under «تفاسير»,
    // the ~44 translation tafsir_entries under «ترجمات» — so the compare
    // picker finally offers everything the cards view already does.
    final tafsirItems = [
      for (final e in entries.where((e) => e.language == 'ar'))
        _CompareSource(key: 'e:${e.source}', label: sourceLabels[e.source] ?? e.source, text: e.text),
      for (final b in tafsirBooks)
        _CompareSource(key: 'b:${b['id']}', label: '${b['name'] ?? b['short'] ?? ''}', bookId: b['id'] as int?),
    ];
    final translationItems = [
      for (final e in entries.where((e) => e.language != 'ar'))
        _CompareSource(
          key: 'e:${e.source}',
          label: '${sourceLabels[e.source] ?? e.source} (${QuranSearchRepository.languageLabels[e.language] ?? e.language})',
          text: e.text,
        ),
    ];
    final byKey = {for (final s in [...tafsirItems, ...translationItems]) s.key: s};

    Widget chipGroup(List<_CompareSource> items) => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map((s) => ChoiceChip(
                    label: Text(s.label, style: const TextStyle(fontSize: 12)),
                    selected: selection.contains(s.key),
                    onSelected: (_) => onToggle(s.key),
                  ))
              .toList(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onBackToCards,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(basicText('exit_compare_action', lang)),
              ),
              const Spacer(),
              Text(basicText('pick_two_to_four_sources', lang), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 190),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tafsirItems.isNotEmpty) ...[
                    _SectionHeader(basicText('ql_tafsir_section', lang)),
                    chipGroup(tafsirItems),
                  ],
                  if (translationItems.isNotEmpty) ...[
                    _SectionHeader(basicText('ql_translation_section', lang)),
                    chipGroup(translationItems),
                  ],
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 20),
        Expanded(
          child: selection.length < 2
              ? Center(child: Text(basicText('pick_two_to_four_sources', lang), style: const TextStyle(color: AppColors.textMuted)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: selection.map((k) => byKey[k]).whereType<_CompareSource>().map((s) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppColors.surfaceCard,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: const BorderSide(color: AppColors.divider)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: s.bookId != null
                            ? _CompareBookBody(bookId: s.bookId!, label: s.label, surah: surah, ayah: ayah, lang: lang)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(s.label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.textMuted),
                                        tooltip: basicText('share_action', lang),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => Share.share('${s.label}\n\n${s.text}'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(s.text ?? '', textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 14, height: 1.8)),
                                ],
                              ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

/// A selected corpus-book source's card body — its ayah text isn't
/// preloaded (unlike `tafsir_entries`), so it's fetched on demand through
/// the same `QuranBookCache` the single-source reader already uses.
class _CompareBookBody extends StatelessWidget {
  final int bookId;
  final String label;
  final int surah;
  final int ayah;
  final String lang;
  const _CompareBookBody({required this.bookId, required this.label, required this.surah, required this.ayah, required this.lang});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Object?>?>(
      future: QuranBookCache.instance.tafsirEntry(bookId, surah, ayah),
      builder: (context, snapshot) {
        final row = snapshot.data;
        final text = row?['text'] as String?;
        final isMirror = row?['mirror'] == true;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                if (text != null)
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.textMuted),
                    tooltip: basicText('share_action', lang),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Share.share('$label\n\n$text'),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            if (snapshot.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (isMirror)
              Text(basicText('ql_tafsir_mirror', lang), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5))
            else if (text == null)
              Text(basicText('no_tafsir_for_this_ayah', lang), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5))
            else
              SelectableText(text, textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 14, height: 1.8)),
          ],
        );
      },
    );
  }
}
