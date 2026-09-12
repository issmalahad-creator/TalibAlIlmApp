import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/quran_book_cache.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';
import 'package:talib_alilm_app/screens/quran_learning/corpus_panels.dart';
import 'package:talib_alilm_app/services/quran_import_service.dart';

/// Ismail (2026-09-12): "أصلحت التفسير جيدًا ولكن الترجمة لم تكملها... هل
/// لك أن تصلح موضوع الترجمة؟" — the footnote/explanation feature
/// (TAFSIR_UNIFIED_ARCHITECTURE.md §5) landed in AyahStudyScreen's
/// tafsir/translation list, but the everyday «الترجمة» tab
/// (AyahTranslationPanel, the 138-edition System-C picker most people
/// actually use) still showed literal text only. This proves the real
/// explanatory note now surfaces directly there too, for a real
/// footnote-bearing language (Amharic), sourced from the real bundled
/// assets via both QuranCorpusSync (System C editions) and
/// QuranImportService (System A footnotes) — not mocked.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_translation_footnote_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await QuranCorpusSync().sync();
    await QuranImportService().importIfNeeded();
  });

  setUp(QuranBookCache.instance.clear);

  Future<void> pumpPanel(WidgetTester tester, Widget panel) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: panel)),
    ));
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump();
    }
  }

  testWidgets(
      'الترجمة tab shows a real explanatory note for Amharic, collapsed by default',
      (tester) async {
    // `lang: 'am'` makes the panel initialize straight into the Amharic
    // locale — the same locale code ('am') both System C (bundled edition)
    // and System A (QuranEnc footnote) use — without needing to drive the
    // dropdown's popup route.
    await pumpPanel(
        tester, const AyahTranslationPanel(surah: 1, ayah: 1, lang: 'am'));

    // The explanatory-note box is present but collapsed — its label shows,
    // its content does not, until tapped.
    expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
    expect(find.textContaining('ቡኻሪ'), findsNothing);

    await tester.tap(find.byIcon(Icons.sticky_note_2_outlined));
    await tester.pump();

    expect(find.textContaining('ቡኻሪ'), findsOneWidget);
  });

  testWidgets(
      'a language with no real footnote for this ayah never shows the note box',
      (tester) async {
    // Amharic footnote (per the real fetched data) is scoped to 1:1;
    // 1:2's Amharic entry has none — must not fabricate a note here either.
    await pumpPanel(
        tester, const AyahTranslationPanel(surah: 1, ayah: 2, lang: 'am'));
    expect(find.byIcon(Icons.sticky_note_2_outlined), findsNothing);
  });
}
