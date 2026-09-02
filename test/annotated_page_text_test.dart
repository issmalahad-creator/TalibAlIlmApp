import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/widgets/annotated_page_text.dart';

/// Phase 79 «علامات الدراسة» / Phase B — the run splitter and the
/// `SelectableText.rich` highlight rendering. The rule under test: a
/// highlight is drawn over the ENTIRE `[start, end)` span, across lines,
/// and tapping any covered run reports that annotation's id.

void main() {
  group('buildAnnotatedRuns', () {
    test('no highlights → one plain run over the whole text', () {
      final runs = buildAnnotatedRuns(50, const []);
      expect(runs, hasLength(1));
      expect(runs.single.covered, isFalse);
      expect((runs.single.start, runs.single.end), (0, 50));
    });

    test('one highlight → plain / covered / plain, covering the full span', () {
      final runs = buildAnnotatedRuns(100, const [
        PageHighlight(annotationId: 7, start: 20, end: 60, colorKey: 'benefit'),
      ]);
      expect(runs.map((r) => (r.start, r.end, r.covered)).toList(), [
        (0, 20, false),
        (20, 60, true),
        (60, 100, false),
      ]);
      final covered = runs.firstWhere((r) => r.covered);
      expect(covered.annotationId, 7);
      expect(covered.end - covered.start, 40, reason: 'the whole selection, not a fragment');
    });

    test('covered runs exactly reconstruct the original text length', () {
      final runs = buildAnnotatedRuns(200, const [
        PageHighlight(annotationId: 1, start: 10, end: 40, colorKey: 'explain'),
        PageHighlight(annotationId: 2, start: 90, end: 150, colorKey: 'question'),
      ]);
      var acc = 0;
      for (final r in runs) {
        expect(r.start, acc);
        acc = r.end;
      }
      expect(acc, 200);
    });

    test('overlap: the newest annotation (highest id) owns the shared sub-run', () {
      final runs = buildAnnotatedRuns(100, const [
        PageHighlight(annotationId: 1, start: 10, end: 50, colorKey: 'benefit'),
        PageHighlight(annotationId: 2, start: 40, end: 80, colorKey: 'important'),
      ]);
      // boundaries: 0,10,40,50,80,100
      expect(runs.map((r) => (r.start, r.end, r.annotationId, r.colorKey)).toList(), [
        (0, 10, null, null),
        (10, 40, 1, 'benefit'),
        (40, 50, 2, 'important'), // shared piece → newer id wins
        (50, 80, 2, 'important'),
        (80, 100, null, null),
      ]);
    });

    test('out-of-range / inverted highlights are dropped, valid ones kept', () {
      final runs = buildAnnotatedRuns(30, const [
        PageHighlight(annotationId: 1, start: 25, end: 10, colorKey: 'benefit'), // inverted
        PageHighlight(annotationId: 2, start: 20, end: 999, colorKey: 'explain'), // clamped to 30
      ]);
      expect(runs.map((r) => (r.start, r.end, r.annotationId)).toList(), [
        (0, 20, null),
        (20, 30, 2),
      ]);
    });
  });

  group('AnnotatedPageText widget', () {
    const text = 'السطر الأول من الصفحة\n'
        'السطر الثاني وفيه موضع التظليل يمتد\n'
        'إلى السطر الثالث ثم ينتهي هنا تمامًا.';

    testWidgets('draws a background tint over the full multi-line span and no other run', (tester) async {
      final start = text.indexOf('موضع التظليل');
      final end = text.indexOf('السطر الثالث') + 'السطر الثالث'.length; // crosses a newline
      final selected = text.substring(start, end);
      expect(selected, contains('\n'));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnnotatedPageText(
            text: text,
            highlights: [PageHighlight(annotationId: 42, start: start, end: end, colorKey: 'memorize')],
            style: const TextStyle(fontSize: 14),
            night: false,
            onTapHighlight: (_) {},
          ),
        ),
      ));

      final st = tester.widget<SelectableText>(find.byType(SelectableText));
      final children = (st.textSpan!.children!).cast<TextSpan>();
      final tinted = children.where((s) => s.style?.backgroundColor != null).toList();

      expect(tinted, hasLength(1), reason: 'exactly one contiguous highlighted run');
      expect(tinted.single.text, selected, reason: 'the tint covers the ENTIRE selection verbatim');
      expect(children.map((s) => s.text).join(), text, reason: 'runs reconstruct the page');
    });

    testWidgets('night mode uses the darker tint', (tester) async {
      Future<Color?> tintFor({required bool night}) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: AnnotatedPageText(
              text: text,
              highlights: const [PageHighlight(annotationId: 1, start: 0, end: 10, colorKey: 'important')],
              style: const TextStyle(fontSize: 14),
              night: night,
              onTapHighlight: (_) {},
            ),
          ),
        ));
        final st = tester.widget<SelectableText>(find.byType(SelectableText));
        return (st.textSpan!.children!.cast<TextSpan>())
            .firstWhere((s) => s.style?.backgroundColor != null)
            .style!
            .backgroundColor;
      }

      final light = await tintFor(night: false);
      final dark = await tintFor(night: true);
      expect(light, isNot(dark));
    });

    testWidgets('PageMarksBar renders a chip per mark and reports taps', (tester) async {
      int? tapped;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PageMarksBar(
            marks: const [
              (1, 'benefit', 'أول علامة'),
              (2, 'question', 'ثاني علامة'),
            ],
            onTap: (id) => tapped = id,
          ),
        ),
      ));
      expect(find.byType(ActionChip), findsExactly(2));
      expect(find.text('ثاني علامة'), findsOneWidget);
      await tester.tap(find.text('ثاني علامة'));
      expect(tapped, 2);
    });

    testWidgets('PageMarksBar is invisible when there are no marks', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: PageMarksBar(marks: const [], onTap: (_) {})),
      ));
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('tapping a highlighted run reports its annotation id', (tester) async {
      final h = await _pump(tester, text,
          const [PageHighlight(annotationId: 99, start: 5, end: 20, colorKey: 'benefit')]);
      await tester.tapAt(_charPoint(tester, text, 12));
      await tester.pump();
      expect(h.opened, [99]);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Selection interaction — the DONE checklist.
  //
  //   tap on a highlight        → highlight interaction
  //   drag                      → completely free text selection
  //   long-press                → natural text selection
  //   selection crossing marks  → no interference
  //   no per-span recognizers, no gesture competition with SelectableText
  //
  // The contract that makes all of this true: a highlight opens ONLY on
  // `SelectionChangedCause.tap`; every other cause (drag / longPress /
  // doubleTap / …) is left entirely to SelectableText.
  // ───────────────────────────────────────────────────────────────────────
  group('AnnotatedPageText — selection interaction', () {
    // three lines, Arabic, RTL; one highlight sits inside line 2.
    const text = 'السطر الأول من الصفحة\n'
        'السطر الثاني وفيه موضع التظليل يمتد هنا\n'
        'إلى السطر الثالث ثم ينتهي هنا تمامًا.';
    final hlStart = text.indexOf('موضع');
    final hlEnd = text.indexOf('يمتد') + 'يمتد'.length; // inside line 2
    List<PageHighlight> hl([int id = 1]) =>
        [PageHighlight(annotationId: id, start: hlStart, end: hlEnd, colorKey: 'benefit')];

    testWidgets('architecture: AnnotatedPageText wraps SelectableText with '
        'NOTHING in between (no GestureDetector / Listener / recognizer)',
        (tester) async {
      await _pump(tester, text, hl());
      final el = tester.element(find.byType(AnnotatedPageText));
      Widget? child;
      el.visitChildElements((e) => child = e.widget);
      expect(child, isA<SelectableText>(),
          reason: 'SelectableText is returned verbatim — no wrapper can compete');
      final st = tester.widget<SelectableText>(find.byType(SelectableText));
      for (final s in st.textSpan!.children!.cast<TextSpan>()) {
        expect(s.recognizer, isNull, reason: 'no per-span gesture recognizer');
      }
    });

    testWidgets('A — tap inside a highlight opens it', (tester) async {
      final h = await _pump(tester, text, hl(7));
      await tester.tapAt(_charPoint(tester, text, hlStart + 2));
      await tester.pump();
      expect(h.opened, [7]);
    });

    testWidgets('A2 — tap just OUTSIDE the highlight does not open it',
        (tester) async {
      final h = await _pump(tester, text, hl());
      await tester.tapAt(_charPoint(tester, text, hlStart - 3)); // still line 2
      await tester.pump();
      expect(h.opened, isEmpty);
    });

    testWidgets('B — drag STARTING inside the highlight selects freely, '
        'never opens it', (tester) async {
      final h = await _pump(tester, text, hl());
      // a raw pointer drag (no long-press) must never be misread as a tap
      await _rawDrag(tester, from: hlStart + 1, to: hlEnd + 6);
      expect(h.opened, isEmpty, reason: 'a drag is a drag, not a tap');
      // and the mobile select gesture from inside the highlight works
      await _lpDrag(tester, from: hlStart + 1, to: hlEnd + 6);
      expect(h.opened, isEmpty);
      expect(_selection(tester).isCollapsed, isFalse,
          reason: 'text got selected — selection was not blocked');
    });

    testWidgets('C — drag starting OUTSIDE a highlight selects freely',
        (tester) async {
      final h = await _pump(tester, text, hl());
      await _lpDrag(tester, from: 2, to: hlStart + 4); // ends inside the highlight
      expect(h.opened, isEmpty);
      expect(_selection(tester).isCollapsed, isFalse);
    });

    testWidgets('D — long-press inside a highlight is selection, not open',
        (tester) async {
      final h = await _pump(tester, text, hl());
      await tester.longPressAt(_charPoint(tester, text, hlStart + 2));
      await tester.pump(const Duration(milliseconds: 100));
      expect(h.opened, isEmpty, reason: 'cause=longPress → hands off');
      expect(_selection(tester).isCollapsed, isFalse,
          reason: 'long-press selected a word, naturally');
    });

    testWidgets('E — selection crossing highlighted + plain text: no interference',
        (tester) async {
      final h = await _pump(tester, text, hl());
      await _lpDrag(tester, from: hlStart - 4, to: hlEnd + 10);
      expect(h.opened, isEmpty);
      final sel = _selection(tester);
      expect(sel.isCollapsed, isFalse);
      expect(sel.textInside(text).contains('موضع'), isTrue,
          reason: 'the selection spans into the highlighted words');
    });

    testWidgets('F — selection across multiple lines works', (tester) async {
      final h = await _pump(tester, text, hl());
      final line3 = text.indexOf('الثالث');
      await _lpDrag(tester, from: 4, to: line3 + 3);
      expect(h.opened, isEmpty);
      final sel = _selection(tester);
      expect(sel.isCollapsed, isFalse);
      expect(sel.textInside(text).contains('\n'), isTrue,
          reason: 'selection crosses at least one line break');
    });

    testWidgets('G — RTL: the opened id matches the character actually tapped',
        (tester) async {
      // one highlight on line 1, another on line 3; tapping each must
      // resolve to its own id even though RTL lays glyphs right-to-left.
      final a = text.indexOf('الأول');
      final b = text.indexOf('الثالث');
      final h1 = await _pump(tester, text, [
        PageHighlight(annotationId: 11, start: a, end: a + 5, colorKey: 'benefit'),
      ]);
      await tester.tapAt(_charPoint(tester, text, a + 2));
      await tester.pump();
      expect(h1.opened, [11], reason: 'line-1 highlight resolves in RTL');

      final bEnd = text.indexOf('ينتهي') + 'ينتهي'.length; // wide, deep in line 3
      final h2 = await _pump(tester, text, [
        PageHighlight(annotationId: 22, start: b, end: bEnd, colorKey: 'question'),
      ]);
      await tester.tapAt(_charPoint(tester, text, (b + bEnd) ~/ 2));
      await tester.pump();
      expect(h2.opened, [22], reason: 'a highlight past the first line resolves in RTL');

      // a tap before that highlight → nothing
      final h3 = await _pump(tester, text, [
        PageHighlight(annotationId: 33, start: b, end: bEnd, colorKey: 'question'),
      ]);
      await tester.tapAt(_charPoint(tester, text, b - 4));
      await tester.pump();
      expect(h3.opened, isEmpty);
    });

    testWidgets('H — MOUSE drag selects freely, never opens a highlight',
        (tester) async {
      final h = await _pump(tester, text, hl());
      final g = await tester.startGesture(
          _charPoint(tester, text, hlStart + 1),
          kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 60));
      await g.moveTo(_charPoint(tester, text, hlEnd + 8));
      await tester.pump();
      await g.up();
      await tester.pump();
      expect(h.opened, isEmpty);
      expect(_selection(tester).isCollapsed, isFalse);
    });

    testWidgets('I — rapid tap (opens) then a drag (selects) — one open only',
        (tester) async {
      final h = await _pump(tester, text, hl(5));
      await tester.tapAt(_charPoint(tester, text, hlStart + 2));
      await tester.pump(const Duration(milliseconds: 30));
      await _lpDrag(tester, from: 2, to: 14);
      expect(h.opened, [5], reason: 'only the first tap opened; the drag did not');
      expect(_selection(tester).isCollapsed, isFalse);
    });

    testWidgets('J — drag that RELEASES inside a highlight does not open it',
        (tester) async {
      final h = await _pump(tester, text, hl());
      await _lpDrag(tester, from: 3, to: hlStart + 3); // release lands in highlight
      expect(h.opened, isEmpty);
      expect(_selection(tester).isCollapsed, isFalse);
    });

    testWidgets('K — onSelectionActive(true) fires when a range is selected '
        '(reader freezes its scroll during handle drags)', (tester) async {
      final h = await _pump(tester, text, hl());
      await _lpDrag(tester, from: 4, to: hlEnd + 8);
      expect(h.selActive, contains(true),
          reason: 'a non-collapsed selection was reported as active');
    });
  });
}

