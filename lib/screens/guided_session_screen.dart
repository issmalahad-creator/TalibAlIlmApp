import 'package:flutter/material.dart';

import '../data/session_time_budget.dart';
import '../repositories/daily_session_repository.dart';
import '../repositories/journey_plan_repository.dart';
import '../repositories/memorization_repository.dart';
import '../theme/app_theme.dart';
import 'memorization_quiz_screen.dart';
import 'quran_browse_screen.dart';
import 'review_screen.dart';
import 'understanding_screen.dart';

const _phaseIcons = {
  'quick_review': Icons.refresh_rounded,
  'new_memorization': Icons.add_circle_outline_rounded,
  'repetition': Icons.repeat_rounded,
  'recitation_test': Icons.mic_none_rounded,
  'understanding': Icons.auto_stories_rounded,
};

const _difficultyOptions = [
  ('easy', 'سهلة'),
  ('moderate', 'مناسبة'),
  ('hard', 'صعبة'),
];

/// "جلسة موجّهة" — Phase 14 Sub-phase B. Turns "جلسة اليوم" from an
/// any-order checklist into a single guided walkthrough with a time
/// budget per phase (`session_time_budget.dart`) and an end-of-session
/// self-reflection. Each phase just opens the real existing screen for it
/// (Review/QuranBrowse/Quiz/Understanding) — no duplicated logic, this is
/// purely a sequencing + time-budgeting + reflection layer on top.
class GuidedSessionScreen extends StatefulWidget {
  const GuidedSessionScreen({super.key});

  @override
  State<GuidedSessionScreen> createState() => _GuidedSessionScreenState();
}

class _GuidedSessionScreenState extends State<GuidedSessionScreen> {
  final _journeyRepo = JourneyPlanRepository();
  final _sessionRepo = DailySessionRepository();
  final _memoRepo = MemorizationRepository();

  bool _loading = true;
  String _level = 'beginner';
  MemorizationUnit? _nextUnit;
  int _selectedMinutes = 30;
  List<SessionPhase> _plan = [];
  int _step = 0; // 0 = duration picker, 1..plan.length = phases, plan.length+1 = reflection
  String? _difficulty;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final plan = await _journeyRepo.get();
    final nextUnit = await _memoRepo.nextRecommendedUnit();
    if (!mounted) return;
    setState(() {
      _level = plan?.level ?? 'beginner';
      _nextUnit = nextUnit;
      _loading = false;
    });
  }

  void _start() {
    setState(() {
      _plan = computeSessionPlan(_level, _selectedMinutes);
      _step = 1;
    });
  }

  Future<void> _openPhaseScreen(SessionPhase phase) async {
    switch (phase.key) {
      case 'quick_review':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen()));
        break;
      case 'new_memorization':
        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => QuranBrowseScreen(highlightUnitId: _nextUnit?.id)));
        break;
      case 'recitation_test':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const MemorizationQuizScreen()));
        break;
      case 'understanding':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const UnderstandingScreen()));
        break;
    }
  }

  Future<void> _finish() async {
    if (_difficulty == null) return;
    await _sessionRepo.recordSessionReflection(
      _selectedMinutes,
      _difficulty!,
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('أحسنت 🌱 أنجزت جلستك اليوم', textAlign: TextAlign.center),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('جلسة موجّهة')), body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('جلسة موجّهة')),
      body: _step == 0
          ? _buildPicker()
          : _step <= _plan.length
              ? _buildPhase(_plan[_step - 1])
              : _buildReflection(),
    );
  }

  Widget _buildPicker() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('كم دقيقة لديك اليوم؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          'سنوزّع وقتك على مراحل الجلسة تلقائيًا حسب مستواك — هذا مجرد اقتراح ينظّم وقتك، لا مؤقّت صارم يجبرك على الالتزام بالثانية.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [15, 20, 30, 45, 60]
              .map((m) => ChoiceChip(
                    label: Text('$m د'),
                    selected: _selectedMinutes == m,
                    onSelected: (_) => setState(() => _selectedMinutes = m),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        ...computeSessionPlan(_level, _selectedMinutes).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(_phaseIcons[p.key], size: 16, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.titleAr, style: const TextStyle(fontSize: 13))),
                  Text('${p.minutes} د', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            )),
        const SizedBox(height: 20),
        FilledButton(onPressed: _start, child: const Text('ابدأ الجلسة')),
      ],
    );
  }

  Widget _buildPhase(SessionPhase phase) {
    final isLast = _step == _plan.length;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المرحلة $_step من ${_plan.length}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Icon(_phaseIcons[phase.key], size: 40, color: AppColors.primaryDark),
          const SizedBox(height: 12),
          Text(phase.titleAr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('الوقت المقترح: ${phase.minutes} دقيقة', style: const TextStyle(fontSize: 13, color: AppColors.primaryDark)),
          const SizedBox(height: 10),
          Text(phase.descriptionAr, style: const TextStyle(fontSize: 13.5, height: 1.7)),
          const Spacer(),
          if (phase.key != 'repetition')
            FilledButton.icon(
              onPressed: () => _openPhaseScreen(phase),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('افتح الشاشة'),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_step > 1) TextButton(onPressed: () => setState(() => _step--), child: const Text('السابق')),
              const Spacer(),
              FilledButton(
                onPressed: () => setState(() => _step++),
                child: Text(isLast ? 'إنهاء الجلسة' : 'التالي'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReflection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('كيف كانت جلستك اليوم؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('تقييمك يساعدنا على اقتراح وتيرة أنسب لك لاحقًا — لن يُغيَّر شيء تلقائيًا بدون علمك.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: _difficultyOptions
              .map((d) => ChoiceChip(
                    label: Text(d.$2),
                    selected: _difficulty == d.$1,
                    onSelected: (_) => setState(() => _difficulty = d.$1),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'ملاحظة (اختياري)...', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _difficulty == null ? null : _finish, child: const Text('إنهاء الجلسة')),
      ],
    );
  }
}
