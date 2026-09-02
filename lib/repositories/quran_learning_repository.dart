import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/quran_learning.dart';
import '../services/quran_learning/knowledge_gateway.dart';

/// Phase 79 `79-ql` — read/write for the Quran Learning Layer above the
/// [KnowledgeGateway]. Concepts + lessons + the student's learning-path
/// state + the append-only [StudyEvent] log. No AI, no guessing.
class QuranLearningRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  /// True once the bundled knowledge is seeded.
  Future<bool> isReady() async {
    final db = await _db;
    final n = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM knowledge_facts')) ?? 0;
    return n > 0;
  }

  // ---- knowledge (via the gateway) --------------------------------------

  Future<KnowledgeResult> factsForWord(int surah, int ayah, int wordIndex) =>
      KnowledgeGateway.instance.factsFor(surah: surah, ayah: ayah, wordIndex: wordIndex);

  /// All facts for a whole ayah — the Ayah Knowledge Surface.
  Future<KnowledgeResult> factsForAyah(int surah, int ayah) =>
      KnowledgeGateway.instance.factsForAyah(surah: surah, ayah: ayah);

  /// Which learning domains have any verified fact for this word — for the
  /// launcher panel (order: naḥw first = P0, then ṣarf, tajwīd, tafsīr).
  Future<List<String>> availableDomainsOrdered(int surah, int ayah, int wordIndex) async {
    final have = await KnowledgeGateway.instance.availableDomains(surah, ayah, wordIndex);
    const order = ['nahw', 'sarf', 'tajweed', 'meaning', 'tafsir'];
    return [for (final d in order) if (have.contains(d)) d];
  }

  /// Every naḥw fact for an ayah, by word_index — the material for the
  /// interactive iʿrāb view.
  Future<List<KnowledgeFact>> irabForAyah(int surah, int ayah) async {
    final db = await _db;
    final rows = await db.query('knowledge_facts',
        where: "domain = 'nahw' AND surah = ? AND ayah = ?",
        whereArgs: [surah, ayah],
        orderBy: 'word_start ASC');
    return [for (final r in rows) KnowledgeFact.fromRow(r)];
  }

  Future<SourceReference?> source(String id) async {
    final db = await _db;
    final rows = await db.query('source_references', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : SourceReference.fromRow(rows.first);
  }

  // ---- concepts + lessons ---------------------------------------------

  Future<LearningConcept?> concept(String id) async {
    final db = await _db;
    final rows = await db.query('knowledge_concepts', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : LearningConcept.fromRow(rows.first);
  }

  Future<List<SourceReference>> conceptSources(LearningConcept c) async {
    if (c.sourceRefIds.isEmpty) return const [];
    final db = await _db;
    final rows = await db.query('source_references',
        where: 'id IN (${List.filled(c.sourceRefIds.length, '?').join(',')})',
        whereArgs: c.sourceRefIds);
    return [for (final r in rows) SourceReference.fromRow(r)];
  }

  // ---- learning-path state ------------------------------------------------

  String _now() => DateTime.now().toUtc().toIso8601String();

  /// Begin (or touch) learning [conceptId], originating from a mushaf spot.
  Future<int> startLearning({
    required String conceptId,
    required int surah,
    required int ayah,
    int? wordStart,
    int? wordEnd,
  }) async {
    final db = await _db;
    final existing = await db.query('learning_path_items',
        where: 'concept_id = ? AND origin_surah = ? AND origin_ayah = ?',
        whereArgs: [conceptId, surah, ayah],
        limit: 1);
    final now = _now();
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update('learning_path_items', {'last_touched_at': now},
          where: 'id = ?', whereArgs: [id]);
      return id;
    }
    return db.insert('learning_path_items', {
      'concept_id': conceptId,
      'origin_surah': surah,
      'origin_ayah': ayah,
      'origin_word_start': wordStart,
      'origin_word_end': wordEnd,
      'state': 'learning',
      'first_opened_at': now,
      'last_touched_at': now,
    });
  }

  Future<void> setLearningState(int id, String state) async {
    final db = await _db;
    await db.update('learning_path_items',
        {'state': state, 'last_touched_at': _now()}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LearningPathItem>> learningPath() async {
    final db = await _db;
    final rows = await db.query('learning_path_items', orderBy: 'last_touched_at DESC');
    return [for (final r in rows) LearningPathItem.fromRow(r)];
  }

  /// Learning-path items grouped by concept domain — the "ما تعلمته من
  /// القرآن" notebook view.
  Future<Map<String, List<({LearningPathItem item, LearningConcept concept})>>>
      learningPathByDomain() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT l.*, c.domain AS c_domain, c.title_ar AS c_title, c.short_def_ar AS c_def,
             c.blocks_json AS c_blocks, c.source_ref_ids_json AS c_srcs, c.status AS c_status
      FROM learning_path_items l JOIN knowledge_concepts c ON l.concept_id = c.id
      ORDER BY c.domain ASC, l.last_touched_at DESC
    ''');
    final out = <String, List<({LearningPathItem item, LearningConcept concept})>>{};
    for (final r in rows) {
      final item = LearningPathItem.fromRow(r);
      final concept = LearningConcept.fromRow({
        'id': r['concept_id'],
        'domain': r['c_domain'],
        'title_ar': r['c_title'],
        'short_def_ar': r['c_def'],
        'blocks_json': r['c_blocks'],
        'source_ref_ids_json': r['c_srcs'],
        'status': r['c_status'],
      });
      (out[concept.domain] ??= []).add((item: item, concept: concept));
    }
    return out;
  }

  // ---- study events (append-only) ------------------------------------

  Future<void> logEvent({
    required String verb,
    required String targetKind,
    required String targetId,
    int? surah,
    int? ayah,
    int? wordStart,
    String? layer,
    int? dwellMs,
    Map<String, Object?>? meta,
  }) async {
    if (!StudyEventVerbs.all.contains(verb)) return; // never a quiz verb
    final db = await _db;
    await db.insert('study_events', {
      'ts': _now(),
      'verb': verb,
      'target_kind': targetKind,
      'target_id': targetId,
      'surah': surah,
      'ayah': ayah,
      'word_start': wordStart,
      'layer': layer,
      'dwell_ms': dwellMs,
      'meta_json': meta == null ? null : jsonEncode(meta),
    });
  }

  Future<int> eventCount() async {
    final db = await _db;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM study_events')) ?? 0;
  }
}
