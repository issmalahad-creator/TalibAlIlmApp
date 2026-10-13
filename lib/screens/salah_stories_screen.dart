import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';

import '../data/salah_content.dart';
import '../theme/app_theme.dart';

/// This screen's strings — `basicText` in the current app language.
String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);


/// "قصص الأولين في الصلاة" — Ismail's request 2026-08-16. Well-known
/// accounts of the Salaf's khushu, presented honestly as widely-circulated
/// stories rather than precisely chain-verified narrations.
class SalahStoriesScreen extends StatelessWidget {
  const SalahStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t('x_salah_stories'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _t('x_salah_stories_intro'),
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
