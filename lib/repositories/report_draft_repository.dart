import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/report_draft.dart';

class ReportDraftRepository {
  Future<ReportDraft> get(String month) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('report_drafts', where: 'month = ?', whereArgs: [month]);
    if (rows.isEmpty) return ReportDraft(month: month);
    return ReportDraft.fromMap(rows.first);
  }

  Future<void> save(ReportDraft draft) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('report_drafts', draft.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
