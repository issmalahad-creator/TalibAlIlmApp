import '../data/quran_surahs.dart';
import '../db/database_helper.dart';
import '../utils/arabic_normalize.dart';

class QuranSearchResult {
  final int surah;
  final int ayah;
  final String surahName;
  final String textUthmani;
  final int? pageNumber;
  final int? juzNumber;
  QuranSearchResult({
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.textUthmani,
    this.pageNumber,
    this.juzNumber,
  });
}

/// Full-Quran word/phrase search — Phase 1 of QURAN_COMPANION_ROADMAP.md
/// ("البحث بدون تشكيل"). Matches against `text_normalized` (tashkeel and
/// letter-variant stripped) so a plain, undiacritized query still finds
/// fully-vocalized ayat; every returned ayah's *display* text stays the
/// untouched `text_uthmani`.
class QuranSearchRepository {
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  /// Also accepts a direct `"سورة آية"` / `"سورة:آية"` reference (e.g.
  /// "البقرة 255") and resolves it to that single ayah instead of a text
  /// search, when the query matches a known surah name followed by a number.
  Future<List<QuranSearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final refMatch = RegExp(r'^(.+?)\s*[:\s]\s*(\d+)$').firstMatch(trimmed);
    if (refMatch != null) {
      final surahQuery = normalizeArabicForSearch(refMatch.group(1)!.trim());
      final ayahNum = int.tryParse(refMatch.group(2)!);
      final surahEntry = quranSurahs.where((s) => normalizeArabicForSearch(s.name) == surahQuery).toList();
      if (surahEntry.isNotEmpty && ayahNum != null) {
        return _byReference(surahEntry.first.number, ayahNum);
      }
    }

    return _byText(trimmed);
  }

  Future<List<QuranSearchResult>> _byReference(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'quran_ayat',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
      limit: 1,
    );
    return rows.map(_toResult).toList();
  }

  Future<List<QuranSearchResult>> _byText(String query) async {
    final normalized = normalizeArabicForSearch(query);
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'quran_ayat',
      where: 'text_normalized LIKE ?',
      whereArgs: ['%$normalized%'],
      orderBy: 'surah, ayah',
      limit: 300,
    );
    return rows.map(_toResult).toList();
  }

  QuranSearchResult _toResult(Map<String, Object?> row) {
    final surah = row['surah'] as int;
    return QuranSearchResult(
      surah: surah,
      ayah: row['ayah'] as int,
      surahName: _surahNames[surah] ?? '',
      textUthmani: row['text_uthmani'] as String,
      pageNumber: row['page_number'] as int?,
      juzNumber: row['juz_number'] as int?,
    );
  }
}
