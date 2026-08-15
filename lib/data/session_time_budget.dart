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

/// Splits [totalMinutes] across the 5 phases for [level]
/// ('beginner'/'intermediate'/'advanced', falls back to beginner ratios
/// for an unrecognized value). Whole-minute rounding, with the remainder
/// (if any, from rounding down) added to "تكرار" so the total always adds
/// up to [totalMinutes] exactly.
List<SessionPhase> computeSessionPlan(String level, int totalMinutes) {
  final ratios = _ratiosByLevel[level] ?? _ratiosByLevel['beginner']!;
  final minutes = {for (final e in ratios.entries) e.key: (totalMinutes * e.value).floor()};
  final allocated = minutes.values.fold(0, (a, b) => a + b);
  minutes['repetition'] = (minutes['repetition'] ?? 0) + (totalMinutes - allocated);

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
