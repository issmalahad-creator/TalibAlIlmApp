import 'package:flutter/material.dart';

import '../../data/quran_surahs.dart';
import '../../l10n/basic_translations.dart';
import '../../models/fiqh_tree.dart';
import '../../repositories/quran_reading_repository.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/knowledge_tree_3d.dart';
import '../ayah_study_screen.dart';
import '../turath_reader_screen.dart';
import 'fiqh_tree_screen.dart';

String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);

/// «السلسلة» (docs/KNOWLEDGE_TREE_ZAD_PLAN.md ش3–ش4): stacked quick cards for
/// one chapter or one ruling — the matn; al-Rawd's explanation of exactly
/// this ruling; the ayat and the Bulugh hadith al-Rawd itself cites for it;
/// the chapter's other hadith from Bulugh al-Maram; and the larger
/// commentaries opened at this chapter in the Turath reader.
class FiqhChainSheet extends StatefulWidget {
  const FiqhChainSheet({super.key, required this.tree, required this.chapter, this.masala});
  final FiqhTree tree;
  final FiqhChapter chapter;
  final FiqhMasala? masala;

  @override
  State<FiqhChainSheet> createState() => _FiqhChainSheetState();
}

class _FiqhChainSheetState extends State<FiqhChainSheet> {
  bool _allHadith = false;
  bool _fullSharh = false;
  final _quran = QuranReadingRepository();
  final Map<(int, int), String> _ayahText = {};

  List<(int, int)> get _ayat => widget.masala?.ayat ?? widget.chapter.ayat;

  @override
  void initState() {
    super.initState();
    for (final k in _ayat) {
      _quran.ayahAt(k.$1, k.$2).then((a) {
        if (mounted && a != null) setState(() => _ayahText[k] = a.text);
      }).catchError((_) {});
    }
  }

