import 'dart:math';

// Reusing adhan_dart's own already-tested astronomical primitives (right
// ascension/declination/sidereal time, and the trusted altitude formula)
// instead of re-deriving them — the safer choice for a worship-adjacent
// calculation than a second hand-rolled implementation. These aren't
// exported from the package's public barrel file, hence the explicit lint
// suppression rather than a silent `flutter analyze` regression.
// ignore: implementation_imports
import 'package:adhan_dart/src/Astronomical.dart';
// ignore: implementation_imports
import 'package:adhan_dart/src/MathUtils.dart';
// ignore: implementation_imports
import 'package:adhan_dart/src/SolarCoordinates.dart';

/// Real-time solar altitude/azimuth — powers "تحديد القبلة بالشمس"
/// (100_IDEAS_FOR_IMPROVEMENT.md's Qibla-accuracy request). Reuses
/// `adhan_dart`'s own right-ascension/declination/apparent-sidereal-time
/// (`SolarCoordinates`) and its already-trusted `altitudeOfCelestialBody`
/// formula — the exact same numbers this app already relies on for real
/// prayer-time calculations, not a second implementation. The only new
/// piece is the azimuth transform, split out as [fromHourAngle] so it can
/// be unit-tested against a hard mathematical invariant (at solar transit,
/// H=0, the sun is exactly due South or due North depending on whether
/// latitude exceeds declination) instead of trusting a remembered formula —
/// see `test/solar_position_test.dart`. Azimuth is degrees from North,
/// clockwise — the same compass convention `heading`/`qiblaBearing` already
/// use everywhere else in `qibla_screen.dart`.
class SolarPosition {
  final double altitudeDegrees;
  final double azimuthDegrees;
  const SolarPosition({required this.altitudeDegrees, required this.azimuthDegrees});

  factory SolarPosition.forLocation({required double latitude, required double longitude, required DateTime utc}) {
    final jd = Astronomical.julianDay(utc.year, utc.month, utc.day, utc.hour + utc.minute / 60 + utc.second / 3600);
    final coords = SolarCoordinates(jd);
    final hourAngle = unwindAngle(coords.apparentSiderealTime + longitude - coords.rightAscension!);
    return SolarPosition.fromHourAngle(
      hourAngleDegrees: hourAngle,
      declinationDegrees: coords.declination!,
      latitudeDegrees: latitude,
    );
  }

  /// Pure equatorial→horizontal transform (Astronomical Algorithms ch.13),
  /// isolated from Julian-day/sidereal-time plumbing so it's directly
  /// testable. `hourAngleDegrees` follows `adhan_dart`'s own sign
  /// convention (positive = west of the local meridian, i.e. afternoon) —
  /// the same H already used internally by `Astronomical.correctedHourAngle`.
  factory SolarPosition.fromHourAngle({
    required double hourAngleDegrees,
    required double declinationDegrees,
    required double latitudeDegrees,
  }) {
    final altitude = Astronomical.altitudeOfCelestialBody(latitudeDegrees, declinationDegrees, hourAngleDegrees);

    final phi = degreesToRadians(latitudeDegrees);
    final delta = degreesToRadians(declinationDegrees);
    final h = degreesToRadians(hourAngleDegrees);
    final azimuthRad = atan2(-sin(h), tan(delta) * cos(phi) - sin(phi) * cos(h));
    final azimuth = unwindAngle(radiansToDegrees(azimuthRad));

    return SolarPosition(altitudeDegrees: altitude, azimuthDegrees: azimuth);
  }
}
