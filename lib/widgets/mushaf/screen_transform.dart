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
  /// to sit inside [available] pixels, centred, aspect ratio kept (one
  /// scalar — never stretched).
  ///
  /// [cover] (Ismail 2026-09-19: "لا أريد مساحة بيضاء" — the reader screen's
  /// own chrome is now an overlay, not a layout slot, so the page has the
  /// full screen and a phone's aspect ratio doesn't match a mushaf page's;
  /// containing would leave empty top/bottom bands). `false` (default) fits
  /// the whole page inside [available] (may letterbox); `true` fills
  /// [available] completely (may crop the page's own outer margin evenly on
  /// the excess axis — the caller must clip, `MushafPageView`'s `Clip
  /// .hardEdge` already does). Still one scalar either way: glyph shapes are
  /// identical, cover just picks the larger of the two candidate scales.
  ///
  /// ```
  /// scale = (cover ? max : min)(available.w / fitWidth, available.h / fitHeight)
  /// dx    = (available.w - fitWidth  * scale) / 2 - fitLeft * scale
  /// dy    = (available.h - fitHeight * scale) / 2 - fitTop  * scale
  /// ```
  factory ScreenTransform.fit({
    required double fitLeft,
    required double fitTop,
    required double fitWidth,
    required double fitHeight,
    required Size available,
    bool cover = false,
  }) {
    final sx = available.width / fitWidth;
    final sy = available.height / fitHeight;
    final scale = cover ? math.max(sx, sy) : math.min(sx, sy);
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
