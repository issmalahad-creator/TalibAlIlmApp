import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class QuranAyahText {
  final int surah;
  final int ayah;
  final String text;
  QuranAyahText({required this.surah, required this.ayah, required this.text});
}

/// "قراءة القرآن" — the periodic full read-through concept added in
/// QURAN_COMPANION_ROADMAP.md section 4.15, genuinely separate from
/// `MemorizationRepository` (reading doesn't require memorizing). Single
/// row tracks the bookmark; `khatm_count` increments every time page 604
/// is finished and the cycle restarts from page 1.
class QuranReadingRepository {
  Future<int> lastPage() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quran_reading_progress', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return 1;
    return (rows.first['last_page'] as int?) ?? 1;
  }

  Future<int> khatmCount() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quran_reading_progress', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return 0;
    return (rows.first['khatm_count'] as int?) ?? 0;
  }

  Future<void> savePosition(int page) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query('quran_reading_progress', where: 'id = 1', limit: 1);
    final currentKhatmCount = existing.isEmpty ? 0 : (existing.first['khatm_count'] as int? ?? 0);
    await db.insert(
      'quran_reading_progress',
      {'id': 1, 'last_page': page, 'last_read_date': todayDate(), 'khatm_count': currentKhatmCount},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Call when the student finishes page 604 — records the completed خَتمة
  /// and restarts the cycle from page 1.
  Future<void> completeKhatmAndRestart() async {
    final db = await DatabaseHelper.instance.database;
    final current = await khatmCount();
    await db.insert(
      'quran_reading_progress',
      {'id': 1, 'last_page': 1, 'last_read_date': todayDate(), 'khatm_count': current + 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<QuranAyahText>> ayatForPage(int page) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quran_ayat', where: 'page_number = ?', whereArgs: [page], orderBy: 'surah, ayah');
    return rows.map((r) => QuranAyahText(surah: r['surah'] as int, ayah: r['ayah'] as int, text: r['text_uthmani'] as String)).toList();
  }

  /// Tafsir for every ayah on [page] in one query, keyed `"surah:ayah"` —
  /// backs the reading screen's inline "التفسير" toggle (Ismail's request
  /// 2026-08-16 to gather everything Quran-related into one screen instead
  /// of a separate search-only view).
  Future<Map<String, String>> tafsirForPage(int page, String source) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT q.surah, q.ayah, t.text AS tafsir
      FROM quran_ayat q
      LEFT JOIN tafsir_entries t ON t.surah = q.surah AND q.ayah BETWEEN t.ayah_from AND t.ayah_to AND t.source = ?
      WHERE q.page_number = ?
      ORDER BY q.surah, q.ayah
    ''', [source, page]);
    return {
      for (final r in rows) '${r['surah']}:${r['ayah']}': (r['tafsir'] as String?) ?? '',
    };
  }
}
