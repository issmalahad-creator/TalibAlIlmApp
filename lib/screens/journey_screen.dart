import 'package:flutter/material.dart';

import '../repositories/journey_plan_repository.dart';
import '../theme/app_theme.dart';
import 'certificates_screen.dart';
import 'curriculum_map_screen.dart';

/// "رحلتي" — QURAN_COMPANION_ROADMAP.md §4.7. First run shows a SMART-style
/// setup wizard (goal duration + current level -> computed daily pace,
/// starting with a lighter trial week); afterwards it's a dashboard showing
/// "أنت اليوم في اليوم X" + mastery progress, with the certificate gallery
/// one tap away.
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
              : _DashboardView(status: _status!, repo: _repo, onCommitmentChanged: _load),
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

  double get _fullDailyPages => 604 / (_years * 365);
  double get _trialDailyPages => _fullDailyPages / 2;

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
          'حدّد هدفك ومستواك الحالي، وسنحسب لك وتيرة يومية مناسبة — تبدأ بأسبوع تجريبي أخف قبل الوتيرة الكاملة.',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الوتيرة الكاملة المحسوبة: ${_fullDailyPages.toStringAsFixed(2)} صفحة يوميًا',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('أول أسبوع تجريبي بوتيرة أخف: ${_trialDailyPages.toStringAsFixed(2)} صفحة يوميًا',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
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
  final VoidCallback onCommitmentChanged;
  const _DashboardView({required this.status, required this.repo, required this.onCommitmentChanged});

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
    onCommitmentChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('أنت اليوم في اليوم ${status.dayNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        if (status.onTrialWeek) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: const Text('أسبوعك التجريبي الأول — وتيرة أخف قبل الانتقال للوتيرة الكاملة',
                style: TextStyle(fontSize: 11.5, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
          ),
        ],
        const SizedBox(height: 20),
        Text('${status.masteryPercent.toStringAsFixed(1)}% إتقان', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: status.masteryPercent / 100, minHeight: 10, backgroundColor: AppColors.divider),
        ),
        const SizedBox(height: 6),
        Text('${status.masteredPages} من ${status.totalPages} صفحة متقنة تمامًا', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
          child: Text('الوتيرة الحالية: ${status.currentDailyPace.toStringAsFixed(2)} صفحة جديدة يوميًا',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
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
