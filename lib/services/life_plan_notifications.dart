/// Pure scheduling policy for «مُحرّك الحياة» (Life Engine) local
/// notifications — no plugin, no I/O, so `test/` can exercise it directly.
/// `NotificationService.scheduleLifePlanReminders` turns each [LifeReminder]
/// into a `zonedSchedule` call; the recurring 05:00 morning brief is a plain
/// daily alarm handled there, not here.
///
/// L4 of `docs/LIFE_ENGINE.md`. Everything here is TODAY-only and one-shot:
/// callers reschedule on every app open and at midnight, so a completed or
/// already-started block simply drops out on the next pass.
library;

import '../models/life_plan.dart';

/// Notification id band. Per-block reminders take `base + slot_no` (slot_no
/// is 1..~23, a stable id); the fixed ids sit clear above the block band and
/// clear of every range `NotificationService` already reserves
/// (…, 11000 + categoryId for custom adhkar).
const int kLifeSlotReminderIdBase = 12000;
const int kLifeSlotReminderIdMax = 12060; // cancel-sweep upper bound
const int kLifeMorningBriefId = 12100;
const int kLifeNightlyReviewId = 12101;

/// 05:00 morning brief · 21:30 nightly «حاسب نفسك».
const int kLifeMorningBriefHour = 5;
const int kLifeNightlyReviewHour = 21;
const int kLifeNightlyReviewMinute = 30;

/// `HH:MM` from minutes-since-midnight — render LTR at call sites.
String lifeHhmm(int minutesSinceMidnight) {
  final h = (minutesSinceMidnight ~/ 60).toString().padLeft(2, '0');
  final m = (minutesSinceMidnight % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// One scheduled Life-Engine reminder — plain data. [payload] is the deep-
/// link tapped-notification target (`'life'` → the engine, `'life_note'` →
/// straight into today's reflection sheet).
class LifeReminder {
  final int id;
  final DateTime fireAt;
  final String title;
  final String body;
  final String payload;
  const LifeReminder({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    this.payload = 'life',
  });
}

/// TODAY's one-shot reminders: every block that is not ticked and whose
/// start is still ahead of `now`, plus tonight's «حاسب نفسك» if 21:30 hasn't
/// passed. All display strings are pre-localized by the caller.
List<LifeReminder> planLifeReminders({
  required List<LifeSlot> slots,
  required Set<int> doneSlotNos,
  required DateTime now,
  required String slotBody,
  required String nightlyTitle,
  required String nightlyBody,
}) {
  final midnight = DateTime(now.year, now.month, now.day);
  final nowMin = now.hour * 60 + now.minute;
  final out = <LifeReminder>[];

  for (final s in slots) {
    if (doneSlotNos.contains(s.slotNo)) continue;
    if (s.startMin <= nowMin) continue; // already began / passed today
    out.add(LifeReminder(
      id: kLifeSlotReminderIdBase + s.slotNo,
      fireAt: midnight.add(Duration(minutes: s.startMin)),
      title: '⏰ ${lifeHhmm(s.startMin)} — ${s.activity}',
      body: slotBody,
    ));
  }

  const nightlyMin = kLifeNightlyReviewHour * 60 + kLifeNightlyReviewMinute;
  if (nowMin < nightlyMin) {
    out.add(LifeReminder(
      id: kLifeNightlyReviewId,
      fireAt: midnight.add(const Duration(minutes: nightlyMin)),
      title: nightlyTitle,
      body: nightlyBody,
      payload: 'life_note', // tap → straight into the reflection sheet
    ));
  }
  return out;
}
