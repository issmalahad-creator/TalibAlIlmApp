import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/repositories/quran_reading_repository.dart';
import 'package:talib_alilm_app/screens/ayah_study_screen.dart';
import 'package:talib_alilm_app/services/quran_import_service.dart';

/// docs/quran/TAFSIR_UNIFIED_ARCHITECTURE.md §5 — Ismail's question: can a
/// non-Arabic reader (Amharic specifically) see a real EXPLANATION of an
/// ayah, not just its literal translation? `tool/fetch_quranenc_footnotes.py`
/// re-fetched every bundled QuranEnc edition with its `footnotes` field
/// (previously discarded); this proves the whole pipeline for real, bundled
/// data — DB v62 column, `QuranImportService` import, `tafsirEntriesForAyah`,
/// and the reader UI's separate «شرح توضيحي» layer — with al-Fātiḥa's
/// Amharic footnote (a real hadith on the sūrah's virtue).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_ayah_study_footnote_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    // The real import path, from the real bundled assets — not a mock.
    await QuranImportService().importIfNeeded();
  });

  test('amharic_sadiq carries a real footnote for al-Fātiḥa 1:1', () async {
    final entries = await QuranReadingRepository().tafsirEntriesForAyah(1, 1);
    final amharic = entries.where((e) => e.source == 'amharic_sadiq').firstOrNull;
    expect(amharic, isNotNull,
        reason: 'amharic_sadiq must be imported for 1:1');
    expect(amharic!.footnote, isNotNull);
    expect(amharic.footnote!.trim(), isNotEmpty);
    // A real hadith reference (Bukhari) about al-Fātiḥa's virtue — proves
    // this is genuine explanatory content, not the literal translation
    // repeated.
    expect(amharic.footnote, contains('ቡኻሪ'));
  });

  test('oromo_ababor — a new language added 2026-09-12 — imports with real text + footnote',
      () async {
    // Ismail is in Ethiopia and asked specifically about Oromo; verified
    // live on quranenc.com (translator: Ghali Ababor) and added as a full
    // 44th tafsir_entries edition, not just Amharic.
    final entries = await QuranReadingRepository().tafsirEntriesForAyah(1, 1);
    final oromo = entries.where((e) => e.source == 'oromo_ababor').firstOrNull;
    expect(oromo, isNotNull, reason: 'oromo_ababor must be imported for 1:1');
    expect(oromo!.text.trim(), isNotEmpty);
    expect(oromo.footnote, isNotNull);
    expect(oromo.footnote!, contains('bukhaariitu'));
  });

  test('a source with no footnote for this ayah stays null, never fabricated',
      () async {
    // 1:2 has no footnote in the real QuranEnc data (verified against the
    // live source while building this fix).
    final entries = await QuranReadingRepository().tafsirEntriesForAyah(1, 2);
    final amharic = entries.where((e) => e.source == 'amharic_sadiq').firstOrNull;
    expect(amharic, isNotNull);
    expect(amharic!.footnote == null || amharic.footnote!.trim().isEmpty, isTrue);
  });

  testWidgets(
      'the reader shows the footnote as a separate labelled section',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AyahStudyScreen(surah: 1, ayah: 1, initialSource: 'amharic_sadiq'),
    ));
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump();
    }
    expect(find.text(basicText('ql_footnote_section', 'ar')), findsOneWidget);
    expect(find.textContaining('ቡኻሪ'), findsOneWidget);
  });
}
