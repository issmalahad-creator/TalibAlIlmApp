import 'package:flutter/material.dart';

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
    final runs = buildAnnotatedRuns(widget.text.length, widget.highlights);
    _covered = [for (final r in runs) if (r.covered) r];
    final spans = <InlineSpan>[];
    for (final run in runs) {
      final slice = widget.text.substring(run.start, run.end);
      if (!run.covered) {
        spans.add(TextSpan(text: slice));
        continue;
      }
      final (light, dark, accent) = AppColors.studyAnnotation(run.colorKey!);
      final focused = widget.focusHighlightId != null &&
          run.annotationId == widget.focusHighlightId;
      spans.add(TextSpan(
        text: slice,
        style: focused
            ? TextStyle(
                backgroundColor: accent.withValues(alpha: 0.38),
                decoration: TextDecoration.underline,
                decorationColor: accent,
                decorationThickness: 2,
              )
            : TextStyle(backgroundColor: widget.night ? dark : light),
      ));
    }
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
