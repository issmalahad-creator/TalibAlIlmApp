import 'package:flutter/material.dart';

import '../../data/quran_surahs.dart';
import '../../data/tajweed_rules_ref.dart';
import '../../l10n/basic_translations.dart';
import '../../models/quran_learning.dart';
import '../../models/quran_selection.dart';
import '../../repositories/quran_corpus_repository.dart';
import '../../repositories/quran_learning_repository.dart';
import '../../repositories/quran_reading_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/depth.dart';
import '../../theme/tajweed_palette.dart';
import '../ayah_notebook_screen.dart';
import '../ayah_study_screen.dart';
import '../tajweed_tier_screen.dart';
import 'corpus_panels.dart';
import 'irab_view_screen.dart';
import 'learning_lesson_screen.dart';
import 'topic_index_screen.dart';
import '../usul/usul_tree_screen.dart';

/// خطة القارئ الموحّد — P0 · لوحات المعرفة (`docs/quran/QURAN_PREMIUM_UI.md`).
///
/// Not a plain BottomSheet: a draggable **Knowledge Surface** that keeps the
/// mushaf visible behind it (light scrim, ≥ ~40% of the page still shown),
/// headed by the selected word/ayah itself in the mushaf script, with the
/// science laid out **progressive-disclosure first** — the "seconds" answer
/// (إعراب / علامة / لماذا / علاقة) always visible, details one tap away.
///
/// Identity comes from the central [QuranSelection]; nothing is recomputed.
/// Missing data is stated («لا توجد بيانات موثقة لهذا العنصر حاليًا») — never
/// guessed, never an empty section.

const Color _kGold = Color(0xFFD9A441);

String _surahName(int n) {
  for (final s in quranSurahs) {
    if (s.number == n) return s.name;
  }
  return '$n';
}

/// Resolves to `'applied'` when the reader should KEEP the word selected
/// (the student came back from a lesson via «طبّق»), else `null`.
Future<Object?> showWordKnowledgeSurface(
  BuildContext context, {
  required QuranSelection selection,
  required String lang,
}) {
  assert(selection.isWord);
  return _show(context, child: _WordSurface(selection: selection, lang: lang));
}

Future<Object?> showAyahKnowledgeSurface(
  BuildContext context, {
  required QuranSelection selection,
  required String lang,
}) {
  return _show(context, child: _AyahSurface(selection: selection, lang: lang));
}

Future<Object?> _show(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.10), // mushaf stays visible
    useSafeArea: true,
    // A slower, eased rise + a soft settle on the way out — the surface
    // "blooms" from the page rather than snapping up (نظام التصميم §4).
    sheetAnimationStyle: AnimationStyle(
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) =>
          _SurfaceShell(scrollController: scrollController, child: child),
    ),
  );
}

