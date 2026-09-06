import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/mushaf_layout.dart';
import 'mushaf/mushaf_page_cache.dart';
import 'mushaf/screen_transform.dart';

export 'mushaf/screen_transform.dart' show ScreenTransform;
export 'mushaf/mushaf_page_cache.dart' show MushafPageCache;

/// M3 — margin added around the `contentRect` (`md-page-inner data-rect`,
/// ~245 wide and uniform across all 604 pages) before fitting it to the
/// viewport, as a fraction of that width.
///
/// The bare 15-line block excludes the outer-margin furniture — the repeated
/// juz-name / surah-name headers and the foot page number. Measured across
/// all 604 pages, those overhang `data-rect` by at most **0.088** of its
/// width on either side (median 0.078). `0.09` brings every one of them back
/// on-screen while keeping the per-page centring (so the recto/verso gutter
/// shift stays cancelled) and still rendering larger than the pre-M3
/// `_contentBox`. The deep margin ornaments (rubʿ ۞ / sajda ۩) overhang much
/// further and are deliberately left in the margin (clipped) — that is where
/// the printed mushaf puts them.
const double _kContentRectPad = 0.09;

/// Phase 79 `79-mushaf` / خطة القارئ الموحّد — the **Rendering + Interaction
/// Layer**.
///
/// Draws one [MushafPageLayout] (real MushafDatabase V1.01 page art, all 604
/// pages bundled gzipped) and resolves a tap to exactly one target via a
/// **single page-level hit-test** against real `mushaf_*` geometry:
///
///   * tap inside a verse-end medallion box → [onAyaMarkTap] (ayah entry).
///   * tap inside a word body box → [onWordTap] (word entry).
///   * tap anywhere else → nothing (reading).
///
/// No proximity / nearest-word. No per-word `GestureDetector`. No knowledge
/// logic here — this widget knows only geometry and paints the Selection
/// Layer highlight it is told to show.
class MushafPageView extends StatelessWidget {
  final MushafPageLayout layout;

  /// The currently selected word — painted as the premium word highlight.
  final MushafWord? selectedWord;

  /// The currently selected ayah — painted as the (calmer) ayah highlight.
  final ({int surah, int ayah})? selectedAyah;

  /// Tap resolved to a word body.
  final void Function(MushafWord word)? onWordTap;

  /// Tap resolved to a verse-end medallion — the only path to an ayah selection.
  final void Function(MushafAyaMark mark)? onAyaMarkTap;

  /// Long-press on a word (future shortcut, e.g. ayah panel / notebook).
  final void Function(MushafWord word)? onWordLongPress;

  /// When set, the (monochrome) MushafDatabase art is re-inked in this
  /// colour via `BlendMode.srcIn` — used for night reading. Null = the art's
  /// own black.
  final Color? artInk;

  /// QC7 — a short ṣarf/iʿrāb line for [selectedWord], drawn as a small
  /// floating label in the line-gap **above** the word (never over the
  /// glyph ink; `IgnorePointer`, so no interaction impact). Null = nothing.
  final String? wordCaption;

  /// Phase G-t v2 — «وضع التجويد». When true, the page renders the
  /// **glyph-coloured** variant: `fill` injected on the exact `<path>` of
  /// each rule glyph (`MushafPageCache` + `paintTajweedIntoSvg`), and the
  /// wholesale night `ColorFilter` is dropped (the base ink is baked in).
  /// False = ordinary reading, byte-identical to before.
  final bool tajweed;

