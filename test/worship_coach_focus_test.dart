import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/repositories/worship_coach_repository.dart';

void main() {
  test('prayer is the focus whenever it is weak, regardless of the others', () {
    expect(focusAreaFor(0.5, 0.9, 0.9), CoachFocusArea.prayer);
    expect(focusAreaFor(0.5, 0.2, 0.2), CoachFocusArea.prayer);
  });

  test('quran becomes the focus only once prayer is solid', () {
    expect(focusAreaFor(0.9, 0.5, 0.9), CoachFocusArea.quran);
  });

  test('dhikr becomes the focus only once prayer and quran are solid', () {
    expect(focusAreaFor(0.9, 0.9, 0.5), CoachFocusArea.dhikr);
  });

  test('all three solid means stable, not a false weak-area flag', () {
    expect(focusAreaFor(0.9, 0.9, 0.9), CoachFocusArea.stable);
  });

  test('the threshold boundary itself counts as solid, not weak', () {
    expect(focusAreaFor(coachWeakThreshold, 1.0, 1.0), CoachFocusArea.stable);
  });
}
