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
  /// 0.0-1.0 for items with a known total (null for open-ended/ongoing
  /// items like adhkar streaks, or comingSoon items with nothing to
  /// measure yet) — used to draw a real progress ring on the map node,
  /// not a decorative placeholder.
  final double? progressFraction;

  /// Non-blocking suggestion text (e.g. "يُنصح بإكمال X أولًا") when one of
  /// this item's `prerequisites` isn't `completed`/`ongoing` yet — null
  /// when there's nothing to suggest. **Never** prevents opening the item;
  /// see `CurriculumItemDef.prerequisites`'s doc comment.
  final String? advisoryText;
  const CurriculumItemStatus({
    required this.contentType,
    required this.titleAr,
    required this.state,
    required this.detailAr,
    this.progressFraction,
    this.advisoryText,
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

  /// Every item across all 3 levels, keyed by level id — 100_IDEAS_FOR_IMPROVEMENT.md's
  /// "deepen the prerequisite map" ask. Computed over the *full* flattened
  /// list (not per-level, unlike [statusesFor]) because a prerequisite can
  /// point at an item from an earlier level, so its status must already be
  /// known before [advisoryText] can be filled in. Only 12 items total —
  /// cheap enough to always compute in full.
  Future<Map<int, List<CurriculumItemStatus>>> allStatuses() async {
    final db = await DatabaseHelper.instance.database;
    final allItems = [for (final level in curriculumLevels) ...level.items];

    final byType = <String, CurriculumItemStatus>{};
    for (final item in allItems) {
      byType[item.contentType] = await _statusFor(db, item);
    }

    final withAdvisory = <String, CurriculumItemStatus>{};
    for (final item in allItems) {
      final base = byType[item.contentType]!;
      String? advisory;
      for (final prereqType in item.prerequisites) {
        final prereqStatus = byType[prereqType];
        if (prereqStatus == null) continue;
        final satisfied = prereqStatus.state == CurriculumItemState.completed || prereqStatus.state == CurriculumItemState.ongoing;
        if (!satisfied) {
          advisory = 'يُنصح بإكمال "${prereqStatus.titleAr}" أولًا';
          break;
        }
      }
      withAdvisory[item.contentType] = CurriculumItemStatus(
        contentType: base.contentType,
        titleAr: base.titleAr,
        state: base.state,
        detailAr: base.detailAr,
        progressFraction: base.progressFraction,
        advisoryText: advisory,
      );
    }

    return {for (final level in curriculumLevels) level.id: [for (final item in level.items) withAdvisory[item.contentType]!]};
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
      progressFraction: (done / total).clamp(0, 1),
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
