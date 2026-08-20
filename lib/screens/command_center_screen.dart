import 'package:flutter/material.dart';

import '../data/session_time_budget.dart';
import '../repositories/adhkar_repository.dart';
import '../repositories/journey_plan_repository.dart';
import '../repositories/knowledge_review_repository.dart';
import '../repositories/memorization_repository.dart';
import '../services/completion_forecast.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/loading_view.dart';

/// "لوحة القيادة" — the Command Center piece of 100_IDEAS_FOR_IMPROVEMENT.md's
/// "Learning Decision Engine" (see quirky-gliding-shell.md's plan for the
/// full scoping/honesty discussion). Purely a synthesis screen: every
/// number here already comes from an existing repository or from Batch A's
/// two new pure engines (`computeSessionPlan`'s backlog-aware top-up,
/// `CompletionForecastService`'s real-history bootstrap forecast) — no new
/// tracking, no fabricated statistics. Deliberately its own screen, not
/// folded into `home_screen.dart` (already 17 stacked sections).
class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  static const _illustrativeMinutes = 30;

  bool _loading = true;
  List<SessionPhase>? _baselinePlan;
  List<SessionPhase>? _smartPlan;
  int _dueQuran = 0;
  int _dueKnowledge = 0;
  ForecastResult? _forecast;
  List<(String, int)> _sensitivity = const [];
  double? _masteryPercent;
  int _adhkarStreak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final journeyStatus = await JourneyPlanRepository().status();
    final level = journeyStatus?.plan.level ?? 'beginner';

    final dueQuranUnits = await MemorizationRepository().dueToday();
    final dueAll = await KnowledgeReviewRepository().dueTodayAll();
    final dueKnowledgeCount = dueAll.values.fold<int>(0, (sum, list) => sum + list.length);

    final baseline = computeSessionPlan(level, _illustrativeMinutes);
    final smart = computeSessionPlan(
      level,
      _illustrativeMinutes,
      dueQuranReviews: dueQuranUnits.length,
      dueKnowledgeReviews: dueKnowledgeCount,
    );

    ForecastResult? forecast;
    List<(String, int)> sensitivity = const [];
    if (journeyStatus != null && journeyStatus.goalStatus.remaining > 0) {
      final forecastSvc = CompletionForecastService();
      forecast = await forecastSvc.forecast(remaining: journeyStatus.goalStatus.remaining);
      sensitivity = await forecastSvc.sensitivityFactors(remaining: journeyStatus.goalStatus.remaining);
    }

    final categories = await AdhkarRepository().allCategories();
    final coreMatches = categories.where((c) => c.title == 'أذكار الصباح والمساء');
    final streak = coreMatches.isEmpty ? 0 : await AdhkarRepository().currentStreak(coreMatches.first.id);

    if (!mounted) return;
    setState(() {
      _baselinePlan = baseline;
      _smartPlan = smart;
      _dueQuran = dueQuranUnits.length;
      _dueKnowledge = dueKnowledgeCount;
      _forecast = forecast;
      _sensitivity = sensitivity;
      _masteryPercent = journeyStatus?.masteryPercent;
      _adhkarStreak = streak;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة القيادة')),
      body: _loading
          ? const AppLoadingView(icon: Icons.dashboard_customize_outlined, message: 'جاري حساب لوحتك...')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildAllocationCard(),
                const SizedBox(height: 14),
                _buildForecastCard(),
                const SizedBox(height: 14),
                if (_sensitivity.isNotEmpty) ...[_buildSensitivityCard(), const SizedBox(height: 14)],
                _buildPillarRow(),
              ],
            ),
    );
  }

  Widget _buildAllocationCard() {
    final smart = _smartPlan!;
    final baseline = _baselinePlan!;
    final changed = smart.any((p) => p.minutes != baseline.firstWhere((b) => b.key == p.key).minutes);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.premium,
      curve: AppMotion.entranceCurve,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('خطتك اليوم محسوبة بذكاء', style: AppTextStyles.headline.copyWith(color: AppColors.primaryDark)),
            const SizedBox(height: 4),
            Text('لو خصصت $_illustrativeMinutes دقيقة اليوم — توزيع تجريبي، لا يُلزمك بشيء', style: AppTextStyles.caption),
            const SizedBox(height: 12),
            for (final phase in smart)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(phase.titleAr, style: AppTextStyles.body)),
                    Text('${phase.minutes} د', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
                  ],
                ),
              ),
            if (changed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 15, color: AppColors.primaryDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'زادت "مراجعة سريعة" لأن لديك $_dueQuran صفحة قرآن و$_dueKnowledge مراجعة معرفية مستحقة اليوم',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard() {
    final forecast = _forecast;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text('توقّع ختمك', style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: 10),
          if (forecast == null || forecast.insufficientData)
            const Text(
              'بيانات غير كافية بعد لتوقّع موثوق — يحتاج الأمر أيامًا أكثر من الحفظ الفعلي المسجَّل حتى نستطيع بناء توقّع مبني على تاريخك الحقيقي، لا رقم مختلَق.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.6),
            )
          else ...[
            Row(
              children: [
                Expanded(child: _ForecastStat(label: 'أفضل حالة', days: forecast.p10Days!)),
                Expanded(child: _ForecastStat(label: 'المتوقَّع', days: forecast.p50Days!, emphasize: true)),
                Expanded(child: _ForecastStat(label: 'أسوأ حالة', days: forecast.p90Days!)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'مبني على محاكاة لأيام حفظك الحقيقية المسجَّلة فعليًا، لا افتراضًا نظريًا.',
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSensitivityCard() {
    final top = _sensitivity.first;
    if (top.$2 <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('أكبر عامل يمكن تحسينه: ${top.$1}', style: AppTextStyles.title),
                const SizedBox(height: 2),
                Text('قد يقرّب ختمك ~${top.$2} يومًا لو تحسّن هذا العامل تحديدًا', style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarRow() {
    return Row(
      children: [
        Expanded(child: _PillarStat(icon: Icons.menu_book_outlined, label: 'إتقان القرآن', value: _masteryPercent == null ? '—' : '${_masteryPercent!.toStringAsFixed(0)}%')),
        const SizedBox(width: 10),
        Expanded(child: _PillarStat(icon: Icons.spa_outlined, label: 'استمرارية الأذكار', value: '$_adhkarStreak يوم')),
        const SizedBox(width: 10),
        Expanded(child: _PillarStat(icon: Icons.school_outlined, label: 'مراجعات معرفية مستحقة', value: '$_dueKnowledge')),
      ],
    );
  }
}

class _ForecastStat extends StatelessWidget {
  final String label;
  final int days;
  final bool emphasize;
  const _ForecastStat({required this.label, required this.days, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$days', style: TextStyle(fontSize: emphasize ? 22 : 17, fontWeight: FontWeight.w800, color: emphasize ? AppColors.primaryDark : AppColors.textDark)),
        Text('يوم', style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _PillarStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PillarStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDark),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.title, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }
}
