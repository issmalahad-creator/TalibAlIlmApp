import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/quran_search_repository.dart';
import '../services/language_preference_service.dart';
import '../services/text_scale_preference_service.dart';
import '../theme/app_theme.dart';

/// "دراسة الآية" — QURAN_COMPANION_ROADMAP.md Phase 72. Turns one ayah into
/// a study hub: every real tafsir/translation source available for it as
/// cards, a full reader with prev/next-ayah swipe (no need to back out to
/// the card list between ayat), and a side-by-side comparison of 2-4
/// sources. Deterministic only — every word shown here is a real stored
/// text from `tafsir_entries` (see `quran_reading_repository.dart`'s
/// `tafsirEntriesForAyah`); nothing is generated or summarized by AI,
/// matching Ismail's explicit "لا AI، كله رياضيات" rule for anything
/// student-facing, confirmed again for this specific feature 2026-08-22.
class AyahStudyScreen extends StatefulWidget {
  final int surah;
  final int ayah;
  const AyahStudyScreen({super.key, required this.surah, required this.ayah});

  @override
  State<AyahStudyScreen> createState() => _AyahStudyScreenState();
}

enum _StudyMode { cards, reader, compare }

class _AyahStudyScreenState extends State<AyahStudyScreen> {
  final _repo = QuranReadingRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};
  static final _sourceLabels = {for (final s in QuranSearchRepository.tafsirSources) s.$1: s.$2};

  late int _surah = widget.surah;
  late int _ayah = widget.ayah;
  QuranAyahText? _currentAyah;
  List<AyahTafsirEntry> _entries = [];
  bool _loading = true;

  _StudyMode _mode = _StudyMode.cards;
  String? _readerSource;
  final Set<String> _compareSelection = {};

  bool _sepia = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ayahText = await _repo.ayahAt(_surah, _ayah);
    final entries = await _repo.tafsirEntriesForAyah(_surah, _ayah);
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
      _loading = false;
      // A source that no longer has an entry on the new ayah (the
      // Ibn Ashur/Al-Kahf gap, or any other real gap) drops the reader
      // back to the card list instead of showing a stale/blank source.
      if (_readerSource != null && !entries.any((e) => e.source == _readerSource)) {
        _mode = _StudyMode.cards;
        _readerSource = null;
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
  }

  void _openReader(String source) {
    setState(() {
      _mode = _StudyMode.reader;
      _readerSource = source;
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
                  Expanded(
                    child: switch (_mode) {
                      _StudyMode.cards => _CardsView(
                          entries: _entries,
                          sourceLabels: _sourceLabels,
                          lang: lang,
                          onOpenReader: _openReader,
                          onStartCompare: () => setState(() => _mode = _StudyMode.compare),
                        ),
                      _StudyMode.reader => _ReaderView(
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
                          sourceLabels: _sourceLabels,
                          selection: _compareSelection,
                          lang: lang,
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

class _CardsView extends StatelessWidget {
  final List<AyahTafsirEntry> entries;
  final Map<String, String> sourceLabels;
  final String lang;
  final void Function(String source) onOpenReader;
  final VoidCallback onStartCompare;
  const _CardsView({
    required this.entries,
    required this.sourceLabels,
    required this.lang,
    required this.onOpenReader,
    required this.onStartCompare,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
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
        ...entries.map((e) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(sourceLabels[e.source] ?? e.source, style: const TextStyle(fontWeight: FontWeight.w700))),
                    // Several sources share an identical organizational
                    // label across languages (e.g. several "Rowwad
                    // Translation Center" editions) — without this tag
                    // those cards would be indistinguishable by title alone.
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                      child: Text(QuranSearchRepository.languageLabels[e.language] ?? e.language, style: const TextStyle(fontSize: 10.5, color: AppColors.primaryDark)),
                    ),
                  ],
                ),
                subtitle: Text(
                  e.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.6),
                ),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => onOpenReader(e.source),
              ),
            )),
      ],
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
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(sourceLabels[source] ?? source, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (entry != null) Text(QuranSearchRepository.languageLabels[entry.language] ?? entry.language, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                entry?.text ?? basicText('no_tafsir_for_this_ayah', lang),
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

class _CompareView extends StatelessWidget {
  final List<AyahTafsirEntry> entries;
  final Map<String, String> sourceLabels;
  final Set<String> selection;
  final String lang;
  final void Function(String source) onToggle;
  final VoidCallback onBackToCards;
  const _CompareView({
    required this.entries,
    required this.sourceLabels,
    required this.selection,
    required this.lang,
    required this.onToggle,
    required this.onBackToCards,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: entries.map((e) {
              final selected = selection.contains(e.source);
              return ChoiceChip(
                label: Text('${sourceLabels[e.source] ?? e.source} (${QuranSearchRepository.languageLabels[e.language] ?? e.language})', style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (_) => onToggle(e.source),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 20),
        Expanded(
          child: selection.length < 2
              ? Center(child: Text(basicText('pick_two_to_four_sources', lang), style: const TextStyle(color: AppColors.textMuted)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: entries.where((e) => selection.contains(e.source)).map((e) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sourceLabels[e.source] ?? e.source, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                          const SizedBox(height: 6),
                          Text(e.text, textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 14, height: 1.8)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
