import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../data/quran_surahs.dart';
import '../db/database_helper.dart';
import '../models/quran_learning.dart';

/// Outcome of a [QuranLearningSync] run.
class QuranLearningSyncResult {
  final String outcome; // seeded | up-to-date | rejected | skipped
  final bool changed;
  final QuranLearningValidation? validation;
  const QuranLearningSyncResult(this.outcome, {this.changed = false, this.validation});
  @override
  String toString() => 'QuranLearningSyncResult($outcome, changed=$changed, ${validation ?? "-"})';
}

/// Structural validation of a `prototype.json` payload, before any write.
class QuranLearningValidation {
  final int sources;
  final int concepts;
  final int facts;
  final int factsWithoutSource;
  final int factsWithBadAnchor;
  final int factsWithUndisplayableSource;
  final int conceptRefsMissing;
  final List<String> failures;
  const QuranLearningValidation({
    required this.sources,
    required this.concepts,
    required this.facts,
    required this.factsWithoutSource,
    required this.factsWithBadAnchor,
    required this.factsWithUndisplayableSource,
    required this.conceptRefsMissing,
    required this.failures,
  });
  bool get ok => failures.isEmpty;
  @override
  String toString() => 'QuranLearningValidation(sources=$sources, concepts=$concepts, facts=$facts, '
      'noSource=$factsWithoutSource, badAnchor=$factsWithBadAnchor, '
      'undisplayable=$factsWithUndisplayableSource, conceptRefsMissing=$conceptRefsMissing, ok=$ok'
      '${failures.isEmpty ? "" : ", failures=$failures"})';
}

/// Seeds the Quran Learning Layer's bundled knowledge (`knowledge_facts`,
/// `knowledge_concepts`, `source_references`) from
/// `assets/quran_learning/prototype.json` (phase `79-ql`). Wholesale rebuild
/// of the *bundled* rows in one transaction, after validation; user data
/// (`ayah_study_entries`, `learning_path_items`, `study_events`) is never
/// touched. External/online providers are a separate concern (the gateway).
class QuranLearningSync {
  static const _assetPath = 'assets/quran_learning/prototype.json';

  /// The usul-tafsir tree (USUL_TAFSIR_TREE.md U1, built by
  /// tool/build_usul_tree.py) — merged into the same wholesale seed, because
  /// `_ingest` rebuilds these tables whole: a separate seeder would be wiped.
  static const _usulAssetPath = 'assets/quran_learning/usul_tree.json';
  static const _seedVersionKey = 'seed_version';

