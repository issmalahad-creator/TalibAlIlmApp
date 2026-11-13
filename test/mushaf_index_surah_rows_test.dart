import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/screens/mushaf_index_screen.dart';
import 'package:talib_alilm_app/widgets/mushaf/revelation_icon.dart';

/// The surah index redesign (Ismail 2026-11-13, his reference screenshot):
/// number strip · name · «آياتها» · Kaʿba / dome · page strip, and the
/// surah being read is marked and in view.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DatabaseHelper.databaseName = 'talib_index_rows_test.db';

  Future<void> pumpIndex(WidgetTester t, {int currentPage = 0}) async {
    await t.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MushafIndexScreen(lang: 'ar', currentPage: currentPage),
      ),
    ));
    await t.pump();
  }

  testWidgets('first rows: al-Fātiḥa is Meccan, al-Baqara Medinan, with ayah counts',
      (t) async {
    await pumpIndex(t);
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('البقرة'), findsOneWidget);
    final icons = t.widgetList<RevelationIcon>(find.byType(RevelationIcon)).toList();
    expect(icons.first.meccan, isTrue); // al-Fātiḥa
    expect(icons[1].meccan, isFalse); // al-Baqara
    expect(find.textContaining('٢٨٦'), findsOneWidget); // al-Baqara's ayat
    expect(find.byIcon(Icons.bookmark_rounded), findsNothing); // no current page
    expect(t.takeException(), isNull);
  });

  testWidgets('the surah being read (page 586 → an-Nāziʿāt/ʿAbasa area) is marked and in view',
      (t) async {
    await pumpIndex(t, currentPage: 586);
    // page 586 opens inside ʿAbasa (80:41) — far down the list, yet visible
    expect(find.text('عبس'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    expect(find.text('الفاتحة'), findsNothing); // scrolled past the top
  });
}
