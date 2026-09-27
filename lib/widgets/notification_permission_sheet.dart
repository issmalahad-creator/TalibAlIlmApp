import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'feedback/light_trail.dart';

/// Why the app wants to notify — one sentence the user reads before any
/// system dialog (docs/architecture/NOTIFICATIONS_ARCHITECTURE.md §3.3).
enum NotificationReason { general, adhkar, task, prayer }

/// Ensures notifications are allowed, asking only in context:
/// already allowed → true at once; otherwise a short sheet explains [reason]
/// and only «السماح» triggers Android's own dialog. «ليس الآن» never nags.
/// Call from a user action (enabling a reminder), never at startup.
Future<bool> ensureNotificationPermission(BuildContext context, NotificationReason reason) async {
  final service = NotificationService();
  if (await service.notificationsEnabled()) return true;
  if (!context.mounted) return false;
  final allow = await _prime(
    context,
    icon: Icons.notifications_active_outlined,
    title: 'notif_perm_title',
    body: 'notif_perm_reason_${reason.name}',
    action: 'notif_perm_allow',
  );
  if (allow != true) return false;
  final granted = await service.requestPermission();
  if (!granted && context.mounted) {
    // Android stops showing its dialog after two denials — say where to fix it.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(basicText('notif_perm_denied_hint', LanguagePreferenceService.currentLanguage))),
    );
  }
  return granted;
}

/// Prayer-time notifications: notifications + exact alarms. Exact alarms open
/// the system «Alarms & reminders» screen on Android 12+, so it is explained
/// first; without it prayer alerts still arrive, a few minutes late — said
/// honestly rather than hidden.
Future<bool> ensureExactAlarmsForPrayer(BuildContext context) async {
  if (!await ensureNotificationPermission(context, NotificationReason.prayer)) return false;
  final service = NotificationService();
  if (await service.exactAlarmsEnabled()) return true;
  if (!context.mounted) return false;
  final go = await _prime(
    context,
    icon: Icons.alarm_on_outlined,
    title: 'notif_exact_title',
    body: 'notif_exact_body',
    action: 'notif_exact_open',
  );
  if (go != true) return false;
  return service.requestExactAlarms();
}

Future<bool?> _prime(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  required String action,
}) {
  final lang = LanguagePreferenceService.currentLanguage;
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primaryDark, size: 30),
            ),
            const SizedBox(height: 14),
            Text(basicText(title, lang),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(basicText(body, lang),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            const SizedBox(width: 60, height: 2, child: ColoredBox(color: kLightTrailGold)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(basicText(action, lang))),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(basicText('notif_perm_later', lang))),
          ],
        ),
      ),
    ),
  );
}
