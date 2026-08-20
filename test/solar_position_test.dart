import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/solar_position.dart';

void main() {
  group('SolarPosition.fromHourAngle azimuth sign convention', () {
    // At solar transit (hour angle = 0) the sun is mathematically guaranteed
    // to sit exactly on the observer's meridian: due South (azimuth 180°)
    // when the observer's latitude is north of the sun's declination, due
    // North (azimuth 0°) when it's south of it. This is a hard invariant,
    // not a remembered textbook number — if the azimuth formula's sign is
    // wrong, this fails immediately instead of shipping a Qibla-adjacent
    // feature that quietly points the wrong way.
    test('latitude north of declination -> due South at transit', () {
      final pos = SolarPosition.fromHourAngle(hourAngleDegrees: 0, declinationDegrees: 10, latitudeDegrees: 30);
      expect(pos.azimuthDegrees, closeTo(180, 0.001));
      expect(pos.altitudeDegrees, closeTo(90 - (30 - 10).abs(), 0.001));
    });

    test('latitude south of declination -> due North at transit', () {
      final pos = SolarPosition.fromHourAngle(hourAngleDegrees: 0, declinationDegrees: 23, latitudeDegrees: 10);
      expect(pos.azimuthDegrees, closeTo(0, 0.001));
      expect(pos.altitudeDegrees, closeTo(90 - (10 - 23).abs(), 0.001));
    });

    test('negative declination (southern-hemisphere summer), still due South at transit for a northern latitude', () {
      final pos = SolarPosition.fromHourAngle(hourAngleDegrees: 0, declinationDegrees: -20, latitudeDegrees: 15);
      expect(pos.azimuthDegrees, closeTo(180, 0.001));
    });

    // Sanity check on the other side of transit: for a northern mid-latitude
    // observer with positive (summer) declination, the sun sets north of
    // due West — a well-known, easily-checked qualitative fact.
    test('summer declination at a northern latitude sets north of due West', () {
      final pos = SolarPosition.fromHourAngle(hourAngleDegrees: 90, declinationDegrees: 15, latitudeDegrees: 30);
      expect(pos.azimuthDegrees, greaterThan(270));
      expect(pos.azimuthDegrees, lessThan(360));
    });
  });

  group('SolarPosition.forLocation', () {
    test('returns an altitude within [-90, 90] and azimuth within [0, 360) for a real date/time', () {
      final pos = SolarPosition.forLocation(latitude: 9.03, longitude: 38.74, utc: DateTime.utc(2026, 8, 17, 9, 0));
      expect(pos.altitudeDegrees, inInclusiveRange(-90, 90));
      expect(pos.azimuthDegrees, greaterThanOrEqualTo(0));
      expect(pos.azimuthDegrees, lessThan(360));
    });
  });
}
