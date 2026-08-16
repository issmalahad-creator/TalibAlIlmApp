import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';

import '../theme/app_theme.dart';
import 'qibla_map_view.dart' show haversineDistanceKm;
import 'qibla_screen.dart' show kaabaLatitude, kaabaLongitude;
import '../widgets/loading_view.dart';

/// Assumed horizontal field of view of a typical rear phone camera — the
/// `camera` package doesn't expose the real per-device FOV, so this is a
/// documented approximation (same one comparable Qibla-AR apps effectively
/// use), not a guessed-and-forgotten magic number.
const _assumedFovDeg = 60.0;

/// "الواقع المعزز" — camera-background Qibla view (Ismail's request
/// 2026-08-16, strengthened same day, then fixed again same day after he
/// reported two concrete regressions on-device: had to tilt the phone back
/// toward flat/"raise the camera up" for the reading to settle, and the
/// direction was reversed).
///
/// Root cause of both, found by working through the actual rotation math
/// rather than guessing: `flutter_rotation_sensor`'s default `azimuth` is
/// the compass bearing of the phone's TOP edge (its body Y-axis) — correct
/// for the flat-held compass dial (`QiblaScreen`'s `_CompassView`), but
/// wrong for this view. Held vertically like a camera, the top-of-phone
/// axis points mostly toward the sky, so its horizontal component shrinks
/// toward zero — a near-gimbal-lock condition where tiny sensor noise
/// swings the reported azimuth wildly, which only settles once the phone is
/// tilted back toward flat (exactly Ismail's "أرفع الكاميرا" symptom); and
/// using the wrong body axis for "which way the lens points" also explains
/// a heading that reads rotated/reversed from what the user expects.
///
/// The fix: this view computes its own bearing directly from the
/// orientation event's rotation matrix, using the body **-Z axis** (the
/// direction the back camera actually looks) instead of the Y axis. Column
/// 2 of the rotation matrix (`c`, `f`, `i`) is the world-frame
/// representation of the body Z axis — `atan2(-c, -f)` is therefore the
/// compass bearing of the back camera's line of sight. Verified by
/// reproducing the package's own documented default-azimuth formula
/// algebraically from the same matrix before trusting this derivation.
/// Held-vertically, that axis is naturally close to horizontal, so it
/// avoids the gimbal-lock zone entirely instead of requiring the user to
/// compensate by tilting the phone. Falls back to `widget.heading` (the
/// flat-oriented heading `QiblaScreen` computes for the compass tab) if the
/// rotation sensor errors out on a device without a gyroscope — imperfect
/// in this posture, but better than nothing.
///
/// Also from that same research pass:
/// - The marker's screen position is a real FOV-based projection (assumed
///   ~60° horizontal FOV) instead of a linear `diff/90` hack — once the
///   Qibla direction leaves that field of view the glyph is replaced by an
///   edge arrow telling the student which way to turn and by how much,
///   instead of a marker awkwardly clamped at the screen edge.
/// - A low-accuracy banner (reusing the same accuracy tiering as the compass
///   tab) prompts the "figure-8" magnetometer recalibration real compass
///   apps rely on, instead of silently showing a possibly-wrong direction.
class QiblaArView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? headingAccuracy;
  final double qiblaBearing;

  const QiblaArView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.qiblaBearing,
    this.headingAccuracy,
  });

  @override
  State<QiblaArView> createState() => _QiblaArViewState();
}

