import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/fiqh_tree.dart';
import '../../models/knowledge_tree_node.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/knowledge_tree_3d.dart';
import '../../widgets/loading_view.dart';
import 'fiqh_chain_sheet.dart';

String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);

/// «شجرة الفقه» (docs/KNOWLEDGE_TREE_ZAD_PLAN.md ش3): Zad al-Mustaqni' as a
/// tree — the kitab is the trunk, its chapters the branches, each ruling of
/// the matn a leaf, coloured by the matn's own ruling word. Tapping opens
/// «السلسلة»: the matn, al-Rawd's explanation, and the chapter's evidence
/// from Bulugh al-Maram — quick cards, the full texts one tap further.
class FiqhTreeScreen extends StatefulWidget {
  const FiqhTreeScreen({super.key, this.asset = FiqhTree.zadTaharah, this.openChapterId, this.openMasalaId});
  final String asset;

  /// From the mushaf (ش4): open the chain of this chapter / ruling at once.
  final String? openChapterId;
  final String? openMasalaId;

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
      final cid = widget.openChapterId;
      if (cid != null && _asset == widget.asset) {
        final ch = root.children.where((n) => n.id == cid).firstOrNull;
        final target = ch?.children.where((n) => n.id == widget.openMasalaId).firstOrNull ?? ch;
        if (target != null) WidgetsBinding.instance.addPostFrameCallback((_) => _open(target));
      }
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

