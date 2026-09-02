import 'dart:convert' show utf8;
import 'dart:io' show gzip;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../models/mushaf_layout.dart';

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

  /// Font family for the text fallback (pages without bundled art — none in
  /// the shipped build, kept for tests / safety).
  final String fontFamily;

  final Color textColor;

  /// When set, the (monochrome) MushafDatabase art is re-inked in this
  /// colour via `BlendMode.srcIn` — used for night reading. Null = the art's
  /// own black.
  final Color? artInk;

  /// Draw each word box outline — debugging / verification aid.
  final bool debugBoxes;

  const MushafPageView({
    super.key,
    required this.layout,
    this.selectedWord,
    this.selectedAyah,
    this.onWordTap,
    this.onAyaMarkTap,
    this.onWordLongPress,
    this.fontFamily = 'DigitalKhattMadina',
    this.textColor = const Color(0xFF1F2937),
    this.artInk,
    this.debugBoxes = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vbW = layout.viewBoxWidth;
        final vbH = layout.viewBoxHeight;
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : vbW;
        final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : vbH;

        // Fit the page's inked content to the viewport (see _contentBox) —
        // the hit-test, the art and the Selection Layer all share this exact
        // transform, so a tap lands on the same word the user sees.
        final content = _contentBox(layout);
        final cpad = 0.045 * (content.w > content.h ? content.w : content.h);
        final cx = content.x - cpad;
        final cy = content.y - cpad;
        final cw = content.w + 2 * cpad;
        final ch = content.h + 2 * cpad;
        final scale = (maxW / cw) < (maxH / ch) ? (maxW / cw) : (maxH / ch);
        final dx = (maxW - cw * scale) / 2 - cx * scale;
        final dy = (maxH - ch * scale) / 2 - cy * scale;

        Offset toLocalViewBox(Offset widgetLocal) => Offset(
              (widgetLocal.dx - dx) / scale,
              (widgetLocal.dy - dy) / scale,
            );

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
                    page: layout.page,
                    fallbackLines: _lines(layout),
                    scale: scale,
                    textColor: textColor,
                    artInk: artInk,
                    debugBoxes: debugBoxes,
                  ),
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
// Page art
// ─────────────────────────────────────────────────────────────────────────

/// True for every page — the full 604-page MushafDatabase V1.01 art set is
/// bundled gzipped under `assets/mushaf/pages_svg/NNN.svg.gz`. Kept as a
/// function (not a Set) so the text fallback path stays reachable if a file
/// is ever missing.
bool mushafArtBundled(int page) => page >= 1 && page <= 604;

/// The page's visual: the real MushafDatabase SVG (gzip-decoded at runtime),
/// else a line-by-line text fallback. Rendered inside a box that is exactly
/// the source viewBox scaled by [scale], so `BoxFit.fill` maps viewBox→box
/// 1:1 and stays locked to the hit-test transform.
class _PageArt extends StatefulWidget {
  final int page;
  final List<_RenderedLine> fallbackLines;
  final double scale;
  final Color textColor;
  final Color? artInk;
  final bool debugBoxes;
  const _PageArt({
    required this.page,
    required this.fallbackLines,
    required this.scale,
    required this.textColor,
    required this.artInk,
    required this.debugBoxes,
  });

  @override
  State<_PageArt> createState() => _PageArtState();
}

class _PageArtState extends State<_PageArt> {
  /// Decoded SVG string per page — small (a page is ~150–800 KB of text),
  /// and the reader only holds a few pages live at once.
  static final Map<int, String?> _cache = {};
  String? _svg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_PageArt old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page) {
      _svg = null;
      _load();
    }
  }

  Future<void> _load() async {
    final page = widget.page;
    if (_cache.containsKey(page)) {
      if (mounted) setState(() => _svg = _cache[page]);
      return;
    }
    String? svg;
    if (mushafArtBundled(page)) {
      try {
        final key =
            'assets/mushaf/pages_svg/${page.toString().padLeft(3, '0')}.svg.gz';
        final data = await rootBundle.load(key);
        svg = utf8.decode(gzip.decode(data.buffer.asUint8List()),
            allowMalformed: true);
        if (!svg.contains('<svg')) svg = null;
      } catch (e) {
        debugPrint('MushafPageView: no art for page $page ($e) — text fallback.');
        svg = null;
      }
    }
    _cache[page] = svg;
    if (mounted) setState(() => _svg = svg);
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svg;
    final ink = widget.artInk;
    if (svg != null) {
      return SvgPicture.string(
        svg,
        fit: BoxFit.fill,
        // Monochrome art → re-ink wholesale for night reading.
        colorFilter:
            ink == null ? null : ColorFilter.mode(ink, BlendMode.srcIn),
        placeholderBuilder: (_) => ColoredBox(
            color: ink == null ? const Color(0xFFFFFDF7) : Colors.transparent),
      );
    }
    if (mushafArtBundled(widget.page) && !_cache.containsKey(widget.page)) {
      // still decoding
      return ColoredBox(
          color: ink == null ? const Color(0xFFFFFDF7) : Colors.transparent);
    }
    // Fallback (page with no bundled art): each line at its own box.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final line in widget.fallbackLines)
          Positioned(
            left: line.box.x * widget.scale,
            top: line.box.y * widget.scale - line.box.h * widget.scale * 0.35,
            width: line.box.w * widget.scale,
            height: line.box.h * widget.scale * 1.7,
            child: Container(
              alignment: Alignment.center,
              decoration: widget.debugBoxes
                  ? BoxDecoration(
                      border: Border.all(
                          color: const Color(0x553B82F6), width: 0.5))
                  : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  line.text,
                  maxLines: 1,
                  softWrap: false,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: widget.textColor,
                    height: 1.0,
                    fontSize:
                        (line.box.h * widget.scale * 2.4).clamp(12.0, 60.0),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One printed line as a single RTL run + its box (viewBox units).
class _RenderedLine {
  final String text;
  final MushafBox box;
  const _RenderedLine(this.text, this.box);
}

List<_RenderedLine> _lines(MushafPageLayout layout) {
  final byLine = <int, List<MushafWord>>{};
  for (final w in layout.words) {
    byLine.putIfAbsent(w.line, () => []).add(w);
  }
  final out = <_RenderedLine>[];
  final lineNos = byLine.keys.toList()..sort();
  for (final ln in lineNos) {
    final ws = byLine[ln]!..sort((a, b) => a.wordOrder.compareTo(b.wordOrder));
    var minX = double.infinity, minY = double.infinity, maxR = 0.0, maxB = 0.0;
    for (final w in ws) {
      if (w.box.x < minX) minX = w.box.x;
      if (w.box.y < minY) minY = w.box.y;
      if (w.box.right > maxR) maxR = w.box.right;
      if (w.box.bottom > maxB) maxB = w.box.bottom;
    }
    out.add(_RenderedLine(
      ws.map((w) => w.textUthmani).join(' '),
      MushafBox(minX, minY, maxR - minX, maxB - minY),
    ));
  }
  return out;
}

/// The box (source viewBox units) to fit to the viewport, so the page fills
/// the screen instead of floating inside its wide print margins — kept
/// horizontally centred about the viewBox centre.
MushafBox _contentBox(MushafPageLayout layout) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  final textLineNos = <int>{};
  void add(MushafBox? x, {int? line}) {
    if (x == null || (x.w <= 0 && x.h <= 0)) return;
    if (x.x < minX) minX = x.x;
    if (x.y < minY) minY = x.y;
    if (x.right > maxX) maxX = x.right;
    if (x.bottom > maxY) maxY = x.bottom;
    if (line != null) textLineNos.add(line);
  }

  for (final w in layout.words) {
    add(w.box, line: w.line);
  }
  for (final m in layout.ayaMarks) {
    add(m.box);
  }
  for (final m in layout.markers) {
    add(m.box);
  }
  if (minX.isInfinite) {
    return MushafBox(0, 0, layout.viewBoxWidth, layout.viewBoxHeight);
  }

  final cxc = layout.viewBoxWidth / 2;
  final halfW = (cxc - minX).abs() > (maxX - cxc).abs()
      ? (cxc - minX).abs()
      : (maxX - cxc).abs();

  final lineH = textLineNos.length > 1
      ? (maxY - minY) / (textLineNos.length - 1)
      : (maxY - minY);
  final top = minY - lineH * 0.5;
  final bottom = maxY + lineH * 0.5;

  return MushafBox(cxc - halfW, top, halfW * 2, bottom - top);
}