class _QiblaArViewState extends State<QiblaArView> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _permissionDenied = false;
  bool _noCamera = false;

  StreamSubscription<OrientationEvent>? _orientationSub;
  double? _cameraBearingDeg;
  double? _smoothedPitchDeg;
  double? _pitchBaselineDeg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _initOrientationTracking();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _noCamera = true);
        return;
      }
      final back = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      final controller = CameraController(back, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  /// Local subscription, deliberately separate from `QiblaScreen`'s own —
  /// that one is tuned for the flat-held compass dial and would carry the
  /// gimbal-lock/wrong-axis problem into this view if reused. Computes both
  /// the camera-facing bearing (see class doc comment for the derivation)
  /// and pitch (for the small vertical nudge) from the same event stream.
  void _initOrientationTracking() {
    try {
      RotationSensor.samplingPeriod = SensorInterval.gameInterval;
      _orientationSub = RotationSensor.orientationStream.listen(
        (event) {
          if (!mounted) return;
          final m = event.rotationMatrix;
          final rawBearingDeg = (atan2(-m.c, -m.f) * 180 / pi) % 360;
          final rawPitchDeg = event.eulerAngles.pitch * 180 / pi;
          setState(() {
            _cameraBearingDeg = _smoothHeading(_cameraBearingDeg, rawBearingDeg, 0.18);
            _pitchBaselineDeg ??= rawPitchDeg;
            _smoothedPitchDeg = (_smoothedPitchDeg ?? rawPitchDeg) + (rawPitchDeg - (_smoothedPitchDeg ?? rawPitchDeg)) * 0.18;
          });
        },
        onError: (_) {
          // Device without a gyroscope/rotation-vector sensor — falls back
          // to widget.heading below; the vertical nudge stays at 0.
        },
      );
    } catch (_) {
      // Package unavailable on this platform build — same fallback.
    }
  }

  /// Exponential smoothing aware that headings wrap at 360°/0° — a naive
  /// average of e.g. 359° and 1° would wrongly produce 180° instead of 0°.
  double _smoothHeading(double? previous, double target, double alpha) {
    if (previous == null) return target;
    final delta = ((target - previous + 540) % 360) - 180;
    var result = (previous + delta * alpha) % 360;
    if (result < 0) result += 360;
    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
      _orientationSub?.cancel();
      _orientationSub = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
      _initOrientationTracking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _orientationSub?.cancel();
    super.dispose();
  }

  /// Same accuracy tiering `_CompassView` uses on the compass tab — kept
  /// local rather than shared since it only needs a pass/fail banner here.
  String? get _lowAccuracyWarning {
    final acc = widget.headingAccuracy;
    if (acc == null) return null;
    final accDegrees = acc * 180 / pi;
    if (accDegrees < 40) return null;
    return 'دقة البوصلة ضعيفة — حرّك الهاتف على شكل ٨ لمعايرتها';
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return const _ArMessage(icon: Icons.no_photography_outlined, text: 'يحتاج هذا الوضع إذن الكاميرا — فعّله من إعدادات الجهاز للتطبيق');
    }
    if (_noCamera) {
      return const _ArMessage(icon: Icons.camera_alt_outlined, text: 'لا توجد كاميرا متاحة على هذا الجهاز');
    }
    final controller = _controller;
    if (controller == null) {
      return const AppLoadingView(icon: Icons.camera_alt_outlined, message: 'جاري تشغيل الكاميرا...');
    }

    final distanceKm = haversineDistanceKm(widget.latitude, widget.longitude, kaabaLatitude, kaabaLongitude);
    final effectiveHeading = _cameraBearingDeg ?? widget.heading;
    final diff = effectiveHeading == null ? 0.0 : ((widget.qiblaBearing - effectiveHeading + 540) % 360) - 180; // -180..180
    final facingQibla = diff.abs() < 8;
    final withinFov = diff.abs() <= _assumedFovDeg / 2;

    final pitchDelta = (_smoothedPitchDeg != null && _pitchBaselineDeg != null) ? (_smoothedPitchDeg! - _pitchBaselineDeg!).clamp(-40.0, 40.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final xFraction = (diff / (_assumedFovDeg / 2)).clamp(-1.0, 1.0);
        final offsetX = xFraction * (constraints.maxWidth / 2);
        final offsetY = (pitchDelta / 40.0) * (constraints.maxHeight * 0.12);

        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            if (withinFov)
              Positioned(
                top: constraints.maxHeight * 0.35 - offsetY,
                left: constraints.maxWidth / 2 + offsetX - 32,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.85),
                    border: Border.all(color: facingQibla ? Colors.white : const Color(0xFFD9A441), width: 3),
                    boxShadow: [BoxShadow(color: (facingQibla ? AppColors.primary : const Color(0xFFD9A441)).withValues(alpha: 0.6), blurRadius: 14, spreadRadius: 2)],
                  ),
                  child: const Icon(Icons.mosque, color: Colors.white, size: 30),
                ),
              )
            else
              Positioned(
                top: constraints.maxHeight * 0.35 - 26,
                left: diff > 0 ? constraints.maxWidth - 60 : 12,
                child: _TurnArrow(turnRight: diff > 0, degrees: diff.abs().round()),
              ),
            if (_lowAccuracyWarning != null)
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(12)),
                  child: Text(_lowAccuracyWarning!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    Text(
                      facingQibla
                          ? 'أنت تواجه القبلة الآن 🕋'
                          : withinFov
                              ? 'حرّك الهاتف حتى تصل الأيقونة للمنتصف'
                              : 'استدر ${diff > 0 ? 'يمينًا' : 'يسارًا'} حتى تظهر الكعبة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: facingQibla ? AppColors.primaryLight : Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text('${distanceKm.toStringAsFixed(0)} كم إلى الكعبة', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Off-screen guidance shown once the Qibla direction leaves the assumed
/// camera field of view — tells the student which way to turn and by how
/// much, instead of a marker awkwardly pinned to the screen edge.
class _TurnArrow extends StatelessWidget {
  final bool turnRight;
  final int degrees;
  const _TurnArrow({required this.turnRight, required this.degrees});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(turnRight ? Icons.chevron_right : Icons.chevron_left, color: const Color(0xFFD9A441), size: 34),
          Text('$degrees°', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}

class _ArMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ArMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
