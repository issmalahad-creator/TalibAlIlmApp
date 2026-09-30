import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../services/spaced_repetition_engine.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';

/// One due-for-review item, generalized across pillars — powers
/// `KnowledgeReviewScreen`'s per-pillar due lists.
class DueReviewItem {
  final String itemType; // 'hadith' | 'wasitiyyah' | 'adhkar'
  final int itemId;
  const DueReviewItem({required this.itemType, required this.itemId});
}

/// Generalized spaced-repetition tracking for pillars beyond Quran
/// memorization — Ismail's 2026-08-16 "الدماغ الذي يربط" request, Batch 1.
/// Reuses `spaced_repetition_engine.dart`'s exact station logic (same
/// `[1,3,7,14,30,60]`-day engine as `MemorizationRepository`) against the
/// new `knowledge_review_progress` table (v35), keyed by `(item_type,
/// item_id)` so hadith, Wasitiyyah, and (added 2026-08-16) adhkar items
/// share one table without a second migration per pillar.
/// `MemorizationRepository`/`memorization_progress` are completely
/// untouched — Quran keeps its own table and engine call sites exactly as
/// they were.
///
/// This sits ON TOP of, not instead of, each pillar's existing tracking —
/// for hadith/Wasitiyyah, `startReviewing` is called right after the flat
/// "memorized" flag is set; for adhkar (which has no memorized flag at
/// all, only a daily completion streak), it's opted into review
/// explicitly per-item from the reading screen instead — see
/// `adhkar_category_screen.dart`.
class KnowledgeReviewRepository {
  /// Seeds an item into spaced review at station 1 (reviewed again
  /// tomorrow) — call once, right after the pillar's own `markMemorized`.
  /// Safe to call more than once (e.g. re-marking the same item):
  /// `ConflictAlgorithm.ignore` so an item already under active review
  /// isn't reset back to station 1.
  Future<void> startReviewing(String itemType, int itemId) async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();
    await db.insert(
      'knowledge_review_progress',
      {
        'item_type': itemType,
        'item_id': itemId,
        'status': 'reviewing',
        'station': 1,
        'last_review_date': today,
        'next_review_date': _addDays(today, stationDays[0]),
        'consecutive_good_count': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> recordReview(String itemType, int itemId, ReviewQuality quality) async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();

    final rows = await db.query(
      'knowledge_review_progress',
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [itemType, itemId],
      limit: 1,
    );
    final current = rows.isEmpty ? null : rows.first;
    final outcome = nextStation(
      currentStatus: current?['status'] as String? ?? 'reviewing',
      currentStation: current?['station'] as int?,
      consecutiveGoodCount: (current?['consecutive_good_count'] as int?) ?? 0,
      quality: quality,
    );

    await db.insert(
      'knowledge_review_progress',
      {
        'item_type': itemType,
        'item_id': itemId,
        'status': outcome.status,
        'station': outcome.station,
        'last_review_date': today,
        'next_review_date': _addDays(today, outcome.intervalDays),
        'consecutive_good_count': outcome.consecutiveGoodCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Same "بدون عقاب" throttle as `MemorizationRepository.dueToday()`:
  /// everything due exactly today is always included; older overdue items
  /// are capped at [maxExtra], oldest first.
  Future<List<DueReviewItem>> dueToday(String itemType, {int maxExtra = 5}) async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();
    final rows = await db.query(
      'knowledge_review_progress',
      where: 'item_type = ? AND next_review_date <= ?',
      whereArgs: [itemType, today],
      orderBy: 'next_review_date ASC',
    );
    final dueTodayExact = rows.where((r) => r['next_review_date'] == today).toList();
    final overdue = rows.where((r) => (r['next_review_date'] as String) != today).toList();
    final selected = [...dueTodayExact, ...overdue.take(maxExtra)];
    return selected.map((r) => DueReviewItem(itemType: r['item_type'] as String, itemId: r['item_id'] as int)).toList();
  }

  Future<Map<String, List<DueReviewItem>>> dueTodayAll() async {
    return {
      'hadith': await dueToday('hadith'),
      'wasitiyyah': await dueToday('wasitiyyah'),
      'adhkar': await dueToday('adhkar'),
      // «أعد بناء الشجرة» cards (USUL_TAFSIR_TREE.md U6).
      'usul_tree': await dueToday('usul_tree'),
    };
  }

  /// Every item currently opted into review for [itemType], regardless of
  /// due date — powers a quiz screen's "pick a random item I'm reviewing"
  /// sampling (same role `HadithRepository.memorizedIds()`/
  /// `WasitiyyahRepository.memorizedIds()` play for their own quizzes).
  Future<List<int>> allItemIds(String itemType) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('knowledge_review_progress', where: 'item_type = ?', whereArgs: [itemType], columns: ['item_id']);
    return rows.map((r) => r['item_id'] as int).toList();
  }

  Future<bool> isUnderReview(String itemType, int itemId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('knowledge_review_progress', where: 'item_type = ? AND item_id = ?', whereArgs: [itemType, itemId], limit: 1);
    return rows.isNotEmpty;
  }

  String _addDays(String hijriDate, int days) {
    final dt = gregorianFromHijriDateTime(hijriDate, null).add(Duration(days: days));
    return hijriDateStringForDate(dt);
  }
}