// ─── test helpers ────────────────────────────────────────────────────────

const _style = TextStyle(fontSize: 14);
const _width = 320.0;

class _Harness {
  final List<int> opened = [];
  final List<bool> selActive = [];
}

Future<_Harness> _pump(
    WidgetTester tester, String text, List<PageHighlight> highlights) async {
  final h = _Harness();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: _width,
          child: AnnotatedPageText(
            text: text,
            highlights: highlights,
            style: _style,
            night: false,
            onTapHighlight: h.opened.add,
            onSelectionActive: h.selActive.add,
          ),
        ),
      ),
    ),
  ));
  return h;
}

RenderEditable _renderEditable(WidgetTester tester) {
  RenderEditable? found;
  void visit(RenderObject o) {
    if (o is RenderEditable) found ??= o;
    o.visitChildren(visit);
  }

  visit(tester.renderObject(find.byType(SelectableText)));
  return found!;
}

/// Global point on the glyph of character [offset] — computed from the LIVE
/// `RenderEditable`, so it hits exactly what `SelectableText` hit-tests
/// (correct for RTL, wrapping, strut, `textScaler`, font size and scroll).
/// The widget itself does no geometry; this is test-only aiming.
Offset _charPoint(WidgetTester tester, String text, int offset) {
  final re = _renderEditable(tester);
  final o = offset.clamp(0, text.length - 1);
  final c0 = re.getLocalRectForCaret(TextPosition(offset: o)).center;
  final c1 = re.getLocalRectForCaret(TextPosition(offset: o + 1)).center;
  return re.localToGlobal(Offset((c0.dx + c1.dx) / 2, c0.dy));
}

