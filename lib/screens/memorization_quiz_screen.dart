import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/daily_session_repository.dart';
import '../repositories/quiz_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

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
      SnackBar(content: Text(knewIt ? 'أحسنت 🌱' : 'لا بأس — راجعها مع صفحتها اليوم')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختبر نفسك')),
      body: _loading ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_quiz', LanguagePreferenceService.currentLanguage)) : _buildBody(),
    );
  }

  Widget _buildBody() {
    final q = _question;
    if (q == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('احفظ صفحة على الأقل حتى يبني التطبيق لك سؤالًا', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('سورة ${q.surahName} — آية ${q.ayah}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
            child: Text(q.currentText, textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, height: 1.9)),
          ),
          const SizedBox(height: 16),
          const Text('ما الآية التالية؟', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    label: const Text('تلميح كلمة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(onPressed: () => setState(() => _revealed = true), child: const Text('أظهر الإجابة كاملة')),
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
              TextButton(onPressed: _loadQuestion, child: const Text('سؤال آخر'))
            else
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => _selfReport(false), child: const Text('أحتاج مراجعة'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: () => _selfReport(true), child: const Text('كنت أعرفها'))),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
