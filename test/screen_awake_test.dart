import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_alilm_app/services/screen_awake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <Object?>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('talib_alilm/screen'), (c) async {
      calls.add(c.arguments);
      return null;
    });
  });

  test('stacked readers keep the screen on until the last one leaves', () async {
    await ScreenAwake.acquire(); // muṣḥaf
    await ScreenAwake.acquire(); // a Turath book on top
    await ScreenAwake.release();
    expect(calls.last, true);
    await ScreenAwake.release();
    expect(calls.last, false);
  });

  test('turning the setting off clears the flag while reading', () async {
    await ScreenAwake.acquire();
    expect(calls.last, true);
    await ScreenAwake.setEnabled(false);
    expect(calls.last, false);
    await ScreenAwake.release();
    await ScreenAwake.setEnabled(true);
    expect(calls.last, false);
  });
}
