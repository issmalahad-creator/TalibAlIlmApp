import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_alilm_app/services/notification_policy.dart';

/// N2 (NOTIFICATIONS_ARCHITECTURE.md §3.2): encouragement reminders respect
/// quiet hours and a daily cap; nothing else is touched.
void main() {
  DateTime? plan(DateTime want, {List<DateTime> booked = const [], int daily = 0, int cap = 2}) =>
      planEncouragement(
        want: want,
        bookedDays: booked,
        dailyRecurring: daily,
        cap: cap,
        quietEnabled: true,
        quietStart: 22,
        quietEnd: 6,
      );

  group('planEncouragement', () {
    test('outside quiet hours and under the cap: unchanged', () {
      expect(plan(DateTime(2026, 9, 28, 20, 15)), DateTime(2026, 9, 28, 20, 15));
    });

    test('late evening moves to the window end the next morning', () {
      expect(plan(DateTime(2026, 9, 28, 23, 40)), DateTime(2026, 9, 29, 6));
    });

    test('small hours move to the window end the same morning', () {
      expect(plan(DateTime(2026, 9, 29, 2, 10)), DateTime(2026, 9, 29, 6));
    });

    test('a full day pushes to the next day, same time', () {
      final day = DateTime(2026, 9, 28);
      expect(plan(DateTime(2026, 9, 28, 20), booked: [day, day]), DateTime(2026, 9, 29, 20));
    });

    test('daily-repeating reminders count against every day', () {
      expect(plan(DateTime(2026, 9, 28, 20), booked: [DateTime(2026, 9, 28)], daily: 1),
          DateTime(2026, 9, 29, 20));
    });

    test('no room within the horizon: skipped, not pushed forever', () {
      expect(plan(DateTime(2026, 9, 28, 20), daily: 2), isNull);
    });

    test('quiet hours off: evening time kept', () {
      expect(
        planEncouragement(
          want: DateTime(2026, 9, 28, 23),
          bookedDays: const [],
          dailyRecurring: 0,
          cap: 2,
          quietEnabled: false,
          quietStart: 22,
          quietEnd: 6,
        ),
        DateTime(2026, 9, 28, 23),
      );
    });
  });

  group('NotificationPolicy ledger', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    final now = DateTime(2026, 9, 28, 12);

    test('third reminder on the same day moves to tomorrow (cap 2)', () async {
      final p = NotificationPolicy.instance;
      expect(await p.place(Encouragement.hifz, DateTime(2026, 9, 28, 18), now: now), DateTime(2026, 9, 28, 18));
      expect(await p.place(Encouragement.companion, DateTime(2026, 9, 28, 20), now: now), DateTime(2026, 9, 28, 20));
      expect(await p.place(Encouragement.reading, DateTime(2026, 9, 28, 19), now: now), DateTime(2026, 9, 29, 19));
    });

    test('rescheduling a kind replaces its own booking instead of stacking', () async {
      final p = NotificationPolicy.instance;
      await p.place(Encouragement.hifz, DateTime(2026, 9, 28, 18), now: now);
      await p.place(Encouragement.hifz, DateTime(2026, 9, 28, 19), now: now);
      expect(await p.place(Encouragement.companion, DateTime(2026, 9, 28, 20), now: now), DateTime(2026, 9, 28, 20));
    });

    test('a disabled kind is never scheduled and frees its slot', () async {
      final p = NotificationPolicy.instance;
      await p.place(Encouragement.hifz, DateTime(2026, 9, 28, 18), now: now);
      await p.setEnabled(Encouragement.hifz, false);
      expect(await p.place(Encouragement.hifz, DateTime(2026, 9, 28, 18), now: now), isNull);
      await p.place(Encouragement.companion, DateTime(2026, 9, 28, 20), now: now);
      expect(await p.place(Encouragement.reading, DateTime(2026, 9, 28, 19), now: now), DateTime(2026, 9, 28, 19));
    });

    test('past bookings expire', () async {
      final p = NotificationPolicy.instance;
      await p.place(Encouragement.hifz, DateTime(2026, 9, 28, 13), now: now);
      await p.place(Encouragement.companion, DateTime(2026, 9, 28, 14), now: now);
      final later = DateTime(2026, 9, 28, 15);
      expect(await p.place(Encouragement.reading, DateTime(2026, 9, 28, 17), now: later), DateTime(2026, 9, 28, 17));
    });
  });
}
