import '../l10n/basic_translations.dart';
import '../models/life_plan.dart';

/// General starting suggestions for «مُحرّك الحياة» (Ismail 2026‑11‑12:
/// «فارغة مع اقتراحات»). A new user's plan starts EMPTY; these are offered,
/// each one a pillar + its time-blocks, and the user picks what fits. All
/// are ordinary editable rows once added — nothing here is privileged.
///
/// Labels are resolved in the user's language at the moment of adding
/// (the plan stores text, like everything the user types in the editor).
class LifeSuggestionPack {
  /// Stable pillar key, `sug_*` — lets the picker hide packs already added.
  final String key;
  final String emoji;
  final String labelKey;
  final String targetKey;
  final LifeCadence cadence;
  final int weeklyTarget;

  /// (startMin, endMin, activity l10n key)
  final List<(int, int, String)> blocks;

  const LifeSuggestionPack({
    required this.key,
    required this.emoji,
    required this.labelKey,
    required this.targetKey,
    this.cadence = LifeCadence.daily,
    this.weeklyTarget = 0,
    required this.blocks,
  });

  String label(String lang) => basicText(labelKey, lang);

  LifePillar pillar(String lang, {required int sort}) => LifePillar(
        key: key,
        label: '$emoji ${label(lang)}',
        emoji: emoji,
        targetText: basicText(targetKey, lang),
        cadence: cadence,
        weeklyTarget: weeklyTarget,
        sort: sort,
      );

  /// The blocks as new slots (`slotNo: 0` → the repository allocates ids).
  List<LifeSlot> slots(String lang) => [
        for (final b in blocks)
          LifeSlot(
            slotNo: 0,
            startMin: b.$1,
            endMin: b.$2,
            activity: '$emoji ${basicText(b.$3, lang)}',
            mihwar: label(lang),
            pillarKey: key,
            sort: 0,
          ),
      ];
}

const List<LifeSuggestionPack> kLifeSuggestionPacks = [
  LifeSuggestionPack(
    key: 'sug_salah',
    emoji: '🕌',
    labelKey: 'life_sug_salah',
    targetKey: 'life_sug_t_daily',
    blocks: [(300, 320, 'life_sug_s_fajr'), (1020, 1035, 'life_sug_s_evening')],
  ),
  LifeSuggestionPack(
    key: 'sug_quran',
    emoji: '📖',
    labelKey: 'life_sug_quran',
    targetKey: 'life_sug_t_daily',
    blocks: [(320, 350, 'life_sug_s_wird'), (1200, 1230, 'life_sug_s_review')],
  ),
  LifeSuggestionPack(
    key: 'sug_health',
    emoji: '🏃',
    labelKey: 'life_sug_health',
    targetKey: 'life_sug_t_week3',
    cadence: LifeCadence.weekly,
    weeklyTarget: 3,
    blocks: [(390, 420, 'life_sug_s_sport')],
  ),
  LifeSuggestionPack(
    key: 'sug_work',
    emoji: '💼',
    labelKey: 'life_sug_work',
    targetKey: 'life_sug_t_daily',
    blocks: [(540, 720, 'life_sug_s_work')],
  ),
  LifeSuggestionPack(
    key: 'sug_family',
    emoji: '🏡',
    labelKey: 'life_sug_family',
    targetKey: 'life_sug_t_week3',
    cadence: LifeCadence.weekly,
    weeklyTarget: 3,
    blocks: [(1170, 1200, 'life_sug_s_family')],
  ),
  LifeSuggestionPack(
    key: 'sug_ilm',
    emoji: '📚',
    labelKey: 'life_sug_ilm',
    targetKey: 'life_sug_t_daily',
    blocks: [(1260, 1290, 'life_sug_s_learn')],
  ),
  LifeSuggestionPack(
    key: 'sug_sleep',
    emoji: '😴',
    labelKey: 'life_sug_sleep',
    targetKey: 'life_sug_t_daily',
    blocks: [(1320, 1335, 'life_sug_s_sleep')],
  ),
];
