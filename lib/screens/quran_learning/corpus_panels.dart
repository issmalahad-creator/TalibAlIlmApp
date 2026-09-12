import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../repositories/quran_book_cache.dart';
import '../../repositories/quran_corpus_repository.dart';
import '../../repositories/quran_reading_repository.dart';
import '../../repositories/quran_search_repository.dart';
import '../../theme/app_theme.dart';

/// Phase 80 / QC3 — the **Quran Corpus** surfaced on the mushaf.
///
/// Four self-contained panels that hang off the Word / Ayah Knowledge
/// Surfaces ([knowledge_surface.dart]) and read only from
/// [QuranCorpusRepository] + [QuranBookCache] over the canonical
/// `(surah, ayah[, word_index])` spine:
///
///  * [WordCorpusPanel]   — ṣarf (QAC), syntactic iʿrāb (Treebank), غريب
///                          الكلمة, and the qirāʾāt phrases that touch the
///                          tapped word.
///  * [AyahCorpusPanel]   — سبب النزول · إعراب من الكتب · الناسخ والمنسوخ ·
///                          غريب الآية · الفوائد · المتشابهات · الآثار ·
///                          الموضوعات.
///  * [AyahTafsirPanel]   — a picker over the 122 bundled tafsīrs (the ~27
///                          overflow books say "عبر الإنترنت — قريبًا").
///  * [AyahTranslationPanel] — a language + edition picker over the 138
///                          bundled translation editions.
///
/// Every block carries its source line. A block with nothing to show is
/// omitted; a panel with nothing at all shows the calm
/// «لا توجد بيانات موثقة» — never a guess, never a silent empty section.

const Color _kGold = Color(0xFFD9A441);

// Fixed source citations — kept as literals (not `basicText`) so the
// licence-required credit is always present verbatim, never subject to a
// missing-translation fallback (`quran-engineering` skill: visible
// corpus.quran.com credit + link).
const String _srcQac =
    'Quranic Arabic Corpus — corpus.quran.com · GNU GPL';
const String _srcTreebank = 'The Quranic Treebank (NoorBayan) · MIT';
const String _srcQuranpedia = 'Quranpedia.net';
const String _srcNasekh = 'الإيضاح لناسخ القرآن ومنسوخه';

// ─────────────────────────── shared helpers ────────────────────────────

final RegExp _harakaRe =
    RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭـ]');
final RegExp _wsRe = RegExp(r'\s+');

// `stripCorpusHtml` now lives in `quran_corpus_repository.dart` (imported
// above) — shared with `corpusEntriesForAyah` so the quick-card and the
// دراسة الآية deep page always render the exact same underlying text.

/// Skeleton form for loose Arabic matching (harakāt dropped, alif / yāʾ /
/// tāʾ-marbūṭa / hamza unified, whitespace removed). Same intent as the
/// ingest-time `norm()` in `tool/build_alignments.py`.
String _norm(String s) => s
    .replaceAll(_harakaRe, '')
    .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .replaceAll('ء', '')
    .replaceAll(_wsRe, '')
    .trim();

Widget _calmNoData(String lang) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          basicText('ql_no_data_element', lang),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
      ),
    );

Widget _calmMessage(String msg) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
      ),
    );

/// A quiet, non-animating "loading" placeholder — the surface already shows
/// one spinner for the primary result; a second would just be noise (and it
/// keeps widget tests free of a perpetual animation).
Widget _dots() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text('···',
            style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
      ),
    );

Widget _sourceLine(String? text) {
  if (text == null || text.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
    ),
  );
}

/// Collapsible corpus block, styled to match `knowledge_surface.dart`'s
/// `_block` but expandable — a study surface can carry a dozen of these
/// without becoming a wall of text (خطة القارئ الموحّد §4، progressive
/// disclosure).
class _CorpusSection extends StatefulWidget {
  final String title;
  final String? source;
  final Widget child;
  final bool open;
  const _CorpusSection({
    required this.title,
    required this.child,
    this.source,
    this.open = false,
  });

  @override
  State<_CorpusSection> createState() => _CorpusSectionState();
}

class _CorpusSectionState extends State<_CorpusSection> {
  late bool _open = widget.open;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 160),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState:
                _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.child,
                  _sourceLine(widget.source),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

Widget _rtl(String text,
        {double size = 12.5, double height = 1.8, int? maxLines}) =>
    Text(
      text,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: TextStyle(fontSize: size, height: height),
    );

/// A short, fast-to-read excerpt. The Knowledge Surface is a **quick card**,
/// not a reader — anything long lives on the dedicated ayah page («للمزيد»).
String excerpt(String s, {int maxChars = 300}) {
  final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.length <= maxChars) return t;
  var cut = t.lastIndexOf(' ', maxChars);
  if (cut < maxChars * 0.6) cut = maxChars;
  return '${t.substring(0, cut).trimRight()}…';
}

