import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local notifications: one optional reminder per daily task, plus
/// reading/hifz inactivity nudges. `FlutterLocalNotificationsPlugin`'s
/// platform channel is effectively shared across every Dart-side instance,
/// so initialization is tracked with a `static` future — every
/// `NotificationService()` instance (several exist, one per screen that
/// needs it) awaits the *same* init.
///
/// Notification id 1001 / the 'report_reminders' channel are reserved but
/// currently unused — they held the monthly-report-deadline reminder before
/// the Report feature was removed (Phase -1 of QURAN_COMPANION_ROADMAP.md).
/// Phase 2 of that roadmap defines the real replacement: a daily
/// "جلسة اليوم" reminder. Don't reuse id 1001 for anything unrelated to that.
class NotificationService {
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

  // "خطة الختم" per-goal daily reminders — one id per goal, offset clear of
  // every range above (1001, 2000+taskId, 3000, 4000, 5000). Fires every
  // evening; CompletionGoalsScreen cancels/reschedules based on
  // CompletionGoalRepository.hasProgressedToday so it only actually nags
  // when today's target genuinely wasn't touched.
  static const _goalReminderNotificationIdBase = 6000;
  static const _goalChannelId = 'goal_reminders';
  static const _goalChannelName = 'تذكير خطط الختم';
  static const _goalReminderHour = 20;

  // Adhkar morning/evening reminders — fixed daily times (honest
  // approximation: this app has no real prayer-time calculation yet, so
  // these are NOT actually "after Fajr"/"after Asr" as the roadmap's
  // original wording aspired to, just reasonable fixed clock times).
  // Offset clear of every range above (1001, 2000+taskId, 3000, 4000,
  // 5000, 6000+goalId).
  static const _adhkarMorningNotificationId = 7000;
  static const _adhkarEveningNotificationId = 7001;
  static const _adhkarChannelId = 'adhkar_reminders';
  static const _adhkarChannelName = 'تذكير أذكار الصباح والمساء';
  static const _adhkarMorningHour = 6;
  static const _adhkarEveningHour = 17;

  // "محاسبة الوقت" daily log reminder — fixed evening time, same
  // always-recurring pattern as the adhkar reminders below (not a
  // reschedule-on-checkin pattern like reading/hifz/goals, since this
  // should nudge every day regardless of whether yesterday was logged).
  // Offset clear of every range above (1001, 2000+taskId, 3000, 4000,
  // 5000, 6000+goalId, 7000/7001) and clear of the still-unbuilt prayer-
  // notification range planned at 8000+ (roadmap §4.25).
  static const _timeLogReminderNotificationId = 9000;
  static const _timeLogChannelId = 'time_log_reminders';
  static const _timeLogChannelName = 'تذكير محاسبة الوقت';
  static const _timeLogReminderHour = 21;

  final _plugin = FlutterLocalNotificationsPlugin();

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

    // Report-deadline reminder removed with the Report feature (Phase -1).
    // Cancel any reminder a previous app version may have already scheduled
    // on this device so it doesn't keep firing with stale copy.
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

  /// Schedules today's reminder for one "خطة ختم" goal, showing its
  /// per-page/per-unit KPI (`dailyTargetLabel`, e.g. "15 صفحة اليوم") — fires
  /// at [_goalReminderHour] today if that time hasn't passed yet, else
  /// tomorrow. Callers (`CompletionGoalsScreen`) should call this once per
  /// active goal on load/refresh, and [cancelGoalReminder] the moment
  /// `hasProgressedToday` becomes true or the goal completes, so a student
  /// who already read today never gets nagged.
  Future<void> scheduleGoalReminder({
    required int goalId,
    required String goalTitle,
    required String dailyTargetLabel,
  }) async {
    await _ensureInitialized();
    final id = _goalReminderNotificationIdBase + goalId;
    await _plugin.cancel(id: id);

    var fireAt = DateTime.now().copyWith(hour: _goalReminderHour, minute: 0, second: 0, millisecond: 0);
    if (fireAt.isBefore(DateTime.now())) fireAt = fireAt.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: id,
      title: 'لم تكمل نصيبك اليوم 🎯',
      body: '$goalTitle — $dailyTargetLabel',
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _goalChannelId,
          _goalChannelName,
          channelDescription: 'تذكير يومي بنصيبك من خطة ختم لم تُنجَز بعد',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelGoalReminder(int goalId) async {
    await _ensureInitialized();
    await _plugin.cancel(id: _goalReminderNotificationIdBase + goalId);
  }

  /// Fixed daily adhkar reminders (morning ~$_adhkarMorningHour:00, evening
  /// ~$_adhkarEveningHour:00) — true recurring alarms via
  /// `matchDateTimeComponents: DateTimeComponents.time`, unlike every other
  /// reminder in this file which reschedules itself on each check-in.
  /// Idempotent to call repeatedly (cancels then reschedules).
  Future<void> scheduleAdhkarReminders() async {
    await _ensureInitialized();
    await _scheduleDailyAt(
      id: _adhkarMorningNotificationId,
      hour: _adhkarMorningHour,
      title: 'أذكار الصباح 🌅',
      body: 'وقت أذكار الصباح — لا تنسَ نصيبك اليوم.',
      channelId: _adhkarChannelId,
      channelName: _adhkarChannelName,
      channelDescription: 'تذكير يومي ثابت بأذكار الصباح والمساء (وقت تقريبي، لا يعتمد على أوقات الصلاة الفعلية بعد)',
    );
    await _scheduleDailyAt(
      id: _adhkarEveningNotificationId,
      hour: _adhkarEveningHour,
      title: 'أذكار المساء 🌇',
      body: 'وقت أذكار المساء — لا تنسَ نصيبك اليوم.',
      channelId: _adhkarChannelId,
      channelName: _adhkarChannelName,
      channelDescription: 'تذكير يومي ثابت بأذكار الصباح والمساء (وقت تقريبي، لا يعتمد على أوقات الصلاة الفعلية بعد)',
    );
  }

  /// "محاسبة الوقت" daily reminder (Ismail's request 2026-08-16): a fixed
  /// evening nudge to log how the day's hours were actually spent
  /// (slept/wasted/studied/worked). Always-recurring like the adhkar
  /// reminders, not reschedule-on-checkin — the whole point is a daily
  /// prompt regardless of yesterday's entry.
  Future<void> scheduleTimeLogReminder() async {
    await _ensureInitialized();
    await _scheduleDailyAt(
      id: _timeLogReminderNotificationId,
      hour: _timeLogReminderHour,
      title: 'محاسبة يومك ⏳',
      body: 'قبل أن ينام يومك — سجّل كم نمت، وكم ضاع، وكم درست واشتغلت.',
      channelId: _timeLogChannelId,
      channelName: _timeLogChannelName,
      channelDescription: 'تذكير يومي ثابت بتسجيل محاسبة الوقت',
    );
  }

  Future<void> _scheduleDailyAt({
    required int id,
    required int hour,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    await _plugin.cancel(id: id);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
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
