import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

/// «املأ الصفحة» (Ismail 2026-10-10, with reference screenshots): the 15
/// lines of a Madani page spread evenly down the whole screen, the text
/// filling the width — instead of one uniform scale that leaves empty bands
/// above and below the text block on a tall phone.
///
/// Glyphs are never stretched: every line keeps ONE scale [scale]; only the
/// vertical position of each line changes. Each line is drawn from its own
/// `<g id="md-line-NN">` group ([splitMushafSvg]), so no ink is clipped.
/// The juzʼ/surah header and the page number (`md-page-outer`) are drawn
/// as their own pieces at the top and bottom.
///
/// The renderer, the hit-test and the Selection Layer all go through this
/// one mapping, exactly as they go through `ScreenTransform` otherwise.
class LineSpreadTransform {
  /// viewBox → pixels for the text lines (one scalar: glyph shapes kept).
  final double scale;

  /// x offset for the text lines: `screenX = vbX * scale + dx`.
  final double dx;

  /// Top of the 15-line frame in viewBox units, and one line's pitch.
  final double vbTop;
  final double pitch;

  /// Screen y where line i's band top (`vbTop + i * pitch`) lands.
  final List<double> lineTop;

  /// Screen slot height of one line (≥ `pitch * scale`).
  final double slotH;
  final double areaTop;

  /// The header / page-number pieces: their own uniform transform each
  /// (`screen = vb * outerScale + offset`), wide enough for the headers'
  /// side overhang.
  final double outerScale;
  final Offset headerOffset;
  final Offset footerOffset;

  const LineSpreadTransform._({
    required this.scale,
    required this.dx,
    required this.vbTop,
    required this.pitch,
    required this.lineTop,
    required this.slotH,
    required this.areaTop,
    required this.outerScale,
    required this.headerOffset,
    required this.footerOffset,
  });

  static const lines = 15;

  /// Side margin of the text, as a fraction of the frame width.
  static const padX = 0.03;

  /// Header band above the frame and page-number band below it, in frame
  /// widths — measured on the V1.01 art: header ink spans 0.164–0.262 w
  /// above the frame, the page number 0.164–0.210 w below; both overhang
  /// the frame sideways by ≤ 0.085 w.
  static const headerFrom = 0.275, headerTo = 0.155;
  static const footerFrom = 0.150, footerTo = 0.225;
  static const outerPadX = 0.10;

  /// [rect] = the page's `md-page-inner` frame (x, y, w, h) in viewBox units.
  factory LineSpreadTransform.fit({
    required Rect rect,
    required Size available,
    double margin = 6,
  }) {
    final w = rect.width;
    final outerScale = available.width / (w * (1 + 2 * outerPadX));
    final headerH = (headerFrom - headerTo) * w * outerScale;
    final footerH = (footerTo - footerFrom) * w * outerScale;
    final areaTop = margin + headerH;
    final areaBottom = available.height - margin - footerH;
    final area = math.max(0.0, areaBottom - areaTop);
    final pitch = rect.height / lines;
    // as wide as the screen allows, but never taller than a line's slot
    final scale = math.min(available.width / (w * (1 + 2 * padX)), area / (lines * pitch));
    final slotH = area / lines;
    final dx = (available.width - w * scale) / 2 - rect.left * scale;
    final lineTop = [
      for (var i = 0; i < lines; i++) areaTop + i * slotH + (slotH - pitch * scale) / 2,
    ];
    final odx = (available.width - w * outerScale) / 2 - rect.left * outerScale;
    return LineSpreadTransform._(
      scale: scale,
      dx: dx,
      vbTop: rect.top,
      pitch: pitch,
      lineTop: lineTop,
      slotH: slotH,
      areaTop: areaTop,
      outerScale: outerScale,
      headerOffset: Offset(odx, margin - (rect.top - headerFrom * w) * outerScale),
      footerOffset: Offset(odx, areaBottom - (rect.bottom + footerFrom * w) * outerScale),
    );
  }

  /// The line (0..14) a viewBox y belongs to.
  int lineOf(double vbY) => ((vbY - vbTop) / pitch).floor().clamp(0, lines - 1);

  /// Screen y of viewBox y, as drawn in line [i].
  double _y(double vbY, int i) => lineTop[i] + (vbY - (vbTop + i * pitch)) * scale;

