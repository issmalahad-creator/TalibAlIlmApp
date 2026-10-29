/// The hifz schedule generator — ح1 of
/// `docs/memorization/HIFZ_SCHEDULE_ARCHITECTURE.md` (§3.3, §5).
///
/// A pure, deterministic function: given every ayah's share of muṣḥaf lines,
/// a direction and a timeline, it lays out the days — new portions that never
/// split an ayah and finish a surah when little of it is left, a review day
/// after a long surah and after each completed juzʼ, a weekly day with no new
/// memorization, and a closing phase of accelerating khatm cycles. The daily
/// amount `q` (lines) is solved so the plan ends on time. Nothing is stored:
/// when the student falls behind, the plan is simply generated again from
/// where they are (§5.1).
library;

/// One ayah and how many muṣḥaf text lines it occupies (fractional: an ayah
/// sharing a line gets its share of that line's words).
class AyahLines {
  final int surah;
  final int ayah;
  final int juz;
  final double lines;
  const AyahLines({required this.surah, required this.ayah, required this.juz, required this.lines});
}

enum HifzDirection {
  /// Al-Fātiḥa → an-Nās, in muṣḥaf order.
  mushaf,

  /// An-Nās → al-Fātiḥa, surah by surah (each surah still read in order).
  reverse,

  /// Juzʼ ʿAmma (an-Nās → an-Nabaʼ), then Juzʼ Tabārak (al-Mulk → al-Mursalāt),
  /// then from al-Fātiḥa onward — the default of `HIFZ_TIMELINE_ENGINE.md` §3.
  hybrid,
}

/// The five timelines (`HIFZ_SCHEDULE_ARCHITECTURE.md` §4): total days and the
/// closing khatm phase with no new memorization.
enum HifzTimeline {
  months6(182, 21),
  months10(301, 35),
  months19(574, 56),
  months24(728, 70),
  months27(819, 84);

  final int totalDays;
  final int finalPhaseDays;
  const HifzTimeline(this.totalDays, this.finalPhaseDays);
}

enum DayKind { newPortion, reviewSurah, reviewJuz, weekly, khatmCycle }

class DayPlan {
  /// 1-based day of the plan.
  final int day;
  final DayKind kind;

  /// newPortion: first and last ayah (inclusive) and their lines.
  final (int, int)? from;
  final (int, int)? to;
  final double lines;

  /// reviewSurah: the surah; reviewJuz: the juzʼ; khatmCycle: its length in
  /// days (30, then 20, then 15…).
  final int? ref;

  const DayPlan({required this.day, required this.kind, this.from, this.to, this.lines = 0, this.ref});
}

class HifzSchedule {
  final List<DayPlan> days;

  /// Lines of new memorization per new day — the solved `q`.
  final double linesPerDay;

  /// Days the new memorization itself takes (before the khatm phase).
  final int scheduleDays;
  const HifzSchedule({required this.days, required this.linesPerDay, required this.scheduleDays});

  int count(DayKind k) => days.where((d) => d.kind == k).length;
}

/// The ayat in the order they will be memorized.
List<AyahLines> orderAyat(List<AyahLines> mushafOrder, HifzDirection direction) {
  final bySurah = <int, List<AyahLines>>{};
  for (final a in mushafOrder) {
    bySurah.putIfAbsent(a.surah, () => []).add(a);
  }
  List<int> surahs;
  switch (direction) {
    case HifzDirection.mushaf:
      surahs = [for (var s = 1; s <= 114; s++) s];
    case HifzDirection.reverse:
      surahs = [for (var s = 114; s >= 1; s--) s];
    case HifzDirection.hybrid:
      surahs = [
        for (var s = 114; s >= 78; s--) s, // Juzʼ ʿAmma, an-Nās first
        for (var s = 67; s <= 77; s++) s, // Juzʼ Tabārak, al-Mulk first
        for (var s = 1; s <= 66; s++) s,
      ];
  }
  return [for (final s in surahs) ...?bySurah[s]];
}

/// Below this share of `q` left in a surah, today's portion finishes it (§5.2).
const _finishSurahTolerance = 0.35;

