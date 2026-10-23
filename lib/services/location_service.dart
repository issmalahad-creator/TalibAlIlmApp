import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppCoordinates {
  final double latitude;
  final double longitude;
  final bool isManual;

  /// GPS accuracy radius in meters, when known (a fresh GPS fix only — null
  /// for manual/cached locations, since neither carries a real accuracy
  /// figure). Purely additive info for the Qibla screen's confidence
  /// display (Ismail's 2026-08-16 "قوّي البوصلة... زيادة لا خراب" request)
  /// — doesn't change how the coordinates themselves are used anywhere.
  final double? accuracyMeters;

  const AppCoordinates({required this.latitude, required this.longitude, this.isManual = false, this.accuracyMeters});
}

/// Why no fresh GPS fix could be had — lets a screen say exactly what to
/// do («turn location on», «allow access») instead of a vague failure.
enum LocationProblem { serviceOff, denied, deniedForever, noFix }

/// Location for Phase 9 (Qibla + prayer times) — QURAN_COMPANION_ROADMAP.md.
/// Tries a real GPS fix first; if permission is denied or the signal is
/// unavailable, falls back to the last-known fix, then to a manually
/// entered location (persisted via shared_preferences) — the student is
/// never simply stuck with no prayer times because of a GPS hiccup.
class LocationService {
  static const _latKey = 'manual_location_lat';
  static const _lngKey = 'manual_location_lng';
  static const _cachedLatKey = 'last_known_lat';
  static const _cachedLngKey = 'last_known_lng';

  /// Returns a usable location, or null if neither GPS nor a manual/cached
  /// location is available yet — callers must handle that (prompt for
  /// manual entry), never silently guess a coordinate.
  ///
  /// [mayAskPermission] is false for background work (startup notification
  /// scheduling): it uses GPS only if permission was already granted, else
  /// the manual/cached location — the system dialog is only ever shown from
  /// a screen the user opened (prayer times, qibla), never out of nowhere
  /// over Home (docs/architecture/ZERO_WAIT_PROGRESSIVE_ARCHITECTURE.md ZW-4).
  /// Set by the last [currentLocation] call when GPS gave nothing.
  LocationProblem? lastProblem;

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<AppCoordinates?> currentLocation({bool mayAskPermission = true}) async {
    lastProblem = null;
    final prefs = await SharedPreferences.getInstance();
    // A location the user chose (typed, or picked as a city) wins over GPS
    // until they clear it — it used to be read only when GPS failed, so on
    // a phone with working GPS «أدخل موقعك يدويًا» silently did nothing.
    final manualLat = prefs.getDouble(_latKey);
    final manualLng = prefs.getDouble(_lngKey);
    if (manualLat != null && manualLng != null) {
      return AppCoordinates(latitude: manualLat, longitude: manualLng, isManual: true);
    }

    final gps = await _tryGps(mayAskPermission: mayAskPermission);
    if (gps != null) {
      await _cacheLocation(gps.latitude, gps.longitude);
      return gps;
    }

    final cachedLat = prefs.getDouble(_cachedLatKey);
    final cachedLng = prefs.getDouble(_cachedLngKey);
    if (cachedLat != null && cachedLng != null) {
      return AppCoordinates(latitude: cachedLat, longitude: cachedLng);
    }

    return null;
  }

  Future<AppCoordinates?> _tryGps({required bool mayAskPermission}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        lastProblem = LocationProblem.serviceOff;
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && mayAskPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        lastProblem = LocationProblem.deniedForever;
        return null;
      }
      if (permission == LocationPermission.denied) {
        lastProblem = LocationProblem.denied;
        return null;
      }

      // 1) Google's fused provider; 2) the phone's own LocationManager —
      // phones without Google services (and some with a broken one) only
      // answer the second; 3) the last fix either one remembers.
      for (final forceManager in [false, true]) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 12),
              forceLocationManager: forceManager,
            ),
          );
          return AppCoordinates(latitude: position.latitude, longitude: position.longitude, accuracyMeters: position.accuracy);
        } catch (_) {
          // try the next provider
        }
      }
      for (final forceManager in [false, true]) {
        try {
          final last = await Geolocator.getLastKnownPosition(forceAndroidLocationManager: forceManager);
          if (last != null) {
            return AppCoordinates(latitude: last.latitude, longitude: last.longitude, accuracyMeters: last.accuracy);
          }
        } catch (_) {}
      }
      lastProblem = LocationProblem.noFix;
      return null;
    } catch (_) {
      // Any platform failure just means "no GPS fix right now" — callers
      // fall back to cached/manual location instead of crashing.
      lastProblem = LocationProblem.noFix;
      return null;
    }
  }

  Future<void> _cacheLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cachedLatKey, lat);
    await prefs.setDouble(_cachedLngKey, lng);
  }

  /// Throws [ArgumentError] outside ±90 / ±180.
  Future<void> setManualLocation(double lat, double lng) async {
    if (lat.abs() > 90 || lng.abs() > 180) throw ArgumentError('lat/lng out of range');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, lat);
    await prefs.setDouble(_lngKey, lng);
  }

  Future<void> clearManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_latKey);
    await prefs.remove(_lngKey);
  }
}
