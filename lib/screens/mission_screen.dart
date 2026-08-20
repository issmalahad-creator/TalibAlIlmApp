import 'package:flutter/material.dart';

import '../repositories/journey_plan_repository.dart';
import '../repositories/placement_repository.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/loading_view.dart';
import 'adhkar_screen.dart';
import 'arabic_curriculum_screen.dart';
import 'hadith_screen.dart';
import 'quran_browse_screen.dart';
import 'tajweed_screen.dart';
import 'wasitiyyah_screen.dart';

const _dailyMinuteOptions = [15, 20, 30, 45, 60];

Widget _screenForArea(String area) => switch (area) {
      'quran' => const QuranBrowseScreen(),
      'hadith' => const HadithScreen(),
      'aqeedah' => const WasitiyyahScreen(),
      'arabic' => const ArabicCurriculumScreen(),
      'tajweed' => const TajweedScreen(),
      'adhkar' => const AdhkarScreen(),
      _ => const QuranBrowseScreen(),
    };

const _levelLabels = {'beginner': 'مبتدئ', 'intermediate': 'متوسط', 'advanced': 'متقدم'};

/// "رسالتي" (إيكيغاي طالب العلم) — Ismail's 2026-08-17 request: a short
/// self-reflection quiz (ماذا تحب / قيّم نفسك / وقتك المتاح / هدفك خلال
/// سنة) feeding a rich results view inside رحلتي, expanding the
/// already-approved "اختبار تحديد المستوى" (Batch 2 of "الدماغ الذي
/// يربط") rather than duplicating it. Purely advisory — never locks or
/// silently overwrites `journey_plan.level`; see `PlacementRepository`.
class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  final _repo = PlacementRepository();
  final _journeyRepo = JourneyPlanRepository();
  bool _loading = true;
  bool _hasCompleted = false;
  List<AreaRating> _ratings = [];
  StudentMission _mission = StudentMission();
  String? _currentLevel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final hasCompleted = await _repo.hasCompleted();
    final ratings = hasCompleted ? await _repo.allRatings() : <AreaRating>[];
    final mission = hasCompleted ? await _repo.mission() : StudentMission();
    final plan = await _journeyRepo.get();
    if (!mounted) return;
    setState(() {
      _hasCompleted = hasCompleted;
      _ratings = ratings;
      _mission = mission;
      _currentLevel = plan?.level;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رسالتي')),
      body: _loading
          ? const AppLoadingView(icon: Icons.flag_outlined, message: 'جاري التحميل...')
          : _hasCompleted
              ? _ResultsView(
                  ratings: _ratings,
                  mission: _mission,
                  currentLevel: _currentLevel,
                  onReassess: () async {
                    await _repo.reset();
                    _load();
                  },
                  onApplyLevel: (level) async {
                    await _journeyRepo.updateLevel(level);
                    _load();
                  },
                )
              : _QuizFlow(repo: _repo, onDone: _load),
    );
  }
}

class _QuizFlow extends StatefulWidget {
  final PlacementRepository repo;
  final VoidCallback onDone;
  const _QuizFlow({required this.repo, required this.onDone});

  @override
  State<_QuizFlow> createState() => _QuizFlowState();
}

