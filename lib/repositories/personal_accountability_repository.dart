import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/personal_accountability.dart';

/// Purely local, self-declared reward/punishment — see
/// QURAN_COMPANION_ROADMAP.md section 4.7. This repository only stores and
/// returns what the student themselves wrote; nothing here ever triggers an
/// automated action (no payments, no notifications to anyone else, no
/// blocking/deleting anything).
class PersonalAccountabilityRepository {
  Future<PersonalAccountability> get() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('personal_accountability', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return const PersonalAccountability();
    return PersonalAccountability.fromMap(rows.first);
  }

  Future<void> save(PersonalAccountability value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('personal_accountability', value.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
