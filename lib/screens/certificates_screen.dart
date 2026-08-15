import 'package:flutter/material.dart';

import '../repositories/milestone_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';

/// "شهاداتي" — QURAN_COMPANION_ROADMAP.md §4.14. Shows EVERY possible
/// certificate at once (achieved in full color, locked greyed with a
/// 🔒 + unlock hint) so the whole reward map is visible from day one,
/// building anticipation rather than surprising the student only after
/// completion.
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final _repo = MilestoneRepository();
  List<Milestone> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.all();
    if (!mounted) return;
    setState(() {
      _all = all;
      _loading = false;
    });
  }

  Future<void> _onTap(Milestone m) async {
    if (m.isAchieved) {
      await showCelebration(context, m);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🔒 أكمل "${m.title.replaceFirst('شهادة ', '')}" لتفتح هذه الشهادة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final byType = <String, List<Milestone>>{};
    for (final m in _all) {
      byType.putIfAbsent(m.milestoneType, () => []).add(m);
    }
    final earnedCount = _all.where((m) => m.isAchieved).length;

    return Scaffold(
      appBar: AppBar(title: const Text('شهاداتي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('حصلت على $earnedCount من ${_all.length} شهادة', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          _section('ختم القرآن الكريم كاملًا', byType['full_quran'] ?? []),
          _section('الأربعون النووية كاملة', byType['full_arbain'] ?? []),
          _section('دفعات الأحاديث', byType['ten_hadiths'] ?? []),
          _section('استمرارية أذكار الصباح والمساء', [
            ...byType['adhkar_streak_7'] ?? [],
            ...byType['adhkar_streak_30'] ?? [],
            ...byType['adhkar_streak_100'] ?? [],
          ]),
          _section('الأجزاء', byType['juz'] ?? []),
          _section('السور', byType['surah'] ?? []),
          _section('منهج تعلم العربية', byType['stage_alphabet'] ?? []),
          _section('دفتر فوائد الصوتيات', [
            ...byType['audio_reflections_1'] ?? [],
            ...byType['audio_reflections_10'] ?? [],
            ...byType['audio_reflections_50'] ?? [],
          ]),
          _section('التجويد', [
            ...byType['tajweed_basic'] ?? [],
            ...byType['tajweed_intermediate'] ?? [],
            ...byType['tajweed_advanced'] ?? [],
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Milestone> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((m) => _MilestoneChip(milestone: m, onTap: () => _onTap(m))).toList(),
          ),
        ],
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  final Milestone milestone;
  final VoidCallback onTap;
  const _MilestoneChip({required this.milestone, required this.onTap});

  bool get _wide => milestone.milestoneType == 'full_quran' || milestone.milestoneType == 'full_arbain';

  String get _label => switch (milestone.milestoneType) {
        'surah' || 'juz' => '${milestone.referenceId}',
        _ => milestone.title,
      };

  @override
  Widget build(BuildContext context) {
    final achieved = milestone.isAchieved;
    return Tooltip(
      message: milestone.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: _wide ? double.infinity : 56,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: achieved ? AppColors.primaryLight : AppColors.divider.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: achieved ? AppColors.primary : AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                achieved ? Icons.emoji_events : Icons.lock_outline,
                size: 18,
                color: achieved ? AppColors.primaryDark : AppColors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                _label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: achieved ? AppColors.primaryDark : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