class _QuizFlowState extends State<_QuizFlow> {
  int _step = 0;
  final Set<String> _interests = {};
  final Map<String, int> _ratings = {for (final a in placementAreas) a: 3};
  int _dailyMinutes = 20;
  final _goalController = TextEditingController();

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await widget.repo.saveAssessment(
      ratings: _ratings,
      interests: _interests,
      dailyMinutes: _dailyMinutes,
      oneYearGoal: _goalController.text.trim().isEmpty ? null : _goalController.text.trim(),
    );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: List.generate(4, (i) {
              final active = i <= _step;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: AppMotion.normal,
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: switch (_step) {
                0 => _InterestStep(selected: _interests, onToggle: (a) => setState(() => _interests.contains(a) ? _interests.remove(a) : _interests.add(a))),
                1 => _RatingStep(ratings: _ratings, onChanged: (a, v) => setState(() => _ratings[a] = v)),
                2 => _MinutesStep(selected: _dailyMinutes, onSelect: (m) => setState(() => _dailyMinutes = m)),
                _ => _GoalStep(controller: _goalController),
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _step--), child: const Text('السابق'))),
              if (_step > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _step < 3 ? () => setState(() => _step++) : _submit,
                  child: Text(_step < 3 ? 'التالي' : 'أظهر خريطتي'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _StepScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _InterestStep extends StatelessWidget {
  final Set<String> selected;
  final void Function(String) onToggle;
  const _InterestStep({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'ماذا تحب أن تتعلم أكثر؟',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: placementAreas
            .map((a) => FilterChip(
                  label: Text(placementAreaLabels[a]!),
                  selected: selected.contains(a),
                  onSelected: (_) => onToggle(a),
                ))
            .toList(),
      ),
    );
  }
}

class _RatingStep extends StatelessWidget {
  final Map<String, int> ratings;
  final void Function(String, int) onChanged;
  const _RatingStep({required this.ratings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'قيّم نفسك في كل مجال (تصريح ذاتي فقط)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: placementAreas
            .map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(placementAreaLabels[a]!, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Row(
                        children: List.generate(5, (i) {
                          final filled = i < ratings[a]!;
                          return IconButton(
                            onPressed: () => onChanged(a, i + 1),
                            icon: Icon(filled ? Icons.star : Icons.star_border, color: AppColors.primary),
                          );
                        }),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MinutesStep extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;
  const _MinutesStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'كم دقيقة تستطيع التعلّم يوميًا؟',
      child: Wrap(
        spacing: 8,
        children: _dailyMinuteOptions
            .map((m) => ChoiceChip(label: Text('$m دقيقة'), selected: selected == m, onSelected: (_) => onSelect(m)))
            .toList(),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  final TextEditingController controller;
  const _GoalStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'ما هدفك خلال سنة؟ (اختياري)',
      child: TextField(
        controller: controller,
        maxLines: 4,
        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'مثال: أحفظ 5 أجزاء وأتقن الواسطية'),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final List<AreaRating> ratings;
  final StudentMission mission;
  final String? currentLevel;
  final VoidCallback onReassess;
  final void Function(String level) onApplyLevel;
  const _ResultsView({
    required this.ratings,
    required this.mission,
    required this.currentLevel,
    required this.onReassess,
    required this.onApplyLevel,
  });

  @override
  Widget build(BuildContext context) {
    final byArea = {for (final r in ratings) r.area: r};
    final sorted = [...ratings]..sort((a, b) => a.rating.compareTo(b.rating));
    final weakest = sorted.isEmpty ? null : sorted.first;
    final strongest = sorted.isEmpty ? null : sorted.last;
    final avg = ratings.isEmpty ? 0.0 : ratings.map((r) => r.rating).reduce((a, b) => a + b) / ratings.length;
    final suggested = PlacementRepository().suggestedLevel(ratings);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (mission.oneYearGoal != null && mission.oneYearGoal!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯 هدفك خلال سنة', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(mission.oneYearGoal!, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(child: _KpiCard(label: 'أقوى مجال', value: strongest == null ? '—' : placementAreaLabels[strongest.area]!)),
            const SizedBox(width: 8),
            Expanded(child: _KpiCard(label: 'أضعف مجال', value: weakest == null ? '—' : placementAreaLabels[weakest.area]!)),
            const SizedBox(width: 8),
            Expanded(child: _KpiCard(label: 'المتوسط', value: avg.toStringAsFixed(1))),
          ],
        ),
        const SizedBox(height: 20),
        const Text('خريطتك', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: placementAreas.asMap().entries.map((entry) {
            final area = entry.value;
            final r = byArea[area];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppMotion.premium,
              curve: AppMotion.entranceCurve,
              builder: (context, t, child) => Opacity(opacity: t, child: Transform.scale(scale: 0.85 + 0.15 * t, child: child)),
              child: _AreaRing(label: placementAreaLabels[area]!, rating: r?.rating ?? 0, interest: r?.interest ?? false),
            );
          }).toList(),
        ),
        if (weakest != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('أكبر فرصة لتحسينك الآن: ${placementAreaLabels[weakest.area]}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _screenForArea(weakest.area))),
                    child: const Text('ابدأ من هنا'),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (currentLevel != null && suggested != currentLevel) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
            child: Row(
              children: [
                Expanded(child: Text('المستوى المقترح: ${_levelLabels[suggested]} — استخدمه؟', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                TextButton(onPressed: () => onApplyLevel(suggested), child: const Text('استخدمه')),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        OutlinedButton(onPressed: onReassess, child: const Text('أعد التقييم')),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryDark), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _AreaRing extends StatelessWidget {
  final String label;
  final int rating; // 0-5
  final bool interest;
  const _AreaRing({required this.label, required this.rating, required this.interest});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: interest ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB8860B), width: 2)) : null,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: rating / 5, strokeWidth: 5, backgroundColor: AppColors.divider, color: AppColors.primary),
                Text('$rating/5', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ],
    );
  }
}
