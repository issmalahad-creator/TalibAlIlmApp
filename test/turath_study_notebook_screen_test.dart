import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/turath_repository.dart';
import 'package:talib_alilm_app/screens/turath_study_notebook_screen.dart';
import 'package:talib_alilm_app/utils/study_annotation_anchor.dart';

/// Phase 79 `79-sa-D` — the unified notebook screen renders real annotation
/// rows and its colour filter narrows the list.
///
/// The DB runs on a real background thread under `sqflite_common_ffi`, so
/// these use `runAsync` + explicit `pump`s rather than `pumpAndSettle`.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const page = 'اعلم أنّ الأعمال بالنيّات، وأنّ لكلّ امرئٍ ما نوى.';

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_notebook_screen_test.db';
    final f = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();

    final repo = TurathRepository();
    final norm = normalizePageText(page);
    await repo.addAnnotation(bookId: 1, pageNumber: 3, normalizedPageText: norm, selectedText: 'الأعمال بالنيّات', charStartHint: norm.indexOf('الأعمال'), colorKey: 'benefit', noteType: 'benefit', noteBody: 'فائدة النية', bookName: 'الأربعون', authorName: 'النووي');
    await repo.addAnnotation(bookId: 1, pageNumber: 4, normalizedPageText: norm, selectedText: 'لكلّ امرئٍ ما نوى', charStartHint: norm.indexOf('لكلّ'), colorKey: 'question', noteType: 'question', noteBody: 'إشكال', bookName: 'الأربعون', authorName: 'النووي');
  });

  Future<void> pumpLoaded(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
  }

  testWidgets('renders every annotation with its text, note and source', (tester) async {
    await pumpLoaded(tester, const TurathStudyNotebookScreen());

    expect(find.text('الأعمال بالنيّات'), findsOneWidget);
    expect(find.text('فائدة النية'), findsOneWidget);
    expect(find.text('لكلّ امرئٍ ما نوى'), findsOneWidget);
    expect(find.textContaining('الأربعون'), findsWidgets);
    expect(find.textContaining('النووي'), findsWidgets);
  });

  testWidgets('a colour filter chip narrows the list', (tester) async {
    await pumpLoaded(tester, const TurathStudyNotebookScreen());

    // the chip row also carries the highlight/page-note kind chips up front
    // now, so the 5th colour chip can start off the right edge — bring it in.
    final questionChip = find.byType(FilterChip).at(4); // question is the 5th colour
    await tester.ensureVisible(questionChip);
    await tester.pump();
    await tester.tap(questionChip);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();

    expect(find.text('لكلّ امرئٍ ما نوى'), findsOneWidget);
    expect(find.text('الأعمال بالنيّات'), findsNothing);
  });

  testWidgets('book-scoped notebook with no notes shows the empty state', (tester) async {
    await pumpLoaded(tester, const TurathStudyNotebookScreen(bookId: 999, bookTitle: 'كتاب بلا فوائد'));
    expect(find.textContaining('لا فوائد بعد'), findsOneWidget);
  });
}
