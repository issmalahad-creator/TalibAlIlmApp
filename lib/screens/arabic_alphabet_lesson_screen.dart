import 'package:flutter/material.dart';

import '../data/arabic_curriculum.dart';
import '../l10n/basic_translations.dart';
import '../repositories/arabic_curriculum_repository.dart';
import '../repositories/milestone_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/loading_view.dart';

/// Stage 1 lesson: the 28-letter Arabic alphabet, each with its name,
/// pronunciation guidance, and an example word — QURAN_COMPANION_ROADMAP.md
/// Phase 10b.
class ArabicAlphabetLessonScreen extends StatefulWidget {
  const ArabicAlphabetLessonScreen({super.key});

  @override
  State<ArabicAlphabetLessonScreen> createState() => _ArabicAlphabetLessonScreenState();
}

class _ArabicAlphabetLessonScreenState extends State<ArabicAlphabetLessonScreen> {
  final _repo = ArabicCurriculumRepository();
  final _milestoneRepo = MilestoneRepository();
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

  Future<void> _toggleLearned(ArabicLetter letter) async {
    final key = 'alphabet_${letter.letter}';
    if (_learned.contains(key)) return;
    await _repo.markLearned(key);
    final newLearned = {..._learned, key};
    setState(() => _learned = newLearned);

    final allDone = arabicAlphabet.every((l) => newLearned.contains('alphabet_${l.letter}'));
    final newlyEarned = await _milestoneRepo.checkArabicCurriculumMilestones(alphabetComplete: allDone);
    for (final milestone in newlyEarned) {
      if (!mounted) return;
      await showCelebration(context, milestone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المرحلة ١: الحروف والنطق')),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_lesson', LanguagePreferenceService.currentLanguage))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${_learned.length} من ${arabicAlphabet.length}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                ...arabicAlphabet.map((letter) => _LetterCard(
                      letter: letter,
                      learned: _learned.contains('alphabet_${letter.letter}'),
                      onTap: () => _toggleLearned(letter),
                    )),
              ],
            ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final ArabicLetter letter;
  final bool learned;
  final VoidCallback onTap;
  const _LetterCard({required this.letter, required this.learned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: learned ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: learned ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(letter.letter, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${letter.nameAr} (${letter.nameEn})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(letter.pronunciationEn, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text('${letter.exampleWordAr} — ${letter.exampleWordEn}', style: const TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
            Icon(learned ? Icons.check_circle : Icons.circle_outlined, color: learned ? AppColors.primary : AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
