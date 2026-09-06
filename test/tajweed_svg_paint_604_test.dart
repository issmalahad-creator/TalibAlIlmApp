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

/// Phase G-t v2 — the 604-page safety gate for the glyph-level tajwīd
/// transform, and the source of `docs/quran/reports/TAJWEED_GLYPH_COVERAGE.md`
/// (Ismail's requirement: direct vs band vs skipped, per rule, with
/// examples — the ligature fallback must be visible, never silent).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final corpus = QuranCorpusRepository();
  final layoutRepo = MushafLayoutRepository();

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_tajweed_svg_604.db';
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

  test('all 604 pages: transform is safe, and the coverage report holds', () async {
    var total = 0, direct = 0, band = 0, skip = 0;
    final byRule = <String, List<int>>{}; // rule -> [direct, band, skip]
    final examples = <String>[];
    final failures = <String>[];

    for (var page = 1; page <= 604; page++) {
      final layout = await layoutRepo.pageLayout(page);
      if (layout == null) {
        failures.add('p$page: no layout');
        continue;
      }
      final byAyah = <String, AyahTajweed>{};
      for (final w in layout.words) {
        if (w.type != MushafWordType.text) continue;
        final k = '${w.surah}:${w.ayah}';
        byAyah[k] ??= await corpus.tajweedForAyah(w.surah, w.ayah);
      }
      final paint = resolveTajweedPaint(
        pageWords: layout.words,
        tajweedByAyah: byAyah,
        glyphsByWordOrder: await layoutRepo.glyphsForPage(page),
        night: false,
      );

      total += paint.spansTotal;
      direct += paint.spansDirect;
      band += paint.spansBand;
      skip += paint.spansSkipped;
      paint.byRule.forEach((r, c) {
        final l = byRule.putIfAbsent(r, () => [0, 0, 0]);
        l[0] += c.direct;
        l[1] += c.band;
        l[2] += c.skip;
      });
      if (examples.length < 30) examples.addAll(paint.skippedExamples);

      // ---- transform safety ----
      final raw = utf8.decode(
          gzip.decode(File(p.join('assets', 'mushaf', 'pages_svg',
                  '${page.toString().padLeft(3, '0')}.svg.gz'))
              .readAsBytesSync()),
          allowMalformed: true);
      String out;
      try {
        out = paintTajweedIntoSvg(raw,
            directFills: paint.directFills, bands: paint.bands, baseInkHex: '#000000');
      } catch (e) {
        failures.add('p$page: transform threw $e');
        continue;
      }
      if (!out.contains('<svg')) failures.add('p$page: no <svg> after transform');
      if ('<g id="md-page" fill='.allMatches(out).length != 1) {
        failures.add('p$page: md-page fill count != 1');
      }
      // paths grow by exactly one clipped duplicate per madd band
      if ('<path '.allMatches(out).length !=
          '<path '.allMatches(raw).length + paint.bands.length) {
        failures.add('p$page: path count off by ${'<path '.allMatches(out).length - '<path '.allMatches(raw).length} (bands ${paint.bands.length})');
      }
      final cDefs = RegExp(r'<clipPath id="tjc\d+">').allMatches(out).length;
      final cRefs = RegExp(r'clip-path="url\(#tjc\d+\)"').allMatches(out).length;
      if (cDefs != cRefs || cDefs != paint.bands.length) {
        failures.add('p$page: clip defs $cDefs / refs $cRefs / bands ${paint.bands.length}');
      }
      // EVERY id resolveTajweedPaint counted as `direct` must actually be
      // present + coloured in the output — otherwise coverage over-reports
      // and a silently-uncoloured glyph is invisible.
      final colouredIds = RegExp(r'<path fill="#[0-9a-f]{6}" id="(md-path-[0-9A-Za-z-]+)"')
          .allMatches(out)
          .map((m) => m.group(1)!)
          .toSet();
      for (final id in paint.directFills.keys) {
        if (!colouredIds.contains(id)) {
          failures.add('p$page: directFills id "$id" not coloured in output');
        }
        // no fill landed on a non-glyph decoration
        if (id.contains('header') ||
            id.contains('page-number') ||
            id.contains('margin')) {
          failures.add('p$page: coloured a decoration $id');
        }
      }
    }

    // ---- write the report ----
    String pct(int n) =>
        total == 0 ? '0' : (100 * n / total).toStringAsFixed(1);
    final md = StringBuffer()
      ..writeln('# Tajwīd glyph-colouring coverage — v1 (Phase G-t v2)')
      ..writeln()
      ..writeln('**Glyph-level Tajwīd rendering.** The colour is injected on the')
      ..writeln('exact `<path>` of a glyph. MushafDatabase draws 2–10-letter')
      ..writeln('ligatures as one `<path>` and has no per-letter path, so v1')
      ..writeln('colours only what it can colour **precisely** — every covered')
      ..writeln('diacritic (wasla, shadda, maddah, superscript-alef, tanwīn,')
      ..writeln('sukūn…) and every single-letter ligature. The `[cs, ce)` span')
      ..writeln('data stays codepoint-exact.')
      ..writeln()
      ..writeln('- rule spans on the page art: **$total**')
      ..writeln('- **DIRECT** — colour on the exact glyph path: **$direct**  '
          '(${pct(direct)}%)')
      ..writeln('- **BAND** — المدّ only: a clip-path x-slice at the madd '
          "letter's position inside a whole-word ligature (never the whole "
          'word): **$band**  (${pct(band)}%)')
      ..writeln('- **SKIPPED** — non-madd rule inside a whole-word ligature '
          'with no anchor; black on the page, shown in the knowledge surface '
          '+ on tap: **$skip**  (${pct(skip)}%)')
      ..writeln()
      ..writeln('True per-letter colouring for the skipped spans needs a')
      ..writeln('different art source / an in-app Arabic-shaping renderer (v3).')
      ..writeln()
      ..writeln('## Per rule')
      ..writeln()
      ..writeln('| rule | direct | band | skipped |')
      ..writeln('|---|---|---|---|');
    final rules = byRule.keys.toList()
      ..sort((a, b) => (byRule[b]![0] + byRule[b]![1] + byRule[b]![2]) -
          (byRule[a]![0] + byRule[a]![1] + byRule[a]![2]));
    for (final r in rules) {
      final c = byRule[r]!;
      md.writeln('| `$r` | ${c[0]} | ${c[1]} | ${c[2]} |');
    }
    md
      ..writeln()
      ..writeln('## Skipped examples (${examples.length > 30 ? 30 : examples.length})')
      ..writeln()
      ..writeln('These rules land inside a whole-word ligature with no mark to')
      ..writeln('anchor to — not coloured on the page in v1:')
      ..writeln();
    for (final e in examples.take(30)) {
      md.writeln('- $e');
    }
    File(p.join('docs', 'quran', 'reports', 'TAJWEED_GLYPH_COVERAGE.md'))
        .writeAsStringSync(md.toString());

    expect(failures, isEmpty,
        reason: '${failures.length}:\n${failures.take(20).join('\n')}');
    expect(total, greaterThan(60000));
    // the precise majority is coloured; skips are the honest, tracked gap
    expect(direct, greaterThan(total * 0.7));
  });
}
