import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/student_profile.dart';

class ProfileRepository {
  Future<StudentProfile> get() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('profile', where: 'id = 1');
    if (rows.isEmpty) return const StudentProfile();
    return StudentProfile.fromMap(rows.first);
  }

  Future<void> save(StudentProfile profile) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'profile',
      {'id': 1, ...profile.toMap()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
