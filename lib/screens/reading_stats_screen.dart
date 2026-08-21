import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/book_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

/// A small personal achievement view — books opened/finished, quizzes
/// passed, average score — built from [book_bookmarks]/[quiz_results],
/// which already cover every book opened in-app (admin, other Telegram
/// content, and the student's own personal library alike). Motivational,
/// not administrative — nothing here is sent anywhere or seen by the admin.
class ReadingStatsScreen extends StatefulWidget {
  const ReadingStatsScreen({super.key});

  @override
  State<ReadingStatsScreen> createState() => _ReadingStatsScreenState();
}

class _ReadingStatsScreenState extends State<ReadingStatsScreen> {
  final _bookRepo = BookRepository();
  bool _loading = true;

  int _booksOpened = 0;
  int _booksFinished = 0;
  int _totalPagesRead = 0;
  int _quizzesPassed = 0;
  int _quizzesTaken = 0;
  double _avgQuizScore = 0;

  static const _passThreshold = 60;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookmarks = await _bookRepo.allBookmarks();
    final quizResults = await _bookRepo.allQuizResults();

    final finished = bookmarks.where((b) => b.totalPages > 0 && b.lastPage >= b.totalPages - 1).length;
    final pagesRead = bookmarks.fold<int>(0, (sum, b) => sum + (b.lastPage + 1));
    final passed = quizResults.where((q) => q.scorePercent >= _passThreshold).length;
    final avgScore = quizResults.isEmpty
        ? 0.0
        : quizResults.fold<int>(0, (sum, q) => sum + q.scorePercent) / quizResults.length;

    if (!mounted) return;
    setState(() {
      _booksOpened = bookmarks.length;
      _booksFinished = finished;
      _totalPagesRead = pagesRead;
      _quizzesTaken = quizResults.length;
      _quizzesPassed = passed;
      _avgQuizScore = avgScore;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(title: Text(basicText('reading_stats_title', lang))),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_generic', lang))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                            icon: Icons.menu_book_rounded, value: '$_booksOpened', label: basicText('books_opened_label', lang))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _StatCard(
                            icon: Icons.check_circle_rounded, value: '$_booksFinished', label: basicText('books_finished_label', lang))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                            icon: Icons.auto_stories_rounded, value: '$_totalPagesRead', label: basicText('pages_read_label', lang))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _StatCard(
                            icon: Icons.quiz_rounded, value: '$_quizzesPassed/$_quizzesTaken', label: basicText('quiz_passed_label', lang))),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.percent_rounded,
                  value: _quizzesTaken == 0 ? '—' : '${_avgQuizScore.round()}%',
                  label: basicText('average_quiz_results_label', lang),
                  wide: true,
                ),
                const SizedBox(height: 20),
                if (_booksOpened == 0)
                  Text(basicText('reading_stats_empty_message', lang),
                      textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool wide;
  const _StatCard({required this.icon, required this.value, required this.label, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: wide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
