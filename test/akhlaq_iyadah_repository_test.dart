import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/akhlaq_repository.dart';
import 'package:talib_alilm_app/services/akhlaq/akhlaq_content.dart';

/// AKHLAQ — proves a second slice (عيادة المريض) works through
/// `AkhlaqRepository` exactly like الرفق, AND that the two slices
/// coexist in the same `akhlaq_*` tables without interfering: subskill
/// slugs are namespaced (`rifq_*` vs `iy_*`), and "focus of the week" is
/// now scoped per `sliceId`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final rifq = AkhlaqRepository(); // defaults to al-rifq
  final iyadah = AkhlaqRepository(sliceId: 'iyadat-almarid');

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_akhlaq_iyadah_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    AkhlaqContent.instance.debugSetSlice(
        AkhlaqContent.parseJsonString(
            File('docs/akhlaq/alrifq/ar-rifq.json').readAsStringSync()),
        'al-rifq');
    AkhlaqContent.instance.debugSetSlice(
        AkhlaqContent.parseJsonString(File(
                'docs/akhlaq/adab_book/ar-iyadah.json')
            .readAsStringSync()),
        'iyadat-almarid');
    await DatabaseHelper.instance.database;
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('akhlaq_attempt');
    await db.delete('akhlaq_sr_state');
    await db.delete('akhlaq_progress');
    await db.delete('akhlaq_meta');
  });

  test('the iyadah slice loads through its own repository', () async {
    final slice = await iyadah.slice();
    expect(slice, isNotNull);
    expect(slice!.slice, 'iyadat-almarid');
    expect(slice.subskills.length, 7);
  });

  test('recordAttempt on iyadah: writes attempt, advances SR, no score',
      () async {
    final slice = (await iyadah.slice())!;
    final sc = slice.scenarioById('S-IY-01')!; // subskills: iy_julus, iy_hiyah
    final aqrab = sc.options.firstWhere((o) => o.verdict == 'aqrab');

    final score = await iyadah.recordAttempt(
        scenario: sc, chosenKey: aqrab.key, now: DateTime(2026, 6, 1));
    expect(score.quality, 5);

    expect((await iyadah.attempts()).length, 2); // 2 subskills on S-IY-01
    final sr =
        (await iyadah.srStates()).firstWhere((s) => s.subskill == 'iy_julus');
    expect(sr.track, 'R'); // S → R, same engine as الرفق
  });

  test('the two slices do not interfere in the shared akhlaq_* tables',
      () async {
    await rifq.ensureSrSeed(now: DateTime(2026, 5, 1));
    await iyadah.ensureSrSeed(now: DateTime(2026, 5, 1));

    final rifqStates = await rifq.srStates();
    final iyadahStates = await iyadah.srStates();
    expect(rifqStates.length, 12); // الرفق's 12 subskills
    expect(iyadahStates.length, 7); // عيادة المريض's 7 subskills
    expect(rifqStates.every((s) => s.subskill.startsWith('rifq_')), isTrue);
    expect(iyadahStates.every((s) => s.subskill.startsWith('iy_')), isTrue);
  });

  test('"focus of the week" is scoped per slice, not shared', () async {
    await rifq.setFocusSubskill('rifq_hazm');
    await iyadah.setFocusSubskill('iy_ruqyah');
    expect(await rifq.focusSubskill(), 'rifq_hazm');
    expect(await iyadah.focusSubskill(), 'iy_ruqyah');
  });

  tearDownAll(() {
    AkhlaqContent.instance.debugSetSlice(null, 'al-rifq');
    AkhlaqContent.instance.debugSetSlice(null, 'iyadat-almarid');
  });
}
