/// «مُحرّك الحياة» — Life Engine model (`docs/LIFE_ENGINE.md`).
///
/// A **continuous** daily engine — the day number is `today − startDate`,
/// unbounded; the "90 days" is only a soft cycle for the weekly-review /
/// evolution ritual, never an end. Plain, immutable, framework-free.
library;

enum LifeCadence { daily, weekly }

LifeCadence _cadence(String? s) =>
    s == 'weekly' ? LifeCadence.weekly : LifeCadence.daily;

/// One of the tracked life pillars (7, seeded from Ismail's sheet, editable).
class LifePillar {
  final String key; // 'quran' | 'books' | 'social' | 'coding' | 'erp' | ...
  final String label; // '📖 القرآن الكريم'
  final String emoji;
  final String targetText; // 'يومي' / '3–4 فيديو/أسبوع'
  final LifeCadence cadence;
  final int weeklyTarget; // for weekly pillars: e.g. 4 videos
  final int sort;
  final String? color; // optional '#RRGGBB' accent (L6-DYN)
  final bool archived; // soft-deleted — kept for history, off the plan

  const LifePillar({
    required this.key,
    required this.label,
    this.emoji = '',
    this.targetText = '',
    this.cadence = LifeCadence.daily,
    this.weeklyTarget = 0,
    this.sort = 0,
    this.color,
    this.archived = false,
  });

  factory LifePillar.fromRow(Map<String, Object?> r) => LifePillar(
        key: r['key'] as String,
        label: (r['label'] ?? '') as String,
        emoji: (r['emoji'] ?? '') as String? ?? '',
        targetText: (r['target_text'] ?? '') as String? ?? '',
        cadence: _cadence(r['cadence'] as String?),
        weeklyTarget: (r['weekly_target'] as num?)?.toInt() ?? 0,
        sort: (r['sort'] as num?)?.toInt() ?? 0,
        color: (r['color'] as String?)?.isNotEmpty == true
            ? r['color'] as String
            : null,
        archived: ((r['archived'] as num?)?.toInt() ?? 0) == 1,
      );

  Map<String, Object?> toRow() => {
        'key': key,
        'label': label,
        'emoji': emoji,
        'target_text': targetText,
        'cadence': cadence == LifeCadence.weekly ? 'weekly' : 'daily',
        'weekly_target': weeklyTarget,
        'sort': sort,
        'color': color,
        'archived': archived ? 1 : 0,
      };

  LifePillar copyWith({
    String? label,
    String? emoji,
    String? targetText,
    LifeCadence? cadence,
    int? weeklyTarget,
    int? sort,
    String? color,
    bool? archived,
    bool clearColor = false,
  }) =>
      LifePillar(
        key: key,
        label: label ?? this.label,
        emoji: emoji ?? this.emoji,
        targetText: targetText ?? this.targetText,
        cadence: cadence ?? this.cadence,
        weeklyTarget: weeklyTarget ?? this.weeklyTarget,
        sort: sort ?? this.sort,
        color: clearColor ? null : (color ?? this.color),
        archived: archived ?? this.archived,
      );
}

/// One time-block in the daily schedule (23, seeded, editable).
class LifeSlot {
  final int slotNo; // 1..N, stable id
  final int startMin; // minutes since 00:00, local
  final int endMin;
  final String activity; // '💻 Python / برمجة'
  final String? mihwar; // the slot's free category ('تطوير', 'روحي', …)
  final String? pillarKey; // links to a tracked pillar, or null
  final int sort;
  final bool archived; // retired block — old ticks stay valid, off the plan

  const LifeSlot({
    required this.slotNo,
    required this.startMin,
    required this.endMin,
    required this.activity,
    this.mihwar,
    this.pillarKey,
    this.sort = 0,
    this.archived = false,
  });

  factory LifeSlot.fromRow(Map<String, Object?> r) => LifeSlot(
        slotNo: (r['slot_no'] as num).toInt(),
        startMin: (r['start_min'] as num).toInt(),
        endMin: (r['end_min'] as num).toInt(),
        activity: (r['activity'] ?? '') as String,
        mihwar: r['mihwar'] as String?,
        pillarKey: (r['pillar_key'] as String?)?.isNotEmpty == true
            ? r['pillar_key'] as String
            : null,
        sort: (r['sort'] as num?)?.toInt() ?? 0,
        archived: ((r['archived'] as num?)?.toInt() ?? 0) == 1,
      );

  Map<String, Object?> toRow() => {
        'slot_no': slotNo,
        'start_min': startMin,
        'end_min': endMin,
        'activity': activity,
        'mihwar': mihwar,
        'pillar_key': pillarKey,
        'sort': sort,
        'archived': archived ? 1 : 0,
      };

