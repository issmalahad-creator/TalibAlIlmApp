import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import 'app_feature_registry.dart';
import 'language_preference_service.dart';

class CompanionNavigationTarget {
  final List<String> names;
  final String displayName;
  final WidgetBuilder builder;
  const CompanionNavigationTarget({required this.names, required this.displayName, required this.builder});
}

/// "علّمه كل الكلمات المكتوبة في التطبيق... اعطه القدرة للذهاب الى ذلك
/// المكان وبس" (Ismail, 2026-08-18) — a name→screen registry so the
/// companion chat can actually navigate somewhere, not just talk about it.
///
/// Since 2026-10-30 it is derived from `appFeatures`, the same list the side
/// menu shows, so every feature in the menu is reachable from the chat too
/// («افتح علاجاتي», «وين جدول الحفظ»). Each target matches on its
/// title in Arabic, English and the current UI language, plus the feature's
/// own extra names; `companion_chat_session.dart` normalizes and picks the
/// best (most specific) match.
List<CompanionNavigationTarget> get companionNavigationTargets {
  final lang = LanguagePreferenceService.currentLanguage;
  return [
    for (final f in appFeatures)
      CompanionNavigationTarget(
        names: {
          basicText(f.titleKey, 'ar'),
          basicText(f.titleKey, 'en').toLowerCase(),
          basicText(f.titleKey, lang),
          ...f.names,
        }.toList(),
        displayName: basicText(f.titleKey, lang),
        builder: f.builder,
      ),
  ];
}
