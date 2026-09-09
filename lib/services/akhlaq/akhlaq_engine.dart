import '../../models/akhlaq.dart';

/// AKHLAQ — the training engine. **Pure functions only**: no I/O, no
/// state, isolate-safe (same discipline as
/// `lib/services/mushaf/tajweed_svg.dart`). The repository feeds it rows
/// and persists what comes back.
///
/// Nothing here produces a judgement on the person. Outputs are training
/// signals over the user's in-app attempts, per subskill
/// (`AKHLAQ_SYSTEM_PHILOSOPHY §6/§7`).

/// Verdict → quality: aqrab=5, maqbul=3, baid=1 (spaced-repetition spec).
int qualityForVerdict(String verdict) {
  switch (verdict) {
    case 'aqrab':
      return 5;
    case 'maqbul':
      return 3;
    default:
      return 1;
  }
}

class DimScore {
  final int quality; // 1 | 3 | 5
  final String verdict;
  final Map<String, int> dims; // dimension -> net (+/-) for the chosen option
  const DimScore(this.quality, this.verdict, this.dims);
}

/// Score one chosen option. No "correct answer" flag — just the verdict,
/// the derived quality, and the dimension tally for the feedback layer.
DimScore evaluateOption(AkhlaqOption o) =>
    DimScore(qualityForVerdict(o.verdict), o.verdict, Map.of(o.dimensions));

// ── trend / band ──────────────────────────────────────────────────────

/// Rolling response-selection trend for one subskill. Weights recent
/// attempts by scenario difficulty (a good choice under pressure counts
/// for more). `weakDimension` = the dimension most often chosen negative
/// in recent attempts — used to steer the next scenario, never shown as
/// a label on the user.
AkhlaqProgress rollSubskillTrend({
  required String subskill,
  required List<AkhlaqAttempt> attempts,
  int window = 8,
}) {
  final mine = attempts.where((a) => a.subskill == subskill).toList()
    ..sort((a, b) => b.answeredAt.compareTo(a.answeredAt));
  final recent = mine.take(window).toList();

  if (recent.isEmpty) {
    return AkhlaqProgress(
        subskill: subskill, trend: 0, attempts: 0, band: 'beginner');
  }

  var num = 0.0, den = 0.0;
  final negTally = <String, int>{};
  for (final a in recent) {
    final w = a.difficulty.toDouble().clamp(1, 8);
    num += (a.quality / 5.0) * w;
    den += w;
    a.dimScore.forEach((k, v) {
      if (v < 0) negTally[k] = (negTally[k] ?? 0) + 1;
    });
  }
  final trend = den == 0 ? 0.0 : (num / den);

  String band;
  final n = mine.length;
  if (n < 3) {
    band = 'practising';
  } else if (trend < 0.5) {
    band = 'review';
  } else if (trend < 0.75) {
    band = 'stable';
  } else {
    band = 'mastery';
  }

  String? weak;
  var most = 0;
  negTally.forEach((k, v) {
    if (v > most) {
      most = v;
      weak = k;
    }
  });

  return AkhlaqProgress(
    subskill: subskill,
    trend: double.parse(trend.toStringAsFixed(4)),
    attempts: n,
    band: band,
    weakDimension: weak,
  );
}

// ── spaced repetition (SM-2 adapted) ──────────────────────────────────