/// The shared premium shell: gold-edged raised surface + grab handle. The
/// [child] is given the [scrollController] via an inherited widget so its
/// scrollable drives drag-to-resize.
class _SurfaceShell extends StatelessWidget {
  final ScrollController scrollController;
  final Widget child;
  const _SurfaceShell({required this.scrollController, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, inner) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.975 + 0.025 * t,
          alignment: Alignment.bottomCenter,
          child: inner,
        ),
      ),
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: const Border(top: BorderSide(color: Color(0x4DD9A441))),
        boxShadow: DepthShadows.modal(_kGold),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _ScrollControllerScope(
              controller: scrollController,
              child: child,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ScrollControllerScope extends InheritedWidget {
  final ScrollController controller;
  const _ScrollControllerScope({required this.controller, required super.child});
  static ScrollController of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_ScrollControllerScope>()!.controller;
  @override
  bool updateShouldNotify(_ScrollControllerScope old) =>
      old.controller != controller;
}

// ─────────────────────────────────────────────────────────────────────────
// Word Knowledge Surface
// ─────────────────────────────────────────────────────────────────────────

class _WordSurface extends StatefulWidget {
  final QuranSelection selection;
  final String lang;
  const _WordSurface({required this.selection, required this.lang});

  @override
  State<_WordSurface> createState() => _WordSurfaceState();
}

class _WordSurfaceState extends State<_WordSurface> {
  final _repo = QuranLearningRepository();
  KnowledgeResult? _result;
  bool _detailsOpen = false;

  QuranSelection get sel => widget.selection;
  int get surah => sel.surah;
  int get ayah => sel.ayah;
  int get wordIndex => sel.wordIndex!;

  @override
  void initState() {
    super.initState();
    _repo.factsForWord(surah, ayah, wordIndex).then((r) {
      if (mounted) setState(() => _result = r);
    });
  }

  KnowledgeFact? get _nahw {
    final f = _result?.facts('nahw');
    return (f == null || f.isEmpty) ? null : f.first;
  }

  KnowledgeFact? get _sarf {
    final f = _result?.facts('sarf');
    return (f == null || f.isEmpty) ? null : f.first;
  }

  String? get _conceptId {
    for (final d in const ['nahw', 'sarf', 'tajweed']) {
      for (final f in _result?.facts(d) ?? const <KnowledgeFact>[]) {
        if (f.conceptId != null) return f.conceptId;
      }
    }
    return null;
  }

  Future<void> _learn() async {
    final cid = _conceptId;
    // Keep this surface mounted under the lesson. When «طبّق» returns
    // `'applied'`, close the surface WITH that signal so the reader keeps
    // the word selected on the page (return to the exact spot).
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => cid != null
            ? LearningLessonScreen(
                conceptId: cid,
                originSurah: surah,
                originAyah: ayah,
                originWordStart: wordIndex,
                originWordEnd: wordIndex,
              )
            : IrabViewScreen(
                surah: surah, ayah: ayah, focusWordIndex: wordIndex),
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, result == 'applied' ? 'applied' : null);
  }

  void _openIrab() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IrabViewScreen(
          surah: surah,
          ayah: ayah,
          focusWordIndex: wordIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final r = _result;
    final scroll = _ScrollControllerScope.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            children: [
              // Header — the word itself, in the mushaf script.
              Center(
                child: Text(
                  sel.textUthmani ?? '',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontFamily: 'AmiriQuran', fontSize: 30, height: 1.5),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  '${_surahName(surah)} $ayah · '
                  '${basicText('mushaf_word_order_label', lang)} $wordIndex',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 14),

              if (r == null)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _tier1(lang),
                const SizedBox(height: 10),
                _detailsToggle(lang),
                if (_detailsOpen) ...[
                  const SizedBox(height: 6),
                  _tier2(r, lang),
                ],
                const SizedBox(height: 12),
                _sources(r, lang),
                const SizedBox(height: 14),
                // QC3 — the Quran Corpus for this exact word: ṣarf (QAC),
                // syntactic iʿrāb (Treebank), غريب الكلمة, qirāʾāt.
                WordCorpusPanel(
                  surah: surah,
                  ayah: ayah,
                  wordIndex: wordIndex,
                  lang: lang,
                ),
              ],
            ],
          ),
        ),
        _actionBar(lang, enabled: r != null),
      ],
    );
  }

  // Tier 1 — the "seconds" answer, always visible.
  Widget _tier1(String lang) {
    final n = _nahw;
    if (n == null) {
      return _calmNoData(lang);
    }
    final p = n.payload;
    final role = p['role_ar'] as String? ?? '';
    final sign = p['sign_ar'] as String? ?? '';
    final why = p['irab_text'] as String? ?? '';
    final rels = (p['relations'] as List? ?? const []).cast<Map>();
    final topRel = rels.isEmpty
        ? null
        : '${rels.first['rel_ar'] ?? ''}'
            '${rels.first['to_word'] != null ? ' → ${basicText('mushaf_word_order_label', lang)} ${rels.first['to_word']}' : ''}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _kGold.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kv(basicText('ql_domain_nahw', lang), role, strong: true),
          if (sign.isNotEmpty) _kv(basicText('ql_sign', lang), sign),
          if (why.isNotEmpty) _kv(basicText('ql_why', lang), why),
          if (topRel != null) _kv(basicText('ql_top_relation', lang), topRel),
          const SizedBox(height: 6),
          _sourceLine(_result!.sourceFor(n)),
        ],
      ),
    );
  }

  Widget _detailsToggle(String lang) {
    final hasAny = (_sarf != null) ||
        (_result?.facts('tajweed').isNotEmpty ?? false) ||
        (_result?.facts('tafsir').isNotEmpty ?? false) ||
        ((_nahw?.payload['relations'] as List?)?.length ?? 0) > 1;
    if (!hasAny) return const SizedBox.shrink();
    return InkWell(
      onTap: () => setState(() => _detailsOpen = !_detailsOpen),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(basicText('ql_details', lang),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const Spacer(),
            Icon(
              _detailsOpen
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tier2(KnowledgeResult r, String lang) {
    final rows = <Widget>[];

    final s = _sarf;
    if (s != null) {
      final p = s.payload;
      final parts = <String>[
        if ((p['pos_ar'] ?? '') != '') '${p['pos_ar']}',
        if ((p['root'] ?? '') != '') '${basicText('ql_root', lang)}: ${p['root']}',
        if ((p['pattern'] ?? '') != '')
          '${basicText('ql_pattern', lang)}: ${p['pattern']}',
        if ((p['lemma'] ?? '') != '')
          '${basicText('ql_lemma', lang)}: ${p['lemma']}',
      ];
      rows.add(_block(
        basicText('ql_domain_sarf', lang),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parts.isNotEmpty)
              Text(parts.join('  ·  '),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 12.5, height: 1.7)),
            if ((p['note'] ?? '') != '')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(p['note'] as String,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 12, height: 1.7)),
              ),
            const SizedBox(height: 4),
            _sourceLine(r.sourceFor(s)),
          ],
        ),
      ));
    }

    // remaining relations
    final rels = (_nahw?.payload['relations'] as List? ?? const []).cast<Map>();
    if (rels.length > 1) {
      rows.add(_block(
        basicText('ql_relations', lang),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final rel in rels.skip(1))
              Text(
                '• ${rel['rel_ar'] ?? ''}'
                '${rel['to_word'] != null ? '  → ${basicText('mushaf_word_order_label', lang)} ${rel['to_word']}' : ''}',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 12.5, height: 1.6),
              ),
          ],
        ),
      ));
    }

    for (final t in r.facts('tajweed')) {
      final tr = (t.payload['rules'] as List? ?? const []).cast<Map>();
      rows.add(_block(
        basicText('ql_domain_tajweed', lang),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final rule in tr)
              Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: (TajweedPalette.byKey(
                                '${rule['rule_category'] ?? 'silent'}') ??
                            kTajweedCategories.last)
                        .color(night: false),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text('${rule['rule_ar']}',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ]),
            const SizedBox(height: 4),
            _sourceLine(r.sourceFor(t)),
          ],
        ),
      ));
    }

    for (final tf in r.facts('tafsir')) {
      rows.add(_block(
        '${basicText('ql_related_tafsir', lang)} — ${tf.payload['name_ar'] ?? ''}',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tf.payload['snippet'] ?? ''}',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 12.5, height: 1.8)),
            const SizedBox(height: 4),
            _sourceLine(r.sourceFor(tf)),
          ],
        ),
      ));
    }

    if (rows.isEmpty) return _calmNoData(lang);
    return Column(children: rows);
  }

  /// A single compact bibliography line — the per-claim attribution already
  /// sits inline under each fact, so this is just the roll-up, not a repeat.
  Widget _sources(KnowledgeResult r, String lang) {
    if (r.sources.isEmpty) return const SizedBox.shrink();
    final names = r.sources.values.map((s) => s.name).toSet().join('  ·  ');
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${basicText('ql_sources', lang)}: $names',
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.6),
      ),
    );
  }

  Widget _actionBar(String lang, {required bool enabled}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: enabled ? _learn : null,
              icon: const Icon(Icons.school_rounded, size: 18),
              label: Text(basicText('ql_learn_this', lang)),
              style: FilledButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: enabled
                ? () {
                    Navigator.pop(context);
                    _openIrab();
                  }
                : null,
            child: Text(basicText('ql_interactive_irab', lang),
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ---- small helpers -------------------------------------------------------

  Widget _kv(String k, String v, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: RichText(
          textDirection: TextDirection.rtl,
          text: TextSpan(
            style: const TextStyle(
                fontSize: 13, height: 1.7, color: AppColors.textDark),
            children: [
              TextSpan(
                text: '$k: ',
                style: const TextStyle(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: v,
                style: TextStyle(
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w500),
              ),
            ],
          ),
        ),
      );

  Widget _block(String title, Widget body) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 5),
            body,
          ],
        ),
      );

  Widget _sourceLine(SourceReference? s) {
    if (s == null) return const SizedBox.shrink();
    return Text(
      '${basicText('ql_source', widget.lang)}: ${s.name} · ${s.badgeAr}',
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
    );
  }

  Widget _calmNoData(String lang) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            basicText('ql_no_data_element', lang),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Ayah Knowledge Surface
