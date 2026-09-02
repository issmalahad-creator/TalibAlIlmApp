import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/ayah_study_entry.dart';
import 'package:talib_alilm_app/repositories/ayah_study_repository.dart';
import 'package:talib_alilm_app/screens/quran_notebook_home_screen.dart';

/// Phase 79 `79-sa-D-ayah` phase 4 — the cross-ayah Quran notebook home
/// renders entries, filters by type, and switches to the "richest ayat"
/// view. DB runs on a real background thread → runAsync + explicit pumps.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_quran_notebook_home_test.db';
    final f = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();

    final repo = AyahStudyRepository();
    await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'فائدة عن آية الكرسي', entryType: AyahEntryTypes.benefit));
    await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'سؤال حول الصيغة', entryType: AyahEntryTypes.question));
    await repo.addEntry(112, 1, const AyahStudyEntryInput(body: 'قل هو الله أحد — التوحيد', entryType: AyahEntryTypes.meaning));
  });

  Future<void> pumpLoaded(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuranNotebookHomeScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
  }

  testWidgets('lists every entry across ayat', (tester) async {
    await pumpLoaded(tester);
    expect(find.text('فائدة عن آية الكرسي'), findsOneWidget);
    expect(find.text('سؤال حول الصيغة'), findsOneWidget);
    expect(find.text('قل هو الله أحد — التوحيد'), findsOneWidget);
  });

  testWidgets('the "open questions" filter narrows the list to open questions', (tester) async {
    await pumpLoaded(tester);
    // first chip in the always-visible filter row
    await tester.tap(find.widgetWithText(FilterChip, 'سؤال مفتوح'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    expect(find.text('سؤال حول الصيغة'), findsOneWidget);
    expect(find.text('فائدة عن آية الكرسي'), findsNothing);
  });

  testWidgets('the "richest ayat" sort shows an aggregated count row', (tester) async {
    await pumpLoaded(tester);
    await tester.tap(find.byIcon(Icons.sort_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الآيات الأكثر ثراءً').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    // البقرة 255 has 2 entries → a "2" count avatar
    expect(find.text('2'), findsOneWidget);
  });
}
