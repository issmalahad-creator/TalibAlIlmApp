import 'dart:math';

import '../db/database_helper.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';

/// Bootstrap-simulation forecast for "متى سأختم؟" — 100_IDEAS_FOR_IMPROVEMENT.md's
/// "Learning Decision Engine" ask, deliberately built on **real recorded
/// history**, not an invented distribution: `memorization_progress.memorized_date`
/// already logs a real date for every page ever memorized. Grouping those by
/// date gives a genuine empirical sample of "how many pages did Ismail
/// actually memorize on a given active day" — resampling from that (with
/// replacement) to simulate many possible futures is honest about real
/// variability instead of presenting one falsely-precise number, and adds
/// no new tracking at all. Deliberately does NOT touch
/// `CompletionGoalRepository`/`MemorizationRepository`'s scheduling — this
/// only reads already-written history for a separate, additive forecast.
class ForecastResult {
  final bool insufficientData;
  final int? p10Days, p50Days, p90Days;
  final String? p10Date, p50Date, p90Date;
  const ForecastResult({
    required this.insufficientData,
    this.p10Days,
    this.p50Days,
    this.p90Days,
    this.p10Date,
    this.p50Date,
    this.p90Date,
  });
}

/// Below this many distinct active days of real history, a resampled
/// distribution would just be reshuffling a handful of data points and
/// presenting that as a confidence range would be misleading precision.
const _minActiveDaysForForecast = 10;
const _simulationRuns = 2000;

class CompletionForecastService {
  /// Real per-day memorization counts, most-recent-history-agnostic (order
  /// doesn't matter for resampling) — one entry per day that had at least
  /// one page newly memorized.
  Future<List<int>> _realDailySamples() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS c FROM memorization_progress
      WHERE memorized_date IS NOT NULL
      GROUP BY memorized_date
    ''');
    return rows.map((r) => r['c'] as int).toList();
  }

  Future<ForecastResult> forecast({required int remaining, Random? random}) async {
    final samples = await _realDailySamples();
    if (samples.length < _minActiveDaysForForecast || remaining <= 0) {
      return const ForecastResult(insufficientData: true);
    }
    final rng = random ?? Random();
    final daysToComplete = simulateDaysToComplete(samples, remaining, rng);
    return forecastResultFromRuns(daysToComplete);
  }

  /// Re-runs the same simulation under two synthetic nudges to see which
  /// one moves the median completion date more — "أكبر عامل يمكن تحسينه".
  /// Reuses [simulateDaysToComplete] rather than a separate model: "consistency" is
  /// approximated by dropping the bottom quartile of days (as if the
  /// weakest days became average ones), "pace" by boosting the top
  /// quartile (as if the best days became even more common). Both are
  /// explicitly synthetic what-ifs on top of the same real base sample,
  /// not separate invented distributions.
  Future<List<(String, int)>> sensitivityFactors({required int remaining, Random? random}) async {
    final samples = await _realDailySamples();
    if (samples.length < _minActiveDaysForForecast || remaining <= 0) return const [];
    final rng = random ?? Random();

    final sorted = [...samples]..sort();
    final baselineP50 = forecastResultFromRuns(simulateDaysToComplete(samples, remaining, rng)).p50Days!;

    final consistencySample = sorted.sublist(sorted.length ~/ 4);
    final consistencyP50 = forecastResultFromRuns(simulateDaysToComplete(consistencySample, remaining, rng)).p50Days!;

    final topQuarter = sorted.sublist((sorted.length * 3) ~/ 4);
    final paceSample = [...samples, ...topQuarter, ...topQuarter];
    final paceP50 = forecastResultFromRuns(simulateDaysToComplete(paceSample, remaining, rng)).p50Days!;

    final factors = [
      ('الاستمرارية', baselineP50 - consistencyP50),
      ('زيادة الوتيرة', baselineP50 - paceP50),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return factors;
  }
}

/// Bootstrap resampling core, deliberately a pure top-level function (no DB,
/// no `CompletionForecastService` instance needed) so it's directly
/// unit-testable against hand-built sample lists — see
/// `test/completion_forecast_test.dart`. [samples] must be non-empty.
List<int> simulateDaysToComplete(List<int> samples, int remaining, Random rng) {
  final results = <int>[];
  for (var run = 0; run < _simulationRuns; run++) {
    var covered = 0;
    var days = 0;
    while (covered < remaining && days < 20000) {
      covered += samples[rng.nextInt(samples.length)];
      days++;
    }
    results.add(days);
  }
  return results;
}

/// Turns raw simulated day-counts into p10/p50/p90 days + Hijri dates. Pure
/// (no DB) except for reading "today" via `todayDate()` to anchor the dates.
ForecastResult forecastResultFromRuns(List<int> daysToComplete) {
  final sorted = [...daysToComplete]..sort();
  int atPercentile(double p) => sorted[(sorted.length * p).floor().clamp(0, sorted.length - 1)];
  final p10 = atPercentile(0.10);
  final p50 = atPercentile(0.50);
  final p90 = atPercentile(0.90);
  final today = todayDate();
  String addDays(int days) => hijriDateStringForDate(gregorianFromHijriDateTime(today, null).add(Duration(days: days)));
  return ForecastResult(
    insufficientData: false,
    p10Days: p10,
    p50Days: p50,
    p90Days: p90,
    p10Date: addDays(p10),
    p50Date: addDays(p50),
    p90Date: addDays(p90),
  );
}
