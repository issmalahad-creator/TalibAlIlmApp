import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/repositories/time_awareness_repository.dart';

void main() {
  test('sleep within the cap is neither benefit nor waste', () {
    const e = DailyTimeEntry(hoursSlept: 7, hoursStudied: 5, hoursWorked: 8, hoursWasted: 4);
    expect(e.excessSleepHours, 0);
    expect(e.benefitedHours, 13); // 5 + 8
    expect(e.accountedHours, 24); // 7+4+5+8
    expect(e.unaccountedHours, 0);
    expect(e.wastedHours, 4); // only the explicit waste
  });

  test('sleep beyond the cap counts toward wasted time', () {
    const e = DailyTimeEntry(hoursSlept: 10, hoursStudied: 2, hoursWorked: 8, hoursWasted: 2);
    expect(e.excessSleepHours, 2); // 10 - 8
    expect(e.benefitedHours, 10);
    expect(e.accountedHours, 22);
    expect(e.unaccountedHours, 2);
    expect(e.wastedHours, 6); // 2 explicit + 2 excess sleep + 2 unaccounted
  });

  test('hours never entered at all default to wasted, not benefit', () {
    const e = DailyTimeEntry(hoursSlept: 8);
    expect(e.benefitedHours, 0);
    expect(e.unaccountedHours, 16);
    expect(e.wastedHours, 16);
  });

  test('an empty entry reports no data rather than a false zero', () {
    const e = DailyTimeEntry();
    expect(e.hasAnyEntry, false);
  });
}
