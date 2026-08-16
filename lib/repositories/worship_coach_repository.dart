import '../db/database_helper.dart';
import '../utils/hijri_date.dart';
import 'adhkar_repository.dart';
import 'memorization_repository.dart';
import 'salah_repository.dart';

enum CoachFocusArea { prayer, quran, dhikr, stable }

const coachWeakThreshold = 0.7;

/// The IF/ELSE waterfall Ismail specified: prayer first, then Quran, then
/// dhikr — the first one below the consistency threshold becomes the
/// single focus. Nothing below threshold means "stable," which recommends
/// introducing the next stage rather than nagging about an already-solid
/// habit. Pure function (no DB) so the rule itself is directly testable.
CoachFocusArea focusAreaFor(double prayer, double quran, double dhikr) {
  if (prayer < coachWeakThreshold) return CoachFocusArea.prayer;
  if (quran < coachWeakThreshold) return CoachFocusArea.quran;
  if (dhikr < coachWeakThreshold) return CoachFocusArea.dhikr;
  return CoachFocusArea.stable;
}

const _prayerLabels = {
  'fajr': 'الفجر',
  'dhuhr': 'الظهر',
  'asr': 'العصر',
  'maghrib': 'المغرب',
  'isha': 'العشاء',
};

class WorshipCoachStatus {
  final double prayerConsistency;
  final double quranConsistency;
  final double dhikrConsistency;
  final CoachFocusArea focus;
  final String stageLabel;
  final String taskLabel;
  final CoachFocusArea taskArea;
  /// True when the Quran task is "review what you have" (mastery gate)
  /// rather than "memorize something new" — لديه UI difference: the
  /// "ابدأ الآن" button should open المراجعة, not تصفح القرآن.
  final bool quranTaskIsReview;
  const WorshipCoachStatus({
    required this.prayerConsistency,
    required this.quranConsistency,
    required this.dhikrConsistency,
    required this.focus,
    required this.stageLabel,
    required this.taskLabel,
    required this.taskArea,
    this.quranTaskIsReview = false,
  });
}

/// "مدرب العبادة" — a rule-based (no AI/LLM) coaching layer over three
/// pillars that already have real tracking data (Salah, Quran, Dhikr).
/// Ismail's explicit spec, condensed: observe consistency, pick ONE weak
/// area via simple IF/ELSE thresholds, recommend ONE small next action,
/// never overwhelm with a full checklist. "أعمال إضافية" (qiyam al-layl,
/// witr, sadaqah, voluntary fasting, dua) are deliberately NOT covered
/// yet — none of them have any existing tracking in this app (confirmed
/// by a full-codebase search), and Ismail's own spec said not to start
/// with everything at once. This reads every number live from the same
/// tables the Salah/Quran/Adhkar screens already use — no separate
/// "coach" schema duplicating that state, same principle as
/// `CurriculumRepository`/`CompletionGoalRepository`.
class WorshipCoachRepository {
  static const _windowDays = 7;

  final _salahRepo = SalahRepository();
  final _memoRepo = MemorizationRepository();
  final _adhkarRepo = AdhkarRepository();

  List<String> _lastNDates() => List.generate(_windowDays, (i) => hijriDateStringForDate(DateTime.now().subtract(Duration(days: i))));

  /// Fraction of the last 7 days' 35 possible prayer slots (5 prayers x 7
  /// days) logged on-time or in congregation — same definition
  /// `SalahRepository.weeklyCompletionCount` already uses, just over a
  /// rolling window instead of the Saturday-aligned week.
  Future<double> prayerConsistency() async {
    var completed = 0;
    for (final date in _lastNDates()) {
      final statuses = await _salahRepo.statusesForDate(date);
      completed += statuses.values.where((s) => s == PrayerStatus.onTime || s == PrayerStatus.jamaah).length;
    }
    return completed / (_windowDays * 5);
  }

  /// Fraction of the last 7 days with any real Quran activity — reading,
  /// new memorization, review, OR application ("طبّق" — actually living
  /// out a Quranic lesson that day, `application_log`/`did_application`).
  /// Application is included deliberately, not just the memorization-
  /// adjacent steps: real research into "أهل القرآن" (QURAN_COMPANION_
  /// ROADMAP.md §4.32) confirms the authentic hadith and classical usage
  /// define it by acting on the Quran, not by reciting or memorizing it —
  /// someone who lives it without memorizing it is closer to "أهل القرآن"
  /// than someone who only recites. Before this fix the coach could only
  /// ever see memorization/reading/review — it had no way to notice
  /// whether the student was actually living what they memorize.
  /// Reuses `daily_session_log`, the same per-day activity flags "جلسة
  /// اليوم" already writes — no new tracking.
  Future<double> quranConsistency() async {
    final db = await DatabaseHelper.instance.database;
    var activeDays = 0;
    for (final date in _lastNDates()) {
      final rows = await db.query('daily_session_log', where: 'date = ?', whereArgs: [date], limit: 1);
      if (rows.isEmpty) continue;
      final r = rows.first;
      final didApplication = (r['did_application'] as int?) == 1;
      if ((r['did_reading'] as int) == 1 || (r['did_new_memorization'] as int) == 1 || (r['did_review'] as int) == 1 || didApplication) {
        activeDays++;
      }
    }
    return activeDays / _windowDays;
  }

