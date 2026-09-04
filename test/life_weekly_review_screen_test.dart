import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/life_plan_repository.dart';
import 'package:talib_alilm_app/screens/life_weekly_review_screen.dart';

/// «مُحرّك الحياة» L5 — the «ملخص الأسبوع» screen must actually paint its
/// body. A regression guard: the first cut rendered a blank body because a
/// `CrossAxisAlignment.stretch` Row (and bare Columns) sat in a ListView's
/// unbounded-height context. This test fails if the body doesn't lay out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_life_week_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await LifePlanRepository().ensureSeeded();
  });

  testWidgets('renders the week summary body (no blank / no overflow)',
      (t) async {
    await t.pumpWidget(const MaterialApp(home: LifeWeeklyReviewScreen()));
    // weeklyReview() is query-heavy (pillar trend + streak + day percents);
    // give the fake-async loop plenty of real time to drain the DB calls.
    for (var i = 0; i < 120; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
      await t.pump();
    }

    // the body actually painted (regression: it was blank) — title +
    // the computed headline + the momentum section are all on screen
    expect(find.text('ملخّص الأسبوع'), findsOneWidget);
    expect(find.text('إنجاز الأسبوع'), findsOneWidget);
    expect(find.text('زخم المحاور (آخر 7 أيام)'), findsOneWidget);
    // a pillar row rendered
    expect(find.text('القرآن الكريم'), findsWidgets);
    // the notes section + its empty state (below the fold — build it)
    expect(find.text('ملاحظات الأسبوع', skipOffstage: false), findsOneWidget);
    expect(find.text('لا ملاحظات هذا الأسبوع بعد', skipOffstage: false),
        findsOneWidget);
    // no RenderFlex overflow / layout error while building the body
    expect(t.takeException(), isNull);
  });
}
