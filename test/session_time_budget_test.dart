import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/data/session_time_budget.dart';

int _minutesOf(List<SessionPhase> plan, String key) => plan.firstWhere((p) => p.key == key).minutes;
int _total(List<SessionPhase> plan) => plan.fold(0, (a, p) => a + p.minutes);

void main() {
  group('computeSessionPlan backward compatibility', () {
    test('no backlog args behaves exactly as before (existing call sites unaffected)', () {
      final plan = computeSessionPlan('beginner', 60);
      expect(_total(plan), 60);
      expect(_minutesOf(plan, 'new_memorization'), 21); // 60*0.35 floored, unaffected by top-up
    });

    test('total always sums to totalMinutes regardless of backlog size', () {
      final plan = computeSessionPlan('intermediate', 45, dueQuranReviews: 50, dueKnowledgeReviews: 50);
      expect(_total(plan), 45);
    });
  });

  group('computeSessionPlan greedy backlog top-up', () {
    test('a real backlog increases quick_review at the expense of understanding/new_memorization', () {
      final baseline = computeSessionPlan('beginner', 60);
      final withBacklog = computeSessionPlan('beginner', 60, dueQuranReviews: 20, dueKnowledgeReviews: 10);
      expect(_minutesOf(withBacklog, 'quick_review'), greaterThan(_minutesOf(baseline, 'quick_review')));
      expect(_minutesOf(withBacklog, 'understanding') + _minutesOf(withBacklog, 'new_memorization'),
          lessThan(_minutesOf(baseline, 'understanding') + _minutesOf(baseline, 'new_memorization')));
    });

    test('no phase is ever thinned below the floor even with a huge backlog', () {
      final plan = computeSessionPlan('beginner', 30, dueQuranReviews: 500, dueKnowledgeReviews: 500);
      expect(_minutesOf(plan, 'understanding'), greaterThanOrEqualTo(0));
      expect(_minutesOf(plan, 'new_memorization'), greaterThanOrEqualTo(0));
    });

    test('a small backlog that fits within the existing quick_review share changes nothing', () {
      final baseline = computeSessionPlan('advanced', 60);
      final tinyBacklog = computeSessionPlan('advanced', 60, dueQuranReviews: 1);
      expect(_minutesOf(tinyBacklog, 'quick_review'), _minutesOf(baseline, 'quick_review'));
    });
  });
}
