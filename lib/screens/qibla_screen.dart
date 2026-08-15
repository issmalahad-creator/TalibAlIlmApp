import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../repositories/prayer_times_repository.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// "اتجاه القبلة" — QURAN_COMPANION_ROADMAP.md Phase 9. Bearing to the
/// Kaaba is computed via `adhan_dart`'s verified great-circle formula, not
/// derived here. The compass heading comes from `flutter_compass` (device
/// magnetometer, fused with the accelerometer at the platform level) — its
/// `accuracy` value (radians of uncertainty on Android; often null/unknown
/// on iOS) drives an honest confidence indicator instead of ever silently
/// claiming a precise direction from unstable sensors.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final _locationService = LocationService();
  final _prayerRepo = PrayerTimesRepository();

  double? _qiblaBearing;
  AppCoordinates? _coordinates;
  bool _loading = true;
  bool _noLocation = false;
  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;
  double? _headingAccuracy;

  @override
  void initState() {
    super.initState();
    _load();
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      setState(() {
        _heading = event.heading;
        _headingAccuracy = event.accuracy;
      });
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final coords = await _locationService.currentLocation();
    if (coords == null) {
      if (!mounted) return;
      setState(() {
        _noLocation = true;
        _loading = false;
      });
      return;
    }
    final bearing = _prayerRepo.qiblaBearing(coords);
    if (!mounted) return;
    setState(() {
      _coordinates = coords;
      _qiblaBearing = bearing;
      _noLocation = false;
      _loading = false;
    });
  }

  /// Confidence tier from the compass's own reported accuracy — never
  /// upgraded/guessed past what the sensor actually reports.
  (String, Color) get _confidence {
    final acc = _headingAccuracy;
    if (_heading == null) return ('لا توجد بيانات من البوصلة', AppColors.textMuted);
    if (acc == null) return ('دقة البوصلة غير معروفة على هذا الجهاز', AppColors.textMuted);
    final accDegrees = acc * 180 / pi;
    if (accDegrees < 15) return ('دقة عالية', AppColors.primary);
    if (accDegrees < 40) return ('دقة متوسطة — قد تحتاج معايرة', const Color(0xFFB8860B));
    return ('دقة ضعيفة — حرّك هاتفك برسم ٨ لمعايرة البوصلة', Colors.redAccent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اتجاه القبلة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _noLocation
              ? _NoLocationView(onRetry: _load)
              : _buildCompass(),
    );
  }

  Widget _buildCompass() {
    final heading = _heading;
    final qibla = _qiblaBearing ?? 0;
    final (confidenceLabel, confidenceColor) = _confidence;

    // Rotation needed so the needle points at the Kaaba direction relative
    // to the phone's current heading.
    final needleAngle = heading == null ? 0.0 : ((qibla - heading) * pi / 180);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider, width: 2),
                    color: AppColors.surface,
                  ),
                ),
                Transform.rotate(
                  angle: heading == null ? 0 : -heading * pi / 180,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Align(alignment: Alignment.topCenter, child: Text('N', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                  ),
                ),
                Transform.rotate(
                  angle: needleAngle,
                  child: const Icon(Icons.navigation, size: 90, color: AppColors.primaryDark),
                ),
                const Icon(Icons.mosque, size: 22, color: AppColors.primary),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('اتجاه القبلة: ${qibla.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: confidenceColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(confidenceLabel, style: TextStyle(fontSize: 12, color: confidenceColor, fontWeight: FontWeight.w700)),
              ),
              if (_coordinates?.isManual == true) ...[
                const SizedBox(height: 8),
                const Text('يُستخدم موقع مُدخَل يدويًا — دقة الاتجاه تعتمد على دقة الإحداثيات المدخلة', style: TextStyle(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 6),
              const Text(
                'وجّه أعلى الهاتف نحو السهم — إن كانت الدقة ضعيفة، حرّك الهاتف على شكل ٨ لمعايرة البوصلة',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoLocationView extends StatelessWidget {
  final VoidCallback onRetry;
  const _NoLocationView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('لم نتمكن من تحديد موقعك', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('يحتاج اتجاه القبلة إلى موقعك — من شاشة "أوقات الصلاة" يمكنك إدخاله يدويًا', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
