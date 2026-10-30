import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/daily_session_repository.dart';
import '../repositories/quiz_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';
import '../widgets/app_empty_view.dart';
import 'mushaf_semantic_reader_screen.dart';

/// This screen's strings — `basicText` in the current app language.
String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);


/// "اختبر نفسك" — the 6th and last جلسة اليوم step. Generated entirely from
/// `quran_ayat` (no external question bank exists for this — see
/// QuizRepository's doc comment): "ما الآية التالية؟" within the student's
/// own memorized pages, self-graded like every other pillar. Not named
/// `quiz_screen.dart`/`QuizScreen` — that name is already taken by the
/// unrelated Book-of-the-Month quiz feature inherited from DawahReportApp.
class MemorizationQuizScreen extends StatefulWidget {
  const MemorizationQuizScreen({super.key});

  @override
  State<MemorizationQuizScreen> createState() => _MemorizationQuizScreenState();
}

class _MemorizationQuizScreenState extends State<MemorizationQuizScreen> {
  final _repo = QuizRepository();
  final _sessionRepo = DailySessionRepository();

  MemorizationQuizQuestion? _question;
  bool _revealed = false;
  bool _loading = true;
  bool _markedToday = false;

  /// Progressive hinting before full reveal — Ismail's session (2026-08-16
  /// Phase 14 Sub-phase A) flagged the old "one reveal button" as a "blind
  /// self-rate," not real تسميع. A real hifz teacher gives a word or two
  /// of a hint before the full answer, rather than jumping straight to it
  /// — `_hintWordCount` tracks how many words of `q.nextText` are shown
  /// before the student either recalls the rest or asks for the full
  /// answer.
  int _hintWordCount = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _revealed = false;
      _hintWordCount = 0;
    });
    final q = await _repo.randomQuestion();
    if (!mounted) return;
    setState(() {
      _question = q;
      _loading = false;
    });
  }

  void _addHintWord() {
    final total = (_question?.nextText.split(' ').length) ?? 0;
    setState(() => _hintWordCount = (_hintWordCount + 1).clamp(0, total));
  }

  Future<void> _selfReport(bool knewIt) async {
    await _sessionRepo.markStep(quiz: true);
    if (!mounted) return;
    setState(() => _markedToday = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(knewIt ? _t('mq_good') : _t('mq_review_it'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t('mq_title'))),
      body: _loading ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_quiz', LanguagePreferenceService.currentLanguage)) : _buildBody(),
    );
  }

  Widget _buildBody() {
    final q = _question;
    if (q == null) {
      return AppEmptyView(
        icon: Icons.auto_stories_outlined,
        message: _t('mq_need_page'),
        actionLabel: _t('empty_open_mushaf'),
        onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MushafSemanticReaderScreen())),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_t('qs_ref').replaceAll('{s}', q.surahName).replaceAll('{a}', '${q.ayah}'), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
            child: Text(q.currentText, textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, height: 1.9)),
          ),
          const SizedBox(height: 16),
          Text(_t('mq_next_ayah'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (!_revealed) ...[
            if (_hintWordCount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                child: Text(
                  q.nextText.split(' ').take(_hintWordCount).join(' '),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 16, height: 1.9, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _hintWordCount >= q.nextText.split(' ').length ? null : _addHintWord,
                    icon: const Icon(Icons.lightbulb_outline, size: 16),
                    label: Text(_t('mq_hint_word')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(onPressed: () => setState(() => _revealed = true), child: Text(_t('mq_reveal'))),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
              child: Text(q.nextText, textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, height: 1.9)),
            ),
            const SizedBox(height: 16),
            if (_markedToday)
              TextButton(onPressed: _loadQuestion, child: Text(_t('mq_another')))
            else
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => _selfReport(false), child: Text(_t('mq_need_review')))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: () => _selfReport(true), child: Text(_t('mq_knew_it')))),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
