import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/medication.dart';
import 'package:talib_alilm_app/repositories/medication_repository.dart';
import 'package:talib_alilm_app/services/medication_schedule.dart';

/// «علاجاتي» — the dose calculator, the reminder window and the repository.
void main() {
  group('buildMedicationDoses', () {
    test('every 8 hours for 7 days = 21 doses, 8 h apart', () {
      final c = MedCourse(name: 'Amoxicillin', mode: MedScheduleMode.interval, intervalHours: 8, durationDays: 7, startAt: DateTime(2026, 11, 1, 7));
      final d = buildMedicationDoses(c);
      expect(d.length, 21);
      expect(d.first.scheduledAt, DateTime(2026, 11, 1, 7));
      expect(d[1].scheduledAt, DateTime(2026, 11, 1, 15));
      expect(d[2].scheduledAt, DateTime(2026, 11, 1, 23));
      expect(d.last.scheduledAt, DateTime(2026, 11, 7, 23));
      expect(d.map((x) => x.seq), List.generate(21, (i) => i + 1));
    });

    test('every 12 h × 7 = 14, every 6 h × 7 = 28, daily × 3 = 3', () {
      MedCourse c(int h, int days) => MedCourse(name: 'x', mode: MedScheduleMode.interval, intervalHours: h, durationDays: days, startAt: DateTime(2026, 11, 1, 9));
      expect(buildMedicationDoses(c(12, 7)).length, 14);
      expect(buildMedicationDoses(c(6, 7)).length, 28);
      expect(buildMedicationDoses(c(24, 3)).map((d) => d.scheduledAt.day), [1, 2, 3]);
    });

    test('morning and evening started at noon still gives the full count', () {
      final c = MedCourse(name: 'x', mode: MedScheduleMode.fixedTimes, timesOfDay: const [20 * 60, 8 * 60], durationDays: 2, startAt: DateTime(2026, 11, 1, 12));
      final d = buildMedicationDoses(c).map((x) => x.scheduledAt).toList();
      expect(d, [DateTime(2026, 11, 1, 20), DateTime(2026, 11, 2, 8), DateTime(2026, 11, 2, 20), DateTime(2026, 11, 3, 8)]);
    });

    test('fixed times started before the first time uses that day fully', () {
      final c = MedCourse(name: 'x', mode: MedScheduleMode.fixedTimes, timesOfDay: const [8 * 60, 14 * 60, 20 * 60], durationDays: 1, startAt: DateTime(2026, 11, 1, 6));
      expect(buildMedicationDoses(c).map((x) => x.scheduledAt.hour), [8, 14, 20]);
    });

    test('nothing for zero days', () {
      expect(buildMedicationDoses(MedCourse(name: 'x', mode: MedScheduleMode.interval, durationDays: 0, startAt: DateTime(2026))), isEmpty);
    });
  });

  test('spreadTimesOfDay spreads evenly and wraps the day', () {
    expect(spreadTimesOfDay(8 * 60, 3), [0, 8 * 60, 16 * 60]);
    expect(spreadTimesOfDay(9 * 60, 2), [9 * 60, 21 * 60]);
  });

  test('every preset produces a real schedule', () {
    for (final p in kMedPresets) {
      final c = MedCourse(name: 'x', mode: p.mode, intervalHours: p.intervalHours, timesOfDay: p.timesOfDay, durationDays: p.days, startAt: DateTime(2026, 11, 1, 7));
      expect(buildMedicationDoses(c), isNotEmpty, reason: p.id);
    }
  });

  test('reminder window: only pending, future, within horizon, reminders-on, earliest first', () {
    final now = DateTime(2026, 11, 1, 10);
    final a = MedCourse(id: 1, name: 'A', mode: MedScheduleMode.interval, intervalHours: 8, durationDays: 30, startAt: DateTime(2026, 11, 1, 7));
    final b = MedCourse(id: 2, name: 'B', mode: MedScheduleMode.interval, intervalHours: 12, durationDays: 3, startAt: DateTime(2026, 11, 1, 9), remindersOn: false);
    final aDoses = buildMedicationDoses(a, courseId: 1).toList();
    aDoses[1] = MedDose(courseId: 1, seq: 2, scheduledAt: aDoses[1].scheduledAt, status: MedDoseStatus.taken);
    final plan = planMedicationReminders(
      courses: [MedCourseWithDoses(a, aDoses), MedCourseWithDoses(b, buildMedicationDoses(b, courseId: 2))],
      now: now,
      title: (c, d, t) => c.name,
      body: (c, d, t) => '${d.seq}/$t',
    );
    expect(plan.every((r) => r.title == 'A'), isTrue);
    expect(plan.first.fireAt, DateTime(2026, 11, 1, 23)); // 07:00 passed, 15:00 taken
    expect(plan.last.fireAt.isAfter(now.add(kMedReminderHorizon)), isFalse);
    expect(plan.map((r) => r.id).toSet().length, plan.length);
    expect(plan.first.id, kMedReminderIdBase);
  });

  group('MedicationRepository', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final repo = MedicationRepository();

    setUpAll(() async {
      DatabaseHelper.databaseName = 'talib_med_test.db';
      final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    });

    test('save, take, move with shift, edit keeps history, delete', () async {
      final soon = DateTime.now().add(const Duration(hours: 1));
      final start = DateTime(soon.year, soon.month, soon.day, soon.hour, soon.minute);
      final id = await repo.saveCourse(MedCourse(name: 'Augmentin', doseNote: '1 g', mode: MedScheduleMode.interval, intervalHours: 12, durationDays: 7, startAt: start));
      var c = (await repo.course(id))!;
      expect(c.total, 14);

      await repo.setDoseStatus(c.doses[0].id!, MedDoseStatus.taken);
      await repo.moveDose(c.doses[1], c.doses[1].scheduledAt.add(const Duration(hours: 2)), shiftFollowing: true);
      c = (await repo.course(id))!;
      expect(c.taken, 1);
      expect(c.doses[1].scheduledAt, start.add(const Duration(hours: 14)));
      expect(c.doses[13].scheduledAt, start.add(const Duration(hours: 12 * 13 + 2)));

      // Edit to every 8 hours: the taken dose stays, the rest is re-planned.
      await repo.saveCourse(c.course.copyWith(intervalHours: 8));
      c = (await repo.course(id))!;
      expect(c.total, 21);
      expect(c.doses.first.status, MedDoseStatus.taken);
      expect(c.doses.map((d) => d.seq), List.generate(21, (i) => i + 1));

      final next = await repo.nextDose(DateTime.now());
      expect(next?.$2.courseId, id);

      await repo.deleteCourse(id);
      expect(await repo.course(id), isNull);
      expect(await repo.courses(), isEmpty);
    });
  });
}
