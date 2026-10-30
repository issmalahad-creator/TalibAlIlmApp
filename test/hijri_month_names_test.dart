import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/utils/hijri_date.dart';

/// Tour أ5 (`docs/TOUR_2026-10-29.md`): the Hijri month name follows the
/// app language instead of staying Arabic in all 13.
void main() {
  test('month names per language', () {
    expect(hijriMonthName(5, 'ar'), 'جمادى الأولى');
    expect(hijriMonthName(9, 'en'), 'Ramadan');
    expect(hijriMonthName(9, 'tr'), 'Ramazan');
    expect(hijriMonthName(12, 'fa'), 'ذی‌الحجه');
  });

  test('every language has all 12 months, none falling back to the key', () {
    for (final lang in const ['ar', 'en', 'am', 'fr', 'sw', 'ur', 'tr', 'id', 'bn', 'ha', 'so', 'fa', 'ms']) {
      for (var m = 1; m <= 12; m++) {
        final name = hijriMonthName(m, lang);
        expect(name, isNot(contains('hijri_month')), reason: '$lang $m');
        expect(name.trim(), isNotEmpty);
      }
    }
  });
}
