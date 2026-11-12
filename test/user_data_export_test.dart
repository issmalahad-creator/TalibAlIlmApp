import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/data_export_tables.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/services/user_data_export_service.dart';

/// «النسخة الاحتياطية»:
///  1. every table a fresh install has is classified (user-owned vs seeded);
///  2. export → mess up → import round-trips the user data and preferences,
///     and leaves seeded content and internal markers alone;
///  3. bad files are refused without touching anything.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Database db;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_backup_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    db = await DatabaseHelper.instance.database;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    for (final t in kUserOwnedTables) {
      await db.delete(t);
    }
    await db.delete('quran_ayat');
  });

  test('every table on a fresh install is classified exactly once', () async {
    final actual = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    ))
        .map((r) => r['name'] as String)
        .toSet();
    final classified = {...kUserOwnedTables, ...kSeededOrCacheTables, ...kLegacyUnusedTables};
    expect(actual.difference(classified), isEmpty,
        reason: 'new table(s) not in data_export_tables.dart — classify each as user-owned or seeded/cache');
    expect(classified.difference(actual).difference(kMigrationOnlyTables), isEmpty,
        reason: 'classified table(s) a fresh install does not build (typo? renamed?)');
    expect(kUserOwnedTables.intersection(kSeededOrCacheTables), isEmpty);
  });

  test('export holds user tables and chosen prefs only — never seeded content or internal markers', () async {
    SharedPreferences.setMockInitialValues({
      'app_ui_language': 'en',
      'hifz_schedule_plan_v1': '{"q":7}',
      'adhkar_notif_morning_enabled': false,
      'seed_version': 9,
      'packs_installed': ['tafsir.x'],
    });
    await db.insert('profile', {'id': 1, 'full_name': 'اسماعيل'});
    await db.insert('quran_ayat', {'surah': 1, 'ayah': 1, 'text_uthmani': 'بسم الله', 'text_normalized': 'بسم الله'});

    final map = await UserDataExportService().exportToMap();
    expect(map['format'], 'talibalilm-backup');
    expect(map['schema_version'], DatabaseHelper.schemaVersion);
    final tables = (map['tables'] as Map).cast<String, Object?>();
    expect(tables.containsKey('quran_ayat'), isFalse, reason: 'seeded content must never be in a backup');
    expect((tables['profile'] as List).single['full_name'], 'اسماعيل');
    final prefs = (map['prefs'] as Map).cast<String, Object?>();
    expect(prefs.keys.toSet(), {'app_ui_language', 'hifz_schedule_plan_v1', 'adhkar_notif_morning_enabled'});
    expect(() => jsonEncode(map), returnsNormally);
  });

  test('round-trip restores tables and prefs exactly; seeded content untouched', () async {
    SharedPreferences.setMockInitialValues({'app_ui_language': 'fr', 'drawer_pinned': ['medications', 'qibla']});
    await db.insert('profile', {'id': 1, 'full_name': 'اسماعيل', 'residence': 'صنعاء'});
    await db.insert('daily_tasks', {'title': 'مراجعة', 'date': '1447-03-01', 'completed': 0});
    await db.insert('memorization_progress', {'unit_id': 1, 'station': 3, 'next_review_date': '1447-03-05'});
    // the four tables the first version of this backup wrongly skipped
    await db.insert('activities', {'category': 'lesson', 'date': '1447-03', 'title': 'درس الفقه'});
    await db.insert('goals', {'title': 'ختمة', 'target': 30, 'current': 12, 'month': '1447-03'});
    await db.insert('med_courses', {
      'name': 'Amoxicillin', 'mode': 'interval', 'interval_hours': 8, 'duration_days': 7,
      'start_at': 0, 'created_at': 0,
    });
    await db.insert('quran_ayat', {'surah': 2, 'ayah': 255, 'text_uthmani': 'الله', 'text_normalized': 'الله'});

    final svc = UserDataExportService();
    final backup = await svc.exportToJson();
    expect(await UserDataExportService.lastExportAt(), isNotNull);

    // the person makes a mess (or it is a new phone), then restores
    await db.delete('profile');
    await db.insert('profile', {'id': 1, 'full_name': 'WRONG'});
    await db.insert('daily_tasks', {'title': 'junk', 'date': 'x', 'completed': 0});
    await db.delete('memorization_progress');
    await db.delete('goals');
    await db.delete('med_courses');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_ui_language', 'ar');
    await prefs.remove('drawer_pinned');

    final res = await svc.importFromJson(backup);
    expect(res.ok, isTrue, reason: res.error?.toString());

    expect((await db.query('profile')).single['residence'], 'صنعاء');
    expect((await db.query('daily_tasks')).map((r) => r['title']), ['مراجعة']);
    expect((await db.query('memorization_progress')).single['station'], 3);
    expect((await db.query('activities')).single['title'], 'درس الفقه');
    expect((await db.query('goals')).single['current'], 12);
    expect((await db.query('med_courses')).single['name'], 'Amoxicillin');
    expect((await db.query('quran_ayat')).length, 1);
    expect(prefs.getString('app_ui_language'), 'fr');
    expect(prefs.getStringList('drawer_pinned'), ['medications', 'qibla']);

    final summary = UserDataExportService.summarize((jsonDecode(backup) as Map).cast<String, Object?>());
    expect(summary.tasks, 1);
    expect(summary.medicines, 1);
    expect(summary.exportedAt, isNotNull);
  });

  test('bad files are refused and change nothing', () async {
    await db.insert('daily_tasks', {'title': 'keep me', 'date': 'x', 'completed': 0});
    final svc = UserDataExportService();
    expect((await svc.importFromJson('not json')).error, ImportError.notJson);
    expect((await svc.importFromJson('{}')).error, ImportError.notBackup);
    expect((await svc.importFromJson(jsonEncode({'format': 'talibalilm-backup', 'version': 99, 'tables': {}}))).error,
        ImportError.unsupportedVersion);
    expect(
        (await svc.importFromJson(
                jsonEncode({'format': 'talibalilm-backup', 'version': 2, 'schema_version': 99999, 'tables': {}})))
            .error,
        ImportError.newerApp);
    expect((await db.query('daily_tasks')).single['title'], 'keep me');
  });

  test('a version-1 file (no prefs, older schema) still restores', () async {
    final res = await UserDataExportService().importFromJson(jsonEncode({
      'format': 'talibalilm-backup',
      'version': 1,
      'schema_version': 60,
      'tables': {
        'daily_tasks': [
          {'title': 'old', 'date': 'x', 'completed': 1, 'column_removed_since': 'ignored'},
        ],
      },
    }));
    expect(res.ok, isTrue);
    expect((await db.query('daily_tasks')).single['title'], 'old');
  });
}
