import 'package:flutter/material.dart';

import '../data/tajweed_curriculum.dart';
import '../theme/app_theme.dart';

/// External classical-text recommendations for learners who want the
/// traditional memorized-poem route beyond this app's own curriculum —
/// citation only, no bundled/reproduced verses.
class TajweedResourcesScreen extends StatelessWidget {
  const TajweedResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مصادر موصى بها')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'قواعد هذا المنهج تعطيك أساسًا عمليًا لتطبيق التجويد. للإتقان الكامل والإجازة، هذان المتنان الكلاسيكيان هما الطريق التقليدي المتّبع منذ قرون:',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...recommendedTajweedResources.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.titleAr, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text(r.titleEn, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                    Text('المؤلف: ${r.authorAr}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(r.noteAr, style: const TextStyle(fontSize: 12.5, height: 1.6)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
