import 'package:flutter/material.dart';

import '../repositories/knowledge_review_repository.dart';
import '../repositories/memorization_repository.dart';
import '../screens/knowledge_review_screen.dart';
import '../theme/app_theme.dart';

/// Home-screen entry point for "مراجعتك اليوم" (Batch 1's cross-pillar
/// review engine) — same self-contained load-on-init pattern as
/// `DailyJourneyCard`. Hides itself entirely when nothing is due, so it
/// never adds a permanent "0" row to the home screen.
class KnowledgeReviewEntryCard extends StatefulWidget {
  const KnowledgeReviewEntryCard({super.key});

  @override
  State<KnowledgeReviewEntryCard> createState() => _KnowledgeReviewEntryCardState();
}

class _KnowledgeReviewEntryCardState extends State<KnowledgeReviewEntryCard> {
  bool _loading = true;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final quranDue = await MemorizationRepository().dueToday();
    final reviewDue = await KnowledgeReviewRepository().dueTodayAll();
    final total = quranDue.length + reviewDue.values.fold<int>(0, (sum, list) => sum + list.length);
    if (!mounted) return;
    setState(() {
      _total = total;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _total == 0) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeReviewScreen()));
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryLight),
              child: const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مراجعتك اليوم', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('$_total عنصرًا يستحق المراجعة', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
