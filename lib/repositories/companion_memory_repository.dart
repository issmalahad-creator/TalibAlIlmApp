import '../db/database_helper.dart';

/// Backs "اريد ان يتذكره ويكون صديقه" (Ismail, 2026-08-18) — durable memory
/// for the companion chat engine, so it stops greeting the student as a
/// stranger every message. Two kinds of memory, deliberately separate:
/// `companion_memory` for small durable facts (name), `companion_chat_log`
/// for a rolling history the engine can glance back at.
class CompanionMemoryRepository {
  static const _keyName = 'student_name';

  Future<String?> getName() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('companion_memory', where: 'key = ?', whereArgs: [_keyName], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setName(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('companion_memory', {'key': _keyName, 'value': name});
  }

  /// Most recent log entry strictly before this call — i.e. "what we last
  /// talked about," read BEFORE logging the current message so it never
  /// just echoes itself back.
  Future<(String userText, String? intentId, DateTime at)?> lastEntry() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('companion_chat_log', orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return (row['user_text'] as String, row['intent_id'] as String?, DateTime.parse(row['created_at'] as String));
  }

  Future<void> logMessage(String userText, String? intentId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('companion_chat_log', {
      'created_at': DateTime.now().toIso8601String(),
      'user_text': userText,
      'intent_id': intentId,
    });
  }
}
