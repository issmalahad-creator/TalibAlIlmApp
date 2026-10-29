import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/mistake_log_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'mushaf_semantic_reader_screen.dart';
import 'page_recitation_screen.dart';

/// «سجل الأخطاء» — one organised log (ت5 of
/// `docs/memorization/RECITATION_REBUILD_PLAN.md`).
///
/// Word-level recitation mistakes and self-rated page reviews, read together
/// by [MistakeLogRepository]: page → ayah → newest first, each mistake named
/// by its kind (ناقص / مُبدَّل / زيادة). Every ayah opens the muṣḥaf page with
/// that ayah lit, or re-recites just that ayah. A page with repeated mistakes
/// gets a quiet suggestion to review it sooner — advice only, nothing is
/// rescheduled.
class RecitationMistakesScreen extends StatefulWidget {
  const RecitationMistakesScreen({super.key});

  @override
  State<RecitationMistakesScreen> createState() => _RecitationMistakesScreenState();
}

const _red = Color(0xFFC0392B);
const _amber = Color(0xFFB5651D);

class _RecitationMistakesScreenState extends State<RecitationMistakesScreen> {
  final _repo = MistakeLogRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  List<PageMistakes> _pages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pages = await _repo.pages();
    if (!mounted) return;
    setState(() {
      _pages = pages;
      _loading = false;
    });
  }

  Future<void> _openMushaf(int page, int surah, int ayah) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MushafSemanticReaderScreen(initialPage: page, focusAyah: (surah: surah, ayah: ayah))),
    );
  }

  Future<void> _recite(int page, int surah, int ayah) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PageRecitationScreen(pageNumber: page, onlyAyah: (surah: surah, ayah: ayah))),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(basicText('recitation_mistakes_title', lang))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _pages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(basicText('recitation_mistakes_empty', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pages.length,
                    itemBuilder: (context, i) => _pageCard(_pages[i], lang),
                  ),
      ),
    );
  }

  Widget _pageCard(PageMistakes p, String lang) {
    final first = p.byAyah.keys.isNotEmpty ? p.byAyah.keys.first : (p.pageLevel.first.surah, p.pageLevel.first.ayah);
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.divider)),
      child: ExpansionTile(
        shape: const Border(),
        initiallyExpanded: _pages.length <= 3,
        leading: CircleAvatar(
          backgroundColor: _red.withValues(alpha: 0.12),
          child: Text('${p.total}', style: const TextStyle(color: _red, fontWeight: FontWeight.w800)),
        ),
        title: Text('${basicText('page_label', lang)} ${p.page} — ${_surahNames[first.$1] ?? first.$1}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(p.lastDate, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        children: [
          if (p.total >= 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(basicText('mistake_page_advice', lang), style: const TextStyle(color: _amber, fontSize: 12.5)),
            ),
          for (final e in p.pageLevel) _selfRatedRow(p.page, e, lang),
          for (final entry in p.byAyah.entries) _ayahBlock(p.page, entry.key.$1, entry.key.$2, entry.value, lang),
        ],
      ),
    );
  }

  Widget _selfRatedRow(int page, MistakeEntry e, String lang) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.flag_outlined, color: _amber),
        title: Text(basicText('mistake_kind_self_rated', lang)),
        subtitle: Text([if ((e.note ?? '').trim().isNotEmpty) e.note!.trim(), e.date].join(' · ')),
        onTap: () => _openMushaf(page, e.surah, e.ayah),
      );

  Widget _ayahBlock(int page, int surah, int ayah, List<MistakeEntry> entries, String lang) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${_surahNames[surah] ?? surah} — ${basicText('ayah_label', lang)} $ayah', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final e in entries) _entryRow(e, lang),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => _openMushaf(page, surah, ayah),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: Text(basicText('mistake_open_in_mushaf', lang)),
              ),
              TextButton.icon(
                onPressed: () => _recite(page, surah, ayah),
                icon: const Icon(Icons.mic_none_rounded, size: 18),
                label: Text(basicText('recitation_redo_ayah', lang)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _entryRow(MistakeEntry e, String lang) {
    final (label, color) = switch (e.kind) {
      MistakeKind.omission => (basicText('mistake_kind_omission', lang), _amber),
      MistakeKind.substitution => (basicText('mistake_kind_substitution', lang), _red),
      MistakeKind.addition => (basicText('mistake_kind_addition', lang), _red),
      MistakeKind.selfRated => (basicText('mistake_kind_self_rated', lang), _amber),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          if (e.word != null)
            Text(e.word!, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 18)),
          if (e.kind == MistakeKind.addition) Text('×${e.count}', style: const TextStyle(color: AppColors.textMuted)),
          if (e.said != null && e.kind == MistakeKind.substitution)
            Flexible(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Text(
                  basicText('mistake_said_instead', lang).replaceAll('{w}', e.said!),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ),
          const Spacer(),
          Text(e.date, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
