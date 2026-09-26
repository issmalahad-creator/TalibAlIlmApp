import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/config/app_version.dart';
import 'package:talib_alilm_app/services/boot/boot_scheduler.dart';
import 'package:talib_alilm_app/widgets/brand_splash.dart';

void main() {
  final boot = BootScheduler.instance;
  setUp(boot.resetForTest);
  tearDown(boot.resetForTest);

  test('kAppVersion matches pubspec version name', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final name = RegExp(r'^version:\s*([^+\s]+)', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(kAppVersion, name);
  });

  /// Lets pending timers fire, then drives the 520 ms exit animation to its end.
  Future<void> settleExit(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  Widget app() => const MaterialApp(
        home: BrandSplashGate(
          minVisible: Duration(milliseconds: 600),
          maxVisible: Duration(seconds: 5),
          child: Scaffold(body: Text('HOME')),
        ),
      );

  testWidgets('splash covers the first screen until it reports ready', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(BrandSplash), findsOneWidget);
    // The real screen is already built underneath (zero-wait), just covered.
    expect(find.text('HOME'), findsOneWidget);

    boot.markOnboardingShown(); // min time already elapsed → leaves now
    await settleExit(tester);
    expect(find.byType(BrandSplash), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a fast first screen still gets the minimum brand moment', (tester) async {
    await tester.pumpWidget(app());
    boot.markOnboardingShown();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BrandSplash), findsOneWidget); // not a flash
    await tester.pump(const Duration(milliseconds: 400)); // min reached
    await settleExit(tester);
    expect(find.byType(BrandSplash), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('safety valve: splash never holds the app hostage', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(seconds: 5)); // never marked ready
    await settleExit(tester);
    expect(find.byType(BrandSplash), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('loader + status only appear once the wait is real', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 500));
    final early = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first);
    expect(early.opacity, 0);
    await tester.pump(const Duration(seconds: 1));
    final later = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first);
    expect(later.opacity, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
