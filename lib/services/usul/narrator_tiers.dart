/// Which generation a narrator of the athar belongs to — feeds the «أحسن
/// طرق التفسير» branch (tafsir by the Companions / the Successors / later).
///
/// **DRAFT for Ismail's review** (docs/quran/reports/USUL_TREE_COVERAGE.md):
/// the most frequent names in the athar data, classified by hand. It covers
/// ~90% of chains; anyone not listed is simply "unclassified" and never shown
/// under a tier — classification is scholarship, never guessed. Keep in sync
/// with tool/usul_tree_coverage.py.
enum NarratorTier { sahabi, tabii, later }

NarratorTier? narratorTier(String name) {
  if (_sahaba.contains(name)) return NarratorTier.sahabi;
  if (_tabiin.contains(name)) return NarratorTier.tabii;
  if (_later.contains(name)) return NarratorTier.later;
  return null;
}

const _sahaba = {
  'عبد الله بن عباس', 'عبد الله بن مسعود', 'أبو هريرة', 'عبد الله بن عمر', 'أنس بن مالك',
  'علي بن أبي طالب', 'علي', 'عائشة', 'جابر بن عبد الله', 'أبو سعيد الخدري', 'عبد الله بن عمرو بن العاص',
  'عمر بن الخطاب', 'أبو بن كعب', 'أبي بن كعب', 'أبو أمامة', 'أبو الدرداء', 'حذيفة بن اليمان', 'البراء بن عازب',
  'أبو موسى الأشعري', 'أبو ذر', 'عبد الله بن الزبير', 'سلمان الفارسي', 'معاذ بن جبل',
};

const _tabiin = {
  'قتادة بن دعامة', 'مجاهد بن جبر', 'الحسن البصري', 'الحسن', 'إسماعيل السدي', 'الضحاك بن مزاحم',
  'سعيد بن جبير', 'عكرمة مولى ابن عباس', 'الربيع بن أنس', 'عطاء', 'عطاء بن أبي رباح', 'أبو العالية الرياحي',
  'عامر الشعبي', 'محمد بن كعب القرظي', 'إبراهيم النخعي', 'إبراهيم', 'محمد بن شهاب الزهري', 'زيد بن أسلم',
  'عطاء الخراساني', 'أبو مالك غزوان الغفاري', 'سعيد بن المسيب', 'أبو صالح باذام', 'عطية بن سعد العوفي',
  'عروة بن الزبير', 'طاووس بن كيسان', 'محمد بن سيرين', 'مسروق بن الأجدع الهمداني', 'عبيد بن عمير',
  'مكحول الشامي', 'ميمون بن مهران', 'وهب بن منبه', 'كعب الأحبار', 'الأعمش', 'سليمان بن مهران الأعمش',
  'عاصم بن أبي النجود',
};

const _later = {
  'مقاتل بن سليمان', 'مقاتل', 'يحيى بن سلام', 'عبد الرحمن بن زيد بن أسلم', 'عبد الملك بن جريج',
  'محمد بن السائب الكلبي', 'محمد بن إسحاق', 'مقاتل بن حيان', 'سفيان الثوري', 'سفيان', 'سفيان بن عيينة',
  'مالك بن أنس',
};
