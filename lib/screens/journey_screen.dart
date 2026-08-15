import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../repositories/completion_goal_repository.dart';
import '../repositories/journey_plan_repository.dart';
import '../theme/app_theme.dart';
import 'certificates_screen.dart';
import 'curriculum_map_screen.dart';
import 'quran_browse_screen.dart';

final _surahNames = {for (final s in quranSurahs) s.number: s.name};

const _scheduleLabels = {
  ScheduleStatus.ahead: ('متقدّم على الخطة', Icons.trending_up, AppColors.primary),
  ScheduleStatus.onTrack: ('في الموعد', Icons.check_circle_outline, AppColors.primaryDark),
  ScheduleStatus.behind: ('متأخر عن الخطة', Icons.schedule_outlined, Color(0xFFD9A441)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('رحلتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'شهاداتي',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CertificatesScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _status == null
              ? _WizardView(repo: _repo, onCreated: _load)
              : _DashboardView(status: _status!, repo: _repo, onChanged: _load),
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

  double get _dailyPages => 604 / (_years * 365);

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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('ابدأ رحلتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          'حدّد هدفك ومستواك الحالي، وسنحسب لك وتيرة يومية مناسبة — وستتكيّف هذه الوتيرة تلقائيًا مع أدائك الفعلي لاحقًا، لا تبقى رقمًا ثابتًا.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        const Text('في كم سنة تريد ختم حفظ القرآن؟', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        Slider(
          value: _years,
          min: 0.5,
          max: 10,
          divisions: 19,
          label: '${_years.toStringAsFixed(1)} سنة',
          onChanged: (v) => setState(() => _years = v),
        ),
        Text('${_years.toStringAsFixed(1)} سنة', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        const Text('ما مستواك الحالي؟', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _levels
              .map((l) => ChoiceChip(
                    label: Text(l.$2),
                    selected: _level == l.$1,
                    onSelected: (_) => setState(() => _level = l.$1),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
          child: Text('الوتيرة المحسوبة: ${_dailyPages.toStringAsFixed(2)} صفحة يوميًا',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 20),
        const Text('التزام شخصي (اختياري)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
          'تذكير تكتبه لنفسك يظهر لك عند العودة بعد انقطاع — أنت من يقرر وينفّذ، لا التطبيق.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commitmentController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'مثال: لو فوّت 3 أيام متتالية، سأتصدق بكذا',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _create, child: const Text('ابدأ رحلتي')),
      ],
    );
  }
}

class _DashboardView extends StatelessWidget {
  final JourneyStatus status;
  final JourneyPlanRepository repo;
  final VoidCallback onChanged;
  const _DashboardView({required this.status, required this.repo, required this.onChanged});

  Future<void> _editCommitment(BuildContext context) async {
    final controller = TextEditingController(text: status.plan.personalCommitmentText ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('التزامي الشخصي'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('حفظ')),
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
        title: const Text('أنت متأخر قليلًا عن الخطة — لا بأس'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر ما يناسبك، بلا أي ضغط:', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            _ChoiceCard(
              title: 'أكمل بوتيرتي الحالية',
              subtitle: 'سيتأخر تاريخ الختم قليلًا، وهذا طبيعي',
              onTap: () => Navigator.pop(context, 'extend'),
            ),
            const SizedBox(height: 8),
            _ChoiceCard(
              title: 'كثّف للوصول للهدف الأصلي',
              subtitle: 'وتيرتك المطلوبة الآن: ${gs.recalculatedDailyTarget.toStringAsFixed(2)} ${status.goal.unitLabel} يوميًا',
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
    final scheduleLabel = _scheduleLabels[gs.scheduleStatus]!;
    final nextUnit = status.nextRecommendedUnit;
    final surahName = nextUnit == null ? null : (_surahNames[nextUnit.surahStart] ?? '${nextUnit.surahStart}');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('أنت اليوم في اليوم ${status.dayNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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
          'الوتيرة الحالية: ${gs.recalculatedDailyTarget.toStringAsFixed(2)} ${status.goal.unitLabel} يوميًا — بقي ${gs.remaining} من ${gs.daysLeft} يومًا',
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        if (gs.scheduleStatus == ScheduleStatus.behind) ...[
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => _showReplanChoices(context), child: const Text('أعِد التخطيط')),
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
                TextButton(onPressed: () => _showReplanChoices(context), child: const Text('أعِد التخطيط', style: TextStyle(fontSize: 12))),
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
                const Text('تكليف اليوم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 6),
                Text('صفحة ${nextUnit.id} — سورة $surahName، من آية ${nextUnit.ayahStart}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => QuranBrowseScreen(highlightUnitId: nextUnit.id))),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('ابدأ الحفظ'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Text('${status.masteryPercent.toStringAsFixed(1)}% إتقان', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: status.masteryPercent / 100, minHeight: 10, backgroundColor: AppColors.divider),
        ),
        const SizedBox(height: 6),
        Text('${status.masteredPages} من ${status.totalPages} صفحة متقنة تمامًا (بعد مراجعات متكررة، لا بمجرد "حفظتها")',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CertificatesScreen())),
          icon: const Icon(Icons.emoji_events_outlined),
          label: const Text('شهاداتي'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurriculumMapScreen())),
          icon: const Icon(Icons.map_outlined),
          label: const Text('خريطتي التعليمية'),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('التزامي الشخصي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                status.plan.personalCommitmentText?.isNotEmpty == true ? status.plan.personalCommitmentText! : 'لم تكتب التزامًا بعد',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: () => _editCommitment(context), child: const Text('تعديل', style: TextStyle(fontSize: 12))),
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
