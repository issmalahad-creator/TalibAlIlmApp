import 'package:flutter/material.dart';

import '../data/salah_content.dart';
import '../theme/app_theme.dart';

/// External book recommendations for learners who want scholar-authored
/// depth beyond this app's own library — citation only, no bundled or
/// reproduced content, same pattern as every other resources screen here.
class SalahResourcesScreen extends StatelessWidget {
  const SalahResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مصادر موصى بها')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'مكتبة هذا التطبيق تعطيك أساسًا عمليًا لإقامة الصلاة. للتعمق أكثر، هذه كتب موثوقة يُنصح بها:',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...recommendedSalahResources.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.titleAr, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
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
