import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

/// Phase 80 / QC2 — read access to the seeded **Quran Corpus**
/// (`quran_corpus_*`, migration v54). Every method addresses the canonical
/// Hafs spine `(surah, ayah)`; nothing here knows a foreign word index.
///
/// The bulky tafsīr / translation / riwāya *text* is not here — that is
/// `QuranBookRepository` (per-book gz assets, on demand). This repo serves
/// the small per-ayah layers + the catalogs.
class QuranCorpusRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<Object?> _json(String table, int surah, int ayah) async {
    final db = await _db;
    final rows = await db.query(table,
        columns: ['data'],
        where: 'surah = ? AND ayah = ?',
        whereArgs: [surah, ayah],
        limit: 1);
    if (rows.isEmpty) return null;
    try {
      return jsonDecode(rows.first['data'] as String);
    } catch (_) {
      return null;
    }
  }

  /// ṣarf — Quranic Arabic Corpus per-word segments for the ayah, or null.
  /// `{source, words:[{number, text, root, lemma, segments:[…]}]}` where
  /// `number` is the **QAC** word position — use [qacWordFor] to map a
  /// mushaf `word_index` onto it.
  Future<Object?> morphology(int surah, int ayah) =>
      _json('quran_morphology', surah, ayah);

  /// The QAC word number our `mushaf_words.word_index` maps to for this ayah
  /// (VT-3 `align_qac`), or null if unaligned (≈40 flagged ayat).
  Future<int?> qacWordFor(int surah, int ayah, int wordIndex) async {
    final m = await _json('quran_align', surah, ayah);
    if (m is Map) {
      final v = m['$wordIndex'] ?? m[wordIndex];
      if (v is int) return v;
    }
    return null;
  }

  /// The ṣarf entry for one tapped word: resolves `word_index → QAC word →
  /// that word's morphology`. Null when unaligned or absent.
  Future<Object?> morphologyForWord(int surah, int ayah, int wordIndex) async {
    final qac = await qacWordFor(surah, ayah, wordIndex);
    if (qac == null) return null;
    final ayahM = await morphology(surah, ayah);
    if (ayahM is Map) {
      final words = ayahM['words'];
      if (words is List && qac >= 1 && qac <= words.length) {
        return words[qac - 1];
      }
    }
    return null;
  }

  /// iʿrāb dependency (The Quranic Treebank) for the ayah, or null.
  Future<Object?> syntax(int surah, int ayah) =>
      _json('quran_syntax', surah, ayah);

  /// غريب القرآن word meanings for the ayah, or null.
  Future<Object?> wordMeanings(int surah, int ayah) =>
      _json('quran_word_meaning', surah, ayah);

  /// Sourced فوائد / وقفات list for the ayah, or null.
  Future<Object?> notes(int surah, int ayah) => _json('quran_note', surah, ayah);

  /// Per-word variant readings (qirāʾāt) for the ayah, or null.
  Future<Object?> qiraat(int surah, int ayah) =>
      _json('quran_qiraat', surah, ayah);

  /// Near-identical ayah pairs (mutashābihāt) for the ayah, or null.
  Future<Object?> similar(int surah, int ayah) =>
      _json('quran_similar', surah, ayah);

  /// Athar / أقوال السلف linked to the ayah, or null.
  Future<Object?> sayings(int surah, int ayah) =>
      _json('quran_saying', surah, ayah);

  /// nāsikh & mansūkh note for the ayah, or null.
  Future<Object?> nasekh(int surah, int ayah) =>
      _json('quran_nasekh', surah, ayah);

  /// iʿrāb prose for the ayah, across every bundled iʿrāb book:
  /// `[{book_id, name, html}]`.
  Future<List<Map<String, Object?>>> irabProse(int surah, int ayah) async {
    final db = await _db;
    return db.rawQuery('''
      SELECT p.book_id, b.name, b.short, b.author, p.html
      FROM quran_irab_prose p
      LEFT JOIN quran_irab_book b ON b.id = p.book_id
      WHERE p.surah = ? AND p.ayah = ?
    ''', [surah, ayah]);
  }

  /// asbāb al-nuzūl for the ayah, across bundled asbāb books.
  Future<List<Map<String, Object?>>> asbab(int surah, int ayah) async {
    final db = await _db;
    return db.rawQuery('''
      SELECT a.book_id, b.name, b.short, b.author, a.html
      FROM quran_asbab a
      LEFT JOIN quran_asbab_book b ON b.id = a.book_id
      WHERE a.surah = ? AND a.ayah = ?
    ''', [surah, ayah]);
  }

  /// Topics whose ayah range covers `(surah, ayah)` — the Knowledge Index
  /// entry point. `[{id, name, parent_id}]`.
  Future<List<Map<String, Object?>>> topicsForAyah(int surah, int ayah) async {
    final db = await _db;
    return db.rawQuery('''
      SELECT DISTINCT t.id, t.name, t.parent_id
      FROM quran_topic_ayah ta
      JOIN quran_topic t ON t.id = ta.topic_id
      WHERE ta.surah = ? AND ? BETWEEN ta.ayah_from AND ta.ayah_to
      ORDER BY t.name
    ''', [surah, ayah]);
  }

  /// The `(surah, ayah_from, ayah_to)` ranges a topic covers.
  Future<List<Map<String, Object?>>> ayatForTopic(int topicId) async {
    final db = await _db;
    return db.query('quran_topic_ayah',
        columns: ['surah', 'ayah_from', 'ayah_to'],
        where: 'topic_id = ?',
        whereArgs: [topicId]);
  }

  // ---- QC4 · the Knowledge Index (topic ⇄ ayah, offline) ----------------
  // The generic `knowledge_links` graph (hadith / book / lesson edges) is a
  // Phase-E concern; offline the index is `quran_topic` + `quran_topic_ayah`.

  /// One topic row `{id, name, parent_id}` or null.
  Future<Map<String, Object?>?> topicById(int id) async {
    final db = await _db;
    final rows = await db.query('quran_topic',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Topics whose name contains [query], most-covered first.
  /// `[{id, name, parent_id, ayat}]`. Empty query → the broadest topics.
  Future<List<Map<String, Object?>>> searchTopics(String query,
      {int limit = 60}) async {
    final db = await _db;
    final q = query.trim();
    final esc = q.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
    final where = q.isEmpty ? '' : "WHERE t.name LIKE ? ESCAPE '\\'";
    final args = <Object?>[
      if (q.isNotEmpty) '%$esc%',
      limit,
    ];
    return db.rawQuery('''
      SELECT t.id, t.name, t.parent_id,
             COUNT(ta.rowid) AS ayat
      FROM quran_topic t
      LEFT JOIN quran_topic_ayah ta ON ta.topic_id = t.id
      $where
      GROUP BY t.id
      ORDER BY ayat DESC, t.name ASC
      LIMIT ?
    ''', args);
  }

  /// Direct children of [parentId] (topic tree), most-covered first.
  Future<List<Map<String, Object?>>> topicChildren(int parentId) async {
    final db = await _db;
    return db.rawQuery('''
      SELECT t.id, t.name, t.parent_id, COUNT(ta.rowid) AS ayat
      FROM quran_topic t
      LEFT JOIN quran_topic_ayah ta ON ta.topic_id = t.id
      WHERE t.parent_id = ?
      GROUP BY t.id
      ORDER BY ayat DESC, t.name ASC
    ''', [parentId]);
  }

  /// Every `(surah, ayah)` a topic covers — ranges expanded, de-duped,
  /// ordered, capped at [limit].
  Future<List<({int surah, int ayah})>> topicAyat(int topicId,
      {int limit = 400}) async {
    final ranges = await ayatForTopic(topicId);
    final seen = <int>{};
    final out = <({int surah, int ayah})>[];
    for (final r in ranges) {
      final s = (r['surah'] as num?)?.toInt();
      final a1 = (r['ayah_from'] as num?)?.toInt();
      if (s == null || a1 == null) continue;
      final a2 = (r['ayah_to'] as num?)?.toInt() ?? a1;
      for (var a = a1; a <= a2 && a - a1 < 300; a++) {
        if (seen.add(s * 1000 + a)) out.add((surah: s, ayah: a));
      }
    }
    out.sort((x, y) =>
        x.surah != y.surah ? x.surah - y.surah : x.ayah - y.ayah);
    return out.length > limit ? out.sublist(0, limit) : out;
  }

  // ---- catalogs ----

  Future<List<Map<String, Object?>>> tafsirBooks({bool? bundled}) async {
    final db = await _db;
    return db.query('quran_tafsir_book',
        where: bundled == null ? null : 'bundled = ?',
        whereArgs: bundled == null ? null : [bundled ? 1 : 0],
        orderBy: 'bundled DESC, id ASC');
  }

  Future<List<Map<String, Object?>>> translationEditions({String? lang}) async {
    final db = await _db;
    return db.query('quran_translation_edition',
        where: lang == null ? null : 'lang = ?',
        whereArgs: lang == null ? null : [lang],
        orderBy: 'lang ASC, id ASC');
  }

  Future<List<Map<String, Object?>>> riwayat() async {
    final db = await _db;
    return db.query('quran_riwaya', orderBy: 'is_primary DESC, id ASC');
  }

  Future<List<Map<String, Object?>>> reciters() async {
    final db = await _db;
    return db.query('quran_reciter', orderBy: 'id ASC');
  }

  Future<String?> surahIntro(int surah) async {
    final db = await _db;
    final rows = await db.query('quran_surah_info',
        columns: ['intro_html'],
        where: 'surah = ?',
        whereArgs: [surah],
        limit: 1);
    return rows.isEmpty ? null : rows.first['intro_html'] as String?;
  }

  Future<List<Map<String, Object?>>> booksByType(String type,
      {int limit = 200}) async {
    final db = await _db;
    return db.query('quran_book',
        where: 'type = ?', whereArgs: [type], limit: limit, orderBy: 'name ASC');
  }

  /// True once the corpus has been seeded (checked via one small table).
  Future<bool> isReady() async {
    final db = await _db;
    final n = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM quran_corpus_meta'));
    return (n ?? 0) > 0;
  }

  /// Per-dataset provenance for the "About sources" screen:
  /// `[{dataset, source, source_version, licence, rows, seeded_at_ms}]`.
  Future<List<Map<String, Object?>>> corpusMeta() async {
    final db = await _db;
    return db.query('quran_corpus_meta',
        columns: [
          'dataset',
          'source',
          'source_version',
          'licence',
          'rows',
          'seeded_at_ms'
        ],
        orderBy: 'dataset ASC');
  }
}
