/// "خريطتي التعليمية" — QURAN_COMPANION_ROADMAP.md §4.11 (Phase 7).
/// A recommendation-only 3-level map linking pillars that already exist
/// in this app ("يدخل المسلم صفر يخرج دكتور") — no new content, and
/// deliberately NOT a technical lock: a student can open any screen
/// regardless of level, matching the app's "companion not manager"
/// principle. `contentType` keys are matched by `CurriculumRepository`'s
/// live status computation, which reads existing progress tables rather
/// than duplicating any data here.
class CurriculumItemDef {
  final String contentType;
  final String titleAr;

  /// `contentType` values of items a real hifz/study-institute sequence
  /// would normally cover first — 100_IDEAS_FOR_IMPROVEMENT.md's "deepen
  /// the prerequisite map" ask, picking up a decision made but never
  /// implemented in an earlier plan. **Advisory only, never a lock** — a
  /// student can still open and start any item regardless (same
  /// "companion not manager" principle stated above), this only powers a
  /// non-blocking suggestion badge (`CurriculumRepository.allStatuses()`).
  final List<String> prerequisites;
  const CurriculumItemDef({required this.contentType, required this.titleAr, this.prerequisites = const []});
}

class CurriculumLevelDef {
  final int id;
  final String titleAr;
  final String descriptionAr;
  final List<CurriculumItemDef> items;
  const CurriculumLevelDef({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.items,
  });
}

const curriculumLevels = [
  CurriculumLevelDef(
    id: 1,
    titleAr: 'المستوى الأول: المبتدئ',
    descriptionAr: 'أساس القراءة والحفظ الأول — لكل من يبدأ من الصفر، صغيرًا كان أو كبيرًا.',
    items: [
      CurriculumItemDef(contentType: 'qaida', titleAr: 'القاعدة النورانية (قراءة الحروف)'),
      CurriculumItemDef(contentType: 'juz_amma', titleAr: 'حفظ جزء عمّ', prerequisites: ['qaida']),
      CurriculumItemDef(contentType: 'adhkar', titleAr: 'أذكار الصباح والمساء'),
      CurriculumItemDef(contentType: 'arbain', titleAr: 'الأربعون النووية'),
    ],
  ),
  CurriculumLevelDef(
    id: 2,
    titleAr: 'المستوى الثاني: طالب علم',
    descriptionAr: 'توسيع الحفظ مع الفهم والتطبيق، وأول خطوات العقيدة والفقه.',
    items: [
      CurriculumItemDef(contentType: 'quran_memorization', titleAr: 'حفظ ومراجعة أوسع بالقرآن', prerequisites: ['juz_amma']),
      CurriculumItemDef(contentType: 'application', titleAr: 'فهم التفسير وتطبيقه يوميًا', prerequisites: ['juz_amma']),
      CurriculumItemDef(contentType: 'wasitiyyah', titleAr: 'العقيدة الواسطية', prerequisites: ['arbain']),
      CurriculumItemDef(contentType: 'fiqh_taharah_salah', titleAr: 'فقه الطهارة والصلاة', prerequisites: ['adhkar']),
    ],
  ),
  CurriculumLevelDef(
    id: 3,
    titleAr: 'المستوى الثالث: تعمّق علمي',
    descriptionAr: 'إتقان وترسيخ، ونصوص علمية أعمق لمن أراد المزيد.',
    items: [
      CurriculumItemDef(contentType: 'full_quran_mastery', titleAr: 'إتقان حفظ القرآن كاملًا', prerequisites: ['quran_memorization']),
      CurriculumItemDef(contentType: 'ajlan_tafsir', titleAr: 'شرح ابن كثير الصوتي المتعمّق (العجلان)', prerequisites: ['application']),
      CurriculumItemDef(contentType: 'zad_almaad', titleAr: 'زاد المعاد', prerequisites: ['wasitiyyah']),
      CurriculumItemDef(contentType: 'madarij', titleAr: 'مدارج السالكين', prerequisites: ['zad_almaad']),
    ],
  ),
];
