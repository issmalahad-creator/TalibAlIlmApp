import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A small static percent ring — a grey track + a gold-gradient progress arc
/// with the percentage centered inside. Modeled on the `_DayRing`/
/// `_RingPainter` pair in `lib/screens/life_plan_screen.dart` (private
/// there, generalized here with a size/stroke-width parameter instead of
/// copy-pasting their hardcoded 132px/gold-gradient version).
///
/// Deliberately NOT animated (no `TweenAnimationBuilder`/
/// `AnimationController`, unlike `_DayRing`): its first user is `_GoalCard`
/// in `completion_goal_list_view.dart`, a card that has already broken once
/// from an unrelated widget (`FilledButton.tonal`) leaving its list layout
/// permanently unresolved for a reason never fully root-caused. Avoiding a
/// Ticker-driven widget here is a deliberate precaution, not an oversight —
/// a static paint delivers the same visual (ring + centered percentage)
/// with materially lower risk in that specific context.
class CircularPercentGauge extends StatelessWidget {
  final int percent; // 0..100, clamped defensively
  final double size;
  final double strokeWidth;
  const CircularPercentGauge({super.key, required this.percent, this.size = 44, this.strokeWidth = 5});

  @override
  Widget build(BuildContext context) {
    final v = (percent / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PercentRingPainter(v, strokeWidth),
        child: Center(
          child: Text(
            '$percent%',
            style: TextStyle(fontSize: size * 0.28, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
        ),
      ),
    );
  }
}

class _PercentRingPainter extends CustomPainter {
  final double v; // 0..1
  final double strokeWidth;
  _PercentRingPainter(this.v, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - strokeWidth / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFFE5E7EB);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(colors: [Color(0xFFE8C877), Color(0xFFD9A441)])
          .createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, track);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * v, false, arc);
  }

  @override
  bool shouldRepaint(covariant _PercentRingPainter old) => old.v != v || old.strokeWidth != strokeWidth;
}
