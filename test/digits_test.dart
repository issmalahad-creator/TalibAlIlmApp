import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/utils/digits.dart';

void main() {
  test('any digit set parses', () {
    expect(parseAnyDigits('٣٢٣'), 323);
    expect(parseAnyDigits('۳۲۳'), 323);
    expect(parseAnyDigits(' 323 '), 323);
    expect(parseAnyDigits('٣2۳'), 323);
    expect(parseAnyDigits('ص ٣'), isNull);
    expect(parseAnyDigits(''), isNull);
  });

  test('formatter keeps Arabic keyboard digits as Latin', () {
    const f = AnyDigitsFormatter();
    final out = f.formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: '٣٢٣'));
    expect(out.text, '323');
    final mixed = f.formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: '٣a-۲'));
    expect(mixed.text, '32');
  });
}
