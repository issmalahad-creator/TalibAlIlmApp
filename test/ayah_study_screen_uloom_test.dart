import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';
import 'package:talib_alilm_app/screens/ayah_study_screen.dart';

/// The "العلوم المرتبطة" family on `AyahStudyScreen` — the actual fix for
/// Ismail's bug report: «توسّع في صفحة الآية» from the uloom tab used to
/// land on a screen with zero awareness of أسباب النزول / إعراب / ناسخ /
/// غريب / فوائد / متشابهات / أقوال. Real seeded data only — no mocks.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_ayah_study_uloom_test.db';
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

  // sqflite_common_ffi's real disk I/O doesn't resolve under
  // `pumpAndSettle`'s fake clock — same fix as `corpus_panels_test.dart`'s
  // `pumpPanel`: interleave real waits (`runAsync`) with `pump()` so each
  // `setState` in the load chain actually reaches a frame.
  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(MaterialApp(home: screen));
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump();
    }
  }

  testWidgets('opens straight into العلوم when initialFamily is uloom',
      (tester) async {
    await pumpScreen(
        tester, const AyahStudyScreen(surah: 112, ayah: 1, initialFamily: AyahStudyFamily.uloom));
    expect(find.text(basicText('ql_related_sciences', 'ar')), findsWidgets);
    // Both asbāb books for 112:1 are real, distinct entries — never merged.
    expect(find.text('أسباب نزول القرآن - الواحدي'), findsOneWidget);
    expect(
        find.text('المحرر في أسباب نزول القرآن من خلال الكتب التسعة'),
        findsOneWidget);
  });

  testWidgets('tapping a card opens the full untruncated text, "كل المصادر" returns',
      (tester) async {
    await pumpScreen(
        tester, const AyahStudyScreen(surah: 112, ayah: 1, initialFamily: AyahStudyFamily.uloom));
    await tester.tap(find.text('أسباب نزول القرآن - الواحدي'));
    await tester.pump();
    // The reader shows real prose, long enough that it could never have
    // been the ~200-char quick-card excerpt.
    final bodyFinder = find.byWidgetPredicate(
      (w) => w is Text && w.textDirection == TextDirection.rtl && (w.data?.length ?? 0) > 250,
    );
    expect(bodyFinder, findsWidgets);

    await tester.tap(find.text(basicText('all_sources_action', 'ar')));
    await tester.pump();
    expect(find.text('أسباب نزول القرآن - الواحدي'), findsOneWidget);
  });

  testWidgets('2:255 — no card for asbab, but says the surah has other documented places',
      (tester) async {
    await pumpScreen(
        tester, const AyahStudyScreen(surah: 2, ayah: 255, initialFamily: AyahStudyFamily.uloom));
    expect(find.text(basicText('ql_asbab_not_for_ayah', 'ar')), findsOneWidget);
    expect(find.text(basicText('ql_asbab_not_for_surah', 'ar')), findsNothing);
  });

  testWidgets('26:1 — surah 26 has no أسباب النزول documented anywhere in it',
      (tester) async {
    await pumpScreen(
        tester, const AyahStudyScreen(surah: 26, ayah: 1, initialFamily: AyahStudyFamily.uloom));
    expect(find.text(basicText('ql_asbab_not_for_surah', 'ar')), findsOneWidget);
    expect(find.text(basicText('ql_asbab_not_for_ayah', 'ar')), findsNothing);
  });

  testWidgets('switching families works both ways, no initialFamily defaults to تفسير وترجمة',
      (tester) async {
    await pumpScreen(tester, const AyahStudyScreen(surah: 112, ayah: 1));
    // Defaults to تفسير وترجمة when no initialFamily is given.
    expect(find.text(basicText('ql_family_tafsir_translation', 'ar')), findsWidgets);
    expect(find.text('أسباب نزول القرآن - الواحدي'), findsNothing);

    await tester.tap(find.text(basicText('ql_related_sciences', 'ar')));
    await tester.pump();
    expect(find.text('أسباب نزول القرآن - الواحدي'), findsOneWidget);

    await tester.tap(find.text(basicText('ql_family_tafsir_translation', 'ar')));
    await tester.pump();
    expect(find.text('أسباب نزول القرآن - الواحدي'), findsNothing);
  });
}
