import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
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
}
