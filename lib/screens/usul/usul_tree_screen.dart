
import 'package:flutter/material.dart';

import '../../data/quran_surahs.dart';
import '../../l10n/basic_translations.dart';
import '../../repositories/usul_tree_repository.dart';
import '../../services/language_preference_service.dart';
import '../../services/packs/content_pack_engine.dart';
import '../../services/usul/usul_answers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/knowledge_tree_3d.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/packs/pack_ui.dart';
import '../ayah_study_screen.dart';
import 'usul_rebuild_screen.dart';

/// «شجرة أصول التفسير» for one ayah (docs/quran/USUL_TAFSIR_TREE.md U3) —
/// the paper mind-map Ismail showed: root on the right, the four branches of
/// Ibn Taymiyya's Muqaddima, their nodes, dotted connectors; soft 3D depth
/// (layered heights + shadows + a light perspective), pinch to zoom. Each
/// node is lit by what the sources say about THIS ayah; tapping it opens a
/// quick card, never a reader.
class UsulTreeScreen extends StatefulWidget {
  const UsulTreeScreen({super.key, required this.surah, required this.ayah});
  final int surah;
  final int ayah;

  @override
  State<UsulTreeScreen> createState() => _UsulTreeScreenState();
}

// The paper palette: cream page, dark-teal hexagons like the image, grey
// value nodes; the gold accent is the only colour of state.
const _page = KnowledgeTreePalette.page;
const _ink = KnowledgeTreePalette.ink;
const _gold = KnowledgeTreePalette.gold;

