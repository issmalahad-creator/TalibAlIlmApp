import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_alilm_app/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a chosen location wins over GPS, and clearing it hands back to GPS/cache', () async {
    SharedPreferences.setMockInitialValues({'last_known_lat': 9.0, 'last_known_lng': 38.7});
    final s = LocationService();
    await s.setManualLocation(21.42, 39.83);
    final chosen = await s.currentLocation(mayAskPermission: false);
    expect(chosen!.isManual, isTrue);
    expect(chosen.latitude, 21.42);

    await s.clearManualLocation();
    // no GPS plugin in tests → falls through to the cached fix
    final back = await s.currentLocation(mayAskPermission: false);
    expect(back!.isManual, isFalse);
    expect(back.latitude, 9.0);
  });

  test('impossible coordinates are refused', () async {
    SharedPreferences.setMockInitialValues({});
    expect(() => LocationService().setManualLocation(200, 10), throwsArgumentError);
    expect(() => LocationService().setManualLocation(10, -181), throwsArgumentError);
  });
}
