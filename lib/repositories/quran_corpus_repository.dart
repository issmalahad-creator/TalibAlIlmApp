import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/tajweed_span.dart';

final RegExp _footRe =
    RegExp(r'<footer[^>]*>.*?</footer>', caseSensitive: false, dotAll: true);
final RegExp _brRe =
    RegExp(r'<\s*/?\s*(br|p|div|li|tr|h[1-6])\s*/?\s*>', caseSensitive: false);
final RegExp _tagRe = RegExp(r'<[^>]+>');
final RegExp _blankRe = RegExp(r'[ \t]*\n[ \t]*(\n[ \t]*)+');

/// HTML (or a list / map of html fragments) → plain text with real line
/// breaks. The iʿrāb / asbāb / nāsikh / āthār corpus fields keep their raw
/// markup (only tafsīr + translations were cleaned at ingest). Shared by
/// the quick-card layer (`corpus_panels.dart`) and [corpusEntriesForAyah]
/// so both always render the exact same underlying text.
String stripCorpusHtml(Object? v) {
  if (v == null) return '';
  if (v is List) {
    return v.map(stripCorpusHtml).where((s) => s.isNotEmpty).join('\n\n');
  }
  if (v is Map) {
    return stripCorpusHtml(v['text'] ?? v['html'] ?? v['content'] ?? '');
  }
  var s = v.toString().replaceAll('\r', '').replaceAll('﻿', '');
  s = s.replaceAll(_footRe, '');
  s = s.replaceAll(_brRe, '\n').replaceAll(_tagRe, '');
  s = s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  s = s.replaceAll(_blankRe, '\n\n');
  return s.trim();
}

/// One full-text, never-excerpted item from the "العلوم المرتبطة" corpus
/// layers, for the دراسة الآية deep page (`AyahStudyScreen`'s uloom
/// family). `domain` is one of: asbab, iraab, nasekh, ghareeb, notes,
/// similar, sayings — the same seven layers `AyahCorpusPanel` renders as
/// short cards; this is their full-text counterpart, sourced from the
/// exact same tables so the two views never drift.
class AyahCorpusEntry {
  final String domain;
  final String label;
  final String? author;
  final String text;
  const AyahCorpusEntry({
    required this.domain,
    required this.label,
    this.author,
    required this.text,
  });

