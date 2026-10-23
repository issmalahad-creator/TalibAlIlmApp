import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_theme.dart';

/// One resolved, drawable study-annotation highlight over a page's text
/// (Phase 79 «علامات الدراسة», Phase B). `start`/`end` are UTF-16 offsets
/// into the same normalised string the reader renders — the FULL span the
/// user selected, not a fragment.
class PageHighlight {
  final int annotationId;
  final int start;
  final int end;
  final String colorKey;
  const PageHighlight({
    required this.annotationId,
    required this.start,
    required this.end,
    required this.colorKey,
  });
}

/// A run of the page text: a slice `[start, end)` that is either plain or
/// covered by exactly one annotation (the newest, when highlights overlap).
class TextRun {
  final int start;
  final int end;
  final int? annotationId;
  final String? colorKey;
  const TextRun(this.start, this.end, {this.annotationId, this.colorKey});
  bool get covered => annotationId != null;
}

/// Split [textLength] characters into consecutive [TextRun]s at every
/// highlight boundary. Where highlights overlap, the one with the **highest
/// annotationId** (most recently created) owns the shared sub-run — its
/// colour is shown and its id is the tap target there. Highlights are
/// clamped to `[0, textLength]`; empty or inverted ones are dropped.
List<TextRun> buildAnnotatedRuns(int textLength, List<PageHighlight> highlights) {
  if (textLength <= 0) return const [];
  final clamped = <PageHighlight>[];
  for (final h in highlights) {
    final s = h.start.clamp(0, textLength);
    final e = h.end.clamp(0, textLength);
    if (e > s) {
      clamped.add(PageHighlight(annotationId: h.annotationId, start: s, end: e, colorKey: h.colorKey));
    }
  }
  if (clamped.isEmpty) return [TextRun(0, textLength)];

  final boundaries = <int>{0, textLength};
  for (final h in clamped) {
    boundaries
      ..add(h.start)
      ..add(h.end);
  }
  final points = boundaries.toList()..sort();

  final runs = <TextRun>[];
  for (var i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];
    if (b <= a) continue;
    // Every highlight covering this whole sub-run; newest id wins.
    PageHighlight? winner;
    for (final h in clamped) {
      if (h.start <= a && h.end >= b) {
        if (winner == null || h.annotationId > winner.annotationId) winner = h;
      }
    }
    runs.add(winner == null
        ? TextRun(a, b)
        : TextRun(a, b, annotationId: winner.annotationId, colorKey: winner.colorKey));
  }
  return runs;
}

/// A compact index of the study annotations on the current page — a
/// coloured chip per annotation, tapping one opens it. This is the
/// guaranteed way to reach an annotation even where a tap on the
/// highlighted text itself doesn't register (Phase B risk R2), and doubles
/// as a quick "what did I mark on this page" overview.
class PageMarksBar extends StatelessWidget {
  /// (annotationId, colorKey, label) per drawable annotation, in reading order.
  final List<(int, String, String)> marks;
  final void Function(int annotationId) onTap;

  const PageMarksBar({super.key, required this.marks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (marks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (id, colorKey, label) in marks)
            ActionChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: CircleAvatar(backgroundColor: AppColors.studyAnnotation(colorKey).$3, radius: 6),
              label: Text(
                label,
                textDirection: TextDirection.rtl,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
              onPressed: () => onTap(id),
            ),
        ],
      ),
    );
  }
}

/// `SelectableText.rich` for a Turath page with study-annotation highlights
/// drawn as translucent `backgroundColor` runs. A `backgroundColor` on a
/// `TextSpan` paints behind every glyph of the run and wraps across every
/// visual line the span covers — so a selection that ran from mid-line-1 to
/// mid-line-3 shows as one continuous marker stroke, no per-line rectangles,
/// no coordinates. Text selection still works; tapping a highlighted run
/// calls [onTapHighlight] with its annotation id.
class AnnotatedPageText extends StatefulWidget {
  final String text;
  final List<PageHighlight> highlights;
  final TextStyle style;
  final bool night;
  final void Function(int annotationId) onTapHighlight;
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Fires `true` when a non-collapsed selection appears, `false` when it
  /// clears. The reader uses it to freeze the outer page scroll while a
  /// selection handle is being dragged, so the handle drag never loses the
  /// gesture-arena fight to the scroll view (the "left handle is tiring"
  /// report). Selection itself is untouched.
  final void Function(bool active)? onSelectionActive;

  /// While set, this annotation's runs are drawn emphasised (a brief pulse
  /// after a notebook deep-link).
  final int? focusHighlightId;

  const AnnotatedPageText({
    super.key,
    required this.text,
    required this.highlights,
    required this.style,
    required this.night,
    required this.onTapHighlight,
    this.contextMenuBuilder,
    this.onSelectionActive,
    this.focusHighlightId,
  });

  @override
  State<AnnotatedPageText> createState() => _AnnotatedPageTextState();
}

