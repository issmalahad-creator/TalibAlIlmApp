/// One draft per Hijri month — the student's own private study-progress
/// report, written directly (not auto-summarized from a dated activity
/// log), then sent only to the founder's own Telegram chat.
class ReportDraft {
  final String month; // YYYY-MM (Hijri)
  final String booksRead; // الكتب التي قرأتها أو بدأت قراءتها هذا الشهر
  final String currentLevel; // المستوى أو المرحلة الدراسية الحالية
  final String testsAndScores; // الاختبارات التي خضعت لها ونتائجها هذا الشهر
  final String topicsToReview; // مواضيع أحتاج إلى مراجعتها
  final String studyNotes; // ملاحظات عامة عن الدراسة هذا الشهر

  const ReportDraft({
    required this.month,
    this.booksRead = '',
    this.currentLevel = '',
    this.testsAndScores = '',
    this.topicsToReview = '',
    this.studyNotes = '',
  });

  ReportDraft copyWith({
    String? booksRead,
    String? currentLevel,
    String? testsAndScores,
    String? topicsToReview,
    String? studyNotes,
  }) =>
      ReportDraft(
        month: month,
        booksRead: booksRead ?? this.booksRead,
        currentLevel: currentLevel ?? this.currentLevel,
        testsAndScores: testsAndScores ?? this.testsAndScores,
        topicsToReview: topicsToReview ?? this.topicsToReview,
        studyNotes: studyNotes ?? this.studyNotes,
      );

  Map<String, Object?> toMap() => {
        'month': month,
        'books_read': booksRead,
        'current_level': currentLevel,
        'tests_and_scores': testsAndScores,
        'topics_to_review': topicsToReview,
        'study_notes': studyNotes,
      };

  factory ReportDraft.fromMap(Map<String, Object?> map) => ReportDraft(
        month: map['month'] as String,
        booksRead: map['books_read'] as String? ?? '',
        currentLevel: map['current_level'] as String? ?? '',
        testsAndScores: map['tests_and_scores'] as String? ?? '',
        topicsToReview: map['topics_to_review'] as String? ?? '',
        studyNotes: map['study_notes'] as String? ?? '',
      );
}
