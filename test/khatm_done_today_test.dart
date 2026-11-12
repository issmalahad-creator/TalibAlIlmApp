import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/repositories/completion_goal_repository.dart';

/// «أتممت ورد اليوم» records an ABSOLUTE muṣḥaf page; the card's status is
/// relative to a ranged goal's start.
void main() {
  test('whole-muṣḥaf goal: position + today’s portion', () {
    expect(doneTodayPosition(currentPosition: 40, pagesRemainingToday: 20, totalUnits: 604), 60);
  });

  test('ranged goal starting at page 50: converted back to the absolute page', () {
    // read pages 50..59 (10 within the goal), 5 more due today → page 64
    expect(doneTodayPosition(currentPosition: 10, pagesRemainingToday: 5, totalUnits: 100, startUnit: 50), 64);
  });

  test('never past the end of the goal', () {
    expect(doneTodayPosition(currentPosition: 98, pagesRemainingToday: 9, totalUnits: 100, startUnit: 50), 149);
    expect(doneTodayPosition(currentPosition: 600, pagesRemainingToday: 9, totalUnits: 604), 604);
  });
}
