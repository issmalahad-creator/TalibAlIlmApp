import '../data/tajweed_curriculum.dart';
import '../theme/tajweed_palette.dart';

/// Phase G-t · the single reference for cpfair/quran-tajweed's 18 rule ids:
/// Arabic label, learning‑concept id, and the curriculum rule it maps to.
/// The **colour category** is resolved from `kTajweedRuleCategory`
/// (`tajweed_palette.dart`) — the six‑category Quran‑reading palette — so
/// colour and label have one source each.
class TajweedRuleRef {
  final String id;
  final String ruleAr;
  final String conceptId;

  /// The `tajweedTiers` tier this rule is taught in, and that tier rule's
  /// `titleAr` — together they form `TajweedRepository`'s progress key
  /// (`'${tier.key}_$tierRuleTitleAr'`). Null for the rules with no direct
  /// curriculum entry (hamzat al‑waṣl, lām shamsiyyah, the two same/close‑
  /// makhraj idghām rules, silent).
  final String? tierKey;
  final String? tierRuleTitleAr;

  const TajweedRuleRef(this.id, this.ruleAr, this.conceptId,
      {this.tierKey, this.tierRuleTitleAr});

  /// Colour category key (`madd` · `ghunnah` · `ikhfa` · `qalqalah` ·
  /// `idghaam` · `silent`).
  String get categoryKey => kTajweedRuleCategory[id] ?? 'silent';
  TajweedCategory get category => TajweedPalette.categoryForRule(id);

  String? get tierProgressKey =>
      (tierKey != null && tierRuleTitleAr != null)
          ? '${tierKey}_$tierRuleTitleAr'
          : null;

  /// The `TajweedTier` object for navigation to `TajweedTierScreen`, or null.
  TajweedTier? get tier {
    if (tierKey == null) return null;
    for (final t in tajweedTiers) {
      if (t.key == tierKey) return t;
    }
    return null;
  }
}

/// All 18 cpfair rule ids → label + concept + curriculum link. Colour comes
/// from `kTajweedRuleCategory`.
const Map<String, TajweedRuleRef> kTajweedRules = {
  'ikhfa': TajweedRuleRef('ikhfa', 'إخفاء حقيقي', 'concept:tajweed:ikhfa',
      tierKey: 'basic', tierRuleTitleAr: 'الإخفاء الحقيقي'),
  'iqlab': TajweedRuleRef('iqlab', 'إقلاب', 'concept:tajweed:iqlab',
      tierKey: 'basic', tierRuleTitleAr: 'الإقلاب'),
  'idghaam_ghunnah': TajweedRuleRef('idghaam_ghunnah', 'إدغام بغنّة',
      'concept:tajweed:idgham_ghunnah',
      tierKey: 'basic', tierRuleTitleAr: 'الإدغام'),
  'idghaam_no_ghunnah': TajweedRuleRef('idghaam_no_ghunnah', 'إدغام بغير غنّة',
      'concept:tajweed:idgham_no_ghunnah',
      tierKey: 'basic', tierRuleTitleAr: 'الإدغام'),
  'idghaam_mutajanisayn': TajweedRuleRef('idghaam_mutajanisayn',
      'إدغام متجانسين', 'concept:tajweed:idgham_mutajanisayn'),
  'idghaam_mutaqaribayn': TajweedRuleRef('idghaam_mutaqaribayn',
      'إدغام متقاربين', 'concept:tajweed:idgham_mutaqaribayn'),
  'ikhfa_shafawi': TajweedRuleRef('ikhfa_shafawi', 'إخفاء شفوي',
      'concept:tajweed:ikhfa_shafawi',
      tierKey: 'intermediate', tierRuleTitleAr: 'الإخفاء الشفوي'),
  'idghaam_shafawi': TajweedRuleRef('idghaam_shafawi', 'إدغام شفوي',
      'concept:tajweed:idgham_shafawi',
      tierKey: 'intermediate', tierRuleTitleAr: 'الإدغام الشفوي'),
  'madd_2': TajweedRuleRef('madd_2', 'مدّ طبيعي (حركتان)',
      'concept:tajweed:madd_tabee',
      tierKey: 'advanced', tierRuleTitleAr: 'المد الطبيعي'),
  'madd_246': TajweedRuleRef('madd_246', 'مدّ عارض / لين (٢ أو ٤ أو ٦)',
      'concept:tajweed:madd_aarid',
      tierKey: 'advanced', tierRuleTitleAr: 'المد العارض للسكون'),
  'madd_6': TajweedRuleRef('madd_6', 'مدّ لازم (٦ حركات)',
      'concept:tajweed:madd_lazim',
      tierKey: 'advanced', tierRuleTitleAr: 'المد اللازم'),
  'madd_muttasil': TajweedRuleRef('madd_muttasil', 'مدّ متّصل واجب',
      'concept:tajweed:madd_muttasil',
      tierKey: 'advanced', tierRuleTitleAr: 'المد المتصل'),
  'madd_munfasil': TajweedRuleRef('madd_munfasil', 'مدّ منفصل جائز',
      'concept:tajweed:madd_munfasil',
      tierKey: 'advanced', tierRuleTitleAr: 'المد المنفصل'),
  'ghunnah': TajweedRuleRef('ghunnah', 'غنّة', 'concept:tajweed:ghunnah'),
  'qalqalah': TajweedRuleRef('qalqalah', 'قلقلة', 'concept:tajweed:qalqalah',
      tierKey: 'intermediate', tierRuleTitleAr: 'القلقلة'),
  'lam_shamsiyyah': TajweedRuleRef('lam_shamsiyyah', 'اللام الشمسية',
      'concept:tajweed:lam_shamsiyyah'),
  'hamzat_wasl': TajweedRuleRef('hamzat_wasl', 'همزة الوصل',
      'concept:tajweed:hamzat_wasl'),
  'silent': TajweedRuleRef('silent', 'حرف لا يُنطق', 'concept:tajweed:silent'),
};
