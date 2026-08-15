import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppCoordinates {
  final double latitude;
  final double longitude;
  final bool isManual;
  const AppCoordinates({required this.latitude, required this.longitude, this.isManual = false});
}

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
  Future<AppCoordinates?> currentLocation() async {
    final gps = await _tryGps();
    if (gps != null) {
      await _cacheLocation(gps.latitude, gps.longitude);
      return gps;
    }

    final prefs = await SharedPreferences.getInstance();
    final manualLat = prefs.getDouble(_latKey);
    final manualLng = prefs.getDouble(_lngKey);
    if (manualLat != null && manualLng != null) {
      return AppCoordinates(latitude: manualLat, longitude: manualLng, isManual: true);
    }

    final cachedLat = prefs.getDouble(_cachedLatKey);
    final cachedLng = prefs.getDouble(_cachedLngKey);
    if (cachedLat != null && cachedLng != null) {
      return AppCoordinates(latitude: cachedLat, longitude: cachedLng);
    }

    return null;
  }

  Future<AppCoordinates?> _tryGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
      );
      return AppCoordinates(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      // Any platform/timeout failure just means "no GPS fix right now" —
      // callers fall back to cached/manual location instead of crashing.
      return null;
    }
  }

  Future<void> _cacheLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cachedLatKey, lat);
    await prefs.setDouble(_cachedLngKey, lng);
  }

  Future<void> setManualLocation(double lat, double lng) async {
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