  const MushafPageView({
    super.key,
    required this.layout,
    this.selectedWord,
    this.selectedAyah,
    this.onWordTap,
    this.onAyaMarkTap,
    this.onWordLongPress,
    this.artInk,
    this.wordCaption,
    this.tajweed = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vbW = layout.viewBoxWidth;
        final vbH = layout.viewBoxHeight;
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : vbW;
        final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : vbH;

        // Fit the mushaf's own 15-line content frame (`md-page-inner
        // data-rect`, corrected in M1) — plus a uniform breathing margin
        // (`_kContentRectPad`) that keeps the juz/surah margin headers and
        // the foot page number on screen. Centring this per page cancels the
        // recto/verso gutter shift (the frame's width is uniform ~245 across
        // all 604 pages). One rule, no per-page logic. The hit-test, the art
        // and the Selection Layer all share this one transform.
        final r = layout.rect;
        final ({double left, double top, double width, double height}) fit;
        if (r != null && r.w > 0 && r.h > 0) {
          final pad = _kContentRectPad * r.w;
          fit = (
            left: r.x - pad,
            top: r.y - pad,
            width: r.w + 2 * pad,
            height: r.h + 2 * pad,
          );
        } else {
          // no content rect (never happens for the seeded 604 — QA-gated):
          // fall back to the whole viewBox rather than reconstructing text.
          fit = (left: 0, top: 0, width: vbW, height: vbH);
        }
        final t = ScreenTransform.fit(
          fitLeft: fit.left,
          fitTop: fit.top,
          fitWidth: fit.width,
          fitHeight: fit.height,
          available: Size(maxW, maxH),
        );
        final scale = t.scale;
        final dx = t.offset.dx;
        final dy = t.offset.dy;

        Offset toLocalViewBox(Offset widgetLocal) => t.toViewBox(widgetLocal);

        void handleTap(Offset widgetLocal) {
          if (onWordTap == null && onAyaMarkTap == null) return;
          final p = toLocalViewBox(widgetLocal);
          // Medallion first — the only ayah entry. Then the word body.
          final mark = layout.ayaMarkAtPoint(p.dx, p.dy);
          if (mark != null) {
            onAyaMarkTap?.call(mark);
            return;
          }
          final w = layout.wordAtPoint(p.dx, p.dy);
          if (w != null) onWordTap?.call(w);
        }

        void handleLongPress(Offset widgetLocal) {
          if (onWordLongPress == null) return;
          final p = toLocalViewBox(widgetLocal);
          final w = layout.wordAtPoint(p.dx, p.dy);
          if (w != null) onWordLongPress!.call(w);
        }

        final sel = selectedAyah;
        final ayahBoxes = sel == null
            ? const <MushafBox>[]
            : layout.ayahBoxes(sel.surah, sel.ayah);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => handleTap(d.localPosition),
          onLongPressStart: (d) => handleLongPress(d.localPosition),
          child: SizedBox(
            width: maxW,
            height: maxH,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: dx,
                  top: dy,
                  width: vbW * scale,
                  height: vbH * scale,
                  child: _PageArt(
                      page: layout.page, artInk: artInk, tajweed: tajweed),
                ),
                // Selection Layer — premium highlight over the art, never
                // touches the SVG, never darkens the glyph ink.
                Positioned.fill(
                  child: _SelectionOverlay(
                    wordBox: selectedWord?.box,
                    ayahBoxes: ayahBoxes,
                    scale: scale,
                    offset: Offset(dx, dy),
                  ),
                ),
                // QC7 — the on-page ṣarf/iʿrāb label, in the gap above the
                // word. IgnorePointer + placed clear of the glyph ink.
                if (selectedWord != null &&
                    (wordCaption?.trim().isNotEmpty ?? false))
                  _WordCaption(
                    box: selectedWord!.box,
                    text: wordCaption!.trim(),
                    scale: scale,
                    offset: Offset(dx, dy),
                    available: Size(maxW, maxH),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Selection Layer
// ─────────────────────────────────────────────────────────────────────────

/// Gold accent — `DepthPalette.quran.accent`, the single mushaf colour.
const Color _kGold = Color(0xFFD9A441);

/// Animated highlight for the current word / ayah. `docs/quran/QURAN_PREMIUM_UI.md`
/// §3: word = gold fill 0.10–0.14 + 1px gold stroke, grow-in 180ms; ayah =
/// calmer per-line fill 0.06–0.08, no stroke.
class _SelectionOverlay extends StatefulWidget {
  final MushafBox? wordBox;
  final List<MushafBox> ayahBoxes;
  final double scale;
  final Offset offset;
  const _SelectionOverlay({
    required this.wordBox,
    required this.ayahBoxes,
    required this.scale,
    required this.offset,
  });

  @override
  State<_SelectionOverlay> createState() => _SelectionOverlayState();
}

class _SelectionOverlayState extends State<_SelectionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  bool get _hasSelection => widget.wordBox != null || widget.ayahBoxes.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasSelection) _c.value = 1;
  }

  @override
  void didUpdateWidget(_SelectionOverlay old) {
    super.didUpdateWidget(old);
    final was = old.wordBox != null || old.ayahBoxes.isNotEmpty;
    if (_hasSelection && !was) {
      _c.forward(from: 0);
    } else if (_hasSelection &&
        (old.wordBox?.x != widget.wordBox?.x ||
            old.wordBox?.y != widget.wordBox?.y)) {
      _c.forward(from: 0); // moved to a new word → replay grow-in
    } else if (!_hasSelection && was) {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) => CustomPaint(
          painter: _SelectionPainter(
            wordBox: widget.wordBox,
            ayahBoxes: widget.ayahBoxes,
            scale: widget.scale,
            offset: widget.offset,
            t: _t.value,
          ),
        ),
      ),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  final MushafBox? wordBox;
  final List<MushafBox> ayahBoxes;
  final double scale;
  final Offset offset;
  final double t; // 0..1 entrance

  _SelectionPainter({
    required this.wordBox,
    required this.ayahBoxes,
    required this.scale,
    required this.offset,
    required this.t,
  });

  Rect _rect(MushafBox b, double grow) => Rect.fromLTWH(
        offset.dx + b.x * scale - grow,
        offset.dy + b.y * scale - grow,
        b.w * scale + grow * 2,
        b.h * scale + grow * 2,
      );

  @override
  void paint(Canvas canvas, Size size) {
    // Ayah — calm, per line, no stroke.
    if (ayahBoxes.isNotEmpty) {
      final fill = Paint()..color = _kGold.withValues(alpha: 0.07 * t);
      for (final b in ayahBoxes) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(_rect(b, 1.5), const Radius.circular(3)),
          fill,
        );
      }
    }
    // Word — gold wash + thin gold stroke, scales in about its centre.
    final wb = wordBox;
    if (wb != null) {
      final r = _rect(wb, 1.5);
      final s = 0.96 + 0.04 * t;
      canvas.save();
      canvas.translate(r.center.dx, r.center.dy);
      canvas.scale(s);
      canvas.translate(-r.center.dx, -r.center.dy);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
      canvas.drawRRect(rr, Paint()..color = _kGold.withValues(alpha: 0.13 * t));
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _kGold.withValues(alpha: 0.30 * t),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter o) =>
      o.wordBox?.x != wordBox?.x ||
      o.wordBox?.y != wordBox?.y ||
      o.ayahBoxes != ayahBoxes ||
      o.scale != scale ||
      o.offset != offset ||
      o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────
// QC7 — on-page ṣarf/iʿrāb label
// ─────────────────────────────────────────────────────────────────────────

/// A small label anchored to [box], placed in the line-gap **above** the
/// word (flips below only if it would clip the page top). `IgnorePointer`,
/// translucent card with a hairline gold edge — it sits clear of the glyph
/// ink and never affects the hit-test.
class _WordCaption extends StatelessWidget {
  final MushafBox box;
  final String text;
  final double scale;
  final Offset offset;
  final Size available;
  const _WordCaption({
    required this.box,
    required this.text,
    required this.scale,
    required this.offset,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final wx = offset.dx + box.x * scale;
    final wy = offset.dy + box.y * scale;
    final ww = box.w * scale;
    final wh = box.h * scale;
    const chipH = 20.0;
    const gap = 4.0;
    double top = wy - gap - chipH;
    if (top < 4) top = wy + wh + gap; // word on the top line → place below
    final cx = (wx + ww / 2).clamp(0.0, available.width);
    final frac =
        available.width <= 0 ? 0.0 : ((cx / available.width) * 2 - 1);
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(text),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          tween: Tween(begin: 0, end: 1),
          builder: (_, v, child) =>
              Opacity(opacity: v.clamp(0.0, 1.0), child: child),
          child: Align(
            alignment: Alignment(frac.clamp(-1.0, 1.0), 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: available.width * 0.82),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xF7FFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _kGold.withValues(alpha: 0.45)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 6,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.2,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Page art
// ─────────────────────────────────────────────────────────────────────────

/// True for every page — the full 604-page MushafDatabase V1.01 art set is
/// bundled gzipped under `assets/mushaf/pages_svg/NNN.svg.gz`. Kept as a
/// function (not a Set) so the text fallback path stays reachable if a file
/// is ever missing.
bool mushafArtBundled(int page) => page >= 1 && page <= 604;

/// The page's visual: the real MushafDatabase V1.01 SVG, decoded by
/// [MushafPageCache] off the UI isolate. Placed inside a box that is exactly
/// `viewBox × scale` (see [MushafPageView.build]), so `BoxFit.fill` maps
/// viewBox→box 1:1 and stays locked to the hit-test transform. No text
/// reconstruction — every one of the 604 pages is bundled and QA-gated.
class _PageArt extends StatefulWidget {
  final int page;
  final Color? artInk;
  final bool tajweed;
  const _PageArt(
      {required this.page, required this.artInk, this.tajweed = false});

  @override
  State<_PageArt> createState() => _PageArtState();
}

class _PageArtState extends State<_PageArt> {
  /// M4: decode + LRU + preload live in [MushafPageCache] (background isolate).
  final _cache = MushafPageCache.instance;
  String? _svg;

  /// The base-ink hex baked into the tajwīd variant — the same colour the
  /// non-tajwīd path re-inks the whole picture with (`artInk`), so nothing
  /// diverges if that colour is ever themed.
  String get _baseInkHex {
    final ink = widget.artInk;
    if (ink == null) return '#000000';
    return '#${(ink.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_PageArt old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page ||
        old.tajweed != widget.tajweed ||
        old.artInk?.toARGB32() != widget.artInk?.toARGB32()) {
      _svg = null;
      _load();
    }
  }

  Future<void> _load() async {
    final page = widget.page;
    final tj = widget.tajweed;
    if (!tj && _cache.has(page)) {
      _svg = _cache.peek(page);
      if (mounted) setState(() {});
    } else {
      final svg =
          await _cache.load(page, tajweed: tj, baseInkHex: _baseInkHex);
      if (!mounted || widget.page != page || widget.tajweed != tj) return;
      setState(() => _svg = svg);
    }
    _cache.preloadAround(page);
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svg;
    final ink = widget.artInk;
    if (svg != null) {
      return SvgPicture.string(
        svg,
        fit: BoxFit.fill,
        // Monochrome art → re-ink wholesale for night reading. In tajwīd
        // mode the ink (+ colours) are baked into the string by
        // `paintTajweedIntoSvg`, so no filter — it would flatten the hues.
        colorFilter: (ink == null || widget.tajweed)
            ? null
            : ColorFilter.mode(ink, BlendMode.srcIn),
        placeholderBuilder: (_) => ColoredBox(
            color: ink == null ? const Color(0xFFFFFDF7) : Colors.transparent),
      );
    }
    // still decoding (or the vanishingly rare decode failure) — a warm
    // placeholder, never a hard blank and never a text reconstruction.
    return ColoredBox(
        color: ink == null ? const Color(0xFFFFFDF7) : Colors.transparent);
  }
}
