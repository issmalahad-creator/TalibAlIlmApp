import 'package:sqflite/sqflite.dart';

import '../data/quran_surahs.dart';
import '../db/database_helper.dart';
import '../utils/month.dart';

class Milestone {
  final int id;
  final String pillar; // 'quran' | 'hadith' | 'adhkar'
  final String milestoneType; // 'surah' | 'juz' | 'full_quran' | 'ten_hadiths' | 'full_arbain' | 'adhkar_streak_7' | 'adhkar_streak_30' | 'adhkar_streak_100'
  final int? referenceId;
  final String title;
  final String? achievedDate;
  final bool certificateShared;
  Milestone({
    required this.id,
    required this.pillar,
    required this.milestoneType,
    this.referenceId,
    required this.title,
    this.achievedDate,
    required this.certificateShared,
  });

  bool get isAchieved => achievedDate != null;

  /// Confetti intensity scaling for the celebration overlay — roadmap
  /// §4.14's "يرتفع مع ارتفاع الهمة" (bigger achievement, bigger
  /// celebration): page < surah/10-hadiths < juz/full-Arbain < full Quran.
  int get celebrationTier => switch (milestoneType) {
        'full_quran' => 3,
        'juz' || 'full_arbain' || 'adhkar_streak_100' => 2,
        _ => 1,
      };
}

/// Certificates + celebration — QURAN_COMPANION_ROADMAP.md §4.14. Every
/// possible certificate is seeded up front (locked, `achieved_date` NULL) so
/// "شهاداتي" can show the full unlock map from day one, building
/// anticipation rather than surprising the student only after the fact.
/// `checkQuranMilestones`/`checkHadithMilestones` are safe to call after
/// every relevant progress update (idempotent) — they only stamp
/// `achieved_date` the moment a milestone first becomes true.
class MilestoneRepository {
  static const _hadithBatchSizes = [10, 20, 30, 40];
  static const _totalHadiths = 42;
  static const _adhkarStreakThresholds = [7, 30, 100];

  Future<void> seedIfNeeded() async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM achievement_milestones'));
    if ((count ?? 0) > 0) return;

