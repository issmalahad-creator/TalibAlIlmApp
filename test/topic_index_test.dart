import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_repository.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';
import 'package:talib_alilm_app/screens/quran_learning/topic_index_screen.dart';

/// Phase 80 / QC4 — the offline Quran Knowledge Index: topic search →
/// a topic's places across the Quran → the ayah's study page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late QuranCorpusRepository repo;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_topic_index_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await QuranCorpusSync().sync();
    repo = QuranCorpusRepository();
  });

  test('empty query returns the broadest topics, most-covered first', () async {
    final r = await repo.searchTopics('');
    expect(r, isNotEmpty);
    final counts =
        r.map((t) => (t['ayat'] as num?)?.toInt() ?? 0).toList();
    for (var i = 1; i < counts.length; i++) {
      expect(counts[i] <= counts[i - 1], isTrue, reason: 'ordered by ayat DESC');
    }
  });

  test('name search + LIKE-wildcard escaping', () async {
    final r = await repo.searchTopics('اللباس');
    expect(r.any((t) => '${t['name']}'.contains('اللباس')), isTrue);
    // a query full of LIKE metacharacters must not throw or match everything
    expect(() => repo.searchTopics('100%_\\'), returnsNormally);
    expect((await repo.searchTopics('zz_no_such_%topic')), isEmpty);
  });

  test('topicAyat expands ranges, de-dupes, orders, and caps', () async {
    // a topic that covers 7:26 (اللباس/الريش in the raw dump)
    final topics = await repo.topicsForAyah(7, 26);
    expect(topics, isNotEmpty);
    final id = topics.first['id'] as int;
    final ayat = await repo.topicAyat(id);
    expect(ayat, isNotEmpty);
    expect(ayat.any((a) => a.surah == 7 && a.ayah == 26), isTrue);
    for (var i = 1; i < ayat.length; i++) {
      final prev = ayat[i - 1], cur = ayat[i];
      final ok = cur.surah > prev.surah ||
          (cur.surah == prev.surah && cur.ayah > prev.ayah);
      expect(ok, isTrue, reason: 'sorted, de-duped');
    }
  });

  testWidgets('TopicIndexScreen (topic mode) lists the topic\'s ayat',
      (t) async {
    // DB access must sit inside runAsync under the widget-test binding
    // (sqflite_ffi uses real timers; fake-async would deadlock the await).
    late int id;
    await t.runAsync(() async {
      id = (await repo.topicsForAyah(7, 26)).first['id'] as int;
    });
    await t.pumpWidget(MaterialApp(
      home: TopicIndexScreen(topicId: id, title: 'اختبار'),
    ));
    for (var i = 0; i < 40; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await t.pump();
    }
    expect(find.text('اختبار'), findsOneWidget); // AppBar title
    expect(find.textContaining('الأعراف : 26'), findsWidgets);
  });
}
