import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';

/// An install that imported the old (scrambled) chapter is repaired in place
/// by the v72 sync — same rows, same ids, corrected notes + sessions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('syncAdhkarMorningEvening repairs an existing chapter in place', () async {
    DatabaseHelper.databaseName = 'adhkar_migration_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();
    final db = await DatabaseHelper.instance.database;

    final catId = await db.insert('adhkar_categories', {'category_order': 29, 'title': DatabaseHelper.adhkarMorningEveningTitle, 'is_daily_core': 1});
    final chapters = jsonDecode(File('assets/adhkar/hisn_almuslim.json').readAsStringSync()) as List<dynamic>;
    final items = (chapters.cast<Map<String, dynamic>>().firstWhere((c) => c['title'] == DatabaseHelper.adhkarMorningEveningTitle)['items'] as List<dynamic>);
    final ids = <int>[];
    for (var i = 0; i < items.length; i++) {
      // the old import: right text, wrong note, no session columns
      ids.add(await db.insert('adhkar_items', {'category_id': catId, 'item_order': i + 1, 'text': 'old', 'footnote': 'wrong', 'repeat_count': 1}));
    }

    await DatabaseHelper.syncAdhkarMorningEvening(db);

    final rows = await db.query('adhkar_items', where: 'category_id = ?', whereArgs: [catId], orderBy: 'item_order');
    expect(rows.map((r) => r['id']), ids);
    final hasbi = rows.firstWhere((r) => (r['text'] as String).startsWith('حسبي الله'));
    expect(hasbi['footnote'], contains('سبع مرات'));
    expect(hasbi['repeat_count'], 7);
    expect(rows.where((r) => r['time_of_day'] == 'evening').length, 1);
    expect(rows.where((r) => r['evening_text'] != null).length, 6);
  });
}
