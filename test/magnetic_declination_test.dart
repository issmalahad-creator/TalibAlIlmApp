import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/magnetic_declination.dart';

/// Reference values: NOAA's WMM2025 coefficients evaluated by the
/// independent `pygeomag` 1.1.0 implementation at decimal year 2026.78.
void main() {
  final when = DateTime(2026, 10, 12, 12);
  const cases = <(String, double, double, double)>[
    ('Addis Ababa', 9.03, 38.74, 2.198),
    ('Makkah', 21.42, 39.83, 3.501),
    ('Cairo', 30.04, 31.24, 4.771),
    ('London', 51.5, -0.13, 1.21),
    ('New York', 40.7, -74.0, -12.464),
    ('Reykjavik', 64.1, -21.9, -11.013),
    ('Sydney', -33.9, 151.2, 12.836),
    ('Jakarta', -6.2, 106.8, 0.647),
    ('Helsinki', 60.2, 24.9, 10.474),
    ('Utqiagvik', 71.0, -156.0, 10.486),
    ('Ushuaia', -54.8, -68.3, 11.631),
    ('0,0', 0, 0, -3.797),
  ];
  for (final (name, lat, lng, expected) in cases) {
    test('declination at $name', () {
      expect(MagneticDeclination.degrees(lat, lng, when: when), closeTo(expected, 0.05));
    });
  }
}