/// Full-width «للمزيد» affordance — the single, obvious way out of the card
/// into the deep page. Rendered only when a destination is wired.
Widget moreButton(String label, VoidCallback? onTap) {
  if (onTap == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.menu_book_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kGold,
          side: BorderSide(color: _kGold.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    ),
  );
}

Widget _bookLabel(String name) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Text(
        name,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark),
      ),
    );

// ═══════════════════════════════ WORD ══════════════════════════════════

class WordCorpusPanel extends StatefulWidget {
  final int surah;
  final int ayah;
  final int wordIndex;
  final String lang;
  const WordCorpusPanel({
    super.key,
    required this.surah,
    required this.ayah,
    required this.wordIndex,
    required this.lang,
  });

  @override
  State<WordCorpusPanel> createState() => _WordCorpusPanelState();
}

class _WordCorpusPanelState extends State<WordCorpusPanel> {
  final _repo = QuranCorpusRepository();

  bool _loading = true;
  Map<String, dynamic>? _sarf; // the tapped word's QAC morphology entry
  List<Map<String, dynamic>> _tokens = []; // Treebank tokens for this word
  List<MapEntry<String, String>> _gloss = []; // book → غريب meaning
  List<Map<String, dynamic>> _qiraat = []; // {text, readers}

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WordCorpusPanel old) {
    super.didUpdateWidget(old);
    if (old.surah != widget.surah ||
        old.ayah != widget.ayah ||
        old.wordIndex != widget.wordIndex) {
      setState(() => _loading = true);
      _load();
    }
  }

  Future<void> _load() async {
    final s = widget.surah, a = widget.ayah, wi = widget.wordIndex;

    Map<String, dynamic>? sarf;
    final rawSarf = await _repo.morphologyForWord(s, a, wi);
    if (rawSarf is Map) sarf = rawSarf.cast<String, dynamic>();
    final ref = sarf != null ? _norm('${sarf['text'] ?? ''}') : '';
    final qac = await _repo.qacWordFor(s, a, wi);

    final tokens = <Map<String, dynamic>>[];
    if (qac != null) {
      final syn = await _repo.syntax(s, a);
      if (syn is Map) {
        for (final sent in (syn['sentences'] as List? ?? const [])) {
          for (final w in ((sent as Map)['words'] as List? ?? const [])) {
            if ((w as Map)['number'] == qac) {
              for (final t in (w['tokens'] as List? ?? const [])) {
                tokens.add((t as Map).cast<String, dynamic>());
              }
            }
          }
        }
      }
    }

    final gloss = <MapEntry<String, String>>[];
    if (ref.isNotEmpty) {
      final gm = await _repo.wordMeanings(s, a);
      if (gm is List) {
        for (final book in gm) {
          final bi = (book as Map)['book_info'];
          final name = bi is Map ? '${bi['name'] ?? ''}' : '';
          for (final w in (book['words'] as List? ?? const [])) {
            final wt = _norm('${(w as Map)['text'] ?? ''}');
            if (wt.isEmpty) continue;
            if (wt == ref || wt.contains(ref) || ref.contains(wt)) {
              final m = '${w['meaning'] ?? ''}'.trim();
              if (m.isNotEmpty) gloss.add(MapEntry(name, m));
            }
          }
        }
      }
    }

    final qir = <Map<String, dynamic>>[];
    if (ref.isNotEmpty) {
      final q = await _repo.qiraat(s, a);
      if (q is List) {
        for (final grp in q) {
          final phrase = _norm('${(grp as Map)['ayah_word'] ?? ''}');
          if (phrase.isEmpty || !phrase.contains(ref)) continue;
          for (final qq in (grp['qiraat'] as List? ?? const [])) {
            final txt = '${(qq as Map)['qiraa_text'] ?? ''}'.trim();
            if (txt.isEmpty) continue;
            final readers = <String>{};
            for (final rw in (qq['rewayat'] as List? ?? const [])) {
              final qa = ((rw as Map)['rawi'] as Map?)?['qiraa'];
              if (qa is Map && qa['short_name'] != null) {
                readers.add('${qa['short_name']}');
              }
            }
            qir.add({'text': txt, 'readers': readers.toList()});
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _sarf = sarf;
      _tokens = tokens;
      _gloss = gloss;
      _qiraat = qir;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    if (_loading) return _dots();
    if (_sarf == null &&
        _tokens.isEmpty &&
        _gloss.isEmpty &&
        _qiraat.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 2),
          child: Text(
            basicText('ql_word_sciences', lang),
            textDirection: TextDirection.rtl,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppColors.textDark),
          ),
        ),
        if (_sarf != null) _sarfSection(lang, _sarf!),
        if (_tokens.isNotEmpty) _iraabSection(lang),
        if (_gloss.isNotEmpty) _ghareebSection(lang),
        if (_qiraat.isNotEmpty) _qiraatSection(lang),
      ],
    );
  }

  Widget _sarfSection(String lang, Map<String, dynamic> w) {
    final segs = (w['segments'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    Map<String, dynamic>? stem;
    for (final s in segs) {
      if (s['role'] == 'stem') {
        stem = s;
        break;
      }
    }
    stem ??= segs.isNotEmpty ? segs.last : null;

    final rows = <Widget>[];
    void kv(String k, Object? v) {
      final s = '${v ?? ''}'.trim();
      if (s.isEmpty) return;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: RichText(
          textDirection: TextDirection.rtl,
          text: TextSpan(
            style: const TextStyle(
                fontSize: 12.5, height: 1.7, color: AppColors.textDark),
            children: [
              TextSpan(
                  text: '$k: ',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
              TextSpan(text: s),
            ],
          ),
        ),
      ));
    }

    if (stem != null) {
      kv(basicText('ql_word_type', lang), stem['pos']);
      kv(basicText('ql_sign', lang), stem['inflection']);
      final quals = (stem['qualifiers'] as List? ?? const []).join('، ');
      kv(basicText('ql_features', lang), quals);
      kv(basicText('ql_root', lang), stem['root']);
      kv(basicText('ql_lemma', lang), stem['lemma']);
      kv(basicText('ql_pattern', lang), stem['pattern']);
    }
    final translit = [
      if ('${w['phonetic'] ?? ''}'.isNotEmpty) '${w['phonetic']}',
      if ('${w['translation'] ?? ''}'.isNotEmpty) '${w['translation']}',
    ].join('  ·  ');
    if (translit.isNotEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(translit,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ));
    }

    if (segs.length > 1) {
      rows.add(const SizedBox(height: 6));
      rows.add(Text(basicText('ql_word_structure', lang),
          textDirection: TextDirection.rtl,
          style: const TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700)));
      for (final sg in segs) {
        final desc = '${sg['description'] ?? sg['pos'] ?? ''}'.trim();
        rows.add(_rtl('• ${sg['form'] ?? ''} — $desc', size: 12, height: 1.7));
      }
    }

    return _CorpusSection(
      title: basicText('ql_domain_sarf', lang),
      open: true,
      source:
          '${basicText('ql_source', lang)}: $_srcQac',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }

  Widget _iraabSection(String lang) {
    final orderLbl = basicText('mushaf_word_order_label', lang);
    return _CorpusSection(
      title: basicText('ql_iraab_syntax', lang),
      source:
          '${basicText('ql_source', lang)}: $_srcTreebank',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final t in _tokens)
            _rtl(
              '• ${t['text'] ?? ''}'
              '${(t['pos'] ?? '') != '' ? '  ·  ${t['pos']}' : ''}'
              '${(t['rel_ar'] ?? t['rel'] ?? '') != '' ? '  ·  ${t['rel_ar'] ?? t['rel']}' : ''}'
              '${t['head'] is Map && (t['head'] as Map)['word'] != null ? '  →  $orderLbl ${(t['head'] as Map)['word']}' : ''}',
              size: 12,
              height: 1.7,
            ),
        ],
      ),
    );
  }

  Widget _ghareebSection(String lang) {
    return _CorpusSection(
      title: basicText('ql_ghareeb_word', lang),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in _gloss) ...[
            if (e.key.isNotEmpty) _bookLabel(e.key),
            _rtl(e.value, size: 12.5),
          ],
        ],
      ),
    );
  }

  Widget _qiraatSection(String lang) {
    return _CorpusSection(
      title: basicText('ql_qiraat', lang),
      source:
          '${basicText('ql_source', lang)}: $_srcQuranpedia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final q in _qiraat) ...[
            _rtl('• ${q['text']}', size: 12.5),
            if ((q['readers'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 4),
                child: Text(
                  '${basicText('ql_readers', lang)}: ${(q['readers'] as List).join('، ')}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════ AYAH ══════════════════════════════════

class AyahCorpusPanel extends StatefulWidget {
  final int surah;
  final int ayah;
  final String lang;

  /// QC4 hook — tapping a topic chip will drive the Knowledge Index search.
  final void Function(int topicId, String name)? onTopicTap;

  /// «للمزيد» — opens the dedicated ayah page for the full text of any of
  /// these layers. The card only ever shows short excerpts.
  final VoidCallback? onOpenFull;

  const AyahCorpusPanel({
    super.key,
    required this.surah,
    required this.ayah,
    required this.lang,
    this.onTopicTap,
    this.onOpenFull,
  });

  @override
  State<AyahCorpusPanel> createState() => _AyahCorpusPanelState();
}

class _AyahCorpusPanelState extends State<AyahCorpusPanel> {
  final _repo = QuranCorpusRepository();
  bool _loading = true;

  List<Map<String, Object?>> _asbab = [];
  List<Map<String, Object?>> _iraab = [];
  String _nasekh = '';
  List _notes = [];
  List _similar = [];
  List _sayings = [];
  List<Map<String, Object?>> _topics = [];
  List _ghareeb = [];
  List _qiraat = [];
  List<Map<String, Object?>> _riwayat = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AyahCorpusPanel old) {
    super.didUpdateWidget(old);
    if (old.surah != widget.surah || old.ayah != widget.ayah) {
      setState(() => _loading = true);
      _load();
    }
  }

  Future<void> _load() async {
    final s = widget.surah, a = widget.ayah;
    final asbab = await _repo.asbab(s, a);
    final iraab = await _repo.irabProse(s, a);
    final nasekhRaw = await _repo.nasekh(s, a);
    final notes = await _repo.notes(s, a);
    final similar = await _repo.similar(s, a);
    final sayings = await _repo.sayings(s, a);
    final topics = await _repo.topicsForAyah(s, a);
    final gm = await _repo.wordMeanings(s, a);
    final qiraat = await _repo.qiraat(s, a);
    final riwayat = await _repo.riwayat();

    if (!mounted) return;
    setState(() {
      _asbab = asbab;
      _iraab = iraab;
      _nasekh = nasekhRaw is Map ? stripCorpusHtml(nasekhRaw['html']) : '';
      _notes = notes is List ? notes : const [];
      _similar = similar is List ? similar : const [];
      _sayings = sayings is List ? sayings : const [];
      _topics = topics;
      _ghareeb = gm is List ? gm : const [];
      _qiraat = qiraat is List ? qiraat : const [];
      _riwayat = riwayat;
      _loading = false;
    });
  }

  bool get _empty =>
      _asbab.isEmpty &&
      _iraab.isEmpty &&
      _nasekh.isEmpty &&
      _notes.isEmpty &&
      _similar.isEmpty &&
      _sayings.isEmpty &&
      _topics.isEmpty &&
      _ghareeb.isEmpty &&
      _qiraat.isEmpty &&
      _riwayat.isEmpty;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    if (_loading) return _dots();
    if (_empty) return _calmNoData(lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_asbab.isNotEmpty) _asbabSection(lang),
        if (_iraab.isNotEmpty) _iraabProseSection(lang),
        if (_nasekh.isNotEmpty) _nasekhSection(lang),
        if (_ghareeb.isNotEmpty) _ghareebSection(lang),
        if (_notes.isNotEmpty) _notesSection(lang),
        if (_similar.isNotEmpty) _similarSection(lang),
        if (_sayings.isNotEmpty) _sayingsSection(lang),
        if (_qiraat.isNotEmpty) _qiraatSection(lang),
        if (_riwayat.isNotEmpty) _riwayatSection(lang),
        if (_topics.isNotEmpty) _topicsSection(lang),
        moreButton(basicText('ql_open_ayah_page', lang), widget.onOpenFull),
      ],
    );
  }

  Widget _qiraatSection(String lang) => _CorpusSection(
        title: basicText('ql_qiraat', lang),
        source: '${basicText('ql_source', lang)}: $_srcQuranpedia',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final grp in _qiraat.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ('${(grp as Map)['ayah_word'] ?? ''}'.isNotEmpty)
                      _rtl('﴿ ${grp['ayah_word']} ﴾',
                          size: 12, height: 1.6),
                    for (final qq in (grp['qiraat'] as List? ?? const []))
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _rtl('• ${excerpt('${(qq as Map)['qiraa_text'] ?? ''}', maxChars: 200)}',
                                size: 12, height: 1.7),
                            if (_qReaders(qq).isNotEmpty)
                              Text(
                                '${basicText('ql_readers', lang)}: ${_qReaders(qq).join('، ')}',
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );

  List<String> _qReaders(Object? qq) {
    final out = <String>{};
    if (qq is Map) {
      for (final rw in (qq['rewayat'] as List? ?? const [])) {
        final qa = ((rw as Map)['rawi'] as Map?)?['qiraa'];
        if (qa is Map && qa['short_name'] != null) out.add('${qa['short_name']}');
      }
    }
    return out.toList();
  }

  Widget _riwayatSection(String lang) => _CorpusSection(
        title: basicText('ql_riwayat_section', lang),
        source: '${basicText('ql_source', lang)}: $_srcQuranpedia',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in _riwayat)
              _RiwayaBox(
                key: ValueKey('${r['id']}-${widget.surah}-${widget.ayah}'),
                riwayaId: r['id'] as int,
                name: '${r['name'] ?? ''}'
                    '${'${r['rawi'] ?? ''}'.isNotEmpty ? ' — ${r['rawi']}' : ''}',
                primary: r['is_primary'] == 1,
                surah: widget.surah,
                ayah: widget.ayah,
                lang: lang,
              ),
          ],
        ),
      );

  Widget _fromBooks(List<Map<String, Object?>> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in rows) ...[
            _bookLabel('${r['name'] ?? r['short'] ?? ''}'
                '${(r['author'] ?? '') != '' ? ' — ${r['author']}' : ''}'),
            _rtl(excerpt(stripCorpusHtml(r['html']), maxChars: 200), size: 12.5),
          ],
        ],
      );

  Widget _asbabSection(String lang) => _CorpusSection(
        title: basicText('ql_asbab', lang),
        open: true,
        source:
            '${basicText('ql_source', lang)}: $_srcQuranpedia',
        child: _fromBooks(_asbab),
      );

  Widget _iraabProseSection(String lang) => _CorpusSection(
        title: basicText('ql_iraab_prose', lang),
        source:
            '${basicText('ql_source', lang)}: $_srcQuranpedia',
        child: _fromBooks(_iraab),
      );

  Widget _nasekhSection(String lang) => _CorpusSection(
        title: basicText('ql_nasekh', lang),
        source:
            '${basicText('ql_source', lang)}: $_srcNasekh',
        child: _rtl(excerpt(_nasekh, maxChars: 200), size: 12.5),
      );

  Widget _ghareebSection(String lang) => _CorpusSection(
        title: basicText('ql_ghareeb_ayah', lang),
        source:
            '${basicText('ql_source', lang)}: $_srcQuranpedia',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final book in _ghareeb) ...[
              if (((book as Map)['book_info'] is Map) &&
                  '${(book['book_info'] as Map)['name'] ?? ''}'.isNotEmpty)
                _bookLabel('${(book['book_info'] as Map)['name']}'),
              for (final w in (book['words'] as List? ?? const []))
                _rtl(
                    '• ${(w as Map)['text'] ?? ''}: ${w['meaning'] ?? ''}',
                    size: 12,
                    height: 1.7),
            ],
          ],
        ),
      );

  Widget _notesSection(String lang) => _CorpusSection(
        title: basicText('ql_faidah', lang),
        source: '${basicText('ql_source', lang)}: $_srcQuranpedia',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final n in _notes.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rtl(excerpt(stripCorpusHtml((n as Map)['ar_note']),
                        maxChars: 200),
                        size: 12.5),
                    if ('${n['author'] ?? ''}'.isNotEmpty)
                      Text('— ${n['author']}',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _similarSection(String lang) {
    final tiles = <Widget>[];
    for (final grp in _similar.take(3)) {
      final note = stripCorpusHtml((grp as Map)['notes']);
      if (note.isNotEmpty) {
        tiles.add(_rtl('• ${excerpt(note, maxChars: 200)}', size: 12.5));
      }
      for (final ay in (grp['ayahs'] as List? ?? const [])) {
        final info = (ay as Map)['info'];
        if (info is! Map) continue;
        final t = stripCorpusHtml(info['text']);
        tiles.add(Padding(
          padding: const EdgeInsets.only(right: 10, top: 2, bottom: 4),
          child: Text(
            '﴿ $t ﴾  [${info['surah_id'] ?? '?'}:${info['number'] ?? '?'}]',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 12, height: 1.9),
          ),
        ));
      }
    }
    return _CorpusSection(
      title: basicText('ql_mutashabihat', lang),
      source:
          '${basicText('ql_source', lang)}: $_srcQuranpedia',
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: tiles),
    );
  }

  Widget _sayingsSection(String lang) => _CorpusSection(
        title: basicText('ql_athar', lang),
        source:
            '${basicText('ql_source', lang)}: $_srcQuranpedia',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final sy in _sayings.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ('${(sy as Map)['title'] ?? ''}'.isNotEmpty)
                      _rtl('${sy['title']}',
                          size: 11.5, height: 1.5, maxLines: 2),
                    _rtl(excerpt(stripCorpusHtml(sy['text']), maxChars: 220),
                        size: 12.5),
                    if ((sy['narrators'] as List? ?? const []).isNotEmpty)
                      Text(
                        '${basicText('ql_narrators', lang)}: '
                        '${(sy['narrators'] as List).map((x) => (x as Map)['name']).where((x) => x != null).join('، ')}',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _topicsSection(String lang) => _CorpusSection(
        title: basicText('ql_topics', lang),
        open: true,
        source:
            '${basicText('ql_source', lang)}: $_srcQuranpedia',
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in _topics)
              ActionChip(
                label: Text('${t['name'] ?? ''}',
                    style: const TextStyle(fontSize: 11)),
                onPressed: widget.onTopicTap == null
                    ? null
                    : () => widget.onTopicTap!(
                        t['id'] as int, '${t['name'] ?? ''}'),
                backgroundColor: _kGold.withValues(alpha: 0.08),
                side: BorderSide(color: _kGold.withValues(alpha: 0.25)),
              ),
          ],
        ),
      );
}

