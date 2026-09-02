/// The real 40 subject categories turath.io's own site (app.turath.io)
/// organizes its ~8,593 books into — verified against the real site
/// 2026-08-29 (Ismail sent the real category page; independently confirmed
/// there is NO public api.turath.io endpoint to *list* categories: tried
/// `categories`, `cats`, `category/list`, `books?cat_id=`, and inspecting
/// app.turath.io's raw page source directly for embedded data -- none
/// exist).
///
/// BUT the real `search` endpoint's `cat_id` filter (already used for
/// in-book search) turns out to genuinely scope by category, and its
/// numeric IDs are exactly 1-40 in this list's real display order --
/// verified live 2026-08-29 by querying `cat_id` 1-10, 12, 13, 22, 23, 33,
/// 38-40 with a neutral query and checking the returned books' real
/// subject matter matches each position (e.g. `cat_id=6` returned musnads/
/// sunan == "كتب السنة", `cat_id=38` returned "الطب النبوي لابن القيم" ==
/// "الطب"). So `catId` below is real and usable for genuine category-
/// scoped search, not guessed.
///
/// [bookCountSnapshot] has no live source, though -- stored as a dated
/// snapshot, never presented as a real-time count. Full names are kept
/// un-truncated on purpose (Ismail: "لا تقطع أسماء الأقسام").
class TurathCategoryRef {
  final int catId;
  final String name;
  final int bookCountSnapshot;
  const TurathCategoryRef(this.catId, this.name, this.bookCountSnapshot);
}

/// 2026-08-29 snapshot, in the real display order from app.turath.io.
const String turathCategorySnapshotDate = '2026-08-29';

const List<TurathCategoryRef> turathCategories = [
  TurathCategoryRef(1, 'العقيدة', 808),
  TurathCategoryRef(2, 'الفرق والردود', 151),
  TurathCategoryRef(3, 'التفسير', 274),
  TurathCategoryRef(4, 'علوم القرآن وأصول التفسير', 311),
  TurathCategoryRef(5, 'التجويد والقراءات', 152),
  TurathCategoryRef(6, 'كتب السنة', 1243),
  TurathCategoryRef(7, 'شروح الحديث', 265),
  TurathCategoryRef(8, 'التخريج والأطراف', 129),
  TurathCategoryRef(9, 'العلل والسؤالات الحديثية', 78),
  TurathCategoryRef(10, 'علوم الحديث', 320),
  TurathCategoryRef(11, 'أصول الفقه', 252),
  TurathCategoryRef(12, 'علوم الفقه والقواعد الفقهية', 58),
  TurathCategoryRef(13, 'المنطق', 11),
  TurathCategoryRef(14, 'الفقه الحنفي', 87),
  TurathCategoryRef(15, 'الفقه المالكي', 89),
  TurathCategoryRef(16, 'الفقه الشافعي', 90),
  TurathCategoryRef(17, 'الفقه الحنبلي', 153),
  TurathCategoryRef(18, 'الفقه العام', 208),
  TurathCategoryRef(19, 'مسائل فقهية', 429),
  TurathCategoryRef(20, 'السياسة الشرعية والقضاء', 100),
  TurathCategoryRef(21, 'الفرائض والوصايا', 28),
  TurathCategoryRef(22, 'الفتاوى', 64),
  TurathCategoryRef(23, 'الرقائق والآداب والأذكار', 625),
  TurathCategoryRef(24, 'السيرة النبوية', 187),
  TurathCategoryRef(25, 'التاريخ', 206),
  TurathCategoryRef(26, 'التراجم والطبقات', 579),
  TurathCategoryRef(27, 'الأنساب', 52),
  TurathCategoryRef(28, 'البلدان والرحلات', 97),
  TurathCategoryRef(29, 'كتب اللغة', 79),
  TurathCategoryRef(30, 'الغريب والمعاجم', 135),
  TurathCategoryRef(31, 'النحو والصرف', 213),
  TurathCategoryRef(32, 'الأدب', 406),
  TurathCategoryRef(33, 'العروض والقوافي', 9),
  TurathCategoryRef(34, 'الشعر ودواوينه', 25),
  TurathCategoryRef(35, 'البلاغة', 44),
  TurathCategoryRef(36, 'الجوامع', 137),
  TurathCategoryRef(37, 'فهارس الكتب والأدلة', 102),
  TurathCategoryRef(38, 'الطب', 14),
  TurathCategoryRef(39, 'كتب عامة', 357),
  TurathCategoryRef(40, 'علوم أخرى', 26),
];
