import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';

class AdhkarCategory {
  final int id;
  final int order;
  final String title;
  final bool isDailyCore;
  AdhkarCategory({required this.id, required this.order, required this.title, required this.isDailyCore});
}

class AdhkarItem {
  final int id;
  final String text;
  final String? footnote;
  final int repeatCount;
  AdhkarItem({required this.id, required this.text, this.footnote, required this.repeatCount});
}

/// Hisn al-Muslim daily adhkar — QURAN_COMPANION_ROADMAP.md Phase 5هـ. A
/// category "counts" as done for a given day once every item in it has
/// been tapped through (`markCompletedToday`) — that single date-keyed row
/// is all a streak needs, no per-item/per-tap history is persisted.
class AdhkarRepository {
  Future<List<AdhkarCategory>> allCategories() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('adhkar_categories', orderBy: 'category_order');
    return rows
        .map((r) => AdhkarCategory(
              id: r['id'] as int,
              order: r['category_order'] as int,
              title: r['title'] as String,
              isDailyCore: (r['is_daily_core'] as int) == 1,
            ))
        .toList();
  }

  Future<List<AdhkarItem>> itemsFor(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('adhkar_items', where: 'category_id = ?', whereArgs: [categoryId], orderBy: 'item_order');
    return rows
        .map((r) => AdhkarItem(
              id: r['id'] as int,
              text: r['text'] as String,
              footnote: r['footnote'] as String?,
              repeatCount: r['repeat_count'] as int,
            ))
        .toList();
  }

  Future<bool> isCompletedToday(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'adhkar_completion',
      where: 'category_id = ? AND completed_date = ?',
      whereArgs: [categoryId, todayDate()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> markCompletedToday(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('adhkar_completion', {'category_id': categoryId, 'completed_date': todayDate()});
  }

  /// Consecutive-day streak ending today or yesterday (a day not yet
  /// completed today doesn't reset the streak until the day actually
  /// passes) — powers the 7/30/100-day adhkar certificates.
  Future<int> currentStreak(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'adhkar_completion',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'completed_date DESC',
    );
    if (rows.isEmpty) return 0;
    final dates = rows.map((r) => r['completed_date'] as String).toList();

    final today = todayDate();
    var cursor = today;
    if (dates.first != today) {
      // Streak only survives one un-completed day (today) before it breaks —
      // if even yesterday is missing, there's no active streak.
      final yesterday = _addDays(today, -1);
      if (dates.first != yesterday) return 0;
      cursor = yesterday;
    }

    var streak = 0;
    for (final d in dates) {
      if (d != cursor) break;
      streak++;
      cursor = _addDays(cursor, -1);
    }
    return streak;
  }

  String _addDays(String hijriDate, int days) {
    final dt = gregorianFromHijriDateTime(hijriDate, null).add(Duration(days: days));
    return hijriDateStringForDate(dt);
  }

  /// Where the student left off reading this category today — Ismail's
  /// 2026-08-16 "تجربة عبادة متصلة" request. Only the item index is
  /// persisted (repeat counters stay in-memory, unchanged from before);
  /// gated to today's Hijri date so a stale position from a previous day
  /// is silently ignored rather than resuming somewhere irrelevant.
  Future<int> resumePosition(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('adhkar_session_position', where: 'category_id = ?', whereArgs: [categoryId], limit: 1);
    if (rows.isEmpty) return 0;
    if (rows.first['updated_date'] != todayDate()) return 0;
    return rows.first['item_index'] as int;
  }

  Future<void> saveSessionPosition(int categoryId, int itemIndex) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'adhkar_session_position',
      {'category_id': categoryId, 'item_index': itemIndex, 'updated_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearSessionPosition(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('adhkar_session_position', where: 'category_id = ?', whereArgs: [categoryId]);
  }
}
