import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/models/akhlaq.dart';
import 'package:talib_alilm_app/services/akhlaq/akhlaq_content.dart';
import 'package:talib_alilm_app/services/akhlaq/akhlaq_engine.dart';

/// AKHLAQ — the training engine is pure functions; test them with fixed
/// inputs (same discipline as `tajweed_svg_paint_test`).
void main() {
  final slice = AkhlaqContent.parseJsonString(
      File('docs/akhlaq/alrifq/ar-rifq.json').readAsStringSync());

  AkhlaqAttempt att(String sub, String verdict, int diff, int ago) =>
      AkhlaqAttempt(
        subskill: sub,
        scenarioId: 'S-XX',
        chosenKey: 'A',
        verdict: verdict,
        quality: qualityForVerdict(verdict),
        difficulty: diff,
        dimScore: verdict == 'baid' ? const {'gentleness': -1} : const {},
        answeredAt: DateTime(2026, 1, 10).millisecondsSinceEpoch - ago * 86400000,
      );

  test('qualityForVerdict maps aqrab/maqbul/baid → 5/3/1', () {
    expect(qualityForVerdict('aqrab'), 5);
    expect(qualityForVerdict('maqbul'), 3);
    expect(qualityForVerdict('baid'), 1);
    expect(qualityForVerdict('whatever'), 1);
  });

  test('evaluateOption returns verdict + quality + dims, no "correct" flag',
      () {
    final sc = slice.scenarios.firstWhere((s) => s.id == 'S-01');
    final aqrab = sc.options.firstWhere((o) => o.verdict == 'aqrab');
    final d = evaluateOption(aqrab);
    expect(d.quality, 5);
    expect(d.verdict, 'aqrab');
    expect(d.dims, isNotEmpty);
  });

  test('rollSubskillTrend: empty → beginner; aqrab-run → mastery; baid-run → review',
      () {
    expect(rollSubskillTrend(subskill: 'x', attempts: const []).band,
        'beginner');

    final good = [for (var i = 0; i < 6; i++) att('rifq_ibara', 'aqrab', 3, i)];
    final gp = rollSubskillTrend(subskill: 'rifq_ibara', attempts: good);
    expect(gp.trend, greaterThan(0.9));
    expect(gp.band, 'mastery');
    expect(gp.attempts, 6);

    final bad = [for (var i = 0; i < 6; i++) att('rifq_ibara', 'baid', 3, i)];
    final bp = rollSubskillTrend(subskill: 'rifq_ibara', attempts: bad);
    expect(bp.trend, lessThan(0.3));
    expect(bp.band, 'review');
    expect(bp.weakDimension, 'gentleness'); // from the -1 tally

    // difficulty weighting: a good hard attempt outweighs a poor easy one
    final mixed = [att('m', 'aqrab', 8, 0), att('m', 'baid', 1, 1)];
    expect(rollSubskillTrend(subskill: 'm', attempts: mixed).trend,
        greaterThan(0.7));
  });

  test('scheduleNext: SM-2 adapted', () {
    const start = AkhlaqSrState(subskill: 's', track: 'S', intervalDays: 1);
    final t = DateTime(2026, 3, 1);

    // good answer grows the interval and cycles the track S→R
    final g = scheduleNext(start, 5, today: t);
    expect(g.intervalDays, 2);
    expect(g.ease, greaterThan(start.ease));
    expect(g.track, 'R');
    expect(g.difficulty, 1); // no stableRun → no ramp
    expect(g.dueDate, '2026-03-03');

    // stableRun raises difficulty by one
    final ramp = scheduleNext(start, 5, today: t, stableRun: true);
    expect(ramp.difficulty, 2);

    // a poor answer resets the interval to 1 and never raises difficulty
    const mid = AkhlaqSrState(
        subskill: 's', track: 'S', intervalDays: 12, difficulty: 4, ease: 2.5);
    final p = scheduleNext(mid, 1, today: t, stableRun: true);
    expect(p.intervalDays, 1);
    expect(p.difficulty, 4);
    expect(p.ease, lessThan(mid.ease));
    expect(p.ease, greaterThanOrEqualTo(1.3));
  });

  test('pickNextScenario: prefers this subskill + difficulty, avoids seen', () {
    final id = pickNextScenario(
      subskill: 'rifq_istifzaz',
      difficulty: 5,
      slice: slice,
      attempts: const [],
    );
    expect(id, isNotNull);
    final sc = slice.scenarioById(id!)!;
    expect(sc.subskills, contains('rifq_istifzaz'));
    expect(sc.difficulty, 5); // S-06 is the difficulty-5 rifq_istifzaz one

    // once seen, a different scenario for the same subskill is chosen
    final seen = [att2(id, 'rifq_istifzaz')];
    final id2 = pickNextScenario(
      subskill: 'rifq_istifzaz',
      difficulty: 5,
      slice: slice,
      attempts: seen,
    );
    expect(id2, isNot(id));
  });

  test('todayPlan: focus first, respects due date, capped', () {
    final today = DateTime(2026, 4, 10);
    final states = [
      const AkhlaqSrState(subskill: 'rifq_ibara', track: 'S', dueDate: ''),
      AkhlaqSrState(
          subskill: 'rifq_nabra',
          track: 'K',
          dueDate: '2026-04-09'), // due
      AkhlaqSrState(
          subskill: 'rifq_hazm',
          track: 'R',
          dueDate: '2026-04-30'), // not due
      const AkhlaqSrState(subskill: 'rifq_nush', track: 'S', dueDate: ''),
    ];
    final plan = todayPlan(
      states: states,
      attempts: const [],
      slice: slice,
      today: today,
      focusSubskill: 'rifq_hazm',
      max: 3,
    );
    expect(plan.first.subskill, 'rifq_hazm'); // focus wins even though not due
    expect(plan.length, 3);
    expect(plan.map((i) => i.subskill), isNot(contains('rifq_nush'))); // capped
    // an 'S' item carries a scenario id
    final s = plan.firstWhere((i) => i.track == 'S');
    expect(s.scenarioId, isNotNull);
  });
}

AkhlaqAttempt att2(String scenarioId, String sub) => AkhlaqAttempt(
      subskill: sub,
      scenarioId: scenarioId,
      chosenKey: 'A',
      verdict: 'maqbul',
      quality: 3,
      difficulty: 5,
      dimScore: const {},
      answeredAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
    );
