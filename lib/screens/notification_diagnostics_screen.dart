import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// "تشخيص الإشعارات" (2026-08-17 reliability pass) — a lightweight
/// self-check screen, not the full monitoring/observability dashboard a
/// larger team app might build. Lets Ismail confirm for himself that
/// reminders are actually scheduled with the OS and that permissions are
/// really granted, rather than trusting a saved preference alone.
class NotificationDiagnosticsScreen extends StatefulWidget {
  const NotificationDiagnosticsScreen({super.key});

  @override
  State<NotificationDiagnosticsScreen> createState() => _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState extends State<NotificationDiagnosticsScreen> {
  final _notifications = NotificationService();
  bool _loading = true;
  bool _notificationsEnabled = false;
  bool _exactAlarmsEnabled = false;
  List<PendingNotificationRequest> _pending = [];
  AppCoordinates? _location;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notificationsEnabled = await _notifications.notificationsEnabled();
    final exactAlarmsEnabled = await _notifications.exactAlarmsEnabled();
    final pending = await _notifications.pendingNotifications();
    final location = await LocationService().currentLocation();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _exactAlarmsEnabled = exactAlarmsEnabled;
      _pending = pending;
      _location = location;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(title: Text(basicText('notification_diagnostics_title', lang))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _statusTile(
                    title: basicText('notification_permission_title', lang),
                    ok: _notificationsEnabled,
                    okText: basicText('permission_granted_label', lang),
                    badText: basicText('notification_permission_denied_text', lang),
                  ),
                  const SizedBox(height: 10),
                  _statusTile(
                    title: basicText('exact_alarm_scheduling_title', lang),
                    ok: _exactAlarmsEnabled,
                    okText: basicText('exact_alarm_granted_text', lang),
                    badText: basicText('exact_alarm_denied_text', lang),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(basicText('location_label', lang), style: AppTextStyles.title),
                        const SizedBox(height: 6),
                        Text(
                          _location == null
                              ? basicText('no_location_available_text', lang)
                              : _location!.isManual
                                  ? basicText('manual_location_text', lang)
                                  : '${basicText('real_gps_location_text', lang)}${_location!.accuracyMeters != null ? ' (${basicText('accuracy_meters_suffix', lang)}${_location!.accuracyMeters!.round()} ${basicText('meters_unit_short', lang)})' : ' (${basicText('from_cache_text', lang)})'}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${basicText('scheduled_notifications_count_title', lang)} (${_pending.length})', style: AppTextStyles.headline),
                  const SizedBox(height: 10),
                  if (_pending.isEmpty)
                    Text(basicText('no_scheduled_notifications_text', lang), style: AppTextStyles.caption)
                  else
                    ..._pending.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.title ?? '—', style: AppTextStyles.body),
                                    if (p.body != null) Text(p.body!, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Text('#${p.id}', style: AppTextStyles.caption),
                            ],
                          ),
                        )),
                ],
              ),
            ),
      ),
    );
  }

  Widget _statusTile({required String title, required bool ok, required String okText, required String badText}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ok ? AppColors.primaryLight : Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: ok ? AppColors.primary.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.error_outline, color: ok ? AppColors.primary : Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: 2),
                Text(ok ? okText : badText, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
