import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/akhlaq_repository.dart';
import 'package:talib_alilm_app/services/akhlaq/akhlaq_content.dart';

/// AKHLAQ — the store keeps only the student's training data; content is a
/// bundled asset. An attempt → SR advance → training indicator round-trip.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final repo = AkhlaqRepository();

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_akhlaq_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    // inject the الرفق slice (no rootBundle in a plain test)
    AkhlaqContent.instance.debugSetSlice(AkhlaqContent.parseJsonString(
        File('docs/akhlaq/alrifq/ar-rifq.json').readAsStringSync()));
    await DatabaseHelper.instance.database; // trigger v61 migration
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('akhlaq_attempt');
    await db.delete('akhlaq_sr_state');
    await db.delete('akhlaq_progress');
    await db.delete('akhlaq_meta');
  });

  test('ensureSrSeed creates one SR row per subskill, due today', () async {
    await repo.ensureSrSeed(now: DateTime(2026, 5, 1));
    final states = await repo.srStates();
    expect(states.length, 12);
    expect(states.every((s) => s.dueDate == '2026-05-01'), isTrue);
    expect(states.every((s) => s.track == 'S' && s.difficulty == 1), isTrue);
    // idempotent
    await repo.ensureSrSeed(now: DateTime(2026, 5, 1));
    expect((await repo.srStates()).length, 12);
  });

  test('recordAttempt: writes attempt, advances SR, computes the indicator',
      () async {
    final slice = (await repo.slice())!;
    final sc = slice.scenarioById('S-01')!; // subskills: rifq_ibara, rifq_taysir
    final aqrab = sc.options.firstWhere((o) => o.verdict == 'aqrab');

    final score = await repo.recordAttempt(
        scenario: sc, chosenKey: aqrab.key, now: DateTime(2026, 6, 1));
    expect(score.quality, 5);

    // one attempt row per subskill of the scenario
    expect((await repo.attempts()).length, 2);
    expect((await repo.attempts(subskill: 'rifq_ibara')).length, 1);

    final sr = (await repo.srStates())
        .firstWhere((s) => s.subskill == 'rifq_ibara');
    expect(sr.intervalDays, 2); // grew from 1
    expect(sr.track, 'R'); // S → R
    expect(sr.dueDate, '2026-06-03');

    final prog =
        (await repo.progressAll()).firstWhere((x) => x.subskill == 'rifq_ibara');
    expect(prog.attempts, 1);
    expect(prog.trend, greaterThan(0.9));
  });

  test('a run of poor choices → band "review", difficulty stays at 1',
      () async {
    final slice = (await repo.slice())!;
    final sc = slice.scenarioById('S-03')!; // rifq_jahil, difficulty 2
    final baid = sc.options.firstWhere((o) => o.verdict == 'baid');
    for (var i = 0; i < 5; i++) {
      await repo.recordAttempt(
          scenario: sc, chosenKey: baid.key, now: DateTime(2026, 7, 1 + i));
    }
    final prog = (await repo.progressAll())
        .firstWhere((x) => x.subskill == 'rifq_jahil');
    expect(prog.band, 'review');
    final sr =
        (await repo.srStates()).firstWhere((s) => s.subskill == 'rifq_jahil');
    expect(sr.difficulty, 1);
    expect(sr.intervalDays, 1); // poor answer keeps it short
  });

  test('todayPlan returns focus first then due items, capped at 3', () async {
    await repo.setFocusSubskill('rifq_hazm');
    final plan = await repo.todayPlan(now: DateTime(2026, 8, 1));
    expect(plan, isNotEmpty);
    expect(plan.first.subskill, 'rifq_hazm');
    expect(plan.length, lessThanOrEqualTo(3));
  });

  tearDownAll(() => AkhlaqContent.instance.debugSetSlice(null));
}
