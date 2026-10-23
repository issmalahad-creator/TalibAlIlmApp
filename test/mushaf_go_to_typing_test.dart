import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_alilm_app/widgets/mushaf/mushaf_go_to_sheet.dart';

void main() {
  testWidgets('typing «٣٢٣» on an Arabic keyboard goes to page 323 and remembers where we were', (tester) async {
    SharedPreferences.setMockInitialValues({});
    int? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showMushafGoToSheet(context, current: 5, lang: 'ar'),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '٣٢٣');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(result, 323);
    // and the page we left is offered next time
    expect(await GoToRecents.get(), [5]);
  });
}
