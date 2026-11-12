import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/quran_search_repository.dart';
import 'package:talib_alilm_app/utils/arabic_normalize.dart';

/// Search counts over the whole muṣḥaf, and «بحث مطابق» (whole words).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final repo = QuranSearchRepository();

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_search_counts_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();
    final db = await DatabaseHelper.instance.database;
    await db.delete('quran_ayat');
    final batch = db.batch();
    for (final line in File('assets/quran/quran-uthmani.txt').readAsLinesSync()) {
      final parts = line.split('|');
      if (parts.length != 3 || line.startsWith('#')) continue;
      batch.insert('quran_ayat', {
        'surah': int.parse(parts[0]), 'ayah': int.parse(parts[1]), 'text_uthmani': parts[2],
        'text_normalized': normalizeArabicForSearch(parts[2]), 'page_number': 1, 'juz_number': 1, 'hizb_number': 1,
      });
    }
    await batch.commit(noResult: true);
  });

  test('a word that occurs everywhere: counts cover the whole muṣḥaf, not the first 300 rows', () async {
    final c = await repo.textCounts('الله');
    expect(c.ayat, greaterThan(300));
    expect(c.occurrences, greaterThanOrEqualTo(c.ayat));
    expect(c.surahs, greaterThan(80));
    expect((await repo.search('الله')).length, 300); // the list itself stays capped
  });

  test('«بحث مطابق»: whole words only', () async {
    final loose = await repo.textCounts('علم');
    final exact = await repo.textCounts('علم', exact: true);
    expect(exact.ayat, lessThan(loose.ayat), reason: 'يعلمون/العلم/علمه no longer count');
    expect(exact.ayat, greaterThan(0));
    final hits = await repo.search('علم', exact: true);
    expect(hits.length, exact.ayat.clamp(0, 300));
  });

  test('a surah reference still resolves to one ayah', () async {
    final r = await repo.search('البقرة 255');
    expect(r.single.ayah, 255);
  });
}
