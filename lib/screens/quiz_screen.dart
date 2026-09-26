import 'package:flutter/material.dart';

import '../models/book_of_month.dart';
import '../models/reading_record.dart';
import '../repositories/book_repository.dart';

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
        const SnackBar(content: Text('يرجى الإجابة على جميع الأسئلة')),
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
    setState(() {
      _submitted = true;
      _scorePercent = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('نتيجة الاختبار')),
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
                'نتيجتك: $_scorePercent%',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('عودة'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('اختبار: ${widget.book.title}')),
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
            child: const Text('إرسال الإجابات'),
          ),
        ),
      ),
    );
  }
}
