import 'package:sqflite/sqflite.dart';

import '../data/arabic_curriculum.dart';
import '../db/database_helper.dart';
import '../utils/month.dart';

/// Progress tracking for the Arabic-learning curriculum (Phase 10b) —
/// per-letter/lesson "learned" marks, keyed by a stable string key
/// (e.g. 'alphabet_ا') rather than a numeric id, since the curriculum
/// content is a fixed const list, not DB-driven.
class ArabicCurriculumRepository {
  Future<Set<String>> learnedKeys() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('arabic_curriculum_progress');
    return rows.map((r) => r['lesson_key'] as String).toSet();
  }

  Future<void> markLearned(String lessonKey) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'arabic_curriculum_progress',
      {'lesson_key': lessonKey, 'learned_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isStageComplete(CurriculumStage stage, Set<String> learned) async {
    if (stage.key != 'alphabet') return false;
    return arabicAlphabet.every((l) => learned.contains('alphabet_${l.letter}'));
  }
}
