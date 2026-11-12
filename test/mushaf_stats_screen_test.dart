import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/repositories/mushaf_stats_repository.dart';
import 'package:talib_alilm_app/screens/mushaf_stats_screen.dart';

/// «إحصاءات المصحف» opens, counts a surah from `quran_ayat`, shows the
/// numbers and the waqf table.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_stats_screen_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();
    final db = await DatabaseHelper.instance.database;
    await db.delete('quran_ayat');
    final lines = File('assets/quran/quran-uthmani.txt').readAsLinesSync().where((l) => l.startsWith('1|') || RegExp(r'^2\|[1-7]\|').hasMatch(l));
    final batch = db.batch();
    for (final l in lines) {
      final parts = l.split('|');
      batch.insert('quran_ayat', {
        'surah': int.parse(parts[0]), 'ayah': int.parse(parts[1]), 'text_uthmani': parts[2], 'text_normalized': parts[2],
        'page_number': parts[0] == '1' ? 1 : 2, 'juz_number': 1, 'hizb_number': 1,
      });
    }
    await batch.commit(noResult: true);
  });

  testWidgets('al-Fātiḥa: 7 ayat, 29 words, waqf table, no sajda', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await MushafStatsRepository.instance.stats(const StatsScope(StatsScopeKind.surah, 1));
    });
    await tester.pumpWidget(const MaterialApp(home: MushafStatsScreen(initialScope: StatsScope(StatsScopeKind.surah, 1))));
    await tester.pumpAndSettle();
    expect(find.text(basicText('ms_title', 'ar')), findsOneWidget);
    expect(find.text('7'), findsWidgets); // ayat
    expect(find.text('29'), findsOneWidget); // words
    expect(find.text(basicText('ms_waqf_lazim', 'ar')), findsOneWidget);
    expect(find.text(basicText('ms_none_here', 'ar')), findsNWidgets(2)); // no sakta, no sajda
  });
}
