import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('تشخيص الإشعارات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _statusTile(
                    title: 'إذن الإشعارات',
                    ok: _notificationsEnabled,
                    okText: 'ممنوح',
                    badText: 'غير ممنوح — لن تصل أي إشعارات حتى تُفعّله من إعدادات النظام',
                  ),
                  const SizedBox(height: 10),
                  _statusTile(
                    title: 'الجدولة الدقيقة (لتنبيه الصلاة)',
                    ok: _exactAlarmsEnabled,
                    okText: 'ممنوحة — تنبيه الصلاة يصل في وقته بدقة',
                    badText: 'غير ممنوحة — تنبيه الصلاة قد يتأخر بضع دقائق بسبب توفير البطارية',
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
                        Text('الموقع', style: AppTextStyles.title),
                        const SizedBox(height: 6),
                        Text(
                          _location == null
                              ? 'لا يوجد موقع متاح — تُحسب أوقات الصلاة والأذكار بالساعات الافتراضية الثابتة'
                              : _location!.isManual
                                  ? 'موقع مُدخَل يدويًا'
                                  : 'موقع GPS حقيقي${_location!.accuracyMeters != null ? ' (دقة ~${_location!.accuracyMeters!.round()} م)' : ' (من ذاكرة التخزين المؤقت)'}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('الإشعارات المجدولة الآن (${_pending.length})', style: AppTextStyles.headline),
                  const SizedBox(height: 10),
                  if (_pending.isEmpty)
                    Text('لا توجد إشعارات مجدولة حاليًا', style: AppTextStyles.caption)
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
