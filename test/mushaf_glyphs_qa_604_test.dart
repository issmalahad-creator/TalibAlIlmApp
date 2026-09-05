import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_repository.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_sync.dart';

/// Phase G-t2 — the 604/604 gate on `assets/mushaf/mushaf_glyphs.json.gz`
/// (`tool/extract_mushaf_glyphs.py`). Every sub-word glyph box must sit
/// inside its word's layout box; char spans must be in-bounds and
/// non-decreasing; every text word must have a base ligature UNLESS its
/// Uthmani text is a single lone pause mark.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Map<int, Map<int, ({List<double> box, String hafs})>> layoutWords;
  late Map<String, dynamic> glyphs;

  setUpAll(() {
    // layout: (page -> word_order -> {box, hafs})
    final lay = jsonDecode(utf8.decode(gzip.decode(File(p.join(
            'assets', 'mushaf', 'mushaf_layout.json.gz'))
        .readAsBytesSync()))) as Map<String, dynamic>;
    layoutWords = {};
    for (final pg in (lay['pages'] as List)) {
      final m = pg as Map<String, dynamic>;
      final wm = <int, ({List<double> box, String hafs})>{};
      for (final w in (m['words'] as List)) {
        final wo = w as Map<String, dynamic>;
        final b = (wo['b'] as List?)?.map((e) => (e as num).toDouble()).toList();
        wm[(wo['o'] as num).toInt()] = (
          box: b ?? const [0, 0, 0, 0],
          hafs: wo['hafs'] as String? ?? '',
        );
      }
      layoutWords[(m['page'] as num).toInt()] = wm;
    }

    glyphs = jsonDecode(utf8.decode(gzip.decode(File(p.join(
            'assets', 'mushaf', 'mushaf_glyphs.json.gz'))
        .readAsBytesSync()))) as Map<String, dynamic>;
  });

  bool inside(List<num> g, List<double> w, [double eps = 0.75]) {
    final gx = g[0].toDouble(),
        gy = g[1].toDouble(),
        gw = g[2].toDouble(),
        gh = g[3].toDouble();
    return gx >= w[0] - eps &&
        gy >= w[1] - eps &&
        gx + gw <= w[0] + w[2] + eps &&
        gy + gh <= w[1] + w[3] + eps;
  }

  test('604 pages, every glyph box ⊆ its word box, spans valid + monotonic', () {
    final pages = (glyphs['pages'] as List);
    expect(pages, hasLength(604));

    var totalGlyphs = 0;
    var wordsNoBase = 0;
    var maxPerWord = 0;
    final failures = <String>[];

    for (final pg in pages) {
      final m = pg as Map<String, dynamic>;
      final page = (m['p'] as num).toInt();
      final lw = layoutWords[page]!;
      for (final w in (m['words'] as List)) {
        final wo = w as Map<String, dynamic>;
        final order = (wo['o'] as num).toInt();
        final n = (wo['n'] as num).toInt();
        final gs = (wo['g'] as List).cast<Map<String, dynamic>>();
        final info = lw[order];
        expect(info, isNotNull, reason: 'p$page word_order $order not in layout');

        totalGlyphs += gs.length;
        if (gs.length > maxPerWord) maxPerWord = gs.length;

        final bases = gs.where((g) => (g['k'] as num) == 0).length;
        if (bases == 0) {
          wordsNoBase++;
          // acceptable only when the word IS a single combining pause mark
          final h = info!.hafs;
          if (!(h.runes.length == 1)) {
            failures.add('p$page o$order: no base glyph, hafs="$h"');
          }
          continue;
        }

        var lastCs = -1;
        for (final g in gs) {
          final cs = (g['cs'] as num).toInt();
          final ce = (g['ce'] as num).toInt();
          if (cs < 0 || ce <= cs || ce > n) {
            failures.add('p$page o$order: bad span [$cs,$ce) n=$n');
          }
          if (cs < lastCs) {
            failures.add('p$page o$order: cs went backwards ($cs < $lastCs)');
          }
          lastCs = cs;
          final b = (g['b'] as List).cast<num>();
          if (!inside(b, info!.box)) {
            failures.add('p$page o$order: glyph $b outside word ${info.box}');
          }
        }
      }
    }

    expect(failures, isEmpty,
        reason: '${failures.length} failures:\n${failures.take(25).join('\n')}');
    expect(totalGlyphs, greaterThan(400000));
    expect(maxPerWord, lessThanOrEqualTo(40));
    // the ~4.3k lone-pause-mark words are the only baseless ones
    expect(wordsNoBase, lessThan(6000));
  });

  test('MushafLayoutSync seeds mushaf_glyphs; repo run-for-range works', () async {
    DatabaseHelper.databaseName = 'talib_mushaf_glyphs_qa.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    final res = await MushafLayoutSync().sync();
    expect(res.outcome, anyOf('seeded', 'up-to-date'));

    final repo = MushafLayoutRepository();
    final page1 = await repo.glyphsForPage(1);
    expect(page1, isNotEmpty);
    // word 2 of al-Fātiḥa 1:1 on page 1 is "ٱللَّهِ" — it has ≥1 base ligature
    final anyWord = page1.values.firstWhere((w) => w.glyphs.isNotEmpty);
    expect(anyWord.glyphs.any((g) => g.isBase), isTrue);
    final run = anyWord.runForCharRange(0, 1);
    expect(run, isNotEmpty);
    for (final g in run) {
      expect(g.box.w, greaterThanOrEqualTo(0));
    }
  });
}
