import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/widgets/mushaf/screen_transform.dart';

/// Phase 80 / M2 — `ScreenTransform` must reproduce the pre-M2 inline
/// `MushafPageView` fit math **exactly** (behaviour-preserving step), and its
/// coordinate round-trip must be lossless.
void main() {
  // The exact expressions `MushafPageView.build` used before M2, kept here as
  // the oracle.
  ({double scale, double dx, double dy}) legacy({
    required double cx,
    required double cy,
    required double cw,
    required double ch,
    required double maxW,
    required double maxH,
  }) {
    final scale = (maxW / cw) < (maxH / ch) ? (maxW / cw) : (maxH / ch);
    final dx = (maxW - cw * scale) / 2 - cx * scale;
    final dy = (maxH - ch * scale) / 2 - cy * scale;
    return (scale: scale, dx: dx, dy: dy);
  }

  group('ScreenTransform.fit reproduces the legacy formula bit-for-bit', () {
    final cases = <List<double>>[
      // cx, cy, cw, ch, maxW, maxH  — realistic mushaf frames + viewports
      [45.32, 73.57, 245.55, 399.50, 411, 812], // recto page, phone portrait
      [90.80, 74.61, 248.20, 400.46, 411, 812], // verso page, phone portrait
      [98.98, 103.34, 185.32, 341.16, 411, 812], // al-Fatiha (narrow)
      [45.0, 74.0, 245.9, 399.3, 800, 600], // width-limited (landscape)
      [43.0, 76.77, 249.04, 398.77, 1280, 800], // tablet
      [46.1, 73.87, 243.86, 399.31, 300, 300], // tiny square
      [0.0, 0.0, 382.68, 547.09, 411, 914], // whole viewBox
    ];

    for (final c in cases) {
      test('cx=${c[0]} cw=${c[2]} maxW=${c[4]} maxH=${c[5]}', () {
        final want = legacy(
          cx: c[0], cy: c[1], cw: c[2], ch: c[3], maxW: c[4], maxH: c[5],
        );
        final t = ScreenTransform.fit(
          fitLeft: c[0],
          fitTop: c[1],
          fitWidth: c[2],
          fitHeight: c[3],
          available: Size(c[4], c[5]),
        );
        expect(t.scale, want.scale);
        expect(t.offset.dx, want.dx);
        expect(t.offset.dy, want.dy);
      });
    }
  });

  test('toViewBox is the exact inverse the old toLocalViewBox used', () {
    final t = ScreenTransform.fit(
      fitLeft: 45.32,
      fitTop: 73.57,
      fitWidth: 245.55,
      fitHeight: 399.5,
      available: const Size(411, 812),
    );
    for (final p in const [Offset(0, 0), Offset(200, 500), Offset(410, 811)]) {
      final vb = t.toViewBox(p);
      // the pre-M2 expression, verbatim
      final wantVb = Offset(
        (p.dx - t.offset.dx) / t.scale,
        (p.dy - t.offset.dy) / t.scale,
      );
      expect(vb, wantVb);
    }
  });

  test('round-trip toScreen∘toViewBox is within 1e-9 px', () {
    final t = ScreenTransform.fit(
      fitLeft: 90.8,
      fitTop: 74.61,
      fitWidth: 248.2,
      fitHeight: 400.46,
      available: const Size(411, 812),
    );
    for (final r in const [
      Rect.fromLTWH(100, 100, 20, 8),
      Rect.fromLTWH(0, 0, 382.68, 547.09),
      Rect.fromLTWH(250.4, 300.1, 5.2, 12.7),
    ]) {
      final screen = t.toScreen(r);
      final back = t.toViewBox(screen.topLeft);
      expect((back.dx - r.left).abs(), lessThan(1e-9));
      expect((back.dy - r.top).abs(), lessThan(1e-9));
    }
  });

  test('aspect ratio is always preserved (one scalar scale)', () {
    for (final avail in const [Size(300, 900), Size(900, 300), Size(500, 500)]) {
      final t = ScreenTransform.fit(
        fitLeft: 45,
        fitTop: 74,
        fitWidth: 245,
        fitHeight: 399,
        available: avail,
      );
      final box = t.toScreen(const Rect.fromLTWH(0, 0, 100, 100));
      // a viewBox square stays a screen square (±Rect's own right-left ULPs)
      expect(box.width, closeTo(box.height, 1e-9));
      // the scale is a single scalar → aspect ratio preserved by construction
      final min = math.min(avail.width / 245, avail.height / 399);
      expect(t.scale, min);
    }
  });
}
