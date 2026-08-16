import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../data/practical_lessons_seed.dart';
import '../db/database_helper.dart';
import '../utils/arabic_normalize.dart';

/// One-time import of the bundled Tanzil Uthmani text + Juz/Page boundaries
/// (assets/quran/) into `quran_ayat` — Phase 0 of QURAN_COMPANION_ROADMAP.md.
/// Both files are verbatim Tanzil Project data (CC-BY 3.0); their own
/// embedded copyright headers are the source of truth for attribution, not
/// duplicated here. Safe to call on every app start — a no-op once the
/// table already has rows.
class QuranImportService {
  Future<void> importIfNeeded() async {
    final db = await DatabaseHelper.instance.database;

    final existingAyat = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM quran_ayat'));
    if (existingAyat == null || existingAyat == 0) {
      final ayat = await _parseAyat();
      final boundaries = await _parseBoundaries();

      // Single pass, in canonical Mushaf order: insert each ayah AND track
      // the first/last (surah, ayah) seen per page — that directly gives
      // memorization_units' ranges without a second, trickier tuple-min/max
      // SQL query (page boundaries don't always align to surah boundaries).
      final pageFirst = <int, (int, int)>{};
      final pageLast = <int, (int, int)>{};
      final pageJuz = <int, int>{};

      final batch = db.batch();
      for (final a in ayat) {
        final juz = _boundaryIndexFor(boundaries.juz, a.surah, a.ayah);
        final page = _boundaryIndexFor(boundaries.page, a.surah, a.ayah);
        batch.insert('quran_ayat', {
          'surah': a.surah,
          'ayah': a.ayah,
          'text_uthmani': a.text,
          'text_normalized': normalizeArabicForSearch(a.text),
          'juz_number': juz,
          'page_number': page,
        });
        pageFirst.putIfAbsent(page, () => (a.surah, a.ayah));
        pageLast[page] = (a.surah, a.ayah);
        pageJuz.putIfAbsent(page, () => juz);
      }
      await batch.commit(noResult: true);
      await _generateMemorizationUnits(db, pageFirst, pageLast, pageJuz);
    }

    // Self-healing check (Ismail's report 2026-08-16: "حدد ما حفظته"/
    // "ابدأ الحفظ" opening to a genuinely empty page — not an error, not a
    // crash, just zero rows). `_generateMemorizationUnits` above only runs
    // inside the `quran_ayat`-empty branch, so any device that somehow
    // ended up with `quran_ayat` populated but `memorization_units` empty
    // (the exact combination that produces this symptom) would never get
    // it backfilled — this recomputes it independently, straight from the
    // already-imported `quran_ayat` rows (which already carry the needed
    // `page_number`/`juz_number` columns), so it self-heals regardless of
    // how the table ended up empty. Cheap no-op on every normal run.
    final existingUnits = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM memorization_units'));
    if (existingUnits == null || existingUnits == 0) {
      await _regenerateMemorizationUnitsFromAyat(db);
    }

    final existingTafsir = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tafsir_entries'));
    if (existingTafsir == null || existingTafsir == 0) {
      for (final edition in _tafsirEditions) {
        await _importTafsirEdition(db, edition);
      }
    }

    final existingLessons = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM practical_lessons'));
    if (existingLessons == null || existingLessons == 0) {
      final batch = db.batch();
      for (final l in practicalLessonsSeed) {
        batch.insert('practical_lessons', {
          'surah': l.surah,
          'ayah_from': l.ayahFrom,
          'ayah_to': l.ayahTo,
          'lesson_text': l.lessonText,
          'value_tag': l.valueTag,
        });
      }
      await batch.commit(noResult: true);
    }

    final existingHadiths = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM nawawi_hadiths'));
    if (existingHadiths == null || existingHadiths == 0) {
      await _importNawawiHadiths(db);
    }

    final existingWasitiyyah = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM wasitiyyah_sections'));
    if (existingWasitiyyah == null || existingWasitiyyah == 0) {
      await _importWasitiyyah(db);
    }

    final existingZad = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM zad_almaad_chapters'));
    if (existingZad == null || existingZad == 0) {
      await _importZadAlMaad(db);
    }

    final existingMadarij = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM madarij_sections'));
    if (existingMadarij == null || existingMadarij == 0) {
      await _importMadarij(db);
    }

    final existingAdhkar = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM adhkar_categories'));
    if (existingAdhkar == null || existingAdhkar == 0) {
      await _importAdhkar(db);
    }
  }

