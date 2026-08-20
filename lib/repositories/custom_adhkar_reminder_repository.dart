import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

class CustomAdhkarReminder {
  final int categoryId;
  final int hour;
  const CustomAdhkarReminder({required this.categoryId, required this.hour});
}

/// Per-category adhkar reminders beyond the 3 fixed morning/evening/sleep
/// ones — Ismail's 2026-08-17 request to add/remove a reminder for any
/// dhikr category, from either that category's own reading screen or the
/// notification settings screen.
class CustomAdhkarReminderRepository {
  Future<List<CustomAdhkarReminder>> all() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('custom_adhkar_reminders');
    return rows.map((r) => CustomAdhkarReminder(categoryId: r['category_id'] as int, hour: r['hour'] as int)).toList();
  }

  Future<int?> hourFor(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('custom_adhkar_reminders', where: 'category_id = ?', whereArgs: [categoryId], limit: 1);
    return rows.isEmpty ? null : rows.first['hour'] as int;
  }

  Future<void> add(int categoryId, int hour) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'custom_adhkar_reminders',
      {'category_id': categoryId, 'hour': hour},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('custom_adhkar_reminders', where: 'category_id = ?', whereArgs: [categoryId]);
  }
}
