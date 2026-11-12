import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/widgets/side_menu_tab.dart';

/// The visible way into every section: one tap opens the menu, and the
/// «كل الأقسام» label is shown only the first three times, then folds away.
void main() {
  Widget host(VoidCallback onOpen) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: Align(alignment: AlignmentDirectional.centerStart, child: SideMenuTab(onOpen: onOpen))),
        ),
      );
  final label = basicText('drawer_title', 'ar');

  testWidgets('tap opens; label shows, then folds after a few seconds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var opened = 0;
    await tester.pumpWidget(host(() => opened++));
    await tester.pumpAndSettle();
    expect(find.text(label), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(label), findsNothing);
    await tester.tap(find.byIcon(Icons.apps_rounded));
    expect(opened, 1);
  });

  testWidgets('after three launches the label no longer appears', (tester) async {
    SharedPreferences.setMockInitialValues({'side_tab_hint_count': 3});
    await tester.pumpWidget(host(() {}));
    await tester.pumpAndSettle();
    expect(find.text(label), findsNothing);
    expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
  });
}
