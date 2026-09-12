import '../data/quran_surahs.dart';
import '../db/database_helper.dart';
import '../utils/arabic_normalize.dart';
import '../utils/fuzzy_match.dart' as fuzzy;

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

  /// Available tafsir/translation sources (slug, display label, language
  /// code) — see QURAN_COMPANION_ROADMAP.md's "التفسير" section for the
  /// original 4 Arabic editions, and quirky-gliding-shell.md's "مكتبة
  /// التفسير/الترجمة متعددة اللغات" plan for the English/Amharic additions
  /// (batch 1 of a wider multi-language library, QuranEnc.com source).
  /// Default is the concise modern mukhtasar, not the full Ibn Kathir text,
  /// since search results are meant to be scannable.
  static const tafsirSources = [
    ('almukhtasar', 'التفسير المختصر', 'ar'),
    ('muyassar', 'التفسير الميسر', 'ar'),
    ('saadi', 'تفسير السعدي', 'ar'),
    ('ibn_kathir_full', 'تفسير ابن كثير (الكامل)', 'ar'),
    ('ibn_ashur', 'التحرير والتنوير (ابن عاشور)', 'ar'),
    ('english_rwwad', 'Rowwad Translation Center', 'en'),
    ('amharic_sadiq', 'መሐመድ ሳዲቅ', 'am'),
    ('french_rashid', 'Rachid Maach', 'fr'),
    ('turkish_rwwad', 'Rowwad Translation Center', 'tr'),
    ('indonesian_sabiq', 'Sabiq Company', 'id'),
    ('urdu_junagarhi', 'محمد جوناگڑھی', 'ur'),
    ('bengali_zakaria', 'ড. আবু বকর মুহাম্মাদ যাকারিয়া', 'bn'),
    // Batch 3 — as many more QuranEnc languages as verified real (every
    // key curl-checked live before being added; see TODO.md Phase 61).
    ('spanish_garcia', 'Muhammad Isa García', 'es'),
    ('portuguese_nasr', 'Helmi Nasr', 'pt'),
    ('greek_rwwad', 'Rowwad Translation Center', 'el'),
    ('german_rwwad', 'Rowwad Translation Center', 'de'),
    ('italian_rwwad', 'Rowwad Translation Center', 'it'),
    ('bulgarian_translation', 'фондация "99 имена на Аллах"', 'bg'),
    ('romanian_project', 'Islam4RO Project', 'ro'),
    ('dutch_center', 'Dutch Islamic Center', 'nl'),
    ('swedish_rwwad', 'Rowwad Translation Center', 'sv'),
    ('azeri_musayev', 'Musayev', 'az'),
    ('georgian_rwwad', 'Rowwad Translation Center', 'ka'),
    ('macedonian_group', 'Translation Group', 'mk'),
    // 2026-09-12: swapped for 'albanian_nahi' (Hasan Efendi Nahi) — the
    // old 'albanian_rwwad' key carries zero footnotes; this one has real
    // ones (12 sampled across 3 sūrahs).
    ('albanian_nahi', 'Hasan Efendi Nahi', 'sq'),
    ('bosnian_rwwad', 'Rowwad Translation Center', 'bs'),
    ('russian_rwwad', 'Rowwad Translation Center', 'ru'),
    ('belarusian_krivtsov', 'Krivtsov', 'be'),
    ('serbian_rwwad', 'Rowwad Translation Center', 'sr'),
    ('croatian_rwwad', 'Rowwad Translation Center', 'hr'),
    ('lithuanian_rwwad', 'Rowwad Translation Center', 'lt'),
    ('ukrainian_yakubovych', 'Yakubovych', 'uk'),
    ('kazakh_altai', 'Altai', 'kk'),
    // 2026-09-12: swapped for 'uzbek_mansour' — the old 'uzbek_rwwad' key
    // carries zero footnotes; this one has 527 real ones across the Quran.
    ('uzbek_mansour', 'Mansour', 'uz'),
    ('tajik_arifi', 'Arifi', 'tg'),
    ('kyrgyz_hakimov', 'Hakimov', 'ky'),
    ('circassian_rwwad', 'Rowwad Translation Center', 'ady'),
    ('tagalog_rwwad', 'Rowwad Translation Center', 'tl'),
    ('bisayan_rwwad', 'Rowwad Translation Center', 'ceb'),
    ('iranun_sarro', 'Sarro', 'iru'),
    ('maguindanao_rwwad', 'Rowwad Translation Center', 'mdh'),
    ('malay_basumayyah', 'Abdullah Basumayyah', 'ms'),
    // 2026-08-21: re-enabled alongside quran_import_service.dart's matching list.
    ('chinese_suliman', 'Suliman', 'zh'),
    ('uyghur_saleh', 'Saleh', 'ug'),
    ('japanese_saeedsato', 'Saeed Sato', 'ja'),
    // 2026-09-12: swapped for 'somali_yacob' (Abdullah Hasan Yaqoub) — the
    // current live quranenc.com Somali edition, which carries real
    // footnotes; the old 'somali_abduh' key has none.
    ('somali_yacob', 'Abdullah Hasan Yaqoub', 'so'),
    ('hindi_omari', 'Azizul Haq Al-Omari', 'hi'),
    ('luganda_foundation', 'African Institution for Development', 'lg'),
    // 2026-09-12: Ismail is in Ethiopia and asked specifically about
    // Oromo — verified live on quranenc.com, complete + real footnotes.
    ('oromo_ababor', 'Ghali Ababor', 'om'),
  ];
  static const defaultTafsirSource = 'almukhtasar';

  /// Display name per language code, for the language-picker step —
  /// each language's own name in its own script, not translated.
  static const languageLabels = {
    'ar': 'العربية',
    'en': 'English',
    'am': 'አማርኛ',
    'fr': 'Français',
    'tr': 'Türkçe',
    'id': 'Bahasa Indonesia',
    'ur': 'اردو',
    'bn': 'বাংলা',
    'es': 'Español',
    'pt': 'Português',
    'el': 'Ελληνικά',
    'de': 'Deutsch',
    'it': 'Italiano',
    'bg': 'Български',
    'ro': 'Română',
    'nl': 'Nederlands',
    'sv': 'Svenska',
    'az': 'Azərbaycan',
    'ka': 'ქართული',
    'mk': 'Македонски',
    'sq': 'Shqip',
    'bs': 'Bosanski',
    'ru': 'Русский',
    'be': 'Беларуская',
    'sr': 'Српски',
    'hr': 'Hrvatski',
    'lt': 'Lietuvių',
    'uk': 'Українська',
    'kk': 'Қазақша',
    'uz': 'Oʻzbekcha',
    'tg': 'Тоҷикӣ',
    'ky': 'Кыргызча',
    'ady': 'Адыгэбзэ',
    'tl': 'Tagalog',
    'ceb': 'Cebuano',
    'iru': 'Iranun',
    'mdh': 'Maguindanaon',
    'ms': 'Bahasa Melayu',
    'zh': '中文',
    'ug': 'ئۇيغۇرچە',
    'ja': '日本語',
    'so': 'Soomaali',
    'hi': 'हिन्दी',
    'lg': 'Luganda',
    'om': 'Afaan Oromoo',
  };

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

  static const _selectByTranslationText = '''
    SELECT t.surah, t.ayah_from AS ayah, q.text_uthmani, q.page_number, q.juz_number, t.text AS tafsir
    FROM tafsir_entries t
    JOIN quran_ayat q ON q.surah = t.surah AND q.ayah = t.ayah_from
    WHERE t.source = ?
  ''';

  /// Real multi-language search ("تعدد اللغه" — Ismail, 2026-08-18): rather
  /// than inventing translation content, searches the ACTUAL translation
  /// text already stored per-language in `tafsir_entries` (the same
  /// QuranEnc-sourced rows `tafsirSources` already lists — e.g.
  /// 'english_rwwad'). A student typing in English searches English
  /// translation text directly, not the Arabic Quran text. `source` must be
  /// a non-Arabic entry from `tafsirSources` (e.g. 'english_rwwad',
  /// 'french_rashid').
  Future<List<QuranSearchResult>> searchTranslationText(String query, String source) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '$_selectByTranslationText AND t.text LIKE ? ORDER BY t.surah, t.ayah_from LIMIT 300',
      [source, '%$trimmed%'],
    );
    return rows.map(_toResult).toList();
  }

  /// Same "closest real thing, not nothing" fallback as `closestMatch()`,
  /// applied to a translation-text source instead of the Arabic Quran text
  /// — identical algorithm (word-overlap + Damerau-Levenshtein fuzzy
  /// matching via `fuzzy.isFuzzyMatch`), just a different content column,
  /// which is exactly why the matching logic lives in a shared,
  /// script-agnostic utility rather than being duplicated per language.
  Future<QuranSearchResult?> closestTranslationMatch(String query, String source) async {
    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    if (queryWords.isEmpty) return null;

    final db = await DatabaseHelper.instance.database;
    final seen = <String>{};
    final candidates = <Map<String, Object?>>[];
    for (final word in queryWords.take(5)) {
      final rows = await db.rawQuery(
        '$_selectByTranslationText AND t.text LIKE ? LIMIT 100',
        [source, '%$word%'],
      );
      for (final row in rows) {
        final key = '${row['surah']}:${row['ayah']}';
        if (seen.add(key)) candidates.add(row);
      }
    }
    if (candidates.isEmpty) return null;

    Map<String, Object?>? best;
    var bestScore = 0.0;
    for (final row in candidates) {
      final textWords = (row['tafsir'] as String).toLowerCase().split(RegExp(r'\s+')).toSet();
      final matchedCount = queryWords.where((qw) => textWords.any((tw) => tw.contains(qw) || qw.contains(tw) || fuzzy.isFuzzyMatch(tw, qw))).length;
      final score = matchedCount / queryWords.length;
      if (score > bestScore) {
        bestScore = score;
        best = row;
      }
    }
    if (best == null || bestScore < 0.4) return null;
    return _toResult(best);
  }

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

  /// "تخيل انه بحث عام... مثل اليوتيوب" (Ismail, 2026-08-18): `search()`
  /// only does exact substring matching (`LIKE '%...%'`) — a single typo or
  /// slightly different phrasing returns nothing at all. This is the
  /// "closest real thing" fallback: pulls candidate ayat containing at
  /// least one significant query word (bounded — at most 5 words × 100
  /// rows), then ranks them by how many query words actually appear in
  /// each candidate (word-level, fuzzy-tolerant via `fuzzy.isFuzzyMatch` so
  /// small typos on either side still count). Requires at least 40% of the
  /// query's words to match before returning anything — an honest
  /// "couldn't find anything close" (null) beats a confident-looking wrong
  /// guess. Pure edit-distance arithmetic, not language-specific — works
  /// the same on any script — but only ever searches this table's Arabic
  /// Quran text, so a query in another script simply won't have matching
  /// words to score against.
  Future<QuranSearchResult?> closestMatch(String query, {String tafsirSource = defaultTafsirSource}) async {
    final normalizedQuery = normalizeArabicForSearch(query);
    final queryWords = normalizedQuery.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    if (queryWords.isEmpty) return null;

    final db = await DatabaseHelper.instance.database;
    final seen = <String>{};
    final candidates = <Map<String, Object?>>[];
    for (final word in queryWords.take(5)) {
      final rows = await db.rawQuery(
        '$_selectWithTafsir WHERE q.text_normalized LIKE ? LIMIT 100',
        [tafsirSource, '%$word%'],
      );
      for (final row in rows) {
        final key = '${row['surah']}:${row['ayah']}';
        if (seen.add(key)) candidates.add(row);
      }
    }
    if (candidates.isEmpty) return null;

    Map<String, Object?>? best;
    var bestScore = 0.0;
    for (final row in candidates) {
      final ayahWords = normalizeArabicForSearch(row['text_uthmani'] as String).split(RegExp(r'\s+')).toSet();
      final matchedCount = queryWords.where((qw) => ayahWords.any((aw) => aw.contains(qw) || qw.contains(aw) || fuzzy.isFuzzyMatch(aw, qw))).length;
      final score = matchedCount / queryWords.length;
      if (score > bestScore) {
        bestScore = score;
        best = row;
      }
    }
    if (best == null || bestScore < 0.4) return null;
    return _toResult(best);
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
