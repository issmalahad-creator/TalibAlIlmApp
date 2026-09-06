import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/mushaf_layout.dart';
import 'package:talib_alilm_app/models/tajweed_span.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_repository.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_sync.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_repository.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';
import 'package:talib_alilm_app/services/mushaf/tajweed_svg.dart';

/// Phase G-t v2 — glyph-level tajwīd rendering. The colour goes on the exact
/// `<path>` of a diacritic / single-letter glyph (direct `fill`), or a
/// clip-path band inside a multi-letter ligature — never a whole-word fill,
/// never a rectangle. Tajwīd OFF = the bundled SVG untouched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final corpus = QuranCorpusRepository();
  final layoutRepo = MushafLayoutRepository();

  String pageSvg(int page) {
    final f = File(p.join('assets', 'mushaf', 'pages_svg',
        '${page.toString().padLeft(3, '0')}.svg.gz'));
    return utf8.decode(gzip.decode(f.readAsBytesSync()), allowMalformed: true);
  }

  Future<TajweedGlyphPaint> paintFor(int page, {bool night = false}) async {
    final layout = (await layoutRepo.pageLayout(page))!;
    final byAyah = <String, AyahTajweed>{};
    for (final w in layout.words) {
      if (w.type != MushafWordType.text) continue;
      byAyah['${w.surah}:${w.ayah}'] =
          await corpus.tajweedForAyah(w.surah, w.ayah);
    }
    return resolveTajweedPaint(
      pageWords: layout.words,
      tajweedByAyah: byAyah,
      glyphsByWordOrder: await layoutRepo.glyphsForPage(page),
      night: night,
    );
  }

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_tajweed_svg_paint.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await QuranCorpusSync().sync();
    await MushafLayoutSync().sync();
  });

  test('tajwīd OFF: paintTajweedIntoSvg with nothing = bundled SVG + one base fill',
      () {
    final raw = pageSvg(1);
    final out = paintTajweedIntoSvg(raw,
        directFills: const {}, bands: const [], baseInkHex: '#000000');
    // only change: one fill on the page group
    expect('<g id="md-page" fill="#000000"'.allMatches(out).length, 1);
    expect(out.replaceFirst(' fill="#000000"', ''), raw);
    expect('<path '.allMatches(out).length, '<path '.allMatches(raw).length);
  });

  test('al-Fātiḥa p1: real fills land only on md-path glyph ids; page inked',
      () async {
    final paint = await paintFor(1);
    expect(paint.isEmpty, isFalse);
    expect(paint.spansDirect, greaterThan(0));

    for (final id in paint.directFills.keys) {
      expect(id.startsWith('md-path-'), isTrue);
      // never a header / page-number / margin decoration
      expect(
          id.contains('header') ||
              id.contains('page-number') ||
              id.contains('margin'),
          isFalse);
    }

    final raw = pageSvg(1);
    final out = paintTajweedIntoSvg(raw,
        directFills: paint.directFills, bands: paint.bands, baseInkHex: '#000000');
    // every injected fill= sits on a real glyph path (direct) or a clipped
    // madd-band duplicate — never a stray element.
    for (final m
        in RegExp(r'<path fill="(#[0-9a-f]{6})"([^>]*)>').allMatches(out)) {
      final rest = m.group(2)!;
      expect(rest.contains('id="md-path-') || rest.contains('clip-path="url(#tjc'),
          isTrue,
          reason: 'stray fill on: ${m.group(0)}');
    }
    // clip defs are well-formed + referenced 1:1
    final defs = RegExp(r'<clipPath id="(tjc\d+)">').allMatches(out).length;
    final refs = RegExp(r'clip-path="url\(#(tjc\d+)\)"').allMatches(out).length;
    expect(defs, refs);
    // paths grow by exactly one clipped duplicate per band, nothing else
    expect('<path '.allMatches(out).length,
        '<path '.allMatches(raw).length + paint.bands.length);
    expect(out.contains('<svg'), isTrue);
  });

  test('diacritic rules colour the mark path exactly (hamzat al-waṣl → wasla)',
      () async {
    // 1:1 word 2 (ٱللَّهِ): hamzat_wasl on the ٱ. The wasla diacritic path is
    // md-path-{wordN}-01-01 — a direct fill, not a band.
    final paint = await paintFor(1);
    final glyphs = (await layoutRepo.glyphsForPage(1));
    // find ٱللَّهِ's wordOrder
    final layout = (await layoutRepo.pageLayout(1))!;
    final wAllah = layout.words.firstWhere(
        (w) => w.surah == 1 && w.ayah == 1 && w.wordIndex == 2);
    final wg = glyphs[wAllah.wordOrder]!;
    final wasla = wg.glyphs.firstWhere((g) => g.kind == 1);
    expect(paint.directFills.containsKey(wasla.pathId), isTrue,
        reason: 'the waṣla mark path was not directly coloured');
  });

  test('night vs day give different hues for the same paths', () async {
    final day = await paintFor(1, night: false);
    final night = await paintFor(1, night: true);
    expect(day.directFills.keys.toSet(), night.directFills.keys.toSet());
    final anyDiff = day.directFills.entries
        .any((e) => night.directFills[e.key] != e.value);
    expect(anyDiff, isTrue);
  });
}
