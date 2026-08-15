import 'package:flutter/material.dart';

import '../data/adab_lessons_seed.dart';
import '../theme/app_theme.dart';

/// "باب الأدب" — Ismail's request 2026-08-15. Two curated lesson sets:
/// character/manners, and the value of staying close to the Quran daily.
/// Static content (`data/adab_lessons_seed.dart`), no DB table — same
/// lightweight pattern as the practical-lessons content in "تطبّق".
class AdabScreen extends StatelessWidget {
  const AdabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('باب الأدب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('حسن الخلق والأدب', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...adabLessonsSeed.map((l) => _LessonCard(lesson: l)),
          const SizedBox(height: 24),
          const Text('قيمة القرب من القرآن', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...quranVirtueLessonsSeed.map((l) => _LessonCard(lesson: l)),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final AdabLesson lesson;
  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Text(lesson.theme, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ),
          const SizedBox(height: 8),
          Text(lesson.lessonText, style: const TextStyle(fontSize: 13.5, height: 1.7)),
        ],
      ),
    );
  }
}
