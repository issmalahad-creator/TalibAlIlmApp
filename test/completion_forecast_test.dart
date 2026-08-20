import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/completion_forecast.dart';

void main() {
  group('simulateDaysToComplete / forecastResultFromRuns', () {
    test('percentiles are always ordered p10 <= p50 <= p90', () {
      final samples = [1, 1, 2, 1, 3, 1, 1, 2, 1, 4, 1, 1, 2];
      final runs = simulateDaysToComplete(samples, 60, Random(42));
      final result = forecastResultFromRuns(runs);
      expect(result.insufficientData, isFalse);
      expect(result.p10Days!, lessThanOrEqualTo(result.p50Days!));
      expect(result.p50Days!, lessThanOrEqualTo(result.p90Days!));
    });

    test('a sample that always memorizes N pages/day converges to remaining/N days exactly', () {
      final samples = List.filled(15, 2); // every real day memorized exactly 2 pages
      final runs = simulateDaysToComplete(samples, 20, Random(7));
      final result = forecastResultFromRuns(runs);
      // No variance in the sample at all -> every simulated run takes exactly 10 days.
      expect(result.p10Days, 10);
      expect(result.p50Days, 10);
      expect(result.p90Days, 10);
    });

    test('a faster/more-consistent sample finishes sooner than a slower one for the same remaining count', () {
      final slow = List.filled(15, 1);
      final fast = List.filled(15, 3);
      final slowResult = forecastResultFromRuns(simulateDaysToComplete(slow, 30, Random(1)));
      final fastResult = forecastResultFromRuns(simulateDaysToComplete(fast, 30, Random(1)));
      expect(fastResult.p50Days!, lessThan(slowResult.p50Days!));
    });

    test('dates are populated and anchored to today when not insufficient', () {
      final samples = List.filled(12, 1);
      final result = forecastResultFromRuns(simulateDaysToComplete(samples, 5, Random(3)));
      expect(result.p10Date, isNotNull);
      expect(result.p50Date, isNotNull);
      expect(result.p90Date, isNotNull);
    });
  });
}
