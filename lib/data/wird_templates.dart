/// "الورد اليومي" — QURAN_COMPANION_ROADMAP.md §4.17. A fixed, curated set
/// of daily-portion templates, not a DB-driven/user-authorable system —
/// same pattern as `_fixedGoalOptions` in completion_goals_screen.dart.
///
/// IMPORTANT (per Ismail's explicit confirmation 2026-08-15): the
/// scholar-named templates below are NOT presented as a wird those scholars
/// themselves authored or prescribed — no such verified document exists for
/// any of them. They are this app's own suggested daily routine, assembled
/// from content already sourced and verified elsewhere in the app (that
/// scholar's tafsir/commentary/text), explicitly labeled as such in each
/// template's `description`. Only the generic template is unattributed.
library;

class WirdTemplateItem {
  final String key; // 'quran' | 'adhkar' | 'istighfar' | 'reading'
  final String label;
  final String? subtitle;
  const WirdTemplateItem({required this.key, required this.label, this.subtitle});
}

class WirdTemplate {
  final String key;
  final String title;
  final String description;
  final List<WirdTemplateItem> items;

  /// Set only for a 'reading' item — which existing *_progress table/date
  /// column to check for "touched today", reusing the tracker that content
  /// type already has rather than building a new one.
  final (String table, String dateColumn)? readingSource;

  const WirdTemplate({
    required this.key,
    required this.title,
    required this.description,
    required this.items,
    this.readingSource,
  });
}

const wirdTemplates = [
  WirdTemplate(
    key: 'generic',
    title: 'الورد المقترح',
    description: 'ورد عام غير منسوب لعالم بعينه — حسب الاعتدال الشرعي العام في المداومة على القرآن والذكر والاستغفار.',
    items: [
      WirdTemplateItem(key: 'quran', label: 'ورد القرآن اليومي', subtitle: 'قراءة أو حفظ — حسب خطتك في "رحلتي"'),
      WirdTemplateItem(key: 'adhkar', label: 'أذكار الصباح والمساء'),
      WirdTemplateItem(key: 'istighfar', label: 'الاستغفار', subtitle: '100 مرة'),
    ],
  ),
  WirdTemplate(
    key: 'ibn_kathir',
    title: 'مسار تدبّر مع ابن كثير',
    description: 'ورد من تجميع التطبيق حول تفسير ابن كثير المُتاح فيه — وليس وردًا منسوبًا للإمام ابن كثير نفسه.',
    items: [
      WirdTemplateItem(key: 'quran', label: 'ورد القرآن اليومي'),
      WirdTemplateItem(key: 'reading', label: 'قراءة تفسير الآيات التي قرأتها اليوم', subtitle: 'من شاشة البحث في القرآن'),
      WirdTemplateItem(key: 'adhkar', label: 'أذكار الصباح والمساء'),
      WirdTemplateItem(key: 'istighfar', label: 'الاستغفار', subtitle: '100 مرة'),
    ],
  ),
  WirdTemplate(
    key: 'ibn_uthaymeen',
    title: 'مسار العقيدة مع ابن عثيمين',
    description: 'ورد من تجميع التطبيق حول محتوى العقيدة الواسطية المُتاح فيه — وليس وردًا منسوبًا للشيخ ابن عثيمين نفسه.',
    items: [
      WirdTemplateItem(key: 'quran', label: 'ورد القرآن اليومي'),
      WirdTemplateItem(key: 'reading', label: 'قراءة مقطع من العقيدة الواسطية', subtitle: 'من شاشة "العقيدة الواسطية"'),
      WirdTemplateItem(key: 'adhkar', label: 'أذكار الصباح والمساء'),
      WirdTemplateItem(key: 'istighfar', label: 'الاستغفار', subtitle: '100 مرة'),
    ],
    readingSource: ('wasitiyyah_progress', 'memorized_date'),
  ),
  WirdTemplate(
    key: 'ibn_qayyim',
    title: 'مسار السلوك مع ابن القيّم',
    description: 'ورد من تجميع التطبيق حول مدارج السالكين المُتاح فيه — وليس وردًا منسوبًا للإمام ابن القيّم نفسه.',
    items: [
      WirdTemplateItem(key: 'quran', label: 'ورد القرآن اليومي'),
      WirdTemplateItem(key: 'reading', label: 'قراءة مقطع من مدارج السالكين', subtitle: 'من شاشة "مدارج السالكين"'),
      WirdTemplateItem(key: 'adhkar', label: 'أذكار الصباح والمساء'),
      WirdTemplateItem(key: 'istighfar', label: 'الاستغفار', subtitle: '100 مرة'),
    ],
    readingSource: ('madarij_progress', 'read_date'),
  ),
  WirdTemplate(
    key: 'ibn_taymiyyah',
    title: 'مسار العقيدة مع ابن تيمية',
    description: 'ورد من تجميع التطبيق حول نص العقيدة الواسطية الأصلي (تأليف ابن تيمية) — وليس وردًا منسوبًا له شخصيًا.',
    items: [
      WirdTemplateItem(key: 'quran', label: 'ورد القرآن اليومي'),
      WirdTemplateItem(key: 'reading', label: 'قراءة مقطع من متن العقيدة الواسطية', subtitle: 'من شاشة "العقيدة الواسطية"'),
      WirdTemplateItem(key: 'adhkar', label: 'أذكار الصباح والمساء'),
      WirdTemplateItem(key: 'istighfar', label: 'الاستغفار', subtitle: '100 مرة'),
    ],
    readingSource: ('wasitiyyah_progress', 'memorized_date'),
  ),
];