/// Advance the SR state after an attempt of the given [quality] (1|3|5).
/// `difficulty` ramps up only after a run of good choices; a poor choice
/// (quality<=1) shortens the interval and never raises difficulty.
AkhlaqSrState scheduleNext(
  AkhlaqSrState prev,
  int quality, {
  required DateTime today,
  bool stableRun = false,
}) {
  var ease = prev.ease + (quality - 3) * 0.1;
  ease = ease.clamp(1.3, 2.6);

  int interval;
  if (quality <= 1) {
    interval = 1;
  } else if (prev.intervalDays <= 1) {
    interval = 2;
  } else {
    interval = (prev.intervalDays * ease).round().clamp(2, 120);
  }

  var difficulty = prev.difficulty;
  if (quality > 1 && stableRun && difficulty < 8) difficulty += 1;

  // K → S → R → K …
  const order = ['K', 'S', 'R'];
  final nextTrack = order[(order.indexOf(prev.track) + 1) % order.length];

  final due = today.add(Duration(days: interval));
  final ymd = '${due.year.toString().padLeft(4, '0')}-'
      '${due.month.toString().padLeft(2, '0')}-'
      '${due.day.toString().padLeft(2, '0')}';

  return prev.copyWith(
    track: nextTrack,
    intervalDays: interval,
    ease: double.parse(ease.toStringAsFixed(3)),
    difficulty: difficulty,
    dueDate: ymd,
    lastQuality: quality,
  );
}

// ── next scenario (rule-based, transparent) ───────────────────────────

/// Choose the next scenario for [subskill] at [difficulty]. Prefers one
/// that exercises [weakDimension], hasn't been seen recently, and — for a
/// composite — still lists this subskill. Falls back to the least-recently
/// attempted scenario of any difficulty for this subskill.
String? pickNextScenario({
  required String subskill,
  required int difficulty,
  required AkhlaqSlice slice,
  required List<AkhlaqAttempt> attempts,
  String? weakDimension,
}) {
  final seenAt = <String, int>{};
  for (final a in attempts) {
    seenAt[a.scenarioId] =
        seenAt[a.scenarioId] == null ? a.answeredAt : (a.answeredAt > seenAt[a.scenarioId]! ? a.answeredAt : seenAt[a.scenarioId]!);
  }

  final forSkill =
      slice.scenarios.where((s) => s.subskills.contains(subskill)).toList();
  if (forSkill.isEmpty) return null;

  int rank(AkhlaqScenario s) {
    var r = 0;
    if (s.difficulty == difficulty) r += 100;
    r -= (s.difficulty - difficulty).abs() * 8;
    if (!seenAt.containsKey(s.id)) r += 40;
    if (weakDimension != null &&
        s.options.any((o) => o.dimensions.containsKey(weakDimension))) {
      r += 20;
    }
    return r;
  }

  forSkill.sort((a, b) {
    final byRank = rank(b).compareTo(rank(a));
    if (byRank != 0) return byRank;
    // tie-break: least-recently seen first
    return (seenAt[a.id] ?? 0).compareTo(seenAt[b.id] ?? 0);
  });
  return forSkill.first.id;
}

// ── today's plan ──────────────────────────────────────────────────────

class TrainingItem {
  final String subskill;
  final String track; // 'K' | 'S' | 'R'
  final String? scenarioId; // for track 'S'
  final int difficulty;
  const TrainingItem(this.subskill, this.track, this.scenarioId, this.difficulty);
}

/// The items due today. A `focusSubskill` (the student's "focus of the
/// week") is always included first; the rest are subskills whose SR
/// `dueDate` is today or earlier.
List<TrainingItem> todayPlan({
  required List<AkhlaqSrState> states,
  required List<AkhlaqAttempt> attempts,
  required AkhlaqSlice slice,
  required DateTime today,
  String? focusSubskill,
  int max = 3,
}) {
  final ymd = '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';

  final ordered = [
    for (final s in states)
      if (focusSubskill != null && s.subskill == focusSubskill) s,
    for (final s in states)
      if (s.subskill != focusSubskill &&
          (s.dueDate.isEmpty || s.dueDate.compareTo(ymd) <= 0))
        s,
  ];

  final out = <TrainingItem>[];
  for (final s in ordered) {
    if (out.length >= max) break;
    String? scenarioId;
    if (s.track == 'S') {
      final prog = rollSubskillTrend(subskill: s.subskill, attempts: attempts);
      scenarioId = pickNextScenario(
        subskill: s.subskill,
        difficulty: s.difficulty,
        slice: slice,
        attempts: attempts,
        weakDimension: prog.weakDimension,
      );
    }
    out.add(TrainingItem(s.subskill, s.track, scenarioId, s.difficulty));
  }
  return out;
}
