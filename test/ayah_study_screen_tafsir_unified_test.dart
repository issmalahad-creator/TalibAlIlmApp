import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_repository.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';
import 'package:talib_alilm_app/screens/ayah_study_screen.dart';

/// Ismail's bug report (2026-09-11): tapping a bundled tafsir book in the
/// reader's quick-card panel and pressing «التفسير كاملًا» used to silently
/// discard the chosen book and reopen on `AyahStudyScreen`'s unrelated
/// 5-source legacy Arabic list, mixed in with ~40 language translations
/// with no separation ("فقط 5 تفاسير، ومختلط بترجمات"). This proves the
/// fix at `AyahStudyScreen`'s boundary: a real bundled corpus book
/// (`quran_tafsir_book`, ~122 titles) opens on the EXACT book selected,
/// and the card list keeps تفاسير/ترجمات visually separate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_ayah_study_tafsir_unified_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await QuranCorpusSync().sync();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(MaterialApp(home: screen));
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump();
    }
  }

  testWidgets(
      'the card list shows تفاسير for the bundled corpus books (System B)',
      (tester) async {
    // `tafsir_entries` (System A: the 5 legacy Arabic editions + ~42
    // language translations) is populated by a live QuranEnc.com import
    // (`quran_import_service.dart`), not by `QuranCorpusSync` — it stays
    // empty in this offline test DB, so only «تفاسير» (from the bundled
    // corpus books) is assertable here; «ترجمات» needs a live-seeded DB
    // and is covered by device verification instead.
    await pumpScreen(tester, const AyahStudyScreen(surah: 112, ayah: 1));
    expect(find.text(basicText('ql_tafsir_section', 'ar')), findsOneWidget);
  });

  testWidgets(
      'opening with initialBookId lands directly on that bundled book, not the legacy list',
      (tester) async {
    final books = (await tester
        .runAsync(() => QuranCorpusRepository().tafsirBooks(bundled: true)))!;
    expect(books, isNotEmpty,
        reason: 'the bundled corpus tafsir catalog must seed real books');
    final book = books.first;
    final bookId = book['id'] as int;
    final bookName = '${book['name'] ?? book['short'] ?? ''}';

    await pumpScreen(
        tester,
        AyahStudyScreen(surah: 112, ayah: 1, initialBookId: bookId));

    // straight into the book reader — its name is shown, the legacy
    // "اختر تفسيرًا" card list is not.
    expect(find.text(bookName), findsOneWidget);
    expect(find.text(basicText('ql_tafsir_section', 'ar')), findsNothing);

    // "كل المصادر" returns to the unified card list.
    await tester.tap(find.text(basicText('all_sources_action', 'ar')));
    await tester.pump();
    expect(find.text(basicText('ql_tafsir_section', 'ar')), findsOneWidget);
  });

  testWidgets('tapping a bundled book card opens its own full reader',
      (tester) async {
    final books = (await tester
        .runAsync(() => QuranCorpusRepository().tafsirBooks(bundled: true)))!;
    final bookName = '${books.first['name'] ?? books.first['short'] ?? ''}';

    await pumpScreen(tester, const AyahStudyScreen(surah: 112, ayah: 1));
    await tester.tap(find.text(bookName));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // now in the reader for that exact book (its name in the header, the
    // card-list section headers gone).
    expect(find.text(bookName), findsOneWidget);
    expect(find.text(basicText('ql_tafsir_section', 'ar')), findsNothing);
  });
}
