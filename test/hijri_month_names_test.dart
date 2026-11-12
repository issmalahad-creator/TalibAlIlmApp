import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/utils/hijri_date.dart';

/// Tour 2026-10-29 A5: the Hijri month showed in Arabic in every language.
void main() {
  test('month label follows the language', () {
    expect(hijriMonthLabel('1447-09', 'ar'), 'رمضان 1447');
    expect(hijriMonthLabel('1447-09', 'en'), 'Ramadan 1447');
    expect(hijriMonthLabel('1448-05', 'tr'), 'Cemaziyelevvel 1448');
  });

  test('all 12 months exist in all 13 languages', () {
    for (final lang in ['ar', 'en', 'am', 'fr', 'sw', 'ur', 'tr', 'id', 'bn', 'ha', 'so', 'fa', 'ms']) {
      final names = {for (var m = 1; m <= 12; m++) hijriMonthName(m, lang)};
      expect(names.length, 12, reason: lang);
      expect(names.any((n) => n.startsWith('hijri_month_')), isFalse, reason: lang);
    }
  });
}
