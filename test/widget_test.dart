import 'package:flutter_test/flutter_test.dart';

import 'package:talib_alilm_app/main.dart';

void main() {
  testWidgets('App launches without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const TalibAlIlmApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
