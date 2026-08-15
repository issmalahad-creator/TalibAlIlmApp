import '../db/database_helper.dart';
import '../models/daily_task.dart';

class DailyTaskRepository {
  Future<int> add(DailyTask task) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('daily_tasks', task.toMap()..remove('id'));
  }

  Future<void> update(DailyTask task) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('daily_tasks', task.toMap()..remove('id'), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> setCompleted(int id, bool completed) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('daily_tasks', {'completed': completed ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('daily_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DailyTask>> forDate(String date) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('daily_tasks',
        where: 'date = ?', whereArgs: [date], orderBy: 'completed ASC, time ASC, id ASC');
    return rows.map((r) => DailyTask.fromMap(r)).toList();
  }

  /// All tasks from [fromDate] onward (today and future) — used for the
  /// full tasks list screen.
  Future<List<DailyTask>> upcoming(String fromDate) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('daily_tasks',
        where: 'date >= ?', whereArgs: [fromDate], orderBy: 'date ASC, completed ASC, time ASC, id ASC');
    return rows.map((r) => DailyTask.fromMap(r)).toList();
  }
}
