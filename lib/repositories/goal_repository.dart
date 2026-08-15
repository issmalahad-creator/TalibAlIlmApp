import '../db/database_helper.dart';
import '../models/goal.dart';

class GoalRepository {
  Future<int> add(Goal goal) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('goals', goal.toMap()..remove('id'));
  }

  Future<void> updateProgress(int id, int current) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('goals', {'current': current}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> update(int id, {required String title, required int target, required int current}) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('goals', {'title': title, 'target': target, 'current': current},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Goal>> forMonth(String month) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('goals', where: 'month = ?', whereArgs: [month], orderBy: 'id DESC');
    return rows.map((r) => Goal.fromMap(r)).toList();
  }
}
