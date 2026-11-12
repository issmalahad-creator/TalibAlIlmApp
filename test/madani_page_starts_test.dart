import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/data/madani_page_starts.dart';
import 'package:talib_alilm_app/data/quran_surahs.dart';
import 'package:talib_alilm_app/db/database_helper.dart';

/// Page numbers = the 1421H King Fahd edition the reader draws, everywhere.
/// docs/quran/reports/PAGE_BOUNDARY_AUDIT.md.
void main() {
  test('604 page starts, strictly in muṣḥaf order, page 1 = al-Fātiḥa', () {
    expect(kMadaniPageStarts.length, 604);
    expect(kMadaniPageStarts.first, (1, 1));
    for (var i = 1; i < 604; i++) {
      final (ps, pa) = kMadaniPageStarts[i - 1];
      final (s, a) = kMadaniPageStarts[i];
      expect(s > ps || (s == ps && a > pa), isTrue, reason: 'page ${i + 1}');
      expect(a >= 1 && a <= quranSurahs[s - 1].ayahCount, isTrue, reason: 'page ${i + 1}');
    }
  });

  test('the 1421H pages where the old 1405H table was wrong', () {
    // Spot values checked against quran.com's edition lookup (mushaf=1).
    expect(kMadaniPageStarts[586 - 1], (80, 41)); // 1405H: (81, 1)
    expect(kMadaniPageStarts[121 - 1], (5, 78)); // 1405H: (5, 77)
    expect(kMadaniPageStarts[532 - 1], (55, 19)); // 1405H: (55, 17)
    expect(kMadaniPageStarts[600 - 1], (100, 6)); // 1405H: (100, 10)
    expect(kMadaniPageStarts[604 - 1], (112, 1));
  });

  group('v74 realignment of an existing install', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    test('quran_ayat pages and memorization units follow the drawn edition; progress stays put', () async {
      DatabaseHelper.databaseName = 'talib_pages_test.db';
      final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
      if (f.existsSync()) f.deleteSync();
      final db = await DatabaseHelper.instance.database;
      await db.delete('quran_ayat');
      await db.delete('memorization_units');
      await db.delete('memorization_progress');

      // An install imported with the old 1405H pages: 'Abasa whole on 585,
      // at-Takwir on 586.
      final batch = db.batch();
      for (var a = 1; a <= 42; a++) {
        batch.insert('quran_ayat', {'surah': 80, 'ayah': a, 'text_uthmani': 'x', 'text_normalized': 'x', 'juz_number': 30, 'page_number': 585});
      }
      for (var a = 1; a <= 29; a++) {
        batch.insert('quran_ayat', {'surah': 81, 'ayah': a, 'text_uthmani': 'x', 'text_normalized': 'x', 'juz_number': 30, 'page_number': 586});
      }
      batch.insert('memorization_units', {'id': 585, 'surah_start': 80, 'ayah_start': 1, 'surah_end': 80, 'ayah_end': 42, 'juz_number': 30});
      batch.insert('memorization_units', {'id': 586, 'surah_start': 81, 'ayah_start': 1, 'surah_end': 81, 'ayah_end': 29, 'juz_number': 30});
      batch.insert('memorization_progress', {'unit_id': 586, 'station': 2, 'next_review_date': '2026-11-13'});
      await batch.commit(noResult: true);

      await DatabaseHelper.realignPageNumbers(db);

      Future<int> page(int s, int a) async =>
          (await db.query('quran_ayat', columns: ['page_number'], where: 'surah = ? AND ayah = ?', whereArgs: [s, a])).single['page_number'] as int;
      expect(await page(80, 40), 585);
      expect(await page(80, 41), 586);
      expect(await page(81, 29), 586);
      final u586 = (await db.query('memorization_units', where: 'id = 586')).single;
      expect([u586['surah_start'], u586['ayah_start'], u586['surah_end'], u586['ayah_end']], [80, 41, 81, 29]);
      final u585 = (await db.query('memorization_units', where: 'id = 585')).single;
      expect([u585['ayah_start'], u585['ayah_end']], [1, 40]);
      expect((await db.query('memorization_progress')).single['unit_id'], 586);
    });
  });
}
