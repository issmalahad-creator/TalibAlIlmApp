import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'qibla_map_view.dart' show haversineDistanceKm;
import 'qibla_screen.dart' show kaabaLatitude, kaabaLongitude;

/// "الواقع المعزز" — camera-background Qibla view (Ismail's request
/// 2026-08-16). This is deliberately heading-based, not true ARCore
/// plane-anchoring (no `ar_flutter_plugin`/ARCore dependency added, which
/// would be a much heavier, less reliable addition for what's really just
/// an orientation aid): a live camera preview with the Kaaba glyph
/// horizontally offset by the angular difference between the device's
/// compass heading and the real Qibla bearing — centered exactly when
/// you're facing Qibla, sliding toward the edge as you turn away, same
/// practical effect a Qibla app's camera mode gives someone even though
/// it isn't 3D-anchored to the room.
class QiblaArView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double? heading;
  final double qiblaBearing;

  const QiblaArView({super.key, required this.latitude, required this.longitude, required this.heading, required this.qiblaBearing});

  @override
  State<QiblaArView> createState() => _QiblaArViewState();
}

class _QiblaArViewState extends State<QiblaArView> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _permissionDenied = false;
  bool _noCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
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
      return const Center(child: CircularProgressIndicator());
    }

    final distanceKm = haversineDistanceKm(widget.latitude, widget.longitude, kaabaLatitude, kaabaLongitude);
    final heading = widget.heading;
    final diff = heading == null ? 0.0 : ((widget.qiblaBearing - heading + 540) % 360) - 180; // -180..180
    final facingQibla = diff.abs() < 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Off-center by up to half the screen width as the angular
        // difference approaches 90°+ — clamped so the glyph never leaves
        // the visible area entirely.
        final offsetX = (diff / 90).clamp(-1.4, 1.4) * (constraints.maxWidth / 2);
        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            Positioned(
              top: constraints.maxHeight * 0.35,
              left: constraints.maxWidth / 2 + offsetX - 32,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
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
                      facingQibla ? 'أنت تواجه القبلة الآن 🕋' : 'حرّك الهاتف حتى تصل الأيقونة للمنتصف',
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
