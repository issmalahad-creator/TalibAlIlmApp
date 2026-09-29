import 'dart:io';

import 'package:flutter/material.dart' show SizedBox;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/main.dart';

/// Real smoke test: the whole app tree mounts and renders its first frames
/// without throwing. The app's `main()` isn't run here (that's the platform
/// entrypoint) — the widget is pumped directly, so this test stands up the
/// things `main()` normally would: an FFI SQLite factory, a temp DB, mocked
/// `SharedPreferences`, and no-op handlers for the plugin channels the app
/// pokes on launch (path_provider, notifications, timezone, connectivity,
/// package info). Everything else (asset-backed seeds, guarded network) runs
/// for real.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final tmp = Directory.systemTemp.createTempSync('talib_widget_smoke');

  setUpAll(() {
    DatabaseHelper.databaseName = 'talib_widget_smoke.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();
    SharedPreferences.setMockInitialValues({});

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Plugin method channels the app touches during initState — return
    // harmless defaults so nothing rejects on a plain test VM.
    for (final channel in const [
      'plugins.flutter.io/path_provider',
      'plugins.flutter.io/path_provider_android',
      'plugins.flutter.io/path_provider_macos',
      'dexterous.com/flutter/local_notifications',
      'flutter_timezone',
      'dev.fluttercommunity.plus/connectivity',
      'dev.fluttercommunity.plus/package_info',
      'plugins.flutter.io/package_info',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), (call) async {
        switch (call.method) {
          case 'getTemporaryDirectory':
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationSupportDirectory':
          case 'getApplicationCacheDirectory':
          case 'getLibraryDirectory':
          case 'getTemporaryPath':
          case 'getApplicationDocumentsPath':
          case 'getApplicationSupportPath':
          case 'getApplicationCachePath':
          case 'getLibraryPath':
            return tmp.path;
          case 'getExternalStorageDirectories':
          case 'getExternalStoragePaths':
            return <String>[tmp.path];
          case 'getLocalTimezone':
            return 'UTC';
          case 'check':
          case 'getConnectivity':
            return 'wifi';
          case 'getAll':
            return <String, Object?>{'appName': 'talib', 'packageName': 'x', 'version': '1', 'buildNumber': '1'};
          case 'pendingNotificationRequests':
          case 'getActiveNotifications':
            return <Object?>[];
          default:
            return null;
        }
      });
    }
    // connectivity's event channel (onConnectivityChanged) — never emits,
    // which is fine: the app just doesn't get a connectivity callback.
    messenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (args, sink) {}),
    );
  });

  tearDownAll(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('App launches without throwing', (tester) async {
    await tester.pumpWidget(const TalibAlIlmApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(TalibAlIlmApp), findsOneWidget);

    // The app deliberately arms timers at launch — the splash's reading /
    // max-visible timers (≤12 s) and BootScheduler's 4 s safety net. Unmount
    // and let fake time run past them so the test ends with none pending
    // (the binding fails a test that leaves a Timer behind).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 15));
  });
}