  /// Hisn al-Muslim (Sa'id Al-Qahtani) — Phase 5هـ of
  /// QURAN_COMPANION_ROADMAP.md. Source: `rn0x/hisn_almuslim_json` on
  /// GitHub, fetched as raw JSON (not summarized) and verified against the
  /// well-known text (restroom dua's Bukhari/Muslim citation, the Ayat
  /// al-Kursi/Mu'awwidhat opening of the morning adhkar). 134 chapters,
  /// 298 duas, imported whole — `is_daily_core` (computed at bundling time
  /// in the scratchpad transform script, not here) flags the routine
  /// everyday-life chapters pinned to the top of the adhkar screen.
  Future<void> _importAdhkar(Database db) async {
    final raw = await rootBundle.loadString('assets/adhkar/hisn_almuslim.json');
    final categories = jsonDecode(raw) as List<dynamic>;
    final batch = db.batch();
    for (final entry in categories) {
      final map = entry as Map<String, dynamic>;
      final categoryId = await db.insert('adhkar_categories', {
        'category_order': map['order'] as int,
        'title': map['title'] as String,
        'is_daily_core': (map['is_daily_core'] as bool) ? 1 : 0,
      });
      final items = map['items'] as List<dynamic>;
      for (var i = 0; i < items.length; i++) {
        final item = items[i] as Map<String, dynamic>;
        batch.insert('adhkar_items', {
          'category_id': categoryId,
          'item_order': i + 1,
          'text': item['text'] as String,
          'footnote': item['footnote'] as String?,
          'repeat_count': item['repeat'] as int,
        });
      }
    }
    await batch.commit(noResult: true);
  }