/// Lays out the memorization days for a fixed daily amount [q] (lines).
List<DayPlan> _layout(List<AyahLines> seq, double q) {
  final surahLines = <int, double>{};
  final juzLeft = <int, int>{};
  for (final a in seq) {
    surahLines[a.surah] = (surahLines[a.surah] ?? 0) + a.lines;
    juzLeft[a.juz] = (juzLeft[a.juz] ?? 0) + 1;
  }

  final days = <DayPlan>[];
  final pendingReviews = <DayPlan>[];
  var i = 0;
  var day = 0;
  while (i < seq.length || pendingReviews.isNotEmpty) {
    day++;
    if (day % 7 == 0) {
      days.add(DayPlan(day: day, kind: DayKind.weekly));
      continue;
    }
    if (pendingReviews.isNotEmpty) {
      final r = pendingReviews.removeAt(0);
      days.add(DayPlan(day: day, kind: r.kind, ref: r.ref));
      continue;
    }

    final start = i;
    var acc = 0.0;
    while (i < seq.length && acc < q) {
      acc += seq[i].lines;
      i++;
    }
    // Finish the surah when only a little of it is left.
    if (i < seq.length && seq[i].surah == seq[i - 1].surah) {
      final s = seq[i].surah;
      var rest = 0.0;
      for (var k = i; k < seq.length && seq[k].surah == s; k++) {
        rest += seq[k].lines;
      }
      if (rest <= q * _finishSurahTolerance) {
        while (i < seq.length && seq[i].surah == s) {
          acc += seq[i].lines;
          i++;
        }
      }
    }
    days.add(DayPlan(
      day: day,
      kind: DayKind.newPortion,
      from: (seq[start].surah, seq[start].ayah),
      to: (seq[i - 1].surah, seq[i - 1].ayah),
      lines: acc,
    ));

    // Review days earned today: each long surah finished, then each juzʼ
    // completed — in any direction, by counting what is left of it.
    final finishedJuz = <int>[];
    for (var k = start; k < i; k++) {
      final a = seq[k];
      final endsSurah = k + 1 >= seq.length || seq[k + 1].surah != a.surah;
      if (endsSurah && surahLines[a.surah]! >= 2 * q) {
        pendingReviews.add(DayPlan(day: 0, kind: DayKind.reviewSurah, ref: a.surah));
      }
      juzLeft[a.juz] = juzLeft[a.juz]! - 1;
      if (juzLeft[a.juz] == 0) finishedJuz.add(a.juz);
    }
    for (final j in finishedJuz) {
      pendingReviews.add(DayPlan(day: 0, kind: DayKind.reviewJuz, ref: j));
    }
  }
  return days;
}

/// The khatm phase: cycles of 30, 20, 15, 15… days over everything.
List<DayPlan> _khatmPhase(int firstDay, int length) {
  final out = <DayPlan>[];
  const cycles = [30, 20, 15];
  var c = 0;
  var left = 0;
  var cycleLen = 0;
  for (var d = 0; d < length; d++) {
    if (left == 0) {
      cycleLen = cycles[c < cycles.length ? c : cycles.length - 1];
      c++;
      left = cycleLen;
    }
    out.add(DayPlan(day: firstDay + d, kind: DayKind.khatmCycle, ref: cycleLen));
    left--;
  }
  return out;
}

/// Generates the plan. [alreadyMemorized] holds `(surah, ayah)` pairs to skip
/// — the student's existing hifz, or what they have done when re-planning.
/// [totalDays]/[finalPhaseDays] default to the [timeline]'s; pass the days
/// remaining to re-plan mid-way.
HifzSchedule generateSchedule({
  required List<AyahLines> mushafOrder,
  required HifzDirection direction,
  required HifzTimeline timeline,
  Set<(int, int)> alreadyMemorized = const {},
  int? totalDays,
  int? finalPhaseDays,
}) {
  final total = totalDays ?? timeline.totalDays;
  final finalDays = finalPhaseDays ?? timeline.finalPhaseDays;
  final seq = [
    for (final a in orderAyat(mushafOrder, direction))
      if (!alreadyMemorized.contains((a.surah, a.ayah))) a,
  ];
  if (seq.isEmpty) {
    return HifzSchedule(days: _khatmPhase(1, finalDays), linesPerDay: 0, scheduleDays: 0);
  }

  // Smallest q (to 0.1 line) whose layout fits before the khatm phase.
  final budget = total - finalDays;
  var lo = 0.5, hi = 1000.0;
  for (var k = 0; k < 40; k++) {
    final mid = (lo + hi) / 2;
    if (_layout(seq, mid).length <= budget) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  final q = (hi * 10).ceil() / 10;
  final days = _layout(seq, q);
  return HifzSchedule(
    days: [...days, ..._khatmPhase(days.length + 1, total - days.length)],
    linesPerDay: q,
    scheduleDays: days.length,
  );
}

/// Each ayah's share of text lines on the real muṣḥaf: every word of a line
/// counts `1 / words on that line`. [words] are `(page, line, surah, ayah)` in
/// muṣḥaf order — the rows of `mushaf_words`.
List<AyahLines> ayahLinesFromWords(Iterable<(int, int, int, int)> words, int Function(int surah, int ayah) juzOf) {
  final perLine = <(int, int), int>{};
  for (final w in words) {
    perLine[(w.$1, w.$2)] = (perLine[(w.$1, w.$2)] ?? 0) + 1;
  }
  final shares = <(int, int), double>{};
  final order = <(int, int)>[];
  for (final w in words) {
    final key = (w.$3, w.$4);
    if (!shares.containsKey(key)) order.add(key);
    shares[key] = (shares[key] ?? 0) + 1 / perLine[(w.$1, w.$2)]!;
  }
  order.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  return [for (final k in order) AyahLines(surah: k.$1, ayah: k.$2, juz: juzOf(k.$1, k.$2), lines: shares[k]!)];
}
