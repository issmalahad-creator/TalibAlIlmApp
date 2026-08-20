/// Time-budgeting for the guided session (Phase 14 Sub-phase B) — a
/// student picks a session length, this splits it across 5 phases.
/// **Honesty note**: these ratios are a reasonable, documented design
/// heuristic, NOT a scientifically-validated standard — same caution
/// applied throughout this app to anything that could be mistaken for
/// verified authority. Beginners lean toward building volume (more new
/// memorization, more repetition before testing); advanced students lean
/// toward review/testing/understanding since they already have more
/// material to maintain. Adjustable later if it doesn't feel right in use.
class SessionPhase {
  final String key; // 'quick_review' | 'new_memorization' | 'repetition' | 'recitation_test' | 'understanding'
  final String titleAr;
  final String descriptionAr;
  final int minutes;
  const SessionPhase({
    required this.key,
    required this.titleAr,
    required this.descriptionAr,
    required this.minutes,
  });
}

const _ratiosByLevel = {
  'beginner': {'quick_review': 0.15, 'new_memorization': 0.35, 'repetition': 0.25, 'recitation_test': 0.15, 'understanding': 0.10},
  'intermediate': {'quick_review': 0.20, 'new_memorization': 0.25, 'repetition': 0.20, 'recitation_test': 0.20, 'understanding': 0.15},
  'advanced': {'quick_review': 0.25, 'new_memorization': 0.15, 'repetition': 0.15, 'recitation_test': 0.25, 'understanding': 0.20},
};

const _phaseTitles = {
  'quick_review': ('مراجعة سريعة', 'راجع الصفحات المستحقة اليوم من محفوظك القديم'),
  'new_memorization': ('حفظ جديد', 'احفظ صفحتك المقترحة اليوم'),
  'repetition': ('تكرار', 'كرّر ما حفظته اليوم بصوت عالٍ عدة مرات قبل اختبار نفسك'),
  'recitation_test': ('تسميع', 'اختبر حفظك بنفسك'),
  'understanding': ('فهم', 'اقرأ تفسير ما حفظته وتدبّره'),
};

/// A phase's minutes floor when the greedy backlog top-up (below) shifts
/// time away from it — never emptied out entirely just because a lot is
/// due elsewhere, only thinned.
const _minPhaseFloor = 5;

/// Rough, explicitly-approximate minutes-per-item used only to decide
/// *how much* extra review time a real backlog justifies — not a claim
/// about how long any single review actually takes.
const _minutesPerDueItem = 2;

/// Splits [totalMinutes] across the 5 phases for [level]
/// ('beginner'/'intermediate'/'advanced', falls back to beginner ratios
/// for an unrecognized value). Whole-minute rounding, with the remainder
/// (if any, from rounding down) added to "تكرار" so the total always adds
/// up to [totalMinutes] exactly.
///
/// [dueQuranReviews]/[dueKnowledgeReviews] (100_IDEAS_FOR_IMPROVEMENT.md's
/// "Learning Decision Engine" ask, deliberately scoped to a plain
/// deterministic greedy top-up rather than a full LP solver — 5 fixed
/// phases doesn't justify that complexity) are optional and default to 0,
/// so the two existing call sites in `guided_session_screen.dart` are
/// completely unaffected unless they start passing real backlog counts.
/// When the real due-item count would need more time than the level's
/// baseline "مراجعة سريعة" share already covers, minutes are moved in from
/// "فهم" then "حفظ جديد" (in that order), each never thinned below
/// [_minPhaseFloor] — review of material already memorized takes priority
/// over new volume when there's a real backlog, but a session never loses
/// a phase entirely. The total always still sums to exactly [totalMinutes]
/// since this only moves minutes between buckets.
List<SessionPhase> computeSessionPlan(
  String level,
  int totalMinutes, {
  int dueQuranReviews = 0,
  int dueKnowledgeReviews = 0,
}) {
  final ratios = _ratiosByLevel[level] ?? _ratiosByLevel['beginner']!;
  final minutes = {for (final e in ratios.entries) e.key: (totalMinutes * e.value).floor()};
  final allocated = minutes.values.fold(0, (a, b) => a + b);
  minutes['repetition'] = (minutes['repetition'] ?? 0) + (totalMinutes - allocated);

  final neededReview = ((dueQuranReviews + dueKnowledgeReviews) * _minutesPerDueItem).clamp(0, totalMinutes);
  var extraNeeded = neededReview - minutes['quick_review']!;
  if (extraNeeded > 0) {
    for (final donor in ['understanding', 'new_memorization']) {
      if (extraNeeded <= 0) break;
      final shiftable = (minutes[donor]! - _minPhaseFloor).clamp(0, extraNeeded);
      minutes[donor] = minutes[donor]! - shiftable;
      minutes['quick_review'] = minutes['quick_review']! + shiftable;
      extraNeeded -= shiftable;
    }
  }

  return [
    for (final key in ['quick_review', 'new_memorization', 'repetition', 'recitation_test', 'understanding'])
      SessionPhase(
        key: key,
        titleAr: _phaseTitles[key]!.$1,
        descriptionAr: _phaseTitles[key]!.$2,
        minutes: minutes[key] ?? 0,
      ),
  ];
}
