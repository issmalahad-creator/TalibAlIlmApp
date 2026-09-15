import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../theme/app_theme.dart';
import 'qibla_screen.dart' show kaabaLatitude, kaabaLongitude;

/// "المرئية" — Qibla-on-a-map view (Ismail's request 2026-08-16, after
/// seeing a reference app's map mode). Uses OpenStreetMap tiles via
/// `flutter_map` (free, no API key — unlike Google Maps, which would need
/// Ismail's own billing account) with a straight line drawn from the
/// student's location to the Kaaba. A straight line on a flat map isn't the
/// true great-circle path over long distances, but it's the same
/// simplification every consumer Qibla app's map view makes — it still
/// shows the correct bearing at the student's own location, which is what
/// actually matters for orientation.
class QiblaMapView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double distanceKm;

  const QiblaMapView({super.key, required this.latitude, required this.longitude, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final me = ll.LatLng(latitude, longitude);
    const kaaba = ll.LatLng(kaabaLatitude, kaabaLongitude);
    final bounds = LatLngBounds.fromPoints([me, kaaba]);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.talibalilm.app',
            ),
            PolylineLayer(polylines: [
              Polyline(points: [me, kaaba], strokeWidth: 3, color: AppColors.primaryDark),
            ]),
            MarkerLayer(markers: [
              Marker(
                point: me,
                width: 26,
                height: 26,
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary, border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
              Marker(
                point: kaaba,
                width: 34,
                height: 34,
                child: const _KaabaGlyph(size: 34),
              ),
            ]),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(AppRadius.sm), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]),
            child: Text('المسافة إلى الكعبة: ${distanceKm.toStringAsFixed(0)} كم', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}

/// A simple original geometric abstraction of the Kaaba (rounded dark cube
/// with a gold band) — drawn from scratch, not a traced/copied icon.
class _KaabaGlyph extends StatelessWidget {
  final double size;
  const _KaabaGlyph({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white, width: 1.5)),
      child: Align(
        alignment: Alignment.center,
        child: Container(height: size * 0.22, color: const Color(0xFFD9A441)),
      ),
    );
  }
}

double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}
