import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'repositories/adhkar_repository.dart';
import 'repositories/custom_adhkar_reminder_repository.dart';
import 'repositories/milestone_repository.dart';
import 'repositories/mushaf_layout_sync.dart';
import 'repositories/quran_corpus_sync.dart';
import 'repositories/quran_learning_sync.dart';
import 'repositories/turath_catalog_sync.dart';
import 'screens/adhkar_screen.dart';
import 'screens/completion_goals_screen.dart';
import 'screens/knowledge_review_screen.dart';
import 'screens/personal_library_screen.dart';
import 'screens/prayer_times_screen.dart';
import 'screens/quran_browse_screen.dart';
import 'screens/startup_gate.dart';
import 'services/book_content_service.dart';
import 'services/calendar_preference_service.dart';
import 'services/companion_context_service.dart';
import 'services/companion_engine.dart';
import 'services/content_badge_service.dart';
import 'services/language_preference_service.dart';
import 'services/notification_service.dart';
import 'services/quran_import_service.dart';
import 'services/text_scale_preference_service.dart';
import 'theme/app_theme.dart';
import 'utils/hijri_date.dart';
import 'widgets/companion_floating_bubble.dart';
import 'widgets/restart_widget.dart';

/// Global navigator so a tapped notification's `payload` can open the
/// right screen even from outside the widget tree (background tap /
/// cold-start launch) — 2026-08-17 deep-linking pass. Every payload maps
/// to a screen that already exists; unrecognized payloads (or 'home') do
/// nothing, since the tap has already brought the app to its default
/// screen.
final navigatorKey = GlobalKey<NavigatorState>();

void _routeForPayload(String payload) {
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;
  final category = payload.split(':').first;
  final Widget? screen = switch (category) {
    'prayer_times' => const PrayerTimesScreen(),
    'adhkar' => const AdhkarScreen(),
    'quran_review' || 'companion' => const KnowledgeReviewScreen(),
    'goal' => const CompletionGoalsScreen(),
    'hifz' => const QuranBrowseScreen(),
    'reading' => const PersonalLibraryScreen(),
    _ => null,
  };
  if (screen != null) navigator.push(MaterialPageRoute(builder: (_) => screen));
}

/// 2026-08-17 (Ismail's "زرار ابدأ يودي إلى صفحة فارغة" report on
/// `quran_browse_screen.dart`, a screen that already has a documented
/// prior "shows blank instead of the list, no reliable repro" bug):
/// Flutter's *default* `ErrorWidget` — what actually renders if a
/// screen's `build()` throws partway through — is a near-invisible grey
/// box with no text in release builds, which looks exactly like "a blank
/// page" from a screenshot. This makes any future render crash, anywhere
/// in the app, show a real message instead of silently looking empty —
/// turns an undiagnosable "blank" report into an actionable one.
void _installErrorWidgetBuilder() {
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFFFBF6EE),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                const SizedBox(height: 10),
                Text(
                  'حدث خطأ غير متوقع في عرض هذه الشاشة:\n${details.exceptionAsString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorWidgetBuilder();
  initHijriLocale();
  await CalendarPreferenceService.load();
  await TextScalePreferenceService.load();
  // Was never actually called before 2026-08-17 — the saved language
  // preference silently never took effect on relaunch. See
  // `LanguagePreferenceService`'s doc comment for the full bug list.
  await LanguagePreferenceService.load();
  runApp(const RestartWidget(child: TalibAlIlmApp()));
}

class TalibAlIlmApp extends StatefulWidget {
  const TalibAlIlmApp({super.key});

  @override
  State<TalibAlIlmApp> createState() => _TalibAlIlmAppState();
}

class _TalibAlIlmAppState extends State<TalibAlIlmApp> {
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  final _notificationService = NotificationService();
  final _bookContentService = BookContentService();
  final _quranImportService = QuranImportService();
  final _turathCatalogSync = TurathCatalogSync();
  final _mushafLayoutSync = MushafLayoutSync();
  final _quranCorpusSync = QuranCorpusSync();
  final _quranLearningSync = QuranLearningSync();
  final _milestoneRepository = MilestoneRepository();

