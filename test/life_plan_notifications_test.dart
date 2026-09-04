import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/models/life_plan.dart';
import 'package:talib_alilm_app/services/life_plan_notifications.dart';

/// «مُحرّك الحياة» L4 — the pure reminder planner. TODAY-only, one-shot:
/// only not-done, still-upcoming blocks get a nudge, plus tonight's review
/// while 21:30 is still ahead.
void main() {
  // A trimmed stand-in for the real 23-slot seed.
  final slots = <LifeSlot>[
    const LifeSlot(slotNo: 1, startMin: 300, endMin: 330, activity: '🕌 فجر', mihwar: 'روحي'),
    const LifeSlot(slotNo: 2, startMin: 330, endMin: 390, activity: '📖 حفظ القرآن', mihwar: 'قرآن', pillarKey: 'quran'),
    const LifeSlot(slotNo: 6, startMin: 510, endMin: 570, activity: '💻 Python / برمجة', mihwar: 'تطوير', pillarKey: 'coding'),
    const LifeSlot(slotNo: 20, startMin: 1170, endMin: 1230, activity: '📖 مراجعة الحفظ', mihwar: 'قرآن', pillarKey: 'quran'),
  ];

  DateTime at(int h, int m) => DateTime(2026, 9, 4, h, m);

  test('hhmm formats minutes-since-midnight, LTR-safe', () {
    expect(lifeHhmm(0), '00:00');
    expect(lifeHhmm(330), '05:30');
    expect(lifeHhmm(510), '08:30');
    expect(lifeHhmm(1290), '21:30');
  });

  test('mid-morning: only later, not-done blocks + tonight\'s review', () {
    final out = planLifeReminders(
      slots: slots,
      doneSlotNos: {2}, // already memorised today
      now: at(9, 0), // 540 min
      slotBody: 'اليوم 5',
      nightlyTitle: 'حاسب نفسك',
      nightlyBody: 'أنجزت 1/23 اليوم.',
    );

    // slot 1 (05:00) & slot 2 (done) drop out; slot 6 (08:30) is already
    // past 09:00 → drops out; only slot 20 (19:30) remains + the review.
    final ids = out.map((r) => r.id).toList();
    expect(ids, containsAll([kLifeSlotReminderIdBase + 20, kLifeNightlyReviewId]));
    expect(ids, isNot(contains(kLifeSlotReminderIdBase + 1)));
    expect(ids, isNot(contains(kLifeSlotReminderIdBase + 2)));
    expect(ids, isNot(contains(kLifeSlotReminderIdBase + 6)));
    expect(out.length, 2);

    final slot20 = out.firstWhere((r) => r.id == kLifeSlotReminderIdBase + 20);
    expect(slot20.fireAt, at(19, 30));
    expect(slot20.title, contains('19:30'));
    expect(slot20.title, contains('مراجعة الحفظ'));
    expect(slot20.body, 'اليوم 5');

    final review = out.firstWhere((r) => r.id == kLifeNightlyReviewId);
    expect(review.fireAt, at(21, 30));
    expect(review.title, 'حاسب نفسك');
  });

  test('early morning: every block ahead is scheduled', () {
    final out = planLifeReminders(
      slots: slots,
      doneSlotNos: const {},
      now: at(4, 0),
      slotBody: 'اليوم 1',
      nightlyTitle: 'حاسب نفسك',
      nightlyBody: 'لم تُسجّل شيئًا.',
    );
    expect(out.map((r) => r.id), [
      kLifeSlotReminderIdBase + 1,
      kLifeSlotReminderIdBase + 2,
      kLifeSlotReminderIdBase + 6,
      kLifeSlotReminderIdBase + 20,
      kLifeNightlyReviewId,
    ]);
    expect(out.first.fireAt, at(5, 0));
  });

  test('after 21:30: no nightly review, only any block still ahead', () {
    final out = planLifeReminders(
      slots: slots,
      doneSlotNos: const {},
      now: at(22, 0),
      slotBody: 'اليوم 5',
      nightlyTitle: 'حاسب نفسك',
      nightlyBody: 'x',
    );
    expect(out, isEmpty); // slot 20 (19:30) already passed, review gate closed
  });

  test('block exactly at "now" counts as already started (excluded)', () {
    final out = planLifeReminders(
      slots: slots,
      doneSlotNos: const {},
      now: at(8, 30), // == slot 6 start (510)
      slotBody: 'اليوم 5',
      nightlyTitle: 'حاسب نفسك',
      nightlyBody: 'x',
    );
    expect(out.map((r) => r.id), isNot(contains(kLifeSlotReminderIdBase + 6)));
    expect(out.map((r) => r.id), contains(kLifeSlotReminderIdBase + 20));
  });
}
