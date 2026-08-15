class PersonalAccountability {
  final bool rewardEnabled;
  final String rewardText;
  final bool punishmentEnabled;
  final String punishmentText;

  const PersonalAccountability({
    this.rewardEnabled = false,
    this.rewardText = '',
    this.punishmentEnabled = false,
    this.punishmentText = '',
  });

  Map<String, Object?> toMap() => {
        'id': 1,
        'reward_enabled': rewardEnabled ? 1 : 0,
        'reward_text': rewardText,
        'punishment_enabled': punishmentEnabled ? 1 : 0,
        'punishment_text': punishmentText,
      };

  factory PersonalAccountability.fromMap(Map<String, Object?> map) => PersonalAccountability(
        rewardEnabled: (map['reward_enabled'] as int? ?? 0) == 1,
        rewardText: map['reward_text'] as String? ?? '',
        punishmentEnabled: (map['punishment_enabled'] as int? ?? 0) == 1,
        punishmentText: map['punishment_text'] as String? ?? '',
      );
}
