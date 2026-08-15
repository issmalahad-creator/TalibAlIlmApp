import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/startup_gate.dart';
import 'services/book_content_service.dart';
import 'services/content_badge_service.dart';
import 'services/notification_service.dart';
import 'services/quran_import_service.dart';
import 'theme/app_theme.dart';
import 'utils/hijri_date.dart';

void main() {
  initHijriLocale();
  runApp(const TalibAlIlmApp());
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

  @override
  void initState() {
    super.initState();
    _quranImportService.importIfNeeded();
    _checkBookContent();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _checkBookContent();
      }
    });
    _notificationService.init();
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
    return MaterialApp(
      title: 'طالب العلم',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const StartupGate(),
    );
  }
}
