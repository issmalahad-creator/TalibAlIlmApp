import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class QuranAyahText {
  final int surah;
  final int ayah;
  final String text;
  final int? juzNumber;
  QuranAyahText({required this.surah, required this.ayah, required this.text, this.juzNumber});
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
    return rows
        .map((r) => QuranAyahText(
              surah: r['surah'] as int,
              ayah: r['ayah'] as int,
              text: r['text_uthmani'] as String,
              juzNumber: r['juz_number'] as int?,
            ))
        .toList();
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

  /// Single-ayah tafsir lookup — backs the per-ayah context menu's
  /// "التفسير" action, independent of whether the page-level tafsir
  /// toggle is on.
  Future<String?> tafsirForAyah(int surah, int ayah, String source) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT text FROM tafsir_entries WHERE surah = ? AND ? BETWEEN ayah_from AND ayah_to AND source = ? LIMIT 1',
      [surah, ayah, source],
    );
    if (rows.isEmpty) return null;
    return rows.first['text'] as String?;
  }

  Future<bool> isFavorite(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quran_favorites', where: 'surah = ? AND ayah = ?', whereArgs: [surah, ayah], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> addFavorite(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'quran_favorites',
      {'surah': surah, 'ayah': ayah, 'added_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('quran_favorites', where: 'surah = ? AND ayah = ?', whereArgs: [surah, ayah]);
  }

  /// Backs "الفهرس" (surah index) — the page each surah starts on, for a
  /// tap-to-jump list.
  Future<int?> firstPageOfSurah(int surah) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('SELECT MIN(page_number) AS p FROM quran_ayat WHERE surah = ?', [surah]);
    return rows.isEmpty ? null : rows.first['p'] as int?;
  }

  /// Backs "المفضلة" (favorites/bookmarks list) — every saved ayah with
  /// enough context (surah name resolved by the caller) to jump to its page.
  Future<List<FavoriteAyah>> favoriteAyahs() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT f.surah, f.ayah, q.text_uthmani, q.page_number
      FROM quran_favorites f
      JOIN quran_ayat q ON q.surah = f.surah AND q.ayah = f.ayah
      ORDER BY f.added_date DESC
    ''');
    return rows
        .map((r) => FavoriteAyah(
              surah: r['surah'] as int,
              ayah: r['ayah'] as int,
              text: r['text_uthmani'] as String,
              pageNumber: r['page_number'] as int?,
            ))
        .toList();
  }
}

class FavoriteAyah {
  final int surah;
  final int ayah;
  final String text;
  final int? pageNumber;
  FavoriteAyah({required this.surah, required this.ayah, required this.text, required this.pageNumber});
}
