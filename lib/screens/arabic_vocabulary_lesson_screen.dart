import 'package:flutter/material.dart';

import '../data/arabic_curriculum.dart';
import '../repositories/arabic_curriculum_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

const _tierLabels = {
  'tier1': 'الأكثر تكرارًا (المستوى ١)',
  'tier2': 'كثيرة التكرار (المستوى ٢)',
  'tier3': 'مهمة (المستوى ٣)',
};

/// Stage 3 lesson: vocabulary grouped by real Quranic-corpus frequency
/// tier — see arabic_curriculum.dart's file-level doc comment for the
/// research this is grounded in.
class ArabicVocabularyLessonScreen extends StatefulWidget {
  const ArabicVocabularyLessonScreen({super.key});

  @override
  State<ArabicVocabularyLessonScreen> createState() => _ArabicVocabularyLessonScreenState();
}

class _ArabicVocabularyLessonScreenState extends State<ArabicVocabularyLessonScreen> {
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

  Future<void> _toggle(VocabWord w) async {
    final key = 'vocab_${w.wordAr}';
    if (_learned.contains(key)) return;
    await _repo.markLearned(key);
    setState(() => _learned = {..._learned, key});
  }

  @override
  Widget build(BuildContext context) {
    final byTier = <String, List<VocabWord>>{};
    for (final w in quranicVocabulary) {
      byTier.putIfAbsent(w.tier, () => []).add(w);
    }
    final learnedCount = quranicVocabulary.where((w) => _learned.contains('vocab_${w.wordAr}')).length;

    return Scaffold(
      appBar: AppBar(title: const Text('المرحلة ٣: أكثر كلمات القرآن تكرارًا')),
      body: _loading
          ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('$learnedCount من ${quranicVocabulary.length}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                const Text(
                  'أول ١٠٠ كلمة الأكثر تكرارًا بالقرآن تغطي تقريبًا نصف نصه — كلما حفظت أكثر من هذه القائمة، فهمت أكثر مما تقرأ.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                for (final tier in ['tier1', 'tier2', 'tier3']) ...[
                  Text(_tierLabels[tier]!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (byTier[tier] ?? []).map((w) => _WordChip(word: w, learned: _learned.contains('vocab_${w.wordAr}'), onTap: () => _toggle(w))).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final VocabWord word;
  final bool learned;
  final VoidCallback onTap;
  const _WordChip({required this.word, required this.learned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: learned ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: learned ? AppColors.primary : AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word.wordAr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(word.meaningEn, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
