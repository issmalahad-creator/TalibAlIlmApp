import 'package:flutter/material.dart';

import '../data/arabic_curriculum.dart';
import '../l10n/basic_translations.dart';
import '../repositories/arabic_curriculum_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

/// Stage 5 lesson: word-by-word breakdown of two short, widely-known
/// surahs (Al-Fatihah, Al-Ikhlas) — direct application of Stages 1-4.
class ArabicQuranicTextLessonScreen extends StatefulWidget {
  const ArabicQuranicTextLessonScreen({super.key});

  @override
  State<ArabicQuranicTextLessonScreen> createState() => _ArabicQuranicTextLessonScreenState();
}

class _ArabicQuranicTextLessonScreenState extends State<ArabicQuranicTextLessonScreen> {
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

  Future<void> _toggleAyah(QuranicAyahLesson a) async {
    final key = 'quranic_text_${a.ayahNumber}_${a.textAr}';
    if (_learned.contains(key)) return;
    await _repo.markLearned(key);
    setState(() => _learned = {..._learned, key});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المرحلة ٥: فهم لغة القرآن')),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_lesson', LanguagePreferenceService.currentLanguage))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final lesson in quranicTextLessons) ...[
                  Text('${lesson.surahNameAr} (${lesson.surahNameEn})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ...lesson.ayat.map((a) => _AyahCard(
                        ayah: a,
                        learned: _learned.contains('quranic_text_${a.ayahNumber}_${a.textAr}'),
                        onTap: () => _toggleAyah(a),
                      )),
                  const SizedBox(height: 20),
                ],
              ],
            ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  final QuranicAyahLesson ayah;
  final bool learned;
  final VoidCallback onTap;
  const _AyahCard({required this.ayah, required this.learned, required this.onTap});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 12, backgroundColor: AppColors.primaryLight, child: Text('${ayah.ayahNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                const Spacer(),
                Icon(learned ? Icons.check_circle : Icons.circle_outlined, size: 18, color: learned ? AppColors.primary : AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 8),
            Text(ayah.textAr, textAlign: TextAlign.right, style: const TextStyle(fontSize: 19, height: 1.9)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ayah.words
                  .map((w) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.wordAr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            Text(w.meaningEn, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
