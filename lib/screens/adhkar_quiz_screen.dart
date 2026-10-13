import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/adhkar_repository.dart';
import '../repositories/knowledge_review_repository.dart';
import '../services/language_preference_service.dart';
import '../services/spaced_repetition_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

/// This screen's strings — `basicText` in the current app language.
String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);


/// "اختبر نفسك" for Adhkar — Ismail's 2026-08-16 "أريد المستخدم أن يحفظ
/// الأذكار أيضًا" request. Same self-graded "أكمل" mechanic as the Quran
/// and hadith quizzes, generalized to whichever dhikr items the student
/// has opted into review via `adhkar_category_screen.dart`'s "أضفه لحفظ
/// الأذكار" button. Text-only — no audio dependency (see
/// `ADHKAR_AUDIO_SOURCES.md` for why).
class AdhkarQuizScreen extends StatefulWidget {
  const AdhkarQuizScreen({super.key});

  @override
  State<AdhkarQuizScreen> createState() => _AdhkarQuizScreenState();
}

class _AdhkarQuizScreenState extends State<AdhkarQuizScreen> {
  final _repo = AdhkarRepository();
  final _reviewRepo = KnowledgeReviewRepository();

  AdhkarItem? _item;
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
    final ids = await _reviewRepo.allItemIds('adhkar');
    if (ids.isEmpty) {
      if (!mounted) return;
      setState(() {
        _item = null;
        _loading = false;
      });
      return;
    }
    final items = await _repo.itemsByIds(ids);
    if (items.isEmpty) {
      if (!mounted) return;
      setState(() {
        _item = null;
        _loading = false;
      });
      return;
    }
    final chosen = items[Random().nextInt(items.length)];
    if (!mounted) return;
    setState(() {
      _item = chosen;
      _opening = chosen.text.length > 60 ? '${chosen.text.substring(0, 60)}...' : chosen.text;
      _loading = false;
    });
  }

  Future<void> _selfReport(bool knewIt) async {
    final item = _item;
    if (item != null) {
      await _reviewRepo.recordReview('adhkar', item.id, knewIt ? ReviewQuality.good : ReviewQuality.needsReview);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(knewIt ? _t('mq_good') : _t('qz_review_today'))));
    _loadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t('qz_adhkar_title'))),
      body: _loading ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_quiz', LanguagePreferenceService.currentLanguage)) : _buildBody(),
    );
  }

  Widget _buildBody() {
    final item = _item;
    if (item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_t('qz_adhkar_need'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
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
            child: Text(_opening, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, height: 1.9)),
          ),
          const SizedBox(height: 16),
          Text(_t('qz_complete_dhikr'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (!_revealed)
            OutlinedButton(onPressed: () => setState(() => _revealed = true), child: Text(_t('qz_show_dhikr')))
          else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
              child: Text(item.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, height: 1.9)),
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
