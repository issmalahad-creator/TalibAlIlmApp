import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/widgets/feedback/talib_action_button.dart';
import 'package:talib_alilm_app/widgets/feedback/talib_navigation.dart';
import 'package:talib_alilm_app/widgets/feedback/talib_pressable.dart';
import 'package:talib_alilm_app/widgets/feedback/talib_skeleton.dart';
import 'package:talib_alilm_app/widgets/feedback/light_trail.dart';
import 'package:talib_alilm_app/widgets/loading_view.dart';

/// IF-1 test matrix (docs/architecture/INTERACTION_FEEDBACK_ARCHITECTURE.md §10).
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  group('TalibActionButton', () {
    testWidgets('fast action: no spinner, no "working" text — just done', (tester) async {
      var runs = 0;
      await tester.pumpWidget(host(TalibActionButton(
        label: 'حفظ',
        successLabel: 'تم الحفظ',
        onPressed: () async => runs++,
      )));
      await tester.tap(find.text('حفظ'));
      await tester.pump(); // action completes within the same turn
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('تم الحفظ'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(runs, 1);
      await tester.pump(const Duration(seconds: 2)); // back to idle
      expect(find.text('حفظ'), findsOneWidget);
    });

    testWidgets('slow action: spinner at 300 ms, contextual text at 800 ms', (tester) async {
      final done = Completer<void>();
      await tester.pumpWidget(host(TalibActionButton(
        label: 'حفظ',
        runningLabel: 'جاري الحفظ…',
        onPressed: () => done.future,
      )));
      await tester.tap(find.text('حفظ'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 150)); // 350 ms
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('جاري الحفظ…'), findsNothing);
      await tester.pump(const Duration(milliseconds: 500)); // 850 ms
      expect(find.text('جاري الحفظ…'), findsOneWidget);
      done.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('rapid repeated taps run the action once', (tester) async {
      var runs = 0;
      final done = Completer<void>();
      await tester.pumpWidget(host(TalibActionButton(
        label: 'تحميل',
        onPressed: () {
          runs++;
          return done.future;
        },
      )));
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byType(FilledButton), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(runs, 1);
      done.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('failure shows plain words + retry, and the next tap retries', (tester) async {
      var runs = 0;
      await tester.pumpWidget(host(TalibActionButton(
        label: 'فتح',
        failureLabel: 'تعذّر فتح الكتاب',
        onPressed: () async {
          runs++;
          if (runs == 1) throw StateError('db locked'); // never shown to the user
        },
      )));
      await tester.tap(find.text('فتح'));
      await tester.pump();
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.textContaining('تعذّر فتح الكتاب'), findsOneWidget);
      expect(find.textContaining('db locked'), findsNothing);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(runs, 2);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('disposed mid-run (user went back) does not throw', (tester) async {
      final done = Completer<void>();
      await tester.pumpWidget(host(TalibActionButton(label: 'حفظ', onPressed: () => done.future)));
      await tester.tap(find.text('حفظ'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox());
      done.complete();
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('TalibPressable', () {
    testWidgets('press visual never steals the child button tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(TalibPressable(
        onTap: null,
        child: FilledButton(onPressed: () => taps++, child: const Text('زر')),
      )));
      await tester.tap(find.text('زر'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);
    });

    testWidgets('sinks while pressed and returns on release', (tester) async {
      await tester.pumpWidget(host(TalibPressable(onTap: () {}, child: const SizedBox(width: 100, height: 60))));
      double scale() => tester.widget<Transform>(find.descendant(of: find.byType(TalibPressable), matching: find.byType(Transform))).transform.entry(0, 0);
      final g = await tester.startGesture(tester.getCenter(find.byType(TalibPressable)));
      // Frames at 40 ms steps: the ticker starts on the first one.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(scale(), lessThan(1.0));
      await g.up();
      await tester.pump(); // reverse starts on this frame
      await tester.pump(const Duration(milliseconds: 250));
      expect(scale(), closeTo(1.0, 0.001));
    });
  });

  group('talibPush', () {
    setUp(resetTalibNavigationForTest);

    testWidgets('three fast taps on the same destination open one page', (tester) async {
      var built = 0;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => talibPush(context, 'open_quran', (_) {
                built++;
                return const Scaffold(body: Text('القرآن'));
              }),
              child: const Text('افتح'),
            ),
          ),
        ),
      ));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('افتح'), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      expect(find.text('القرآن'), findsOneWidget);
      expect(built, 1);
      expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isTrue);
    });

    testWidgets('different destinations are not blocked by each other', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: Text('home'));
      })));
      talibPush(ctx, 'a', (_) => const Scaffold(body: Text('A')));
      await tester.pumpAndSettle();
      Navigator.of(ctx).pop();
      await tester.pumpAndSettle();
      talibPush(ctx, 'b', (_) => const Scaffold(body: Text('B')));
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('AppLoadingView (IF-2 timing tiers)', () {
    Widget view() => const MaterialApp(
          home: Scaffold(body: AppLoadingView(icon: Icons.menu_book, message: 'جاري فتح الكتاب…')),
        );

    testWidgets('a fast load shows nothing at all', (tester) async {
      await tester.pumpWidget(view());
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(LightTrail), findsNothing);
      expect(find.byIcon(Icons.menu_book), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox()); // load finished → view gone
    });

    testWidgets('≥300 ms: icon + light trail; ≥800 ms: the contextual words', (tester) async {
      await tester.pumpWidget(view());
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(LightTrail), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing); // no spinner
      final hidden = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(hidden.opacity, 0);
      await tester.pump(const Duration(milliseconds: 600));
      final shown = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(shown.opacity, 1);
      expect(find.text('جاري فتح الكتاب…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('TalibSkeleton (IF-3)', () {
    Widget host(Widget child) => MaterialApp(home: Scaffold(body: TalibSkeleton(semanticLabel: 'جاري البحث…', child: child)));

    testWidgets('fast load: no skeleton flash before 300 ms', (tester) async {
      await tester.pumpWidget(host(const SkeletonCardList()));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(SkeletonBlock), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('after 300 ms: the content shape, pulsing, no spinner', (tester) async {
      await tester.pumpWidget(host(const SkeletonCardList(count: 3)));
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SkeletonBlock), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('home skeleton renders at phone size without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(host(const SkeletonHome()));
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/skeleton_home.png'));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
