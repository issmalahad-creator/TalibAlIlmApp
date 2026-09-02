---
name: flutter-text-selection
description: >-
  Load before building or debugging ANY selectable-text UI where taps and
  drags must coexist — tappable highlights/annotations over `SelectableText`,
  RTL/Arabic scholarly text, selection inside a scroll view, custom
  selection handles, or "the drag feels stuck / grabs one character". Carries
  the gesture-arena model, the `SelectionChangedCause` pattern that replaces
  fragile hit-testing, the RTL selection-handle asymmetry, and the widget-test
  patterns for driving real selection. Learned the hard way on TalibAlIlmApp's
  Turath reader (`lib/widgets/annotated_page_text.dart`).
---

# Flutter text selection + tappable annotations

## The core problem

You want: **tap a highlighted run → open it**, **drag anywhere → free text
selection**, **long-press → natural selection**, with **no interference**.

## What does NOT work

- **`TextSpan.recognizer` (per-span `TapGestureRecognizer`)** — `RenderParagraph`
  adds it to the hit-test entry for that pixel region, so it joins the
  gesture arena *alongside* `SelectableText`'s recognizers. It holds the
  arena open until pointer-up or tap-slop, delaying the selection drag's
  start → "sticky / stuck". Every covered pixel adds contention.
- **A wrapping `GestureDetector`** — its tap competes with the child's; the
  child (opaque) usually wins the tap but the arena churn still hurts.
- **A `Listener` + `TextPainter` hit-test** — `Listener` genuinely never
  joins the arena (pure `RenderPointerListener` observer), so this is safe
  for the arena. But you then re-derive tap-vs-drag with time/slop
  heuristics AND must keep a `TextPainter` byte-identical to the rendered
  text (same `maxWidth`, `textScaler`, `strutStyle`, spans) — fragile,
  breaks silently when the OS font scale ≠ 100%.

## What works — `SelectableText.onSelectionChanged`

Add **zero** input widgets. Return `SelectableText.rich(...)` verbatim, and:

```dart
void _onSelectionChanged(TextSelection sel, SelectionChangedCause? cause) {
  if (cause != SelectionChangedCause.tap) return;   // drag/longPress/doubleTap/… → hands off
  if (!sel.isCollapsed) return;
  final id = _annotationAtOffset(sel.baseOffset);    // offset comes FROM SelectableText
  if (id != null) widget.onTapHighlight(id);
}
```

Why it cannot interfere: you add no gesture-handling widget, so there is
nothing in the arena to compete. `SelectableText`'s own
`TapAndDragGestureRecognizer` + `LongPressGestureRecognizer` classify the
gesture and hand you `SelectionChangedCause` — the source of truth. A drag
is `cause: drag` from the first pixel; a tap that moved < slop is `cause:
tap` (correct — it *was* a tap). `selection.baseOffset` is already correct
for RTL, wrapping, `textScaler`, font size, and scroll — no geometry to
sync. Selection handles live in the `Overlay`, unaffected by anything you
wrap.

Keep only a run list (`[{start, end, annotationId}]`) for the offset→id
lookup. `_covered.isEmpty ? null : _onSelectionChanged` so plain pages skip
it entirely.

## RTL selection-handle asymmetry ("left handle is tiring")

In RTL the selection **start (base)** renders visually on the **right**, the
**end (extent)** on the **left**. The left/extent handle is the hard one
because:
1. Dragging it further left (to extend forward / grab a lower line's end)
   pushes the finger past the text's `RenderEditable` box → `selectPositionAt`
   clamps to line-start → the handle "snaps back". **Fix:** trim the reader's
   horizontal padding so text isn't flush to where the handle needs travel.
2. Vertical handle drag near a viewport edge triggers `ensureVisible` on the
   *external* `SingleChildScrollView` → text jumps under the finger. **Fix
   (escalation):** `SelectionArea` (better-tuned auto-scroll) — but that
   changes the whole selection model and breaks any flow that reads
   `EditableTextState.contextMenuButtonItems` / `.textEditingValue.selection`.
3. **Add `magnifierConfiguration: TextMagnifier.adaptiveMagnifierConfiguration`**
   — a loupe under the finger is the single highest-value fix: the user
   places the handle precisely instead of re-grabbing.

## Mobile vs desktop

On mobile a **plain drag does not select** — the gesture is long-press-then-
drag. So "drag after highlighting grabs one character" on a phone is
`SelectableText`'s normal behaviour, not your bug. To *prove* free
selection, drive long-press-then-drag.

## Testing selection in `flutter_test`

- **Aim** at a character with the LIVE render object, not your own painter:
  ```dart
  RenderEditable re = /* walk children of find.byType(SelectableText) */;
  final c0 = re.getLocalRectForCaret(TextPosition(offset: n)).center;
  final c1 = re.getLocalRectForCaret(TextPosition(offset: n + 1)).center;
  final global = re.localToGlobal(Offset((c0.dx + c1.dx) / 2, c0.dy));
  ```
  A test-side `TextPainter` will be off by a line by line 3 (strut/height
  mismatch) — use the render object.
- **`debugDefaultTargetPlatformOverride` in a widget test throws** "a
  foundation debug variable was changed by the test" — the invariant check
  runs *before* `tearDown`. Don't set it; drive the mobile gesture instead.
- **Two `tester.tapAt` within 300 ms + `kDoubleTapSlop`** = a double-tap →
  `cause: doubleTap` (word select), not two `tap`s. Space them with
  `pump(Duration(milliseconds: 400))`.
- A horizontal **`ListView` of chips culls off-screen children** — index-
  based finders (`find.byType(FilterChip).at(4)`) then find fewer than
  expected or hit off-screen. Use `SingleChildScrollView`+`Row` (eager) or
  `tester.ensureVisible(finder)` before tapping.
