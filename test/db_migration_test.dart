import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';

/// M2 (Stabilization) — proves that a **fresh install** (`onCreate`) ends up
/// with the same schema as an **upgraded install**
/// (`v1 → onUpgrade → schemaVersion`).
///
/// `lib/db/database_helper.dart` is one 2,200-LOC file with ~60 tables and a
/// 74-step migration ladder. `onCreate` runs `_createV1..V74`; `onUpgrade`
/// runs `_createV2..V74` plus a few data-only steps. If any migration step
/// ever forgets to mirror what `onCreate` builds — or `onCreate` drifts from
/// the ladder — this test fails, in CI, instead of a user's device hitting a
/// missing column. Every DB-version bump must keep this green.
typedef _TableSchema = ({Map<String, String> columns, Set<String> indexes});

Future<Map<String, _TableSchema>> _schemaOf(Database db) async {
  final tables = (await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata' ORDER BY name",
  ))
      .map((r) => r['name'] as String)
      .toList();

  final out = <String, _TableSchema>{};
  for (final t in tables) {
    final columns = <String, String>{};
    for (final c in await db.rawQuery('PRAGMA table_info("$t")')) {
      columns[c['name'] as String] = 'type=${c['type']} '
          'notnull=${c['notnull']} dflt=${c['dflt_value']} pk=${c['pk']}';
    }
    final indexes = <String>{};
    for (final i in await db.rawQuery('PRAGMA index_list("$t")')) {
      final name = i['name'] as String;
      final cols = (await db.rawQuery('PRAGMA index_info("$name")'))
          .map((r) => r['name'])
          .join(',');
      // autoindexes (implicit PK/UNIQUE) are named by rowid position, which
      // is not stable to compare — key them by (columns, unique) instead.
      final key = name.startsWith('sqlite_autoindex_')
          ? 'auto($cols) unique=${i['unique']} origin=${i['origin']}'
          : '$name($cols) unique=${i['unique']}';
      indexes.add(key);
    }
    out[t] = (columns: columns, indexes: indexes);
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // some steps read bundled assets
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final helper = DatabaseHelper.instance;

  /// Tables that exist ONLY on the upgrade path: created by an early
  /// `_createVN`, never dropped (migrations are additive-only), but removed
  /// from `onCreate` when their feature was deleted. A fresh install lacks
  /// them; an upgraded install keeps them. Known and accepted — a *new*
  /// entry showing up here is a real regression to investigate.
  const knownMigrationOnlyTables = <String>{
    // Report feature removed in Phase -1 (commit d1de6ab).
    'report_drafts',
    'submission_queue',
  };

  var seq = 0;

  /// A brand-new database file per call — a unique name so the FFI factory
  /// never reuses a connection from a previous test run (which left
  /// `table profile already exists` on the second run).
  Future<Database> open(String tag) async {
    final dir = Directory(
        p.join('.dart_tool', 'sqflite_common_ffi', 'databases'))
      ..createSync(recursive: true);
    final path = p.join(dir.path,
        'mig_${DateTime.now().microsecondsSinceEpoch}_${seq++}_$tag.db');
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
  }

  test('schemaVersion matches the openDatabase(version:) constant', () {
    expect(DatabaseHelper.schemaVersion, 74);
  });

  test('fresh onCreate schema == v1 -> onUpgrade -> schemaVersion', () async {
    final f = await open('fresh');
    await helper.onCreateForTest(f);
    final fresh = await _schemaOf(f);
    await f.close();

    final m = await open('migrated');
    await helper.createV1ForTest(m);
    await helper.onUpgradeForTest(m, 1, DatabaseHelper.schemaVersion);
    final migrated = await _schemaOf(m);
    await m.close();

    final problems = <String>[];

    for (final entry in fresh.entries) {
      final name = entry.key;
      final mig = migrated[name];
      if (mig == null) {
        problems.add('MISSING on upgrade path: table "$name" is created by '
            'onCreate but no migration step creates it');
        continue;
      }
      for (final col in entry.value.columns.entries) {
        final mv = mig.columns[col.key];
        if (mv == null) {
          problems.add('"$name".${col.key}: on fresh only');
        } else if (mv != col.value) {
          problems.add('"$name".${col.key}: fresh[${col.value}] != migrated[$mv]');
        }
      }
      for (final col in mig.columns.keys) {
        if (!entry.value.columns.containsKey(col)) {
          problems.add('"$name".$col: on migrated only');
        }
      }
      final onlyFresh = entry.value.indexes.difference(mig.indexes);
      final onlyMig = mig.indexes.difference(entry.value.indexes);
      if (onlyFresh.isNotEmpty) {
        problems.add('"$name" indexes on fresh only: $onlyFresh');
      }
      if (onlyMig.isNotEmpty) {
        problems.add('"$name" indexes on migrated only: $onlyMig');
      }
    }

    final extraTables = migrated.keys.toSet()
      ..removeAll(fresh.keys)
      ..removeAll(knownMigrationOnlyTables);
    if (extraTables.isNotEmpty) {
      problems.add('migration path creates tables onCreate does not, and they '
          'are not in knownMigrationOnlyTables: $extraTables');
    }

    expect(problems, isEmpty,
        reason: 'fresh vs migrated schema divergence:\n${problems.join('\n')}');
  });

  test('re-running onUpgrade at schemaVersion is a safe no-op', () async {
    final db = await open('noop');
    await helper.createV1ForTest(db);
    await helper.onUpgradeForTest(db, 1, DatabaseHelper.schemaVersion);
    // Simulates an app relaunch with no version change.
    await helper.onUpgradeForTest(
        db, DatabaseHelper.schemaVersion, DatabaseHelper.schemaVersion);
    await db.close();
  });
}
