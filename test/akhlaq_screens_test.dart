import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/screens/akhlaq/akhlaq_home_screen.dart';
import 'package:talib_alilm_app/screens/akhlaq/akhlaq_profile_screen.dart';
import 'package:talib_alilm_app/screens/akhlaq/akhlaq_scenario_screen.dart';
import 'package:talib_alilm_app/services/akhlaq/akhlaq_content.dart';

/// AKHLAQ · P4 — the training loop renders: today's plan → a sourced
/// scenario → pick a response → verdict + evidence, and the training
/// indicator carries the mandatory disclaimer, never a score.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_akhlaq_screens_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    AkhlaqContent.instance.debugSetSlice(AkhlaqContent.parseJsonString(
        File('docs/akhlaq/alrifq/ar-rifq.json').readAsStringSync()));
    await DatabaseHelper.instance.database;
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('akhlaq_attempt');
    await db.delete('akhlaq_sr_state');
    await db.delete('akhlaq_progress');
    await db.delete('akhlaq_meta');
  });

  tearDownAll(() => AkhlaqContent.instance.debugSetSlice(null));

  // The screens show a spinner while loading; pumpAndSettle would never
  // settle it, so drive real async work then a few frames by hand.
  Future<void> tick(WidgetTester tester) async {
    for (var i = 0; i < 14; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  testWidgets('home shows the virtue + today plan', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AkhlaqHomeScreen()));
    await tick(tester);
    expect(find.text('الرِّفق'), findsWidgets);
    expect(find.text('تكليف اليوم'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsWidgets);
  });

  testWidgets('scenario: choosing an option reveals a verdict + evidence',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: AkhlaqScenarioScreen(scenarioId: 'S-01')));
    await tick(tester);

    expect(find.textContaining('موقف — مستوى'), findsOneWidget);
    expect(find.text('اختر استجابتك'), findsOneWidget);

    // S-01 option C ("فائدةٌ: الصواب…") is the aqrab one
    final optC = find.ancestor(
        of: find.textContaining('فائدة'), matching: find.byType(InkWell));
    await tester.ensureVisible(optC);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.tap(optC);
    await tick(tester);

    expect(find.text('الاستجابة الأقرب للرفق في هذا الموقف'), findsOneWidget);
    expect(find.text('الدليل'), findsOneWidget);
    expect(find.text('تمّ'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('profile shows the disclaimer and a descriptive band, no score',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AkhlaqProfileScreen()));
    await tick(tester);
    expect(find.textContaining('وليس حكمًا على أخلاقك'), findsOneWidget);
    expect(find.text('لم يبدأ'), findsWidgets);
    expect(find.textContaining('%'), findsNothing);
  });
}
