import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/quiet_hours_prefs.dart';

void main() {
  group('applyQuietHours', () {
    test('returns the original hour when disabled', () {
      expect(applyQuietHours(hour: 23, quietEnabled: false, quietStart: 22, quietEnd: 6), 23);
    });

    test('leaves an hour outside the window untouched', () {
      expect(applyQuietHours(hour: 12, quietEnabled: true, quietStart: 22, quietEnd: 6), 12);
    });

    test('shifts an hour inside a window that wraps past midnight', () {
      expect(applyQuietHours(hour: 23, quietEnabled: true, quietStart: 22, quietEnd: 6), 6);
      expect(applyQuietHours(hour: 2, quietEnabled: true, quietStart: 22, quietEnd: 6), 6);
    });

    test('shifts an hour inside a same-day window', () {
      expect(applyQuietHours(hour: 14, quietEnabled: true, quietStart: 13, quietEnd: 15), 15);
    });

    test('window boundaries: start is inside, end is not', () {
      expect(applyQuietHours(hour: 22, quietEnabled: true, quietStart: 22, quietEnd: 6), 6);
      expect(applyQuietHours(hour: 6, quietEnabled: true, quietStart: 22, quietEnd: 6), 6);
    });
  });
}
