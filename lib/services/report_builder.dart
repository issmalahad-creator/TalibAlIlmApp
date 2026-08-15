import '../models/book_of_month.dart';
import '../repositories/book_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/report_draft_repository.dart';

class MonthlyReport {
  final Map<String, dynamic> payload;
  final String telegramText;

  MonthlyReport({required this.payload, required this.telegramText});
}

/// Builds the monthly study-progress report directly from the student's own
/// free-text answers (ReportDraft) — sent privately, only to the founder's
/// own Telegram chat, never shared with anyone else.
class ReportBuilder {
  final _profileRepo = ProfileRepository();
  final _draftRepo = ReportDraftRepository();
  final _bookRepo = BookRepository();

  Future<MonthlyReport> build(String month, {required BookOfMonth? book}) async {
    final profile = await _profileRepo.get();
    final draft = await _draftRepo.get(month);
    // Reading progress / quiz results are keyed per-book (book.month holds
    // the book's unique id, see BookScreen._asBookOfMonth) now that
    // multiple books can coexist — not per calendar month.
    final progressKey = book?.month ?? month;
    final readingProgress = await _bookRepo.getProgress(progressKey);
    final quizResult = await _bookRepo.getQuizResult(progressKey);

    final payload = <String, dynamic>{
      'full_name': profile.fullName,
      'residence': profile.residence,
      'study_track': profile.studyTrack,
      'study_source': profile.studySource,
      'books_read': draft.booksRead,
      'current_level': draft.currentLevel,
      'tests_and_scores': draft.testsAndScores,
      'topics_to_review': draft.topicsToReview,
      'study_notes': draft.studyNotes,
      'book_title': book?.isAssigned == true ? book!.title : '',
      'book_progress': readingProgress.percent,
      'quiz_score': quizResult?.scorePercent ?? '',
    };

    final buffer = StringBuffer()
      ..writeln('📋 التقرير الشهري — طالب العلم')
      ..writeln('👤 الاسم الكامل: ${profile.fullName}')
      ..writeln('📍 محل الإقامة: ${profile.residence}')
      ..writeln('🎓 المسار العلمي: ${profile.studyTrack}')
      ..writeln('📚 مصدر الدراسة: ${_orDash(profile.studySource)}')
      ..writeln('')
      ..writeln('📖 الكتب التي قرأتها أو بدأت قراءتها هذا الشهر:')
      ..writeln(_orDash(draft.booksRead))
      ..writeln('')
      ..writeln('🏷 المستوى أو المرحلة الدراسية الحالية:')
      ..writeln(_orDash(draft.currentLevel))
      ..writeln('')
      ..writeln('📝 الاختبارات التي خضعت لها ونتائجها هذا الشهر:')
      ..writeln(_orDash(draft.testsAndScores))
      ..writeln('')
      ..writeln('🔁 مواضيع أحتاج إلى مراجعتها:')
      ..writeln(_orDash(draft.topicsToReview))
      ..writeln('')
      ..writeln('🗒 ملاحظات عامة عن الدراسة هذا الشهر:')
      ..writeln(_orDash(draft.studyNotes));

    if (book?.isAssigned == true) {
      buffer
        ..writeln('')
        ..writeln('📖 كتاب الشهر: ${book!.title}')
        ..writeln('   نسبة القراءة: ${readingProgress.percent}%')
        ..writeln('   درجة الاختبار: ${quizResult?.scorePercent ?? "لم يُجرَ بعد"}');
    }

    return MonthlyReport(payload: payload, telegramText: buffer.toString());
  }

  String _orDash(String value) => value.trim().isEmpty ? '--' : value.trim();
}
