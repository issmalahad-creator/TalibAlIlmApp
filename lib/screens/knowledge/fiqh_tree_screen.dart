import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/fiqh_tree.dart';
import '../../models/knowledge_tree_node.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/knowledge_tree_3d.dart';
import '../../widgets/loading_view.dart';
import '../turath_reader_screen.dart';

String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);

/// «شجرة الفقه» (docs/KNOWLEDGE_TREE_ZAD_PLAN.md ش3): Zad al-Mustaqni' as a
/// tree — the kitab is the trunk, its chapters the branches, each ruling of
/// the matn a leaf, coloured by the matn's own ruling word. Tapping opens
/// «السلسلة»: the matn, al-Rawd's explanation, and the chapter's evidence
/// from Bulugh al-Maram — quick cards, the full texts one tap further.
class FiqhTreeScreen extends StatefulWidget {
  const FiqhTreeScreen({super.key, this.asset = FiqhTree.zadTaharah});
  final String asset;

  @override
  State<FiqhTreeScreen> createState() => _FiqhTreeScreenState();
}

class _FiqhNode implements KnowledgeTreeNode {
  _FiqhNode({required this.id, required this.title, required this.depth, this.parentId, this.chapter, this.masala});

  @override
  final String id;
  @override
  final String title;
  @override
  final int depth;
  @override
  final String? parentId;
  @override
  final List<_FiqhNode> children = [];

  final FiqhChapter? chapter;
  final FiqhMasala? masala;
}

/// The matn's ruling word → a calm, fixed colour (the plan's legend: duty and
/// condition dark, sunna green, makruh amber, haram / invalid muted red).
(IconData, Color)? rulingStyle(List<String> ruling) {
  if (ruling.isEmpty) return null;
  return switch (ruling.first) {
    'يجب' || 'فرض' || 'شرط' => (Icons.priority_high_rounded, KnowledgeTreePalette.ink),
    'يُسنّ' || 'يُستحبّ' => (Icons.spa_rounded, const Color(0xFF3E8E5A)),
    'يُكره' => (Icons.do_disturb_on_outlined, const Color(0xFFC08A2E)),
    'يحرم' || 'لا يصحّ' || 'يبطل' || 'لا يُجزئ' => (Icons.block_rounded, const Color(0xFFB0473C)),
    _ => (Icons.check_circle_outline_rounded, const Color(0xFF5B7C8A)), // لا يُكره، يُباح، يُجزئ
  };
}

/// A leaf's label: the start of the ruling, the rest in «السلسلة».
String leafLabel(String text, {int words = 7}) {
  final w = text.replaceAll(RegExp(r'[.،:]+$'), '').split(' ');
  return w.length <= words ? w.join(' ') : '${w.take(words).join(' ')}…';
}

class _FiqhTreeScreenState extends State<FiqhTreeScreen> {
  FiqhTree? _tree;
  _FiqhNode? _root;
  Object? _error;
  List<FiqhTreeEntry> _kitabs = const [];
  late String _asset = widget.asset;

  @override
  void initState() {
    super.initState();
    _loadIndex();
    _load();
  }

  Future<void> _loadIndex() async {
    try {
      final kitabs = await FiqhTree.index();
      if (mounted) setState(() => _kitabs = kitabs);
    } catch (_) {
      // one tree still works without the index
    }
  }

