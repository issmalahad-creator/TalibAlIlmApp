import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A 33-bead misbaḥa seen at an angle (Ismail 2026-10-22: «2D إلى 3D»):
/// the beads ride a tilted ring, nearer ones larger and brighter, and each
/// tasbīḥa slides the ring one bead toward you. Beads already counted in
/// this round are dark wood; the rest are pale. Painted — no assets.
class Misbaha3D extends StatelessWidget {
  final int count;
  final bool complete;
  final Widget center;
  const Misbaha3D({super.key, required this.count, required this.complete, required this.center});

  static const beads = 33;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: count.toDouble()),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, turn, _) => SizedBox(
          width: 280,
          height: 230,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(size: const Size(280, 230), painter: _RingPainter(turn, count, complete, back: true)),
            Padding(padding: const EdgeInsets.only(bottom: 18), child: center),
            CustomPaint(size: const Size(280, 230), painter: _RingPainter(turn, count, complete, back: false)),
          ]),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double turn;
  final int count;
  final bool complete;
  final bool back;
  _RingPainter(this.turn, this.count, this.complete, {required this.back});

  @override
  void paint(Canvas canvas, Size s) {
    const n = Misbaha3D.beads;
    final c = Offset(s.width / 2, s.height / 2 + 6);
    final rx = s.width * 0.44, ry = s.height * 0.30;
    // the round so far: beads 0..done-1 (counted from the front) are wood
    final done = count == 0 ? 0 : ((count - 1) % n) + 1;

    final items = <(double depth, Offset p, double r, bool counted, bool front)>[];
    for (var i = 0; i < n; i++) {
      // bead i sits at the front when i == turn (mod n)
      final a = math.pi / 2 + (i - turn) * 2 * math.pi / n;
      final depth = math.sin(a); // 1 = nearest, -1 = farthest
      if (back != (depth < 0)) continue;
      final p = c + Offset(math.cos(a) * rx, depth * ry);
      final r = 7.0 + 4.0 * (depth + 1) / 2;
      // counted: the `done` beads that already passed the front
      final k = ((count - i) % n + n) % n; // how far behind the front bead i is
      final counted = k < done && count > 0;
      items.add((depth, p, r, counted, ((i - count) % n + n) % n == 0));
    }
    items.sort((x, y) => x.$1.compareTo(y.$1));

    // the cord
    final cord = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF8C6A3F).withValues(alpha: back ? 0.35 : 0.6);
    final oval = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawArc(oval, back ? math.pi : 0, math.pi, false, cord);

    for (final (depth, p, r, counted, front) in items) {
      final light = 0.55 + 0.45 * (depth + 1) / 2;
      final base = complete
          ? const Color(0xFFC8962E)
          : counted
              ? const Color(0xFF6B4423)
              : const Color(0xFFE9DCC4);
      final col = Color.lerp(Colors.black, base, light)!;
      final rect = Rect.fromCircle(center: p, radius: r);
      canvas.drawCircle(
          p + const Offset(0, 2.5), r, Paint()..color = Colors.black.withValues(alpha: 0.18 * light));
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            colors: [Color.lerp(col, Colors.white, 0.45)!, col, Color.lerp(col, Colors.black, 0.35)!],
            stops: const [0, 0.55, 1],
          ).createShader(rect),
      );
      if (front && !back) {
        canvas.drawCircle(
            p,
            r + 3,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = const Color(0xFFD9A441));
      }
    }

    // the imām bead and tassel hanging at the front
    if (!back) {
      final f = c + Offset(0, ry + 14);
      canvas.drawLine(c + Offset(0, ry + 8), f + const Offset(0, 14), cord..strokeWidth = 1.6);
      canvas.drawOval(Rect.fromCenter(center: f, width: 12, height: 18), Paint()..color = const Color(0xFF4A2E17));
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.turn != turn || o.count != count || o.complete != complete;
}