class _UsulTreeScreenState extends State<UsulTreeScreen> {
  final _repo = UsulTreeRepository();
  UsulTreeNode? _root;
  Map<String, UsulNodeAnswer> _answers = const {};
  Map<String, List<UsulExample>> _examples = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final root = await _repo.tree();
    final answers = await _repo.answersFor(widget.surah, widget.ayah);
    final examples = await _repo.examplesFor(widget.surah, widget.ayah);
    if (!mounted) return;
    setState(() {
      _root = root;
      _answers = answers;
      _examples = examples;
      _loading = false;
    });
  }

  /// What the node shows for this ayah: the source's own word first, then
  /// a book example (U5), then whatever U2 found (hint / not found / …).
  UsulStatus? _statusOf(UsulTreeNode n) {
    final a = n.answerKey == null ? null : _answers[n.answerKey]?.status;
    if (a == UsulStatus.sourced) return a;
    if (_examples[n.id]?.isNotEmpty ?? false) return UsulStatus.curated;
    return a;
  }

  String get _lang => LanguagePreferenceService.currentLanguage;

  KnowledgeNodeLook _lookOf(UsulTreeNode n) {
    final status = _statusOf(n);
    final (_, color, icon) = statusStyle(status);
    return KnowledgeNodeLook(
      icon: icon,
      iconColor: color,
      forceIcon: n.answerKey != null,
      highlighted: status == UsulStatus.sourced || status == UsulStatus.curated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahName = widget.surah >= 1 && widget.surah <= quranSurahs.length ? quranSurahs[widget.surah - 1].name : '';
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _page,
        title: Column(
          children: [
            Text(
              basicText('usul_tree_title', _lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text('$surahName · ${widget.ayah}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: basicText('usul_rebuild_title', _lang),
            icon: const Icon(Icons.extension_outlined),
            onPressed: _root == null
                ? null
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsulRebuildScreen())),
          ),
          IconButton(
            tooltip: basicText('usul_examples_index', _lang),
            icon: const Icon(Icons.format_list_bulleted_rounded),
            onPressed: _root == null ? null : _openIndex,
          ),
        ],
      ),
      body: _loading
          ? AppLoadingView(icon: Icons.account_tree_outlined, message: basicText('loading_quran', _lang))
          : _root == null
          ? Center(child: Text(basicText('usul_status_not_found', _lang)))
          : KnowledgeTree3D(
              root: _root!,
              look: (n) => _lookOf(n as UsulTreeNode),
              onTap: (n) => _openNode(n as UsulTreeNode),
            ),
    );
  }

  Future<void> _openNode(UsulTreeNode n) async {
    final name = n.sourceRefId == null ? null : await _repo.sourceName(n.sourceRefId!);
    final exNames = <String, String?>{
      for (final id in {for (final e in _examples[n.id] ?? const <UsulExample>[]) e.sourceRefId})
        id: await _repo.sourceName(id),
    };
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              n.title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _ink),
            ),
            if (n.question != null) ...[
              const SizedBox(height: 4),
              Text(n.question!, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            ],
            if (n.definition != null) ...[
              const SizedBox(height: 14),
              _QuoteBox(
                label: basicText('usul_definition_label', _lang),
                text: n.definition!,
                attribution: [name, n.locator].whereType<String>().join('، '),
              ),
            ],
            if (n.children.isEmpty || n.answerKey != null) ...[
              const SizedBox(height: 18),
              Text(
                basicText('usul_for_this_ayah', _lang),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ..._answerBody(n, exNames),
            ],
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AyahStudyScreen(surah: widget.surah, ayah: widget.ayah, initialFamily: AyahStudyFamily.uloom),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(basicText('ql_open_ayah_page', _lang)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _answerBody(UsulTreeNode n, Map<String, String?> sourceNames) {
    final a = n.answerKey == null ? null : _answers[n.answerKey];
    final examples = _examples[n.id] ?? const <UsulExample>[];
    if (examples.isNotEmpty && a?.status != UsulStatus.sourced) {
      return [
        _StatusChip(status: UsulStatus.curated, lang: _lang),
        const SizedBox(height: 10),
        ..._exampleBoxes(examples, sourceNames),
      ];
    }
    if (a == null) {
      return [
        _StatusChip(status: null, lang: _lang),
        const SizedBox(height: 6),
        Text(
          basicText('usul_curated_pending', _lang),
          style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted),
        ),
      ];
    }
    final out = <Widget>[_StatusChip(status: a.status, lang: _lang), const SizedBox(height: 10)];
    switch (a.status) {
      case UsulStatus.notDownloaded:
        out.add(
          FutureBuilder(
            future: ContentPackEngine.instance.manifest(),
            builder: (_, snap) {
              final pack = snap.data?.byId('corpus.sayings');
              return pack == null
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: PackStatusView(pack: pack),
                    );
            },
          ),
        );
      case UsulStatus.hint:
        out.add(Text(basicText('usul_hint_note', _lang), style: const TextStyle(fontSize: 13.5, height: 1.6)));
      case UsulStatus.notFound:
        break;
      case UsulStatus.sourced:
        for (final e in a.evidence) {
          out.add(_QuoteBox(text: e.text, attribution: '${e.sayer} — ${e.source}', judgment: e.judgment));
          out.add(const SizedBox(height: 8));
        }
        if (a.count > a.evidence.length) {
          out.add(
            Text(
              basicText('usul_more_items', _lang).replaceAll('{n}', '${a.count - a.evidence.length}'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          );
        }
      case UsulStatus.curated:
        break;
    }
    if (examples.isNotEmpty) {
      out
        ..add(const SizedBox(height: 14))
        ..add(
          Text(
            basicText('usul_status_curated', _lang),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        )
        ..add(const SizedBox(height: 8))
        ..addAll(_exampleBoxes(examples, sourceNames));
    }
    return out;
  }

  /// The book's own words for this ayah (U5) — a mistaken tafsir quoted to
  /// warn against it is marked red, so it can never read as the meaning.
  List<Widget> _exampleBoxes(List<UsulExample> examples, Map<String, String?> sourceNames) => [
    for (final e in examples) ...[
      _QuoteBox(
        label: basicText('usul_kind_${e.kind}', _lang),
        text: e.text,
        attribution: [sourceNames[e.sourceRefId], e.locator].whereType<String>().join('، '),
        accent: e.kind == 'error' ? Colors.red.shade700 : _gold,
      ),
      const SizedBox(height: 8),
    ],
  ];

  /// «آيات الأمثلة» — every ayah the book itself uses as an example; a tap
  /// opens that ayah's tree.
  Future<void> _openIndex() async {
    final titles = <String, String>{};
    void walk(UsulTreeNode n) {
      titles[n.id] = n.title;
      n.children.forEach(walk);
    }

    walk(_root!);
    final ayat = await _repo.exampleAyat();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          itemCount: ayat.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Text(
                  basicText('usul_examples_index', _lang),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
                ),
              );
            }
            final e = ayat[i - 1];
            final here = e.surah == widget.surah && e.ayah == widget.ayah;
            final name = e.surah <= quranSurahs.length ? quranSurahs[e.surah - 1].name : '';
            return ListTile(
              selected: here,
              selectedColor: _ink,
              selectedTileColor: _gold.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              leading: const Icon(Icons.account_tree_outlined, color: _gold),
              title: Text('$name · ${e.ayah}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(e.nodeIds.map((id) => titles[id] ?? '').join(' · ')),
              onTap: () {
                Navigator.pop(ctx);
                if (here) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UsulTreeScreen(surah: e.surah, ayah: e.ayah),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _QuoteBox extends StatelessWidget {
  const _QuoteBox({required this.text, required this.attribution, this.label, this.judgment, this.accent = _gold});
  final String text;
  final String attribution;
  final String? label;
  final String? judgment;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
    decoration: BoxDecoration(
      color: _page,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: BorderDirectional(start: BorderSide(color: accent, width: 3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: TextStyle(
              fontSize: 11.5,
              color: accent == _gold ? AppColors.textMuted : accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        Text('«$text»', style: const TextStyle(fontSize: 15, height: 1.75)),
        if (judgment != null) ...[
          const SizedBox(height: 4),
          Text(judgment!, style: TextStyle(fontSize: 12.5, color: Colors.orange.shade900)),
        ],
        const SizedBox(height: 4),
        Text(attribution, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.lang});
  final UsulStatus? status;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final (key, color, icon) = statusStyle(status);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              basicText(key, lang),
              style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

(String, Color, IconData) statusStyle(UsulStatus? s) => switch (s) {
  UsulStatus.sourced => ('usul_status_sourced', AppColors.primary, Icons.check_circle_rounded),
  UsulStatus.curated => ('usul_status_curated', AppColors.primary, Icons.menu_book_rounded),
  UsulStatus.hint => ('usul_status_hint', _gold, Icons.adjust_rounded),
  UsulStatus.notDownloaded => ('usul_status_not_downloaded', Colors.blueGrey, Icons.download_for_offline_outlined),
  UsulStatus.notFound || null => ('usul_status_not_found', Colors.grey, Icons.radio_button_unchecked),
};
