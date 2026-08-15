import 'package:flutter/material.dart';

import '../repositories/daily_session_repository.dart';
import '../repositories/quiz_repository.dart';
import '../theme/app_theme.dart';

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
    final q = await _repo.randomQuestion();
    if (!mounted) return;
    setState(() {
      _question = q;
      _loading = false;
    });
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
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
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
          if (!_revealed)
            OutlinedButton(onPressed: () => setState(() => _revealed = true), child: const Text('أظهر الإجابة'))
          else ...[
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
