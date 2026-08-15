class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({required this.question, required this.options, required this.correctIndex});

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List),
        correctIndex: json['correctIndex'] as int,
      );
}

class BookOfMonth {
  final String month;
  final String title;
  final String author;
  final String file;
  final List<QuizQuestion> quiz;

  BookOfMonth({
    required this.month,
    required this.title,
    required this.author,
    required this.file,
    required this.quiz,
  });

  bool get isAssigned => title.trim().isNotEmpty;

  factory BookOfMonth.fromJson(Map<String, dynamic> json) => BookOfMonth(
        month: json['month'] as String? ?? '',
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        file: json['file'] as String? ?? '',
        quiz: ((json['quiz'] as List?) ?? [])
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}