  /// Stable identity across reloads (e.g. after prev/next-ayah), so the
  /// reader can tell whether "the same item" still exists on a new ayah —
  /// mirrors `AyahTafsirEntry.source` for tafsir.
  String get id => '$domain::$label';
}

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

  /// Phase G-t1 — tajwīd rule spans for the ayah (`quran_tajweed`, v56),
  /// covering all 6236 ayāt. Each [TajweedSpan] is a `[cs, ce)` char range in
  /// word `wordIndex`'s own Uthmani text, tagged with a cpfair rule id.
  /// Source: cpfair/quran-tajweed (rule data CC BY 4.0).
  Future<AyahTajweed> tajweedForAyah(int surah, int ayah) async {
    final raw = await _json('quran_tajweed', surah, ayah);
    final spans = <TajweedSpan>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          try {
            spans.add(TajweedSpan.fromJson(e.cast<String, dynamic>()));
          } catch (_) {/* skip a malformed span, never throw */}
        }
      }
    }
    return AyahTajweed(surah: surah, ayah: ayah, spans: spans);
  }

  /// The tajwīd spans that fall on one tapped word.
  Future<List<TajweedSpan>> tajweedForWord(
      int surah, int ayah, int wordIndex) async {
    final a = await tajweedForAyah(surah, ayah);
    return a.forWord(wordIndex);
  }

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

  /// Every sourced item across the seven "العلوم المرتبطة" corpus domains
  /// for this ayah, as full untruncated text — the دراسة الآية deep page's
  /// "العلوم" family reads this so «توسّع في صفحة الآية» actually opens
  /// somewhere real. Calls the same per-domain methods the quick-card
  /// layer uses, so both always show the same underlying text.
  Future<List<AyahCorpusEntry>> corpusEntriesForAyah(int surah, int ayah) async {
    final out = <AyahCorpusEntry>[];

    for (final r in await asbab(surah, ayah)) {
      final text = stripCorpusHtml(r['html']);
      if (text.isEmpty) continue;
      out.add(AyahCorpusEntry(
        domain: 'asbab',
        label: '${r['name'] ?? r['short'] ?? ''}',
        author: _nonEmpty(r['author']),
        text: text,
      ));
    }

    for (final r in await irabProse(surah, ayah)) {
      final text = stripCorpusHtml(r['html']);
      if (text.isEmpty) continue;
      out.add(AyahCorpusEntry(
        domain: 'iraab',
        label: '${r['name'] ?? r['short'] ?? ''}',
        author: _nonEmpty(r['author']),
        text: text,
      ));
    }

    final nasekhRaw = await nasekh(surah, ayah);
    if (nasekhRaw is Map) {
      final text = stripCorpusHtml(nasekhRaw['html']);
      if (text.isNotEmpty) {
        out.add(AyahCorpusEntry(domain: 'nasekh', label: '', text: text));
      }
    }

    final gm = await wordMeanings(surah, ayah);
    if (gm is List) {
      for (final book in gm) {
        if (book is! Map) continue;
        final words = book['words'] as List? ?? const [];
        if (words.isEmpty) continue;
        final text = words
            .whereType<Map>()
            .map((w) => '${w['text'] ?? ''}: ${w['meaning'] ?? ''}')
            .join('\n');
        if (text.trim().isEmpty) continue;
        final bookInfo = book['book_info'];
        out.add(AyahCorpusEntry(
          domain: 'ghareeb',
          label: bookInfo is Map ? '${bookInfo['name'] ?? ''}' : '',
          text: text,
        ));
      }
    }

    final notesRaw = await notes(surah, ayah);
    if (notesRaw is List) {
      for (final n in notesRaw) {
        if (n is! Map) continue;
        final text = stripCorpusHtml(n['ar_note']);
        if (text.isEmpty) continue;
        out.add(AyahCorpusEntry(
          domain: 'notes',
          label: '',
          author: _nonEmpty(n['author']),
          text: text,
        ));
      }
    }

    final similarRaw = await similar(surah, ayah);
    if (similarRaw is List) {
      for (final grp in similarRaw) {
        if (grp is! Map) continue;
        final buf = StringBuffer();
        final note = stripCorpusHtml(grp['notes']);
        if (note.isNotEmpty) buf.writeln(note);
        for (final ay in (grp['ayahs'] as List? ?? const [])) {
          if (ay is! Map) continue;
          final info = ay['info'];
          if (info is! Map) continue;
          final t = stripCorpusHtml(info['text']);
          if (t.isEmpty) continue;
          buf.writeln('﴿ $t ﴾  [${info['surah_id'] ?? '?'}:${info['number'] ?? '?'}]');
        }
        final text = buf.toString().trim();
        if (text.isNotEmpty) {
          out.add(AyahCorpusEntry(domain: 'similar', label: '', text: text));
        }
      }
    }

    final sayingsRaw = await sayings(surah, ayah);
    if (sayingsRaw is List) {
      for (final sy in sayingsRaw) {
        if (sy is! Map) continue;
        final text = stripCorpusHtml(sy['text']);
        if (text.isEmpty) continue;
        final narrators = (sy['narrators'] as List? ?? const [])
            .whereType<Map>()
            .map((x) => x['name'])
            .whereType<String>()
            .where((n) => n.isNotEmpty)
            .join('، ');
        out.add(AyahCorpusEntry(
          domain: 'sayings',
          label: '${sy['title'] ?? ''}',
          author: narrators.isEmpty ? null : narrators,
          text: text,
        ));
      }
    }

    return out;
  }

  String? _nonEmpty(Object? v) {
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// How many أسباب النزول books discuss each ayah of [surah] —
  /// `{ayah: bookCount}`, ayat with zero rows simply absent. Used to tell
  /// "no report for this ayah, but the surah has others documented" apart
  /// from "nothing documented anywhere in this surah" — never a guess,
  /// only what `quran_asbab` actually contains.
  Future<Map<int, int>> asbabCoverageForSurah(int surah) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT ayah, COUNT(DISTINCT book_id) AS c
      FROM quran_asbab
      WHERE surah = ?
      GROUP BY ayah
    ''', [surah]);
    return {
      for (final r in rows)
        (r['ayah'] as num).toInt(): (r['c'] as num).toInt(),
    };
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
        // `tafsir:<key>` rows are tafsir-import markers (ZW-5), not corpus datasets.
        await db.rawQuery("SELECT COUNT(*) FROM quran_corpus_meta WHERE dataset NOT LIKE 'tafsir:%'"));
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
        where: "dataset NOT LIKE 'tafsir:%'", // import markers (ZW-5), not sources
        orderBy: 'dataset ASC');
  }
}
