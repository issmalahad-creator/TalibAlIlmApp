import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/adhkar_repository.dart';
import '../repositories/custom_adhkar_reminder_repository.dart';
import '../services/adhkar_notification_prefs.dart';
import '../services/language_preference_service.dart';
import '../services/notification_policy.dart';
import '../services/notification_service.dart';
import '../services/prayer_notification_prefs.dart';
import '../services/quiet_hours_prefs.dart';
import '../theme/app_theme.dart';
import 'notification_diagnostics_screen.dart';
import '../widgets/notification_permission_sheet.dart';

const _categoryLabelKeys = {
  'morning': ('notif_cat_morning_title', 'notif_cat_morning_hint'),
  'evening': ('notif_cat_evening_title', 'notif_cat_evening_hint'),
  'sleep': ('notif_cat_sleep_title', 'notif_cat_sleep_hint'),
};

/// "صفحة ضبط الإشعارات" — Ismail's 2026-08-17 request, first real working
/// version (not yet the full "عملاقة" settings page covering every
/// notification type — deliberately scoped to adhkar reminders only,
/// built to grow later, matching this session's "حبة حبة" pattern). Lets
/// the student enable/disable each of the 3 adhkar reminder categories and
/// optionally override its time — otherwise it defaults to the real
/// prayer time (see `NotificationService.scheduleAdhkarReminders`).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _prefs = AdhkarNotificationPrefs();
  final _notifications = NotificationService();
  final _customRepo = CustomAdhkarReminderRepository();
  final _prayerPrefs = PrayerNotificationPrefs();
  final _quietHoursPrefs = QuietHoursPrefs();
  final _testPlayer = AudioPlayer();
  Map<String, bool> _enabled = {};
  Map<String, int?> _customHours = {};
  List<AdhkarCategory> _allCategories = [];
  List<CustomAdhkarReminder> _customReminders = [];
  bool _prayerEnabled = true;
  bool _useAdhanSound = false;
  bool _quietHoursEnabled = false;
  int _quietStart = 22;
  int _quietEnd = 6;
  bool _loading = true;
  bool _testPlaying = false;
  bool _notifAllowed = true;
  bool _exactOk = true;
  Map<Encouragement, bool> _encEnabled = {};
  int _cap = NotificationPolicy.defaultCap;

  @override
  void initState() {
    super.initState();
    _load();
    _testPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _testPlaying = false);
    });
  }

  @override
  void dispose() {
    _testPlayer.dispose();
    super.dispose();
  }

  /// Plays the bundled adhan recording directly (not via a notification) so
  /// Ismail can preview it immediately — the real notification-channel
  /// sound is a separate native raw-resource copy of the same file (see
  /// `notification_service.dart`'s doc comment on why two copies exist).
  /// Toggles into a real stop control while playing (previously the button
  /// only ever restarted playback from the top — there was no way to
  /// actually stop the preview short of leaving the screen).
  Future<void> _playTestAdhan() async {
    if (_testPlaying) {
      await _testPlayer.stop();
      if (mounted) setState(() => _testPlaying = false);
      return;
    }
    setState(() => _testPlaying = true);
    await _testPlayer.stop();
    await _testPlayer.play(AssetSource('audio/adhan_beautiful.ogg'));
  }

  Future<void> _load() async {
    final enabled = <String, bool>{};
    final hours = <String, int?>{};
    for (final c in _prefs.categories) {
      enabled[c] = await _prefs.isEnabled(c);
      hours[c] = await _prefs.customHour(c);
    }
    final categories = await AdhkarRepository().allCategories();
    final customReminders = await _customRepo.all();
    final prayerEnabled = await _prayerPrefs.isEnabled();
    final useAdhanSound = await _prayerPrefs.useAdhanSound();
    final quietEnabled = await _quietHoursPrefs.isEnabled();
    final quietStart = await _quietHoursPrefs.startHour();
    final quietEnd = await _quietHoursPrefs.endHour();
    final policy = NotificationPolicy.instance;
    final encEnabled = {for (final k in Encouragement.values) k: await policy.isEnabled(k)};
    final cap = await policy.cap();
    final notifAllowed = await _notifications.notificationsEnabled();
    final exactOk = await _notifications.exactAlarmsEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _customHours = hours;
      _allCategories = categories;
      _customReminders = customReminders;
      _prayerEnabled = prayerEnabled;
      _useAdhanSound = useAdhanSound;
      _quietHoursEnabled = quietEnabled;
      _encEnabled = encEnabled;
      _cap = cap;
      _notifAllowed = notifAllowed;
      _exactOk = exactOk;
      _quietStart = quietStart;
      _quietEnd = quietEnd;
      _loading = false;
    });
  }

  Future<void> _togglePrayerNotifications(bool value) async {
    if (value) await ensureExactAlarmsForPrayer(context);
    await _prayerPrefs.setEnabled(value);
    setState(() => _prayerEnabled = value);
    await _notifications.schedulePrayerTimeNotifications();
  }

  Future<void> _fixNotifications() async {
    await ensureNotificationPermission(context, NotificationReason.general);
    await _load();
  }

  Future<void> _fixExactAlarms() async {
    await ensureExactAlarmsForPrayer(context);
    await _notifications.schedulePrayerTimeNotifications();
    await _load();
  }

  Future<void> _sendTest() async {
    if (!await ensureNotificationPermission(context, NotificationReason.general)) return;
    await _notifications.showTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(basicText('notif_test_sent', LanguagePreferenceService.currentLanguage))));
    await _load();
  }

  Future<void> _toggleEncouragement(Encouragement kind, bool value) async {
    await NotificationPolicy.instance.setEnabled(kind, value);
    setState(() => _encEnabled[kind] = value);
    if (!value) {
      await _notifications.cancelEncouragement(kind);
    } else if (kind == Encouragement.timeLog) {
      await _notifications.scheduleTimeLogReminder();
    }
    // The others come back on their own trigger (a hifz check-in, opening a
    // book, the next launch for the companion).
  }

  Future<void> _setCap(int value) async {
    await NotificationPolicy.instance.setCap(value);
    setState(() => _cap = value.clamp(1, 4));
  }

  Future<void> _toggleAdhanSound(bool value) async {
    await _prayerPrefs.setUseAdhanSound(value);
    setState(() => _useAdhanSound = value);
    await _notifications.schedulePrayerTimeNotifications();
  }

  Future<void> _toggleQuietHours(bool value) async {
    await _quietHoursPrefs.setEnabled(value);
    setState(() => _quietHoursEnabled = value);
    await _apply();
  }

  Future<void> _pickQuietWindow() async {
    final start = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _quietStart, minute: 0));
    if (start == null || !mounted) return;
    final end = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _quietEnd, minute: 0));
    if (end == null) return;
    await _quietHoursPrefs.setWindow(start.hour, end.hour);
    setState(() {
      _quietStart = start.hour;
      _quietEnd = end.hour;
    });
    await _apply();
  }

  String _titleFor(int categoryId, String lang) {
    final match = _allCategories.where((c) => c.id == categoryId);
    return match.isEmpty ? basicText('dhikr_generic_fallback', lang) : match.first.title;
  }

  /// "أضف ذكرًا" — Ismail's 2026-08-17 request to add a reminder for any
  /// adhkar category directly from this settings screen too (not only
  /// from the category's own reading screen).
  Future<void> _addCustomReminder() async {
    final category = await showDialog<AdhkarCategory>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(basicText('choose_dhikr_title', LanguagePreferenceService.currentLanguage)),
        children: _allCategories
            .map((c) => SimpleDialogOption(onPressed: () => Navigator.pop(context, c), child: Text(c.title)))
            .toList(),
      ),
    );
    if (category == null || !mounted) return;
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (picked == null || !mounted) return;
    await ensureNotificationPermission(context, NotificationReason.adhkar);
    await _customRepo.add(category.id, picked.hour);
    await _notifications.scheduleCustomAdhkarReminder(categoryId: category.id, categoryTitle: category.title, hour: picked.hour);
    _load();
  }

  Future<void> _removeCustomReminder(int categoryId) async {
    await _customRepo.remove(categoryId);
    await _notifications.cancelCustomAdhkarReminder(categoryId);
    _load();
  }

  Future<void> _apply() async {
    await _notifications.scheduleAdhkarReminders();
  }

  Future<void> _toggleEnabled(String category, bool value) async {
    if (value) await ensureNotificationPermission(context, NotificationReason.adhkar);
    await _prefs.setEnabled(category, value);
    setState(() => _enabled[category] = value);
    await _apply();
  }

  Future<void> _pickHour(String category) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _customHours[category] ?? 6, minute: 0),
    );
    if (picked == null) return;
    await _prefs.setCustomHour(category, picked.hour);
    setState(() => _customHours[category] = picked.hour);
    await _apply();
  }

  Future<void> _useAutoTime(String category) async {
    await _prefs.setCustomHour(category, null);
    setState(() => _customHours[category] = null);
    await _apply();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(
        title: Text(basicText('notifications_title', lang)),
        actions: [
          IconButton(
            tooltip: basicText('notification_diagnostics_tooltip', lang),
            icon: const Icon(Icons.health_and_safety_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationDiagnosticsScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PermissionStatusCard(
                  lang: lang,
                  notifAllowed: _notifAllowed,
                  exactOk: _exactOk,
                  showExact: _prayerEnabled,
                  onFixNotifications: _fixNotifications,
                  onFixExact: _fixExactAlarms,
                  onSendTest: _sendTest,
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(basicText('prayer_notification_title', lang), style: AppTextStyles.title),
                        subtitle: Text(basicText('prayer_notification_subtitle', lang), style: AppTextStyles.caption),
                        value: _prayerEnabled,
                        onChanged: _togglePrayerNotifications,
                      ),
                      if (_prayerEnabled) ...[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(basicText('adhan_sound_title', lang), style: AppTextStyles.title),
                          subtitle: Text(
                            basicText('adhan_sound_subtitle', lang),
                            style: AppTextStyles.caption,
                          ),
                          value: _useAdhanSound,
                          onChanged: _toggleAdhanSound,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: OutlinedButton.icon(
                              onPressed: _playTestAdhan,
                              icon: Icon(_testPlaying ? Icons.stop : Icons.play_arrow),
                              label: Text(basicText(_testPlaying ? 'stop_action' : 'test_adhan_sound_action', lang)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(basicText('quiet_hours_title', lang), style: AppTextStyles.title),
                        subtitle: Text(basicText('quiet_hours_subtitle', lang), style: AppTextStyles.caption),
                        value: _quietHoursEnabled,
                        onChanged: _toggleQuietHours,
                      ),
                      if (_quietHoursEnabled)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: OutlinedButton(
                              onPressed: _pickQuietWindow,
                              child: Text(
                                '${basicText('from_hour_prefix', lang)} $_quietStart:00 ${basicText('to_hour_prefix', lang)} $_quietEnd:00',
                                style: AppTextStyles.label,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _EncouragementSection(
                  lang: lang,
                  enabled: _encEnabled,
                  cap: _cap,
                  quietStart: _quietStart,
                  quietEnd: _quietEnd,
                  onToggle: _toggleEncouragement,
                  onCap: _setCap,
                ),
                Text(basicText('adhkar_notifications_section_title', lang), style: AppTextStyles.headline),
                const SizedBox(height: 10),
                ..._prefs.categories.map((category) {
                final (titleKey, hintKey) = _categoryLabelKeys[category]!;
                final title = basicText(titleKey, lang);
                final defaultHint = basicText(hintKey, lang);
                final enabled = _enabled[category] ?? true;
                final customHour = _customHours[category];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(title, style: AppTextStyles.title),
                        value: enabled,
                        onChanged: (v) => _toggleEnabled(category, v),
                      ),
                      if (enabled) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _useAutoTime(category),
                                style: customHour == null
                                    ? OutlinedButton.styleFrom(backgroundColor: AppColors.primaryLight)
                                    : null,
                                child: Text(basicText('auto_label', lang), style: AppTextStyles.label),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _pickHour(category),
                                style: customHour != null
                                    ? OutlinedButton.styleFrom(backgroundColor: AppColors.primaryLight)
                                    : null,
                                child: Text(
                                  customHour == null
                                      ? basicText('set_time_manually_label', lang)
                                      : '${basicText('hour_at_label', lang)} $customHour:00',
                                  style: AppTextStyles.label,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(customHour == null ? defaultHint : basicText('custom_time_label', lang), style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                );
                }),
                const SizedBox(height: 8),
                Text(basicText('custom_adhkar_section_title', lang), style: AppTextStyles.headline),
                const SizedBox(height: 4),
                Text(basicText('custom_adhkar_section_subtitle', lang), style: AppTextStyles.caption),
                const SizedBox(height: 10),
                ..._customReminders.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(_titleFor(r.categoryId, lang), style: AppTextStyles.body)),
                          Text('${basicText('hour_at_label', lang)} ${r.hour}:00', style: AppTextStyles.caption),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                            onPressed: () => _removeCustomReminder(r.categoryId),
                          ),
                        ],
                      ),
                    )),
                OutlinedButton.icon(
                  onPressed: _addCustomReminder,
                  icon: const Icon(Icons.add),
                  label: Text(basicText('add_dhikr_reminder_action', lang)),
                ),
              ],
            ),
      ),
    );
  }
}

