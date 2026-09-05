import 'package:flutter/painting.dart';

/// Phase G-t v2 · the muṣḥaf tajwīd colour system.
///
/// **A Quran-reading palette, not Material.** Six categories, one hue per
/// *sound behaviour* (not the 18 rule ids and not one‑hue‑per‑rule noise),
/// drawn from the Dār al‑Maʿrifah / King Fahd Complex coloured‑muṣḥaf
/// tradition and muted so a coloured glyph reads as "ink that happens to be
/// coloured", never as a highlight. The six are separated by **value** as
/// well as hue so a colour‑blind reader still sees six bands.
///
/// These hues are painted **onto the glyph outlines themselves**
/// (`lib/services/mushaf/tajweed_svg.dart` injects `fill` on the exact
/// `<path>` of each rule glyph) — there is no rectangle, no wash, no overlay.
///
/// Rules the source (`cpfair/quran-tajweed`) does **not** mark — إظهار
/// (ḥalqī/shafawī), تفخيم/ترقيق — get no colour. Claiming them would be
/// inventing data.
class TajweedCategory {
  final String key;
  final String labelAr;
  final String defAr; // one line for the legend sheet
  final int lightRgb; // 0xFFRRGGBB
  final int darkRgb;
  const TajweedCategory(
      this.key, this.labelAr, this.defAr, this.lightRgb, this.darkRgb);

  Color color({required bool night}) => Color(night ? darkRgb : lightRgb);

  /// `#RRGGBB` for SVG `fill`.
  String hex({required bool night}) =>
      '#${((night ? darkRgb : lightRgb) & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

const List<TajweedCategory> kTajweedCategories = [
  TajweedCategory(
    'madd',
    'المدّ',
    'إطالة الصوت بحرف مدّ — حركتان أو أربع أو ستّ بحسب سببه.',
    0xFFA63D2E, // muted brick‑red — the universal madd colour, softened
    0xFFE08A73,
  ),
  TajweedCategory(
    'ghunnah',
    'الغُنّة والإدغام بغُنّة',
    'صوت يخرج من الخيشوم يصاحب النون والميم المشدّدتين وأحكامهما (ومنه الإقلاب).',
    0xFF1F7A6B, // deep teal‑green — the classic ghunnah/ikhfāʾ family
    0xFF5FC2AE,
  ),
  TajweedCategory(
    'ikhfa',
    'الإخفاء',
    'نطق النون الساكنة أو الميم الساكنة بصفة بين الإظهار والإدغام مع غنّة.',
    0xFF2E6F4E, // forest‑green — same family, a darker value than ghunnah
    0xFF66B98A,
  ),
  TajweedCategory(
    'qalqalah',
    'القلقلة',
    'اضطراب المخرج عند النطق بحرف من «قُطْبُ جَدٍّ» ساكنًا حتى تُسمع نبرة.',
    0xFF25506E, // deep muted blue — a percussive beat, not a stretch
    0xFF6FA8CE,
  ),
  TajweedCategory(
    'idghaam',
    'الإدغام',
    'إدخال حرف ساكن في متحرّك بعده فيصيران حرفًا واحدًا مشدّدًا.',
    0xFF5B6570, // slate‑grey — the letter steps back into the next
    0xFF9AA4B0,
  ),
  TajweedCategory(
    'silent',
    'حرف لا يُنطق',
    'حرف يُرسم ولا يُلفظ — كهمزة الوصل، ولام «الـ» الشمسية، وحروف الصلة.',
    0xFF8A8072, // warm stone‑grey, the faintest — the eye skips it too
    0xFFB9AFA0,
  ),
];

/// cpfair rule id → category key. All 18 ids map to one of the six.
const Map<String, String> kTajweedRuleCategory = {
  // المدّ
  'madd_2': 'madd',
  'madd_246': 'madd',
  'madd_6': 'madd',
  'madd_muttasil': 'madd',
  'madd_munfasil': 'madd',
  // الغُنّة (نأو مشدّدة / إدغام بغنّة / إقلاب)
  'ghunnah': 'ghunnah',
  'idghaam_ghunnah': 'ghunnah',
  'iqlab': 'ghunnah',
  // الإخفاء
  'ikhfa': 'ikhfa',
  'ikhfa_shafawi': 'ikhfa',
  // القلقلة
  'qalqalah': 'qalqalah',
  // الإدغام (بغير غنّة / متجانس / متقارب / شفوي)
  'idghaam_no_ghunnah': 'idghaam',
  'idghaam_mutajanisayn': 'idghaam',
  'idghaam_mutaqaribayn': 'idghaam',
  'idghaam_shafawi': 'idghaam',
  // حرف لا يُنطق
  'silent': 'silent',
  'hamzat_wasl': 'silent',
  'lam_shamsiyyah': 'silent',
};

final Map<String, TajweedCategory> _byKey = {
  for (final c in kTajweedCategories) c.key: c,
};

class TajweedPalette {
  const TajweedPalette._();

  /// The category a cpfair rule id belongs to (defaults to `silent` for an
  /// unknown id — never expected; the build tool validates against the 18).
  static TajweedCategory categoryForRule(String ruleId) =>
      _byKey[kTajweedRuleCategory[ruleId] ?? 'silent'] ?? _byKey['silent']!;

  static TajweedCategory? byKey(String key) => _byKey[key];

  /// Hex `#RRGGBB` for the rule's category, for SVG `fill` injection.
  static String hexForRule(String ruleId, {required bool night}) =>
      categoryForRule(ruleId).hex(night: night);
}
