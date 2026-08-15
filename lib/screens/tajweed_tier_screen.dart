import 'package:flutter/material.dart';

import '../data/tajweed_curriculum.dart';
import '../repositories/milestone_repository.dart';
import '../repositories/tajweed_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';

/// Rule list for one Tajweed tier — mark each rule learned; once every
/// rule in the tier is learned, the tier-completion certificate fires.
class TajweedTierScreen extends StatefulWidget {
  final TajweedTier tier;
  const TajweedTierScreen({super.key, required this.tier});

  @override
  State<TajweedTierScreen> createState() => _TajweedTierScreenState();
}

class _TajweedTierScreenState extends State<TajweedTierScreen> {
  final _repo = TajweedRepository();
  final _milestoneRepo = MilestoneRepository();
  Set<String> _learned = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final learned = await _repo.learnedKeys();
    if (!mounted) return;
    setState(() {
      _learned = learned;
      _loading = false;
    });
  }

  Future<void> _toggle(TajweedRule rule) async {
    final key = '${widget.tier.key}_${rule.titleAr}';
    if (_learned.contains(key)) return;
    await _repo.markLearned(key);
    final newLearned = {..._learned, key};
    setState(() => _learned = newLearned);

    final complete = widget.tier.rules.every((r) => newLearned.contains('${widget.tier.key}_${r.titleAr}'));
    if (!complete) return;
    final newlyEarned = await _milestoneRepo.checkTajweedMilestones(widget.tier.key);
    for (final milestone in newlyEarned) {
      if (!mounted) return;
      await showCelebration(context, milestone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tier.titleAr)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: widget.tier.rules
                  .map((rule) => InkWell(
                        onTap: () => _toggle(rule),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _learned.contains('${widget.tier.key}_${rule.titleAr}') ? AppColors.primaryLight : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _learned.contains('${widget.tier.key}_${rule.titleAr}') ? AppColors.primary : AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text('${rule.titleAr} (${rule.titleEn})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                                  Icon(
                                    _learned.contains('${widget.tier.key}_${rule.titleAr}') ? Icons.check_circle : Icons.circle_outlined,
                                    size: 18,
                                    color: _learned.contains('${widget.tier.key}_${rule.titleAr}') ? AppColors.primary : AppColors.textMuted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(rule.explanationEn, style: const TextStyle(fontSize: 12.5, height: 1.6)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rule.exampleAr, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(rule.exampleNote, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}
