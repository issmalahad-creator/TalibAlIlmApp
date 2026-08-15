import 'package:sqflite/sqflite.dart';

import '../data/wird_templates.dart';
import '../db/database_helper.dart';
import '../utils/month.dart';

/// "الورد اليومي" — QURAN_COMPANION_ROADMAP.md §4.17. Reads today's
/// completion for each item type straight from the *_progress table that
/// content already tracks elsewhere in the app — nothing here duplicates
/// state, it only assembles a single daily checklist view across pillars.
class WirdRepository {
  Future<String> selectedTemplateKey() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('wird_selection', where: 'id = 1', limit: 1);
    return rows.isEmpty ? wirdTemplates.first.key : rows.first['template_key'] as String;
  }

  Future<void> selectTemplate(String key) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('wird_selection', {'id': 1, 'template_key': key}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> istighfarToday() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('istighfar_log', where: 'log_date = ?', whereArgs: [todayDate()], limit: 1);
    return rows.isEmpty ? 0 : rows.first['count'] as int;
  }

  Future<int> incrementIstighfar() async {
    final db = await DatabaseHelper.instance.database;
    final next = await istighfarToday() + 1;
    await db.insert(
      'istighfar_log',
      {'log_date': todayDate(), 'count': next},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return next;
  }

  Future<bool> isQuranDoneToday() async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();
    final readRows = await db.query('quran_reading_progress', where: 'id = 1', limit: 1);
    if (readRows.isNotEmpty && readRows.first['last_read_date'] == today) return true;
    final memCount = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM memorization_progress WHERE memorized_date = ? OR last_review_date = ?",
      [today, today],
    ));
    return (memCount ?? 0) > 0;
  }

  /// Whether the merged morning+evening adhkar chapter was completed today
  /// — looks the category up by its book title since `AdhkarRepository`
  /// doesn't expose a fixed id for it.
  Future<bool> isAdhkarDoneToday() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('adhkar_categories', where: 'title = ?', whereArgs: ['أذكار الصباح والمساء'], limit: 1);
    if (rows.isEmpty) return false;
    final categoryId = rows.first['id'] as int;
    final done = await db.query(
      'adhkar_completion',
      where: 'category_id = ? AND completed_date = ?',
      whereArgs: [categoryId, todayDate()],
      limit: 1,
    );
    return done.isNotEmpty;
  }

  Future<bool> isReadingDoneToday((String table, String dateColumn) source) async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${source.$1} WHERE ${source.$2} = ?', [todayDate()]),
    );
    return (count ?? 0) > 0;
  }
}
