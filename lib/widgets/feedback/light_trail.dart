import 'package:flutter/material.dart';

/// The app's one indeterminate "working" mark: a hair-thin gold rule with a
/// point of light gliding across it — the same motion as the brand splash, so
/// waiting looks like one family everywhere, never a generic spinner
/// (docs/architecture/INTERACTION_FEEDBACK_ARCHITECTURE.md §6).
///
/// Give it an [animation] that loops 0→1 (the splash shares its ambient
/// controller); [passes] glides happen per loop.
class LightTrail extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double width;
  final int passes;

  const LightTrail({
    super.key,
    required this.animation,
    this.color = kLightTrailGold,
    this.width = 86,
    this.passes = 4,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: 10,
        child: CustomPaint(painter: LightTrailPainter(animation, color, passes: passes)),
      ),
    );
  }
}

/// The brand gold used by [LightTrail] (and the splash's gold rule/dust).
const kLightTrailGold = Color(0xFFC9A24A);

class LightTrailPainter extends CustomPainter {
  final Animation<double> t;
  final Color color;
  final int passes;
  LightTrailPainter(this.t, this.color, {this.passes = 4}) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..strokeWidth = 1,
    );
    // Eased so the light lingers at the ends — slow, steady motion reads as
    // a shorter wait than fast motion.
    final p = Curves.easeInOutSine.transform((t.value * passes) % 1.0);
    final x = size.width * p;
    canvas.drawCircle(
      Offset(x, y),
      5,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(Offset(x, y), 1.8, Paint()..color = color);
  }

  @override
  bool shouldRepaint(LightTrailPainter old) => old.color != color || old.passes != passes;
}
