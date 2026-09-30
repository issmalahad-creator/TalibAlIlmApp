import '../../repositories/usul_tree_repository.dart';

/// U6 of docs/quran/USUL_TAFSIR_TREE.md — «أعد بناء الشجرة»: each parent
/// node with children is one recall card («أقسام أصول التفسير»,
/// «أنواع اختلاف السلف في التفسير»…). The student recalls the children,
/// uncovers them, and rates themself; the card then lives in the existing
/// `KnowledgeReviewRepository` station engine — no third review engine,
/// no score, no multiple choice.
class UsulRebuildGroup {
  const UsulRebuildGroup({required this.parent, required this.prompt, required this.itemId});

  final UsulTreeNode parent;

  /// «أقسام أصول التفسير» — the science's own word for the edge + the parent.
  final String prompt;

  /// Stable id in `knowledge_review_progress` (item_type [usulReviewType]).
  final int itemId;

  List<UsulTreeNode> get children => parent.children;
}

const usulReviewType = 'usul_tree';

/// Every recall card, in the tree's reading order (root first).
List<UsulRebuildGroup> usulRebuildGroups(UsulTreeNode root) {
  final out = <UsulRebuildGroup>[];
  void visit(UsulTreeNode n) {
    if (n.children.isNotEmpty) {
      out.add(
        UsulRebuildGroup(
          parent: n,
          prompt: '${relNoun(n.children.first.rel)} ${n.title}'.trim(),
          itemId: usulItemId(n.id),
        ),
      );
    }
    n.children.forEach(visit);
  }

  visit(root);
  return out;
}

/// «أقسامه» → «أقسام»: the edge word without its pronoun, so it can head
/// the parent's name.
String relNoun(String? rel) {
  if (rel == null || rel.isEmpty) return '';
  return rel.endsWith('ه') ? rel.substring(0, rel.length - 1) : rel;
}

/// A stable 31-bit id for a concept id (FNV-1a) — the review table keys
/// items by integer, and the tree's ids are strings. Same input, same id,
/// on every device and every build.
int usulItemId(String conceptId) {
  var h = 0x811c9dc5;
  for (final c in conceptId.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h & 0x7FFFFFFF;
}