  @override
  void initState() {
    super.initState();
    _quranImportService.importIfNeeded();
    _turathCatalogSync.syncCatalog();
    _mushafLayoutSync.sync();
    _quranCorpusSync.sync();
    _quranLearningSync.sync();
    _milestoneRepository.seedIfNeeded();
    _notificationService.scheduleAdhkarReminders();
    _notificationService.scheduleTimeLogReminder();
    _notificationService.schedulePrayerTimeNotifications();
    _scheduleCustomAdhkarReminders();
    _scheduleCompanionCheckIn();
    _checkBookContent();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _checkBookContent();
      }
    });
    NotificationService.onNotificationTap = _routeForPayload;
    _notificationService.init().then((_) async {
      final launchPayload = await _notificationService.getLaunchPayload();
      if (launchPayload != null) _routeForPayload(launchPayload);
    });
  }

  /// "رفيق طالب العلم" push check-in (2026-08-17) — gathers the same
  /// context the in-app `CompanionCard` uses and only actually schedules a
  /// notification if the rule engine has something to say today.
  Future<void> _scheduleCompanionCheckIn() async {
    final message = companionMessageFor(await buildCompanionContext());
    await _notificationService.scheduleOrCancelCompanionMessage(message);
  }

  /// Re-applies every custom adhkar reminder on app start — Android alarms
  /// don't survive some device reboots/updates, and this file has no
  /// persistent background scheduler of its own (same reasoning as the
  /// fixed morning/evening/sleep reminders above).
  Future<void> _scheduleCustomAdhkarReminders() async {
    final saved = await CustomAdhkarReminderRepository().all();
    if (saved.isEmpty) return;
    final categories = await AdhkarRepository().allCategories();
    final titleFor = {for (final c in categories) c.id: c.title};
    await _notificationService.scheduleAllCustomAdhkarReminders([
      for (final r in saved)
        if (titleFor[r.categoryId] != null) (categoryId: r.categoryId, categoryTitle: titleFor[r.categoryId]!, hour: r.hour),
    ]);
  }

  Future<void> _checkBookContent() async {
    final feed = await _bookContentService.fetch();
    await ContentBadgeService.instance.checkForUnseen(feed);
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: TextScalePreferenceService.scaleNotifier,
      builder: (context, textScale, _) => ValueListenableBuilder<String>(
        valueListenable: LanguagePreferenceService.languageNotifier,
        builder: (context, language, _) {
          // Fall back to English chrome for the 2 offered languages
          // Flutter's own Material/Widgets/Cupertino localizations don't
          // cover (Hausa/Somali) — the app's own `basicText()` labels
          // still show correctly regardless, this only affects built-in
          // widgets like date pickers.
          final frameworkLocale = LanguagePreferenceService.frameworkSupportedLanguages.contains(language) ? language : 'en';
          final direction = LanguagePreferenceService.rtlLanguages.contains(language) ? TextDirection.rtl : TextDirection.ltr;
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'طالب العلم',
            debugShowCheckedModeBanner: false,
            locale: Locale(frameworkLocale),
            supportedLocales: const [
              Locale('ar'), Locale('en'), Locale('am'), Locale('bn'), Locale('fa'),
              Locale('fr'), Locale('id'), Locale('ms'), Locale('sw'), Locale('tr'), Locale('ur'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildAppTheme(),
            builder: (context, child) => Directionality(
              textDirection: direction,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
                // Floating companion bubble ("من اي صفحة" — Ismail,
                // 2026-08-18) lives here, above the Navigator, so it stays
                // reachable across every pushed screen instead of only the
                // 4 main-shell tabs.
                child: Stack(children: [child!, const CompanionFloatingBubble()]),
              ),
            ),
            home: const StartupGate(),
          );
        },
      ),
    );
  }
}
