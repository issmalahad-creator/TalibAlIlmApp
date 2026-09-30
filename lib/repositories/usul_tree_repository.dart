import '../db/database_helper.dart';
import '../models/quran_learning.dart';
import '../services/boot/boot_scheduler.dart';
import '../services/packs/content_pack_engine.dart';
import '../services/usul/usul_answers.dart';
import 'quran_corpus_repository.dart';

/// One node of the usul-tafsir tree as the screen draws it.
class UsulTreeNode {
  UsulTreeNode({
    required this.id,
    required this.title,
    required this.depth,
    required this.ord,
    this.parentId,
    this.rel,
    this.definition,
    this.locator,
    this.sourceRefId,
    this.question,
    this.answerKey,
  });

  final String id;
  final String title;
  final int depth;
  final int ord;
  final String? parentId;

  /// The science's own word for the edge from the parent (أقسامه، أنواعه، مراتبه…).
  final String? rel;

  /// Ibn Taymiyya's words, verbatim, and where they are (e.g. «ص 16»).
  final String? definition;
  final String? locator;
  final String? sourceRefId;

  /// The question this node asks of an ayah.
  final String? question;

  /// Which per-ayah answer (U2) feeds this node; null = curated only (U5).
  final String? answerKey;

  final List<UsulTreeNode> children = [];
}

/// Loads the tree (USUL_TAFSIR_TREE.md U1 — `knowledge_concepts` with
/// domain `usul_tafsir` + `knowledge_relations`) and an ayah's answers (U2).
class UsulTreeRepository {
  static const _root = 'concept:usul:usul';

  /// The whole tree, root first. Null if the knowledge seed hasn't landed.
  Future<UsulTreeNode?> tree() async {
    await BootScheduler.instance.ensure(BootTasks.quranLearning);
    final db = await DatabaseHelper.instance.database;
    final concepts = await db.query('knowledge_concepts', where: 'domain = ?', whereArgs: ['usul_tafsir']);
    if (concepts.isEmpty) return null;
    final rels = await db.query('knowledge_relations', orderBy: 'ord ASC');

    final byId = <String, LearningConcept>{for (final r in concepts) r['id'] as String: LearningConcept.fromRow(r)};
    final parentOf = {for (final r in rels) r['to_concept'] as String: r};
    final nodes = <String, UsulTreeNode>{};

    UsulTreeNode build(String id, int depth) {
      final c = byId[id]!;
      LearningBlock? block(String kind) {
        for (final b in c.blocks) {
          if (b.kind == kind) return b;
        }
        return null;
      }

      final def = block('definition');
      final edge = parentOf[id];
      final n = UsulTreeNode(
        id: id,
        title: c.titleAr,
        depth: depth,
        ord: (edge?['ord'] as int?) ?? 0,
        parentId: edge?['from_concept'] as String?,
        rel: edge?['rel'] as String?,
        definition: def?.textAr,
        locator: def?.locator,
        sourceRefId: def?.sourceRefId,
        question: block('question')?.textAr,
        answerKey: block('usul_answer')?.textAr,
      );
      nodes[id] = n;
      for (final r in rels.where((r) => r['from_concept'] == id)) {
        n.children.add(build(r['to_concept'] as String, depth + 1));
      }
      return n;
    }

    return byId.containsKey(_root) ? build(_root, 0) : null;
  }

  /// Human name of a source row, for the «المصدر» line under a quote.
  Future<String?> sourceName(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('source_references', columns: ['name', 'author'], where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final author = rows.first['author'] as String?;
    return author == null ? rows.first['name'] as String : '${rows.first['name']} — $author';
  }

  /// U2 answers for one ayah. In lite without the athar pack, the athar-fed
  /// nodes say «غير محمَّل» (the tree offers the pack).
  Future<Map<String, UsulNodeAnswer>> answersFor(int surah, int ayah) async {
    final corpus = QuranCorpusRepository();
    final haveAthar = await ContentPackEngine.instance.isUsable('corpus.sayings');
    final raw = haveAthar ? await corpus.sayings(surah, ayah) : null;
    final asbab = await corpus.asbab(surah, ayah);
    return usulAnswersFor(
      sayings: haveAthar ? (raw is List ? raw.cast<Object?>() : const []) : null,
      asbab: asbab,
    );
  }
}
