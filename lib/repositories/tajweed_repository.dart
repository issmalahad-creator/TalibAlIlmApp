import 'package:sqflite/sqflite.dart';

import '../data/tajweed_curriculum.dart';
import '../db/database_helper.dart';
import '../utils/month.dart';

/// Progress tracking for the Tajweed curriculum (Phase 11) — per-rule
/// "learned" marks, keyed by a stable string key since the curriculum
/// content is a fixed const list, not DB-driven.
class TajweedRepository {
  Future<Set<String>> learnedKeys() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('tajweed_progress');
    return rows.map((r) => r['rule_key'] as String).toSet();
  }

  Future<void> markLearned(String ruleKey) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'tajweed_progress',
      {'rule_key': ruleKey, 'learned_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  bool isTierComplete(TajweedTier tier, Set<String> learned) {
    return tier.rules.every((r) => learned.contains('${tier.key}_${r.titleAr}'));
  }
}
