import 'dart:convert';

import '../db/database_helper.dart';

class QueuedSubmission {
  final int id;
  final String month;
  final Map<String, dynamic> payload;
  final bool telegramSent;
  final bool sheetsSent;

  QueuedSubmission({
    required this.id,
    required this.month,
    required this.payload,
    required this.telegramSent,
    required this.sheetsSent,
  });

  bool get isFullySent => telegramSent && sheetsSent;
}

class SubmissionRepository {
  Future<int> enqueue(String month, Map<String, dynamic> payload) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('submission_queue', {
      'month': month,
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'telegram_sent': 0,
      'sheets_sent': 0,
    });
  }

  Future<List<QueuedSubmission>> pending() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'submission_queue',
      where: 'telegram_sent = 0 OR sheets_sent = 0',
      orderBy: 'id ASC',
    );
    return rows
        .map((r) => QueuedSubmission(
              id: r['id'] as int,
              month: r['month'] as String,
              payload: jsonDecode(r['payload_json'] as String) as Map<String, dynamic>,
              telegramSent: (r['telegram_sent'] as int) == 1,
              sheetsSent: (r['sheets_sent'] as int) == 1,
            ))
        .toList();
  }

  Future<void> markTelegramSent(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('submission_queue', {'telegram_sent': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markSheetsSent(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('submission_queue', {'sheets_sent': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasSubmittedForMonth(String month) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'submission_queue',
      where: 'month = ? AND telegram_sent = 1 AND sheets_sent = 1',
      whereArgs: [month],
    );
    return rows.isNotEmpty;
  }
}
