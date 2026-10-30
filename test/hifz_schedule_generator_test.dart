import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/hifz/schedule_generator.dart';

/// ح1 of `docs/memorization/HIFZ_SCHEDULE_ARCHITECTURE.md`: the generator on
/// the real bundled muṣḥaf layout, checked against the §4 simulation table
/// (`tool/hifz/schedule_prototype.py`) and the §5.2 rules.

// Standard juzʼ starts (surah, ayah) — the same table as the prototype; in
// the app the juzʼ comes from `quran_ayat.juz_number`.
const _juzStarts = [
  (1, 1), (2, 142), (2, 253), (3, 93), (4, 24), (4, 148), (5, 82), (6, 111), (7, 88), (8, 41),
  (9, 93), (11, 6), (12, 53), (15, 1), (17, 1), (18, 75), (21, 1), (23, 1), (25, 21), (27, 56),
  (29, 46), (33, 31), (36, 28), (39, 32), (41, 47), (46, 1), (51, 31), (58, 1), (67, 1), (78, 1),
];

int _juzOf(int s, int a) {
  var j = 1;
  for (var k = 0; k < _juzStarts.length; k++) {
    final (ss, aa) = _juzStarts[k];
    if (s > ss || (s == ss && a >= aa)) j = k + 1;
  }
  return j;
}

late List<AyahLines> _ayat;