/// ─────────────────────────────────────────────────────────────────────────
/// Interaction architecture — why this cannot fight text selection
/// ─────────────────────────────────────────────────────────────────────────
///
/// This widget adds **zero input widgets** around [SelectableText]. No
/// per-span `recognizer`, no wrapping `GestureDetector`, no `Listener`, no
/// `TextPainter` hit-testing. `SelectableText` is returned verbatim.
///
/// Tap-to-open a highlight is driven entirely by [SelectableText.onSelectionChanged].
/// `SelectableText`'s own gesture recognizers (`TapAndDragGestureRecognizer`
/// + `LongPressGestureRecognizer`, plus the selection-handle drags that live
/// in the `Overlay`) are the single source of truth for *what kind* of
/// gesture happened. They tell us via [SelectionChangedCause]:
///
///   * `SelectionChangedCause.tap`  + collapsed selection → a genuine tap.
///     If the tapped character sits inside a highlight run, open it.
///   * `drag` / `longPress` / `doubleTap` / `forcePress` / `keyboard` /
///     `scribble` / null → pure selection. We do nothing at all.
///
/// Because we never enter the gesture arena and never add a hit-test target,
/// there is nothing to compete with, delay, or block: a drag is a drag from
/// the first pixel, long-press selection is untouched, mouse-drag selection
/// is untouched, and the selection handles behave normally. The offset we
/// act on (`selection.baseOffset`) comes from `SelectableText` itself, so it
/// is automatically correct for RTL, line-wrapping, `textScaler`, font size
/// and scroll position — no geometry to keep in sync.
class _AnnotatedPageTextState extends State<AnnotatedPageText> {
  /// The covered runs of the current build, in reading order — used only to
  /// map a tapped character offset to its annotation id.
  List<TextRun> _covered = const [];

  int? _annotationAtOffset(int offset) {
    for (final run in _covered) {
      if (offset >= run.start && offset < run.end) return run.annotationId;
    }
    return null;
  }

  List<InlineSpan> _buildSpans() {
    final (spans, covered) = annotatedSpans(widget.text, widget.highlights,
        night: widget.night, focusHighlightId: widget.focusHighlightId);
    _covered = covered;
    return spans;
  }

  bool _selActive = false;

  void _onSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    final active = !selection.isCollapsed;
    if (active != _selActive) {
      _selActive = active;
      widget.onSelectionActive?.call(active);
    }
    // Only a real tap (as classified by SelectableText's own recognizers)
    // can open a highlight. Everything else is selection — hands off.
    if (cause != SelectionChangedCause.tap) return;
    if (!selection.isCollapsed) return;
    final id = _annotationAtOffset(selection.baseOffset);
    if (id != null) widget.onTapHighlight(id);
  }

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans();
    // Report selection-active even on plain (un-highlighted) pages so the
    // reader can still freeze its scroll during a handle drag.
    final onChanged = (_covered.isEmpty && widget.onSelectionActive == null)
        ? null
        : _onSelectionChanged;
    return SelectableText.rich(
      TextSpan(style: widget.style, children: spans),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      contextMenuBuilder: widget.contextMenuBuilder,
      onSelectionChanged: onChanged,
      // A loupe under the finger while dragging a selection handle — the one
      // fix that most helps the "left handle is tiring" report: the reader
      // can see exactly which character the handle is on instead of guessing
      // and re-grabbing. Adaptive = platform-native (Android loupe / iOS
      // magnifier), no-op on desktop.
      magnifierConfiguration: TextMagnifier.adaptiveMagnifierConfiguration,
    );
  }
}

/// The page's spans with highlight backgrounds, plus the covered runs (for
/// offset → annotation lookups). Shared by [AnnotatedPageText] and
/// [PenPageText] so both draw a page identically.
(List<InlineSpan>, List<TextRun>) annotatedSpans(
  String text,
  List<PageHighlight> highlights, {
  required bool night,
  int? focusHighlightId,
  (int, int, String)? preview,
}) {
  final all = [
    ...highlights,
    // the stroke being painted right now, drawn above everything (id max)
    if (preview != null && preview.$2 > preview.$1)
      PageHighlight(annotationId: 1 << 40, start: preview.$1, end: preview.$2, colorKey: preview.$3),
  ];
  final runs = buildAnnotatedRuns(text.length, all);
  final covered = [for (final r in runs) if (r.covered && r.annotationId != 1 << 40) r];
  final spans = <InlineSpan>[];
  for (final run in runs) {
    final slice = text.substring(run.start, run.end);
    if (!run.covered) {
      spans.add(TextSpan(text: slice));
      continue;
    }
    final (light, dark, accent) = AppColors.studyAnnotation(run.colorKey!);
    final focused = focusHighlightId != null && run.annotationId == focusHighlightId;
    final painting = run.annotationId == 1 << 40;
    spans.add(TextSpan(
      text: slice,
      style: focused || painting
          ? TextStyle(
              backgroundColor: accent.withValues(alpha: painting ? 0.45 : 0.38),
              decoration: focused ? TextDecoration.underline : null,
              decorationColor: accent,
              decorationThickness: 2,
            )
          : TextStyle(backgroundColor: night ? dark : light),
    ));
  }
  return (spans, covered);
}