    final batch = db.batch();
    for (final s in quranSurahs) {
      batch.insert('achievement_milestones', {
        'pillar': 'quran',
        'milestone_type': 'surah',
        'reference_id': s.number,
        'title': 'شهادة إتمام حفظ سورة ${s.name}',
      });
    }
    for (var juz = 1; juz <= 30; juz++) {
      batch.insert('achievement_milestones', {
        'pillar': 'quran',
        'milestone_type': 'juz',
        'reference_id': juz,
        'title': 'شهادة إتمام حفظ الجزء $juz',
      });
    }
    batch.insert('achievement_milestones', {
      'pillar': 'quran',
      'milestone_type': 'full_quran',
      'reference_id': null,
      'title': 'شهادة ختم حفظ القرآن الكريم كاملًا',
    });
    for (final n in _hadithBatchSizes) {
      batch.insert('achievement_milestones', {
        'pillar': 'hadith',
        'milestone_type': 'ten_hadiths',
        'reference_id': n,
        'title': 'شهادة حفظ $n أحاديث من الأربعين النووية',
      });
    }
    batch.insert('achievement_milestones', {
      'pillar': 'hadith',
      'milestone_type': 'full_arbain',
      'reference_id': null,
      'title': 'شهادة إتمام حفظ الأربعين النووية كاملة',
    });
    for (final days in _adhkarStreakThresholds) {
      batch.insert('achievement_milestones', {
        'pillar': 'adhkar',
        'milestone_type': 'adhkar_streak_$days',
        'reference_id': null,
        'title': 'شهادة الاستمرار $days يومًا في أذكار الصباح والمساء',
      });
    }
    batch.insert('achievement_milestones', {
      'pillar': 'arabic_curriculum',
      'milestone_type': 'stage_alphabet',
      'reference_id': null,
      'title': 'شهادة إتمام المرحلة ١: الحروف والنطق',
    });
    await batch.commit(noResult: true);
  }

  Future<List<Milestone>> all() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('achievement_milestones', orderBy: 'pillar, milestone_type, reference_id');
    return rows.map(_toMilestone).toList();
  }

  /// Detects newly-completed surah/juz/full-Quran certificates from
  /// `memorization_progress` — call after any review/mark-memorized action
  /// that could complete one. "Mastered" = a page reached station 6 (either
  /// `established`, i.e. past station 6, or still at station 6 exactly).
  Future<List<Milestone>> checkQuranMilestones() async {
    final db = await DatabaseHelper.instance.database;
    final newlyEarned = <Milestone>[];
    final today = todayDate();

    Future<void> tryAward(String type, int? referenceId, String unitWhere, List<Object?> args) async {
      final rows = await db.query(
        'achievement_milestones',
        where: 'pillar = ? AND milestone_type = ? AND reference_id IS ?',
        whereArgs: ['quran', type, referenceId],
      );
      if (rows.isEmpty || rows.first['achieved_date'] != null) return;

      final total = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM memorization_units u WHERE $unitWhere', args),
          ) ??
          0;
      if (total == 0) return;
      final mastered = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM memorization_units u
        JOIN memorization_progress p ON p.unit_id = u.id
        WHERE $unitWhere AND (p.status = 'established' OR (p.station IS NOT NULL AND p.station >= 6))
      ''', args)) ?? 0;
      if (mastered < total) return;

      final row = rows.first;
      await db.update('achievement_milestones', {'achieved_date': today}, where: 'id = ?', whereArgs: [row['id']]);
      newlyEarned.add(_toMilestone({...row, 'achieved_date': today}));
    }

    for (final s in quranSurahs) {
      await tryAward('surah', s.number, 'u.surah_start <= ? AND u.surah_end >= ?', [s.number, s.number]);
    }
    for (var juz = 1; juz <= 30; juz++) {
      await tryAward('juz', juz, 'u.juz_number = ?', [juz]);
    }
    await tryAward('full_quran', null, '1 = 1', []);

    return newlyEarned;
  }

  /// Detects newly-completed Arba'in hadith certificates — call after
  /// `HadithRepository.markMemorized`.
  Future<List<Milestone>> checkHadithMilestones() async {
    final db = await DatabaseHelper.instance.database;
    final count =
        Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM hadith_progress WHERE memorized = 1")) ?? 0;
    final newlyEarned = <Milestone>[];
    final today = todayDate();

    Future<void> tryAward(String type, int? referenceId) async {
      final rows = await db.query(
        'achievement_milestones',
        where: 'pillar = ? AND milestone_type = ? AND reference_id IS ?',
        whereArgs: ['hadith', type, referenceId],
      );
      if (rows.isEmpty || rows.first['achieved_date'] != null) return;
      final row = rows.first;
      await db.update('achievement_milestones', {'achieved_date': today}, where: 'id = ?', whereArgs: [row['id']]);
      newlyEarned.add(_toMilestone({...row, 'achieved_date': today}));
    }

    for (final n in _hadithBatchSizes) {
      if (count >= n) await tryAward('ten_hadiths', n);
    }
    if (count >= _totalHadiths) await tryAward('full_arbain', null);

    return newlyEarned;
  }

  /// Detects newly-reached adhkar streak certificates — call after
  /// `AdhkarRepository.markCompletedToday` for the merged morning+evening
  /// category (see `_adhkarStreakCategoryTitle`'s doc comment for why it's
  /// just the one category rather than two).
  Future<List<Milestone>> checkAdhkarMilestones(int streakDays) async {
    final db = await DatabaseHelper.instance.database;
    final newlyEarned = <Milestone>[];
    final today = todayDate();

    for (final threshold in _adhkarStreakThresholds) {
      if (streakDays < threshold) continue;
      final type = 'adhkar_streak_$threshold';
      final rows = await db.query(
        'achievement_milestones',
        where: 'pillar = ? AND milestone_type = ? AND reference_id IS NULL',
        whereArgs: ['adhkar', type],
      );
      if (rows.isEmpty || rows.first['achieved_date'] != null) continue;
      final row = rows.first;
      await db.update('achievement_milestones', {'achieved_date': today}, where: 'id = ?', whereArgs: [row['id']]);
      newlyEarned.add(_toMilestone({...row, 'achieved_date': today}));
    }

    return newlyEarned;
  }

  /// Detects the alphabet-stage certificate — call after
  /// `ArabicCurriculumRepository.markLearned` once every letter in the
  /// alphabet has been marked learned.
  Future<List<Milestone>> checkArabicCurriculumMilestones({required bool alphabetComplete}) async {
    if (!alphabetComplete) return [];
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();
    final rows = await db.query(
      'achievement_milestones',
      where: 'pillar = ? AND milestone_type = ?',
      whereArgs: ['arabic_curriculum', 'stage_alphabet'],
    );
    if (rows.isEmpty || rows.first['achieved_date'] != null) return [];
    final row = rows.first;
    await db.update('achievement_milestones', {'achieved_date': today}, where: 'id = ?', whereArgs: [row['id']]);
    return [_toMilestone({...row, 'achieved_date': today})];
  }

  Future<void> markShared(int milestoneId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('achievement_milestones', {'certificate_shared': 1}, where: 'id = ?', whereArgs: [milestoneId]);
  }

  Milestone _toMilestone(Map<String, Object?> row) => Milestone(
        id: row['id'] as int,
        pillar: row['pillar'] as String,
        milestoneType: row['milestone_type'] as String,
        referenceId: row['reference_id'] as int?,
        title: row['title'] as String,
        achievedDate: row['achieved_date'] as String?,
        certificateShared: (row['certificate_shared'] as int) == 1,
      );
}
