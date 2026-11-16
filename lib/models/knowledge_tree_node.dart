/// A node any knowledge tree can hand to `KnowledgeTree3D`
/// (lib/widgets/knowledge_tree_3d.dart) — the usul-tafsir tree, the fiqh
/// tree of Zad al-Mustaqni', and whatever tree comes next
/// (docs/KNOWLEDGE_TREE_ZAD_PLAN.md §3: one widget, no parallel screens).
abstract class KnowledgeTreeNode {
  String get id;
  String get title;

  /// 0 = the trunk (root), 1 = a branch, 2+ = leaves.
  int get depth;
  String? get parentId;
  List<KnowledgeTreeNode> get children;
}
