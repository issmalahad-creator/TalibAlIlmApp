/// «علاجاتي» — a medication course and its individual doses.
///
/// A course is either *interval* («كل 8 ساعات» from a first-dose time) or
/// *fixed times* («صباحًا ومساءً» at the same clock times every day), for a
/// number of days. The doses are generated once by
/// `buildMedicationDoses` (lib/services/medication_schedule.dart) and stored,
/// so a single dose can be moved or marked taken without touching the rest.
library;

enum MedScheduleMode { interval, fixedTimes }

class MedCourse {
  final int? id;
  final String name;

  /// Free text the person types from the prescription — «حبة 500 ملغ»,
  /// «5 مل بعد الأكل». Shown on every reminder.
  final String doseNote;
  final MedScheduleMode mode;

  /// Hours between doses — interval mode only.
  final int intervalHours;

  /// Minutes since midnight, sorted — fixed-times mode only.
  final List<int> timesOfDay;
  final int durationDays;

  /// First dose (interval) / first day (fixed times; only its date and the
  /// time-of-day cut-off matter: times already past on that day are skipped).
  final DateTime startAt;
  final bool remindersOn;

  const MedCourse({
    this.id,
    required this.name,
    this.doseNote = '',
    required this.mode,
    this.intervalHours = 8,
    this.timesOfDay = const [],
    required this.durationDays,
    required this.startAt,
    this.remindersOn = true,
  });

  MedCourse copyWith({
    int? id,
    String? name,
    String? doseNote,
    MedScheduleMode? mode,
    int? intervalHours,
    List<int>? timesOfDay,
    int? durationDays,
    DateTime? startAt,
    bool? remindersOn,
  }) =>
      MedCourse(
        id: id ?? this.id,
        name: name ?? this.name,
        doseNote: doseNote ?? this.doseNote,
        mode: mode ?? this.mode,
        intervalHours: intervalHours ?? this.intervalHours,
        timesOfDay: timesOfDay ?? this.timesOfDay,
        durationDays: durationDays ?? this.durationDays,
        startAt: startAt ?? this.startAt,
        remindersOn: remindersOn ?? this.remindersOn,
      );

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'name': name,
        'dose_note': doseNote,
        'mode': mode.name,
        'interval_hours': intervalHours,
        'times_of_day': timesOfDay.join(','),
        'duration_days': durationDays,
        'start_at': startAt.millisecondsSinceEpoch,
        'reminders_on': remindersOn ? 1 : 0,
      };

  factory MedCourse.fromRow(Map<String, Object?> r) {
    final times = (r['times_of_day'] as String? ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toList();
    return MedCourse(
      id: r['id'] as int?,
      name: r['name'] as String,
      doseNote: r['dose_note'] as String? ?? '',
      mode: r['mode'] == MedScheduleMode.fixedTimes.name ? MedScheduleMode.fixedTimes : MedScheduleMode.interval,
      intervalHours: r['interval_hours'] as int? ?? 8,
      timesOfDay: times,
      durationDays: r['duration_days'] as int,
      startAt: DateTime.fromMillisecondsSinceEpoch(r['start_at'] as int),
      remindersOn: (r['reminders_on'] as int? ?? 1) == 1,
    );
  }
}

enum MedDoseStatus { pending, taken, skipped }

class MedDose {
  final int? id;
  final int courseId;

  /// 1-based position in the course («الجرعة 4 من 21»).
  final int seq;
  final DateTime scheduledAt;
  final MedDoseStatus status;
  final DateTime? takenAt;

  const MedDose({
    this.id,
    required this.courseId,
    required this.seq,
    required this.scheduledAt,
    this.status = MedDoseStatus.pending,
    this.takenAt,
  });

  bool get isPending => status == MedDoseStatus.pending;

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'course_id': courseId,
        'seq': seq,
        'scheduled_at': scheduledAt.millisecondsSinceEpoch,
        'status': status.name,
        'taken_at': takenAt?.millisecondsSinceEpoch,
      };

  factory MedDose.fromRow(Map<String, Object?> r) => MedDose(
        id: r['id'] as int?,
        courseId: r['course_id'] as int,
        seq: r['seq'] as int,
        scheduledAt: DateTime.fromMillisecondsSinceEpoch(r['scheduled_at'] as int),
        status: MedDoseStatus.values.firstWhere((s) => s.name == r['status'], orElse: () => MedDoseStatus.pending),
        takenAt: r['taken_at'] == null ? null : DateTime.fromMillisecondsSinceEpoch(r['taken_at'] as int),
      );
}

/// A course with its doses — what the screens show.
class MedCourseWithDoses {
  final MedCourse course;
  final List<MedDose> doses;
  const MedCourseWithDoses(this.course, this.doses);

  int get total => doses.length;
  int get taken => doses.where((d) => d.status == MedDoseStatus.taken).length;
  int get done => doses.where((d) => !d.isPending).length;
  bool get finished => doses.every((d) => !d.isPending);
  DateTime? get endsAt => doses.isEmpty ? null : doses.last.scheduledAt;
  MedDose? nextPending(DateTime now) {
    for (final d in doses) {
      if (d.isPending && !d.scheduledAt.isBefore(now.subtract(const Duration(hours: 1)))) return d;
    }
    return null;
  }
}
