import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/basic_translations.dart';
import '../repositories/adhkar_repository.dart';
import '../repositories/life_plan_repository.dart';
import '../repositories/prayer_times_repository.dart';
import 'adhkar_notification_prefs.dart';
import 'companion_engine.dart';
import 'language_preference_service.dart';
import 'life_plan_notifications.dart';
import 'location_service.dart';
import 'prayer_notification_prefs.dart';
import 'quiet_hours_prefs.dart';

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

  // Adhkar morning/evening/sleep reminders — 2026-08-17: now anchored to
  // real prayer times (Fajr/Asr/Isha) when location is available, same
  // `dayWindowFromPrayerTimes` pattern already proven in
  // `lib/data/adhkar_journey.dart`; falls back to these fixed clock times
  // otherwise. `_adhkarSleepNotificationId` uses the entirely-free 10000+
  // range (8000+ is earmarked for prayer notifications, roadmap §4.25) —
  // offset clear of every range above.
  static const _adhkarMorningNotificationId = 7000;
  static const _adhkarEveningNotificationId = 7001;
  static const _adhkarSleepNotificationId = 10000;
  static const _adhkarChannelId = 'adhkar_reminders';
  static const _adhkarChannelName = 'تذكير أذكار الصباح والمساء والنوم';
  static const _adhkarMorningHour = 6;
  static const _adhkarEveningHour = 17;
  static const _adhkarSleepHour = 21;

  // Custom per-category adhkar reminders (Ismail's 2026-08-17 request) —
  // one id per category, offset well clear of every fixed range above.
  // `adhkar_categories.id` currently tops out around 134, so this base
  // leaves a wide, collision-free window.
  static const _customAdhkarReminderIdBase = 11000;
  static const _customAdhkarChannelId = 'custom_adhkar_reminders';
  static const _customAdhkarChannelName = 'تذكيرات أذكار مخصّصة';

  // 5 daily prayer-time notifications — the range this file's own comments
  // reserved back when it was still just a plan (roadmap §4.25). One fixed
  // id per prayer; rescheduled daily (real prayer times shift every day,
  // unlike every other reminder above which repeats at a fixed clock hour).
  static const _fajrNotificationId = 8001;
  static const _dhuhrNotificationId = 8002;
  static const _asrNotificationId = 8003;
  static const _maghribNotificationId = 8004;
  static const _ishaNotificationId = 8005;
  static const _prayerChannelId = 'prayer_time_notifications';
  static const _prayerChannelName = 'تنبيه أوقات الصلاة';

  // Adhan sound (2026-08-17) — `assets/audio/adhan_beautiful.ogg` /
  // `android/app/src/main/res/raw/adhan_beautiful.ogg`, CC0 (Wikimedia
  // Commons, see LICENSED_CONTENT_SOURCES.md). A SEPARATE channel id is
  // required, not just a different `sound:` param on the existing channel
  // — Android locks a notification channel's sound at the moment the
  // channel is first created, and silently ignores any `sound:` passed on
  // later calls to the same channel id. Any device that already has
  // `_prayerChannelId` created (default sound) keeps that channel exactly
  // as before; enabling the toggle routes to this second channel instead,
  // created for the first time with the real audio baked in.
  static const _prayerChannelIdAdhan = 'prayer_time_notifications_adhan';
  static const _prayerChannelNameAdhan = 'تنبيه أوقات الصلاة (بصوت الأذان)';
  static const _adhanSoundResource = 'adhan_beautiful';

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

  // "رفيق طالب العلم" as a real push (2026-08-17), not just the in-app
  // card — reuses the entirely-free 10000+ range, next id after the
  // adhkar-sleep reminder (10000).
  static const _companionNotificationId = 10001;
  static const _companionChannelId = 'companion_checkin';
  static const _companionChannelName = 'رفيق طالب العلم';
  static const _companionCheckInHour = 20;

  // «مُحرّك الحياة» (Life Engine, docs/LIFE_ENGINE.md L4) — a per-block
  // nudge for each of TODAY's not-yet-done, still-upcoming slots, a 21:30
  // nightly «حاسب نفسك» (with the live done/total), and a recurring 05:00
  // morning brief. Id band 12000+ (see life_plan_notifications.dart), clear
  // of every range above (…, 11000 + categoryId). Everything is one-shot
  // except the morning brief; `LifePlanScreen` reschedules on every
  // load / resume / midnight so completed and past blocks drop out.
  static const _lifeChannelId = 'life_slots';
  static const _lifeChannelName = 'مُحرّك الحياة';

  final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void>? _initFuture;

  /// Set once from `main.dart` — called with a notification's `payload`
  /// whenever the student taps one while the app process is alive
  /// (foreground or backgrounded). Cold-start taps (app fully closed) are
  /// handled separately via `getLaunchPayload()`, since the plugin's
  /// response callback doesn't fire in that case until well after
  /// `main()` has already run.
  static void Function(String payload)? onNotificationTap;

  Future<void> init() => _ensureInitialized();

  /// False until the local-notifications platform plugin has initialised
  /// successfully. Stays false on a plain test VM / unsupported platform —
  /// every public method below then no-ops instead of throwing.
  ///
  /// `static`, like [_initFuture]: `_doInit` runs exactly once per process
  /// (whichever instance wins the race), and the native plugin channel is
  /// shared across every Dart-side `NotificationService`. If this were
  /// per-instance, a screen that holds its own `NotificationService()`
  /// would keep `_ready == false` forever once `main.dart`'s instance had
  /// already run init — and all its scheduling calls would silently no-op.
  static bool _ready = false;

  /// Returns the payload of the notification that launched the app from a
  /// fully-closed state, if any — call once from `main.dart` after
  /// `init()`. Null on every ordinary (non-notification) launch.
  Future<String?> getLaunchPayload() async {
    await _ensureInitialized();
    if (!_ready) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }

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

    // Everything below touches the local-notifications platform plugin. If
    // that plugin isn't registered (a plain test VM, a headless / unsupported
    // platform), `initialize` throws a LateInitializationError — swallow it
    // so a launch-time reminder setup never becomes an unhandled async error
    // that breaks the app tree. Reminders simply don't schedule in that case.
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        settings: const InitializationSettings(android: androidInit),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) onNotificationTap?.call(payload);
        },
      );

      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      // Prayer-time notifications only (2026-08-17 reliability pass) — asks
      // once for exact-alarm scheduling so Doze mode can't delay the adhan
      // notification by several minutes. A no-op if already granted; opens
      // Android's own settings screen on 12+ if not.
      // `schedulePrayerTimeNotifications` checks `canScheduleExactNotifications()`
      // itself and silently falls back to inexact scheduling if this was
      // denied — never blocks or throws.
      await android?.requestExactAlarmsPermission();

      // Report-deadline reminder removed with the Report feature (Phase -1).
      // Cancel any reminder a previous app version may have already scheduled
      // on this device so it doesn't keep firing with stale copy.
      await _plugin.cancel(id: _reminderNotificationId);
      _ready = true;
    } catch (_) {
      // Notifications unavailable in this environment — degrade silently.
    }
  }

  /// Whether the OS notification permission is currently granted — read by
  /// `NotificationDiagnosticsScreen`, not used to gate scheduling (the
  /// plugin already no-ops safely if denied).
  Future<bool> notificationsEnabled() async {
    await _ensureInitialized();
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  /// Whether exact-alarm scheduling is currently available — same
  /// diagnostics use, also consulted by `schedulePrayerTimeNotifications`
  /// to decide `exactAllowWhileIdle` vs. `inexactAllowWhileIdle`.
  Future<bool> exactAlarmsEnabled() async {
    await _ensureInitialized();
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  /// Every notification currently scheduled with the OS — read by
  /// `NotificationDiagnosticsScreen` so Ismail can confirm reminders are
  /// actually queued, not just that a preference was saved.
  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    await _ensureInitialized();
    if (!_ready) return const [];
    return _plugin.pendingNotificationRequests();
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required DateTime dateTime,
  }) async {
    await _ensureInitialized();
    if (!_ready) return;
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
          channelDescription: 'تذكير بمهمة يومية حدّدها الطالب لنفسه',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'home',
    );
  }

  Future<void> cancelTaskReminder(int taskId) async {
    await _ensureInitialized();
    if (!_ready) return;
    await _plugin.cancel(id: _taskNotificationIdBase + taskId);
  }

  /// Pushes the "haven't read in a while" reminder [_readingReminderInactiveDays]
  /// days into the future — call every time a student opens any book
  /// (`BookViewerScreen.initState`). Cancelling and rescheduling on every
  /// open means it only actually fires if they go quiet for that many days
  /// in a row; opening any book resets the clock.
  Future<void> scheduleReadingReminder() async {
    await _ensureInitialized();
    if (!_ready) return;
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
      payload: 'reading',
    );
  }

  /// Pushes the Hifz check-in reminder [_hifzReminderInactiveDays] day(s)
  /// into the future — call every time the student checks in on the Hifz
  /// screen. A short 1-day window (vs. the reading reminder's 3) since daily
  /// consistency is the whole point of a memorization streak.
  Future<void> scheduleHifzReminder() async {
    await _ensureInitialized();
    if (!_ready) return;
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
      payload: 'hifz',
    );
  }

  /// Schedules today's reminder for one "خطة ختم" goal, showing its
  /// per-page/per-unit KPI (`dailyTargetLabel`, e.g. "15 صفحة اليوم") — fires
  /// at [hour]:[minute] today if that time hasn't passed yet, else tomorrow
  /// (§2.3 field 8 — a per-goal time, defaulting to the app's original
  /// fixed [_goalReminderHour] for any goal that never set its own).
  /// Callers (`CompletionGoalsScreen`) should call this once per
  /// active goal on load/refresh, and [cancelGoalReminder] the moment
  /// `hasProgressedToday` becomes true or the goal completes, so a student
  /// who already read today never gets nagged.
  Future<void> scheduleGoalReminder({
    required int goalId,
    required String goalTitle,
    required String dailyTargetLabel,
    int? hour,
    int? minute,
  }) async {
    await _ensureInitialized();
    if (!_ready) return;
    final id = _goalReminderNotificationIdBase + goalId;
    await _plugin.cancel(id: id);

    var fireAt = DateTime.now().copyWith(hour: hour ?? _goalReminderHour, minute: minute ?? 0, second: 0, millisecond: 0);
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
      payload: 'goal',
    );
  }

  Future<void> cancelGoalReminder(int goalId) async {
    await _ensureInitialized();
    if (!_ready) return;
    await _plugin.cancel(id: _goalReminderNotificationIdBase + goalId);
  }

  /// Daily adhkar reminders (morning/evening/sleep) — true recurring alarms
  /// via `matchDateTimeComponents: DateTimeComponents.time`, unlike every
  /// other reminder in this file which reschedules itself on each
  /// check-in. Idempotent to call repeatedly (cancels then reschedules) —
  /// call again after any change in `AdhkarNotificationPrefs` (e.g. from
  /// `NotificationSettingsScreen`) to apply it immediately.
  ///
  /// 2026-08-17: each category's default hour now comes from the
  /// student's real, calculated prayer time (Fajr for morning, Asr for
  /// evening, Isha for sleep) when location is available — same
  /// `LocationService` → `PrayerTimesRepository` pattern already proven in
  /// `dayWindowFromPrayerTimes` (`lib/data/adhkar_journey.dart`), with the
  /// same silent fallback to the fixed hours below on any failure. A
  /// student can override any category's hour manually, or disable it
  /// entirely, via `AdhkarNotificationPrefs`.
  Future<void> scheduleAdhkarReminders() async {
    await _ensureInitialized();
    if (!_ready) return;
    final prefs = AdhkarNotificationPrefs();

    int? fajrHour, asrHour, ishaHour;
    try {
      final coords = await LocationService().currentLocation(mayAskPermission: false);
      if (coords != null) {
        final times = await PrayerTimesRepository().prayerTimesFor(coords);
        fajrHour = times.fajr.toLocal().hour;
        asrHour = times.asr.toLocal().hour;
        ishaHour = times.isha.toLocal().hour;
      }
    } catch (_) {
      // Falls back to the fixed hours below.
    }

    final morningMinutes = await _estimatedMinutesForCategory('أذكار الصباح والمساء');
    final sleepMinutes = await _estimatedMinutesForCategory('أذكار النوم');

    await _scheduleAdhkarCategory(
      category: 'morning',
      id: _adhkarMorningNotificationId,
      prefs: prefs,
      defaultHour: fajrHour ?? _adhkarMorningHour,
      title: 'أذكار الصباح 🌅',
      body: '$morningMinutes دقائق فقط ترفع درجتك اليوم — لنبدأ.',
    );
    await _scheduleAdhkarCategory(
      category: 'evening',
      id: _adhkarEveningNotificationId,
      prefs: prefs,
      defaultHour: asrHour ?? _adhkarEveningHour,
      title: 'أذكار المساء 🌇',
      body: '$morningMinutes دقائق فقط تحفظ يومك — لنكمله بذكر.',
    );
    await _scheduleAdhkarCategory(
      category: 'sleep',
      id: _adhkarSleepNotificationId,
      prefs: prefs,
      defaultHour: ishaHour ?? _adhkarSleepHour,
      title: 'أذكار النوم 🌙',
      body: '$sleepMinutes دقائق فقط قبل أن تنام — ختام جميل ليومك.',
    );
  }

  Future<void> _scheduleAdhkarCategory({
    required String category,
    required int id,
    required AdhkarNotificationPrefs prefs,
    required int defaultHour,
    required String title,
    required String body,
  }) async {
    if (!await prefs.isEnabled(category)) {
      await _plugin.cancel(id: id);
      return;
    }
    final hour = await prefs.customHour(category) ?? defaultHour;
    await _scheduleDailyAt(
      id: id,
      hour: hour,
      title: title,
      body: body,
      channelId: _adhkarChannelId,
      channelName: _adhkarChannelName,
      channelDescription: 'تذكير يومي بأذكار الصباح/المساء/النوم، بوقت مرتبط بأوقات الصلاة الفعلية عند توفر الموقع',
      payload: 'adhkar',
    );
  }

  /// Notifies at each of today's 5 real, calculated prayer times — closes
  /// the gap this file's own comments had reserved an id range for since
  /// early in this session (roadmap §4.25) but never actually built.
  /// Unlike the adhkar reminders, prayer times shift every day, so this
  /// can't use `matchDateTimeComponents: DateTimeComponents.time` — it
  /// schedules today's remaining prayers as one-shot alarms and must be
  /// called again (e.g. on next app start) to pick up tomorrow's times.
  /// Silently does nothing if disabled or location isn't available yet —
  /// same graceful-fallback spirit as the adhkar prayer-time anchoring.
  Future<void> schedulePrayerTimeNotifications() async {
    await _ensureInitialized();
    if (!_ready) return;
    final ids = [_fajrNotificationId, _dhuhrNotificationId, _asrNotificationId, _maghribNotificationId, _ishaNotificationId];

    if (!await PrayerNotificationPrefs().isEnabled()) {
      for (final id in ids) {
        await _plugin.cancel(id: id);
      }
      return;
    }

    // 2026-08-17 reliability pass: prayer notifications are the one case
    // in this file where a several-minute Doze delay actually matters
    // (the whole point is "right when the prayer enters"). Uses exact
    // scheduling when the OS has granted it, silently falls back to the
    // existing inexact mode otherwise — never throws, never blocks.
    final exact = await exactAlarmsEnabled();
    final scheduleMode = exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

    // Real licensed adhan audio (CC0, see LICENSED_CONTENT_SOURCES.md) —
    // a distinct channel id when enabled, since Android fixes a channel's
    // sound at creation and ignores changes afterward (see the constants'
    // doc comment above).
    final useAdhanSound = await PrayerNotificationPrefs().useAdhanSound();
    final channelId = useAdhanSound ? _prayerChannelIdAdhan : _prayerChannelId;
    final channelName = useAdhanSound ? _prayerChannelNameAdhan : _prayerChannelName;
    final sound = useAdhanSound ? const RawResourceAndroidNotificationSound(_adhanSoundResource) : null;

    try {
      final coords = await LocationService().currentLocation(mayAskPermission: false);
      if (coords == null) return;
      final times = await PrayerTimesRepository().prayerTimesFor(coords);

      final prayers = [
        (_fajrNotificationId, 'الفجر', times.fajr),
        (_dhuhrNotificationId, 'الظهر', times.dhuhr),
        (_asrNotificationId, 'العصر', times.asr),
        (_maghribNotificationId, 'المغرب', times.maghrib),
        (_ishaNotificationId, 'العشاء', times.isha),
      ];

      final now = DateTime.now();
      for (final (id, name, time) in prayers) {
        await _plugin.cancel(id: id);
        final local = time.toLocal();
        if (local.isBefore(now)) continue; // already passed today
        await _plugin.zonedSchedule(
          id: id,
          title: 'حان وقت صلاة $name 🕌',
          body: 'حي على الصلاة، حي على الفلاح.',
          scheduledDate: tz.TZDateTime.from(local, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: 'تنبيه عند دخول وقت كل صلاة، محسوب من موقعك الفعلي',
              importance: Importance.high,
              priority: Priority.high,
              sound: sound,
              playSound: true,
            ),
          ),
          androidScheduleMode: scheduleMode,
          payload: 'prayer_times',
        );
      }
    } catch (_) {
      // Location/prayer-time lookup failed — leave any previously
      // scheduled notifications as-is rather than clearing them.
    }
  }

  /// Schedules (or re-schedules) a reminder for one custom-picked adhkar
  /// category — called from `AdhkarCategoryScreen`'s "🔔 أضف تذكيرًا" button
  /// and from `NotificationSettingsScreen`'s "أضف ذكرًا" flow.
  Future<void> scheduleCustomAdhkarReminder({required int categoryId, required String categoryTitle, required int hour}) async {
    await _ensureInitialized();
    if (!_ready) return;
    final minutes = await _estimatedMinutesForCategory(categoryTitle);
    await _scheduleDailyAt(
      id: _customAdhkarReminderIdBase + categoryId,
      hour: hour,
      title: '$categoryTitle 🔔',
      body: '$minutes دقائق فقط ترفع درجتك — حان وقتها الآن.',
      channelId: _customAdhkarChannelId,
      channelName: _customAdhkarChannelName,
      channelDescription: 'تذكيرات أذكار اخترتها بنفسك من خارج الصباح/المساء/النوم',
      payload: 'adhkar',
    );
  }

  Future<void> cancelCustomAdhkarReminder(int categoryId) async {
    await _ensureInitialized();
    if (!_ready) return;
    await _plugin.cancel(id: _customAdhkarReminderIdBase + categoryId);
  }

  /// Re-applies every saved custom reminder — call at app startup
  /// alongside `scheduleAdhkarReminders()`, since Android alarms don't
  /// survive some device reboots/updates and this file has no persistent
  /// background scheduler of its own.
  Future<void> scheduleAllCustomAdhkarReminders(List<({int categoryId, String categoryTitle, int hour})> reminders) async {
    for (final r in reminders) {
      await scheduleCustomAdhkarReminder(categoryId: r.categoryId, categoryTitle: r.categoryTitle, hour: r.hour);
    }
  }

  Future<int> _estimatedMinutesForCategory(String title) async {
    try {
      final categories = await AdhkarRepository().allCategories();
      final matches = categories.where((c) => c.title == title);
      if (matches.isEmpty) return 8;
      return await AdhkarRepository().estimatedMinutes(matches.first.id);
    } catch (_) {
      return 8;
    }
  }

  /// "محاسبة الوقت" daily reminder (Ismail's request 2026-08-16): a fixed
  /// evening nudge to log how the day's hours were actually spent
  /// (slept/wasted/studied/worked). Always-recurring like the adhkar
  /// reminders, not reschedule-on-checkin — the whole point is a daily
  /// prompt regardless of yesterday's entry.
  Future<void> scheduleTimeLogReminder() async {
    await _ensureInitialized();
    if (!_ready) return;
    await _scheduleDailyAt(
      id: _timeLogReminderNotificationId,
      hour: _timeLogReminderHour,
      title: 'محاسبة يومك ⏳',
      body: 'قبل أن ينام يومك — سجّل كم نمت، وكم ضاع، وكم درست واشتغلت.',
      channelId: _timeLogChannelId,
      channelName: _timeLogChannelName,
      channelDescription: 'تذكير يومي ثابت بتسجيل محاسبة الوقت',
      payload: 'home',
    );
  }

  /// Shared by every "fixed clock hour, repeats daily" reminder (adhkar,
  /// custom adhkar, time log). 2026-08-17: now also applies
  /// [QuietHoursPrefs] — if the requested hour falls inside the student's
  /// configured quiet window, it's pushed to the window's end instead. Only
  /// shifts *this* scheduling call; it can't recall an alarm the OS already
  /// fired under an earlier schedule (see `QuietHoursPrefs`'s doc comment).
  Future<void> _scheduleDailyAt({
    required int id,
    required int hour,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String payload,
  }) async {
    await _plugin.cancel(id: id);

    final quiet = QuietHoursPrefs();
    final effectiveHour = applyQuietHours(
      hour: hour,
      quietEnabled: await quiet.isEnabled(),
      quietStart: await quiet.startHour(),
      quietEnd: await quiet.endHour(),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, effectiveHour);
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
      payload: payload,
    );
  }

  /// Fires immediately (not scheduled) when [ContentBadgeService] detects
  /// genuinely new admin content (book/banner/announcement) the student
  /// hasn't been notified about yet — see that service for the dedupe logic.
  Future<void> showNewContentNotification(String body) async {
    await _ensureInitialized();
    if (!_ready) return;
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
      payload: 'home',
    );
  }

  /// Schedules TODAY's «مُحرّك الحياة» reminders: one per not-yet-done,
  /// still-upcoming block («⏰ 08:30 — 💻 Python / برمجة» + «اليوم N»),
  /// tonight's «حاسب نفسك» at 21:30 carrying the live done/total, and the
  /// recurring 05:00 morning brief. A no-op (that also clears any stale
  /// reminders) until the engine has been opened once — `life_meta`'s
  /// `start_date` row is the marker, and `meta()` never seeds it. Called
  /// from `main.dart` on start and from `LifePlanScreen` on every
  /// load / resume / midnight, so completed and past blocks drop out on the
  /// next pass. Reschedule-on-open is also what refreshes the copy after a
  /// language change.
  Future<void> scheduleLifePlanReminders() async {
    await _ensureInitialized();
    if (!_ready) return;

    final repo = LifePlanRepository();
    final started = await repo.meta('start_date'); // does NOT seed

    // Clear the whole slot-id band + the fixed one-shot id first, so
    // yesterday's set never lingers.
    for (var id = kLifeSlotReminderIdBase; id <= kLifeSlotReminderIdMax; id++) {
      await _plugin.cancel(id: id);
    }
    await _plugin.cancel(id: kLifeNightlyReviewId);
    if (started == null) {
      await _plugin.cancel(id: kLifeMorningBriefId);
      return;
    }

    final lang = LanguagePreferenceService.currentLanguage;
    final slots = await repo.slots();
    final today = LifePlanRepository.today();
    final done = await repo.doneSlots(today);
    final prog = await repo.progress(today);
    final dayN = (await repo.dayIndex()) + 1;

    final nightlyBody = prog.doneCount == 0
        ? basicText('life_notif_nightly_empty', lang)
        : basicText('life_notif_nightly_done', lang)
            .replaceAll('{done}', '${prog.doneCount}')
            .replaceAll('{total}', '${prog.totalCount}');

    final reminders = planLifeReminders(
      slots: slots,
      doneSlotNos: done,
      now: DateTime.now(),
      slotBody: '${basicText('life_day_word', lang)} $dayN',
      nightlyTitle: basicText('life_notif_nightly_title', lang),
      nightlyBody: nightlyBody,
    );

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _lifeChannelId,
        _lifeChannelName,
        channelDescription: basicText('life_notif_channel_desc', lang),
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime.from(r.fireAt, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: r.payload,
      );
    }

    // Morning brief — recurring & evergreen (no day number, so a day the
    // app isn't opened can't leave it showing a stale count).
    // `_scheduleDailyAt` also folds in the student's quiet-hours window.
    await _scheduleDailyAt(
      id: kLifeMorningBriefId,
      hour: kLifeMorningBriefHour,
      title: basicText('life_notif_morning_title', lang),
      body: basicText('life_notif_morning_body', lang),
      channelId: _lifeChannelId,
      channelName: _lifeChannelName,
      channelDescription: basicText('life_notif_channel_desc', lang),
      payload: 'life',
    );
  }

  /// "رفيق طالب العلم" as a real push (2026-08-17) — call from `main.dart`
  /// on every app start alongside the other daily scheduling. [message] is
  /// gathered by `buildCompanionContext()` + `companionMessageFor()`
  /// (`companion_context_service.dart`), the exact same signals the
  /// in-app `CompanionCard` uses. Null means the rule engine found nothing
  /// worth saying today — the ONE existing check-in (if any) is cancelled
  /// rather than left stale, and nothing new is scheduled. Never spams: a
  /// day with nothing to say gets no notification at all.
  Future<void> scheduleOrCancelCompanionMessage(CompanionMessage? message) async {
    await _ensureInitialized();
    if (!_ready) return;
    if (message == null) {
      await _plugin.cancel(id: _companionNotificationId);
      return;
    }
    await _scheduleDailyAt(
      id: _companionNotificationId,
      hour: _companionCheckInHour,
      title: '${message.title} ${message.icon}',
      body: message.body,
      channelId: _companionChannelId,
      channelName: _companionChannelName,
      channelDescription: 'رسالة يومية من رفيق طالب العلم، فقط عندما يكون لديه شيء مفيد ليقوله',
      payload: 'companion',
    );
  }
}
