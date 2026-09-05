import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/data/tajweed_rules_ref.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_repository.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';
import 'package:talib_alilm_app/services/quran_learning/knowledge_gateway.dart';

/// Phase G-t1 — tajwīd rule spans (cpfair/quran-tajweed, CC BY 4.0) seed
/// from the real bundled `assets/quran/corpus/tajweed.json.gz` for all 6236
/// ayāt, every span lands inside its word, every rule id is one of the 18.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final repo = QuranCorpusRepository();

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_tajweed_sync_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await QuranCorpusSync().sync();
  });

  test('quran_tajweed is seeded with a meta row + a row for every ayah',
      () async {
    final db = await DatabaseHelper.instance.database;
    final meta = await db.query('quran_corpus_meta',
        where: 'dataset = ?', whereArgs: ['tajweed']);
    expect(meta, hasLength(1));
    expect(meta.first['licence'], contains('CC BY 4.0'));

    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM quran_tajweed'));
    expect(count, 6236);
  });

  test('every span is in-bounds and every rule id is a known family member',
      () async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quran_tajweed');

    // word lengths straight from the layout the offsets index
    final wordLen = <String, int>{};
    for (final w in await db.query('mushaf_words',
        columns: ['surah', 'ayah', 'word_index', 'text_uthmani'])) {
      wordLen['${w['surah']}:${w['ayah']}:${w['word_index']}'] =
          (w['text_uthmani'] as String? ?? '').length;
    }

    var spanCount = 0;
    final seenRules = <String>{};
    for (final r in rows) {
      final s = r['surah'], a = r['ayah'];
      final spans = jsonDecode(r['data'] as String) as List;
      for (final sp in spans.cast<Map<String, dynamic>>()) {
        spanCount++;
        final rule = sp['r'] as String;
        seenRules.add(rule);
        expect(kTajweedRules.containsKey(rule), isTrue,
            reason: 'unknown rule "$rule" at $s:$a');
        final cs = sp['cs'] as int, ce = sp['ce'] as int;
        expect(cs, greaterThanOrEqualTo(0));
        expect(ce, greaterThan(cs));
        final len = wordLen['$s:$a:${sp['w']}'];
        if (len != null) {
          expect(ce, lessThanOrEqualTo(len),
              reason: '$s:$a word ${sp['w']} span [$cs,$ce) > len $len');
        }
      }
    }
    expect(spanCount, greaterThan(60000));
    // the corpus really does exercise most of the 18 rules
    expect(seenRules.length, greaterThanOrEqualTo(16));
  });

  test('every family in kTajweedFamilies resolves a palette + label key', () {
    for (final (famKey, l10nKey) in kTajweedFamilies) {
      expect(l10nKey.startsWith('ql_tajfam_'), isTrue);
      final members =
          kTajweedRules.values.where((r) => r.familyKey == famKey).toList();
      expect(members, isNotEmpty, reason: 'family $famKey has no rules');
    }
    // all 18 rule refs point at one of the six families
    final famKeys = kTajweedFamilies.map((e) => e.$1).toSet();
    for (final r in kTajweedRules.values) {
      expect(famKeys.contains(r.familyKey), isTrue);
    }
  });

  test('CorpusTajweedProvider returns per-word facts for al-Fātiḥa 1:1',
      () async {
    final facts = await CorpusTajweedProvider().factsForAyah(1, 1);
    expect(facts, isNotEmpty);
    for (final f in facts) {
      expect(f.domain, 'tajweed');
      expect(f.sourceRefId, 'src:cpfair-tajweed');
      final rules = (f.payload['rules'] as List).cast<Map>();
      expect(rules, isNotEmpty);
      for (final rule in rules) {
        expect(kTajweedRules.containsKey(rule['rule_id']), isTrue);
        expect(rule['rule_ar'], isNotEmpty);
        expect((rule['concept_id'] as String).startsWith('concept:tajweed:'),
            isTrue);
      }
    }
  });

  test('LocalKnowledgeProvider no longer claims the tajweed domain', () {
    expect(LocalKnowledgeProvider().domains.contains('tajweed'), isFalse);
    expect(CorpusTajweedProvider().domains, {'tajweed'});
  });

  test('repository AyahTajweed groups rules by family in canonical order',
      () async {
    final t = await repo.tajweedForAyah(1, 1);
    expect(t.isNotEmpty, isTrue);
    final byFam = t.ruleIdsByFamily;
    // al-Fātiḥa 1:1 has hamzat al-waṣl + lām shamsiyyah (lam_hamza) and a madd
    expect(byFam.keys, contains('lam_hamza'));
    expect(byFam.keys, contains('madd'));
    // family keys come back in kTajweedFamilies order
    final order = kTajweedFamilies.map((e) => e.$1).toList();
    final got = byFam.keys.toList();
    final idx = got.map(order.indexOf).toList();
    final sorted = [...idx]..sort();
    expect(idx, sorted);
  });
}
