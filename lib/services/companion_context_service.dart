import '../repositories/adhkar_repository.dart';
import '../repositories/daily_session_repository.dart';
import '../repositories/journey_plan_repository.dart';
import '../repositories/knowledge_review_repository.dart';
import '../repositories/memorization_repository.dart';
import 'companion_engine.dart';

/// Gathers a live `CompanionContext` from the repositories that already
/// track this data — extracted from `CompanionCard`'s `_load()` (2026-08-17)
/// so the exact same signal-gathering can also drive a real push
/// notification (`CompanionNotificationService`), not just the in-app card.
/// `companion_engine.dart` itself stays DB-free and directly testable —
/// this is the one place that bridges real data into it.
Future<CompanionContext> buildCompanionContext() async {
  final daysAbsent = await DailySessionRepository().daysSinceLastActivity();

  final dueAll = await KnowledgeReviewRepository().dueTodayAll();
  var dueCount = dueAll.values.fold<int>(0, (sum, list) => sum + list.length);
  dueCount += (await MemorizationRepository().dueToday()).length;

  final journeyStatus = await JourneyPlanRepository().status();

  final categories = await AdhkarRepository().allCategories();
  final coreMatches = categories.where((c) => c.title == 'أذكار الصباح والمساء');
  final streak = coreMatches.isEmpty ? 0 : await AdhkarRepository().currentStreak(coreMatches.first.id);

  return CompanionContext(
    daysAbsent: daysAbsent,
    dueReviewsCount: dueCount,
    scheduleStatus: journeyStatus?.goalStatus.scheduleStatus,
    streak: streak,
  );
}