// ═════════════════════════════ TAFSIR ═════════════════════════════════

class AyahTafsirPanel extends StatefulWidget {
  final int surah;
  final int ayah;
  final String lang;

  /// «للمزيد» — opens the dedicated ayah tafsir page **on the book
  /// currently selected in this panel's dropdown** (the exact bundled
  /// book id, not a generic "open the ayah page"). The card only ever
  /// shows a short excerpt; deep reading happens there.
  final void Function(int bookId)? onOpenFull;

  const AyahTafsirPanel({
    super.key,
    required this.surah,
    required this.ayah,
    required this.lang,
    this.onOpenFull,
  });

  @override
  State<AyahTafsirPanel> createState() => _AyahTafsirPanelState();
}

class _AyahTafsirPanelState extends State<AyahTafsirPanel> {
  final _repo = QuranCorpusRepository();

  bool _loadingBooks = true;
  bool _loadingText = false;
  List<Map<String, Object?>> _books = [];
  int _bookId = -1;
  String? _text;
  bool _mirror = false;

  static const _prefer = <String>[
    'الميسر', 'المختصر', 'السعدي', 'ابن كثير', 'البغوي', 'الطبري', 'الجلالين',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant AyahTafsirPanel old) {
    super.didUpdateWidget(old);
    if (old.surah != widget.surah || old.ayah != widget.ayah) _loadText();
  }

