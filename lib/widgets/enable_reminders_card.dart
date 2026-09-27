import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'notification_permission_sheet.dart';

/// Home «فعّل التذكيرات» — the one calm place that invites notifications
/// after onboarding (NOTIFICATIONS_ARCHITECTURE.md §3.3). Invisible when
/// already allowed; «لاحقًا» hides it for good. Nothing asks by itself.
class EnableRemindersCard extends StatefulWidget {
  const EnableRemindersCard({super.key});

  static const dismissedKey = 'notif_invite_dismissed';

  /// Whether notifications are already allowed — replaceable in tests.
  @visibleForTesting
  static Future<bool> Function() isAllowed = () => NotificationService().notificationsEnabled();

  @override
  State<EnableRemindersCard> createState() => _EnableRemindersCardState();
}

class _EnableRemindersCardState extends State<EnableRemindersCard> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(EnableRemindersCard.dismissedKey) ?? false) return;
      if (await EnableRemindersCard.isAllowed()) return;
      if (mounted) setState(() => _show = true);
    } catch (e) {
      debugPrint('EnableRemindersCard: $e');
    }
  }

  Future<void> _dismiss() async {
    setState(() => _show = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(EnableRemindersCard.dismissedKey, true);
    } catch (_) {}
  }

  Future<void> _enable() async {
    final granted = await ensureNotificationPermission(context, NotificationReason.general);
    // Alarms scheduled before permission already exist — Android simply
    // starts showing them now, so nothing needs rescheduling.
    if (granted && mounted) setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final lang = LanguagePreferenceService.currentLanguage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: AppColors.primaryLight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, color: AppColors.primaryDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(basicText('notif_invite_title', lang),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(basicText('notif_perm_reason_general', lang),
                  style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _dismiss, child: Text(basicText('notif_invite_later', lang))),
                  // The app theme's full-width minimum size can't live in a Row.
                  FilledButton(
                      onPressed: _enable,
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      child: Text(basicText('notif_invite_enable', lang))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