void main() {
  setUpAll(() {
    final layout = jsonDecode(utf8.decode(gzip.decode(File('assets/mushaf/mushaf_layout.json.gz').readAsBytesSync()))) as Map<String, dynamic>;
    final words = <(int, int, int, int)>[];
    for (final p in layout['pages'] as List) {
      for (final w in (p as Map)['words'] as List) {
        final m = w as Map;
        if (m['s'] == null) continue;
        words.add((p['page'] as int, m['ln'] as int, m['s'] as int, m['a'] as int));
      }
    }
    _ayat = ayahLinesFromWords(words, _juzOf);
  });

  test('every ayah measured once; ~8,820 text lines in all', () {
    expect(_ayat.length, 6236);
    final total = _ayat.fold<double>(0, (s, a) => s + a.lines);
    expect(total, closeTo(8820, 25));
  });

  // §4 table (corrected 2026-10-29, ERRATA M-1): lines per new day.
  const table = {
    HifzTimeline.months6: 86.1,
    HifzTimeline.months10: 50.1,
    HifzTimeline.months19: 22.9,
    HifzTimeline.months24: 17.2,
    HifzTimeline.months27: 15.2,
  };

  for (final t in HifzTimeline.values) {
    for (final dir in [HifzDirection.reverse, HifzDirection.mushaf, HifzDirection.hybrid]) {
      test('${t.name} ${dir.name}: fits the timeline and follows the rules', () {
        final s = generateSchedule(mushafOrder: _ayat, direction: dir, timeline: t);
        expect(s.days.length, t.totalDays);
        expect(s.scheduleDays, lessThanOrEqualTo(t.totalDays - t.finalPhaseDays));
        expect(s.days.skip(s.scheduleDays).every((d) => d.kind == DayKind.khatmCycle), isTrue);

        // The same for every direction: the order changes the feel, not the load.
        expect(s.linesPerDay, closeTo(table[t]!, 0.4));

        // Every ayah exactly once, in the chosen order, never split.
        final ordered = orderAyat(_ayat, dir);
        final index = {for (var k = 0; k < ordered.length; k++) (ordered[k].surah, ordered[k].ayah): k};
        var next = 0;
        for (final d in s.days.where((d) => d.kind == DayKind.newPortion)) {
          expect(index[d.from], next);
          next = index[d.to]! + 1;
        }
        expect(next, ordered.length);

        // Every 7th day is a weekly day; every juzʼ gets its review day.
        for (final d in s.days.take(s.scheduleDays)) {
          expect(d.day % 7 == 0, d.kind == DayKind.weekly);
        }
        expect(s.days.where((d) => d.kind == DayKind.reviewJuz).map((d) => d.ref).toSet().length, 30);
      });
    }
  }

  test('reverse: day 1 gathers many short surahs, starting at an-Nās', () {
    final s = generateSchedule(mushafOrder: _ayat, direction: HifzDirection.reverse, timeline: HifzTimeline.months24);
    final d1 = s.days.first;
    expect(d1.from, (114, 1));
    expect(d1.to!.$1, lessThan(110)); // several surahs in one day
  });

  test('hybrid: ʿAmma, then al-Mulk, then al-Fātiḥa', () {
    final seq = orderAyat(_ayat, HifzDirection.hybrid);
    expect((seq.first.surah, seq.first.ayah), (114, 1));
    final mulk = seq.indexWhere((a) => a.surah == 67);
    final fatiha = seq.indexWhere((a) => a.surah == 1);
    expect(seq[mulk - 1].surah, 78);
    expect(fatiha, greaterThan(mulk));
    expect(seq.last.surah, 66);
  });

  test('re-planning skips what is memorized and the khatm phase grows into cycles', () {
    final amma = {for (final a in _ayat) if (a.juz == 30) (a.surah, a.ayah)};
    final s = generateSchedule(mushafOrder: _ayat, direction: HifzDirection.reverse, timeline: HifzTimeline.months24, alreadyMemorized: amma);
    expect(s.days.first.from!.$1, 77); // continues at al-Mursalāt
    final full = generateSchedule(mushafOrder: _ayat, direction: HifzDirection.reverse, timeline: HifzTimeline.months24);
    expect(s.linesPerDay, lessThan(full.linesPerDay));
    final khatm = s.days.where((d) => d.kind == DayKind.khatmCycle).map((d) => d.ref).toList();
    expect(khatm.first, 30);
  });

  group('ح4 progress and re-planning', () {
    late HifzSchedule plan;
    setUp(() => plan = generateSchedule(mushafOrder: _ayat, direction: HifzDirection.reverse, timeline: HifzTimeline.months24));

    Set<(int, int)> firstN(int n) => {for (final a in plan.sequence.take(n)) (a.surah, a.ayah)};
    int endOfPortion(int k) {
      final idx = {for (var i = 0; i < plan.sequence.length; i++) (plan.sequence[i].surah, plan.sequence[i].ayah): i};
      return idx[plan.days.where((d) => d.kind == DayKind.newPortion).elementAt(k).to]! + 1;
    }

    test('on track: every past portion done, no lag', () {
      // Day 10 has 8 new days before it (days 1–9 minus day 7, the weekly one).
      final p = measureProgress(plan, firstN(endOfPortion(7)), 10);
      expect(p.lagDays, 0);
      expect(p.byDay.values.every((v) => v == DayProgress.done), isTrue);
      expect(p.byDay.containsKey(7), isFalse); // weekly day is not graded
    });

    test('behind: three portions short, the last ones missed', () {
      final p = measureProgress(plan, firstN(endOfPortion(4)), 10);
      expect(p.lagDays, 3);
      expect(p.byDay[9], DayProgress.missed);
      expect(p.byDay[1], DayProgress.done);
    });

    test('half a portion is partial; ahead is negative lag', () {
      final half = firstN(endOfPortion(0) + (endOfPortion(1) - endOfPortion(0)) ~/ 2);
      expect(measureProgress(plan, half, 3).byDay[2], DayProgress.partial);
      expect(measureProgress(plan, firstN(endOfPortion(5)), 3).lagDays, lessThan(0));
    });

    test('keep-pace re-plan keeps the daily load and moves the end', () {
      final done = firstN(endOfPortion(4));
      final atPace = generateScheduleAtPace(mushafOrder: _ayat, direction: HifzDirection.reverse, linesPerDay: plan.linesPerDay, finalPhaseDays: 70, alreadyMemorized: done);
      expect(atPace.linesPerDay, plan.linesPerDay);
      expect(atPace.days.first.from, (plan.sequence[endOfPortion(4)].surah, plan.sequence[endOfPortion(4)].ayah));
      expect(atPace.scheduleDays, greaterThan(plan.scheduleDays - 9));
    });

    test('a re-plan with no time left still yields a usable list', () {
      final late = generateSchedule(mushafOrder: _ayat, direction: HifzDirection.reverse, timeline: HifzTimeline.months24, totalDays: 5, finalPhaseDays: 7);
      expect(late.scheduleDays, greaterThan(0));
    });
  });
}