  /// Where line [i]'s full-page picture must be placed so its own band
  /// lands at [lineTop] — the picture spans the whole viewBox.
  Offset lineOrigin(int i) => Offset(dx, lineTop[i] - (vbTop + i * pitch) * scale);

  /// A viewBox rect (a word, a medallion, an ayah's line box) on screen, in
  /// the line its centre belongs to.
  Rect toScreen(Rect vb) {
    final i = lineOf(vb.center.dy);
    return Rect.fromLTWH(dx + vb.left * scale, _y(vb.top, i), vb.width * scale, vb.height * scale);
  }

  /// A widget-local point → viewBox units, through the line slot it is in.
  Offset toViewBox(Offset p) {
    final i = ((p.dy - areaTop) / slotH).floor().clamp(0, lines - 1);
    return Offset((p.dx - dx) / scale, vbTop + i * pitch + (p.dy - lineTop[i]) / scale);
  }
}

/// The pieces of one page SVG for [LineSpreadTransform]: [header] = the
/// juzʼ/surah header only, [footer] = the page number only, [lines][i] =
/// only `md-line-(i+1)`. Each piece
/// is a complete SVG with the page's full viewBox, so it is placed exactly
/// like the whole page. Null when the art doesn't have the V1.01 structure
/// (the caller falls back to the whole page).
///
/// Plain string surgery over the known group ids (no XML parse of a
/// ~700 KB page); pure, so it runs inside the page cache's isolate.
({String header, String footer, List<String> lines})? splitMushafSvg(String svg) {
  ({int start, int end})? span(String id) {
    final start = svg.indexOf('<g id="$id"');
    if (start < 0) return null;
    var depth = 0;
    var i = start;
    while (i < svg.length) {
      final open = svg.indexOf('<g', i);
      final close = svg.indexOf('</g>', i);
      if (close < 0) return null;
      if (open >= 0 && open < close) {
        // `<g` followed by a space or `>` — not `<glyph` etc.
        final c = svg.codeUnitAt(open + 2);
        if (c == 0x20 || c == 0x3E || c == 0x0A || c == 0x09) depth++;
        i = open + 2;
      } else {
        depth--;
        i = close + 4;
        if (depth == 0) return (start: start, end: i);
      }
    }
    return null;
  }

  final lineSpans = <({int start, int end})>[];
  for (var n = 1; n <= LineSpreadTransform.lines; n++) {
    final s = span('md-line-${n.toString().padLeft(2, '0')}');
    if (s == null) return null;
    lineSpans.add(s);
  }
  final margin = span('md-non-quranic-margin-juz-hisb');
  final number = span('md-non-quranic-page-number');
  final surahHead = span('md-non-quranic-header-surah-name');
  final juzHead = span('md-non-quranic-header-juz-name');
  if (number == null) return null;

  String without(List<({int start, int end})> cut) {
    final sorted = [...cut]..sort((a, b) => a.start.compareTo(b.start));
    final b = StringBuffer();
    var at = 0;
    for (final c in sorted) {
      b.write(svg.substring(at, c.start));
      at = c.end;
    }
    b.write(svg.substring(at));
    return b.toString();
  }

  // The outer pieces (the margin ornament sits beside a text line and has
  // no place in the spread layout).
  final header = without([...lineSpans, ?margin, number]);
  final footer = without([...lineSpans, ?margin, ?surahHead, ?juzHead]);
  // Each line: the svg up to the first line, that line's group, then the
  // closing tail after the last line (closes md-page-inner / md-page / svg).
  final head = svg.substring(0, lineSpans.first.start);
  final tail = svg.substring(lineSpans.last.end);
  final outerStart = svg.indexOf('<g id="md-page-outer"');
  final innerStart = svg.indexOf('<g id="md-page-inner"');
  if (outerStart < 0 || innerStart < 0 || innerStart > lineSpans.first.start) return null;
  // drop md-page-outer (headers) from the line pieces
  final headNoOuter = head.substring(0, outerStart) + head.substring(innerStart);
  return (
    header: header,
    footer: footer,
    lines: [for (final s in lineSpans) headNoOuter + svg.substring(s.start, s.end) + tail],
  );
}
