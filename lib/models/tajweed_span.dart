import '../data/tajweed_rules_ref.dart';
import '../theme/tajweed_palette.dart';

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

  /// Colour category key (`tajweed_palette.dart`, 6 categories); `silent`
  /// for an unknown id (never expected — the build tool validates the 18).
  String get categoryKey => kTajweedRuleCategory[ruleId] ?? 'silent';

  String get ruleAr => ref?.ruleAr ?? ruleId;
}

/// All tajwīd spans for one ayah, plus grouping helpers for the knowledge
/// surface (rules grouped by colour category).
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

  /// Distinct rule ids present, in the canonical order of [kTajweedRules]
  /// (stable list order).
  List<String> get distinctRuleIds {
    final present = spans.map((s) => s.ruleId).toSet();
    return [for (final id in kTajweedRules.keys) if (present.contains(id)) id];
  }

  /// `categoryKey -> [rule id, ...]` for the rules actually present,
  /// categories in [kTajweedCategories] order.
  Map<String, List<String>> get ruleIdsByCategory {
    final out = <String, List<String>>{};
    for (final id in distinctRuleIds) {
      final cat = kTajweedRuleCategory[id] ?? 'silent';
      (out[cat] ??= <String>[]).add(id);
    }
    return {
      for (final c in kTajweedCategories)
        if (out.containsKey(c.key)) c.key: out[c.key]!,
    };
  }
}
