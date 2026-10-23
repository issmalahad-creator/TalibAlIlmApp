import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/widgets/annotated_page_text.dart';

void main() {
  const text = 'قال الإمام رحمه الله. ثم ذكر الحديث بإسناده؟ وفيه فوائد كثيرة';

  test('a stroke that stops mid-word takes the whole word', () {
    final start = text.indexOf('الإمام') + 2; // inside «الإمام»
    final end = text.indexOf('رحمه') + 1; // inside «رحمه»
    final (s, e) = snapToWords(text, start, end);
    expect(text.substring(s, e), 'الإمام رحمه');
    // dragged backwards (RTL finger) is the same range
    expect(snapToWords(text, end, start), (s, e));
  });

  test('double-tap takes the sentence up to its full stop', () {
    final (s, e) = sentenceAt(text, text.indexOf('الحديث'));
    expect(text.substring(s, e), 'ثم ذكر الحديث بإسناده؟');
    final (s2, e2) = sentenceAt(text, text.indexOf('فوائد'));
    expect(text.substring(s2, e2), 'وفيه فوائد كثيرة');
  });

  testWidgets('a sideways finger stroke paints a highlight', (tester) async {
    (int, int)? painted;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: PenPageText(
            text: text,
            highlights: const [],
            style: const TextStyle(fontSize: 18),
            night: false,
            colorKey: 'benefit',
            onPaint: (s, e) => painted = (s, e),
            onTapHighlight: (_) {},
          ),
        ),
      ),
    ));
    final box = tester.getRect(find.byType(RichText));
    // RTL: start near the right edge of line 1, stroke to the left
    final g = await tester.startGesture(Offset(box.right - 4, box.top + 10));
    for (var i = 1; i <= 8; i++) {
      await g.moveBy(const Offset(-15, 0));
      await tester.pump();
    }
    await g.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(painted, isNotNull);
    final (s, e) = painted!;
    expect(s, 0);
    expect(e, greaterThan(0));
    // snapped: never ends inside a word
    expect(e == text.length || text[e] == ' ', isTrue);
  });
}
