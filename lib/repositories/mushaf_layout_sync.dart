import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, debugPrint, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../data/quran_surahs.dart';
import '../db/database_helper.dart';
import '../models/mushaf_layout.dart';

/// Outcome of a [MushafLayoutSync] run.
class MushafSyncResult {
  final String outcome; // 'seeded' | 'up-to-date' | 'rejected' | 'skipped'
  final bool changed;
  final MushafValidation? validation;
  const MushafSyncResult(this.outcome, {this.changed = false, this.validation});
  @override
  String toString() =>
      'MushafSyncResult($outcome, changed=$changed, ${validation ?? "no validation"})';
}

/// Structural validation of a parsed `mushaf_layout.json.gz` payload, run
/// BEFORE anything is written. A truncated / malformed / re-generated-wrong
/// asset must never replace a good seeded copy.
///
/// All checks are on **internal consistency + the canonical per-surah ayah
/// counts** ([quranSurahs]) — no dependency on `quran_ayat` being populated,
/// so it runs at first launch. `test/mushaf_layout_*` additionally
/// cross-checks the seeded rows against `quran_ayat` itself.
class MushafValidation {
  static const expectedPages = 604;
  static const expectedSurahs = 114;
  static const expectedAyat = 6236; // canonical Hafs total

  final int pages;
  final int surahs;
  final int words;
  final int distinctAyat;
  final int ayaMarks;
  final int nonContiguousWordIndexAyat;
  final int nonContiguousWordOrderPages;
  final int surahAyahCountMismatches;
  final int ayaMarkAyahMismatch; // |marks set  Δ  word-ayat set|
  final int degenerateBoxes;
  final int pagesWithoutWords;

  /// Phase 80 / M1: pages whose `md-page-inner data-rect` (read as
  /// `x0,y0,x1,y1` corners) is missing, malformed, non-positive-area, or not
  /// inside the viewBox. Expected 0 — the content frame is authored for all
  /// 604 pages.
  final int badContentRects;
  final List<String> failures;

  const MushafValidation({
    required this.pages,
    required this.surahs,
    required this.words,
    required this.distinctAyat,
    required this.ayaMarks,
    required this.nonContiguousWordIndexAyat,
    required this.nonContiguousWordOrderPages,
    required this.surahAyahCountMismatches,
    required this.ayaMarkAyahMismatch,
    required this.degenerateBoxes,
    required this.pagesWithoutWords,
    required this.badContentRects,
    required this.failures,
  });

  bool get ok => failures.isEmpty;

  @override
  String toString() => 'MushafValidation(pages=$pages, surahs=$surahs, words=$words, '
      'distinctAyat=$distinctAyat, ayaMarks=$ayaMarks, '
      'badWordIndex=$nonContiguousWordIndexAyat, badWordOrder=$nonContiguousWordOrderPages, '
      'surahCountMismatch=$surahAyahCountMismatches, ayaMarkMismatch=$ayaMarkAyahMismatch, '
      'degenerateBoxes=$degenerateBoxes, pagesWithoutWords=$pagesWithoutWords, '
      'badContentRects=$badContentRects, ok=$ok'
      '${failures.isEmpty ? "" : ", failures=$failures"})';
}

/// Seeds and maintains the local Mushaf **Semantic Layer** (`mushaf_*`
/// tables, migration v51) from the bundled `assets/mushaf/mushaf_layout.json.gz`.
///
/// Phase 79 `79-mushaf`. The asset is generated at build time by
/// `tool/extract_mushaf_svg.py` from the MushafDatabase Ligature-Based SVG
/// V1.01 set. Bundled-only for v1 (no network) — a hosted refresh is a later
/// option in the design doc. The tables are rebuilt wholesale on each seed
/// (≈91k tiny rows) inside one transaction, only after validation passes,
/// and only when the bundled asset's version differs from what's stored.
class MushafLayoutSync {
  static const _assetPath = 'assets/mushaf/mushaf_layout.json.gz';
  static const _manifestPath = 'assets/mushaf/mushaf_manifest.json';
  static const _glyphsAssetPath = 'assets/mushaf/mushaf_glyphs.json.gz';

