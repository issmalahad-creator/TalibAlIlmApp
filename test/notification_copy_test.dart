import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/services/companion_engine.dart';
import 'package:talib_alilm_app/services/notification_policy.dart';

const _langs = ['ar', 'en', 'am', 'fr', 'sw', 'ur', 'tr', 'id', 'bn', 'ha', 'so', 'fa', 'ms'];

/// N3 (NOTIFICATIONS_ARCHITECTURE.md §3.4): every notification string and
/// channel name exists in all 13 languages, and rotating wordings never
/// repeat back-to-back.
void main() {
  test('every notification key is translated in all 13 languages', () {
    final keys = basicTranslations.keys
        .where((k) => k.startsWith('nch_') || k.startsWith('ncd_') || k.startsWith('n_') || k.startsWith('cmp_'))
        .toList();
    expect(keys.length, greaterThanOrEqualTo(60));
    for (final k in keys) {
      for (final l in _langs) {
        expect(basicTranslations[k]![l], isNotNull, reason: '$k/$l');
      }
    }
  });

  test('placeholders survive translation', () {
    for (final k in ['n_adhkar_morning_body', 'n_adhkar_evening_body', 'n_adhkar_sleep_body', 'n_custom_adhkar_body']) {
      for (final l in _langs) {
        expect(basicText(k, l), contains('{minutes}'), reason: '$k/$l');
      }
    }
    for (final l in _langs) {
      expect(basicText('n_prayer_title', l), contains('{name}'), reason: l);
      expect(basicText('cmp_review_body', l), contains('{n}'), reason: l);
      expect(basicText('cmp_celebrate_body', l), contains('{n}'), reason: l);
    }
  });

  group('pickVariant', () {
    test('never picks a recent one while a fresh one exists', () {
      final rng = Random(1);
      for (var i = 0; i < 200; i++) {
        expect([0, 2], isNot(contains(pickVariant(4, [0, 2], rng))));
      }
    });

    test('all recent: still picks something valid', () {
      expect(pickVariant(2, [0, 1], Random(1)), inInclusiveRange(0, 1));
    });
  });

  test('variant: no wording repeats within two consecutive reminders', () async {
    SharedPreferences.setMockInitialValues({});
    final seen = <String>[];
    for (var i = 0; i < 40; i++) {
      seen.add(await NotificationPolicy.instance.variant('n_hifz_body', 4, 'en', rng: Random(i)));
    }
    for (var i = 2; i < seen.length; i++) {
      expect(seen[i], isNot(anyOf(seen[i - 1], seen[i - 2])), reason: 'at $i');
    }
    expect(seen.toSet().length, 4);
  });

  test('companion speaks the app language', () {
    final msg = companionMessageFor(const CompanionContext(dueReviewsCount: 5), lang: 'en');
    expect(msg!.title, 'Your review is waiting');
    expect(msg.body, 'You have 5 reviews due today.');
    expect(companionMessageFor(const CompanionContext(daysAbsent: 3))!.title, 'الحمد لله على عودتك');
  });
}