  LifeSlot copyWith({
    int? startMin,
    int? endMin,
    String? activity,
    String? mihwar,
    String? pillarKey,
    int? sort,
    bool? archived,
    bool clearPillar = false,
  }) =>
      LifeSlot(
        slotNo: slotNo,
        startMin: startMin ?? this.startMin,
        endMin: endMin ?? this.endMin,
        activity: activity ?? this.activity,
        mihwar: mihwar ?? this.mihwar,
        pillarKey: clearPillar ? null : (pillarKey ?? this.pillarKey),
        sort: sort ?? this.sort,
        archived: archived ?? this.archived,
      );

  bool get isTracked => pillarKey != null && pillarKey!.isNotEmpty;

  static String _hhmm(int m) {
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }

  /// `HH:MM–HH:MM`. Render it with `TextDirection.ltr` so the two times
  /// don't swap around the dash inside RTL text.
  String get timeLabel => '${_hhmm(startMin)}–${_hhmm(endMin)}';

  /// Is `now` (minutes-since-midnight) inside this block?
  bool containsMinute(int nowMin) => nowMin >= startMin && nowMin < endMin;
}

/// A note + tomorrow's goal for one date — the reflection layer
/// («ملاحظة اليوم / هدف الغد» from the sheet's tracking tab).
class LifeDayNote {
  final String date; // YYYY-MM-DD
  final String note;
  final String tomorrowGoal;
  final int? mood; // 1..5, optional

  const LifeDayNote({
    required this.date,
    this.note = '',
    this.tomorrowGoal = '',
    this.mood,
  });

  factory LifeDayNote.fromRow(Map<String, Object?> r) => LifeDayNote(
        date: r['date'] as String,
        note: (r['note'] ?? '') as String? ?? '',
        tomorrowGoal: (r['tomorrow_goal'] ?? '') as String? ?? '',
        mood: (r['mood'] as num?)?.toInt(),
      );
}

/// A computed snapshot of one day — never stored, always derived from the
/// slots + the ticks for that date.
class LifeDayProgress {
  final String date; // YYYY-MM-DD
  final int dayIndex; // days since startDate (0-based); can exceed 90
  final int doneCount; // ticked slots
  final int totalCount; // all slots
  final Set<int> doneSlotNos;
  final Map<String, double> byPillar; // pillar key → 0..1 for that day

  const LifeDayProgress({
    required this.date,
    required this.dayIndex,
    required this.doneCount,
    required this.totalCount,
    required this.doneSlotNos,
    required this.byPillar,
  });

  double get percent => totalCount == 0 ? 0 : doneCount / totalCount;

  /// Cycle number (1-based) and the day within it — a soft milestone only.
  int cycle({int cycleLen = 90}) => (dayIndex ~/ cycleLen) + 1;
  int dayInCycle({int cycleLen = 90}) => (dayIndex % cycleLen) + 1;
}

/// One pillar's standing over the last 7 days vs the 7 before — the row
/// shape the weekly review renders. `now`/`prev` are 0..1.
class LifePillarWeek {
  final String key;
  final String label;
  final String emoji;
  final double now;
  final double prev;
  final bool slipping;

  const LifePillarWeek({
    required this.key,
    required this.label,
    required this.emoji,
    required this.now,
    required this.prev,
    required this.slipping,
  });

  double get delta => now - prev;
}

/// «ملخص الأسبوع» (L5) — the last 7 days composed so the UI does no math.
/// Never stored; rebuilt from ticks each time it's opened.
class LifeWeekSummary {
  final String fromDate; // YYYY-MM-DD, 6 days before [toDate]
  final String toDate; // YYYY-MM-DD (usually today)
  final List<({DateTime date, double pct})> days; // oldest → newest, 7
  final double avgPercent; // mean of the 7 day percents
  final double prevAvgPercent; // the 7 days before that
  final int daysHitThreshold; // days at/above streak_threshold
  final int streak; // current streak (with its weekly grace)
  final List<LifePillarWeek> pillars; // sorted: strongest `now` first
  final List<LifeDayNote> notes; // this week's non-empty notes, newest first

  const LifeWeekSummary({
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.avgPercent,
    required this.prevAvgPercent,
    required this.daysHitThreshold,
    required this.streak,
    required this.pillars,
    required this.notes,
  });

  double get delta => avgPercent - prevAvgPercent;
  LifePillarWeek? get strongest => pillars.isEmpty ? null : pillars.first;
  LifePillarWeek? get weakest => pillars.isEmpty ? null : pillars.last;
}

/// Roll-up of one completed 90-day cycle — shown once, at the rollover
/// ritual. `byPillarDone` is done-block counts per tracked pillar key.
class LifeCycleSummary {
  final int cycle; // 1-based
  final String fromDate;
  final String toDate;
  final int lengthDays;
  final double avgPercent;
  final int blocksDone;
  final Map<String, int> byPillarDone;

  const LifeCycleSummary({
    required this.cycle,
    required this.fromDate,
    required this.toDate,
    required this.lengthDays,
    required this.avgPercent,
    required this.blocksDone,
    required this.byPillarDone,
  });
}
