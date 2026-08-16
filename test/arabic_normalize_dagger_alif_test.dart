import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/utils/arabic_normalize.dart';

void main() {
  test('dagger alef cases all normalize to match plain-typed queries', () {
    final cases = <String, String>{
      '\u0671\u0644\u0638\u0651\u064e\u0640\u0670\u0644\u0650\u0645\u0650\u064a\u0646\u064e': 'الظالمين',
      '\u0628\u0650\u0671\u0644\u0631\u0651\u064e\u062d\u0652\u0645\u064e\u0640\u0670\u0646\u0650': 'بالرحمن',
      '\u0647\u064e\u0640\u0670\u0630\u064e\u0627': 'هذا',
      '\u0647\u064e\u0640\u0670\u0630\u0650\u0647\u0650': 'هذه',
      '\u0630\u064e\u0670\u0644\u0650\u0643\u0650': 'ذلك',
      '\u0648\u064e\u0644\u064e\u0640\u0670\u0643\u0650\u0646': 'ولكن',
      '\u0639\u064e\u0644\u064e\u0649\u0670': 'على',
      '\u0645\u064f\u0648\u0633\u064e\u0649\u0670': 'موسى',
      '\u0627\u0644\u0635\u0651\u064e\u0644\u064e\u0648\u0670\u0629\u064e': 'الصلاة',
      '\u0627\u0644\u062d\u064e\u064a\u064e\u0648\u0670\u0629\u064e': 'الحياة',
      '\u0627\u0644\u0641\u0642\u0631\u0627\u0653\u0621': 'الفقراء',
    };
    for (final entry in cases.entries) {
      final a = normalizeArabicForSearch(entry.key);
      final b = normalizeArabicForSearch(entry.value);
      expect(a, equals(b), reason: 'uthmani=${entry.key} -> $a | query=${entry.value} -> $b');
    }
  });
}
