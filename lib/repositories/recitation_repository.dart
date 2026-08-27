import '../db/database_helper.dart';
import '../utils/month.dart';
import '../utils/recitation_alignment.dart';

/// A previously-recited ayah's real result, for the mistake-history list
/// (76.3e) — mirrors Tarteel's real "Mistake History/Frequency" feature.
class RecurringRecitationMistake {
  final int surah;
  final int ayah;
  final String expectedWord;
  final int timesWrong;
  const RecurringRecitationMistake({required this.surah, required this.ayah, required this.expectedWord, required this.timesWrong});
}

/// Backs "تسميع" (Phase 76.3) — stores every real recitation-practice
/// attempt and its word-level mistakes, computed by
/// `alignRecitation` (`lib/utils/recitation_alignment.dart`). Never stores
/// a tajweed/pronunciation-quality judgment — only missing/wrong/extra
/// words, the same honest scope documented in TODO.md 76.3g and verified
/// against Tarteel's own real shipped feature.
class RecitationRepository {
  /// Runs the real alignment, persists the session + its word mistakes,
  /// and returns the alignment result for the screen to render immediately
  /// — the caller doesn't need a second query to show the result it just
  /// produced.
  Future<RecitationAlignmentResult> recordAttempt({
    required int surah,
    required int ayah,
    required String mode,
    required List<String> expectedWords,
    required List<String> saidWords,
  }) async {
    final result = alignRecitation(expectedWords: expectedWords, saidWords: saidWords);
    final db = await DatabaseHelper.instance.database;
    final sessionId = await db.insert('recitation_sessions', {
      'surah': surah,
      'ayah': ayah,
      'mode': mode,
      'score': result.score,
      'extra_word_count': result.extraWordCount,
      'created_at': todayDate(),
    });

    final batch = db.batch();
    for (var i = 0; i < result.words.length; i++) {
      final w = result.words[i];
      if (w.status == RecitationWordStatus.correct) continue;
      batch.insert('recitation_mistakes', {
        'session_id': sessionId,
        'surah': surah,
        'ayah': ayah,
        'word_index': i,
        'expected_word': w.expectedWord,
        'said_word': w.saidWord,
        'status': w.status.name,
      });
    }
    await batch.commit(noResult: true);

    return result;
  }

  /// The ayat a student keeps making real mistakes on, most-frequent
  /// first — the actual data behind a "needs more practice" list.
  Future<List<RecurringRecitationMistake>> recurringMistakes({int limit = 10, int sinceDays = 30}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT surah, ayah, expected_word, COUNT(*) AS times_wrong
      FROM recitation_mistakes
      GROUP BY surah, ayah, expected_word
      ORDER BY times_wrong DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows
        .map((r) => RecurringRecitationMistake(
              surah: r['surah'] as int,
              ayah: r['ayah'] as int,
              expectedWord: r['expected_word'] as String,
              timesWrong: r['times_wrong'] as int,
            ))
        .toList();
  }

  /// Real session history for one ayah, most recent first — the score
  /// trend a student can see improving over time.
  Future<List<(String date, double score)>> sessionHistory(int surah, int ayah, {int limit = 20}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'recitation_sessions',
      columns: ['created_at', 'score'],
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map((r) => (r['created_at'] as String, r['score'] as double)).toList();
  }
}