  /// Madarij As-Salikin Part 1 — see the v12 migration's doc comment for
  /// scope (advanced tier only, part 1 of typically 3).
  Future<void> _importMadarij(Database db) async {
    final raw = await rootBundle.loadString('assets/aqeedah/madarij_part1.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final batch = db.batch();
    for (var i = 0; i < list.length; i++) {
      final entry = list[i] as Map<String, dynamic>;
      batch.insert('madarij_sections', {
        'part': 1,
        'section_order': i + 1,
        'section_title': entry['title'] as String,
        'text_excerpt': entry['text'] as String,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Zad al-Ma'ad Volume 1 (Seerah introduction) — see the v11 migration's
  /// doc comment for scope (volume 1 of 5 only, for now).
  Future<void> _importZadAlMaad(Database db) async {
    final raw = await rootBundle.loadString('assets/fiqh_seerah/zad_almaad_vol1.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final batch = db.batch();
    for (var i = 0; i < list.length; i++) {
      final entry = list[i] as Map<String, dynamic>;
      batch.insert('zad_almaad_chapters', {
        'volume': 1,
        'chapter_order': i + 1,
        'chapter_title': entry['title'] as String,
        'chapter_text': entry['text'] as String,
        'has_uthaymeen_commentary': 0,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Al-Aqidah Al-Wasitiyyah, 82 paragraph sections — source: ar.wikisource.org,
  /// fetched as raw wikitext (not summarized), MediaWiki markup already
  /// stripped ({{ص}} -> ﷺ, header template and category link removed)
  /// before being saved to the bundled asset.
  Future<void> _importWasitiyyah(Database db) async {
    final raw = await rootBundle.loadString('assets/aqeedah/wasitiyyah.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final batch = db.batch();
    for (final entry in list) {
      final map = entry as Map<String, dynamic>;
      batch.insert('wasitiyyah_sections', {
        'id': map['order'] as int,
        'section_order': map['order'] as int,
        'original_text': map['text'] as String,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Al-Arba'in Al-Nawawiyyah, 42 hadith with commentary — source:
  /// osamayy/40-hadith-nawawi-db (GitHub), verified real (hadith 1 checked
  /// against well-known "إنما الأعمال بالنيات"). List order in the JSON is
  /// the canonical hadith order, so index+1 = hadith number.
  Future<void> _importNawawiHadiths(Database db) async {
    final raw = await rootBundle.loadString('assets/hadith/nawawi40.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final batch = db.batch();
    for (var i = 0; i < list.length; i++) {
      final entry = list[i] as Map<String, dynamic>;
      batch.insert('nawawi_hadiths', {
        'id': i + 1,
        'hadith_text': entry['hadith'] as String,
        'commentary_text': entry['description'] as String?,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Four Arabic tafsir editions, all sourced the same way (spa5k/tafsir_api
  /// via jsDelivr CDN, bulk-fetched to a gzip-compressed JSONL asset — see
  /// QURAN_COMPANION_ROADMAP.md's "التفسير" section for the full story of
  /// why these four rather than the three originally-planned mukhtasars, and
  /// why the full Ibn Kathir text is included alongside three actual
  /// mukhtasars). Each becomes its own `source` value in `tafsir_entries`,
  /// so a single ayah can carry all four for the in-app source switcher.
  static const _tafsirEditions = [
    ('assets/quran/tafsir-ibn-kathir-full.jsonl.gz', 'ibn_kathir_full'),
    ('assets/quran/tafsir-almukhtasar.jsonl.gz', 'almukhtasar'),
    ('assets/quran/tafsir-muyassar.jsonl.gz', 'muyassar'),
    ('assets/quran/tafsir-saadi.jsonl.gz', 'saadi'),
  ];

  Future<void> _importTafsirEdition(Database db, (String, String) edition) async {
    final (assetPath, sourceKey) = edition;
    final byteData = await rootBundle.load(assetPath);
    final compressed = byteData.buffer.asUint8List();
    final decompressed = gzip.decode(compressed);
    final jsonlText = utf8.decode(decompressed);

    final batch = db.batch();
    for (final line in const LineSplitter().convert(jsonlText)) {
      if (line.trim().isEmpty) continue;
      final obj = jsonDecode(line) as Map<String, dynamic>;
      batch.insert('tafsir_entries', {
        'surah': obj['surah'] as int,
        'ayah_from': obj['ayah'] as int,
        'ayah_to': obj['ayah'] as int,
        'source': sourceKey,
        'text': obj['text'] as String,
        // Not extracted for any edition yet — deliberately left null rather
        // than guessed via an unvalidated text-search heuristic.
        'asbab_nuzul_excerpt': null,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Phase 1 of QURAN_COMPANION_ROADMAP.md — one `memorization_units` row
  /// per Mushaf page (604 total), the scheduling unit for the review engine
  /// (roadmap section 4). `memorization_progress` rows are NOT created here
  /// — they're created lazily (status 'not_started' is the implicit default
  /// for any unit with no row yet) so this stays a pure reference table.
  Future<void> _generateMemorizationUnits(
    Database db,
    Map<int, (int, int)> pageFirst,
    Map<int, (int, int)> pageLast,
    Map<int, int> pageJuz,
  ) async {
    final batch = db.batch();
    for (final page in pageFirst.keys) {
      final (surahStart, ayahStart) = pageFirst[page]!;
      final (surahEnd, ayahEnd) = pageLast[page]!;
      batch.insert('memorization_units', {
        'id': page,
        'surah_start': surahStart,
        'ayah_start': ayahStart,
        'surah_end': surahEnd,
        'ayah_end': ayahEnd,
        'juz_number': pageJuz[page],
      });
    }
    await batch.commit(noResult: true);
  }

  /// Same algorithm as `_generateMemorizationUnits`, sourced from the
  /// already-imported `quran_ayat` rows instead of a fresh text parse —
  /// the self-healing fallback described above. `quran_ayat` is read in
  /// canonical Mushaf order (surah ascending, ayah ascending — surah
  /// numbers themselves already run in Mushaf order, so this needs no
  /// separate boundary re-parse).
  Future<void> _regenerateMemorizationUnitsFromAyat(Database db) async {
    final rows = await db.query('quran_ayat', columns: ['surah', 'ayah', 'page_number', 'juz_number'], orderBy: 'surah ASC, ayah ASC');
    if (rows.isEmpty) return;

    final pageFirst = <int, (int, int)>{};
    final pageLast = <int, (int, int)>{};
    final pageJuz = <int, int>{};
    for (final row in rows) {
      final page = row['page_number'] as int;
      final surah = row['surah'] as int;
      final ayah = row['ayah'] as int;
      pageFirst.putIfAbsent(page, () => (surah, ayah));
      pageLast[page] = (surah, ayah);
      pageJuz.putIfAbsent(page, () => row['juz_number'] as int);
    }
    await _generateMemorizationUnits(db, pageFirst, pageLast, pageJuz);
  }

  Future<List<_Ayah>> _parseAyat() async {
    final raw = await rootBundle.loadString('assets/quran/quran-uthmani.txt');
    final result = <_Ayah>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split('|');
      if (parts.length != 3) continue;
      final surah = int.tryParse(parts[0]);
      final ayah = int.tryParse(parts[1]);
      if (surah == null || ayah == null) continue;
      result.add(_Ayah(surah, ayah, parts[2]));
    }
    return result;
  }

  /// `quran-data.js` isn't JSON (it's a JS source file with comments), but
  /// the Juz/Page arrays are simple `[sura, aya]` pairs — regex-extractable
  /// without a JS parser. See the file's own header for its CC-BY 3.0 terms.
  Future<_Boundaries> _parseBoundaries() async {
    final raw = await rootBundle.loadString('assets/quran/quran-data.js');
    final juzBlock = _extractBlock(raw, 'QuranData.Juz');
    final pageBlock = _extractBlock(raw, 'QuranData.Page');
    return _Boundaries(_extractPairs(juzBlock), _extractPairs(pageBlock));
  }

  String _extractBlock(String raw, String varName) {
    final start = raw.indexOf('$varName = [');
    final end = raw.indexOf('];', start);
    return raw.substring(start, end);
  }

  List<(int, int)> _extractPairs(String block) {
    final pairRegex = RegExp(r'\[\s*(\d+)\s*,\s*(\d+)\s*\]');
    return pairRegex
        .allMatches(block)
        .map((m) => (int.parse(m.group(1)!), int.parse(m.group(2)!)))
        .toList();
  }

  /// Boundaries are 1-indexed lists of (surah, ayah) start positions in
  /// Mushaf order. Returns the 1-based index of the last boundary at or
  /// before (surah, ayah) — i.e. which Juz/Page this ayah falls in.
  int _boundaryIndexFor(List<(int, int)> boundaries, int surah, int ayah) {
    var result = 1;
    for (var i = 0; i < boundaries.length; i++) {
      final (bSurah, bAyah) = boundaries[i];
      final isAtOrBefore = bSurah < surah || (bSurah == surah && bAyah <= ayah);
      if (isAtOrBefore) result = i + 1;
    }
    return result;
  }
}

class _Ayah {
  final int surah;
  final int ayah;
  final String text;
  _Ayah(this.surah, this.ayah, this.text);
}

class _Boundaries {
  final List<(int, int)> juz;
  final List<(int, int)> page;
  _Boundaries(this.juz, this.page);
}
