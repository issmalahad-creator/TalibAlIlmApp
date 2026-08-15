import '../db/database_helper.dart';
import '../models/hifz_student.dart';

class HifzStudentRepository {
  Future<List<HifzStudent>> all() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('hifz_students', orderBy: 'name ASC');
    return rows.map(HifzStudent.fromMap).toList();
  }

  Future<int> add(HifzStudent student) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('hifz_students', student.toMap());
  }

  Future<void> update(HifzStudent student) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('hifz_students', student.toMap(), where: 'id = ?', whereArgs: [student.id]);
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('hifz_student_fields', where: 'student_id = ?', whereArgs: [id]);
    await db.delete('hifz_students', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HifzStudentField>> fieldsFor(int studentId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('hifz_student_fields', where: 'student_id = ?', whereArgs: [studentId], orderBy: 'id ASC');
    return rows.map(HifzStudentField.fromMap).toList();
  }

  Future<int> addField(HifzStudentField field) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('hifz_student_fields', field.toMap());
  }

  Future<void> updateField(HifzStudentField field) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('hifz_student_fields', field.toMap(), where: 'id = ?', whereArgs: [field.id]);
  }

  Future<void> deleteField(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('hifz_student_fields', where: 'id = ?', whereArgs: [id]);
  }
}