TextSelection _selection(WidgetTester tester) =>
    tester.state<EditableTextState>(find.byType(EditableText))
        .textEditingValue
        .selection;

String _text(WidgetTester tester) =>
    tester.widget<AnnotatedPageText>(find.byType(AnnotatedPageText)).text;

/// A raw pointer drag: down, several moves past the drag slop, up — with NO
/// preceding long-press. Used to prove such a gesture is never misread as a
/// tap on a highlight.
Future<void> _rawDrag(WidgetTester tester,
    {required int from, required int to}) async {
  final t = _text(tester);
  final start = _charPoint(tester, t, from);
  final end = _charPoint(tester, t, to);
  final g = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 40));
  for (var i = 1; i <= 5; i++) {
    await g.moveTo(Offset.lerp(start, end, i / 5)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await tester.pump();
}

/// The mobile select gesture: long-press to grab a word, then drag to extend
/// — the exact gesture a phone user makes in the Turath reader. Deterministic
/// selection on the default test platform.
Future<void> _lpDrag(WidgetTester tester,
    {required int from, required int to}) async {
  final t = _text(tester);
  final start = _charPoint(tester, t, from);
  final end = _charPoint(tester, t, to);
  final g = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 600)); // long-press fires
  for (var i = 1; i <= 6; i++) {
    await g.moveTo(Offset.lerp(start, end, i / 6)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await tester.pump();
}
