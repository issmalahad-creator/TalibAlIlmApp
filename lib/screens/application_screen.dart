import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../repositories/application_repository.dart';
import '../theme/app_theme.dart';

/// "التطبيق 🌱" — Phase 3 of QURAN_COMPANION_ROADMAP.md section 4.8. A
/// short, concrete lesson from a surah the student has actually memorized,
/// self-reported as applied — never graded, never verified.
class ApplicationScreen extends StatefulWidget {
  const ApplicationScreen({super.key});

  @override
  State<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {
  final _repo = ApplicationRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};
  final _reflectionController = TextEditingController();

  PracticalLesson? _lesson;
  bool _loading = true;
  bool _appliedToday = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final lessons = await _repo.availableLessons();
    final appliedToday = await _repo.hasAppliedToday();
    if (!mounted) return;
    setState(() {
      _lesson = lessons.isEmpty ? null : lessons.first;
      _appliedToday = appliedToday;
      _loading = false;
    });
  }

  Future<void> _apply() async {
    if (_lesson == null) return;
    await _repo.logApplication(_lesson!.id, reflection: _reflectionController.text.trim().isEmpty ? null : _reflectionController.text.trim());
    _reflectionController.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التطبيق')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }

  Widget _buildBody() {
    final lesson = _lesson;
    if (lesson == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'لا توجد دروس تطبيقية متاحة بعد لما حفظته — تُضاف تدريجيًا لسور جديدة',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                      child: Text(lesson.valueTag, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                    ),
                    const Spacer(),
                    Text('سورة ${_surahNames[lesson.surah] ?? lesson.surah}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(lesson.lessonText, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, height: 1.8)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_appliedToday)
            const Text('طبّقت درسًا اليوم بالفعل 🌱', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700))
          else ...[
            TextField(
              controller: _reflectionController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'كيف طبّقتها؟ (اختياري)', isDense: true),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: _apply, icon: const Icon(Icons.check), label: const Text('طبّقتها اليوم')),
          ],
        ],
      ),
    );
  }
}
