import '../data/quran_surahs.dart';
import '../db/database_helper.dart';

class MemorizationQuizQuestion {
  final int surah;
  final int ayah;
  final String surahName;
  final String currentText;
  final int nextSurah;
  final int nextAyah;
  final String nextText;
  MemorizationQuizQuestion({
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.currentText,
    required this.nextSurah,
    required this.nextAyah,
    required this.nextText,
  });
}

/// "اختبر نفسك" — no external question bank exists for this (searched,
/// nothing structured found), so the quiz is generated entirely from
/// `quran_ayat` already in Phase 0: "ما الآية التالية؟" within the
/// student's own memorized pages — the same test real Hifz teachers use.
/// Purely self-graded (تعرفها / تحتاج مراجعة), same principle as every
/// other pillar in this app.
class QuizRepository {
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  Future<MemorizationQuizQuestion?> randomQuestion() async {
    final db = await DatabaseHelper.instance.database;

    // Any ayah on a page the student has actually started memorizing.
    final rows = await db.rawQuery('''
      SELECT q.surah, q.ayah FROM quran_ayat q
      JOIN memorization_progress p ON p.unit_id = q.page_number
      WHERE p.status != 'not_started'
      ORDER BY RANDOM()
      LIMIT 5
    ''');
    if (rows.isEmpty) return null;

    for (final row in rows) {
      final surah = row['surah'] as int;
      final ayah = row['ayah'] as int;
      final question = await _buildQuestion(db, surah, ayah);
      if (question != null) return question;
    }
    return null;
  }

  Future<MemorizationQuizQuestion?> _buildQuestion(dynamic db, int surah, int ayah) async {
    final currentRows = await db.query('quran_ayat', where: 'surah = ? AND ayah = ?', whereArgs: [surah, ayah], limit: 1);
    if (currentRows.isEmpty) return null;

    final nextRows = await db.rawQuery(
      'SELECT * FROM quran_ayat WHERE (surah > ? OR (surah = ? AND ayah > ?)) ORDER BY surah, ayah LIMIT 1',
      [surah, surah, ayah],
    );
    if (nextRows.isEmpty) return null; // current is 114:6, the very last ayah — try another pick.

    final next = nextRows.first;
    return MemorizationQuizQuestion(
      surah: surah,
      ayah: ayah,
      surahName: _surahNames[surah] ?? '$surah',
      currentText: currentRows.first['text_uthmani'] as String,
      nextSurah: next['surah'] as int,
      nextAyah: next['ayah'] as int,
      nextText: next['text_uthmani'] as String,
    );
  }
}
