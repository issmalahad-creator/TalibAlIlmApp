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
  final String? tafsir;
  QuranSearchResult({
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.textUthmani,
    this.pageNumber,
    this.juzNumber,
    this.tafsir,
  });
}

/// Full-Quran word/phrase search — Phase 1 of QURAN_COMPANION_ROADMAP.md
/// ("البحث بدون تشكيل"). Matches against `text_normalized` (tashkeel and
/// letter-variant stripped) so a plain, undiacritized query still finds
/// fully-vocalized ayat; every returned ayah's *display* text stays the
/// untouched `text_uthmani`.
class QuranSearchRepository {
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  /// The four available tafsir sources (slug, display label) — see
  /// QURAN_COMPANION_ROADMAP.md's "التفسير" section. Default is the concise
  /// modern mukhtasar, not the full Ibn Kathir text, since search results
  /// are meant to be scannable.
  static const tafsirSources = [
    ('almukhtasar', 'التفسير المختصر'),
    ('muyassar', 'التفسير الميسر'),
    ('saadi', 'تفسير السعدي'),
    ('ibn_kathir_full', 'تفسير ابن كثير (الكامل)'),
  ];
  static const defaultTafsirSource = 'almukhtasar';

  /// Also accepts a direct `"سورة آية"` / `"سورة:آية"` reference (e.g.
  /// "البقرة 255") and resolves it to that single ayah instead of a text
  /// search, when the query matches a known surah name followed by a number.
  Future<List<QuranSearchResult>> search(String query, {String tafsirSource = defaultTafsirSource}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final refMatch = RegExp(r'^(.+?)\s*[:\s]\s*(\d+)$').firstMatch(trimmed);
    if (refMatch != null) {
      final surahQuery = normalizeArabicForSearch(refMatch.group(1)!.trim());
      final ayahNum = int.tryParse(refMatch.group(2)!);
      final surahEntry = quranSurahs.where((s) => normalizeArabicForSearch(s.name) == surahQuery).toList();
      if (surahEntry.isNotEmpty && ayahNum != null) {
        return _byReference(surahEntry.first.number, ayahNum, tafsirSource);
      }
    }

    return _byText(trimmed, tafsirSource);
  }

  static const _selectWithTafsir = '''
    SELECT q.surah, q.ayah, q.text_uthmani, q.page_number, q.juz_number, t.text AS tafsir
    FROM quran_ayat q
    LEFT JOIN tafsir_entries t ON t.surah = q.surah AND q.ayah BETWEEN t.ayah_from AND t.ayah_to AND t.source = ?
  ''';

  Future<List<QuranSearchResult>> _byReference(int surah, int ayah, String tafsirSource) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '$_selectWithTafsir WHERE q.surah = ? AND q.ayah = ? LIMIT 1',
      [tafsirSource, surah, ayah],
    );
    return rows.map(_toResult).toList();
  }

  Future<List<QuranSearchResult>> _byText(String query, String tafsirSource) async {
    final normalized = normalizeArabicForSearch(query);
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '$_selectWithTafsir WHERE q.text_normalized LIKE ? ORDER BY q.surah, q.ayah LIMIT 300',
      [tafsirSource, '%$normalized%'],
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
      tafsir: row['tafsir'] as String?,
    );
  }
}