  Future<void> _init() async {
    final books = await _repo.tafsirBooks();
    if (!mounted) return;
    setState(() {
      _books = books;
      _loadingBooks = false;
      _bookId = _pickDefault() ?? -1;
    });
    if (_bookId != -1) _loadText();
  }

  int? _pickDefault() {
    for (final key in _prefer) {
      for (final b in _books) {
        if (b['bundled'] == 1 &&
            ('${b['name'] ?? ''} ${b['short'] ?? ''}').contains(key)) {
          return b['id'] as int?;
        }
      }
    }
    for (final b in _books) {
      if (b['bundled'] == 1) return b['id'] as int?;
    }
    return _books.isEmpty ? null : _books.first['id'] as int?;
  }

  Future<void> _loadText() async {
    if (_bookId == -1) return;
    setState(() {
      _loadingText = true;
      _text = null;
      _mirror = false;
    });
    final e = await QuranBookCache.instance
        .tafsirEntry(_bookId, widget.surah, widget.ayah);
    if (!mounted) return;
    setState(() {
      _loadingText = false;
      if (e == null) {
        _text = null;
      } else if (e['mirror'] == true) {
        _mirror = true;
      } else {
        _text = '${e['text'] ?? ''}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    if (_loadingBooks) return _dots();
    if (_books.isEmpty) return _calmNoData(lang);

    Map<String, Object?> current = _books.first;
    for (final b in _books) {
      if (b['id'] == _bookId) {
        current = b;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(basicText('ql_choose_tafsir', lang),
            textDirection: TextDirection.rtl,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        DropdownButton<int>(
          isExpanded: true,
          value: _bookId == -1 ? null : _bookId,
          items: [
            for (final b in _books)
              DropdownMenuItem<int>(
                value: b['id'] as int,
                child: Text(
                  '${b['name'] ?? b['short'] ?? ''}'
                  '${b['bundled'] == 1 ? '' : '  · ${basicText('ql_online', lang)}'}',
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _bookId = v);
            _loadText();
          },
        ),
        const SizedBox(height: 8),
        if (_loadingText)
          _dots()
        else if (_mirror)
          _calmMessage(basicText('ql_tafsir_mirror', lang))
        else if (_text == null || _text!.trim().isEmpty)
          _calmNoData(lang)
        else
          // A short excerpt only — the card is a quick read, not a reader.
          Text(
            excerpt(_text!, maxChars: 240),
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 13, height: 1.85),
          ),
        _sourceLine(
          '${basicText('ql_source', lang)}: ${current['name'] ?? ''}'
          '${(current['author'] ?? '') != '' ? ' — ${current['author']}' : ''}'
          '${(current['year'] ?? '') != '' ? ' (${current['year']})' : ''}',
        ),
        moreButton(
          basicText('ql_full_tafsir', lang),
          _bookId == -1 ? null : () => widget.onOpenFull?.call(_bookId),
        ),
      ],
    );
  }
}

// ══════════════════════════ TRANSLATION ═══════════════════════════════

class AyahTranslationPanel extends StatefulWidget {
  final int surah;
  final int ayah;
  final String lang;
  const AyahTranslationPanel({
    super.key,
    required this.surah,
    required this.ayah,
    required this.lang,
  });

  @override
  State<AyahTranslationPanel> createState() => _AyahTranslationPanelState();
}

class _AyahTranslationPanelState extends State<AyahTranslationPanel> {
  final _repo = QuranCorpusRepository();
  final _readingRepo = QuranReadingRepository();

  bool _loadingEds = true;
  List<Map<String, Object?>> _eds = [];
  final Map<String, String> _localeName = {}; // locale → display language
  String _locale = '';

  /// A real explanatory note per language, keyed by locale — the same
  /// QuranEnc-sourced `footnote` field surfaced in `AyahStudyScreen`
  /// (docs/quran/TAFSIR_UNIFIED_ARCHITECTURE.md §5), shown here directly
  /// under the everyday language/edition picker instead of requiring a
  /// separate screen. Only populated when a real footnote exists for this
  /// ayah — never fabricated.
  final Map<String, AyahTafsirEntry> _explainByLocale = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final results = await Future.wait([
      _repo.translationEditions(),
      _readingRepo.tafsirEntriesForAyah(widget.surah, widget.ayah),
    ]);
    if (!mounted) return;
    final eds = results[0] as List<Map<String, Object?>>;
    final entries = results[1] as List<AyahTafsirEntry>;
    for (final e in eds) {
      final loc = '${e['locale'] ?? ''}';
      if (loc.isEmpty) continue;
      _localeName.putIfAbsent(loc, () => '${e['lang'] ?? loc}');
    }
    for (final e in entries) {
      if (e.language == 'ar') continue;
      if (e.footnote == null || e.footnote!.trim().isEmpty) continue;
      _explainByLocale.putIfAbsent(e.language, () => e);
      // A language with a real explanatory note but no bundled edition in
      // this 138-edition corpus still deserves a place in the picker —
      // never drop a language just because only one system has it.
      _localeName.putIfAbsent(
          e.language, () => QuranSearchRepository.languageLabels[e.language] ?? e.language);
    }
    final locs = _localeName.keys.toSet();
    final String locale = locs.contains(widget.lang)
        ? widget.lang
        : locs.contains('en')
            ? 'en'
            : (eds.isEmpty ? '' : '${eds.first['locale'] ?? ''}');
    setState(() {
      _eds = eds;
      _loadingEds = false;
      _locale = locale;
    });
  }

  static String _sourceLabel(String source) {
    for (final t in QuranSearchRepository.tafsirSources) {
      if (t.$1 == source) return t.$2;
    }
    return source;
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    if (_loadingEds) return _dots();
    if (_eds.isEmpty) return _calmNoData(lang);

    final locales = _localeName.keys.toList()
      ..sort((a, b) {
        if (a == 'en') return -1;
        if (b == 'en') return 1;
        return _localeName[a]!.compareTo(_localeName[b]!);
      });
    final editionsForLocale = [
      for (final e in _eds)
        if ('${e['locale'] ?? ''}' == _locale) e,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // language via a plain arrow/dropdown — translations are short, so
        // each edition sits in its own box under the ayah, opened on tap.
        Text(basicText('ql_choose_language', lang),
            style:
                const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        DropdownButton<String>(
          isExpanded: true,
          value: _locale.isEmpty ? null : _locale,
          items: [
            for (final loc in locales)
              DropdownMenuItem<String>(
                value: loc,
                child: Text(_localeName[loc] ?? loc,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
          onChanged: (v) => v == null ? null : setState(() => _locale = v),
        ),
        const SizedBox(height: 8),
        if (editionsForLocale.isEmpty && _explainByLocale[_locale] == null)
          _calmNoData(lang)
        else
          for (var i = 0; i < editionsForLocale.length; i++)
            _TranslationBox(
              key: ValueKey('${editionsForLocale[i]['id']}'
                  '-${widget.surah}-${widget.ayah}'),
              editionId: editionsForLocale[i]['id'] as int,
              name: '${editionsForLocale[i]['name'] ?? editionsForLocale[i]['short'] ?? ''}',
              rtl: '${editionsForLocale[i]['direction'] ?? 'ltr'}' == 'rtl',
              surah: widget.surah,
              ayah: widget.ayah,
              // «تنفتح عند الطلب» — all collapsed; tap the box to read.
              initiallyOpen: false,
              lang: lang,
            ),
        if (_explainByLocale[_locale] != null)
          _ExplanationBox(
            key: ValueKey(
                'explain-$_locale-${widget.surah}-${widget.ayah}'),
            sourceLabel: _sourceLabel(_explainByLocale[_locale]!.source),
            footnote: _explainByLocale[_locale]!.footnote!,
            lang: lang,
          ),
      ],
    );
  }
}

/// A real explanatory note for this ayah in this language — separate from
/// every literal translation box above it, never merged into one of them
/// (same separation principle as `_ReaderView`'s footnote layer in
/// ayah_study_screen.dart / AKHLAQ_TRANSLATION_MODEL.md). Collapsed by
/// default like the edition boxes it sits beside.
class _ExplanationBox extends StatefulWidget {
  final String sourceLabel;
  final String footnote;
  final String lang;
  const _ExplanationBox({
    super.key,
    required this.sourceLabel,
    required this.footnote,
    required this.lang,
  });

  @override
  State<_ExplanationBox> createState() => _ExplanationBoxState();
}

class _ExplanationBoxState extends State<_ExplanationBox> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      size: 16, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(basicText('ql_footnote_section', lang),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: AppColors.primaryDark)),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: AppColors.primaryDark),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.sourceLabel,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Text(widget.footnote,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontSize: 13.5, height: 1.7, color: AppColors.textDark)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One translation edition as a box under the ayah — collapsed by default,
/// loads its (short) text on first open.
class _TranslationBox extends StatefulWidget {
  final int editionId;
  final String name;
  final bool rtl;
  final int surah;
  final int ayah;
  final bool initiallyOpen;
  final String lang;
  const _TranslationBox({
    super.key,
    required this.editionId,
    required this.name,
    required this.rtl,
    required this.surah,
    required this.ayah,
    required this.initiallyOpen,
    required this.lang,
  });

  @override
  State<_TranslationBox> createState() => _TranslationBoxState();
}

class _TranslationBoxState extends State<_TranslationBox> {
  late bool _open = widget.initiallyOpen;
  String? _text;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (_open) _load();
  }

  Future<void> _load() async {
    if (_text != null || _loading) return;
    setState(() => _loading = true);
    final t = await QuranBookCache.instance
        .translation(widget.editionId, widget.surah, widget.ayah);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _text = t ?? '';
    });
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
                    child: _loading
                        ? _dots()
                        : (_text == null || _text!.trim().isEmpty)
                            ? _calmNoData(widget.lang)
                            : Directionality(
                                textDirection: widget.rtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: SelectableText(
                                  _text!,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.9),
                                ),
                              ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One riwāya as a box under the ayah — the ayah's own rasm in that reading
/// (Warsh, Qālūn, al-Dūrī …), in the mushaf script, loaded on first open.
class _RiwayaBox extends StatefulWidget {
  final int riwayaId;
  final String name;
  final bool primary;
  final int surah;
  final int ayah;
  final String lang;
  const _RiwayaBox({
    super.key,
    required this.riwayaId,
    required this.name,
    required this.primary,
    required this.surah,
    required this.ayah,
    required this.lang,
  });

  @override
  State<_RiwayaBox> createState() => _RiwayaBoxState();
}

class _RiwayaBoxState extends State<_RiwayaBox> {
  bool _open = false;
  String? _text;
  String? _marker;
  bool _loading = false;

  Future<void> _load() async {
    if (_text != null || _loading) return;
    setState(() => _loading = true);
    final r = await QuranBookCache.instance
        .riwayaText(widget.riwayaId, widget.surah, widget.ayah);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _text = '${r?['text'] ?? ''}';
      _marker = r?['marker'] as String?;
    });
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.name}'
                      '${widget.primary ? ' · ${basicText('ql_sources_primary', widget.lang)}' : ''}',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(11, 0, 11, 12),
                    child: _loading
                        ? _dots()
                        : (_text == null || _text!.trim().isEmpty)
                            ? _calmNoData(widget.lang)
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                textDirection: TextDirection.rtl,
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      _text!,
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(
                                          fontFamily: 'AmiriQuran',
                                          fontSize: 17,
                                          height: 2.0),
                                    ),
                                  ),
                                  if ((_marker ?? '').isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text('﴿${_marker!}﴾',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted)),
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
