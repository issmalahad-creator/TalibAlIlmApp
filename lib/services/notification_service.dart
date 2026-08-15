import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/hijri_date.dart';
import '../utils/month.dart';
import 'sync_service.dart';

/// Schedules local notifications: (1) a single reminder 3 days before the
/// end of the current Hijri month for the report deadline, and (2) one
/// optional reminder per daily task. `FlutterLocalNotificationsPlugin`'s
/// platform channel is effectively shared across every Dart-side instance,
/// so initialization is tracked with a `static` future — every
/// `NotificationService()` instance (several exist, one per screen that
/// needs it) awaits the *same* init, matching the pattern already needed
/// for `SyncService`'s in-flight guard.
class NotificationService {
  static const _channelId = 'report_reminders';
  static const _channelName = 'تذكيرات التقرير الشهري';
  static const _reminderNotificationId = 1001;

  // Daily task reminder ids are offset well clear of the report reminder id.
  static const _taskNotificationIdBase = 2000;

  static const _taskChannelId = 'task_reminders';
  static const _taskChannelName = 'تذكيرات المهام اليومية';

  // Reading-inactivity reminder — a single fixed id, offset clear of both
  // ranges above (1001, 2000+taskId).
  static const _readingReminderNotificationId = 3000;
  static const _readingChannelId = 'reading_reminders';
  static const _readingChannelName = 'تذكير بالقراءة';
  static const _readingReminderInactiveDays = 3;

  // Immediate (non-scheduled) notification fired when new admin content
  // (book/banner/announcement) is relayed via Telegram — one fixed id, a
  // fresh call always overwrites/replaces rather than stacking duplicates.
  static const _contentNotificationId = 4000;
  static const _contentChannelId = 'content_updates';
  static const _contentChannelName = 'محتوى جديد من المشرف';

  // Hifz (Quran memorization) daily check-in reminder — same
  // reschedule-on-every-checkin pattern as the reading reminder.
  static const _hifzReminderNotificationId = 5000;
  static const _hifzChannelId = 'hifz_reminders';
  static const _hifzChannelName = 'تذكير حفظ القرآن';
  static const _hifzReminderInactiveDays = 1;

  final _plugin = FlutterLocalNotificationsPlugin();
  final _syncService = SyncService();

  static Future<void>? _initFuture;

  Future<void> init() => _ensureInitialized();

  Future<void> _ensureInitialized() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Falls back to UTC if the device timezone can't be resolved — the
      // reminder still fires, just possibly a few hours off.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(settings: const InitializationSettings(android: androidInit));

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _scheduleReminderForCurrentMonth();
  }

  Future<void> _scheduleReminderForCurrentMonth() async {
    await _plugin.cancel(id: _reminderNotificationId);

    final month = currentMonth();
    final alreadySubmitted = await _syncService.hasSubmittedForMonth(month);
    if (alreadySubmitted) return;

    final reminderTime = hijriMonthEndReminderDateTime(daysBefore: 3);
    if (reminderTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: _reminderNotificationId,
      title: 'اقترب موعد إرسال التقرير الشهري',
      body: 'باقي 3 أيام على نهاية الشهر — لا تنسَ إرسال تقريرك الشهري.',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'تنبيه قبل 3 أيام من نهاية الشهر الهجري بإرسال التقرير',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Call after a successful monthly submission so the reminder for this
  /// month is cancelled (nothing left to remind about).
  Future<void> cancelCurrentMonthReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _reminderNotificationId);
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required DateTime dateTime,
  }) async {
    await _ensureInitialized();
    final id = _taskNotificationIdBase + taskId;
    await _plugin.cancel(id: id);
    if (dateTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: id,
      title: 'تذكير بمهمة',
      body: title,
      scheduledDate: tz.TZDateTime.from(dateTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _taskChannelId,
          _taskChannelName,
          channelDescription: 'تذكير بمهمة يومية حدّدها الداعية لنفسه',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskReminder(int taskId) async {
    await _ensureInitialized();
    await _plugin.cancel(id: _taskNotificationIdBase + taskId);
  }

  /// Pushes the "haven't read in a while" reminder [_readingReminderInactiveDays]
  /// days into the future — call every time a student opens any book
  /// (`BookViewerScreen.initState`). Cancelling and rescheduling on every
  /// open means it only actually fires if they go quiet for that many days
  /// in a row; opening any book resets the clock.
  Future<void> scheduleReadingReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _readingReminderNotificationId);
    final fireAt = DateTime.now().add(const Duration(days: _readingReminderInactiveDays));
    await _plugin.zonedSchedule(
      id: _readingReminderNotificationId,
      title: 'اشتقنا لك 📖',
      body: 'لم تفتح أي كتاب منذ عدة أيام — عد إلى مكتبتك وتابع قراءتك.',
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _readingChannelId,
          _readingChannelName,
          channelDescription: 'تذكير عند التوقف عن القراءة لعدة أيام',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Pushes the Hifz check-in reminder [_hifzReminderInactiveDays] day(s)
  /// into the future — call every time the student checks in on the Hifz
  /// screen. A short 1-day window (vs. the reading reminder's 3) since daily
  /// consistency is the whole point of a memorization streak.
  Future<void> scheduleHifzReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _hifzReminderNotificationId);
    final fireAt = DateTime.now().add(const Duration(days: _hifzReminderInactiveDays));
    await _plugin.zonedSchedule(
      id: _hifzReminderNotificationId,
      title: 'حفظ القرآن 📖',
      body: 'لا تنسَ نصيبك اليوم من الحفظ أو المراجعة.',
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _hifzChannelId,
          _hifzChannelName,
          channelDescription: 'تذكير يومي بحفظ أو مراجعة القرآن',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Fires immediately (not scheduled) when [ContentBadgeService] detects
  /// genuinely new admin content (book/banner/announcement) the student
  /// hasn't been notified about yet — see that service for the dedupe logic.
  Future<void> showNewContentNotification(String body) async {
    await _ensureInitialized();
    await _plugin.show(
      id: _contentNotificationId,
      title: '📚 محتوى جديد',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _contentChannelId,
          _contentChannelName,
          channelDescription: 'إشعار عند وصول محتوى جديد من المشرف عبر تلجرام',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
