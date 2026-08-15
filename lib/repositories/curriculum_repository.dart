import 'package:sqflite/sqflite.dart';

import '../data/curriculum_levels.dart';
import '../data/new_muslim_guide.dart';
import '../db/database_helper.dart';

enum CurriculumItemState { comingSoon, notStarted, inProgress, completed, ongoing }

class CurriculumItemStatus {
  final String contentType;
  final String titleAr;
  final CurriculumItemState state;
  final String detailAr;
  const CurriculumItemStatus({
    required this.contentType,
    required this.titleAr,
    required this.state,
    required this.detailAr,
  });
}

/// Computes each level-map item's status LIVE from the existing progress
/// tables it points at — no separate progress table of its own, so this
/// can never drift out of sync with the real screens (same "read live,
/// don't cache" principle as the §4.15 completion planner).
class CurriculumRepository {
  Future<List<CurriculumItemStatus>> statusesFor(List<CurriculumItemDef> items) async {
    final db = await DatabaseHelper.instance.database;
    return [for (final item in items) await _statusFor(db, item)];
  }

  Future<CurriculumItemStatus> _statusFor(Database db, CurriculumItemDef item) async {
    switch (item.contentType) {
      case 'qaida':
        return _comingSoon(item);
      case 'juz_amma':
        return _fraction(
          db,
          item,
          totalSql: 'SELECT COUNT(*) FROM memorization_units WHERE juz_number = 30',
          doneSql: "SELECT COUNT(*) FROM memorization_units u JOIN memorization_progress p ON p.unit_id = u.id "
              "WHERE u.juz_number = 30 AND (p.status = 'established' OR (p.station IS NOT NULL AND p.station >= 6))",
        );
      case 'adhkar':
        return _openEnded(db, item, 'SELECT COUNT(DISTINCT completed_date) FROM adhkar_completion', suffix: 'يوم إتمام');
      case 'arbain':
        return _fraction(
          db,
          item,
          totalSql: 'SELECT COUNT(*) FROM nawawi_hadiths',
          doneSql: 'SELECT COUNT(*) FROM hadith_progress WHERE memorized = 1',
        );
      case 'quran_memorization':
      case 'full_quran_mastery':
        return _fraction(
          db,
          item,
          totalSql: 'SELECT COUNT(*) FROM memorization_units',
          doneSql: "SELECT COUNT(*) FROM memorization_units u JOIN memorization_progress p ON p.unit_id = u.id "
              "WHERE (p.status = 'established' OR (p.station IS NOT NULL AND p.station >= 6))",
        );
      case 'application':
        return _openEnded(db, item, 'SELECT COUNT(*) FROM application_log', suffix: 'تطبيقًا مسجّلًا');
      case 'wasitiyyah':
        return _fraction(
          db,
          item,
          totalSql: 'SELECT COUNT(*) FROM wasitiyyah_sections',
          doneSql: 'SELECT COUNT(*) FROM wasitiyyah_progress WHERE memorized = 1',
        );
      case 'fiqh_taharah_salah':
        final done = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM guide_progress')) ?? 0;
        return _fractionResult(item, done, newMuslimGuideTopics.length);
      case 'ajlan_tafsir':
        return _openEnded(
          db,
          item,
          "SELECT COUNT(*) FROM audio_reflection_log WHERE series_id = 'ajlan_tafsir_baqarah'",
          suffix: 'فائدة مسجّلة',
        );
      case 'zad_almaad':
        return _fraction(
          db,
          item,
          totalSql: 'SELECT COUNT(*) FROM zad_almaad_chapters',
          doneSql: 'SELECT COUNT(*) FROM zad_almaad_progress WHERE read_done = 1',
        );
      case 'madarij':
        return _fraction(
          db,
          item,
          totalSql: 'SELECT COUNT(*) FROM madarij_sections',
          doneSql: 'SELECT COUNT(*) FROM madarij_progress WHERE read_done = 1',
        );
      default:
        return _comingSoon(item);
    }
  }

  Future<CurriculumItemStatus> _fraction(
    Database db,
    CurriculumItemDef item, {
    required String totalSql,
    required String doneSql,
  }) async {
    final total = Sqflite.firstIntValue(await db.rawQuery(totalSql)) ?? 0;
    final done = Sqflite.firstIntValue(await db.rawQuery(doneSql)) ?? 0;
    return _fractionResult(item, done, total);
  }

  CurriculumItemStatus _fractionResult(CurriculumItemDef item, int done, int total) {
    if (total == 0) return _comingSoon(item);
    final state = done == 0
        ? CurriculumItemState.notStarted
        : done >= total
            ? CurriculumItemState.completed
            : CurriculumItemState.inProgress;
    return CurriculumItemStatus(
      contentType: item.contentType,
      titleAr: item.titleAr,
      state: state,
      detailAr: '$done من $total',
    );
  }

  Future<CurriculumItemStatus> _openEnded(
    Database db,
    CurriculumItemDef item,
    String countSql, {
    required String suffix,
  }) async {
    final count = Sqflite.firstIntValue(await db.rawQuery(countSql)) ?? 0;
    return CurriculumItemStatus(
      contentType: item.contentType,
      titleAr: item.titleAr,
      state: count == 0 ? CurriculumItemState.notStarted : CurriculumItemState.ongoing,
      detailAr: count == 0 ? 'لم يبدأ بعد' : '$count $suffix',
    );
  }

  CurriculumItemStatus _comingSoon(CurriculumItemDef item) => CurriculumItemStatus(
        contentType: item.contentType,
        titleAr: item.titleAr,
        state: CurriculumItemState.comingSoon,
        detailAr: 'قريبًا',
      );
}
