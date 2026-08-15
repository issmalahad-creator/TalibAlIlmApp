import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

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
    final existing = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM quran_ayat'));
    if (existing != null && existing > 0) return;

    final ayat = await _parseAyat();
    final boundaries = await _parseBoundaries();

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
