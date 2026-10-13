import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/widgets/mushaf/line_spread.dart';

/// «املأ الصفحة» — the line-spread mapping and the SVG split, on the real
/// V1.01 data: every word of sample pages must hit-test back to itself
/// through the spread mapping, lines must never overlap, glyphs keep one
/// scale, and each page splits into exactly its 15 line groups.
void main() {
  final layout = jsonDecode(utf8.decode(gzip.decode(
          File('assets/mushaf/mushaf_layout.json.gz').readAsBytesSync())))
      as Map<String, dynamic>;
  final pages = {
    for (final p in (layout['pages'] as List).cast<Map<String, dynamic>>())
      p['page'] as int: p,
  };

  Rect rectOf(Map<String, dynamic> p) {
    final r = (p['rect'] as List).cast<num>();
    return Rect.fromLTRB(r[0].toDouble(), r[1].toDouble(), r[2].toDouble(), r[3].toDouble());
  }

  for (final size in const [Size(360, 740), Size(412, 870), Size(800, 1280), Size(390, 600)]) {
    test('every word round-trips through the spread mapping at $size', () {
      for (final pg in const [3, 50, 187, 300, 581, 582, 604]) {
        final p = pages[pg]!;
        final t = LineSpreadTransform.fit(rect: rectOf(p), available: size);
        for (final w in (p['words'] as List).cast<Map<String, dynamic>>()) {
          final b = (w['b'] as List).cast<num>();
          final vb = Rect.fromLTWH(b[0].toDouble(), b[1].toDouble(), b[2].toDouble(), b[3].toDouble());
          final screen = t.toScreen(vb);
          final back = t.toViewBox(screen.center);
          expect(vb.inflate(0.01).contains(back), isTrue,
              reason: 'p$pg word ${w['s']}:${w['a']}#${w['w']} at $size');
        }
      }
    });
  }

  test('lines fill the height without overlapping, inside the screen', () {
    const size = Size(390, 844);
    final t = LineSpreadTransform.fit(rect: rectOf(pages[300]!), available: size);
    for (var i = 1; i < LineSpreadTransform.lines; i++) {
      expect(t.lineTop[i] - t.lineTop[i - 1], greaterThanOrEqualTo(t.pitch * t.scale - 0.001));
    }
    expect(t.lineTop.first, greaterThan(0));
    expect(t.lineTop.last + t.pitch * t.scale, lessThan(size.height));
    // the text fills the width: 3% side margins
    expect(rectOf(pages[300]!).width * t.scale, closeTo(size.width / 1.06, 0.5));
  });

  test('every page SVG splits into header, footer and exactly its 15 lines', () {
    for (final pg in const [3, 4, 77, 187, 300, 581, 582, 604]) {
      final svg = utf8.decode(gzip.decode(File(
              'assets/mushaf/pages_svg/${pg.toString().padLeft(3, '0')}.svg.gz')
          .readAsBytesSync()));
      final parts = splitMushafSvg(svg);
      expect(parts, isNotNull, reason: 'page $pg');
      expect(parts!.lines, hasLength(15));
      for (var i = 0; i < 15; i++) {
        final id = 'md-line-${(i + 1).toString().padLeft(2, '0')}';
        expect(parts.lines[i], contains('id="$id"'));
        // only its own line, and no header
        expect(RegExp('id="md-line-').allMatches(parts.lines[i]).length, 1, reason: '$pg $id');
        expect(parts.lines[i], isNot(contains('md-non-quranic-header')));
        expect(parts.lines[i].trimRight(), endsWith('</svg>'));
      }
      expect(parts.header, contains('md-non-quranic-header-surah-name'));
      expect(parts.header, isNot(contains('md-non-quranic-page-number')));
      expect(parts.footer, contains('md-non-quranic-page-number'));
      expect(parts.footer, isNot(contains('md-line-')));
      // nothing lost: the 15 pieces carry every word group of the page
      final words = RegExp(r'id="md-word-').allMatches(svg).length;
      final split = parts.lines.fold<int>(0, (n, l) => n + RegExp(r'id="md-word-').allMatches(l).length);
      expect(split, words, reason: 'page $pg');
    }
  });
}
