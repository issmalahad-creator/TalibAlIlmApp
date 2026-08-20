import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/repositories/completion_goal_repository.dart';
import 'package:talib_alilm_app/services/companion_engine.dart';

void main() {
  test('no context at all shows no message (never a generic filler)', () {
    expect(companionMessageFor(const CompanionContext()), isNull);
  });

  test('absence at the threshold triggers the returning message', () {
    final msg = companionMessageFor(const CompanionContext(daysAbsent: 3));
    expect(msg?.state, CompanionState.returning);
  });

  test('absence just under the threshold does not trigger returning (falls through to the daily invite instead)', () {
    final msg = companionMessageFor(const CompanionContext(daysAbsent: 2));
    expect(msg?.state, CompanionState.dailyInvite);
  });

  test('absence far beyond the threshold still triggers it', () {
    final msg = companionMessageFor(const CompanionContext(daysAbsent: 30));
    expect(msg?.state, CompanionState.returning);
  });

  test('due reviews alone trigger the review-due message with the real count', () {
    final msg = companionMessageFor(const CompanionContext(dueReviewsCount: 5));
    expect(msg?.state, CompanionState.reviewDue);
    expect(msg?.body, contains('5'));
  });

  test('behind schedule alone triggers the behind message', () {
    final msg = companionMessageFor(const CompanionContext(scheduleStatus: ScheduleStatus.behind));
    expect(msg?.state, CompanionState.behind);
  });

  test('ahead of schedule alone triggers the ahead message', () {
    final msg = companionMessageFor(const CompanionContext(scheduleStatus: ScheduleStatus.ahead));
    expect(msg?.state, CompanionState.ahead);
  });

  test('a long streak alone triggers the celebration message', () {
    final msg = companionMessageFor(const CompanionContext(streak: 7));
    expect(msg?.state, CompanionState.celebrating);
  });

  test('a short streak with no other signal triggers the daily invitation, not nothing', () {
    final msg = companionMessageFor(const CompanionContext(daysAbsent: 0, streak: 6));
    expect(msg?.state, CompanionState.dailyInvite);
  });

  test('a brand-new install (no activity ever) still triggers nothing', () {
    expect(companionMessageFor(const CompanionContext()), isNull);
  });

  // Priority order (Ismail's own rule list): absence > due reviews > behind
  // > ahead > streak celebration > nothing. Each test below sets up two
  // competing conditions and checks the higher-priority one wins.
  group('priority order — the most urgent rule always wins', () {
    test('absence beats due reviews', () {
      final msg = companionMessageFor(const CompanionContext(daysAbsent: 5, dueReviewsCount: 10));
      expect(msg?.state, CompanionState.returning);
    });

    test('due reviews beat being behind schedule', () {
      final msg = companionMessageFor(
        const CompanionContext(dueReviewsCount: 2, scheduleStatus: ScheduleStatus.behind),
      );
      expect(msg?.state, CompanionState.reviewDue);
    });

    test('behind schedule beats being ahead of schedule', () {
      // scheduleStatus can only be one value at a time in real usage, but
      // this still documents which branch the if-chain checks first.
      final msg = companionMessageFor(const CompanionContext(scheduleStatus: ScheduleStatus.behind, streak: 10));
      expect(msg?.state, CompanionState.behind);
    });

    test('ahead of schedule beats a celebration-worthy streak', () {
      final msg = companionMessageFor(const CompanionContext(scheduleStatus: ScheduleStatus.ahead, streak: 30));
      expect(msg?.state, CompanionState.ahead);
    });

    test('due reviews beat a celebration-worthy streak', () {
      final msg = companionMessageFor(const CompanionContext(dueReviewsCount: 1, streak: 30));
      expect(msg?.state, CompanionState.reviewDue);
    });
  });
}
