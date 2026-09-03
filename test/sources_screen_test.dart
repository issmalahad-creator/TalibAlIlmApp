import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_repository.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';
import 'package:talib_alilm_app/screens/quran_learning/sources_screen.dart';

/// Phase 80 / QC5a — the «عن المصادر» screen: every bundled dataset / book /
/// edition with its attribution; the GPL corpus.quran.com credit + link is
/// always on screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late QuranCorpusRepository repo;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_sources_test.db';
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

  test('corpusMeta carries a source + version for each dataset', () async {
    final meta = await repo.corpusMeta();
    expect(meta, isNotEmpty);
    expect(meta.every((m) => '${m['source'] ?? ''}'.isNotEmpty), isTrue);
    expect(meta.any((m) => '${m['source_version'] ?? ''}'.isNotEmpty), isTrue);
  });

  testWidgets('SourcesScreen shows the licence-required QAC credit', (t) async {
    await t.pumpWidget(const MaterialApp(home: SourcesScreen()));
    for (var i = 0; i < 40; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await t.pump();
    }
    expect(find.text('عن المصادر'), findsOneWidget);
    expect(find.textContaining('Quranic Arabic Corpus'), findsOneWidget);
    expect(find.text('https://corpus.quran.com'), findsOneWidget);
    expect(find.textContaining('MIT'), findsWidgets); // Treebank licence
  });
}