  void _openTurath(int bookId, String name, int page) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TurathReaderScreen(bookId: bookId, bookName: name, pageNumber: page)),
      );

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    final m = widget.masala;
    final cited = {for (final h in m?.hadith ?? const <BulughHadith>[]) h.label};
    final chapterHadith = [for (final h in widget.tree.evidenceFor(c)) if (!cited.contains(h.label)) h];
    final shownHadith = _allHadith ? chapterHadith : chapterHadith.take(2).toList();
    final sharh = m?.sharh;
    final rawdTitle = widget.tree.sources['rawd']?['title'] as String? ?? '';
    final bulughTitle = widget.tree.sources['bulugh']?['title'] as String? ?? '';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.66,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: KnowledgeTreePalette.page,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: KnowledgeTreePalette.gold, width: 2)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 10),
            Text('${widget.tree.title} · ${c.title}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: KnowledgeTreePalette.ink)),
            const SizedBox(height: 12),
            if (m != null)
              _Card(
                label: _t('ft_matn'),
                attribution: widget.tree.sources['zad']?['title'] as String? ?? '',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.text, style: const TextStyle(fontSize: 16, height: 1.9, color: AppColors.textDark)),
                    if (m.ruling.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: [for (final r in m.ruling) _RulingChip(r)]),
                    ],
                  ],
                ),
              ),
            // al-Rawd: this ruling's own explanation, else the chapter's opening
            _Card(
              label: _t('ft_sharh'),
              attribution: '$rawdTitle · ${c.sharhChapter}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sharh ?? c.sharhExcerpt,
                    maxLines: _fullSharh ? null : 7,
                    overflow: _fullSharh ? TextOverflow.visible : TextOverflow.fade,
                    style: const TextStyle(fontSize: 14.5, height: 1.9, color: AppColors.textDark),
                  ),
                  Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      if (sharh != null && sharh.length > 420 && !_fullSharh)
                        TextButton(onPressed: () => setState(() => _fullSharh = true), child: Text(_t('ft_read_more'))),
                      TextButton.icon(
                        onPressed: () => _openTurath(widget.tree.turathRawdId, rawdTitle, c.sharhPage),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: Text(_t('ft_read_sharh')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_ayat.isNotEmpty)
              _Card(
                label: _t('ft_from_quran'),
                attribution: _t('ft_cited_by_rawd'),
                child: Column(
                  children: [
                    for (final k in _ayat)
                      InkWell(
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => AyahStudyScreen(surah: k.$1, ayah: k.$2))),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_ayahText[k] != null)
                                Text(_ayahText[k]!,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 18, height: 1.9)),
                              Text('${surahName(k.$1)} · ${k.$2}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (m != null && m.hadith.isNotEmpty)
              _Card(
                label: _t('ft_from_sunnah'),
                attribution: bulughTitle,
                note: _t('ft_sunnah_note'),
                child: Column(children: [for (final h in m.hadith) _HadithTile(h)]),
              ),
            if (chapterHadith.isNotEmpty)
              _Card(
                label: _t('ft_evidence'),
                attribution: '$bulughTitle · ${c.evidenceChapter}',
                note: m == null ? null : _t('ft_evidence_chapter_note'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final h in shownHadith) _HadithTile(h),
                    if (chapterHadith.length > shownHadith.length)
                      TextButton(
                        onPressed: () => setState(() => _allHadith = true),
                        child: Text(_t('ft_show_all').replaceAll('{n}', '${chapterHadith.length}')),
                      ),
                  ],
                ),
              ),
            if (c.more.isNotEmpty)
              _Card(
                label: _t('ft_more_shuruh'),
                attribution: _t('ft_open_at_chapter'),
                child: Column(
                  children: [
                    for (final link in c.more)
                      // its own transparent Material: the white card would hide the ink splash
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.local_library_outlined, color: KnowledgeTreePalette.ink),
                          title: Text(link.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(link.author),
                          trailing: const Icon(Icons.chevron_left_rounded),
                          onTap: () => _openTurath(link.turathId, link.title, link.page),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String surahName(int s) => s >= 1 && s <= quranSurahs.length ? quranSurahs[s - 1].name : '$s';

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.attribution, required this.child, this.note});
  final String label;
  final String attribution;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: KnowledgeTreePalette.ink.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: KnowledgeTreePalette.ink, borderRadius: BorderRadius.circular(20)),
                  child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(attribution,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 6),
              Text(note!, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.5)),
            ],
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class _RulingChip extends StatelessWidget {
  const _RulingChip(this.word);
  final String word;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = rulingStyle([word])!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(word, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _HadithTile extends StatelessWidget {
  const _HadithTile(this.h);
  final BulughHadith h;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 34),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              margin: const EdgeInsetsDirectional.only(end: 8, top: 4),
              decoration: BoxDecoration(
                color: KnowledgeTreePalette.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(h.label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KnowledgeTreePalette.ink)),
            ),
            Expanded(child: Text(h.text, style: const TextStyle(fontSize: 15, height: 1.9, color: AppColors.textDark))),
          ],
        ),
      );
}

/// ش4 — on the ayah's quick card in the mushaf: the fiqh chapters whose
/// explanation (al-Rawd) cites this ayah. Draws nothing when there are none.
class FiqhAyahLinks extends StatefulWidget {
  const FiqhAyahLinks({super.key, required this.surah, required this.ayah});
  final int surah;
  final int ayah;

  @override
  State<FiqhAyahLinks> createState() => _FiqhAyahLinksState();
}

class _FiqhAyahLinksState extends State<FiqhAyahLinks> {
  List<AyahFiqhLink> _links = const [];

  @override
  void initState() {
    super.initState();
    AyahFiqhLink.forAyah(widget.surah, widget.ayah).then((l) {
      if (mounted) setState(() => _links = l);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_links.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_rounded, size: 15, color: KnowledgeTreePalette.ink),
              const SizedBox(width: 6),
              Text(_t('ft_cited_in'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KnowledgeTreePalette.ink)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final l in _links)
                ActionChip(
                  label: Text('${l.kitab.replaceFirst('كتاب ', '')} · ${l.title}', style: const TextStyle(fontSize: 12)),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FiqhTreeScreen(
                      asset: l.asset,
                      openChapterId: l.chapterId,
                      openMasalaId: l.masail.isEmpty ? null : l.masail.first,
                    ),
                  )),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