// ─────────────────────────────────────────────────────────────────────────

class _AyahSurface extends StatefulWidget {
  final QuranSelection selection;
  final String lang;
  const _AyahSurface({required this.selection, required this.lang});

  @override
  State<_AyahSurface> createState() => _AyahSurfaceState();
}

enum _AyahSeg { tafsir, translation, tajweed, uloom, sources }

class _AyahSurfaceState extends State<_AyahSurface> {
  final _repo = QuranLearningRepository();
  final _quran = QuranReadingRepository();
  final _corpusRepo = QuranCorpusRepository();
  KnowledgeResult? _result;
  String? _ayahText;
  _AyahSeg _seg = _AyahSeg.tafsir;
  bool _hasAsbab = false;

  int get surah => widget.selection.surah;
  int get ayah => widget.selection.ayah;

  @override
  void initState() {
    super.initState();
    _repo.factsForAyah(surah, ayah).then((r) {
      if (mounted) setState(() => _result = r);
    });
    _quran.ayahAt(surah, ayah).then((a) {
      if (mounted && a != null) setState(() => _ayahText = a.text);
    });
    // The one science this surface calls out by name before the user even
    // taps in — Ismail's ask that سبب النزول "يُشع" when it's really
    // there. Asbab-only on purpose: any generic "data exists" badge would
    // light up on nearly every ayah (riwāyāt are always present) and lose
    // its meaning.
    _corpusRepo.asbab(surah, ayah).then((rows) {
      if (mounted && rows.isNotEmpty) setState(() => _hasAsbab = true);
    });
  }

