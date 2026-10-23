import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/utils/calendar_days.dart';

void main() {
  test('counts dates, not 24-hour blocks', () {
    expect(calendarDaysBetween(DateTime(2026, 3, 1), DateTime(2026, 3, 2)), 1);
    expect(calendarDaysBetween(DateTime(2026, 3, 1, 23, 59), DateTime(2026, 3, 2, 0, 1)), 1);
    expect(calendarDaysBetween(DateTime(2026, 1, 1), DateTime(2026, 12, 31)), 364);
    expect(calendarDaysBetween(DateTime(2026, 5, 2), DateTime(2026, 5, 1)), -1);
  });

  test('stepping by calendar days visits every date once', () {
    final seen = <String>{};
    var d = DateTime(2026, 1, 1);
    for (var i = 0; i < 365; i++) {
      seen.add('${d.year}-${d.month}-${d.day}');
      d = addCalendarDays(d, 1);
    }
    expect(seen.length, 365);
    expect(d, DateTime(2027, 1, 1));
  });
}
