import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/daily_session_repository.dart';
import '../repositories/hadith_repository.dart';
import '../repositories/knowledge_review_repository.dart';
import '../services/language_preference_service.dart';
import '../services/spaced_repetition_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

/// This screen's strings — `basicText` in the current app language.
String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);


/// "اختبر نفسك" for Al-Arba'in Al-Nawawiyyah — same self-graded "أكمل"
/// mechanic as the Quran quiz, generalized to a discrete hadith collection:
/// shows the hadith's opening words, reveals the rest, self-reported.
/// Counts toward the same daily-session "اختبار" step as the Quran quiz.
class HadithQuizScreen extends StatefulWidget {
  const HadithQuizScreen({super.key});

  @override
  State<HadithQuizScreen> createState() => _HadithQuizScreenState();
}

class _HadithQuizScreenState extends State<HadithQuizScreen> {
  final _repo = HadithRepository();
  final _sessionRepo = DailySessionRepository();
  final _reviewRepo = KnowledgeReviewRepository();

  NawawiHadith? _hadith;
  String _opening = '';
  bool _revealed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _revealed = false;
    });
    final memorizedIds = await _repo.memorizedIds();
    if (memorizedIds.isEmpty) {
      if (!mounted) return;
      setState(() {
        _hadith = null;
        _loading = false;
      });
      return;
    }
    final all = await _repo.all();
    final chosenId = memorizedIds[Random().nextInt(memorizedIds.length)];
    final hadith = all.firstWhere((h) => h.id == chosenId);
    if (!mounted) return;
    setState(() {
      _hadith = hadith;
      _opening = hadith.text.length > 60 ? '${hadith.text.substring(0, 60)}...' : hadith.text;
      _loading = false;
    });
  }

  Future<void> _selfReport(bool knewIt) async {
    await _sessionRepo.markStep(quiz: true);
    final hadith = _hadith;
    if (hadith != null) {
      await _reviewRepo.recordReview(
        'hadith',
        hadith.id,
        knewIt ? ReviewQuality.good : ReviewQuality.needsReview,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(knewIt ? _t('mq_good') : _t('qz_review_today'))),
    );
    _loadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t('qz_hadith_title'))),
      body: _loading ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_quiz', LanguagePreferenceService.currentLanguage)) : _buildBody(),
    );
  }

  Widget _buildBody() {
    final hadith = _hadith;
    if (hadith == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_t('qz_hadith_need'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_t('qz_hadith_n').replaceAll('{n}', '${hadith.id}'), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
            child: Text(_opening, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, height: 1.9)),
          ),
          const SizedBox(height: 16),
          Text(_t('qz_complete_hadith'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (!_revealed)
            OutlinedButton(onPressed: () => setState(() => _revealed = true), child: Text(_t('qz_show_hadith')))
          else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
              child: Text(hadith.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, height: 1.9)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => _selfReport(false), child: Text(_t('mq_need_review')))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: () => _selfReport(true), child: Text(_t('qz_remembered')))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
