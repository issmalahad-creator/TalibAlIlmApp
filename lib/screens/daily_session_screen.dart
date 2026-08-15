import 'package:flutter/material.dart';

import '../repositories/application_repository.dart';
import '../repositories/daily_session_repository.dart';
import '../repositories/memorization_repository.dart';
import '../repositories/understanding_repository.dart';
import '../theme/app_theme.dart';
import 'application_screen.dart';
import 'memorization_quiz_screen.dart';
import 'quran_browse_screen.dart';
import 'review_screen.dart';
import 'understanding_screen.dart';

/// "اليوم" — QURAN_COMPANION_ROADMAP.md section 6. Only 3 of the 6 designed
/// steps have real data behind them (قراءة/حفظ جديد/مراجعة); the other 3
/// (فهم/تطبيق/اختبار) wait on Phase 3 and are shown honestly as "قريبًا"
/// rather than faked.
class DailySessionScreen extends StatefulWidget {
  const DailySessionScreen({super.key});

  @override
  State<DailySessionScreen> createState() => _DailySessionScreenState();
}

class _DailySessionScreenState extends State<DailySessionScreen> {
  final _sessionRepo = DailySessionRepository();
  final _memorizationRepo = MemorizationRepository();
  final _understandingRepo = UnderstandingRepository();
  final _applicationRepo = ApplicationRepository();

  DailySessionStatus _status = const DailySessionStatus();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final memorizedToday = await _memorizationRepo.hasMemorizedToday();
    final reviewedToday = await _memorizationRepo.hasReviewedToday();
    final understoodToday = await _understandingRepo.hasUnderstoodToday();
    final appliedToday = await _applicationRepo.hasAppliedToday();
    await _sessionRepo.markStep(
      newMemorization: memorizedToday,
      review: reviewedToday,
      understanding: understoodToday,
      application: appliedToday,
    );
    final status = await _sessionRepo.today();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _markReadingDone() async {
    await _sessionRepo.markStep(reading: true);
    _load();
  }

  Future<void> _openBrowse() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranBrowseScreen()));
    _load();
  }

  Future<void> _openReview() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen()));
    _load();
  }

  Future<void> _openUnderstanding() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const UnderstandingScreen()));
    _load();
  }

  Future<void> _openApplication() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplicationScreen()));
    _load();
  }

  Future<void> _openQuiz() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const MemorizationQuizScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جلسة اليوم')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_status.allDone)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                    child: const Text('أحسنت 🌱 أنجزت جلسة اليوم', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                _StepCard(
                  title: 'قراءة',
                  subtitle: 'اقرأ ولو صفحة واحدة اليوم',
                  icon: Icons.menu_book_rounded,
                  done: _status.didReading,
                  onTap: _status.didReading ? null : _markReadingDone,
                  actionLabel: 'أنجزتها',
                ),
                _StepCard(
                  title: 'الحفظ الجديد',
                  subtitle: 'احفظ صفحة جديدة أو راجع ما تصفّحته',
                  icon: Icons.add_circle_outline_rounded,
                  done: _status.didNewMemorization,
                  onTap: _openBrowse,
                  actionLabel: 'تصفّح القرآن',
                ),
                _StepCard(
                  title: 'المراجعة',
                  subtitle: 'راجع ما استحق المراجعة اليوم',
                  icon: Icons.refresh_rounded,
                  done: _status.didReview,
                  onTap: _openReview,
                  actionLabel: 'ابدأ المراجعة',
                ),
                _StepCard(
                  title: 'الفهم',
                  subtitle: 'تفسير ما حفظته',
                  icon: Icons.auto_stories_rounded,
                  done: _status.didUnderstanding,
                  onTap: _openUnderstanding,
                  actionLabel: 'ابدأ الفهم',
                ),
                _StepCard(
                  title: 'التطبيق 🌱',
                  subtitle: 'درس تطبيقي من محفوظك',
                  icon: Icons.favorite_border_rounded,
                  done: _status.didApplication,
                  onTap: _openApplication,
                  actionLabel: 'درس اليوم',
                ),
                _StepCard(
                  title: 'اختبر نفسك',
                  subtitle: 'ما الآية التالية؟',
                  icon: Icons.quiz_outlined,
                  done: _status.didQuiz,
                  onTap: _openQuiz,
                  actionLabel: 'ابدأ',
                ),
              ],
            ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  final VoidCallback? onTap;
  final String actionLabel;
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.done = false,
    this.onTap,
    this.actionLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Icon(icon, color: done ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (done)
            const Icon(Icons.check_circle, color: AppColors.primary)
          else
            TextButton(onPressed: onTap, child: Text(actionLabel, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
