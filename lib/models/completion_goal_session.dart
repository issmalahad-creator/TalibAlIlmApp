/// KHATM_SYSTEM_AND_STYLE_REFERENCE.md §2.3 field 7أ — "توزيع ديناميكي للورد
/// على جلسات مرتبطة بالصلاة". A goal's daily target split across named
/// reading sessions, each anchored either to a real prayer time (read live
/// every day from the existing prayer-time engine, ± an optional minute
/// offset) or a fixed clock time (for sessions with no prayer concept, e.g.
/// "بعد الاستيقاظ"/"قبل النوم", or any session the student adds manually).
///
/// Purely a data record — no prayer-time lookup happens here (that's
/// [PrayerTimesRepository], read live by whatever renders/schedules a
/// session, never cached on the row itself, so a session always reflects
/// today's real prayer times, not the time they happened to be on when the
/// session was created).
class CompletionGoalSession {
  final int? id;
  final int goalId;
  final int sortOrder;
  final String label;
  final String anchorType; // 'prayer' | 'fixed'
  final String? anchorPrayer; // fajr|sunrise|dhuhr|asr|maghrib|isha — anchorType == 'prayer' only
  final int offsetMinutes; // anchorType == 'prayer' only; +after / -before
  final int? fixedHour; // anchorType == 'fixed' only
  final int? fixedMinute; // anchorType == 'fixed' only
  final int units;

  const CompletionGoalSession({
    this.id,
    required this.goalId,
    required this.sortOrder,
    required this.label,
    required this.anchorType,
    this.anchorPrayer,
    this.offsetMinutes = 0,
    this.fixedHour,
    this.fixedMinute,
    required this.units,
  });

  CompletionGoalSession copyWith({
    String? label,
    String? anchorType,
    String? anchorPrayer,
    int? offsetMinutes,
    int? fixedHour,
    int? fixedMinute,
    int? units,
    int? sortOrder,
  }) =>
      CompletionGoalSession(
        id: id,
        goalId: goalId,
        sortOrder: sortOrder ?? this.sortOrder,
        label: label ?? this.label,
        anchorType: anchorType ?? this.anchorType,
        anchorPrayer: anchorType == 'fixed' ? null : (anchorPrayer ?? this.anchorPrayer),
        offsetMinutes: offsetMinutes ?? this.offsetMinutes,
        fixedHour: anchorType == 'prayer' ? null : (fixedHour ?? this.fixedHour),
        fixedMinute: anchorType == 'prayer' ? null : (fixedMinute ?? this.fixedMinute),
        units: units ?? this.units,
      );

  Map<String, Object?> toRow() => {
        'goal_id': goalId,
        'sort_order': sortOrder,
        'label': label,
        'anchor_type': anchorType,
        'anchor_prayer': anchorPrayer,
        'offset_minutes': offsetMinutes,
        'fixed_hour': fixedHour,
        'fixed_minute': fixedMinute,
        'units': units,
      };

  factory CompletionGoalSession.fromRow(Map<String, Object?> row) => CompletionGoalSession(
        id: row['id'] as int,
        goalId: row['goal_id'] as int,
        sortOrder: row['sort_order'] as int,
        label: row['label'] as String,
        anchorType: row['anchor_type'] as String,
        anchorPrayer: row['anchor_prayer'] as String?,
        offsetMinutes: row['offset_minutes'] as int? ?? 0,
        fixedHour: row['fixed_hour'] as int?,
        fixedMinute: row['fixed_minute'] as int?,
        units: row['units'] as int,
      );
}

/// The two ready-made distribution patterns from §2.3.7أ — pure functions,
/// no AI/heuristic guessing, matching the app's existing "explicit rules
/// only" philosophy (`WorshipCoachRepository.focusAreaFor()`). Each returns
/// unsaved sessions (`goalId: 0`, no `id`) for the wizard's live preview;
/// the caller assigns the real `goalId` at save time.

/// النمط أ — 7 جلسات شبه متساوية: 5 صلوات + بعد الاستيقاظ + قبل النوم.
/// `base = target ÷ 7` (floor), الباقي يوزَّع صفحة واحدة لكل جلسة من الأول.
/// Always applicable for any `target >= 1`.
List<CompletionGoalSession> equalSessionPattern(int dailyTarget) {
  final target = dailyTarget < 1 ? 1 : dailyTarget;
  const labels = ['بعد الاستيقاظ', 'الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء', 'قبل النوم'];
  const prayers = [null, 'fajr', 'dhuhr', 'asr', 'maghrib', 'isha', null];
  final base = target ~/ 7;
  final remainder = target % 7;
  return List.generate(7, (i) {
    final prayer = prayers[i];
    return CompletionGoalSession(
      goalId: 0,
      sortOrder: i,
      label: labels[i],
      anchorType: prayer == null ? 'fixed' : 'prayer',
      anchorPrayer: prayer,
      fixedHour: prayer == null ? (i == 0 ? 6 : 22) : null,
      fixedMinute: prayer == null ? 0 : null,
      units: base + (i < remainder ? 1 : 0),
    );
  });
}

/// النمط ب — 4 جلسات رئيسية (الفجر/الظهر/العصر/العشاء) + 3 خفيفة ثابتة
/// (الشروق/المغرب/قبل النوم، صفحتان لكل منها). الباقي بعد الخفيفة الثلاث
/// يُقسَّم على الأربع الرئيسية، وكسر القسمة كاملًا لجلسة العشاء. Hidden by
/// the caller (not computed here) when `dailyTarget < 7`.
List<CompletionGoalSession> focusedSessionPattern(int dailyTarget) {
  const lightUnits = 2;
  final remaining = dailyTarget - (lightUnits * 3);
  final mainBase = remaining ~/ 4;
  final mainRemainder = remaining % 4;
  // fajr, sunrise(light), dhuhr, asr, maghrib(light), isha(+remainder), sleep(light)
  return [
    CompletionGoalSession(goalId: 0, sortOrder: 0, label: 'الفجر', anchorType: 'prayer', anchorPrayer: 'fajr', units: mainBase),
    CompletionGoalSession(goalId: 0, sortOrder: 1, label: 'الشروق', anchorType: 'prayer', anchorPrayer: 'sunrise', units: lightUnits),
    CompletionGoalSession(goalId: 0, sortOrder: 2, label: 'الظهر', anchorType: 'prayer', anchorPrayer: 'dhuhr', units: mainBase),
    CompletionGoalSession(goalId: 0, sortOrder: 3, label: 'العصر', anchorType: 'prayer', anchorPrayer: 'asr', units: mainBase),
    CompletionGoalSession(goalId: 0, sortOrder: 4, label: 'المغرب', anchorType: 'prayer', anchorPrayer: 'maghrib', units: lightUnits),
    CompletionGoalSession(goalId: 0, sortOrder: 5, label: 'العشاء', anchorType: 'prayer', anchorPrayer: 'isha', units: mainBase + mainRemainder),
    CompletionGoalSession(goalId: 0, sortOrder: 6, label: 'قبل النوم', anchorType: 'fixed', fixedHour: 22, fixedMinute: 0, units: lightUnits),
  ];
}

/// §2.3.7أ's حالة حدّية — "يُخفى تلقائيًا إن كان daily_target < 7 ... لا قيم
/// سالبة أبدًا".
bool focusedPatternApplicable(int dailyTarget) => dailyTarget >= 7;
