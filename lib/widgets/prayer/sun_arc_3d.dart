import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The day as the sun's path (Ismail 2026-10-22: «2D إلى 3D»): a tilted arc
/// from Fajr through Isha, each prayer a marker on it, the sun sitting where
/// "now" is. The next prayer's marker is raised and gold. Night (before
/// Fajr / after Isha) puts a crescent at the arc's end instead of the sun.
class SunArc3D extends StatelessWidget {
  /// The six times in order: fajr, sunrise, dhuhr, asr, maghrib, isha.
  final List<DateTime> times;
  final List<String> labels;
  final int? nextIndex;
  final DateTime now;
  const SunArc3D({super.key, required this.times, required this.labels, required this.nextIndex, required this.now});

  /// 0..1 along the arc for [t]: Fajr = 0, Isha = 1.
  static double position(List<DateTime> times, DateTime t) {
    final a = times.first.millisecondsSinceEpoch.toDouble();
    final b = times.last.millisecondsSinceEpoch.toDouble();
    if (b <= a) return 0;
    return ((t.millisecondsSinceEpoch - a) / (b - a)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final dir = Directionality.of(context);
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateX(0.5),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: position(times, now)),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, p, _) => CustomPaint(
            painter: _ArcPainter(
              stops: [for (final t in times) position(times, t)],
              labels: labels,
              next: nextIndex,
              sun: p,
              night: now.isBefore(times.first) || now.isAfter(times.last),
              rtl: dir == TextDirection.rtl,
              labelStyle: DefaultTextStyle.of(context).style,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final List<double> stops;
  final List<String> labels;
  final int? next;
  final double sun;
  final bool night;
  final bool rtl;
  final TextStyle labelStyle;
  _ArcPainter({
    required this.stops,
    required this.labels,
    required this.next,
    required this.sun,
    required this.night,
    required this.rtl,
    required this.labelStyle,
  });

  /// Point on the arc for 0..1 — the day runs right→left in RTL.
  Offset _at(Size s, double f) {
    final x0 = 24.0, x1 = s.width - 24;
    final t = rtl ? 1 - f : f;
    final x = x0 + (x1 - x0) * t;
    final ground = s.height - 34;
    final h = s.height - 58;
    final y = ground - math.sin(math.pi * t) * h;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size s) {
    const gold = Color(0xFFD9A441);
    final ground = s.height - 34;

    // sky glow under the arc
    final sky = Path()..moveTo(_at(s, 0).dx, ground);
    for (var i = 0; i <= 60; i++) {
      final p = _at(s, i / 60);
      sky.lineTo(p.dx, p.dy);
    }
    sky.lineTo(_at(s, 1).dx, ground);
    sky.close();
    canvas.drawPath(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gold.withValues(alpha: night ? 0.05 : 0.22), gold.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & s),
    );

    // horizon
    canvas.drawLine(Offset(8, ground), Offset(s.width - 8, ground),
        Paint()..color = const Color(0x33000000)..strokeWidth = 1);

    // the path: walked part solid gold, the rest dashed (at night the whole
    // day ahead is still to come)
    final sun = night ? -1.0 : this.sun;
    final walked = Path(), ahead = Path();
    for (var i = 0; i <= 120; i++) {
      final f = i / 120;
      final p = _at(s, f);
      final path = f <= sun ? walked : ahead;
      if (i == 0 || (f > sun && (i - 1) / 120 <= sun)) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(walked, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
    for (final m in ahead.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, math.min(d + 4.5, m.length)),
            Paint()..color = const Color(0x55000000)..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }

    // prayer markers
    for (var i = 0; i < stops.length; i++) {
      final p = _at(s, stops[i]);
      final isNext = i == next;
      final passed = stops[i] <= sun && !night;
      final r = isNext ? 7.0 : 5.0;
      canvas.drawCircle(p + const Offset(0, 2), r, Paint()..color = Colors.black.withValues(alpha: 0.18));
      canvas.drawCircle(p, r, Paint()..color = isNext ? gold : (passed ? const Color(0xFF2E7D5B) : Colors.white));
      canvas.drawCircle(p, r, Paint()..color = const Color(0x55000000)..style = PaintingStyle.stroke..strokeWidth = 1);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: labelStyle.copyWith(
            fontSize: isNext ? 12 : 10.5,
            fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
            color: isNext ? const Color(0xFF8A5A00) : const Color(0xFF555555),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      // labels alternate above/below so neighbours never collide
      final below = i.isOdd;
      tp.paint(canvas, Offset(p.dx - tp.width / 2, below ? p.dy + 9 : p.dy - 11 - tp.height));
    }

    // the sun — or a crescent at night
    if (night) {
      final c = _at(s, 1) + const Offset(0, -26);
      canvas.drawCircle(c, 11, Paint()..color = const Color(0xFFF2E3B3));
      canvas.drawCircle(c + Offset(rtl ? -5 : 5, -3), 10, Paint()..color = const Color(0xFFF7F3EC));
    } else {
      final c = _at(s, sun);
      canvas.drawCircle(c, 20, Paint()..color = gold.withValues(alpha: 0.18));
      canvas.drawCircle(
        c,
        11,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0xFFFFF3C4), Color(0xFFF2B33D)])
              .createShader(Rect.fromCircle(center: c, radius: 11)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter o) =>
      o.sun != sun || o.next != next || o.night != night || o.labels != labels;
}
