import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/quran_learning.dart';
import 'package:talib_alilm_app/repositories/quran_learning_repository.dart';
import 'package:talib_alilm_app/repositories/quran_learning_sync.dart';

/// Phase 79 `79-ql` — the Prototype chain, against a real SQLite DB and the
/// real bundled `assets/quran_learning/prototype.json`. Proves:
/// every fact has a resolvable source; the gateway resolves a word to
/// sourced ṣarf/naḥw/tajwīd; the iʿrāb graph has typed relations; a
/// bad payload is rejected; study events are append-only with no quiz verbs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Map<String, dynamic> proto;

  setUpAll(() {
    DatabaseHelper.databaseName = 'talib_ql_test.db';
    final f = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    final asset = File(join('assets', 'quran_learning', 'prototype.json'));
    expect(asset.existsSync(), isTrue, reason: 'bundled prototype.json must exist');
    proto = jsonDecode(utf8.decode(asset.readAsBytesSync())) as Map<String, dynamic>;
  });

  group('validation', () {
    test('the bundled prototype.json passes every check', () {
      final v = QuranLearningSync().validate(proto);
      expect(v.ok, isTrue, reason: v.toString());
      expect(v.facts, greaterThan(80));
      expect(v.factsWithoutSource, 0);
      expect(v.factsWithBadAnchor, 0);
      expect(v.factsWithUndisplayableSource, 0);
      expect(v.sources, greaterThanOrEqualTo(5));
    });

    test('a fact with no source is rejected, DB untouched', () async {
      final broken = jsonDecode(jsonEncode(proto)) as Map<String, dynamic>;
      (broken['facts'] as List).add({
        'id': 'x:9:9:9',
        'domain': 'nahw',
        'anchor': {'surah': 9, 'ayah': 9, 'word_start': 1, 'word_end': 1, 'scope': 'word', 'segmentation': 'mushafdb-v1.01'},
        'payload': {'role': 'x'},
        'source_ref_id': 'src:does-not-exist',
      });
      final v = QuranLearningSync().validate(broken);
      expect(v.ok, isFalse);
      final res = await QuranLearningSync().ingestFromJson(broken);
      expect(res.outcome, 'rejected');
      final db = await DatabaseHelper.instance.database;
      expect(Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM knowledge_facts')), 0);
    });
  });

  group('seeded — the chain', () {
    late QuranLearningRepository repo;

    setUpAll(() async {
      final res = await QuranLearningSync().ingestFromJson(proto);
      expect(res.outcome, 'seeded');
      repo = QuranLearningRepository();
    });

    test('every seeded fact resolves to a bundleable, displayable source', () async {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery('''
        SELECT f.id, s.classification, s.license_use
        FROM knowledge_facts f LEFT JOIN source_references s ON f.source_ref_id = s.id
      ''');
      expect(rows, isNotEmpty);
      for (final r in rows) {
        expect(r['classification'], isNotNull, reason: 'orphan source for ${r['id']}');
        expect(['VERIFIED', 'SOURCE_BACKED', 'PROJECT_SPECIFIC'], contains(r['classification']));
        expect(r['license_use'], 'bundled_ok');
      }
    });

    test('tap al-Fatiha 1:1 word 1 → ṣarf + naḥw, each with a source', () async {
      final r = await repo.factsForWord(1, 1, 1);
      expect(r.facts('sarf'), isNotEmpty);
      expect(r.facts('nahw'), isNotEmpty);
      for (final list in r.byDomain.values) {
        for (final f in list) {
          expect(r.sourceFor(f), isNotNull, reason: 'no source for ${f.id}');
          expect(r.sourceFor(f)!.displayable, isTrue);
        }
      }
      expect(r.facts('sarf').first.payload['root'], 'س م و'); // from QAC
    });

    test('tap al-Fatiha 1:1 word 3 → a sourced tajwīd rule (همزة الوصل)', () async {
      final r = await repo.factsForWord(1, 1, 3);
      expect(r.facts('tajweed'), isNotEmpty);
      final rules = (r.facts('tajweed').first.payload['rules'] as List).cast<Map>();
      expect(rules.map((m) => m['rule_id']), contains('hamzat_wasl'));
      expect(r.sourceFor(r.facts('tajweed').first)!.name, contains('quran-tajweed'));
    });

    test('iʿrāb of al-Ikhlas 112:1 covers every word and has typed relations', () async {
      final irab = await repo.irabForAyah(112, 1);
      expect(irab.length, 4); // قل هو الله أحد
      final roles = {for (final f in irab) f.anchor.wordStart!: f.payload['role_ar']};
      expect(roles[1], contains('فعل أمر'));
      expect(roles[2], contains('مبتدأ'));
      final withRelations = irab.where((f) => (f.payload['relations'] as List).isNotEmpty);
      expect(withRelations, isNotEmpty);
      final rel = (withRelations.first.payload['relations'] as List).first as Map;
      expect(rel['to_word'], isA<int>());
      expect(rel['rel_ar'], isA<String>());
    });

    test('the launcher orders naḥw first (P0)', () async {
      final order = await repo.availableDomainsOrdered(1, 2, 1); // «الحمد»
      expect(order.first, 'nahw');
    });

    test('"تعلّم هذا" opens a concept, records a learning-path item + a non-quiz event', () async {
      final f = (await repo.factsForWord(1, 2, 1)).facts('nahw').first;
      final conceptId = f.conceptId!;
      final c = await repo.concept(conceptId);
      expect(c, isNotNull);
      expect(c!.blocks, isNotEmpty);

      final id = await repo.startLearning(conceptId: conceptId, surah: 1, ayah: 2, wordStart: 1, wordEnd: 1);
      expect(id, greaterThan(0));
      await repo.logEvent(
        verb: StudyEventVerbs.openedLesson, targetKind: 'concept', targetId: conceptId,
        surah: 1, ayah: 2, wordStart: 1, layer: 'nahw');
      await repo.logEvent(
        verb: StudyEventVerbs.returnedToAyah, targetKind: 'concept', targetId: conceptId,
        surah: 1, ayah: 2, layer: 'nahw');

      final path = await repo.learningPath();
      expect(path.where((p) => p.conceptId == conceptId), isNotEmpty);

      final db = await DatabaseHelper.instance.database;
      final verbs = (await db.query('study_events', columns: ['verb']))
          .map((r) => r['verb'] as String)
          .toSet();
      expect(verbs, contains('opened_lesson'));
      expect(verbs.intersection({'answered', 'correct', 'incorrect'}), isEmpty);
    });

    test('a rejected quiz-style verb is silently dropped', () async {
      final before = await repo.eventCount();
      await repo.logEvent(verb: 'answered', targetKind: 'concept', targetId: 'x');
      expect(await repo.eventCount(), before);
    });

    test('learning path groups by concept domain', () async {
      final byDomain = await repo.learningPathByDomain();
      expect(byDomain.keys, contains('nahw'));
    });
  });
}