  /// Entry point (called once from app startup, after migrations). Seeds if
  /// the table is empty or the bundled asset version moved on. Every failure
  /// is swallowed and reported via [MushafSyncResult]; the reader's existing
  /// path is never affected.
  Future<MushafSyncResult> sync() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final have = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM mushaf_pages'),
          ) ??
          0;
      final storedVersion = int.tryParse(await _meta(db, 'layout_version') ?? '');
      if (have > 0 && storedVersion == kMushafLayoutVersion) {
        // Layout is current. Phase G-t2's glyph geometry is a separate table
        // seeded on its own (no layout re-seed) — top it up if empty.
        await _ensureGlyphs(db);
        return const MushafSyncResult('up-to-date');
      }
      return _seedFromAsset(db);
    } catch (e) {
      debugPrint('MushafLayoutSync: sync skipped ($e).');
      return const MushafSyncResult('skipped');
    }
  }

  Future<MushafSyncResult> _seedFromAsset(Database db) async {
    try {
      final bytes = await rootBundle.load(_assetPath);
      final jsonText = utf8.decode(gzip.decode(bytes.buffer.asUint8List()));
      final layout = jsonDecode(jsonText) as Map<String, dynamic>;
      final v = validate(layout);
      if (!v.ok) {
        debugPrint('MushafLayoutSync: bundled asset failed validation, not seeding. $v');
        return MushafSyncResult('rejected', validation: v);
      }
      await _ingest(db, layout, v, artSetSha256: await _manifestArtHash());
      await _ensureGlyphs(db); // separate table, its own version marker
      debugPrint('MushafLayoutSync: seeded from asset. $v');
      return MushafSyncResult('seeded', changed: true, validation: v);
    } catch (e) {
      debugPrint('MushafLayoutSync: asset seed failed ($e).');
      return const MushafSyncResult('skipped');
    }
  }

  /// Phase G-t2 / v2 — seed the `mushaf_glyphs` table (one row per page) on
  /// its own: when the table is empty, OR when the bundled asset's `v` moved
  /// on (`mushaf_meta` marker `glyphs_v`). No layout re-seed — the layout
  /// tables are untouched, so `kMushafLayoutVersion` is deliberately not
  /// bumped (that would re-seed ~91k word rows for every existing user).
  Future<void> _ensureGlyphs(Database db) async {
    try {
      final n = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM mushaf_glyphs')) ??
          0;
      final storedV = int.tryParse(await _meta(db, 'glyphs_v') ?? '') ?? 0;
      final loaded = await _loadGlyphs();
      if (loaded == null) return;
      final (assetV, pages) = loaded;
      if (n > 0 && storedV == assetV) return;

      await db.transaction((txn) async {
        await txn.delete('mushaf_glyphs');
        final batch = txn.batch();
        for (final e in pages.entries) {
          batch.insert('mushaf_glyphs', {'page': e.key, 'data': e.value});
        }
        await batch.commit(noResult: true);
        await txn.insert('mushaf_meta', {'key': 'glyphs_v', 'value': '$assetV'},
            conflictAlgorithm: ConflictAlgorithm.replace);
      });
      debugPrint('MushafLayoutSync: glyph geometry v$assetV seeded (${pages.length}).');
    } catch (e) {
      debugPrint('MushafLayoutSync: glyph seed skipped ($e).');
    }
  }

  /// Phase G-t2 — the per-page sub-word glyph geometry: `(assetVersion,
  /// {page: rawJsonForPage})`. The ~8 MB gunzip + parse + per-page re-encode
  /// runs in a background isolate (`compute`). Best-effort: a missing /
  /// malformed asset returns `null` and the tajwīd layer has nothing to draw.
  Future<(int, Map<int, String>)?> _loadGlyphs() async {
    try {
      final bytes = await rootBundle.load(_glyphsAssetPath);
      final out = await compute(_parseGlyphAsset,
          Uint8List.fromList(bytes.buffer.asUint8List()));
      if (out.$2.isEmpty) return null;
      debugPrint('MushafLayoutSync: glyph geometry v${out.$1} for ${out.$2.length} pages.');
      return out;
    } catch (e) {
      debugPrint('MushafLayoutSync: glyph asset skipped ($e).');
      return null;
    }
  }

  /// The bundled art integrity hash (`tool/mushaf_art_hash.py`), from the
  /// manifest. Advisory — a bad/missing value is logged, not fatal; the
  /// structural [validate] is the real gate. Recorded in `mushaf_meta` so the
  /// M5 QA tool can diff it against a fresh recompute of `pages_svg/`.
  Future<String?> _manifestArtHash() async {
    try {
      final text = await rootBundle.loadString(_manifestPath);
      final m = jsonDecode(text) as Map<String, dynamic>;
      final h = m['art_set_sha256'];
      if (h is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(h)) return h;
      debugPrint('MushafLayoutSync: manifest art_set_sha256 missing/invalid.');
    } catch (e) {
      debugPrint('MushafLayoutSync: could not read manifest ($e).');
    }
    return null;
  }

  /// Validate then ingest an already-parsed layout map. The seam tests use.
  @visibleForTesting
  Future<MushafSyncResult> ingestFromJson(Map<String, dynamic> layout) async {
    final db = await DatabaseHelper.instance.database;
    final v = validate(layout);
    if (!v.ok) return MushafSyncResult('rejected', validation: v);
    await _ingest(db, layout, v);
    return MushafSyncResult('seeded', changed: true, validation: v);
  }

  /// Pure, side-effect-free structural validation.
  MushafValidation validate(Map<String, dynamic> layout) {
    final failures = <String>[];
    final pages = (layout['pages'] as List?) ?? const [];

    final seenPages = <int>{};
    var words = 0;
    var badWordOrderPages = 0;
    var degenerateBoxes = 0;
    var pagesWithoutWords = 0;
    var badContentRects = 0;
    final badContentRectPages = <int>[];
    final wordIndicesByAyah = <String, List<int>>{};
    final maxAyahBySurah = <int, int>{};
    final wordAyahKeys = <String>{};
    final markAyahKeys = <String>{};
    var ayaMarks = 0;

    final vbW = (layout['viewBox'] is List && (layout['viewBox'] as List).length == 4)
        ? ((layout['viewBox'] as List)[2] as num).toDouble()
        : kMushafViewBoxWidth;
    final vbH = (layout['viewBox'] is List && (layout['viewBox'] as List).length == 4)
        ? ((layout['viewBox'] as List)[3] as num).toDouble()
        : kMushafViewBoxHeight;

    for (final raw in pages) {
      final p = raw as Map<String, dynamic>;
      final pn = (p['page'] as num).toInt();
      seenPages.add(pn);

      final lines = (p['lines'] as List?) ?? const [];
      if (lines.isEmpty || lines.length > 15) {
        failures.add('page $pn has ${lines.length} lines (expected 1..15)');
      }

      final pw = (p['words'] as List?) ?? const [];
      if (pw.isEmpty) pagesWithoutWords++;
      final orders = <int>[];
      for (final wraw in pw) {
        final w = wraw as Map<String, dynamic>;
        words++;
        orders.add((w['o'] as num).toInt());
        final s = (w['s'] as num).toInt();
        final a = (w['a'] as num).toInt();
        final wi = (w['w'] as num).toInt();
        final key = '$s:$a';
        wordAyahKeys.add(key);
        (wordIndicesByAyah[key] ??= <int>[]).add(wi);
        final cur = maxAyahBySurah[s] ?? 0;
        if (a > cur) maxAyahBySurah[s] = a;

        final b = w['b'];
        if (b is! List || b.length != 4) {
          degenerateBoxes++;
        } else {
          final x = (b[0] as num).toDouble();
          final y = (b[1] as num).toDouble();
          final bw = (b[2] as num).toDouble();
          final bh = (b[3] as num).toDouble();
          if (bw <= 0 ||
              bh <= 0 ||
              x < -1 ||
              y < -1 ||
              x + bw > vbW + 1 ||
              y + bh > vbH + 1) {
            degenerateBoxes++;
          }
        }
      }
      orders.sort();
      final wantOrder = [for (var i = 1; i <= orders.length; i++) i];
      if (!_listEq(orders, wantOrder)) badWordOrderPages++;

      // Content frame — `md-page-inner data-rect` as x0,y0,x1,y1 corners
      // (kMushafLayoutVersion v2). Must be 4 numbers, positive area, inside
      // the viewBox. Authored for all 604 pages.
      final r = p['rect'];
      var rectOk = false;
      if (r is List && r.length == 4 && r.every((v) => v is num)) {
        final x0 = (r[0] as num).toDouble();
        final y0 = (r[1] as num).toDouble();
        final x1 = (r[2] as num).toDouble();
        final y1 = (r[3] as num).toDouble();
        rectOk = x1 > x0 &&
            y1 > y0 &&
            x0 >= -1 &&
            y0 >= -1 &&
            x1 <= vbW + 1 &&
            y1 <= vbH + 1;
      }
      if (!rectOk) {
        badContentRects++;
        if (badContentRectPages.length < 10) badContentRectPages.add(pn);
      }

      for (final mraw in (p['marks'] as List?) ?? const []) {
        final m = mraw as Map<String, dynamic>;
        ayaMarks++;
        markAyahKeys.add('${(m['s'] as num).toInt()}:${(m['a'] as num).toInt()}');
      }
    }

    var badWordIndexAyat = 0;
    wordIndicesByAyah.forEach((_, idxs) {
      idxs.sort();
      final want = [for (var i = 1; i <= idxs.length; i++) i];
      if (!_listEq(idxs, want)) badWordIndexAyat++;
    });

    var surahCountMismatch = 0;
    final canon = {for (final s in quranSurahs) s.number: s.ayahCount};
    for (var s = 1; s <= 114; s++) {
      if ((maxAyahBySurah[s] ?? 0) != canon[s]) surahCountMismatch++;
    }

    final markMismatch = wordAyahKeys.difference(markAyahKeys).length +
        markAyahKeys.difference(wordAyahKeys).length;

    // ---- failure gating ----
    if (seenPages.length != MushafValidation.expectedPages) {
      failures.add('pages=${seenPages.length} (expected ${MushafValidation.expectedPages})');
    }
    final missing = [
      for (var i = 1; i <= MushafValidation.expectedPages; i++)
        if (!seenPages.contains(i)) i
    ];
    if (missing.isNotEmpty) {
      failures.add('missing page numbers: ${missing.take(10).toList()}${missing.length > 10 ? "…" : ""}');
    }
    if (maxAyahBySurah.length != MushafValidation.expectedSurahs) {
      failures.add('surahs=${maxAyahBySurah.length} (expected ${MushafValidation.expectedSurahs})');
    }
    if (wordAyahKeys.length != MushafValidation.expectedAyat) {
      failures.add('distinct ayat=${wordAyahKeys.length} (expected ${MushafValidation.expectedAyat})');
    }
    if (ayaMarks != MushafValidation.expectedAyat) {
      failures.add('aya marks=$ayaMarks (expected ${MushafValidation.expectedAyat})');
    }
    if (badWordIndexAyat != 0) failures.add('ayat with non-contiguous word_index=$badWordIndexAyat');
    if (badWordOrderPages != 0) failures.add('pages with non-contiguous word_order=$badWordOrderPages');
    if (surahCountMismatch != 0) {
      failures.add('per-surah ayah count mismatches vs canonical list=$surahCountMismatch');
    }
    if (markMismatch != 0) failures.add('aya-mark set vs word-ayat set differ by=$markMismatch');
    if (degenerateBoxes != 0) failures.add('degenerate/out-of-viewBox word boxes=$degenerateBoxes');
    if (pagesWithoutWords != 0) failures.add('pages with zero words=$pagesWithoutWords');
    if (badContentRects != 0) {
      failures.add('pages with missing/invalid content rect=$badContentRects '
          '(e.g. $badContentRectPages)');
    }

    return MushafValidation(
      pages: seenPages.length,
      surahs: maxAyahBySurah.length,
      words: words,
      distinctAyat: wordAyahKeys.length,
      ayaMarks: ayaMarks,
      nonContiguousWordIndexAyat: badWordIndexAyat,
      nonContiguousWordOrderPages: badWordOrderPages,
      surahAyahCountMismatches: surahCountMismatch,
      ayaMarkAyahMismatch: markMismatch,
      degenerateBoxes: degenerateBoxes,
      pagesWithoutWords: pagesWithoutWords,
      badContentRects: badContentRects,
      failures: failures,
    );
  }

  Future<void> _ingest(
    Database db,
    Map<String, dynamic> layout,
    MushafValidation validation, {
    String? artSetSha256,
  }) async {
    final pages = (layout['pages'] as List).cast<Map<String, dynamic>>();
    final vb = (layout['viewBox'] as List?) ?? const [0, 0, kMushafViewBoxWidth, kMushafViewBoxHeight];
    final vbW = (vb[2] as num).toDouble();
    final vbH = (vb[3] as num).toDouble();

    await db.transaction((txn) async {
      for (final t in const [
        'mushaf_words',
        'mushaf_lines',
        'mushaf_aya_marks',
        'mushaf_markers',
        'mushaf_pages',
        'mushaf_meta',
        'mushaf_glyphs',
      ]) {
        await txn.delete(t);
      }

      final batch = txn.batch();
      for (final p in pages) {
        final layoutPage = MushafPageLayout.fromJson(p);
        final pn = layoutPage.page;
        final ayat = layoutPage.ayat;
        batch.insert('mushaf_pages', {
          'page': pn,
          'rect_x': layoutPage.rect?.x,
          'rect_y': layoutPage.rect?.y,
          'rect_w': layoutPage.rect?.w,
          'rect_h': layoutPage.rect?.h,
          'vb_w': vbW,
          'vb_h': vbH,
          'line_count': layoutPage.lines.length,
          'surah_first': ayat.isEmpty ? 0 : ayat.first.surah,
          'surah_last': ayat.isEmpty ? 0 : ayat.last.surah,
          'ayah_first': ayat.isEmpty ? 0 : ayat.first.ayah,
          'ayah_last': ayat.isEmpty ? 0 : ayat.last.ayah,
          'word_count': layoutPage.words.length,
        });
        for (final l in layoutPage.lines) {
          batch.insert('mushaf_lines', {'page': pn, 'line': l.line, 'line_type': l.type});
        }
        for (final w in layoutPage.words) {
          batch.insert('mushaf_words', w.toRow());
        }
        for (final m in layoutPage.ayaMarks) {
          batch.insert('mushaf_aya_marks', m.toRow(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        for (final m in layoutPage.markers) {
          batch.insert('mushaf_markers', m.toRow());
        }
      }

      await batch.commit(noResult: true);

      // Post-insert cross-check against the DB itself — if what landed
      // disagrees with the validated payload, throw and roll back.
      final pageRows = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM mushaf_pages'));
      final wordRows = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM mushaf_words'));
      final markRows = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM mushaf_aya_marks'));
      final surahRows = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COUNT(DISTINCT surah) FROM mushaf_words'));
      if (pageRows != MushafValidation.expectedPages ||
          wordRows != validation.words ||
          markRows != MushafValidation.expectedAyat ||
          surahRows != MushafValidation.expectedSurahs) {
        throw StateError('post-insert cross-check failed: pageRows=$pageRows '
            'wordRows=$wordRows (want ${validation.words}) markRows=$markRows '
            'surahRows=$surahRows — rolling back');
      }

      for (final e in {
        'layout_version': '$kMushafLayoutVersion',
        'source': '${layout['source'] ?? ''}',
        'seeded_at_ms': '${DateTime.now().millisecondsSinceEpoch}',
        'words': '${validation.words}',
        'aya_marks': '${validation.ayaMarks}',
        'content_rects_ok': '${validation.pages - validation.badContentRects}',
        'art_set_sha256': ?artSetSha256,
      }.entries) {
        await txn.insert('mushaf_meta', {'key': e.key, 'value': e.value});
      }
    });
  }

  Future<String?> _meta(DatabaseExecutor db, String key) async {
    final rows = await db.query('mushaf_meta', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  static bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Runs in a background isolate (`compute`): gunzip + parse
/// `mushaf_glyphs.json.gz`, and re-emit `(assetVersion, {page: wordsJson})`.
/// Returns `(0, {})` on any problem.
(int, Map<int, String>) _parseGlyphAsset(Uint8List gz) {
  try {
    final text = utf8.decode(gzip.decode(gz));
    final obj = jsonDecode(text) as Map<String, dynamic>;
    final v = (obj['v'] as num?)?.toInt() ?? 1;
    final pages = (obj['pages'] as List?) ?? const [];
    final out = <int, String>{};
    for (final p in pages) {
      final m = p as Map<String, dynamic>;
      out[(m['p'] as num).toInt()] = jsonEncode(m['words'] ?? const []);
    }
    return (v, out);
  } catch (_) {
    return (0, const {});
  }
}
