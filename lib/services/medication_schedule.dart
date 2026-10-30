/// Pure scheduling for «علاجاتي» — no plugin, no I/O, so `test/` exercises
/// it directly. `MedicationRepository` stores what [buildMedicationDoses]
/// returns; `NotificationService.scheduleMedicationReminders` turns
/// [planMedicationReminders] into `zonedSchedule` calls.
library;

import '../l10n/basic_translations.dart';
import '../models/medication.dart';

/// Notification id band: `base + i` for the i-th upcoming dose. Android caps
/// an app at ~500 pending alarms, so only the next [kMedReminderMax] doses
/// within [kMedReminderHorizon] are queued; every app open and every change
/// re-plans the window, so a long course keeps rolling forward.
const int kMedReminderIdBase = 20000;
const int kMedReminderMax = 300;
const Duration kMedReminderHorizon = Duration(days: 10);

/// How many doses a course has — what the person checks against the
/// prescription («21 جرعة»).
int medicationDoseCount(MedCourse c) {
  if (c.durationDays <= 0) return 0;
  if (c.mode == MedScheduleMode.interval) {
    if (c.intervalHours <= 0) return 0;
    return (c.durationDays * 24 / c.intervalHours).round().clamp(1, 10000);
  }
  return c.durationDays * c.timesOfDay.length;
}

/// Every dose of the course, in order.
///
/// * Interval: the first dose at `startAt`, then every `intervalHours` of
///   real elapsed time (a DST change does not stretch an 8-hour gap to 9).
/// * Fixed times: the clock times every day, starting from the first one at
///   or after `startAt`, until the full count is reached — starting a
///   «صباحًا ومساءً» course at noon still gives the whole number of doses,
///   the last one simply falls on the morning after the last day.
List<MedDose> buildMedicationDoses(MedCourse c, {int courseId = 0}) {
  final n = medicationDoseCount(c);
  final out = <MedDose>[];
  if (n == 0) return out;
  if (c.mode == MedScheduleMode.interval) {
    for (var k = 0; k < n; k++) {
      out.add(MedDose(courseId: courseId, seq: k + 1, scheduledAt: c.startAt.add(Duration(hours: c.intervalHours * k))));
    }
    return out;
  }
  final times = [...c.timesOfDay]..sort();
  final s = c.startAt;
  for (var day = 0; out.length < n; day++) {
    for (final t in times) {
      final at = DateTime(s.year, s.month, s.day + day, t ~/ 60, t % 60);
      if (at.isBefore(DateTime(s.year, s.month, s.day, s.hour, s.minute))) continue;
      out.add(MedDose(courseId: courseId, seq: out.length + 1, scheduledAt: at));
      if (out.length == n) break;
    }
  }
  return out;
}

/// Evenly spread [timesPerDay] clock times from [firstMinute] — what a
/// «3 مرات يوميًا» prescription means when the person picks fixed times
/// (08:00 → 08:00 · 16:00 · 00:00). Sorted, wrapped to the day.
List<int> spreadTimesOfDay(int firstMinute, int timesPerDay) {
  if (timesPerDay <= 0) return const [];
  final gap = 1440 ~/ timesPerDay;
  return [for (var i = 0; i < timesPerDay; i++) (firstMinute + gap * i) % 1440]..sort();
}

/// A ready-made schedule from the add screen. [exampleKey] names a common
/// prescription shown as an example only — the person always follows their
/// own doctor's prescription.
class MedPreset {
  final String id;
  final String labelKey;
  final String exampleKey;
  final MedScheduleMode mode;
  final int intervalHours;
  final List<int> timesOfDay;
  final int days;
  const MedPreset({
    required this.id,
    required this.labelKey,
    required this.exampleKey,
    required this.mode,
    this.intervalHours = 8,
    this.timesOfDay = const [],
    required this.days,
  });
}

/// Common antibiotic / medicine schedules (standard adult regimens as
/// usually prescribed — examples, never a recommendation).
const kMedPresets = <MedPreset>[
  MedPreset(id: 'q8', labelKey: 'med_preset_q8', exampleKey: 'med_example_q8', mode: MedScheduleMode.interval, intervalHours: 8, days: 7),
  MedPreset(id: 'q12', labelKey: 'med_preset_q12', exampleKey: 'med_example_q12', mode: MedScheduleMode.interval, intervalHours: 12, days: 7),
  MedPreset(id: 'q6', labelKey: 'med_preset_q6', exampleKey: 'med_example_q6', mode: MedScheduleMode.interval, intervalHours: 6, days: 7),
  MedPreset(id: 'q24', labelKey: 'med_preset_q24', exampleKey: 'med_example_q24', mode: MedScheduleMode.interval, intervalHours: 24, days: 3),
  MedPreset(id: 'am_pm', labelKey: 'med_preset_am_pm', exampleKey: 'med_example_am_pm', mode: MedScheduleMode.fixedTimes, timesOfDay: [8 * 60, 20 * 60], days: 10),
  MedPreset(id: 'meals', labelKey: 'med_preset_meals', exampleKey: 'med_example_meals', mode: MedScheduleMode.fixedTimes, timesOfDay: [8 * 60, 14 * 60, 20 * 60], days: 5),
];

/// One queued reminder — plain data, strings pre-localized by the caller.
class MedReminder {
  final int id;
  final DateTime fireAt;
  final String title;
  final String body;
  const MedReminder({required this.id, required this.fireAt, required this.title, required this.body});
}

/// The rolling reminder window: pending doses of courses with reminders on,
/// still ahead of [now], within [kMedReminderHorizon], earliest first,
/// capped at [kMedReminderMax].
List<MedReminder> planMedicationReminders({
  required List<MedCourseWithDoses> courses,
  required DateTime now,
  required String Function(MedCourse course, MedDose dose, int total) title,
  required String Function(MedCourse course, MedDose dose, int total) body,
}) {
  final horizon = now.add(kMedReminderHorizon);
  final picks = <(MedCourse, MedDose, int)>[];
  for (final c in courses) {
    if (!c.course.remindersOn) continue;
    for (final d in c.doses) {
      if (!d.isPending || !d.scheduledAt.isAfter(now) || d.scheduledAt.isAfter(horizon)) continue;
      picks.add((c.course, d, c.total));
    }
  }
  picks.sort((a, b) => a.$2.scheduledAt.compareTo(b.$2.scheduledAt));
  return [
    for (var i = 0; i < picks.length && i < kMedReminderMax; i++)
      MedReminder(
        id: kMedReminderIdBase + i,
        fireAt: picks[i].$2.scheduledAt,
        title: title(picks[i].$1, picks[i].$2, picks[i].$3),
        body: body(picks[i].$1, picks[i].$2, picks[i].$3),
      ),
  ];
}

/// `HH:MM` from minutes-since-midnight — render LTR at call sites.
String medHhmm(int minutesSinceMidnight) =>
    '${(minutesSinceMidnight ~/ 60).toString().padLeft(2, '0')}:${(minutesSinceMidnight % 60).toString().padLeft(2, '0')}';

/// «اليوم» / «غدًا» / d/M — short and language-neutral.
String medDayLabel(DateTime d, String lang) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
  if (diff == 0) return basicText('med_today', lang);
  if (diff == 1) return basicText('med_tomorrow', lang);
  if (diff == -1) return basicText('med_yesterday', lang);
  return '${d.day}/${d.month}';
}

String medTimeOf(DateTime d) => medHhmm(d.hour * 60 + d.minute);
