import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/completion_goal_repository.dart';
import '../repositories/journey_plan_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'certificates_screen.dart';
import 'command_center_screen.dart';
import 'curriculum_map_screen.dart';
import 'mission_screen.dart';
import 'quran_browse_screen.dart';
import '../widgets/loading_view.dart';

final _surahNames = {for (final s in quranSurahs) s.number: s.name};

/// Same real hifz-institute daily-pace ceilings as `_WizardView`'s own
/// `_realisticDailyPagesMax` (kept as a separate top-level const rather
/// than refactored into one shared symbol, to avoid touching that
/// existing, working wizard code — Grain 3's "tie the real pace numbers
/// into تكليف اليوم itself" ask, §4.31/§4.33).
const _dashboardRealisticDailyPagesMax = {'beginner': 1.0, 'intermediate': 1.5, 'advanced': 2.0};

(String, IconData, Color) _scheduleLabel(ScheduleStatus status, String lang) => switch (status) {
      ScheduleStatus.ahead => (basicText('schedule_ahead', lang), Icons.trending_up, AppColors.primary),
      ScheduleStatus.onTrack => (basicText('schedule_on_track', lang), Icons.check_circle_outline, AppColors.primaryDark),
      ScheduleStatus.behind => (basicText('schedule_behind', lang), Icons.schedule_outlined, const Color(0xFFD9A441)),
    };

/// "رحلتي" — QURAN_COMPANION_ROADMAP.md §4.7, rebuilt 2026-08-16. First run
/// shows a SMART-style setup wizard (goal duration + current level);
/// afterwards it's a live dashboard — the pace/schedule status comes from
/// `CompletionGoalRepository`'s already-adaptive engine (never a frozen
/// number), and "تكليف اليوم" gives a concrete next page instead of
/// leaving the student to browse the Mushaf and pick one themselves.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  final _repo = JourneyPlanRepository();
  JourneyStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final status = await _repo.status();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 2026-08-17 (Ismail's screenshot of the still-Arabic _DashboardView):
    // one `ValueListenableBuilder` around the whole Scaffold now, so the
    // AppBar title/tooltip and the dashboard body share the same live
    // `lang` instead of each needing its own separate wrapper.
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        appBar: AppBar(
          title: Text(basicText('my_journey', lang)),
          actions: [
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: basicText('my_certificates_label', lang),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CertificatesScreen())),
            ),
          ],
        ),
        body: _loading
            ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_progress', lang))
            : _status == null
                ? _WizardView(repo: _repo, onCreated: _load)
                : _DashboardView(status: _status!, repo: _repo, onChanged: _load, lang: lang),
      ),
    );
  }
}

class _WizardView extends StatefulWidget {
  final JourneyPlanRepository repo;
  final VoidCallback onCreated;
  const _WizardView({required this.repo, required this.onCreated});

  @override
  State<_WizardView> createState() => _WizardViewState();
}

class _WizardViewState extends State<_WizardView> {
  double _years = 3;
  String _level = 'beginner';
  final _commitmentController = TextEditingController();

  static const _levels = [
    ('beginner', 'مبتدئ'),
    ('intermediate', 'متوسط'),
    ('advanced', 'متقدم'),
  ];

  /// Real daily سبق (new-memorization) ranges per level — from actual
  /// hifz-institute guidance researched 2026-08-16 at Ismail's request
  /// (QURAN_COMPANION_ROADMAP.md §4.31), not an invented estimate:
  /// beginner/part-time ≈ 0.5-1 page/day, motivated teen/adult ≈ 1-1.5,
  /// full-time student ≈ 1-2 (up to 2 pushing the realistic ceiling).
  static const _realisticDailyPagesMax = {'beginner': 1.0, 'intermediate': 1.5, 'advanced': 2.0};

  double get _dailyPages => 604 / (_years * 365);

  bool get _isAmbitious => _dailyPages > (_realisticDailyPagesMax[_level] ?? 2.0);

