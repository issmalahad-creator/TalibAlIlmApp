import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Simple in-house line-art diagrams for "دليل المسلم الجديد" — drawn as
/// `CustomPainter`s rather than bundled SVG/image assets, deliberately:
/// avoids any licensing question entirely (same caution already applied to
/// the Nabulsi audio decision) and needs no new dependency. One
/// representative illustration per topic — a first pass, not a full
/// per-step illustrated sequence; upgradable later same as the other
/// visual-aid TODOs in this app.
class GuideDiagram extends StatelessWidget {
  final String topicKey;
  const GuideDiagram({super.key, required this.topicKey});

  @override
  Widget build(BuildContext context) {
    final painter = switch (topicKey) {
      'wudu' => _WuduPainter(),
      'ghusl' => _GhuslPainter(),
      'istinja' => _IstinjaPainter(),
      'salah' => _SalahPainter(),
      _ => null,
    };
    if (painter == null) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
        child: CustomPaint(painter: painter, child: Container()),
      ),
    );
  }
}

const _stroke = AppColors.primaryDark;

Paint _linePaint({double width = 3}) => Paint()
  ..color = _stroke
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round;

/// A hand outline with three water droplets — wudu.
class _WuduPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final handPath = Path()
      ..moveTo(cx - 30, cy + 30)
      ..quadraticBezierTo(cx - 40, cy - 10, cx - 20, cy - 30)
      ..lineTo(cx - 20, cy - 40)
      ..quadraticBezierTo(cx - 15, cy - 48, cx - 10, cy - 40)
      ..lineTo(cx - 10, cy - 25)
      ..lineTo(cx - 5, cy - 42)
      ..quadraticBezierTo(cx, cy - 50, cx + 5, cy - 42)
      ..lineTo(cx + 5, cy - 22)
      ..lineTo(cx + 12, cy - 38)
      ..quadraticBezierTo(cx + 20, cy - 40, cx + 18, cy - 28)
      ..lineTo(cx + 30, cy + 30)
      ..close();
    canvas.drawPath(handPath, _linePaint());

    for (final dx in [-55.0, 55.0, 80.0]) {
      final dropCenter = Offset(cx + dx, cy - 45 + (dx.abs() == 80 ? 20 : 0));
      _drawDroplet(canvas, dropCenter, 10);
    }
  }

  void _drawDroplet(Canvas canvas, Offset center, double r) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(center.dx + r, center.dy + r * 0.4, center.dx, center.dy + r)
      ..quadraticBezierTo(center.dx - r, center.dy + r * 0.4, center.dx, center.dy - r)
      ..close();
    canvas.drawPath(path, _linePaint(width: 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A figure under a shower of droplets covering the whole body — ghusl.
class _GhuslPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final headY = size.height / 2 - 45;
    canvas.drawCircle(Offset(cx, headY), 12, _linePaint());
    final bodyPath = Path()
      ..moveTo(cx, headY + 12)
      ..lineTo(cx, headY + 55)
      ..moveTo(cx - 18, headY + 30)
      ..lineTo(cx + 18, headY + 30)
      ..moveTo(cx, headY + 55)
      ..lineTo(cx - 14, headY + 85)
      ..moveTo(cx, headY + 55)
      ..lineTo(cx + 14, headY + 85);
    canvas.drawPath(bodyPath, _linePaint());

    final dropX = [cx - 40, cx - 15, cx + 10, cx + 35];
    for (final dx in dropX) {
      canvas.drawLine(Offset(dx, headY - 30), Offset(dx - 4, headY - 12), _linePaint(width: 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A water droplet with a checkmark — istinja (kept abstract/non-figurative
/// on purpose).
class _IstinjaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = 38.0;
    final path = Path()
      ..moveTo(cx, cy - r)
      ..quadraticBezierTo(cx + r, cy + r * 0.5, cx, cy + r)
      ..quadraticBezierTo(cx - r, cy + r * 0.5, cx, cy - r)
      ..close();
    canvas.drawPath(path, _linePaint(width: 3));

    final check = Path()
      ..moveTo(cx - 14, cy + 5)
      ..lineTo(cx - 3, cy + 16)
      ..lineTo(cx + 16, cy - 10);
    canvas.drawPath(check, _linePaint(width: 3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Three stick-figure silhouettes side by side: standing, bowing (ruku),
/// prostrating (sujood) — the three core salah postures.
class _SalahPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final third = size.width / 3;
    final baseY = size.height * 0.75;
    _standing(canvas, Offset(third * 0.5, baseY));
    _bowing(canvas, Offset(third * 1.5, baseY));
    _prostrating(canvas, Offset(third * 2.5, baseY));
  }

  void _standing(Canvas canvas, Offset foot) {
    final hipY = foot.dy - 45;
    final headY = hipY - 35;
    canvas.drawCircle(Offset(foot.dx, headY), 9, _linePaint());
    canvas.drawLine(Offset(foot.dx, headY + 9), Offset(foot.dx, hipY), _linePaint());
    canvas.drawLine(Offset(foot.dx - 10, hipY - 15), Offset(foot.dx + 10, hipY - 15), _linePaint(width: 2));
    canvas.drawLine(Offset(foot.dx, hipY), Offset(foot.dx - 8, foot.dy), _linePaint());
    canvas.drawLine(Offset(foot.dx, hipY), Offset(foot.dx + 8, foot.dy), _linePaint());
  }

  void _bowing(Canvas canvas, Offset foot) {
    final hipX = foot.dx - 5;
    final hipY = foot.dy - 30;
    final headPos = Offset(hipX + 35, hipY - 5);
    canvas.drawCircle(headPos, 9, _linePaint());
    canvas.drawLine(Offset(hipX, hipY), Offset(headPos.dx - 8, headPos.dy + 5), _linePaint());
    canvas.drawLine(Offset(hipX, hipY), Offset(foot.dx - 8, foot.dy), _linePaint());
    canvas.drawLine(Offset(hipX, hipY), Offset(foot.dx + 8, foot.dy), _linePaint());
    canvas.drawLine(Offset(headPos.dx - 8, headPos.dy + 5), Offset(headPos.dx - 2, headPos.dy + 25), _linePaint(width: 2));
  }

  void _prostrating(Canvas canvas, Offset foot) {
    final groundY = foot.dy;
    final headPos = Offset(foot.dx - 25, groundY - 8);
    canvas.drawCircle(headPos, 8, _linePaint());
    canvas.drawLine(Offset(headPos.dx + 6, groundY - 5), Offset(foot.dx + 5, groundY - 15), _linePaint());
    canvas.drawLine(Offset(foot.dx + 5, groundY - 15), Offset(foot.dx + 15, groundY), _linePaint());
    canvas.drawLine(Offset(headPos.dx - 4, groundY + 2), Offset(headPos.dx + 10, groundY + 2), _linePaint(width: 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
