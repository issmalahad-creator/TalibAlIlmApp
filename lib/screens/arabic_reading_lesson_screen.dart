import 'package:flutter/material.dart';

import '../data/arabic_curriculum.dart';
import '../repositories/arabic_curriculum_repository.dart';
import '../theme/app_theme.dart';

/// Stage 2 lesson: harakat (short vowels), tanween, sukoon, shadda, and
/// madd (long vowels) — the mechanics of reading Arabic script.
class ArabicReadingLessonScreen extends StatefulWidget {
  const ArabicReadingLessonScreen({super.key});

  @override
  State<ArabicReadingLessonScreen> createState() => _ArabicReadingLessonScreenState();
}

class _ArabicReadingLessonScreenState extends State<ArabicReadingLessonScreen> {
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

  Future<void> _toggle(HarakatLesson h) async {
    final key = 'reading_${h.nameAr}';
    if (_learned.contains(key)) return;
    await _repo.markLearned(key);
    setState(() => _learned = {..._learned, key});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المرحلة ٢: القراءة الأساسية')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: harakatLessons
                  .map((h) => InkWell(
                        onTap: () => _toggle(h),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _learned.contains('reading_${h.nameAr}') ? AppColors.primaryLight : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _learned.contains('reading_${h.nameAr}') ? AppColors.primary : AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 56, child: Text(h.symbolAr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(h.nameAr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(h.explanationEn, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(h.exampleAr, style: const TextStyle(fontSize: 12.5)),
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
