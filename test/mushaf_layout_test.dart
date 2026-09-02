import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/data/quran_surahs.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/mushaf_layout.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_repository.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_sync.dart';

/// Phase 79 `79-mushaf` — real proof that the Mushaf Semantic Layer
/// (`mushaf_*`, migration v51) seeds cleanly from the real bundled asset and
/// that every one of the 604 pages resolves `word → ayah → surah → page →
/// line` correctly, with no orphan words and no wrong relationships.
///
/// Ground truth for the cross-check is the canonical per-surah ayah counts
/// in [quranSurahs] (the same list the Hifz checklist uses): 114 surahs,
/// 6236 ayat.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Map<String, dynamic> layout;
  final canon = {for (final s in quranSurahs) s.number: s.ayahCount};
  const canonTotalAyat = 6236;

  setUpAll(() {
    DatabaseHelper.databaseName = 'talib_mushaf_test.db';
    final dbFile = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (dbFile.existsSync()) {
      try {
        dbFile.deleteSync();
      } catch (_) {/* another suite may hold it briefly */}
    }
    final gz = File(join('assets', 'mushaf', 'mushaf_layout.json.gz'));
    expect(gz.existsSync(), isTrue, reason: 'bundled mushaf layout asset must be present');
    layout = jsonDecode(utf8.decode(gzip.decode(gz.readAsBytesSync()))) as Map<String, dynamic>;
  });

  group('validation (pure, before any write)', () {
    test('the bundled layout passes every structural check', () {
      final v = MushafLayoutSync().validate(layout);
      expect(v.ok, isTrue, reason: v.toString());
      expect(v.pages, 604);
      expect(v.surahs, 114);
      expect(v.distinctAyat, canonTotalAyat);
      expect(v.ayaMarks, canonTotalAyat);
      expect(v.nonContiguousWordIndexAyat, 0);
      expect(v.nonContiguousWordOrderPages, 0);
      expect(v.surahAyahCountMismatches, 0);
      expect(v.ayaMarkAyahMismatch, 0);
      expect(v.degenerateBoxes, 0);
      expect(v.pagesWithoutWords, 0);
      expect(v.words, greaterThan(77000));
    });

    test('a truncated layout (one page missing) is rejected, not ingested', () async {
      final broken = jsonDecode(jsonEncode(layout)) as Map<String, dynamic>;
      (broken['pages'] as List).removeAt(300);
      final v = MushafLayoutSync().validate(broken);
      expect(v.ok, isFalse);
      expect(v.failures.any((f) => f.contains('pages=603') || f.contains('missing page')), isTrue);

      final res = await MushafLayoutSync().ingestFromJson(broken);
      expect(res.outcome, 'rejected');
      final db = await DatabaseHelper.instance.database;
      final n = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM mushaf_pages')) ?? 0;
      expect(n, 0, reason: 'a rejected payload must leave the tables untouched');
    });
  });

  group('seeded database — 604-page integrity', () {
    late MushafLayoutRepository repo;

    setUpAll(() async {
      final res = await MushafLayoutSync().ingestFromJson(layout);
      expect(res.outcome, 'seeded');
      repo = MushafLayoutRepository();
    });

    test('604 pages, numbered 1..604 with no gap', () async {
      final db = await DatabaseHelper.instance.database;
      expect(await repo.pageCount(), 604);
      final rows = await db.query('mushaf_pages', columns: ['page'], orderBy: 'page ASC');
      final pages = [for (final r in rows) (r['page'] as num).toInt()];
      expect(pages.first, 1);
      expect(pages.last, 604);
      expect(pages, List.generate(604, (i) => i + 1));
    });

    test('every word maps to a real surah/ayah — no orphan, no over-count', () async {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
          'SELECT surah, MIN(ayah) AS lo, MAX(ayah) AS hi, COUNT(DISTINCT ayah) AS n FROM mushaf_words GROUP BY surah ORDER BY surah');
      expect(rows.length, 114);
      for (final r in rows) {
        final s = (r['surah'] as num).toInt();
        expect(r['lo'], 1, reason: 'surah $s must start at ayah 1');
        expect((r['hi'] as num).toInt(), canon[s], reason: 'surah $s last ayah');
        expect((r['n'] as num).toInt(), canon[s], reason: 'surah $s ayah count (no gaps)');
      }
      final distinctAyat = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM (SELECT DISTINCT surah, ayah FROM mushaf_words)'));
      expect(distinctAyat, canonTotalAyat);
    });

    test('word_index is contiguous 1..k for every one of the 6236 ayat', () async {
      final db = await DatabaseHelper.instance.database;
      final bad = await db.rawQuery('''
        SELECT surah, ayah, MIN(word_index) AS lo, MAX(word_index) AS hi, COUNT(*) AS c
        FROM mushaf_words GROUP BY surah, ayah
        HAVING lo <> 1 OR hi <> c
      ''');
      expect(bad, isEmpty, reason: 'ayat with broken word_index: $bad');
    });

    test('word_order is contiguous 1..n on every page', () async {
      final db = await DatabaseHelper.instance.database;
      final bad = await db.rawQuery('''
        SELECT page, MIN(word_order) AS lo, MAX(word_order) AS hi, COUNT(*) AS c
        FROM mushaf_words GROUP BY page
        HAVING lo <> 1 OR hi <> c
      ''');
      expect(bad, isEmpty, reason: 'pages with broken word_order: $bad');
    });

    test('exactly one aya-mark per ayah, and the mark set == the word ayah set', () async {
      final db = await DatabaseHelper.instance.database;
      expect(
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM mushaf_aya_marks')),
        canonTotalAyat,
      );
      final mismatch = await db.rawQuery('''
        SELECT surah, ayah FROM mushaf_words
        EXCEPT SELECT surah, ayah FROM mushaf_aya_marks
      ''');
      expect(mismatch, isEmpty);
    });

    test('every word bbox sits inside the viewBox with positive size', () async {
      final db = await DatabaseHelper.instance.database;
      final bad = await db.rawQuery('''
        SELECT COUNT(*) AS c FROM mushaf_words
        WHERE bbox_w <= 0 OR bbox_h <= 0
           OR bbox_x < -1 OR bbox_y < -1
           OR bbox_x + bbox_w > ${kMushafViewBoxWidth + 1}
           OR bbox_y + bbox_h > ${kMushafViewBoxHeight + 1}
      ''');
      expect((bad.first['c'] as num).toInt(), 0);
    });

    test('page 1 starts the Quran and page 604 ends it', () async {
      final p1 = await repo.pageLayout(1);
      expect(p1, isNotNull);
      expect(p1!.words.first.surah, 1);
      expect(p1.words.first.ayah, 1);
      expect(p1.words.first.wordIndex, 1);
      expect(p1.words.first.textUthmani, isNotEmpty);

      final p604 = await repo.pageLayout(604);
      expect(p604!.words.last.surah, 114);
      expect(p604.words.last.ayah, 6);
    });

    test('representative pages resolve tap → word → ayah → surah', () async {
      // beginning, middle, a surah-start page, a page deep in a long surah,
      // and the last page.
      for (final page in [1, 2, 255, 302, 500, 604]) {
        final layout = await repo.pageLayout(page);
        expect(layout, isNotNull, reason: 'page $page');
        expect(layout!.words, isNotEmpty);
        for (final w in layout.words) {
          // a point at the centre of the word's box must resolve back to it
          final hit = layout.wordAtPoint(w.box.centerX, w.box.centerY);
          expect(hit, isNotNull, reason: 'page $page word ${w.wordOrder}');
          expect(hit!.surah, w.surah);
          expect(hit.ayah, w.ayah);
        }
      }
    });

    test('a long multi-line ayah lights up on every line it occupies', () async {
      // Al-Baqara 2:282 — the longest verse.
      final page = await repo.pageForAyah(2, 282);
      expect(page, isNotNull);
      final words = await repo.wordsForAyah(2, 282);
      expect(words.length, greaterThan(80));
      final linesTouched = words.map((w) => w.line).toSet();
      expect(linesTouched.length, greaterThan(1), reason: 'must span several lines');
      final boxes = await repo.ayahBoxesOnPage(page!, 2, 282);
      expect(boxes.length, linesTouched.length);
    });

    test('ayah notebook anchor: pageForReference lands on the right surah/ayah', () async {
      // Ayat al-Kursi
      final page = await repo.pageForReference(2, ayah: 255);
      expect(page, isNotNull);
      final layout = await repo.pageLayout(page!);
      expect(layout!.words.any((w) => w.surah == 2 && w.ayah == 255), isTrue);

      // surah start fallback (ayah omitted)
      final fatihaPage = await repo.pageForReference(1);
      expect(fatihaPage, 1);
    });

    test('meta records the layout version and word/mark totals', () async {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('mushaf_meta');
      final meta = {for (final r in rows) r['key'] as String: r['value'] as String};
      expect(meta['layout_version'], '$kMushafLayoutVersion');
      expect(int.parse(meta['aya_marks']!), canonTotalAyat);
      expect(int.parse(meta['words']!), greaterThan(77000));
    });
  });
}