  /// Fraction of the last 7 days where every "is_daily_core" adhkar
  /// category (morning/evening) was completed. If no daily-core category
  /// exists yet (shouldn't happen — Phase 5هـ seeds one) this returns 1.0
  /// rather than falsely flagging dhikr as the weak area.
  Future<double> dhikrConsistency() async {
    final categories = await _adhkarRepo.allCategories();
    final core = categories.where((c) => c.isDailyCore).toList();
    if (core.isEmpty) return 1.0;
    final db = await DatabaseHelper.instance.database;
    var activeDays = 0;
    for (final date in _lastNDates()) {
      final rows = await db.query(
        'adhkar_completion',
        where: 'category_id = ? AND completed_date = ?',
        whereArgs: [core.first.id, date],
        limit: 1,
      );
      if (rows.isNotEmpty) activeDays++;
    }
    return activeDays / _windowDays;
  }

  String _stageLabel(CoachFocusArea focus) => switch (focus) {
        CoachFocusArea.prayer => 'المرحلة ١: تثبيت الصلوات',
        CoachFocusArea.quran => 'المرحلة ٢: الوِرد اليومي من القرآن',
        CoachFocusArea.dhikr => 'المرحلة ٣: تثبيت الأذكار',
        CoachFocusArea.stable => 'المرحلة ٤: التعمّق والاستمرار',
      };

  Future<(String label, bool quranIsReview)> _taskFor(CoachFocusArea focus) async {
    switch (focus) {
      case CoachFocusArea.prayer:
        final statuses = await _salahRepo.statusesForToday();
        final next = _prayerLabels.keys.firstWhere((p) => statuses[p] == null, orElse: () => '');
        return (next.isEmpty ? 'حافظ على صلواتك اليوم — أنت على المسار 🌱' : 'مهمتك الآن: صلاة ${_prayerLabels[next]}', false);
      case CoachFocusArea.quran:
        // Mastery gate (advisory, not a lock — QURAN_COMPANION_ROADMAP.md
        // §4.31's golden rule: "لا يُضاف سبق جديد حتى يُتقن سبق الأمس").
        // If there's real review debt (سبقي/منزل due), that's what
        // actually needs solidifying today — recommending a brand-new
        // page on top of an unreviewed backlog is exactly the "page-
        // stacking, not mastery" pattern Ismail originally criticized.
        final due = await _memoRepo.dueToday();
        if (due.isNotEmpty) {
          return ('مهمتك الآن: ثبّت ما حفظته أولًا — ${due.length} صفحة بحاجة مراجعة قبل حفظ جديد', true);
        }
        final next = await _memoRepo.nextRecommendedUnit();
        return (next == null ? 'أكملت الحفظ — واصل المراجعة 🌱' : 'مهمتك الآن: سبق اليوم — احفظ صفحة ${next.id}', false);
      case CoachFocusArea.dhikr:
        final categories = await _adhkarRepo.allCategories();
        for (final c in categories.where((c) => c.isDailyCore)) {
          if (!await _adhkarRepo.isCompletedToday(c.id)) return ('مهمتك الآن: ${c.title}', false);
        }
        return ('أذكارك اليوم مكتملة 🌱', false);
      case CoachFocusArea.stable:
        return ('أداؤك مستقر في الصلاة والقرآن والأذكار — استمر 🌱', false);
    }
  }

  Future<WorshipCoachStatus> status() async {
    final prayer = await prayerConsistency();
    final quran = await quranConsistency();
    final dhikr = await dhikrConsistency();
    final focus = focusAreaFor(prayer, quran, dhikr);
    final (taskLabel, quranIsReview) = await _taskFor(focus);
    return WorshipCoachStatus(
      prayerConsistency: prayer,
      quranConsistency: quran,
      dhikrConsistency: dhikr,
      focus: focus,
      stageLabel: _stageLabel(focus),
      taskLabel: taskLabel,
      taskArea: focus,
      quranTaskIsReview: quranIsReview,
    );
  }
}
