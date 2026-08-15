import 'package:flutter/material.dart';

import '../data/tajweed_curriculum.dart';
import '../repositories/tajweed_repository.dart';
import '../theme/app_theme.dart';
import 'tajweed_resources_screen.dart';
import 'tajweed_tier_screen.dart';

/// "التجويد" — QURAN_COMPANION_ROADMAP.md Phase 11. Three tiers, each a
/// full lesson set from day one (unlike the Arabic curriculum's phased
/// build) — basic (makharij + noon sakinah rules), intermediate (meem
/// sakinah + qalqalah + tafkheem/tarqeeq), advanced (madd types + waqf).
class TajweedScreen extends StatefulWidget {
  const TajweedScreen({super.key});

  @override
  State<TajweedScreen> createState() => _TajweedScreenState();
}

class _TajweedScreenState extends State<TajweedScreen> {
  final _repo = TajweedRepository();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التجويد')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'ثلاثة مستويات — من مخارج الحروف الأساسية إلى أنواع المدّ وأحكام الوقف',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                ...tajweedTiers.map((tier) {
                  final learnedCount = tier.rules.where((r) => _learned.contains('${tier.key}_${r.titleAr}')).length;
                  return InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => TajweedTierScreen(tier: tier)));
                      _load();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tier.titleAr, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(tier.descriptionAr, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 10),
                          Text('$learnedCount من ${tier.rules.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TajweedResourcesScreen())),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('مصادر موصى بها للدراسة الأعمق'),
                ),
              ],
            ),
    );
  }
}
