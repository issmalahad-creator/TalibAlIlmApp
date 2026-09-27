import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/theme/app_theme.dart';
import 'package:talib_alilm_app/widgets/enable_reminders_card.dart';
import 'package:talib_alilm_app/widgets/notification_permission_sheet.dart';

String t(String key) => basicText(key, 'ar');

/// N1 (NOTIFICATIONS_ARCHITECTURE.md): the OS dialog is never the first
/// thing the user sees — a reason sheet comes first, «ليس الآن» asks nothing,
/// and the Home invite disappears for good once dismissed.
void main() {

  testWidgets('priming sheet explains the reason; «ليس الآن» returns false quietly', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await ensureNotificationPermission(context, NotificationReason.adhkar),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    // The permission check crosses real platform channels (no fake clock).
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text(t('notif_perm_title')), findsOneWidget);
    expect(find.text(t('notif_perm_reason_adhkar')), findsOneWidget);

    await tester.tap(find.text(t('notif_perm_later')));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(result, isFalse);
    expect(find.text(t('notif_perm_denied_hint')), findsNothing);
  });

  testWidgets('Home invite shows when not allowed, «لاحقًا» hides it permanently', (tester) async {
    SharedPreferences.setMockInitialValues({});
    EnableRemindersCard.isAllowed = () async => false;
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: const Scaffold(body: EnableRemindersCard())));
    await tester.pumpAndSettle();
    expect(find.text(t('notif_invite_title')), findsOneWidget);

    await tester.tap(find.text(t('notif_invite_later')));
    await tester.pumpAndSettle();
    expect(find.text(t('notif_invite_title')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(EnableRemindersCard.dismissedKey), isTrue);
  });

  testWidgets('Home invite stays hidden once dismissed', (tester) async {
    SharedPreferences.setMockInitialValues({EnableRemindersCard.dismissedKey: true});
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: const Scaffold(body: EnableRemindersCard())));
    await tester.pumpAndSettle();
    expect(find.text(t('notif_invite_title')), findsNothing);
  });

  test('every priming string exists in all 13 languages', () {
    const keys = [
      'notif_perm_title', 'notif_perm_reason_general', 'notif_perm_reason_adhkar', 'notif_perm_reason_task',
      'notif_perm_reason_prayer', 'notif_perm_allow', 'notif_perm_later', 'notif_perm_denied_hint',
      'notif_exact_title', 'notif_exact_body', 'notif_exact_open',
      'notif_invite_title', 'notif_invite_enable', 'notif_invite_later',
    ];
    for (final r in NotificationReason.values) {
      expect(keys, contains('notif_perm_reason_${r.name}'));
    }
    for (final k in keys) {
      for (final l in const ['ar', 'en', 'am', 'fr', 'sw', 'ur', 'tr', 'id', 'bn', 'ha', 'so', 'fa', 'ms']) {
        expect(basicText(k, l), isNot(k), reason: '$k/$l');
      }
    }
  });
}