  /// «للمزيد» — close the quick card and open the dedicated ayah page
  /// (full tafsīr, translations, sources, prev/next — or العلوم المرتبطة
  /// when that's the tab the user was on). Deep reading never happens
  /// inside the surface.
  void _openAyahPage({int? bookId}) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AyahStudyScreen(
          surah: surah,
          ayah: ayah,
          initialFamily: _seg == _AyahSeg.uloom ? AyahStudyFamily.uloom : null,
          initialBookId: bookId,
        ),
      ),
    );
  }

  void _openUloom() => setState(() => _seg = _AyahSeg.uloom);

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final r = _result;
    final scroll = _ScrollControllerScope.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            children: [
              // Header — the ayah itself.
              Text(
                '${_surahName(surah)} · ${basicText('turath_page_short', lang)} ${widget.selection.page}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              // The ayah itself, in the mushaf script — the surface is
              // headed by what you tapped, not a bare number.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kGold.withValues(alpha: 0.5)),
                    ),
                    child: Text('$ayah',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kGold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _ayahText ?? '',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontFamily: 'AmiriQuran', fontSize: 19, height: 1.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (r == null)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (_hasAsbab) ...[
                  _asbabBadge(lang),
                  const SizedBox(height: 10),
                ],
                _learnQ(r, lang),
                const SizedBox(height: 12),
                _segbar(lang),
                const SizedBox(height: 10),
                _segBody(r, lang),
              ],
            ],
          ),
        ),
        _actionBar(lang),
      ],
    );
  }

  /// The one calm, gold signal on this surface for one specific science —
  /// deliberately not a generic "data available" badge (see [initState]).
  /// A tap just switches to «العلوم المرتبطة» (`AppMotion.normal`, already
  /// the cross-fade this segbar uses) — no extra "premium" transition.
  Widget _asbabBadge(String lang) => InkWell(
        onTap: _openUloom,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: _kGold.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: _kGold),
              const SizedBox(width: 6),
              Text(
                basicText('ql_asbab_documented_badge', lang),
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: _kGold),
              ),
            ],
          ),
        ),
      );

  Widget _learnQ(KnowledgeResult r, String lang) {
    final domains = r.byDomain.keys
        .where((d) => d != 'tafsir')
        .map((d) => basicText('ql_domain_$d', lang))
        .toList();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _kGold.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(basicText('ql_ayah_learn_q', lang),
              textDirection: TextDirection.rtl,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          const SizedBox(height: 6),
          Text(
            domains.isEmpty
                ? basicText('ql_no_data_element', lang)
                : domains.join('  ·  '),
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _segbar(String lang) {
    final items = <(_AyahSeg, String)>[
      (_AyahSeg.tafsir, basicText('ql_domain_tafsir', lang)),
      (_AyahSeg.translation, basicText('ql_translation', lang)),
      (_AyahSeg.tajweed, basicText('ql_domain_tajweed', lang)),
      (_AyahSeg.uloom, basicText('ql_related_sciences', lang)),
      (_AyahSeg.sources, basicText('ql_sources', lang)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (seg, label) in items)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 11.5)),
                selected: _seg == seg,
                onSelected: (_) => setState(() => _seg = seg),
                selectedColor: _kGold.withValues(alpha: 0.20),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _segBody(KnowledgeResult r, String lang) {
    switch (_seg) {
      case _AyahSeg.tafsir:
        // QC3 — a quick excerpt from the picked book; «التفسير كاملًا»
        // inside the panel opens the dedicated ayah page for deep reading.
        return AyahTafsirPanel(
          surah: surah,
          ayah: ayah,
          lang: lang,
          onOpenFull: (bookId) => _openAyahPage(bookId: bookId),
        );
      case _AyahSeg.sources:
        if (r.sources.isEmpty) return _calmNoData(lang);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in r.sources.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '• ${s.name}'
                  '${s.author != null && s.author!.isNotEmpty ? ' — ${s.author}' : ''}'
                  '  · ${s.badgeAr}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 12, height: 1.6),
                ),
              ),
          ],
        );
      case _AyahSeg.tajweed:
        return _tajweedFamilies(r, lang);
      case _AyahSeg.uloom:
        // QC3 — «كل ما ورد في هذه الآية» as short excerpts: سبب النزول ·
        // إعراب من الكتب · ناسخ/منسوخ · غريب · فوائد · متشابهات · آثار ·
        // موضوعات. «توسّع» opens the dedicated ayah page; a topic chip
        // opens the QC4 Knowledge Index.
        return AyahCorpusPanel(
          surah: surah,
          ayah: ayah,
          lang: lang,
          onOpenFull: _openAyahPage,
          onTopicTap: (id, name) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TopicIndexScreen(topicId: id, title: name),
              ),
            );
          },
        );
      case _AyahSeg.translation:
        // QC3 — the real 138-edition translation picker (language + edition).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AyahTranslationPanel(surah: surah, ayah: ayah, lang: lang),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AyahStudyScreen(surah: surah, ayah: ayah),
                    ),
                  );
                },
                icon: const Icon(Icons.translate_rounded, size: 16),
                label: Text(basicText('translate_action', lang),
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        );
    }
  }

  /// أحكام التجويد للآية — grouped by the six colour categories (not the 18
  /// ids). Each category header carries its `tajweed_palette` dot; each rule
  /// row that has a curriculum lesson opens it. Data: cpfair/quran-tajweed
  /// via `CorpusTajweedProvider`, all 6236 ayāt.
  Widget _tajweedFamilies(KnowledgeResult r, String lang) {
    final facts = r.facts('tajweed');
    final present = <String>{};
    for (final t in facts) {
      for (final rule in (t.payload['rules'] as List? ?? const []).cast<Map>()) {
        final id = rule['rule_id'] as String?;
        if (id != null) present.add(id);
      }
    }
    if (present.isEmpty) return _calmNoData(lang);

    final rows = <Widget>[];
    for (final cat in kTajweedCategories) {
      final ids = [
        for (final id in kTajweedRules.keys)
          if (present.contains(id) && kTajweedRules[id]!.categoryKey == cat.key)
            id
      ];
      if (ids.isEmpty) continue;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Row(children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: cat.color(night: false), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(cat.labelAr,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700)),
        ]),
      ));
      for (final id in ids) {
        final ref = kTajweedRules[id]!;
        final tier = ref.tier;
        rows.add(InkWell(
          onTap: tier == null
              ? null
              : () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TajweedTierScreen(tier: tier)),
                  );
                },
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: Row(children: [
              Expanded(
                child: Text('•  ${ref.ruleAr}',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 12.5, height: 1.6)),
              ),
              if (tier != null) ...[
                Text(basicText('ql_open_lesson', lang),
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted)),
                const Icon(Icons.chevron_left_rounded,
                    size: 16, color: AppColors.textMuted),
              ],
            ]),
          ),
        ));
      }
    }

    final src = facts.isEmpty ? null : r.sourceFor(facts.first);
    if (src != null) {
      rows.add(const SizedBox(height: 10));
      rows.add(Text(
        '${basicText('ql_source', lang)}: ${src.name} · ${src.badgeAr}',
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }


  Widget _actionBar(String lang) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AyahNotebookScreen(surah: surah, ayah: ayah),
                  ),
                );
              },
              icon: const Icon(Icons.auto_stories_outlined, size: 18),
              label: Text(basicText('ql_add_to_notebook', lang)),
              style: FilledButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // «شجرة أصول التفسير» for this ayah (USUL_TAFSIR_TREE.md U4).
          IconButton(
            tooltip: basicText('usul_tree_title', lang),
            icon: const Icon(Icons.account_tree_outlined, color: _kGold),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UsulTreeScreen(surah: surah, ayah: ayah)),
              );
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IrabViewScreen(surah: surah, ayah: ayah),
                ),
              );
            },
            child: Text(basicText('ql_irab_title', lang),
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _calmNoData(String lang) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(basicText('ql_no_data_element', lang),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
        ),
      );
}
