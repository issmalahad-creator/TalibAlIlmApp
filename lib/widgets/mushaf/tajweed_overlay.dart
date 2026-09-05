import 'package:flutter/material.dart';

import '../../models/mushaf_layout.dart';
import '../../models/tajweed_span.dart';
import '../../theme/tajweed_palette.dart';

/// Phase G-t3 · the opt-in tajwīd colour layer on the muṣḥaf page.
///
/// **Documented carve-out** to `docs/quran/QURAN_PREMIUM_UI.md` §4/§8/§10
/// (one gold colour; nothing over the ink above 0.15 alpha): §8-bis allows
/// this translucent family-colour wash, and only this, **while «وضع
/// التجويد» is on** (a user toggle, off by default). Ordinary reading is
/// unchanged. No glow, no gradient, no coloured shadow, no motion beyond a
/// plain rebuild.
///
/// Placed in the page Stack **above `_PageArt`, below the Selection Layer**,
/// as an `IgnorePointer` `CustomPaint` — the hit-test is untouched (a tap on
/// a coloured glyph still selects the word).

/// One rule occurrence, already resolved to a family colour + a run of
/// boxes in source viewBox units. Precomputed once per page by
/// [buildTajweedPaintSpans]; the painter only does `box * scale + offset`.
class TajweedPaintSpan {
  final List<MushafBox> boxes;
  final Color color; // family accent — the painter applies the alpha
  final bool underline; // point rules: a baseline rule, not a wash
  const TajweedPaintSpan({
    required this.boxes,
    required this.color,
    required this.underline,
  });

  /// The single box that covers this whole run (boxes are a contiguous run
  /// of glyphs within one word).
  MushafBox get bounds {
    var b = boxes.first;
    for (final o in boxes.skip(1)) {
      b = b.union(o);
    }
    return b;
  }
}

/// Point rules — coloured by a thin baseline rule under the letter rather
/// than a wash (a single silent / bounced letter, not a stretch of sound).
const Set<String> kTajweedUnderlineRules = {
  'hamzat_wasl',
  'silent',
  'qalqalah',
};

/// Precompute the page's paint spans. Frame-free — call once when a page
/// (and the tajwīd data + glyph geometry) has loaded.
///
/// - [words]              `layout.words` for the page
/// - [tajweedByAyah]      `"$surah:$ayah" -> AyahTajweed` for every ayah on it
/// - [glyphsByWordOrder]  `MushafLayoutRepository.glyphsForPage(page)` (may be
///   empty — then the whole word box is washed as a fallback)
List<TajweedPaintSpan> buildTajweedPaintSpans({
  required List<MushafWord> words,
  required Map<String, AyahTajweed> tajweedByAyah,
  required Map<int, MushafWordGlyphs> glyphsByWordOrder,
}) {
  final out = <TajweedPaintSpan>[];
  for (final w in words) {
    if (w.type != MushafWordType.text) continue;
    final at = tajweedByAyah['${w.surah}:${w.ayah}'];
    if (at == null || at.isEmpty) continue;
    final wordSpans = at.forWord(w.wordIndex);
    if (wordSpans.isEmpty) continue;
    final wg = glyphsByWordOrder[w.wordOrder];

    for (final sp in wordSpans) {
      List<MushafBox> boxes;
      if (wg != null && wg.glyphs.isNotEmpty) {
        final run = wg.runForCharRange(sp.cs, sp.ce);
        boxes = run.isEmpty
            ? <MushafBox>[w.box]
            : [for (final g in run) g.box];
      } else {
        boxes = <MushafBox>[w.box];
      }
      out.add(TajweedPaintSpan(
        boxes: boxes,
        color: TajweedPalette.accentOf(sp.familyKey),
        underline: kTajweedUnderlineRules.contains(sp.ruleId),
      ));
    }
  }
  return out;
}

class TajweedPageOverlay extends StatelessWidget {
  final List<TajweedPaintSpan> spans;
  final double scale;
  final Offset offset;
  final bool night;

  const TajweedPageOverlay({
    super.key,
    required this.spans,
    required this.scale,
    required this.offset,
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _TajweedPainter(
          spans: spans,
          scale: scale,
          offset: offset,
          night: night,
        ),
      ),
    );
  }
}

class _TajweedPainter extends CustomPainter {
  final List<TajweedPaintSpan> spans;
  final double scale;
  final Offset offset;
  final bool night;

  _TajweedPainter({
    required this.spans,
    required this.scale,
    required this.offset,
    required this.night,
  });

  // §8-bis: the lowest opacity that still reads as a colour; night sits a
  // little higher against the dark ground.
  double get _washAlpha => night ? 0.30 : 0.24;

  Rect _rect(MushafBox b) => Rect.fromLTWH(
        offset.dx + b.x * scale,
        offset.dy + b.y * scale,
        b.w * scale,
        b.h * scale,
      );

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in spans) {
      final r = _rect(s.bounds);
      if (s.underline) {
        final y = r.bottom + 1.0;
        canvas.drawRect(
          Rect.fromLTWH(r.left, y, r.width, 1.5),
          Paint()..color = s.color.withValues(alpha: 0.85),
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.inflate(0.5), const Radius.circular(2)),
          Paint()..color = s.color.withValues(alpha: _washAlpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TajweedPainter o) =>
      !identical(o.spans, spans) ||
      o.scale != scale ||
      o.offset != offset ||
      o.night != night;
}
