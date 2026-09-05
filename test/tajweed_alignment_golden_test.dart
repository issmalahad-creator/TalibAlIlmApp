import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';

/// Phase G-t1 — hand-verified tajwīd spans for al-Fātiḥa 1:1–1:7 and
/// al-Baqara 2:1–2:5. Each expected `(word_index, rule_id)` was checked
/// letter-by-letter against a standard coloured tajwīd muṣḥaf (Dar
/// al-Ma'rifah). Guards the cpfair-offset → our-`word_index` remap from
/// silent drift.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_tajweed_golden_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await QuranCorpusSync().sync();
  });

  Future<Set<String>> pairs(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quran_tajweed',
        columns: ['data'],
        where: 'surah = ? AND ayah = ?',
        whereArgs: [surah, ayah]);
    final out = <String>{};
    for (final sp
        in (jsonDecode(rows.first['data'] as String) as List).cast<Map>()) {
      out.add('${sp['w']}:${sp['r']}');
    }
    return out;
  }

  test('al-Fātiḥa 1:1 — بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', () async {
    expect(await pairs(1, 1), {
      '2:hamzat_wasl', // ٱللَّهِ
      '3:hamzat_wasl', '3:lam_shamsiyyah', '3:madd_2', // ٱلرَّحْمَٰنِ (dagger alif)
      '4:hamzat_wasl', '4:lam_shamsiyyah', '4:madd_246', // ٱلرَّحِيمِ (stop madd)
    });
  });

  test('al-Fātiḥa 1:7 — ٱلضَّآلِّينَ carries the 6-count lāzim madd', () async {
    final s = await pairs(1, 7);
    expect(s, contains('10:madd_6')); // ٱلضَّآلِّينَ — آ before shaddah lām
    expect(s, contains('10:lam_shamsiyyah'));
    expect(s, contains('10:madd_246')); // final yā' at the stop
    expect(s, contains('2:hamzat_wasl')); // ٱلَّذِينَ
  });

  test('al-Ikhlāṣ 112:1 — qalqalah on the دٌ of أَحَدٌ', () async {
    expect(await pairs(112, 1), contains('4:qalqalah'));
  });

  test('al-Baqara 2:1 — الٓمٓ, madd lāzim on both lām and mīm', () async {
    expect(await pairs(2, 1), {'1:madd_6'});
  });

  test('al-Baqara 2:3 — ٱلصَّلَوٰةَ (silent wāw) + ghunnah in مِمَّا', () async {
    final s = await pairs(2, 3);
    expect(s, containsAll(<String>{
      '6:hamzat_wasl', '6:lam_shamsiyyah', '6:silent', '6:madd_2',
      '8:ghunnah', // مِمَّا
      '10:ikhfa', // يُنفِقُونَ — nūn before fā'
    }));
  });

  test('al-Baqara 2:4 — madd munfaṣil across بِمَآ ‖ أُنزِلَ + qalqalah قَبْلِ',
      () async {
    final s = await pairs(2, 4);
    expect(s, containsAll(<String>{
      '4:madd_munfasil', // بِمَآ then hamza of أُنزِلَ
      '5:ikhfa', // أُنزِلَ — nūn before zāy
      '11:qalqalah', // قَبْلِكَ — bā' sākinah
    }));
  });

  test('al-Baqara 2:5 — أُوْلَٰٓئِكَ: silent wāw + connected madd', () async {
    final s = await pairs(2, 5);
    expect(s, containsAll(<String>{
      '1:silent', '1:madd_muttasil',
      '4:idghaam_ghunnah', // هُدٗى مِّن
      '5:idghaam_no_ghunnah', // مِّن رَّبِّهِمْ
    }));
  });
}
