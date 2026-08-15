class ReadingProgress {
  final String month; // YYYY-MM
  final int percent; // 0-100

  ReadingProgress({required this.month, required this.percent});

  Map<String, Object?> toMap() => {'month': month, 'percent': percent};

  factory ReadingProgress.fromMap(Map<String, Object?> map) => ReadingProgress(
        month: map['month'] as String,
        percent: map['percent'] as int,
      );
}

/// Tracks the exact page reached in a specific PDF (keyed by its content
/// URL, since content now comes dynamically from the Telegram feed).
class BookBookmark {
  final String bookKey;
  final int lastPage;
  final int totalPages;

  /// Hijri date string — when this bookmark was last touched. Nullable
  /// only because rows saved before this column existed have none; every
  /// new save always sets it (see `BookRepository.saveBookmark`'s default).
  final String? lastUpdatedDate;

  BookBookmark({required this.bookKey, required this.lastPage, required this.totalPages, this.lastUpdatedDate});

  double get progressFraction => totalPages <= 0 ? 0 : (lastPage / totalPages).clamp(0, 1).toDouble();

  Map<String, Object?> toMap() => {
        'book_key': bookKey,
        'last_page': lastPage,
        'total_pages': totalPages,
        'last_updated_date': lastUpdatedDate,
      };

  factory BookBookmark.fromMap(Map<String, Object?> map) => BookBookmark(
        bookKey: map['book_key'] as String,
        lastPage: map['last_page'] as int,
        lastUpdatedDate: map['last_updated_date'] as String?,
        totalPages: map['total_pages'] as int,
      );
}

class QuizResult {
  final String month; // YYYY-MM
  final int scorePercent;
  final String takenAt;

  QuizResult({required this.month, required this.scorePercent, required this.takenAt});

  Map<String, Object?> toMap() => {
        'month': month,
        'score_percent': scorePercent,
        'taken_at': takenAt,
      };

  factory QuizResult.fromMap(Map<String, Object?> map) => QuizResult(
        month: map['month'] as String,
        scorePercent: map['score_percent'] as int,
        takenAt: map['taken_at'] as String,
      );
}
