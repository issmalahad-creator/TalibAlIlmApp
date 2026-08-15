import '../db/database_helper.dart';
import '../models/activity_entry.dart';

class ActivityRepository {
  Future<int> add(ActivityEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('activities', entry.toMap()..remove('id'));
  }

  Future<void> update(ActivityEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('activities', entry.toMap()..remove('id'), where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ActivityEntry>> forMonth(String month) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'activities',
      where: 'date LIKE ?',
      whereArgs: ['$month%'],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map((r) => ActivityEntry.fromMap(r)).toList();
  }

  Future<List<ActivityEntry>> byCategoryForMonth(
      ActivityCategory category, String month) async {
    final all = await forMonth(month);
    return all.where((a) => a.category == category).toList();
  }
}
