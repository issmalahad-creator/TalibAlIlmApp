import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../repositories/prayer_times_repository.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'qibla_ar_view.dart';
import 'qibla_map_view.dart';

/// Exact Kaaba coordinates verified against `adhan_dart`'s own
/// `Qibla.makkah` constant (`Coordinates(21.4225241, 39.8261818)`,
/// `adhan_dart-2.0.1/lib/src/Qibla.dart`) — the same source the bearing
/// calculation itself already trusts, not a separately-guessed value.
const kaabaLatitude = 21.4225241;
const kaabaLongitude = 39.8261818;

enum _QiblaMethod { compass, map, ar, sunMoon }

/// "اتجاه القبلة" — QURAN_COMPANION_ROADMAP.md Phase 9, redesigned
/// 2026-08-16 into a 4-method tabbed screen (Ismail's explicit request,
/// after comparing against a reference app and asking Claude to research
/// almosaly.com — see roadmap §4.28's honest gap analysis: multi-method
/// Qibla was the one real, locally-buildable gap found). Every method
/// shares the exact same underlying bearing/location data — only the
/// presentation differs. Original visuals throughout (CustomPainter dial,
/// hand-drawn Kaaba glyph, heading-based camera overlay) — matching the
/// reference's information density and structure, never its actual assets.
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
  _QiblaMethod _method = _QiblaMethod.compass;

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
      appBar: AppBar(title: const Text('القبلة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _noLocation
              ? _NoLocationView(onRetry: _load)
              : Column(
                  children: [
                    _MethodTabs(current: _method, onChanged: (m) => setState(() => _method = m)),
                    Expanded(child: _buildBody()),
                  ],
                ),
    );
  }

  Widget _buildBody() {
    final coords = _coordinates!;
    switch (_method) {
      case _QiblaMethod.compass:
        return _CompassView(
          qiblaBearing: _qiblaBearing ?? 0,
          heading: _heading,
          confidence: _confidence,
          isManualLocation: coords.isManual,
        );
      case _QiblaMethod.map:
        return QiblaMapView(
          latitude: coords.latitude,
          longitude: coords.longitude,
          distanceKm: haversineDistanceKm(coords.latitude, coords.longitude, kaabaLatitude, kaabaLongitude),
        );
      case _QiblaMethod.ar:
        return QiblaArView(
          latitude: coords.latitude,
          longitude: coords.longitude,
          heading: _heading,
          qiblaBearing: _qiblaBearing ?? 0,
        );
      case _QiblaMethod.sunMoon:
        return const _ComingSoonView();
    }
  }
}

class _MethodTabs extends StatelessWidget {
  final _QiblaMethod current;
  final ValueChanged<_QiblaMethod> onChanged;
  const _MethodTabs({required this.current, required this.onChanged});

  static const _tabs = [
    (_QiblaMethod.compass, 'البوصلة', Icons.explore_outlined),
    (_QiblaMethod.map, 'المرئية', Icons.map_outlined),
    (_QiblaMethod.ar, 'الواقع المعزز', Icons.view_in_ar_outlined),
    (_QiblaMethod.sunMoon, 'الشمس والقمر', Icons.wb_twighlight),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      child: Row(
        children: _tabs.map((t) {
          final (method, label, icon) = t;
          final selected = method == current;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(method),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected ? Colors.white : Colors.transparent, width: 3))),
                child: Column(
                  children: [
                    Icon(icon, size: 18, color: selected ? Colors.white : Colors.white54),
                    const SizedBox(height: 3),
                    Text(label, style: TextStyle(fontSize: 10, color: selected ? Colors.white : Colors.white54, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CompassView extends StatelessWidget {
  final double qiblaBearing;
  final double? heading;
  final (String, Color) confidence;
  final bool isManualLocation;

  const _CompassView({required this.qiblaBearing, required this.heading, required this.confidence, required this.isManualLocation});

  @override
  Widget build(BuildContext context) {
    final (confidenceLabel, confidenceColor) = confidence;
    final needleAngle = heading == null ? 0.0 : ((qiblaBearing - heading!) * pi / 180);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: heading == null ? 0 : -heading! * pi / 180,
                  child: CustomPaint(size: const Size(280, 280), painter: _DialPainter()),
                ),
                Transform.rotate(
                  angle: needleAngle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _NeedleGlyph(),
                      Container(margin: const EdgeInsets.only(top: 100), width: 3, height: 60, color: AppColors.primaryDark),
                    ],
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'اتجاه القبلة', value: '${qiblaBearing.toStringAsFixed(1)}°')),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'من الشمال', value: heading == null ? '—' : '${((qiblaBearing - heading!) % 360).toStringAsFixed(0)}°')),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: confidenceColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(Icons.explore, size: 18, color: confidenceColor),
              const SizedBox(width: 8),
              Expanded(child: Text(confidenceLabel, style: TextStyle(fontSize: 12.5, color: confidenceColor, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
        if (isManualLocation) ...[
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
    );
  }
}

class _NeedleGlyph extends StatelessWidget {
  const _NeedleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white, width: 1.5)),
      child: Align(alignment: Alignment.center, child: Container(height: 8, color: const Color(0xFFD9A441))),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Original decorative compass dial — tick marks every 5° (longer every
/// 30°), the 8 cardinal/intercardinal labels, and a plain ring. Hand-drawn
/// with `Canvas` primitives, not traced from any reference app's artwork.
class _DialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    canvas.drawCircle(center, radius, Paint()..color = AppColors.surface);
    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.divider);

    final tickPaint = Paint()..color = AppColors.textMuted;
    for (var deg = 0; deg < 360; deg += 5) {
      final isMajor = deg % 30 == 0;
      final angle = deg * pi / 180;
      final outer = Offset(center.dx + radius * sin(angle), center.dy - radius * cos(angle));
      final inner = Offset(center.dx + (radius - (isMajor ? 14 : 7)) * sin(angle), center.dy - (radius - (isMajor ? 14 : 7)) * cos(angle));
      canvas.drawLine(outer, inner, tickPaint..strokeWidth = isMajor ? 2 : 1);
    }

    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < labels.length; i++) {
      final angle = i * 45 * pi / 180;
      final pos = Offset(center.dx + (radius - 28) * sin(angle), center.dy - (radius - 28) * cos(angle));
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(fontSize: labels[i] == 'N' ? 14 : 11, fontWeight: FontWeight.w800, color: labels[i] == 'N' ? Colors.redAccent : AppColors.textDark),
      );
      textPainter.layout();
      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => false;
}

class _ComingSoonView extends StatelessWidget {
  const _ComingSoonView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_twighlight, size: 40, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'تحديد القبلة بالشمس والقمر — قريبًا',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              'يحتاج حساب موقع الشمس/القمر الفلكي وقت الاستخدام — لم نضفه بعد حتى نتأكد من دقته قبل عرضه، بدل عرض شيء قد يكون غير دقيق',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
