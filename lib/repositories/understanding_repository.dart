import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class UnderstandingStatus {
  final int unitId;
  final bool understood;
  final String? notes;
  UnderstandingStatus({required this.unitId, required this.understood, this.notes});
}

/// "فهمت" — Phase 3 of QURAN_COMPANION_ROADMAP.md. Deliberately its own
/// table/status, never merged with `memorization_progress` — memorizing a
/// page and understanding it are two separate facts about the student.
class UnderstandingRepository {
  Future<void> markUnderstood(int unitId, {String? notes}) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'understanding_progress',
      {'unit_id': unitId, 'understood': 1, 'user_notes': notes, 'marked_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Memorized units (any station, including established) that have not
  /// been marked understood yet — what the "فهم" step of جلسة اليوم and the
  /// understanding screen actually offer the student.
  Future<List<int>> memorizedNotYetUnderstood() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT p.unit_id FROM memorization_progress p
      LEFT JOIN understanding_progress u ON u.unit_id = p.unit_id
      WHERE p.status != 'not_started' AND COALESCE(u.understood, 0) = 0
      ORDER BY p.unit_id
    ''');
    return rows.map((r) => r['unit_id'] as int).toList();
  }

  Future<bool> hasUnderstoodToday() async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM understanding_progress WHERE marked_date = ?', [todayDate()]),
    );
    return (count ?? 0) > 0;
  }
}
