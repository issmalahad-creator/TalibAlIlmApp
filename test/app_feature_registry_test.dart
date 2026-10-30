import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/services/app_feature_registry.dart';
import 'package:talib_alilm_app/services/companion_chat_session.dart';
import 'package:talib_alilm_app/services/companion_navigation_registry.dart';
import 'package:talib_alilm_app/services/drawer_prefs.dart';
import 'package:talib_alilm_app/utils/arabic_normalize.dart';

/// The side menu and the companion read one feature list — it must be
/// complete, translated, and match what people actually type.
void main() {
  const langs = ['ar', 'en', 'am', 'fr', 'sw', 'ur', 'tr', 'id', 'bn', 'ha', 'so', 'fa', 'ms'];

  test('feature ids are unique and every title and section is translated', () {
    expect(appFeatures.map((f) => f.id).toSet().length, appFeatures.length);
    for (final f in appFeatures) {
      for (final l in langs) {
        expect(basicText(f.titleKey, l), isNot(f.titleKey), reason: '${f.id}/$l');
      }
    }
    for (final g in AppFeatureGroup.values) {
      expect(appFeatures.any((f) => f.group == g), isTrue, reason: g.name);
      expect(basicText('feat_group_${g.name}', 'en'), isNot('feat_group_${g.name}'));
    }
  });

  group('companion «افتح …» picks the most specific feature', () {
    String n(String s) => normalizeArabicForSearch(s).toLowerCase();
    final targets = companionNavigationTargets;
    String? open(String q) {
      final t = bestNavigationTarget(n(q), targets, n);
      return t == null ? null : appFeatures[targets.indexOf(t)].id;
    }

    test('names reach their screens', () {
      expect(open('علاجاتي'), 'medications');
      expect(open('منبه الأدوية'), 'medications');
      expect(open('البحث في القرآن'), 'quran_search');
      expect(open('القرآن'), 'mushaf');
      expect(open('جدول الحفظ'), 'hifz_schedule');
      expect(open('القبله'), 'qibla');
      expect(open('prayer times'), 'prayer_times');
      expect(open('my medicines'), 'medications');
    });

    test('unknown text matches nothing', () {
      expect(open('xyzzy'), isNull);
      expect(open(''), isNull);
    });
  });

  group('side menu shortcuts', () {
    test('recent: newest first, no duplicates, at most 3', () {
      expect(pushRecent(const [], 'qibla'), ['qibla']);
      expect(pushRecent(const ['qibla', 'mushaf'], 'mushaf'), ['mushaf', 'qibla']);
      expect(pushRecent(const ['a', 'b', 'c'], 'd'), ['d', 'a', 'b']);
    });

    test('pin toggles, survives, and ids that no longer exist are dropped', () async {
      SharedPreferences.setMockInitialValues({'drawer_pinned': ['gone_feature', 'qibla']});
      final prefs = DrawerPrefs();
      expect(await prefs.pinned(), ['qibla']);
      expect(await prefs.togglePin('medications'), isTrue);
      expect(await prefs.pinned(), ['qibla', 'medications']);
      expect(await prefs.togglePin('qibla'), isFalse);
      expect(await prefs.pinned(), ['medications']);
      await prefs.markOpened('mushaf');
      await prefs.markOpened('adhkar');
      await prefs.markOpened('mushaf');
      expect(await prefs.recent(), ['mushaf', 'adhkar']);
    });
  });
}
