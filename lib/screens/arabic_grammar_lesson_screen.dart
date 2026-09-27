import 'package:flutter/material.dart';

import '../data/arabic_curriculum.dart';
import '../l10n/basic_translations.dart';
import '../repositories/arabic_curriculum_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

/// Stage 4 lesson: 10 core grammar concepts, sequenced the way
/// established non-native Arabic courses introduce them.
class ArabicGrammarLessonScreen extends StatefulWidget {
  const ArabicGrammarLessonScreen({super.key});

  @override
  State<ArabicGrammarLessonScreen> createState() => _ArabicGrammarLessonScreenState();
}

class _ArabicGrammarLessonScreenState extends State<ArabicGrammarLessonScreen> {
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

  Future<void> _toggle(GrammarConcept c) async {
    final key = 'grammar_${c.titleAr}';
    if (_learned.contains(key)) return;
    await _repo.markLearned(key);
    setState(() => _learned = {..._learned, key});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المرحلة ٤: القواعد الأساسية')),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_lesson', LanguagePreferenceService.currentLanguage))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: grammarConcepts
                  .map((c) => InkWell(
                        onTap: () => _toggle(c),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _learned.contains('grammar_${c.titleAr}') ? AppColors.primaryLight : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _learned.contains('grammar_${c.titleAr}') ? AppColors.primary : AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text('${c.titleAr} (${c.titleEn})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                                  Icon(
                                    _learned.contains('grammar_${c.titleAr}') ? Icons.check_circle : Icons.circle_outlined,
                                    size: 18,
                                    color: _learned.contains('grammar_${c.titleAr}') ? AppColors.primary : AppColors.textMuted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(c.explanationEn, style: const TextStyle(fontSize: 12.5, height: 1.6)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.exampleAr, style: const TextStyle(fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text(c.exampleEn, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}