  void _pick(FiqhTreeEntry k) {
    if (k.asset == _asset) return;
    setState(() {
      _asset = k.asset;
      _root = null;
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final tree = await FiqhTree.load(asset: _asset);
      final root = _FiqhNode(id: tree.id, title: tree.title, depth: 0);
      for (final c in tree.chapters) {
        final ch = _FiqhNode(id: c.id, title: c.title, depth: 1, parentId: root.id, chapter: c);
        for (final m in c.masail) {
          ch.children.add(_FiqhNode(id: m.id, title: leafLabel(m.text), depth: 2, parentId: c.id, chapter: c, masala: m));
        }
        root.children.add(ch);
      }
      if (!mounted) return;
      setState(() {
        _tree = tree;
        _root = root;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  KnowledgeNodeLook _look(KnowledgeTreeNode n) {
    final m = (n as _FiqhNode).masala;
    final style = m == null ? null : rulingStyle(m.ruling);
    return KnowledgeNodeLook(icon: style?.$1, iconColor: style?.$2, highlighted: style != null);
  }

  void _open(KnowledgeTreeNode n) {
    final node = n as _FiqhNode;
    final tree = _tree;
    if (tree == null || node.chapter == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiqhChainSheet(tree: tree, chapter: node.chapter!, masala: node.masala),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    return Scaffold(
      backgroundColor: KnowledgeTreePalette.page,
      appBar: AppBar(
        title: Text(_tree?.title ?? _t('feat_fiqh_tree')),
        backgroundColor: KnowledgeTreePalette.page,
      ),
      body: _error != null
          ? Center(child: Text(_t('ft_load_error'), style: const TextStyle(color: AppColors.textMuted)))
          : _root == null
              ? AppLoadingView(icon: Icons.account_tree_outlined, message: basicText('loading_lesson', lang))
              : Column(
                  children: [
                    if (_kitabs.length > 1)
                      SizedBox(
                        height: 46,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            for (final k in _kitabs)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                child: ChoiceChip(
                                  label: Text(k.title.replaceFirst('كتاب ', '')),
                                  selected: k.asset == _asset,
                                  onSelected: (_) => _pick(k),
                                  selectedColor: KnowledgeTreePalette.ink,
                                  labelStyle: TextStyle(
                                    color: k.asset == _asset ? Colors.white : KnowledgeTreePalette.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  showCheckmark: false,
                                ),
                              ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Text(_t('ft_sources_line'),
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.5)),
                    ),
                    Expanded(
                      child: KnowledgeTree3D(
                        key: ValueKey(_root!.id),
                        root: _root!,
                        look: _look,
                        onTap: _open,
                        walkStep: const Duration(milliseconds: 60),
                        tilt: 0,
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// «السلسلة»: stacked quick cards for one chapter or one ruling.
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

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    final m = widget.masala;
    final hadith = widget.tree.evidenceFor(c);
    final shown = _allHadith ? hadith : hadith.take(3).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.94,
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
            Text(c.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: KnowledgeTreePalette.ink)),
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
            _Card(
              label: _t('ft_sharh'),
              attribution: '${widget.tree.sources['rawd']?['title'] ?? ''} · ${c.sharhChapter}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.sharhExcerpt, style: const TextStyle(fontSize: 14.5, height: 1.9, color: AppColors.textDark)),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TurathReaderScreen(
                            bookId: widget.tree.turathRawdId,
                            bookName: widget.tree.sources['rawd']?['title'] as String? ?? '',
                            pageNumber: c.sharhPage,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: Text(_t('ft_read_sharh')),
                    ),
                  ),
                ],
              ),
            ),
            _Card(
              label: _t('ft_evidence'),
              attribution: '${widget.tree.sources['bulugh']?['title'] ?? ''} · ${c.evidenceChapter}',
              note: m == null ? null : _t('ft_evidence_chapter_note'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final h in shown) _HadithTile(h),
                  if (hadith.length > shown.length)
                    TextButton(
                      onPressed: () => setState(() => _allHadith = true),
                      child: Text(_t('ft_show_all').replaceAll('{n}', '${hadith.length}')),
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
                  decoration: BoxDecoration(
                    color: KnowledgeTreePalette.ink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(attribution,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
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
              width: 34,
              padding: const EdgeInsets.symmetric(vertical: 2),
              margin: const EdgeInsetsDirectional.only(end: 8, top: 4),
              decoration: BoxDecoration(
                color: KnowledgeTreePalette.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(h.label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KnowledgeTreePalette.ink)),
            ),
            Expanded(
              child: Text(h.text, style: const TextStyle(fontSize: 15, height: 1.9, color: AppColors.textDark)),
            ),
          ],
        ),
      );
}