/// «الإشعارات مسموحة / متوقفة» + exact-alarm state for prayer, each with a
/// fix button, and the test notification (N4).
class _PermissionStatusCard extends StatelessWidget {
  const _PermissionStatusCard({
    required this.lang,
    required this.notifAllowed,
    required this.exactOk,
    required this.showExact,
    required this.onFixNotifications,
    required this.onFixExact,
    required this.onSendTest,
  });

  final String lang;
  final bool notifAllowed;
  final bool exactOk;
  final bool showExact;
  final VoidCallback onFixNotifications;
  final VoidCallback onFixExact;
  final VoidCallback onSendTest;

  Widget _row(IconData icon, bool ok, String text, VoidCallback onFix) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: ok ? AppColors.primary : Colors.orange.shade800),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AppTextStyles.body)),
            if (!ok) TextButton(onPressed: onFix, child: Text(basicText('notif_fix_action', lang))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
      decoration: BoxDecoration(
        color: notifAllowed ? AppColors.surface : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: notifAllowed ? AppColors.divider : Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(notifAllowed ? Icons.notifications_active_outlined : Icons.notifications_off_outlined, notifAllowed,
              basicText(notifAllowed ? 'notif_status_on' : 'notif_status_off', lang), onFixNotifications),
          if (notifAllowed && showExact)
            _row(exactOk ? Icons.alarm_on_outlined : Icons.alarm_outlined, exactOk,
                basicText(exactOk ? 'notif_exact_on' : 'notif_exact_off', lang), onFixExact),
          if (notifAllowed)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onSendTest,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: Text(basicText('notif_test_action', lang)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The four reminders the app sends on its own, each switchable, plus the
/// daily limit they share (NotificationPolicy).
class _EncouragementSection extends StatelessWidget {
  const _EncouragementSection({
    required this.lang,
    required this.enabled,
    required this.cap,
    required this.quietStart,
    required this.quietEnd,
    required this.onToggle,
    required this.onCap,
  });

  final String lang;
  final Map<Encouragement, bool> enabled;
  final int cap;
  final int quietStart;
  final int quietEnd;
  final void Function(Encouragement, bool) onToggle;
  final void Function(int) onCap;

  static const _labels = {
    Encouragement.hifz: ('enc_hifz_title', 'enc_hifz_sub'),
    Encouragement.timeLog: ('enc_timelog_title', 'enc_timelog_sub'),
    Encouragement.companion: ('enc_companion_title', 'enc_companion_sub'),
    Encouragement.reading: ('enc_reading_title', 'enc_reading_sub'),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(basicText('enc_section_title', lang), style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            basicText('enc_section_subtitle', lang)
                .replaceAll('{start}', '$quietStart')
                .replaceAll('{end}', '$quietEnd'),
            style: AppTextStyles.caption,
          ),
          for (final k in Encouragement.values)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(basicText(_labels[k]!.$1, lang), style: AppTextStyles.body),
              subtitle: Text(basicText(_labels[k]!.$2, lang), style: AppTextStyles.caption),
              value: enabled[k] ?? true,
              onChanged: (v) => onToggle(k, v),
            ),
          Row(
            children: [
              Expanded(child: Text(basicText('enc_cap_label', lang), style: AppTextStyles.body)),
              IconButton(
                onPressed: cap > 1 ? () => onCap(cap - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$cap', style: AppTextStyles.title),
              IconButton(
                onPressed: cap < 4 ? () => onCap(cap + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
