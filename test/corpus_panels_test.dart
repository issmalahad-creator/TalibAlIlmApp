import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/quran_book_cache.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';
import 'package:talib_alilm_app/screens/quran_learning/corpus_panels.dart';

/// Phase 80 / QC3 — the Quran Corpus panels render real, sourced content
/// from the bundled `assets/quran/corpus/` datasets over the canonical
/// `(surah, ayah[, word_index])` spine — never a guess, never a silent
/// empty section.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_corpus_panels_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await QuranCorpusSync().sync();
  });

  setUp(QuranBookCache.instance.clear);

  // Real async (disk DB + gunzip `compute` isolate) only runs inside
  // `runAsync`; interleave short real windows with `pump()` so each
  // `setState` in the load → setState → load chain reaches a frame.
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

  test('stripCorpusHtml turns markup into plain text with real breaks', () {
    // </p> and <br/> both count as a break → one paragraph gap.
    expect(stripCorpusHtml('<p>الحمد</p><br/>لله &amp; <b>رب</b>'),
        'الحمد\n\nلله & رب');
    expect(stripCorpusHtml('سطر<br/>سطر'), 'سطر\nسطر');
    expect(stripCorpusHtml(['<p>أ</p>', '<p>ب</p>']), 'أ\n\nب');
    expect(stripCorpusHtml({'text': '<span>س</span>'}), 'س');
    expect(stripCorpusHtml(null), '');
  });

  testWidgets('WordCorpusPanel shows ṣarf for al-Ikhlāṣ 112:1 word 1', (t) async {
    await pumpPanel(
      t,
      const WordCorpusPanel(surah: 112, ayah: 1, wordIndex: 1, lang: 'ar'),
    );
    expect(find.text('علوم الكلمة'), findsOneWidget);
    expect(find.text('الصرف'), findsOneWidget);
    // the licence-required QAC credit is on-screen
    expect(find.textContaining('corpus.quran.com'), findsWidgets);
  });

  testWidgets('AyahCorpusPanel surfaces topics for 7:26', (t) async {
    await pumpPanel(t, const AyahCorpusPanel(surah: 7, ayah: 26, lang: 'ar'));
    // 7:26 has topic links in the raw dump (see quran_corpus_test.dart)
    expect(find.text('الموضوعات'), findsOneWidget);
    expect(find.text('لا توجد بيانات موثقة لهذا العنصر حاليًا.'), findsNothing);
  });

  testWidgets('AyahTafsirPanel shows a short excerpt + «للمزيد» for 1:1',
      (t) async {
    var opened = false;
    await pumpPanel(
      t,
      AyahTafsirPanel(
        surah: 1,
        ayah: 1,
        lang: 'ar',
        onOpenFull: () => opened = true,
      ),
    );
    expect(find.byType(DropdownButton<int>), findsOneWidget);
    // a book was auto-picked → source line rendered
    expect(find.textContaining('المصدر:'), findsOneWidget);
    // the card shows an excerpt, not a full reader
    expect(find.byType(SelectableText), findsNothing);
    // «التفسير كاملًا» opens the dedicated page
    final more = find.widgetWithText(OutlinedButton, 'التفسير كاملًا');
    expect(more, findsOneWidget);
    await t.tap(more);
    expect(opened, isTrue);
  });

  testWidgets('AyahTranslationPanel: language arrow + per-edition boxes for 1:1',
      (t) async {
    await pumpPanel(t, const AyahTranslationPanel(surah: 1, ayah: 1, lang: 'en'));
    expect(find.byType(DropdownButton<String>), findsOneWidget); // language
    // one collapsed box per English edition; nothing loaded until tapped
    expect(find.byIcon(Icons.expand_more_rounded), findsWidgets);
    expect(find.byType(SelectableText), findsNothing);
    // tap the first box → it loads + shows the basmala from a real edition
    await t.tap(find.byIcon(Icons.expand_more_rounded).first);
    for (var i = 0; i < 20; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await t.pump();
    }
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.textContaining('Merciful'), findsOneWidget);
  });
}