  @override
  void dispose() {
    _commitmentController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    await widget.repo.create(
      targetYears: _years,
      level: _level,
      personalCommitmentText: _commitmentController.text.trim().isEmpty ? null : _commitmentController.text.trim(),
    );
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) {
        final levelLabels = {
          'beginner': basicText('level_beginner', lang),
          'intermediate': basicText('level_intermediate', lang),
          'advanced': basicText('level_advanced', lang),
        };
        return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(basicText('journey_start_title', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          basicText('journey_start_subtitle', lang),
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        Text(basicText('journey_years_question', lang), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        Slider(
          value: _years,
          min: 0.5,
          max: 10,
          divisions: 19,
          label: '${_years.toStringAsFixed(1)} ${basicText('years_label', lang)}',
          onChanged: (v) => setState(() => _years = v),
        ),
        Text('${_years.toStringAsFixed(1)} ${basicText('years_label', lang)}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        Text(basicText('journey_level_question', lang), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _levels
              .map((l) => ChoiceChip(
                    label: Text(levelLabels[l.$1] ?? l.$2),
                    selected: _level == l.$1,
                    onSelected: (_) => setState(() => _level = l.$1),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isAmbitious ? const Color(0xFFFFF3E0) : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${basicText('calculated_pace_prefix', lang)}: ${_dailyPages.toStringAsFixed(2)} ${basicText('pages_per_day_label', lang)}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              if (_isAmbitious) ...[
                const SizedBox(height: 6),
                Text(
                  basicText('ambitious_pace_warning', lang),
                  style: TextStyle(fontSize: 11, color: Colors.brown.shade700, height: 1.5),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(basicText('journey_commitment_label', lang), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          basicText('journey_commitment_desc', lang),
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commitmentController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: basicText('journey_commitment_placeholder', lang),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _create, child: Text(basicText('journey_start_button', lang))),
      ],
    );
      },
    );
  }
}

class _DashboardView extends StatelessWidget {
  final JourneyStatus status;
  final JourneyPlanRepository repo;
  final VoidCallback onChanged;
  final String lang;
  const _DashboardView({required this.status, required this.repo, required this.onChanged, required this.lang});

  Future<void> _editCommitment(BuildContext context) async {
    final controller = TextEditingController(text: status.plan.personalCommitmentText ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('personal_commitment_label', lang)),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(basicText('cancel', lang))),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(basicText('save', lang))),
        ],
      ),
    );
    if (result == null) return;
    await repo.updateCommitment(result.isEmpty ? null : result);
    onChanged();
  }

  Future<void> _showReplanChoices(BuildContext context) async {
    final gs = status.goalStatus;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('behind_schedule_title', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(basicText('choose_whats_right_for_you', lang), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            _ChoiceCard(
              title: basicText('continue_current_pace_title', lang),
              subtitle: basicText('continue_current_pace_subtitle', lang),
              onTap: () => Navigator.pop(context, 'extend'),
            ),
            const SizedBox(height: 8),
            _ChoiceCard(
              title: basicText('intensify_title', lang),
              subtitle: '${basicText('target_pace_now_prefix', lang)}: ${gs.recalculatedDailyTarget.toStringAsFixed(2)} ${status.goal.unitLabel} ${basicText('daily_suffix', lang)}',
              onTap: () => Navigator.pop(context, 'intensify'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'extend') {
      await repo.extendAtCurrentPace(status.goal, gs.remaining);
      onChanged();
    }
    // 'intensify' needs no write — the dashboard already shows the live
    // recalculated pace; the choice is just informational.
  }

  @override
  Widget build(BuildContext context) {
    final gs = status.goalStatus;
    final scheduleLabel = _scheduleLabel(gs.scheduleStatus, lang);
    final nextUnit = status.nextRecommendedUnit;
    final surahName = nextUnit == null ? null : (_surahNames[nextUnit.surahStart] ?? '${nextUnit.surahStart}');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('${basicText('day_number_prefix', lang)} ${status.dayNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: scheduleLabel.$3.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(scheduleLabel.$2, size: 15, color: scheduleLabel.$3),
              const SizedBox(width: 6),
              Text(scheduleLabel.$1, style: TextStyle(fontSize: 12, color: scheduleLabel.$3, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${basicText('current_pace_label', lang)}: ${gs.recalculatedDailyTarget.toStringAsFixed(2)} ${status.goal.unitLabel} ${basicText('daily_suffix', lang)} — ${basicText('remaining_prefix', lang)} ${gs.remaining} ${basicText('of_label', lang)} ${gs.daysLeft} ${basicText('days_unit_label', lang)}',
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        if (gs.scheduleStatus == ScheduleStatus.behind) ...[
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => _showReplanChoices(context), child: Text(basicText('replan_button', lang))),
        ],
        if (status.difficultyAdvisory != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(status.difficultyAdvisory!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                TextButton(onPressed: () => _showReplanChoices(context), child: Text(basicText('replan_button', lang), style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ],
        if (status.masteryGateAdvisory != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8CD8A))),
            child: Row(
              children: [
                const Icon(Icons.psychology_alt_outlined, size: 18, color: Color(0xFFB8860B)),
                const SizedBox(width: 8),
                Expanded(child: Text(status.masteryGateAdvisory!, style: const TextStyle(fontSize: 12, color: Color(0xFF8A6416)))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (nextUnit != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(basicText('today_assignment_label', lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 6),
                Text('${basicText('page_label', lang)} ${nextUnit.id} — سورة $surahName، ${basicText('from_ayah_label', lang)} ${nextUnit.ayahStart}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '${basicText('max_realistic_pace_label', lang)}: ${_dashboardRealisticDailyPagesMax[status.plan.level] ?? 2.0} ${basicText('pages_per_day_label', lang)}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => QuranBrowseScreen(highlightUnitId: nextUnit.id))),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(basicText('start_memorizing_button', lang)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Text('${status.masteryPercent.toStringAsFixed(1)}% ${basicText('mastery_percent_label', lang)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: status.masteryPercent / 100, minHeight: 10, backgroundColor: AppColors.divider),
        ),
        const SizedBox(height: 6),
        Text('${status.masteredPages} ${basicText('of_label', lang)} ${status.totalPages} ${basicText('pages_fully_mastered_suffix', lang)}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text('${basicText('hizb_completed_prefix', lang)}: ${status.hizbCompleted} ${basicText('of_label', lang)} ${status.hizbTotal} ${basicText('hizb_completed_suffix', lang)}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          '${basicText('days_ago_had_pages_prefix', lang)} ${status.pagesStarted30DaysAgo} ${basicText('pages_word', lang)} — ${basicText('added_since_then_prefix', lang)} ${(status.pagesStartedNow - status.pagesStarted30DaysAgo).clamp(0, 604)} ${basicText('pages_since_then_suffix', lang)}'
          ' ${basicText('longest_streak_label', lang)}: ${status.longestMemorizationStreak} ${basicText('days_unit_label', lang)}',
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        if (status.reviewSuccessRate != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.insights_outlined, size: 15, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Text(
                '${basicText('review_success_rate_prefix', lang)}: ${status.reviewSuccessRate!.toStringAsFixed(0)}% ${basicText('excellent_good_label', lang)}',
                style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CertificatesScreen())),
          icon: const Icon(Icons.emoji_events_outlined),
          label: Text(basicText('my_certificates_label', lang)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurriculumMapScreen())),
          icon: const Icon(Icons.map_outlined),
          label: Text(basicText('my_curriculum_map_label', lang)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionScreen())),
          icon: const Icon(Icons.flag_outlined),
          label: Text(basicText('my_mission_label', lang)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommandCenterScreen())),
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: Text(basicText('command_center_label', lang)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(basicText('personal_commitment_label', lang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                status.plan.personalCommitmentText?.isNotEmpty == true ? status.plan.personalCommitmentText! : basicText('no_commitment_yet', lang),
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: () => _editCommitment(context), child: Text(basicText('edit_action', lang), style: const TextStyle(fontSize: 12))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ChoiceCard({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
