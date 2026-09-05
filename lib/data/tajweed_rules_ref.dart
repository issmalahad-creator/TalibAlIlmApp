import '../data/tajweed_curriculum.dart';

/// Phase G-t · the single reference for cpfair/quran-tajweed's 18 rule ids:
/// Arabic label, colour **family** (six — see `tajweed_palette.dart`),
/// learning-concept id, and the curriculum rule it maps to (so a rule on
/// the muṣḥaf links to its lesson in `tajweedTiers`).
///
/// This replaces the ad-hoc `TAJWEED_META` map that lived inside
/// `tool/build_quran_learning_prototype.py`; the build tool
/// (`tool/build_tajweed_rules.py`) only emits the raw rule id — every label,
/// colour and link is resolved here at render time.
class TajweedRuleRef {
  final String id;
  final String ruleAr;
  final String familyKey;
  final String conceptId;

  /// The `tajweedTiers` tier this rule is taught in, and that tier rule's
  /// `titleAr` — together they form `TajweedRepository`'s progress key
  /// (`'${tier.key}_$tierRuleTitleAr'`). Null for the ~6 rules with no
  /// direct curriculum entry (hamzat al-waṣl, lām shamsiyyah, the two
  /// same/close-makhraj idghām rules, silent) — those just carry a label.
  final String? tierKey;
  final String? tierRuleTitleAr;

  const TajweedRuleRef(this.id, this.ruleAr, this.familyKey, this.conceptId,
      {this.tierKey, this.tierRuleTitleAr});

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

/// All 18 cpfair rule ids. Order groups them by family for a stable legend.
const Map<String, TajweedRuleRef> kTajweedRules = {
  // ── أحكام النون الساكنة والتنوين + الإدغام ──
  'ikhfa': TajweedRuleRef('ikhfa', 'إخفاء حقيقي', 'noon_tanwin',
      'concept:tajweed:ikhfa', tierKey: 'basic', tierRuleTitleAr: 'الإخفاء الحقيقي'),
  'iqlab': TajweedRuleRef('iqlab', 'إقلاب', 'noon_tanwin',
      'concept:tajweed:iqlab', tierKey: 'basic', tierRuleTitleAr: 'الإقلاب'),
  'idghaam_ghunnah': TajweedRuleRef('idghaam_ghunnah', 'إدغام بغنّة',
      'noon_tanwin', 'concept:tajweed:idgham_ghunnah',
      tierKey: 'basic', tierRuleTitleAr: 'الإدغام'),
  'idghaam_no_ghunnah': TajweedRuleRef('idghaam_no_ghunnah', 'إدغام بغير غنّة',
      'noon_tanwin', 'concept:tajweed:idgham_no_ghunnah',
      tierKey: 'basic', tierRuleTitleAr: 'الإدغام'),
  'idghaam_mutajanisayn': TajweedRuleRef('idghaam_mutajanisayn',
      'إدغام متجانسين', 'noon_tanwin', 'concept:tajweed:idgham_mutajanisayn'),
  'idghaam_mutaqaribayn': TajweedRuleRef('idghaam_mutaqaribayn',
      'إدغام متقاربين', 'noon_tanwin', 'concept:tajweed:idgham_mutaqaribayn'),

  // ── أحكام الميم الساكنة ──
  'ikhfa_shafawi': TajweedRuleRef('ikhfa_shafawi', 'إخفاء شفوي', 'meem_sakina',
      'concept:tajweed:ikhfa_shafawi',
      tierKey: 'intermediate', tierRuleTitleAr: 'الإخفاء الشفوي'),
  'idghaam_shafawi': TajweedRuleRef('idghaam_shafawi', 'إدغام شفوي',
      'meem_sakina', 'concept:tajweed:idgham_shafawi',
      tierKey: 'intermediate', tierRuleTitleAr: 'الإدغام الشفوي'),

  // ── المدود ──
  'madd_2': TajweedRuleRef('madd_2', 'مدّ طبيعي (حركتان)', 'madd',
      'concept:tajweed:madd_tabee',
      tierKey: 'advanced', tierRuleTitleAr: 'المد الطبيعي'),
  'madd_246': TajweedRuleRef('madd_246', 'مدّ عارض / لين (٢ أو ٤ أو ٦)', 'madd',
      'concept:tajweed:madd_aarid',
      tierKey: 'advanced', tierRuleTitleAr: 'المد العارض للسكون'),
  'madd_6': TajweedRuleRef('madd_6', 'مدّ لازم (٦ حركات)', 'madd',
      'concept:tajweed:madd_lazim',
      tierKey: 'advanced', tierRuleTitleAr: 'المد اللازم'),
  'madd_muttasil': TajweedRuleRef('madd_muttasil', 'مدّ متّصل واجب', 'madd',
      'concept:tajweed:madd_muttasil',
      tierKey: 'advanced', tierRuleTitleAr: 'المد المتصل'),
  'madd_munfasil': TajweedRuleRef('madd_munfasil', 'مدّ منفصل جائز', 'madd',
      'concept:tajweed:madd_munfasil',
      tierKey: 'advanced', tierRuleTitleAr: 'المد المنفصل'),

  // ── الغنّة والقلقلة ──
  'ghunnah': TajweedRuleRef('ghunnah', 'غنّة', 'ghunnah_qalqalah',
      'concept:tajweed:ghunnah'),
  'qalqalah': TajweedRuleRef('qalqalah', 'قلقلة', 'ghunnah_qalqalah',
      'concept:tajweed:qalqalah',
      tierKey: 'intermediate', tierRuleTitleAr: 'القلقلة'),

  // ── اللام والهمزة ──
  'lam_shamsiyyah': TajweedRuleRef('lam_shamsiyyah', 'اللام الشمسية',
      'lam_hamza', 'concept:tajweed:lam_shamsiyyah'),
  'hamzat_wasl': TajweedRuleRef('hamzat_wasl', 'همزة الوصل', 'lam_hamza',
      'concept:tajweed:hamzat_wasl'),

  // ── حرف لا يُنطق ──
  'silent': TajweedRuleRef('silent', 'حرف لا يُنطق', 'silent',
      'concept:tajweed:silent'),
};

/// The six families, in legend order, with their l10n label key.
const List<(String key, String l10nKey)> kTajweedFamilies = [
  ('noon_tanwin', 'ql_tajfam_noon_tanwin'),
  ('meem_sakina', 'ql_tajfam_meem_sakina'),
  ('madd', 'ql_tajfam_madd'),
  ('ghunnah_qalqalah', 'ql_tajfam_ghunnah_qalqalah'),
  ('lam_hamza', 'ql_tajfam_lam_hamza'),
  ('silent', 'ql_tajfam_silent'),
];
