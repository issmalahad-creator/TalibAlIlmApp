import 'package:flutter/material.dart';

import '../data/salah_content.dart';
import '../theme/app_theme.dart';

/// "قصص الأولين في الصلاة" — Ismail's request 2026-08-16. Well-known
/// accounts of the Salaf's khushu, presented honestly as widely-circulated
/// stories rather than precisely chain-verified narrations.
class SalahStoriesScreen extends StatelessWidget {
  const SalahStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قصص الأولين في الصلاة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'قصص مشهورة متداولة في كتب السيرة والزهد عن خشوع السلف في صلاتهم — لتكون تذكيرًا وقدوة، لا نصًا حديثيًا مُدقَّق السند.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...salafStories.map((story) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(story.titleAr, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(story.bodyAr, style: const TextStyle(fontSize: 13.5, height: 1.8)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
