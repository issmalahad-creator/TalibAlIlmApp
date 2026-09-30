import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/quran_learning.dart';
import 'package:talib_alilm_app/repositories/quran_learning_sync.dart';
import 'package:talib_alilm_app/repositories/knowledge_review_repository.dart';
import 'package:talib_alilm_app/repositories/usul_tree_repository.dart';
import 'package:talib_alilm_app/services/usul/usul_rebuild.dart';
import 'package:talib_alilm_app/services/quran_learning/knowledge_gateway.dart';

/// U1 of docs/quran/USUL_TAFSIR_TREE.md — the usul-tafsir tree from Ibn
/// Taymiyya's «مقدمة في أصول التفسير», merged into the knowledge seed.
/// Proves: the tree is well-formed, every definition is a quoted, attributed
/// text with its page, the answer keys are ones U2 knows, and the seed puts
/// concepts + relations into the DB without wiping the existing lessons.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Map<String, dynamic> proto;
  late Map<String, dynamic> usul;
  late Map<String, dynamic> merged;

  Map<String, dynamic> read(String name) =>
      jsonDecode(utf8.decode(File(join('assets', 'quran_learning', name)).readAsBytesSync())) as Map<String, dynamic>;

  setUpAll(() {
    DatabaseHelper.databaseName = 'talib_usul_test.db';
    final f = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    proto = read('prototype.json');
    usul = read('usul_tree.json');
    merged = QuranLearningSync.mergePayloads(proto, usul);
  });

  test('the tree: one root, the four branches of the Muqaddima, no orphans', () {
    final concepts = (usul['concepts'] as List).cast<Map<String, dynamic>>();
    final relations = (usul['relations'] as List).cast<Map<String, dynamic>>();
    final ids = {for (final c in concepts) c['id'] as String};
    final children = {for (final r in relations) r['to'] as String};
    final roots = ids.difference(children);
    expect(roots, {'concept:usul:usul'});
    final branches = relations.where((r) => r['from'] == 'concept:usul:usul').map((r) => r['to']).toList();
    expect(branches, ['concept:usul:bayan', 'concept:usul:ikhtilaf', 'concept:usul:naql_istidlal', 'concept:usul:turuq']);
    for (final r in relations) {
      expect(ids, contains(r['from']));
      expect(ids, contains(r['to']));
    }
  });

  test('every definition is a quote with its source and page — never unattributed', () {
    final concepts = (usul['concepts'] as List).cast<Map<String, dynamic>>();
    var quoted = 0;
    for (final c in concepts) {
      final concept = LearningConcept.fromJson(c);
      for (final b in concept.blocks.where((b) => b.kind == 'definition')) {
        quoted++;
        expect(b.sourceRefId, 'src:muqaddima_usul_tafsir', reason: c['id'] as String);
        expect(b.locator, matches(RegExp(r'^ص \d+$')), reason: c['id'] as String);
        expect(b.textAr!.trim(), isNotEmpty);
      }
    }
    expect(quoted, greaterThanOrEqualTo(14));
    final src = (usul['sources'] as List).single as Map<String, dynamic>;
    expect(src['license_use'], 'bundled_ok');
  });

  test('answer keys are exactly the ones the coverage report / U2 compute', () {
    const known = {'bayan_nabawi', 'ikhtilaf_explicit', 'nuzul', 'ijma', 'naql', 'turuq_sahabi', 'turuq_tabii'};
    for (final c in (usul['concepts'] as List).cast<Map<String, dynamic>>()) {
      for (final b in LearningConcept.fromJson(c).blocks.where((b) => b.kind == 'usul_answer')) {
        expect(known, contains(b.textAr), reason: c['id'] as String);
      }
    }
  });

  test('merged payload validates and seeds concepts + relations beside the lessons', () async {
    final v = QuranLearningSync().validate(merged);
    expect(v.ok, isTrue, reason: v.toString());
    final res = await QuranLearningSync().ingestFromJson(merged);
    expect(res.outcome, 'seeded');

    final db = await DatabaseHelper.instance.database;
    final usulConcepts = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM knowledge_concepts WHERE domain = 'usul_tafsir'"));
    expect(usulConcepts, (usul['concepts'] as List).length);
    final rels = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM knowledge_relations'));
    expect(rels, (usul['relations'] as List).length);
    // The existing lessons are still there (the wholesale rebuild includes both).
    final protoFacts = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM knowledge_facts WHERE domain != 'usul_tafsir'"));
    expect(protoFacts, (proto['facts'] as List).length);
    final usulFacts = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM knowledge_facts WHERE domain = 'usul_tafsir'"));
    expect(usulFacts, (usul['facts'] as List).length);
    // The page survives the round trip through blocks_json.
    final row = (await db.query('knowledge_concepts', where: 'id = ?', whereArgs: ['concept:usul:nuzul'])).single;
    final nuzul = LearningConcept.fromRow(row);
    expect(nuzul.blocks.first.locator, 'ص 16');
    expect(nuzul.blocks.first.textAr, startsWith('ومعرفة سبب النزول يعين على فهم الآية'));
  });

  // U5 — the ayat the Muqaddima itself uses as examples.
  test('book examples: quoted with a page, on a real node, never a guessed kind', () {
    final facts = (usul['facts'] as List).cast<Map<String, dynamic>>();
    final nodes = {for (final c in (usul['concepts'] as List)) (c as Map)['id'] as String};
    final ayat = <String>{};
    for (final f in facts) {
      final p = (f['payload'] as Map).cast<String, dynamic>();
      final a = (f['anchor'] as Map).cast<String, dynamic>();
      expect(f['domain'], 'usul_tafsir');
      expect(f['source_ref_id'], 'src:muqaddima_usul_tafsir');
      expect(a['scope'], 'ayah');
      expect(a['word_start'], isNull, reason: 'an example is about the whole ayah');
      expect(nodes, contains(p['concept_id']), reason: f['id'] as String);
      expect(p['locator'], matches(RegExp(r'^ص \d+$')));
      expect(const {'example', 'error', 'basis'}, contains(p['kind']));
      // A mistaken tafsir is only ever cited under the two nodes that warn.
      if (p['kind'] == 'error') {
        expect(const {'concept:usul:istidlal', 'concept:usul:naql'}, contains(p['concept_id']), reason: f['id'] as String);
      }
      expect((p['text'] as String).trim(), isNotEmpty);
      ayat.add('${a['surah']}:${a['ayah']}');
    }
    expect(ayat.length, greaterThanOrEqualTo(20), reason: 'U5 promises ~20 fully answered ayat');
    // Spot checks against the book: the famous examples are where Ibn Taymiyya put them.
    String? kindOf(String node, int s, int a) => facts
        .where((f) => (f['payload'] as Map)['concept_id'] == 'concept:usul:$node' &&
            (f['anchor'] as Map)['surah'] == s && (f['anchor'] as Map)['ayah'] == a)
        .map((f) => (f['payload'] as Map)['kind'] as String?)
        .firstOrNull;
    expect(kindOf('tanawwu_ibara', 1, 6), 'example'); // الصراط المستقيم
    expect(kindOf('tanawwu_mithal', 35, 32), 'example'); // ظالم لنفسه / مقتصد / سابق
    expect(kindOf('muhtamal', 74, 51), 'example'); // قسورة
    expect(kindOf('istidlal', 111, 1), 'error'); // تبت يدا أبي لهب
    expect(kindOf('bil_ray', 80, 31), 'example'); // وفاكهة وأبًّا
  });

  test('examples reach the tree, and stay out of the word knowledge surface', () async {
    await QuranLearningSync().ingestFromJson(merged);
    final repo = UsulTreeRepository();
    final ex = await repo.examplesFor(111, 1);
    expect(ex['concept:usul:istidlal']!.map((e) => e.kind), everyElement('error'));
    expect(ex['concept:usul:istidlal']!.first.locator, matches(RegExp(r'^ص \d+$')));
    expect(await repo.examplesFor(1, 2), isEmpty);
    final index = await repo.exampleAyat();
    expect(index.first.surah, 1, reason: 'mushaf order');
    expect(index.length, greaterThanOrEqualTo(20));
    final local = await LocalKnowledgeProvider().factsForAyah(1, 6);
    expect(local.where((f) => f.domain == 'usul_tafsir'), isEmpty);
  });

  // U6 — «أعد بناء الشجرة»: recall cards on the shared review engine.
  test('rebuild: one card per parent, named in the science’s own words, stable ids', () async {
    await QuranLearningSync().ingestFromJson(merged);
    final root = (await UsulTreeRepository().tree())!;
    final groups = usulRebuildGroups(root);
    expect(groups.map((g) => g.prompt), [
      'أقسام أصول التفسير',
      'أنواع اختلاف السلف في التفسير',
      'أنواع الاختلاف من جهة النقل ومن جهة الاستدلال',
      'مراتب أحسن طرق التفسير',
    ]);
    expect(groups.map((g) => g.children.length), [4, 5, 2, 5]);
    expect(groups.map((g) => g.itemId).toSet().length, groups.length);
    // The id is a pure function of the concept id — the same on every device.
    expect(usulItemId('concept:usul:usul'), usulItemId('concept:usul:usul'));
    expect(usulItemId('concept:usul:usul'), isNot(usulItemId('concept:usul:turuq')));
    expect(usulItemId('concept:usul:usul'), inInclusiveRange(0, 0x7FFFFFFF));
    expect(relNoun('أقسامه'), 'أقسام');
    expect(relNoun(null), '');

    // First session enrols the card; it then shows up in the shared due list.
    final review = KnowledgeReviewRepository();
    expect(await review.isUnderReview(usulReviewType, groups.first.itemId), isFalse);
    await review.startReviewing(usulReviewType, groups.first.itemId);
    expect(await review.isUnderReview(usulReviewType, groups.first.itemId), isTrue);
    expect((await review.dueTodayAll()).keys, contains(usulReviewType));
  });

  test('a dangling edge is rejected', () {
    final broken = jsonDecode(jsonEncode(merged)) as Map<String, dynamic>;
    (broken['relations'] as List).add({'from': 'concept:usul:usul', 'rel': 'أقسامه', 'to': 'concept:usul:nowhere', 'ord': 99});
    expect(QuranLearningSync().validate(broken).ok, isFalse);
  });
}
