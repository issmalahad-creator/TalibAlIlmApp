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
