import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class TasbihRepository {
  Future<int> todayCount(String phraseKey) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('tasbih_log', where: 'log_date = ? AND phrase_key = ?', whereArgs: [todayDate(), phraseKey], limit: 1);
    return rows.isEmpty ? 0 : rows.first['count'] as int;
  }

  /// Increments today's count for [phraseKey] and returns the new total.
  Future<int> increment(String phraseKey) async {
    final db = await DatabaseHelper.instance.database;
    final current = await todayCount(phraseKey);
    final next = current + 1;
    await db.insert(
      'tasbih_log',
      {'log_date': todayDate(), 'phrase_key': phraseKey, 'count': next},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return next;
  }

  Future<void> reset(String phraseKey) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tasbih_log', where: 'log_date = ? AND phrase_key = ?', whereArgs: [todayDate(), phraseKey]);
  }

  /// Sum of every tap ever logged, across all phrases and all days — powers
  /// the tasbih milestone certificates (100_IDEAS_FOR_IMPROVEMENT.md #33:
  /// "التسبيح... لا شهادات له" — genuinely missing before this). Distinct
  /// from `todayCount`, which only reflects the currently-selected phrase's
  /// count reset each day.
  Future<int> lifetimeTotal() async {
    final db = await DatabaseHelper.instance.database;
    final result = Sqflite.firstIntValue(await db.rawQuery('SELECT COALESCE(SUM(count), 0) FROM tasbih_log'));
    return result ?? 0;
  }

  /// CUSTOMIZATION_IDEAS.md #1 — phrases the student added themselves,
  /// alongside the 6 built-in ones. `id` is included so the screen can
  /// build a stable `'custom_$id'` phraseKey distinct from the built-in
  /// string keys.
  Future<List<(int, String)>> customPhrases() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('custom_tasbih_phrases', orderBy: 'id');
    return rows.map((r) => (r['id'] as int, r['text'] as String)).toList();
  }

  Future<void> addCustomPhrase(String text) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('custom_tasbih_phrases', {'text': text, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<void> deleteCustomPhrase(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('custom_tasbih_phrases', where: 'id = ?', whereArgs: [id]);
  }
}
