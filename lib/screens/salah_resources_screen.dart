import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';

import '../data/salah_content.dart';
import '../theme/app_theme.dart';

/// This screen's strings — `basicText` in the current app language.
String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);


/// External book recommendations for learners who want scholar-authored
/// depth beyond this app's own library — citation only, no bundled or
/// reproduced content, same pattern as every other resources screen here.
class SalahResourcesScreen extends StatelessWidget {
  const SalahResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t('x_recommended'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _t('x_salah_res_intro'),
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
                    Text(_t('x_author').replaceAll('{a}', r.authorAr), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
