import '../data/tajweed_rules_ref.dart';

/// Phase G-t · one tajwīd rule occurrence: a half-open `[cs, ce)` char range
/// inside word `wordIndex` of some ayah, tagged with a cpfair rule id.
///
/// Built by `tool/build_tajweed_rules.py` (cpfair/quran-tajweed, CC BY 4.0),
/// stored per ayah in `quran_tajweed.data` as `{"w":..,"cs":..,"ce":..,"r":".."}`
/// and read by [QuranCorpusRepository.tajweedForAyah] / `tajweedForWord`.
class TajweedSpan {
  final int wordIndex;
  final int cs;
  final int ce;
  final String ruleId;

  const TajweedSpan({
    required this.wordIndex,
    required this.cs,
    required this.ce,
    required this.ruleId,
  });

  factory TajweedSpan.fromJson(Map<String, dynamic> m) => TajweedSpan(
        wordIndex: (m['w'] as num).toInt(),
        cs: (m['cs'] as num).toInt(),
        ce: (m['ce'] as num).toInt(),
        ruleId: m['r'] as String,
      );

  TajweedRuleRef? get ref => kTajweedRules[ruleId];

  /// Colour family key (`tajweed_palette.dart`); `silent` if the id is
  /// unknown (never expected — the build tool validates against the 18).
  String get familyKey => ref?.familyKey ?? 'silent';

  String get ruleAr => ref?.ruleAr ?? ruleId;
}

/// All tajwīd spans for one ayah, plus grouping helpers for the knowledge
/// surface (rules grouped by family) and, later, the on-page overlay.
class AyahTajweed {
  final int surah;
  final int ayah;
  final List<TajweedSpan> spans;

  const AyahTajweed({
    required this.surah,
    required this.ayah,
    required this.spans,
  });

  bool get isEmpty => spans.isEmpty;
  bool get isNotEmpty => spans.isNotEmpty;

  List<TajweedSpan> forWord(int wordIndex) =>
      spans.where((s) => s.wordIndex == wordIndex).toList();

  /// Distinct rule ids present, in the canonical family order of
  /// [kTajweedRules] (stable legend / list order).
  List<String> get distinctRuleIds {
    final present = spans.map((s) => s.ruleId).toSet();
    return [for (final id in kTajweedRules.keys) if (present.contains(id)) id];
  }

  /// `familyKey -> [rule id, ...]` for the rules actually present, families
  /// in [kTajweedFamilies] order.
  Map<String, List<String>> get ruleIdsByFamily {
    final out = <String, List<String>>{};
    for (final id in distinctRuleIds) {
      final fam = kTajweedRules[id]?.familyKey ?? 'silent';
      (out[fam] ??= <String>[]).add(id);
    }
    return {
      for (final (fam, _) in kTajweedFamilies)
        if (out.containsKey(fam)) fam: out[fam]!,
    };
  }
}
