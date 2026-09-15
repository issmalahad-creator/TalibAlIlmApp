import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/application_repository.dart';
import '../repositories/daily_session_repository.dart';
import '../repositories/memorization_repository.dart';
import '../repositories/understanding_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'application_screen.dart';
import 'guided_session_screen.dart';
import 'memorization_quiz_screen.dart';
import 'quran_browse_screen.dart';
import 'review_screen.dart';
import 'understanding_screen.dart';
import '../widgets/loading_view.dart';

/// "اليوم" — QURAN_COMPANION_ROADMAP.md section 6. All 6 designed steps
/// (قراءة/حفظ جديد/مراجعة/فهم/تطبيق/اختبار) have real data behind them.
/// Free-order checklist for whoever prefers that; "جلسة موجّهة" above it
/// (Phase 14 Sub-phase B) offers the same steps as a single time-budgeted
/// guided walkthrough instead, for whoever wants that structure.
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
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(title: Text(basicText('daily_session_title', lang))),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_generic', lang))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidedSessionScreen()));
                    _load();
                  },
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(basicText('guided_session_by_time_action', lang)),
                ),
                const SizedBox(height: 16),
                if (_status.allDone)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                    child: Text(basicText('session_all_done_message', lang), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                _StepCard(
                  title: basicText('step_reading_title', lang),
                  subtitle: basicText('step_reading_subtitle', lang),
                  icon: Icons.menu_book_rounded,
                  done: _status.didReading,
                  onTap: _status.didReading ? null : _markReadingDone,
                  actionLabel: basicText('step_reading_action', lang),
                ),
                _StepCard(
                  title: basicText('step_new_memo_title', lang),
                  subtitle: basicText('step_new_memo_subtitle', lang),
                  icon: Icons.add_circle_outline_rounded,
                  done: _status.didNewMemorization,
                  onTap: _openBrowse,
                  actionLabel: basicText('step_new_memo_action', lang),
                ),
                _StepCard(
                  title: basicText('review_title', lang),
                  subtitle: basicText('step_review_subtitle', lang),
                  icon: Icons.refresh_rounded,
                  done: _status.didReview,
                  onTap: _openReview,
                  actionLabel: basicText('step_review_action', lang),
                ),
                _StepCard(
                  title: basicText('step_understanding_title', lang),
                  subtitle: basicText('step_understanding_subtitle', lang),
                  icon: Icons.auto_stories_rounded,
                  done: _status.didUnderstanding,
                  onTap: _openUnderstanding,
                  actionLabel: basicText('step_understanding_action', lang),
                ),
                _StepCard(
                  title: basicText('step_application_title', lang),
                  subtitle: basicText('step_application_subtitle', lang),
                  icon: Icons.favorite_border_rounded,
                  done: _status.didApplication,
                  onTap: _openApplication,
                  actionLabel: basicText('step_application_action', lang),
                ),
                _StepCard(
                  title: basicText('step_quiz_title', lang),
                  subtitle: basicText('step_quiz_subtitle', lang),
                  icon: Icons.quiz_outlined,
                  done: _status.didQuiz,
                  onTap: _openQuiz,
                  actionLabel: basicText('step_quiz_action', lang),
                ),
              ],
            ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg), side: const BorderSide(color: AppColors.divider)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
      ),
    );
  }
}
