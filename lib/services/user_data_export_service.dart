import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../db/data_export_tables.dart';
import '../db/database_helper.dart';

/// «النسخة الاحتياطية» — a versioned JSON file of the person's own data:
/// every [kUserOwnedTables] table plus the [isBackupPrefKey] preferences.
/// Bundled content (Quran, tafsir, corpus, mushaf geometry, catalogs,
/// seeded texts) is not in the file; a fresh install seeds it as usual.
///
/// A restore **replaces** the user data with the file's (a restore, not a
/// merge), in one transaction — a broken file changes nothing. Columns are
/// matched by name, so a file from an older app version restores into a
/// newer schema; a file from a newer app is refused.
///
/// Revived from the unmerged `stabilization/m3-user-data-export` branch
/// (2026-09-06) onto schema v73, adding the preferences and fixing four
/// live tables that branch had wrongly treated as unused.
class UserDataExportService {
  static const formatId = 'talibalilm-backup';
  static const formatVersion = 2;

  /// When the last export was made — shown on the backup screen. Not itself
  /// part of any backup.
  static const lastExportKey = 'backup_last_export_at';

  /// Test seam: when set, used instead of the real singleton DB.
  final Database? testDatabase;

  UserDataExportService({this.testDatabase});

  Future<Database> get _database async => testDatabase ?? await DatabaseHelper.instance.database;

  /// The full backup as a plain map (ready for `jsonEncode`).
  Future<Map<String, Object?>> exportToMap() async {
    final db = await _database;
    final tables = <String, Object?>{};
    for (final t in kUserOwnedTables.toList()..sort()) {
      tables[t] = await db.query(t);
    }
    final prefs = await SharedPreferences.getInstance();
    final prefMap = <String, Object?>{
      for (final k in prefs.getKeys().where(isBackupPrefKey).toList()..sort()) k: prefs.get(k),
    };
    return {
      'format': formatId,
      'version': formatVersion,
      'schema_version': DatabaseHelper.schemaVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'tables': tables,
      'prefs': prefMap,
    };
  }

  /// The backup as JSON, and the export time remembered for the screen.
  Future<String> exportToJson() async {
    final json = jsonEncode(await exportToMap());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastExportKey, DateTime.now().toIso8601String());
    return json;
  }

  static Future<DateTime?> lastExportAt() async {
    final raw = (await SharedPreferences.getInstance()).getString(lastExportKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Restore from [json]. Destructive: every [kUserOwnedTables] table is
  /// cleared and refilled from the file, and the file's preferences are set.
  Future<ImportResult> importFromJson(String json) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      return ImportResult.fail(ImportError.notJson);
    }
    if (decoded is! Map) return ImportResult.fail(ImportError.notBackup);
    return importFromMap(decoded.cast<String, Object?>());
  }

  Future<ImportResult> importFromMap(Map<String, Object?> data) async {
    if (data['format'] != formatId) return ImportResult.fail(ImportError.notBackup);
    final v = data['version'];
    if (v is! int || v > formatVersion) return ImportResult.fail(ImportError.unsupportedVersion);
    final sv = data['schema_version'];
    if (sv is int && sv > DatabaseHelper.schemaVersion) return ImportResult.fail(ImportError.newerApp);
    final tables = data['tables'];
    if (tables is! Map) return ImportResult.fail(ImportError.notBackup);

    final db = await _database;
    var rows = 0;
    var restored = 0;
    final skippedTables = <String>[];

    await db.transaction((txn) async {
      for (final t in kUserOwnedTables) {
        await txn.delete(t);
      }
      for (final entry in tables.cast<String, Object?>().entries) {
        final table = entry.key;
        if (!kUserOwnedTables.contains(table)) {
          skippedTables.add(table); // an unknown / non-user table in the file
          continue;
        }
        final list = (entry.value as List?) ?? const [];
        if (list.isEmpty) continue;
        final cols = await _columnsOf(txn, table);
        final batch = txn.batch();
        for (final raw in list) {
          if (raw is! Map) continue;
          final row = <String, Object?>{
            for (final e in raw.cast<String, Object?>().entries)
              if (cols.contains(e.key)) e.key: e.value,
          };
          if (row.isEmpty) continue;
          batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
          rows++;
        }
        await batch.commit(noResult: true);
        restored++;
      }
    });

    // Preferences after the database: a failed transaction above leaves both
    // untouched. Version-1 files (the old branch) have none — that is fine.
    final prefMap = data['prefs'];
    if (prefMap is Map) {
      final prefs = await SharedPreferences.getInstance();
      for (final e in prefMap.cast<String, Object?>().entries) {
        if (!isBackupPrefKey(e.key)) continue;
        final value = e.value;
        switch (value) {
          case bool b:
            await prefs.setBool(e.key, b);
          case int i:
            await prefs.setInt(e.key, i);
          case double d:
            await prefs.setDouble(e.key, d);
          case String s:
            await prefs.setString(e.key, s);
          case List l:
            await prefs.setStringList(e.key, l.map((x) => '$x').toList());
        }
      }
    }

    return ImportResult.ok(tablesRestored: restored, rowsRestored: rows, unknownTablesInFile: skippedTables);
  }

  /// What a backup holds, in the person's words — shown before a restore so
  /// they see whose data they are about to bring back.
  static BackupSummary summarize(Map<String, Object?> data) {
    int count(String t) => ((data['tables'] as Map?)?[t] as List?)?.length ?? 0;
    return BackupSummary(
      exportedAt: DateTime.tryParse('${data['exported_at']}')?.toLocal(),
      memorized: count('hifz_surah_status') + count('memorization_progress'),
      notes: count('ayah_study_entries') + count('turath_notes') + count('turath_annotations'),
      tasks: count('daily_tasks') + count('life_tasks'),
      medicines: count('med_courses'),
      totalRows: ((data['tables'] as Map?)?.values ?? const []).fold<int>(0, (s, l) => s + ((l as List?)?.length ?? 0)),
    );
  }

  Future<Set<String>> _columnsOf(DatabaseExecutor txn, String table) async {
    final info = await txn.rawQuery('PRAGMA table_info("$table")');
    return {for (final c in info) c['name'] as String};
  }
}

class BackupSummary {
  final DateTime? exportedAt;
  final int memorized;
  final int notes;
  final int tasks;
  final int medicines;
  final int totalRows;
  const BackupSummary({this.exportedAt, required this.memorized, required this.notes, required this.tasks, required this.medicines, required this.totalRows});
}

enum ImportError { notJson, notBackup, unsupportedVersion, newerApp }

class ImportResult {
  final bool ok;
  final ImportError? error;
  final int tablesRestored;
  final int rowsRestored;
  final List<String> unknownTablesInFile;

  const ImportResult._({
    required this.ok,
    this.error,
    this.tablesRestored = 0,
    this.rowsRestored = 0,
    this.unknownTablesInFile = const [],
  });

  factory ImportResult.ok({required int tablesRestored, required int rowsRestored, List<String> unknownTablesInFile = const []}) =>
      ImportResult._(ok: true, tablesRestored: tablesRestored, rowsRestored: rowsRestored, unknownTablesInFile: unknownTablesInFile);

  factory ImportResult.fail(ImportError error) => ImportResult._(ok: false, error: error);
}
