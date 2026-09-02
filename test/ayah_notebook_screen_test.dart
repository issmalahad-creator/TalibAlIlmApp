import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/ayah_study_entry.dart';
import 'package:talib_alilm_app/repositories/ayah_study_repository.dart';
import 'package:talib_alilm_app/screens/ayah_notebook_screen.dart';

/// Phase 79 `79-sa-D-ayah` phase 2 — the per-ayah "جلسة دراسة الآية"
/// renders the journey, the overview strip, and the free-writing add sheet.
/// (On-device the reader's ayah tap-menu is a separate pre-existing path;
/// this proves the screen itself.)

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_ayah_notebook_screen_test.db';
    final f = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();

    final repo = AyahStudyRepository();
    await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'من درس الشيخ اليوم', entryType: AyahEntryTypes.lessonSummary));
    await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'من تفسير ابن كثير', entryType: AyahEntryTypes.tafsir));
    await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'سؤال أريد بحثه', entryType: AyahEntryTypes.question));
  });

  Future<void> pumpLoaded(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
  }

  testWidgets('shows the journey and an overview count strip', (tester) async {
    await pumpLoaded(tester, const AyahNotebookScreen(surah: 2, ayah: 255));
    // chronological order: lesson summary first
    expect(find.text('من درس الشيخ اليوم'), findsOneWidget);
    expect(find.text('من تفسير ابن كثير'), findsOneWidget);
    expect(find.text('سؤال أريد بحثه'), findsOneWidget);
    // overview chips carry counts (e.g. "1 قول مفسّر")
    expect(find.textContaining('قول مفسّر'), findsWidgets);
  });

  testWidgets('an empty ayah shows the "free writing first" prompt', (tester) async {
    await pumpLoaded(tester, const AyahNotebookScreen(surah: 114, ayah: 1));
    expect(find.textContaining('لا مداخل بعد'), findsOneWidget);
  });

  testWidgets('the add sheet opens straight to the body field', (tester) async {
    await pumpLoaded(tester, const AyahNotebookScreen(surah: 114, ayah: 1));
    await tester.tap(find.widgetWithText(FloatingActionButton, 'إضافة إلى دفتر الآية'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('اكتب هنا ما تعلّمته عن هذه الآية...'), findsOneWidget);
    // the type chips + optional source section are present but not required
    expect(find.text('المصدر (اختياري)'), findsOneWidget);
  });
}
