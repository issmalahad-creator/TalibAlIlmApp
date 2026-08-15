import 'package:flutter/material.dart';

import '../data/arabic_curriculum.dart';
import '../repositories/arabic_curriculum_repository.dart';
import '../theme/app_theme.dart';
import 'arabic_alphabet_lesson_screen.dart';

/// "منهج تعلم العربية لغير الناطقين بها" — QURAN_COMPANION_ROADMAP.md
/// Phase 10b. Shows all 5 planned stages; only Stage 1 (alphabet) is
/// actually built — the rest show honestly as "قريبًا" rather than
/// silently disappearing, so the full roadmap stays visible (same
/// anticipation-building idea as the certificate gallery).
class ArabicCurriculumScreen extends StatefulWidget {
  const ArabicCurriculumScreen({super.key});

  @override
  State<ArabicCurriculumScreen> createState() => _ArabicCurriculumScreenState();
}

class _ArabicCurriculumScreenState extends State<ArabicCurriculumScreen> {
  final _repo = ArabicCurriculumRepository();
  Set<String> _learned = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final learned = await _repo.learnedKeys();
    if (!mounted) return;
    setState(() {
      _learned = learned;
      _loading = false;
    });
  }

  int _learnedCountFor(CurriculumStage stage) {
    if (stage.key != 'alphabet') return 0;
    return arabicAlphabet.where((l) => _learned.contains('alphabet_${l.letter}')).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('منهج تعلم العربية')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'مسار متكامل لغير الناطقين بالعربية — من الحروف إلى فهم لغة القرآن',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                ...curriculumStages.map((s) => _StageCard(
                      stage: s,
                      learnedCount: _learnedCountFor(s),
                      totalCount: s.key == 'alphabet' ? arabicAlphabet.length : 0,
                      onTap: s.isBuilt
                          ? () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ArabicAlphabetLessonScreen()));
                              _load();
                            }
                          : null,
                    )),
              ],
            ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final CurriculumStage stage;
  final int learnedCount;
  final int totalCount;
  final VoidCallback? onTap;
  const _StageCard({required this.stage, required this.learnedCount, required this.totalCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: stage.isBuilt ? AppColors.surface : AppColors.divider.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(stage.titleAr, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800))),
                if (!stage.isBuilt) const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 6),
            Text(stage.descriptionAr, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            if (stage.isBuilt) ...[
              const SizedBox(height: 10),
              Text('$learnedCount من $totalCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            ] else ...[
              const SizedBox(height: 10),
              const Text('قريبًا', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
