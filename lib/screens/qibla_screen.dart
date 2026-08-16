import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';

import '../repositories/prayer_times_repository.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'qibla_ar_view.dart';
import 'qibla_map_view.dart';
import '../widgets/loading_view.dart';

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
  StreamSubscription<OrientationEvent>? _fusedSub;
  double? _heading;
  double? _headingAccuracy;
  double? _fusedHeading;
  _QiblaMethod _method = _QiblaMethod.compass;

  /// The heading actually used for every bearing calculation on this screen
  /// — Ismail's 2026-08-16 "قوّي البوصلة للأجهزة القديمة" request. Prefers
  /// `flutter_rotation_sensor`'s gyroscope-fused, smoothed heading (stable
  /// even on devices with a noisy magnetometer); falls back to the plain
  /// `flutter_compass` reading on devices without a gyroscope/rotation-vector
  /// sensor (older/cheaper hardware) so the feature still works there, just
  /// without the extra stability.
  double? get _effectiveHeading => _fusedHeading ?? _heading;

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
    _initFusedHeading();
  }

  void _initFusedHeading() {
    try {
      RotationSensor.samplingPeriod = SensorInterval.gameInterval;
      _fusedSub = RotationSensor.orientationStream.listen(
        (event) {
          if (!mounted) return;
          final rawHeadingDeg = (event.eulerAngles.azimuth * 180 / pi) % 360;
          setState(() => _fusedHeading = _smoothHeading(_fusedHeading, rawHeadingDeg, 0.18));
        },
        onError: (_) {
          // No gyroscope/rotation-vector sensor on this device — stays on
          // the plain flutter_compass heading via _effectiveHeading.
        },
      );
    } catch (_) {
      // flutter_rotation_sensor unsupported on this platform build.
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
  void dispose() {
    _compassSub?.cancel();
    _fusedSub?.cancel();
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
    if (_effectiveHeading == null) return ('لا توجد بيانات من البوصلة', AppColors.textMuted);
    if (acc == null) return ('دقة البوصلة غير معروفة على هذا الجهاز', AppColors.textMuted);
    final accDegrees = acc * 180 / pi;
    // Ismail's 2026-08-16 "استمر في نقاط التحسين" follow-up — showing the
    // actual degree figure alongside the tier label, same spirit as the
    // location-accuracy addition just before this one (never hide the raw
    // number behind only a qualitative label).
    final degText = '~${accDegrees.round()}°';
    if (accDegrees < 15) return ('دقة عالية ($degText)', AppColors.primary);
    if (accDegrees < 40) return ('دقة متوسطة ($degText) — قد تحتاج معايرة', const Color(0xFFB8860B));
    return ('دقة ضعيفة ($degText) — حرّك هاتفك برسم ٨ لمعايرة البوصلة', Colors.redAccent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القبلة')),
      body: _loading
          ? const AppLoadingView(icon: Icons.explore_outlined, message: 'جاري تحديد موقعك لحساب اتجاه القبلة بدقة...')
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
          heading: _effectiveHeading,
          confidence: _confidence,
          isManualLocation: coords.isManual,
          locationAccuracyMeters: coords.accuracyMeters,
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
          heading: _effectiveHeading,
          headingAccuracy: _headingAccuracy,
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

  /// GPS accuracy radius in meters, when a fresh fix carried one — Ismail's
  /// 2026-08-16 "زد من قوتها... زيادة لا خراب" request. Purely additive
  /// info alongside the existing heading-accuracy confidence line: the
  /// compass can be perfectly stable while the *location* it's aiming from
  /// is still coarse, and that's a real, separate source of Qibla error the
  /// screen didn't previously surface at all.
  final double? locationAccuracyMeters;

  const _CompassView({
    required this.qiblaBearing,
    required this.heading,
    required this.confidence,
    required this.isManualLocation,
    this.locationAccuracyMeters,
  });

  /// Same "never upgrade past what the sensor reports" spirit as the
  /// heading-accuracy tiering above, just for location instead.
  (String, Color)? get _locationConfidence {
    final acc = locationAccuracyMeters;
    if (acc == null) return null;
    if (acc < 20) return ('دقة الموقع عالية (~${acc.round()} م)', AppColors.primary);
    if (acc < 100) return ('دقة الموقع متوسطة (~${acc.round()} م)', const Color(0xFFB8860B));
    return ('دقة الموقع ضعيفة (~${acc.round()} م) — قد يزيح اتجاه القبلة قليلًا', Colors.redAccent);
  }

  /// Light-up gold glow color (Ismail's 2026-08-16 "اجعل البوصلة تضيء عند
  /// الوصول إلى القبلة" request) — the same accent already used elsewhere in
  /// the app for highlighted/focus states, not a new one-off color.
  static const _glowColor = Color(0xFFD9A441);

  /// Human-friendly cardinal name for the Qibla bearing — Ismail's
  /// 2026-08-16 "استمر في نقاط التحسين" follow-up. 8-direction resolution
  /// (not 16) — precise enough to be useful ("roughly north-east") without
  /// implying false precision from a single degree number alone.
  static const _cardinalNames = ['الشمال', 'الشمال الشرقي', 'الشرق', 'الجنوب الشرقي', 'الجنوب', 'الجنوب الغربي', 'الغرب', 'الشمال الغربي'];

  static String _cardinalDirection(double bearingDeg) {
    final index = ((bearingDeg % 360) / 45).round() % 8;
    return _cardinalNames[index];
  }

  @override
  Widget build(BuildContext context) {
    final (confidenceLabel, confidenceColor) = confidence;
    final needleAngle = heading == null ? 0.0 : ((qiblaBearing - heading!) * pi / 180);
    final diff = heading == null ? null : ((qiblaBearing - heading! + 540) % 360) - 180;
    final facingQibla = diff != null && diff.abs() < 8;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: facingQibla
                  ? [BoxShadow(color: _glowColor.withValues(alpha: 0.65), blurRadius: 36, spreadRadius: 6)]
                  : const [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: heading == null ? 0 : -heading! * pi / 180,
                  child: CustomPaint(size: const Size(280, 280), painter: _DialPainter(litUp: facingQibla, glowColor: _glowColor)),
                ),
                Transform.rotate(
                  angle: needleAngle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NeedleGlyph(litUp: facingQibla, glowColor: _glowColor),
                      Container(
                        margin: const EdgeInsets.only(top: 100),
                        width: 3,
                        height: 60,
                        color: facingQibla ? _glowColor : AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: facingQibla ? _glowColor : AppColors.primaryDark),
                ),
              ],
            ),
          ),
        ),
        if (facingQibla) ...[
          const SizedBox(height: 12),
          Text('أنت تواجه القبلة الآن 🕋', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _glowColor)),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'اتجاه القبلة', value: '${qiblaBearing.toStringAsFixed(1)}°', subtitle: _cardinalDirection(qiblaBearing))),
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
        if (_locationConfidence != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: _locationConfidence!.$2.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: _locationConfidence!.$2),
                const SizedBox(width: 8),
                Expanded(child: Text(_locationConfidence!.$1, style: TextStyle(fontSize: 12.5, color: _locationConfidence!.$2, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ],
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
        const SizedBox(height: 10),
        // Honest disclosure, not a silent gap — Ismail's 2026-08-16
        // "استمر في نقاط التحسين" follow-up. The compass reads magnetic
        // north, not true north; the geographic bearing above doesn't have
        // that error at all, so the map tab is a genuinely independent
        // cross-check rather than just "another view of the same number."
        const Text(
          'ملاحظة: البوصلة تعتمد الشمال المغناطيسي، وقد يظهر فرق بسيط بضع درجات حسب موقعك — للتأكد، قارن مع تبويب "المرئية" فهو محسوب جغرافيًا مباشرة بلا اعتماد على البوصلة',
          style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _NeedleGlyph extends StatelessWidget {
  final bool litUp;
  final Color glowColor;
  const _NeedleGlyph({required this.litUp, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: litUp ? glowColor : Colors.white, width: litUp ? 2.5 : 1.5),
        boxShadow: litUp ? [BoxShadow(color: glowColor.withValues(alpha: 0.7), blurRadius: 10, spreadRadius: 1)] : const [],
      ),
      child: Align(alignment: Alignment.center, child: Container(height: 8, color: glowColor)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  /// Optional small line under the value — added for the cardinal-direction
  /// name (Ismail's 2026-08-16 "استمر في نقاط التحسين" follow-up). Purely
  /// additive: existing callers that don't pass it are unaffected.
  final String? subtitle;
  const _StatCard({required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(subtitle!, style: const TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
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
  final bool litUp;
  final Color glowColor;
  const _DialPainter({required this.litUp, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    canvas.drawCircle(center, radius, Paint()..color = AppColors.surface);
    if (litUp) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = glowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = litUp ? glowColor : AppColors.divider);

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
  bool shouldRepaint(covariant _DialPainter oldDelegate) => oldDelegate.litUp != litUp;
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