  Future<QuranLearningSyncResult> sync() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final have = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM knowledge_facts'),
          ) ??
          0;
      final rows = await db.query('quran_learning_meta',
          where: 'key = ?', whereArgs: [_seedVersionKey], limit: 1);
      final storedVersion = rows.isEmpty ? null : int.tryParse(rows.first['value'] as String? ?? '');

      final payload = await _loadMerged();
      final version = (payload['version'] as num?)?.toInt() ?? 1;

      if (have > 0 && storedVersion == version) {
        return const QuranLearningSyncResult('up-to-date');
      }
      final v = validate(payload);
      if (!v.ok) {
        debugPrint('QuranLearningSync: prototype.json failed validation, not seeding. $v');
        return QuranLearningSyncResult('rejected', validation: v);
      }
      await _ingest(db, payload, version);
      debugPrint('QuranLearningSync: seeded. $v');
      return QuranLearningSyncResult('seeded', changed: true, validation: v);
    } catch (e) {
      debugPrint('QuranLearningSync: skipped ($e).');
      return const QuranLearningSyncResult('skipped');
    }
  }

  /// prototype.json + usul_tree.json as one payload. The version combines
  /// both (proto × 1000 + usul) so a change to either re-seeds.
  Future<Map<String, dynamic>> _loadMerged() async {
    Future<Map<String, dynamic>> read(String path) async {
      final bytes = await rootBundle.load(path);
      // MUST be utf8.decode — the JSON is full of Arabic; String.fromCharCodes
      // treats each byte as a code unit and mangles every multi-byte char.
      return jsonDecode(utf8.decode(bytes.buffer.asUint8List())) as Map<String, dynamic>;
    }

    final proto = await read(_assetPath);
    Map<String, dynamic>? usul;
    try {
      usul = await read(_usulAssetPath);
    } catch (_) {}
    return mergePayloads(proto, usul);
  }

  @visibleForTesting
  static Map<String, dynamic> mergePayloads(Map<String, dynamic> proto, Map<String, dynamic>? usul) {
    if (usul == null) return proto;
    List<dynamic> both(String k) => [...(proto[k] as List? ?? const []), ...(usul[k] as List? ?? const [])];
    return {
      ...proto,
      'version': ((proto['version'] as num?)?.toInt() ?? 1) * 1000 + ((usul['version'] as num?)?.toInt() ?? 1),
      'sources': both('sources'),
      'concepts': both('concepts'),
      'facts': both('facts'),
      'relations': both('relations'),
    };
  }

  /// Pure structural validation.
  QuranLearningValidation validate(Map<String, dynamic> payload) {
    final failures = <String>[];
    final srcList = (payload['sources'] as List? ?? const []).cast<Map<String, dynamic>>();
    final conceptList = (payload['concepts'] as List? ?? const []).cast<Map<String, dynamic>>();
    final factList = (payload['facts'] as List? ?? const []).cast<Map<String, dynamic>>();

    final srcById = {for (final s in srcList) s['id'] as String: SourceReference.fromJson(s)};
    final conceptIds = {for (final c in conceptList) c['id'] as String};
    final canon = {for (final s in quranSurahs) s.number: s.ayahCount};

    var noSource = 0, badAnchor = 0, undisplayable = 0;
    for (final f in factList) {
      final srcId = f['source_ref_id'] as String?;
      if (srcId == null || !srcById.containsKey(srcId)) {
        noSource++;
        continue;
      }
      final src = srcById[srcId]!;
      if (!src.displayable) undisplayable++;
      if (src.licenseUse != 'bundled_ok') {
        failures.add('fact ${f['id']} uses a non-bundleable source ($srcId / ${src.licenseUse})');
      }
      final a = (f['anchor'] as Map).cast<String, dynamic>();
      final s = (a['surah'] as num?)?.toInt() ?? 0;
      final ay = (a['ayah'] as num?)?.toInt() ?? 0;
      if (s < 1 || s > 114 || ay < 1 || ay > (canon[s] ?? 0)) badAnchor++;
      final ws = (a['word_start'] as num?)?.toInt();
      final we = (a['word_end'] as num?)?.toInt();
      if (ws != null && (we == null || ws < 1 || we < ws)) badAnchor++;
    }

    var conceptRefsMissing = 0;
    for (final f in factList) {
      final p = (f['payload'] as Map?)?.cast<String, dynamic>() ?? const {};
      final direct = p['concept_id'];
      if (direct is String && !conceptIds.contains(direct)) conceptRefsMissing++;
      final rules = p['rules'];
      if (rules is List) {
        for (final r in rules) {
          final rc = (r as Map)['concept_id'];
          if (rc is String && !conceptIds.contains(rc)) conceptRefsMissing++;
        }
      }
    }

    // Tree edges must join two known concepts — a dangling edge would draw a
    // branch to nowhere.
    for (final r in (payload['relations'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (!conceptIds.contains(r['from']) || !conceptIds.contains(r['to'])) {
        failures.add('relation ${r['from']} -> ${r['to']} joins an unknown concept');
      }
    }

    if (srcList.isEmpty) failures.add('no sources');
    if (factList.isEmpty) failures.add('no facts');
    if (noSource != 0) failures.add('facts without a resolvable source=$noSource');
    if (badAnchor != 0) failures.add('facts with a bad anchor=$badAnchor');
    if (undisplayable != 0) failures.add('facts backed by an undisplayable source=$undisplayable');
    // conceptRefsMissing is a warning, not a hard failure (stub concepts allowed)

    return QuranLearningValidation(
      sources: srcList.length,
      concepts: conceptList.length,
      facts: factList.length,
      factsWithoutSource: noSource,
      factsWithBadAnchor: badAnchor,
      factsWithUndisplayableSource: undisplayable,
      conceptRefsMissing: conceptRefsMissing,
      failures: failures,
    );
  }

  @visibleForTesting
  Future<QuranLearningSyncResult> ingestFromJson(Map<String, dynamic> payload) async {
    final db = await DatabaseHelper.instance.database;
    final v = validate(payload);
    if (!v.ok) return QuranLearningSyncResult('rejected', validation: v);
    await _ingest(db, payload, (payload['version'] as num?)?.toInt() ?? 1);
    return QuranLearningSyncResult('seeded', changed: true, validation: v);
  }

  Future<void> _ingest(Database db, Map<String, dynamic> payload, int version) async {
    final srcList = (payload['sources'] as List).cast<Map<String, dynamic>>();
    final conceptList = (payload['concepts'] as List).cast<Map<String, dynamic>>();
    final factList = (payload['facts'] as List).cast<Map<String, dynamic>>();

    await db.transaction((txn) async {
      for (final t in const ['knowledge_facts', 'knowledge_concepts', 'source_references', 'knowledge_relations']) {
        await txn.delete(t);
      }
      final batch = txn.batch();
      for (final s in srcList) {
        batch.insert('source_references', SourceReference.fromJson(s).toRow());
      }
      for (final c in conceptList) {
        batch.insert('knowledge_concepts', LearningConcept.fromJson(c).toRow());
      }
      for (final f in factList) {
        batch.insert('knowledge_facts', KnowledgeFact.fromJson(f).toRow());
      }
      for (final r in (payload['relations'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        batch.insert('knowledge_relations', {
          'from_concept': r['from'],
          'rel': r['rel'],
          'to_concept': r['to'],
          'ord': r['ord'] ?? 0,
          'source_ref_id': r['source_ref_id'],
        });
      }
      await batch.commit(noResult: true);

      final srcRows = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM source_references'));
      final factRows = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM knowledge_facts'));
      final orphan = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COUNT(*) FROM knowledge_facts f LEFT JOIN source_references s ON f.source_ref_id = s.id WHERE s.id IS NULL'));
      if (srcRows != srcList.length || factRows != factList.length || orphan != 0) {
        throw StateError('post-insert cross-check failed: srcRows=$srcRows factRows=$factRows orphan=$orphan');
      }

      await txn.insert('quran_learning_meta', {'key': _seedVersionKey, 'value': '$version'},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('quran_learning_meta',
          {'key': 'seeded_at_ms', 'value': '${DateTime.now().millisecondsSinceEpoch}'},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('quran_learning_meta',
          {'key': 'scope', 'value': payload['scope'] as String? ?? 'prototype'},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }
}