/// Word-snapped `[start, end)` covering [a]..[b] in [text]: a stroke that
/// starts or ends mid-word takes the whole word (Ismail: highlighting must
/// not take precision).
(int, int) snapToWords(String text, int a, int b) {
  var s = a < b ? a : b, e = a < b ? b : a;
  bool ws(int i) => i < 0 || i >= text.length || RegExp(r'\s').hasMatch(text[i]);
  while (s > 0 && !ws(s - 1)) {
    s--;
  }
  while (e < text.length && !ws(e)) {
    e++;
  }
  while (s < e && ws(s)) {
    s++;
  }
  while (e > s && ws(e - 1)) {
    e--;
  }
  return (s, e);
}

/// The sentence around [offset]: back to the previous and on to the next
/// full stop / question / exclamation / Arabic semicolon or line break.
(int, int) sentenceAt(String text, int offset) {
  if (text.isEmpty) return (0, 0);
  final o = offset.clamp(0, text.length - 1);
  const stops = '.!?؟؛\n';
  var s = o, e = o;
  while (s > 0 && !stops.contains(text[s - 1])) {
    s--;
  }
  while (e < text.length && !stops.contains(text[e])) {
    e++;
  }
  if (e < text.length) e++; // keep the full stop
  // trim spaces only — snapping would pull in the previous sentence's last
  // word, which shares a «word» with its full stop
  while (s < e && text[s].trim().isEmpty) {
    s++;
  }
  while (e > s && text[e - 1].trim().isEmpty) {
    e--;
  }
  return (s, e);
}

/// «وضع القلم»: the page drawn as plain (non-selectable) text where a finger
/// stroke paints a highlight — no long-press, no handles, no menu. A stroke
/// that starts sideways paints (it starts as a pan); one that starts
/// up/down still scrolls the page (the vertical drag wins its slop first).
/// Double-tap highlights the whole sentence. Tapping a highlight opens it.
/// Offsets come from the live [RenderParagraph], so RTL, wrapping and text
/// scale need no geometry of our own.
class PenPageText extends StatefulWidget {
  final String text;
  final List<PageHighlight> highlights;
  final TextStyle style;
  final bool night;
  final String colorKey;
  final void Function(int start, int end) onPaint;
  final void Function(int annotationId) onTapHighlight;

  const PenPageText({
    super.key,
    required this.text,
    required this.highlights,
    required this.style,
    required this.night,
    required this.colorKey,
    required this.onPaint,
    required this.onTapHighlight,
  });

  @override
  State<PenPageText> createState() => _PenPageTextState();
}

class _PenPageTextState extends State<PenPageText> {
  final _key = GlobalKey();
  int? _from;
  int? _to;
  List<TextRun> _covered = const [];
  Offset? _doubleTapAt;

  int? _offsetAt(Offset global) {
    final ro = _key.currentContext?.findRenderObject();
    if (ro is! RenderParagraph) return null;
    return ro.getPositionForOffset(ro.globalToLocal(global)).offset.clamp(0, widget.text.length);
  }

  void _end() {
    final a = _from, b = _to;
    setState(() {
      _from = null;
      _to = null;
    });
    if (a == null || b == null) return;
    final (s, e) = snapToWords(widget.text, a, b);
    if (e > s) widget.onPaint(s, e);
  }

  @override
  Widget build(BuildContext context) {
    final preview = (_from != null && _to != null)
        ? (_from! < _to! ? _from! : _to!, _from! < _to! ? _to! : _from!, widget.colorKey)
        : null;
    final (spans, covered) = annotatedSpans(widget.text, widget.highlights, night: widget.night, preview: preview);
    _covered = covered;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) {
        final o = _offsetAt(d.globalPosition);
        setState(() {
          _from = o;
          _to = o;
        });
      },
      onPanUpdate: (d) {
        final o = _offsetAt(d.globalPosition);
        if (o != null && o != _to) setState(() => _to = o);
      },
      onPanEnd: (_) => _end(),
      onPanCancel: () => setState(() {
        _from = null;
        _to = null;
      }),
      onTapUp: (d) {
        final o = _offsetAt(d.globalPosition);
        if (o == null) return;
        for (final r in _covered) {
          if (o >= r.start && o < r.end) {
            widget.onTapHighlight(r.annotationId!);
            return;
          }
        }
      },
      onDoubleTapDown: (d) => _doubleTapAt = d.globalPosition,
      onDoubleTap: () {
        final at = _doubleTapAt;
        final o = at == null ? null : _offsetAt(at);
        if (o == null) return;
        final (s, e) = sentenceAt(widget.text, o);
        if (e > s) widget.onPaint(s, e);
      },
      child: RichText(
        key: _key,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(style: widget.style, children: spans),
      ),
    );
  }
}
