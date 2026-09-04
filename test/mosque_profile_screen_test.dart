import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/mosque_repository.dart';
import 'package:talib_alilm_app/screens/mosque/mosque_profile_screen.dart';
import 'package:talib_alilm_app/services/mosque/mosque_api_client.dart';

/// «مساجدنا» — the profile screen must actually paint the whole page: the
/// header, the 📸 gallery strip (previously fetched but never rendered),
/// per-section previews, and the services grid. `MosqueProfileScreen`
/// always builds its own backend-configured `MosqueRepository`, so this
/// seeds the shared local DB via a `LocalOnlyMosqueApi`-backed repo first
/// (same tables, different façade) — the screen's own repo then falls back
/// to that cache once its network sync fails in the test sandbox.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late String mosqueId;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({}); // PrayerTimesRepository reads prefs
    DatabaseHelper.databaseName = 'talib_mosque_profile_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    final seedRepo = MosqueRepository(api: const LocalOnlyMosqueApi());
    final mosques = await seedRepo.allMosques(); // seeds the demo mosque
    mosqueId = mosques.single.id;
  });

  testWidgets('renders header, gallery strip, sections and services grid',
      (t) async {
    await t.pumpWidget(
        MaterialApp(home: MosqueProfileScreen(mosqueId: mosqueId)));
    for (var i = 0; i < 60; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await t.pump();
    }

    expect(find.textContaining('مسجد'), findsWidgets); // header name
    expect(find.text('الصور'), findsOneWidget); // 📸 gallery section title
    expect(find.textContaining('الصلاة القادمة'), findsOneWidget); // 🕌 prayer card

    // the services grid sits below 7 section previews — well past the
    // default test viewport + the sliver's cache extent, so its Elements
    // aren't mounted yet; scroll it into view like a real user would.
    await t.scrollUntilVisible(
      find.text('خدمات المسجد'),
      600,
      // the page's own ListView, not the gallery strip's nested horizontal one
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('خدمات المسجد'), findsOneWidget);
    // no RenderFlex overflow / layout error while building the page
    expect(t.takeException(), isNull);
  });
}
