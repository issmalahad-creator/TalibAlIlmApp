import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_sync.dart';
import 'package:talib_alilm_app/repositories/recitation_repository.dart';
import 'package:talib_alilm_app/utils/recitation_alignment.dart';

/// ت3: the recitation page is the reader's Madinah-muṣḥaf page, read from
/// the real bundled layout — not the older Tanzil page numbering.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_recitation_identity_test.db';
    final f = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();
    final raw = gzip.decode(File('assets/mushaf/mushaf_layout.json.gz').readAsBytesSync());
    final res = await MushafLayoutSync().ingestFromJson(jsonDecode(utf8.decode(raw)) as Map<String, dynamic>);
    expect(res.validation?.ok, isTrue);
  });

  test('page 300 is al-Kahf 54–61, with no waqf sign as a word', () async {
    final words = await RecitationRepository().pageWords(300);
    expect(words.first.surah, 18);
    expect(words.first.ayah, 54);
    expect(words.last.ayah, 61);
    expect(words.every((w) => w.text.replaceAll(RegExp('[ۖ-ۭ]'), '').isNotEmpty), isTrue);
    expect(words.map((w) => w.line).toSet().length, 15);
  });

  test('page 2 opens with «الٓمٓ» and drops the two «ۛ» of ayah 2', () async {
    final words = await RecitationRepository().pageWords(2);
    expect(words.first.text, 'الٓمٓ');
    final ayah2 = words.where((w) => w.surah == 2 && w.ayah == 2).toList();
    expect(ayah2.length, 7); // ذلك الكتاب لا ريب فيه هدى للمتقين
  });

  test('the standalone «وَ» of the layout is recited with its word', () async {
    final words = await RecitationRepository().pageWords(2);
    expect(words.any((w) => w.text == 'وَ'), isFalse);
    expect(words.any((w) => w.text.startsWith('وَيُقِيمُونَ')), isTrue);
  });

  test('what is saved is exactly what was shown; unreached words are not mistakes', () async {
    final repo = RecitationRepository();
    final words = await repo.pageWords(2);
    final statuses = List<RecitationWordStatus?>.filled(words.length, null);
    for (var k = 0; k < 8; k++) {
      statuses[k] = RecitationWordStatus.correct; // ayat 1–2
    }
    statuses[6] = RecitationWordStatus.missing; // «هدى»
    final result = await repo.recordPageResult(words: words, statuses: statuses, said: List.filled(words.length, null));
    expect(result.ayat.map((a) => a.ayah), [1, 2]);
    final db = await DatabaseHelper.instance.database;
    final mistakes = await db.query('recitation_mistakes');
    expect(mistakes.length, 1);
    expect(mistakes.single['ayah'], 2);
    expect(mistakes.single['status'], 'missing');
    expect(mistakes.single['word_index'], words[6].wordIndex);
  });
}
