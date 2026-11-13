import 'package:flutter/material.dart';

/// A small drawn emblem for a surah's place of revelation, for the index:
/// the Kaʿba (Meccan) or the green dome (Medinan). Drawn, not an emoji, so
/// it looks the same on every phone and sits calmly beside the text.
class RevelationIcon extends StatelessWidget {
  final bool meccan;
  final double size;
  const RevelationIcon({super.key, required this.meccan, this.size = 30});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: meccan ? _KaabaPainter() : _DomePainter()),
      );
}

class _KaabaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    // a cube seen slightly from the side: a front face and a darker side
    final front = Path()
      ..moveTo(w * 0.12, h * 0.30)
      ..lineTo(w * 0.62, h * 0.38)
      ..lineTo(w * 0.62, h * 0.94)
      ..lineTo(w * 0.12, h * 0.86)
      ..close();
    final side = Path()
      ..moveTo(w * 0.62, h * 0.38)
      ..lineTo(w * 0.90, h * 0.26)
      ..lineTo(w * 0.90, h * 0.80)
      ..lineTo(w * 0.62, h * 0.94)
      ..close();
    final top = Path()
      ..moveTo(w * 0.12, h * 0.30)
      ..lineTo(w * 0.42, h * 0.18)
      ..lineTo(w * 0.90, h * 0.26)
      ..lineTo(w * 0.62, h * 0.38)
      ..close();
    canvas.drawPath(top, Paint()..color = const Color(0xFF3A3A3A));
    canvas.drawPath(front, Paint()..color = const Color(0xFF151515));
    canvas.drawPath(side, Paint()..color = const Color(0xFF262626));
    // the gold band (al-ḥizām) across both faces
    final gold = Paint()
      ..color = const Color(0xFFD4A63A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.07;
    canvas.drawLine(Offset(w * 0.12, h * 0.44), Offset(w * 0.62, h * 0.52), gold);
    canvas.drawLine(Offset(w * 0.62, h * 0.52), Offset(w * 0.90, h * 0.40), gold);
    // the door
    canvas.drawRect(
      Rect.fromLTWH(w * 0.40, h * 0.62, w * 0.12, h * 0.20),
      Paint()..color = const Color(0xFFB8892B),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    const green = Color(0xFF2E9E4F);
    const greenLight = Color(0xFF5CC27A);
    // the drum the dome sits on
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.14, h * 0.62, w * 0.72, h * 0.30), Radius.circular(w * 0.04)),
      Paint()..color = const Color(0xFFE9E4D8),
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.14, h * 0.62, w * 0.72, h * 0.05), Paint()..color = const Color(0xFFCFC8B6));
    // the dome
    final dome = Path()
      ..moveTo(w * 0.20, h * 0.64)
      ..cubicTo(w * 0.18, h * 0.30, w * 0.40, h * 0.22, w * 0.50, h * 0.14)
      ..cubicTo(w * 0.60, h * 0.22, w * 0.82, h * 0.30, w * 0.80, h * 0.64)
      ..close();
    canvas.drawPath(
      dome,
      Paint()
        ..shader = const LinearGradient(colors: [greenLight, green], begin: Alignment.topLeft, end: Alignment.bottomRight)
            .createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    // the finial
    canvas.drawLine(
      Offset(w * 0.50, h * 0.14),
      Offset(w * 0.50, h * 0.02),
      Paint()
        ..color = const Color(0xFFD4A63A)
        ..strokeWidth = w * 0.05
        ..strokeCap = StrokeCap.round,
    );
    // two small windows on the drum
    final win = Paint()..color = const Color(0xFF8A8270);
    canvas.drawRect(Rect.fromLTWH(w * 0.30, h * 0.74, w * 0.08, h * 0.10), win);
    canvas.drawRect(Rect.fromLTWH(w * 0.62, h * 0.74, w * 0.08, h * 0.10), win);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
