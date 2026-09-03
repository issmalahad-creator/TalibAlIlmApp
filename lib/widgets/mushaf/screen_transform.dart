import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart' show immutable;

/// Phase 80 — the **one** bridge between a mushaf page's viewBox-unit
/// geometry and on-screen pixels.
///
/// A [ScreenTransform] is a single uniform [scale] plus a translation
/// [offset]: `screen = viewBox * scale + offset`. Because it is one scalar
/// scale, the aspect ratio is preserved by construction — there is no code
/// path here that can stretch a page. The renderer, the hit-test and the
/// selection overlay all take the *same* instance so they can never drift
/// apart. [MushafPageView] fits it to the mushaf's own 15-line content frame
/// (`md-page-inner data-rect`) + a uniform margin.
@immutable
class ScreenTransform {
  /// viewBox units → pixels. One scalar ⇒ aspect ratio always preserved.
  final double scale;

  /// Pixels added after scaling: `screen = viewBoxPoint * scale + offset`.
  final Offset offset;

  const ScreenTransform({required this.scale, required this.offset});

  /// Scale the viewBox-unit rectangle `(fitLeft, fitTop, fitWidth, fitHeight)`
  /// to sit fully inside [available] pixels, centred, aspect ratio kept.
  ///
  /// Takes raw doubles (not a [Rect]) so the arithmetic is exactly the pre-M2
  /// inline formula — no `right - left` round-trip:
  ///
  /// ```
  /// scale = min(available.w / fitWidth, available.h / fitHeight)
  /// dx    = (available.w - fitWidth  * scale) / 2 - fitLeft * scale
  /// dy    = (available.h - fitHeight * scale) / 2 - fitTop  * scale
  /// ```
  factory ScreenTransform.fit({
    required double fitLeft,
    required double fitTop,
    required double fitWidth,
    required double fitHeight,
    required Size available,
  }) {
    final sx = available.width / fitWidth;
    final sy = available.height / fitHeight;
    final scale = math.min(sx, sy);
    final dx = (available.width - fitWidth * scale) / 2 - fitLeft * scale;
    final dy = (available.height - fitHeight * scale) / 2 - fitTop * scale;
    return ScreenTransform(scale: scale, offset: Offset(dx, dy));
  }

  /// A viewBox-unit rectangle → its on-screen pixel rectangle.
  Rect toScreen(Rect viewBoxRect) => Rect.fromLTWH(
        offset.dx + viewBoxRect.left * scale,
        offset.dy + viewBoxRect.top * scale,
        viewBoxRect.width * scale,
        viewBoxRect.height * scale,
      );

  /// An on-screen pixel point (widget-local) → its point in viewBox units.
  Offset toViewBox(Offset screenPoint) => Offset(
        (screenPoint.dx - offset.dx) / scale,
        (screenPoint.dy - offset.dy) / scale,
      );

  @override
  bool operator ==(Object other) =>
      other is ScreenTransform &&
      other.scale == scale &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(scale, offset);

  @override
  String toString() => 'ScreenTransform(scale: $scale, offset: $offset)';
}
