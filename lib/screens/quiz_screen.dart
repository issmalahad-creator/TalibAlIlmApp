import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';

import '../models/book_of_month.dart';
import '../models/reading_record.dart';
import '../repositories/book_repository.dart';

/// This screen's strings — `basicText` in the current app language.
String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);


class QuizScreen extends StatefulWidget {
  final BookOfMonth book;
  const QuizScreen({super.key, required this.book});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _bookRepo = BookRepository();
  late List<int?> _answers;
  bool _submitted = false;
  int _scorePercent = 0;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.book.quiz.length, null);
  }

  Future<void> _submit() async {
    if (_answers.any((a) => a == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('qz_answer_all'))),
      );
      return;
    }
    var correct = 0;
    for (var i = 0; i < widget.book.quiz.length; i++) {
      if (_answers[i] == widget.book.quiz[i].correctIndex) correct++;
    }
    final score = ((correct / widget.book.quiz.length) * 100).round();
    // widget.book.month actually holds the book's unique id here (see
    // BookScreen._asBookOfMonth) — quiz results are keyed per-book now that
    // multiple books can coexist, not per-calendar-month.
    await _bookRepo.saveQuizResult(
      QuizResult(
        month: widget.book.month,
        scorePercent: score,
        takenAt: DateTime.now().toIso8601String(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _submitted = true;
      _scorePercent = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('qz_result'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _scorePercent >= 60 ? Icons.check_circle : Icons.info,
                size: 64,
                color: _scorePercent >= 60 ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                _t('qz_your_score').replaceAll('{n}', '$_scorePercent'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(_t('qz_back')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_t('qz_book_quiz').replaceAll('{t}', widget.book.title))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.book.quiz.length,
        itemBuilder: (context, qi) {
          final q = widget.book.quiz[qi];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${qi + 1}. ${q.question}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  RadioGroup<int>(
                    groupValue: _answers[qi],
                    onChanged: (v) => setState(() => _answers[qi] = v),
                    child: Column(
                      children: List.generate(
                        q.options.length,
                        (oi) => RadioListTile<int>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(q.options[oi]),
                          value: oi,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _submit,
            child: Text(_t('qz_submit')),
          ),
        ),
      ),
    );
  }
}
