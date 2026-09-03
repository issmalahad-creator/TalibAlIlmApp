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

  const LifePillar({
    required this.key,
    required this.label,
    this.emoji = '',
    this.targetText = '',
    this.cadence = LifeCadence.daily,
    this.weeklyTarget = 0,
    this.sort = 0,
  });

  factory LifePillar.fromRow(Map<String, Object?> r) => LifePillar(
        key: r['key'] as String,
        label: (r['label'] ?? '') as String,
        emoji: (r['emoji'] ?? '') as String? ?? '',
        targetText: (r['target_text'] ?? '') as String? ?? '',
        cadence: _cadence(r['cadence'] as String?),
        weeklyTarget: (r['weekly_target'] as num?)?.toInt() ?? 0,
        sort: (r['sort'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toRow() => {
        'key': key,
        'label': label,
        'emoji': emoji,
        'target_text': targetText,
        'cadence': cadence == LifeCadence.weekly ? 'weekly' : 'daily',
        'weekly_target': weeklyTarget,
        'sort': sort,
      };
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

  const LifeSlot({
    required this.slotNo,
    required this.startMin,
    required this.endMin,
    required this.activity,
    this.mihwar,
    this.pillarKey,
    this.sort = 0,
  });

  factory LifeSlot.fromRow(Map<String, Object?> r) => LifeSlot(
        slotNo: (r['slot_no'] as num).toInt(),
        startMin: (r['start_min'] as num).toInt(),
        endMin: (r['end_min'] as num).toInt(),
        activity: (r['activity'] ?? '') as String,
        mihwar: r['mihwar'] as String?,
        pillarKey: r['pillar_key'] as String?,
        sort: (r['sort'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toRow() => {
        'slot_no': slotNo,
        'start_min': startMin,
        'end_min': endMin,
        'activity': activity,
        'mihwar': mihwar,
        'pillar_key': pillarKey,
        'sort': sort,
      };

  bool get isTracked => pillarKey != null && pillarKey!.isNotEmpty;

  static String _hhmm(int m) {
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }

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
