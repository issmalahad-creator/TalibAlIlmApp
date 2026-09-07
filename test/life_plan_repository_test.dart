import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/life_plan.dart';
import 'package:talib_alilm_app/repositories/life_plan_repository.dart';

/// «مُحرّك الحياة» L1 — the continuous daily engine. No 90‑day ceiling:
/// day index is unbounded, progress is rolling, the streak tolerates a miss.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final repo = LifePlanRepository();
  final today = LifePlanRepository.today();

  Future<void> clearTicks() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('life_day_slots');
    await db.delete('life_day_notes');
    await db.delete('life_meta',
        where: "k LIKE 'cycle_note_%' OR k = 'last_cycle_reviewed'");
    await repo.setMeta('start_date', today); // reset unless a test moves it
  }

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_life_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await repo.ensureSeeded();
  });

  setUp(clearTicks);

  test('seeds 7 pillars + 23 slots from the real sheet', () async {
    final pillars = await repo.pillars();
    final slots = await repo.slots();
    expect(pillars.map((e) => e.key),
        containsAll(['quran', 'books', 'social', 'coding', 'erp', 'micro', 'jobs']));
    expect(slots.length, 23);
    expect(slots.first.startMin, 300); // 05:00
    expect(slots.last.endMin, 1320); // 22:00
    // 12 tracked slots: quran×3, books×2, social×2, erp×2, coding×1, micro×1, jobs×1
    expect(slots.where((s) => s.isTracked).length, 12);
    expect(slots.firstWhere((s) => s.slotNo == 2).pillarKey, 'quran');
    expect(slots.firstWhere((s) => s.slotNo == 6).pillarKey, 'coding');
  });

  test('day index is unbounded (no 90‑day ceiling)', () async {
    await repo.setMeta('start_date',
        LifePlanRepository.ymd(DateTime.now().subtract(const Duration(days: 400))));
    expect(await repo.dayIndex(), greaterThan(90));
    final prog = await repo.progress(today);
    expect(prog.dayIndex, greaterThan(90));
    expect(prog.cycle(), greaterThan(1)); // cycle is a soft milestone only
  });

  test('toggle a slot → progress + per‑pillar reflect it', () async {
    for (final n in [2, 12, 20, 6]) {
      expect(await repo.toggleSlot(today, n), isTrue);
    }
    final prog = await repo.progress(today);
    expect(prog.doneCount, 4);
    expect(prog.totalCount, 23);
    expect(prog.byPillar['quran'], closeTo(1.0, 1e-9)); // all 3 quran slots
    expect(prog.byPillar['coding'], closeTo(1.0, 1e-9)); // its 1 slot
    expect(prog.byPillar['erp'], 0.0); // 2 slots, none ticked
    expect(prog.byPillar['books'], 0.0);
    expect(await repo.toggleSlot(today, 2), isFalse); // untoggle
    expect((await repo.progress(today)).byPillar['quran'], closeTo(2 / 3, 1e-9));
  });

  test('streak counts consecutive ≥threshold days and tolerates one miss',
      () async {
    final now = DateTime.now();
    Future<void> fill(int daysAgo, int count) async {
      final d = LifePlanRepository.ymd(now.subtract(Duration(days: daysAgo)));
      for (var i = 1; i <= count; i++) {
        await repo.setSlotDone(d, i, true);
      }
    }

    // threshold 0.6 of 23 ≈ 14. yesterday..-4 strong; -2 weak (forgiven by
    // the 1 grace/week); -5 weak → breaks.
    await fill(1, 16);
    await fill(2, 3);
    await fill(3, 16);
    await fill(4, 16);
    await fill(5, 2);
    expect(await repo.streak(), 4);
  });

  test('rolling average + pillar momentum are computed, not stored', () async {
    for (final n in [1, 2, 3, 4, 5, 6]) {
      await repo.setSlotDone(today, n, true);
    }
    final avg = await repo.rollingAverage(7);
    expect(avg, greaterThan(0));
    expect(avg, lessThan(1));
    final mom = await repo.pillarMomentum();
    expect(mom.keys, containsAll(['quran', 'coding']));
    expect(mom['quran'], greaterThan(0)); // slot 2 ticked today, weighted
    expect(mom['jobs'], 0.0); // slot 13 untouched
  });

  test('dayPercents batches a date range in one pass', () async {
    final now = DateTime.now();
    final d1 = LifePlanRepository.ymd(now.subtract(const Duration(days: 1)));
    final d2 = LifePlanRepository.ymd(now.subtract(const Duration(days: 2)));
    for (var i = 1; i <= 23; i++) {
      await repo.setSlotDone(d1, i, true); // a full day
    }
    for (var i = 1; i <= 12; i++) {
      await repo.setSlotDone(d2, i, true); // ~half
    }
    final m = await repo.dayPercents(d2, d1);
    expect(m[d1], closeTo(1.0, 1e-9));
    expect(m[d2], closeTo(12 / 23, 1e-9));
    expect(m[today], isNull); // no ticks today → not in the map
  });

  test('pillarMomentumTrend flags a real slip', () async {
    final now = DateTime.now();
    // previous 7-day window (offset 7..13): strong quran
    for (var i = 7; i < 14; i++) {
      final d = LifePlanRepository.ymd(now.subtract(Duration(days: i)));
      for (final n in [2, 12, 20]) {
        await repo.setSlotDone(d, n, true);
      }
    }
    // last 7 days: nothing → quran momentum collapses
    final tr = await repo.pillarMomentumTrend();
    expect(tr['quran']!.prev, greaterThan(0.5));
    expect(tr['quran']!.now, 0.0);
    expect(tr['quran']!.slipping, isTrue);
    expect(tr['jobs']!.slipping, isFalse); // never had momentum
  });

  test('day note round‑trips', () async {
    await repo.saveNote(today, note: 'يوم قوي', tomorrowGoal: 'ابدأ ERP مبكرًا');
    final n = await repo.note(today);
    expect(n?.note, 'يوم قوي');
    expect(n?.tomorrowGoal, 'ابدأ ERP مبكرًا');
    await repo.saveNote(today, mood: 4);
    expect((await repo.note(today))?.note, 'يوم قوي'); // preserved
    expect((await repo.note(today))?.mood, 4);
  });

  // ── L5 — weekly review + cycle rollover ────────────────────────────

  test('weeklyReview composes the last 7 days + pillar standing + notes',
      () async {
    final now = DateTime.now();
    Future<void> fill(int daysAgo, int count) async {
      final d = LifePlanRepository.ymd(now.subtract(Duration(days: daysAgo)));
      for (var i = 1; i <= count; i++) {
        await repo.setSlotDone(d, i, true);
      }
    }

    await fill(0, 16); // today ≥ threshold (0.6·23 ≈ 14)
    await fill(1, 16);
    await fill(2, 3); // a weak day
    await fill(8, 12); // in the *previous* week → feeds the delta
    await repo.saveNote(LifePlanRepository.ymd(now.subtract(const Duration(days: 1))),
        note: 'يوم منتج');
    await repo.saveNote(LifePlanRepository.ymd(now.subtract(const Duration(days: 3))),
        note: ''); // empty → filtered out

    final w = await repo.weeklyReview();
    expect(w.days.length, 7);
    expect(w.days.last.date.day, now.day); // newest is today
    expect(w.daysHitThreshold, 2); // today + yesterday
    expect(w.avgPercent, greaterThan(0));
    expect(w.avgPercent, greaterThan(w.prevAvgPercent)); // this week stronger
    expect(w.pillars.length, 7);
    // sorted: each `now` ≥ the next
    for (var i = 0; i + 1 < w.pillars.length; i++) {
      expect(w.pillars[i].now, greaterThanOrEqualTo(w.pillars[i + 1].now));
    }
    expect(w.notes.length, 1); // the empty one is dropped
    expect(w.notes.first.note, 'يوم منتج');
  });

  test('pendingCycleReview fires only after a full cycle, in order', () async {
    // fresh install (start_date = today) → nothing completed
    expect(await repo.pendingCycleReview(), isNull);

    // 100 days in → cycle 1 is done and unreviewed
    await repo.setMeta('start_date',
        LifePlanRepository.ymd(DateTime.now().subtract(const Duration(days: 100))));
    expect(await repo.pendingCycleReview(), 1);
    await repo.markCycleReviewed(1);
    expect(await repo.pendingCycleReview(), isNull);

    // 200 days in → cycle 2 is now also done; still reviews in order
    await repo.setMeta('start_date',
        LifePlanRepository.ymd(DateTime.now().subtract(const Duration(days: 200))));
    expect(await repo.pendingCycleReview(), 2);
    await repo.markCycleReviewed(2);
    expect(await repo.pendingCycleReview(), isNull);
  });

  test('cycle reflection note round‑trips', () async {
    expect(await repo.cycleNote(1), isNull);
    await repo.saveCycleNote(1, 'التزمت بالقرآن، وأهملت الرياضة');
    expect(await repo.cycleNote(1), 'التزمت بالقرآن، وأهملت الرياضة');
  });

  test('cycleSummary rolls up one completed cycle', () async {
    final start = DateTime.now().subtract(const Duration(days: 95));
    await repo.setMeta('start_date', LifePlanRepository.ymd(start));
    // three days inside cycle 1 (days 0, 5, 10 from start)
    for (final off in [0, 5, 10]) {
      final d = LifePlanRepository.ymd(start.add(Duration(days: off)));
      for (final n in [2, 12, 20, 6]) {
        await repo.setSlotDone(d, n, true);
      }
    }
    final s = await repo.cycleSummary(1);
    expect(s.cycle, 1);
    expect(s.lengthDays, 90);
    expect(s.blocksDone, 12); // 3 days × 4 blocks
    expect(s.avgPercent, closeTo((3 * 4 / 23) / 90, 1e-9));
    expect(s.byPillarDone['quran'], 9); // slots 2,12,20 × 3 days
    expect(s.byPillarDone['coding'], 3); // slot 6 × 3 days
  });

  // ── L6-DYN #1 — in-app authoring of the plan ──────────────────────────

  group('authoring', () {
    setUp(() => repo.resetStructureToSeed());

    test('add / edit a custom pillar; new key never collides', () async {
      final k = await repo.newPillarKey();
      expect(k, 'custom_1');
      await repo.upsertPillar(LifePillar(
          key: k, label: 'تصوير', emoji: '📷', cadence: LifeCadence.weekly,
          weeklyTarget: 2, color: '#1F7A6B', sort: 99));
      var ps = await repo.pillars();
      final added = ps.firstWhere((p) => p.key == k);
      expect(added.label, 'تصوير');
      expect(added.cadence, LifeCadence.weekly);
      expect(added.weeklyTarget, 2);
      expect(added.color, '#1F7A6B');
      // next key skips the taken one
      expect(await repo.newPillarKey(), 'custom_2');
      // edit in place (same key = replace)
      await repo.upsertPillar(added.copyWith(label: 'تصوير فوتوغرافي'));
      ps = await repo.pillars();
      expect(ps.firstWhere((p) => p.key == k).label, 'تصوير فوتوغرافي');
      expect(ps.where((p) => p.key == k).length, 1);
    });

    test('archive a seed pillar: hidden by default, still returned with flag',
        () async {
      await repo.setPillarArchived('erp', true);
      expect((await repo.pillars()).any((p) => p.key == 'erp'), isFalse);
      final all = await repo.pillars(includeArchived: true);
      expect(all.firstWhere((p) => p.key == 'erp').archived, isTrue);
      // its slots are detached, not deleted
      final erpSlots = (await repo.slots(includeArchived: true))
          .where((s) => s.pillarKey == 'erp');
      expect(erpSlots, isEmpty);
      await repo.setPillarArchived('erp', false);
      expect((await repo.pillars()).any((p) => p.key == 'erp'), isTrue);
    });

    test('seed pillar cannot be hard-deleted; unused custom one can', () async {
      expect(await repo.canHardDeletePillar('quran'), isFalse);
      final k = await repo.newPillarKey();
      await repo.upsertPillar(LifePillar(key: k, label: 'x'));
      expect(await repo.canHardDeletePillar(k), isTrue);
      await repo.hardDeletePillar(k);
      expect((await repo.pillars(includeArchived: true)).any((p) => p.key == k),
          isFalse);
    });

    test('reorderPillars persists a new sort order', () async {
      final before = (await repo.pillars()).map((p) => p.key).toList();
      final reversed = before.reversed.toList();
      await repo.reorderPillars(reversed);
      expect((await repo.pillars()).map((p) => p.key).toList(), reversed);
    });

    test('add a slot: id is max+1, shows in the day, counts in progress',
        () async {
      final no = await repo.upsertSlot(const LifeSlot(
          slotNo: 0,
          startMin: 13 * 60,
          endMin: 13 * 60 + 30,
          activity: 'مراجعة',
          pillarKey: 'quran'));
      expect(no, 24); // 23 seeded + 1
      final slots = await repo.slots();
      expect(slots.length, 24);
      expect(slots.firstWhere((s) => s.slotNo == 24).pillarKey, 'quran');
      await repo.setSlotDone(today, 24, true);
      final prog = await repo.progress(today);
      expect(prog.totalCount, 24);
      expect(prog.doneCount, 1);
    });

    test('edit a slot in place keeps its id and its ticks', () async {
      await repo.setSlotDone(today, 6, true);
      final s6 = (await repo.slots()).firstWhere((s) => s.slotNo == 6);
      await repo.upsertSlot(s6.copyWith(activity: 'مشروع', startMin: 9 * 60));
      final after = (await repo.slots()).firstWhere((s) => s.slotNo == 6);
      expect(after.activity, 'مشروع');
      expect(after.startMin, 9 * 60);
      expect((await repo.doneSlots(today)).contains(6), isTrue); // tick survived
    });

    test('archive vs hard-delete a slot depends on whether it was ever ticked',
        () async {
      // slot 6, never ticked in this fresh structure → hard-deletable
      expect(await repo.canHardDeleteSlot(6), isTrue);
      await repo.setSlotDone(today, 7, true);
      expect(await repo.canHardDeleteSlot(7), isFalse);
      await repo.hardDeleteSlot(7); // falls back to archive
      expect((await repo.slots()).any((s) => s.slotNo == 7), isFalse);
      expect((await repo.slots(includeArchived: true))
          .firstWhere((s) => s.slotNo == 7)
          .archived, isTrue);
      // an archived slot drops out of the day total
      expect((await repo.progress(today)).totalCount, 22);
    });

    test('resetStructureToSeed restores 7 + 23 and keeps ticks', () async {
      await repo.setSlotDone(today, 2, true);
      await repo.upsertPillar(LifePillar(
          key: await repo.newPillarKey(), label: 'مؤقّت'));
      await repo.setPillarArchived('quran', true);
      await repo.resetStructureToSeed();
      expect((await repo.pillars()).length, 7);
      expect((await repo.slots()).length, 23);
      expect((await repo.pillars()).any((p) => p.key == 'quran'), isTrue);
      expect((await repo.pillars()).any((p) => p.key.startsWith('custom_')),
          isFalse);
      // the tick on slot 2 is still there (keys on date+slot_no)
      expect((await repo.doneSlots(today)).contains(2), isTrue);
    });
  });

  // ── L6-DYN #3 — tasks & MITs ─────────────────────────────────────────

  group('tasks & MITs', () {
    setUp(() async {
      final db = await DatabaseHelper.instance.database;
      await db.delete('life_tasks');
      await db.delete('life_task_log');
      await db.delete('life_day_mit');
    });

    test('recurring daily task: create, appears for the day, toggles per date',
        () async {
      final id = await repo.upsertTask(const LifeTask(
          title: 'مراجعة كود الأمس', pillarKey: 'coding'));
      expect(id, greaterThan(0));
      final dv = await repo.tasksForDay(today);
      expect(dv.daily.single.title, 'مراجعة كود الأمس');
      expect(dv.dailyDone, isEmpty);
      expect(await repo.toggleTask(today, id), isTrue);
      expect((await repo.tasksForDay(today)).dailyDone, contains(id));
      // a different date is independent
      final ytd = LifePlanRepository.ymd(
          DateTime.now().subtract(const Duration(days: 1)));
      expect((await repo.taskLog(ytd)).contains(id), isFalse);
      expect(await repo.toggleTask(today, id), isFalse); // untoggle
      expect((await repo.taskLog(today)), isEmpty);
    });

    test('weekly recurring task counts completions in the trailing 7 days',
        () async {
      final id = await repo.upsertTask(const LifeTask(
          title: 'إرسال 3 طلبات',
          kind: LifeTaskKind.recurring,
          recurrence: LifeCadence.weekly,
          weeklyTarget: 3,
          pillarKey: 'jobs'));
      final now = DateTime.now();
      for (final ago in [0, 2, 5, 9]) {
        // 9 is outside the 7-day window ending today
        await repo.toggleTask(
            LifePlanRepository.ymd(now.subtract(Duration(days: ago))), id);
      }
      expect(await repo.weeklyTaskDone(id, today), 3);
      final dv = await repo.tasksForDay(today);
      expect(dv.weekly.single.task.weeklyTarget, 3);
      expect(dv.weekly.single.doneThisWeek, 3);
      expect(dv.daily, isEmpty); // not a daily task
    });

    test('milestone: open → done today → reopen', () async {
      final id = await repo.upsertTask(const LifeTask(
          title: 'FastAPI: مشروع أول',
          kind: LifeTaskKind.milestone,
          pillarKey: 'coding'));
      var dv = await repo.tasksForDay(today);
      expect(dv.milestonesOpen.single.id, id);
      expect(dv.milestonesDoneToday, isEmpty);
      await repo.setMilestoneDone(id, true);
      dv = await repo.tasksForDay(today);
      expect(dv.milestonesOpen, isEmpty);
      expect(dv.milestonesDoneToday.single.id, id);
      expect((await repo.tasks()).single.milestoneDone, isTrue);
      await repo.setMilestoneDone(id, false);
      expect((await repo.tasksForDay(today)).milestonesOpen.single.id, id);
    });

    test('archive vs hard-delete a task depends on whether it was ever logged',
        () async {
      final a = await repo.upsertTask(const LifeTask(title: 'أ'));
      final b = await repo.upsertTask(const LifeTask(title: 'ب'));
      expect(await repo.canHardDeleteTask(a), isTrue);
      await repo.toggleTask(today, b);
      expect(await repo.canHardDeleteTask(b), isFalse);
      await repo.hardDeleteTask(a); // gone
      await repo.hardDeleteTask(b); // falls back to archive
      final live = await repo.tasks();
      final all = await repo.tasks(includeArchived: true);
      expect(live.map((t) => t.id), isNot(contains(a)));
      expect(live.map((t) => t.id), isNot(contains(b)));
      expect(all.firstWhere((t) => t.id == b).archived, isTrue);
    });

    test('reorderTasks persists a new order', () async {
      final ids = [
        for (final t in ['x', 'y', 'z'])
          await repo.upsertTask(LifeTask(title: t)),
      ];
      await repo.reorderTasks(ids.reversed.toList());
      expect((await repo.tasks()).map((t) => t.id).toList(),
          ids.reversed.toList());
    });

    test('MITs: always 3, text edit + done flag, empty clears the row',
        () async {
      var m = await repo.mitFor(today);
      expect(m.length, 3);
      expect(m.every((e) => e.isEmpty), isTrue);
      await repo.setMitText(today, 0, 'أنهِ فيديو Python');
      await repo.setMitText(today, 1, 'راسل 3 عملاء');
      expect(await repo.toggleMit(today, 0), isTrue);
      expect(await repo.toggleMit(today, 2), isFalse); // empty slot → no-op
      m = await repo.mitFor(today);
      expect(m[0].text, 'أنهِ فيديو Python');
      expect(m[0].done, isTrue);
      expect(m[1].done, isFalse);
      expect(m[2].isEmpty, isTrue);
      final p = await repo.mitProgress(today);
      expect(p.total, 2);
      expect(p.done, 1);
      // clearing the text drops the row + its done flag
      await repo.setMitText(today, 0, '   ');
      m = await repo.mitFor(today);
      expect(m[0].isEmpty, isTrue);
      expect((await repo.mitProgress(today)).total, 1);
    });

    test('setMitText keeps the done flag when only the text changes', () async {
      await repo.setMitText(today, 0, 'الأصل');
      await repo.toggleMit(today, 0);
      await repo.setMitText(today, 0, 'نصّ معدّل');
      final m = await repo.mitFor(today);
      expect(m[0].text, 'نصّ معدّل');
      expect(m[0].done, isTrue);
    });
  });

  // ── L6-DYN #4 — partial completion + quantity ────────────────────────

  group('partial + quantity', () {
    setUp(() async {
      await repo.resetStructureToSeed(); // tests here add slots
      final db = await DatabaseHelper.instance.database;
      await db.delete('life_day_slots');
      await db.delete('life_tasks');
      await db.delete('life_task_log');
    });

    test('cycleSlot walks 0 → 0.5 → 1 → 0 and the day % counts the halves',
        () async {
      // one slot at half, one full → day % = (0.5 + 1) / 23
      expect(await repo.cycleSlot(today, 2), 0.5);
      expect(await repo.cycleSlot(today, 6), 0.5);
      expect(await repo.cycleSlot(today, 6), 1.0);
      final prog = await repo.progress(today);
      expect(prog.progressOf(2), 0.5);
      expect(prog.progressOf(6), 1.0);
      expect(prog.doneCount, 1); // only slot 6 is at 100%
      expect(prog.percent, closeTo((0.5 + 1.0) / 23, 1e-9));
      // per-pillar: quran has 3 slots, one at 0.5 → 0.5/3
      expect(prog.byPillar['quran'], closeTo(0.5 / 3, 1e-9));
      // full loop back to 0
      expect(await repo.cycleSlot(today, 2), 1.0);
      expect(await repo.cycleSlot(today, 2), 0.0);
      expect((await repo.progress(today)).progressOf(2), 0.0);
    });

    test('legacy done rows still read as progress 1 (no v60 columns written)',
        () async {
      // setSlotDone is the old path — it now writes progress too, but
      // simulate a pre-v60 row by writing only `done`
      final db = await DatabaseHelper.instance.database;
      await db.insert('life_day_slots', {'date': today, 'slot_no': 5, 'done': 1},
          conflictAlgorithm: ConflictAlgorithm.replace);
      final prog = await repo.progress(today);
      expect(prog.progressOf(5), 1.0);
      expect(prog.doneSlotNos, contains(5));
      expect((await repo.doneSlots(today)), contains(5));
    });

    test('a quantity slot: setSlotQty drives progress = qty / target',
        () async {
      final no = await repo.upsertSlot(const LifeSlot(
          slotNo: 0,
          startMin: 600,
          endMin: 660,
          activity: 'محتوى',
          pillarKey: 'social',
          qtyTarget: 4,
          qtyUnit: 'فيديو'));
      expect((await repo.slots()).firstWhere((s) => s.slotNo == no).isQuantity,
          isTrue);
      await repo.setSlotQty(today, no, 3);
      var prog = await repo.progress(today);
      expect(prog.slotQty[no], 3);
      expect(prog.progressOf(no), closeTo(0.75, 1e-9));
      // clamps at the target, and hitting it marks done
      await repo.setSlotQty(today, no, 9);
      prog = await repo.progress(today);
      expect(prog.slotQty[no], 4);
      expect(prog.progressOf(no), 1.0);
      expect(prog.doneSlotNos, contains(no));
      // and back down
      await repo.setSlotQty(today, no, -2);
      expect((await repo.progress(today)).progressOf(no), 0.0);
    });

    test('dayPercents sums fractional progress across the range', () async {
      final now = DateTime.now();
      final d1 = LifePlanRepository.ymd(now.subtract(const Duration(days: 1)));
      await repo.cycleSlot(d1, 1); // 0.5
      await repo.cycleSlot(d1, 2); // 0.5
      await repo.cycleSlot(d1, 3); // 0.5
      await repo.setSlotDone(d1, 4, true); // 1.0
      final m = await repo.dayPercents(d1, d1);
      expect(m[d1], closeTo((0.5 * 3 + 1.0) / 23, 1e-9));
    });

    test('cycleTask + setTaskQty mirror the slot behaviour', () async {
      final plain = await repo.upsertTask(const LifeTask(title: 'تأمل'));
      final qty = await repo.upsertTask(const LifeTask(
          title: 'اقرأ',
          kind: LifeTaskKind.recurring,
          recurrence: LifeCadence.daily,
          qtyTarget: 20,
          qtyUnit: 'صفحة'));
      expect(await repo.cycleTask(today, plain), 0.5);
      expect(await repo.cycleTask(today, plain), 1.0);
      await repo.setTaskQty(today, qty, 5);
      final dv = await repo.tasksForDay(today);
      expect(dv.dailyProgressOf(plain), 1.0);
      expect(dv.dailyDone, contains(plain));
      expect(dv.dailyProgressOf(qty), closeTo(0.25, 1e-9));
      expect(dv.dailyQty[qty], 5);
      expect(dv.dailyDone, isNot(contains(qty)));
      // a partial task still counts as "1 this week" for weekly readouts…
      // (weekly tasks are a separate axis, but the count query is by row)
      expect(await repo.weeklyTaskDone(plain, today), 1);
    });
  });
}
