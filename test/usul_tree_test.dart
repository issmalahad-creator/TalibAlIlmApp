import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/quran_learning.dart';
import 'package:talib_alilm_app/repositories/quran_learning_sync.dart';

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
    final protoFacts = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM knowledge_facts'));
    expect(protoFacts, (proto['facts'] as List).length);
    // The page survives the round trip through blocks_json.
    final row = (await db.query('knowledge_concepts', where: 'id = ?', whereArgs: ['concept:usul:nuzul'])).single;
    final nuzul = LearningConcept.fromRow(row);
    expect(nuzul.blocks.first.locator, 'ص 16');
    expect(nuzul.blocks.first.textAr, startsWith('ومعرفة سبب النزول يعين على فهم الآية'));
  });

  test('a dangling edge is rejected', () {
    final broken = jsonDecode(jsonEncode(merged)) as Map<String, dynamic>;
    (broken['relations'] as List).add({'from': 'concept:usul:usul', 'rel': 'أقسامه', 'to': 'concept:usul:nowhere', 'ord': 99});
    expect(QuranLearningSync().validate(broken).ok, isFalse);
  });
}
