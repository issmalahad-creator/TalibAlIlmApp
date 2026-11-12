import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/screens/main_shell.dart';
import 'package:talib_alilm_app/screens/mushaf_semantic_reader_screen.dart';
import 'package:talib_alilm_app/services/start_screen_preference_service.dart';
import 'package:talib_alilm_app/theme/app_theme.dart';

/// «المصحف هو البيت»: the shell opens on the muṣḥaf by default (no bottom
/// tabs, «كل الأقسام» instead of a back arrow), or on the dashboard when the
/// person chose it; the side menu opens with «اليوم» on top either way.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_shell_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'side_tab_hint_count': 3});
  });

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: const Directionality(textDirection: TextDirection.rtl, child: MainShell())));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('default: the muṣḥaf is home, with «كل الأقسام» and no bottom tabs', (tester) async {
    StartScreenPreferenceService.notifier.value = StartScreenPreferenceService.mushaf;
    await pumpShell(tester);
    expect(find.byType(MushafSemanticReaderScreen), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byIcon(Icons.apps_rounded), findsWidgets);
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);

    await tester.tap(find.byTooltip(basicText('drawer_title', 'ar')));
    await tester.pump(const Duration(milliseconds: 500));
    // Real time for the database, simulated time for the 3 s source limits.
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text(basicText('today_title', 'ar')), findsOneWidget);
    // a fresh install has nothing pending
    expect(find.text(basicText('today_nothing', 'ar')), findsOneWidget);
  });

  testWidgets('dashboard chosen: bottom tabs and the side tab are back', (tester) async {
    StartScreenPreferenceService.notifier.value = StartScreenPreferenceService.home;
    await pumpShell(tester);
    expect(find.byType(MushafSemanticReaderScreen), findsNothing);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.apps_rounded), findsOneWidget); // the side tab
    StartScreenPreferenceService.notifier.value = StartScreenPreferenceService.mushaf;
  });
}
