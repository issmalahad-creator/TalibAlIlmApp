import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/mushaf_layout.dart';

/// One "ورد" (portion) of a §2.5 "تحزيب الصحابة"-style 7-way split — see
/// [MushafLayoutRepository.sevenWerdBoundaries].
typedef WerdBoundary = ({
  int index,
  int startPage,
  int endPage,
  int startSurah,
  int startAyah,
  int endSurah,
  int endAyah,
});

/// Read-only access to the Mushaf **Semantic Layer** (`mushaf_*` tables,
/// migration v51, seeded by `MushafLayoutSync`).
///
/// Phase 79 `79-mushaf`. Everything here is a plain query returning the
/// framework-free models in `models/mushaf_layout.dart`. It knows nothing
/// about how a page is drawn — the [MushafPageView] widget is the only
/// consumer that turns this data into pixels, and it could be swapped for a
/// different renderer without touching a line of this class or the schema.
class MushafLayoutRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  /// True once the layer has been seeded (first launch may briefly be false).
  Future<bool> isReady() async {
    final db = await _db;
    final n = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM mushaf_pages')) ?? 0;
    return n > 0;
  }

  /// Total seeded pages (604 when fully seeded).
  Future<int> pageCount() async {
    final db = await _db;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM mushaf_pages')) ?? 0;
  }

  /// The full layout for one page (1..604), or null if not seeded / bad page.
  Future<MushafPageLayout?> pageLayout(int page) async {
    final db = await _db;
    final pageRows = await db.query('mushaf_pages', where: 'page = ?', whereArgs: [page], limit: 1);
    if (pageRows.isEmpty) return null;
    final pr = pageRows.first;

    final lineRows = await db.query('mushaf_lines',
        where: 'page = ?', whereArgs: [page], orderBy: 'line ASC');
    final wordRows = await db.query('mushaf_words',
        where: 'page = ?', whereArgs: [page], orderBy: 'word_order ASC');
    final markRows = await db.query('mushaf_aya_marks',
        where: 'page = ?', whereArgs: [page], orderBy: 'line ASC, surah ASC, ayah ASC');
    final markerRows = await db.query('mushaf_markers',
        where: 'page = ?', whereArgs: [page], orderBy: 'id ASC');

    MushafBox? rect;
    if (pr['rect_x'] != null) {
      rect = MushafBox(
        (pr['rect_x'] as num).toDouble(),
        (pr['rect_y'] as num).toDouble(),
        (pr['rect_w'] as num).toDouble(),
        (pr['rect_h'] as num).toDouble(),
      );
    }

    return MushafPageLayout(
      page: page,
      rect: rect,
      viewBoxWidth: (pr['vb_w'] as num?)?.toDouble() ?? kMushafViewBoxWidth,
      viewBoxHeight: (pr['vb_h'] as num?)?.toDouble() ?? kMushafViewBoxHeight,
      lines: [
        for (final r in lineRows)
          MushafLineInfo((r['line'] as num).toInt(), r['line_type'] as String? ?? 'text'),
      ],
      words: [for (final r in wordRows) MushafWord.fromRow(r)],
      ayaMarks: [for (final r in markRows) MushafAyaMark.fromRow(r)],
      markers: [for (final r in markerRows) MushafMarker.fromRow(r)],
    );
  }

  /// Every word of one ayah, in `word_index` order (may cross pages in
  /// theory; this mushaf keeps each ayah on a single page, so normally one).
  Future<List<MushafWord>> wordsForAyah(int surah, int ayah) async {
    final db = await _db;
    final rows = await db.query('mushaf_words',
        where: 'surah = ? AND ayah = ?',
        whereArgs: [surah, ayah],
        orderBy: 'word_index ASC');
    return [for (final r in rows) MushafWord.fromRow(r)];
  }

  /// The page a given ayah sits on (from its verse-end mark), or null.
  Future<int?> pageForAyah(int surah, int ayah) async {
    final db = await _db;
    final rows = await db.query('mushaf_aya_marks',
        columns: ['page'], where: 'surah = ? AND ayah = ?', whereArgs: [surah, ayah], limit: 1);
    if (rows.isNotEmpty) return (rows.first['page'] as num).toInt();
    final w = await db.query('mushaf_words',
        columns: ['page'], where: 'surah = ? AND ayah = ?', whereArgs: [surah, ayah], limit: 1);
    return w.isEmpty ? null : (w.first['page'] as num).toInt();
  }

  /// The juzʼ a page belongs to, from its first word's ayah — the reverse of
  /// [pageForJuz]. A page can span two juzʼ boundaries; this reports the
  /// juzʼ its opening ayah is in, matching how a printed muṣḥaf's "الجزء"
  /// label reads for that page.
  Future<int?> juzForPage(int page) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT qa.juz_number AS j
      FROM mushaf_words mw
      JOIN quran_ayat qa ON qa.surah = mw.surah AND qa.ayah = mw.ayah
      WHERE mw.page = ?
      ORDER BY mw.word_order ASC
      LIMIT 1
    ''', [page]);
    final j = rows.isEmpty ? null : rows.first['j'];
    return j == null ? null : (j as num).toInt();
  }

  /// The MushafDatabase page a juzʼ starts on — joined through `quran_ayat`
  /// (which carries `juz_number`) so it is the real V1.01 page, not a Tanzil
  /// page number.
  Future<int?> pageForJuz(int juz) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT MIN(mw.page) AS p
      FROM mushaf_words mw
      JOIN quran_ayat qa ON qa.surah = mw.surah AND qa.ayah = mw.ayah
      WHERE qa.juz_number = ?
    ''', [juz]);
    final p = rows.isEmpty ? null : rows.first['p'];
    return p == null ? null : (p as num).toInt();
  }

  /// The page a `(surah, ayah)` reference should open on. Falls back to the
  /// surah's first page when that exact ayah isn't found.
  Future<int?> pageForReference(int surah, {int ayah = 1}) async {
    final direct = await pageForAyah(surah, ayah);
    if (direct != null) return direct;
    final db = await _db;
    final rows = await db.query('mushaf_words',
        columns: ['MIN(page) AS p'], where: 'surah = ?', whereArgs: [surah]);
    final p = rows.isEmpty ? null : rows.first['p'];
    return p == null ? null : (p as num).toInt();
  }

  /// Per-line highlight boxes for an ayah on a specific page (one per line).
  Future<List<MushafBox>> ayahBoxesOnPage(int page, int surah, int ayah) async {
    final db = await _db;
    final rows = await db.query('mushaf_words',
        where: 'page = ? AND surah = ? AND ayah = ?',
        whereArgs: [page, surah, ayah],
        orderBy: 'line ASC, word_order ASC');
    final byLine = <int, MushafBox>{};
    for (final r in rows) {
      final w = MushafWord.fromRow(r);
      byLine.update(w.line, (b) => b.union(w.box), ifAbsent: () => w.box);
    }
    final lines = byLine.keys.toList()..sort();
    return [for (final l in lines) byLine[l]!];
  }

  /// First and last Mushaf page for a surah.
  Future<({int first, int last})?> pageRangeForSurah(int surah) async {
    final db = await _db;
    final rows = await db.rawQuery(
        'SELECT MIN(page) AS a, MAX(page) AS b FROM mushaf_words WHERE surah = ?', [surah]);
    if (rows.isEmpty || rows.first['a'] == null) return null;
    return (first: (rows.first['a'] as num).toInt(), last: (rows.first['b'] as num).toInt());
  }

  /// The first and last ayah appearing on a page, in true reading order —
  /// reads `mushaf_pages.surah_first`/`ayah_first`/`surah_last`/`ayah_last`,
  /// precomputed at seed time (`MushafLayoutSync`) from `mushaf_words` in
  /// `word_order`. Null if the page isn't seeded.
  Future<({int firstSurah, int firstAyah, int lastSurah, int lastAyah})?> ayahBoundsForPage(int page) async {
    final db = await _db;
    final rows = await db.query('mushaf_pages',
        columns: ['surah_first', 'ayah_first', 'surah_last', 'ayah_last'],
        where: 'page = ?', whereArgs: [page], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return (
      firstSurah: (r['surah_first'] as num).toInt(),
      firstAyah: (r['ayah_first'] as num).toInt(),
      lastSurah: (r['surah_last'] as num).toInt(),
      lastAyah: (r['ayah_last'] as num).toInt(),
    );
  }

  /// §2.5 "تحزيب الصحابة" — the 7 real surah numbers the classical division
  /// starts each werd at ("فمي بشوق"): الفاتحة، المائدة، يونس، الإسراء،
  /// الشعراء، الصافات، ق.
  static const kTahzeebSahabaStartSurahs = <int>[1, 5, 10, 17, 26, 37, 50];

  /// Splits an absolute page range `[startPage, endPage]` into 7 "أوراد",
  /// each described by its start/end page and the surah:ayah it starts/ends
  /// at. When the range is exactly the whole mushaf (1..604) the boundaries
  /// are the real classical "تحزيب الصحابة" surah starts
  /// ([kTahzeebSahabaStartSurahs]) — quoted verbatim in the app's own info
  /// dialog, not an approximation. Otherwise (a partial-range goal) there is
  /// no classical division to anchor to, so the range's own pages are split
  /// into 7 roughly-equal chunks instead — the closest well-defined
  /// generalization. Returns fewer than 7 entries only if the underlying
  /// mushaf data for a boundary page is missing (never a half-resolved
  /// boundary).
  Future<List<WerdBoundary>> sevenWerdBoundaries(int startPage, int endPage) async {
    final startPages = <int>[];
    if (startPage == 1 && endPage == 604) {
      for (final surah in kTahzeebSahabaStartSurahs) {
        final p = await pageForReference(surah);
        if (p == null) return const [];
        startPages.add(p);
      }
    } else {
      final totalPages = endPage - startPage + 1;
      final base = totalPages ~/ 7;
      final extra = totalPages % 7;
      var p = startPage;
      for (var i = 0; i < 7; i++) {
        startPages.add(p);
        p += base + (i < extra ? 1 : 0);
      }
    }

    final boundaries = <WerdBoundary>[];
    for (var i = 0; i < 7; i++) {
      final werdStart = startPages[i];
      final werdEnd = i < 6 ? startPages[i + 1] - 1 : endPage;
      final first = await ayahBoundsForPage(werdStart);
      final last = await ayahBoundsForPage(werdEnd);
      if (first == null || last == null) continue;
      boundaries.add((
        index: i + 1,
        startPage: werdStart,
        endPage: werdEnd,
        startSurah: first.firstSurah,
        startAyah: first.firstAyah,
        endSurah: last.lastSurah,
        endAyah: last.lastAyah,
      ));
    }
    return boundaries;
  }

  /// Phase G-t2 — sub-word glyph geometry for a page, keyed by
  /// `wordOrder` (== [MushafWord.order]). Empty when the optional
  /// `mushaf_glyphs` asset wasn't bundled/seeded (DB v57). Used only by the
  /// opt-in tajwīd overlay.
  Future<Map<int, MushafWordGlyphs>> glyphsForPage(int page) async {
    final db = await _db;
    final rows = await db.query('mushaf_glyphs',
        columns: ['data'], where: 'page = ?', whereArgs: [page], limit: 1);
    if (rows.isEmpty) return const {};
    try {
      final list = jsonDecode(rows.first['data'] as String) as List;
      final out = <int, MushafWordGlyphs>{};
      for (final w in list) {
        final g = MushafWordGlyphs.fromJson((w as Map).cast<String, dynamic>());
        out[g.wordOrder] = g;
      }
      return out;
    } catch (_) {
      return const {};
    }
  }
}
