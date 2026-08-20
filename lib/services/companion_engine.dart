import '../repositories/completion_goal_repository.dart';

/// "رفيق طالب العلم" — Ismail's 2026-08-17 request: a rule-based (NOT AI,
/// no generative text, no network) study companion. This file is the pure
/// decision core — same style as `worship_coach_repository.dart`'s
/// `focusAreaFor()`: a plain function over a small context struct, no DB
/// access, directly testable with no mocking. All copy is pre-written, the
/// function only picks which pre-written message applies.
///
/// Priority order matches Ismail's own rule list, most specific/urgent
/// first: absence > due reviews > behind schedule > ahead of schedule >
/// streak celebration > daily invitation > nothing.
///
/// The last rule is new (2026-08-18: "اول ما يفتح البرنامج... يقترح له
/// عدة اقتراحات") — a deliberate, explicit softening of the original "لا
/// يظهر إلا عندما لديه شيء مفيد ليقوله" rule: on an ordinary day with
/// nothing urgent, the companion now offers a gentle "shall we read
/// today?" nudge instead of staying silent. It still only fires for a
/// student who has used the app at least once (`daysAbsent != null`) — a
/// brand-new install with zero activity yet still gets nothing, same as
/// before.
enum CompanionState { returning, reviewDue, behind, ahead, celebrating, dailyInvite }

class CompanionMessage {
  final CompanionState state;
  final String icon;
  final String title;
  final String body;
  const CompanionMessage({required this.state, required this.icon, required this.title, required this.body});
}

class CompanionContext {
  /// Days since the last recorded session activity — null if the student
  /// has never logged any activity at all (a brand-new install, where an
  /// "absence" message would be meaningless).
  final int? daysAbsent;
  final int dueReviewsCount;
  final ScheduleStatus? scheduleStatus;
  final int streak;
  const CompanionContext({this.daysAbsent, this.dueReviewsCount = 0, this.scheduleStatus, this.streak = 0});
}

const _absenceThresholdDays = 3;
const _celebrationStreakThreshold = 7;

CompanionMessage? companionMessageFor(CompanionContext ctx) {
  if (ctx.daysAbsent != null && ctx.daysAbsent! >= _absenceThresholdDays) {
    return const CompanionMessage(
      state: CompanionState.returning,
      icon: '🤍',
      title: 'الحمد لله على عودتك',
      body: 'لا نحاول تعويض كل شيء اليوم — سنبدأ بخطوة صغيرة.',
    );
  }
  if (ctx.dueReviewsCount > 0) {
    return CompanionMessage(
      state: CompanionState.reviewDue,
      icon: '📚',
      title: 'مراجعتك تنتظرك',
      body: 'لديك ${ctx.dueReviewsCount} من المراجعات المستحقة اليوم.',
    );
  }
  if (ctx.scheduleStatus == ScheduleStatus.behind) {
    return const CompanionMessage(
      state: CompanionState.behind,
      icon: '🙂',
      title: 'لا بأس',
      body: 'تأخرت قليلًا عن خطتك — لنعدّل جلسة اليوم حتى تعود للمسار تدريجيًا.',
    );
  }
  if (ctx.scheduleStatus == ScheduleStatus.ahead) {
    return const CompanionMessage(
      state: CompanionState.ahead,
      icon: '🔥',
      title: 'ممتاز',
      body: 'أنت متقدم عن خطتك — هل نستثمر هذا التقدم اليوم؟',
    );
  }
  if (ctx.streak >= _celebrationStreakThreshold) {
    return CompanionMessage(
      state: CompanionState.celebrating,
      icon: '👏',
      title: 'أحسنت',
      body: 'حافظت على استمرارك ${ctx.streak} يومًا متتاليًا.',
    );
  }
  if (ctx.daysAbsent != null) {
    return const CompanionMessage(
      state: CompanionState.dailyInvite,
      icon: '📖',
      title: 'هل نقرأ القرآن اليوم؟',
      body: 'ولو صفحة واحدة — كل خطوة تُحسب.',
    );
  }
  return null;
}
