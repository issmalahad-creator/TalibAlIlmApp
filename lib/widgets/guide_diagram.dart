import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Real illustrated diagrams for "دليل المسلم الجديد" — redrawn 2026-08-16
/// per Ismail's direct feedback on the original first-pass stick figures
/// ("رسومات بداية من العصر الحجري"). Still `CustomPainter`s, not bundled
/// image/SVG assets — same licensing-avoidance reasoning as the original
/// (see git history), just drawn with real proportions, color fills, and
/// labels instead of bare stroke lines. One representative illustration per
/// topic, same scope as before (not a full per-step sequence — see
/// `guide_topic_screen.dart`'s single `GuideDiagram(topicKey:)` call site).
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
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primaryLight, Color(0xFFF3F8F5)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(painter: painter, child: Container()),
      ),
    );
  }
}

const _skin = Color(0xFFC98D62);
const _skinShade = Color(0xFFB47A50);
const _robe = AppColors.primary;
const _robeShade = AppColors.primaryDark;
const _water = Color(0xFF5FA8D3);
const _hair = Color(0xFF2E2A26);

void _label(Canvas canvas, String text, Offset center, {double fontSize = 11, Color color = AppColors.textDark}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: color)),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
  )..layout();
  tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
}

void _droplet(Canvas canvas, Offset center, double r, {double opacity = 1}) {
  final path = Path()
    ..moveTo(center.dx, center.dy - r)
    ..quadraticBezierTo(center.dx + r, center.dy + r * 0.5, center.dx, center.dy + r)
    ..quadraticBezierTo(center.dx - r, center.dy + r * 0.5, center.dx, center.dy - r)
    ..close();
  canvas.drawPath(path, Paint()..color = _water.withValues(alpha: opacity));
}

/// A face-and-hands figure with the four wudu wash zones labeled — the
/// wash areas (face, arms, head-wipe, feet) rather than a generic hand.
class _WuduPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final headCy = size.height * 0.34;
    final headR = size.height * 0.16;

    // Neck + shoulders
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, headCy + headR + 6), width: 18, height: 20), Paint()..color = _skinShade);
    final shoulders = Path()
      ..moveTo(cx - 55, size.height * 0.78)
      ..quadraticBezierTo(cx - 60, headCy + headR + 10, cx, headCy + headR + 4)
      ..quadraticBezierTo(cx + 60, headCy + headR + 10, cx + 55, size.height * 0.78)
      ..close();
    canvas.drawPath(shoulders, Paint()..color = _robe);

    // Head
    canvas.drawCircle(Offset(cx, headCy), headR, Paint()..color = _skin);
    // Simple hair
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, headCy), radius: headR), 3.4, 2.8, true, Paint()..color = _hair);
    // Face features (calm, minimal)
    canvas.drawCircle(Offset(cx - headR * 0.32, headCy + 2), 2.4, Paint()..color = AppColors.textDark);
    canvas.drawCircle(Offset(cx + headR * 0.32, headCy + 2), 2.4, Paint()..color = AppColors.textDark);
    final smile = Path()..moveTo(cx - 8, headCy + headR * 0.42)..quadraticBezierTo(cx, headCy + headR * 0.42 + 6, cx + 8, headCy + headR * 0.42);
    canvas.drawPath(smile, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = AppColors.textDark);

    // Water droplets over the wash zones, with labels
    for (final dx in [-headR * 0.9, 0.0, headR * 0.9]) {
      _droplet(canvas, Offset(cx + dx, headCy - headR - 14), 6);
    }
    _label(canvas, 'الوجه', Offset(cx, headCy - headR - 30));

    // Hands raised beside the head (washing arms)
    final handY = headCy + headR * 0.3;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - headR - 26, handY), width: 22, height: 34), Paint()..color = _skin);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + headR + 26, handY), width: 22, height: 34), Paint()..color = _skin);
    _droplet(canvas, Offset(cx - headR - 26, handY - 26), 5);
    _droplet(canvas, Offset(cx + headR + 26, handY - 26), 5);
    _label(canvas, 'الذراعان', Offset(cx + headR + 26, handY + 30));

    // Head-wipe indicator
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, headCy - headR * 0.55), radius: headR * 0.55), -2.6, 2.2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = _water);

    // Feet at the base
    final feetY = size.height * 0.93;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 14, feetY), width: 26, height: 14), Paint()..color = _skin);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 14, feetY), width: 26, height: 14), Paint()..color = _skin);
    _droplet(canvas, Offset(cx - 14, feetY - 12), 5);
    _droplet(canvas, Offset(cx + 14, feetY - 12), 5);
    _label(canvas, 'القدمان', Offset(cx, feetY + 16));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A full standing figure covered head-to-foot in water — ghusl, real body
/// proportions instead of a bare stick outline.
class _GhuslPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final headR = size.height * 0.11;
    final headCy = size.height * 0.22;
    final shoulderY = headCy + headR + 6;
    final hipY = size.height * 0.62;
    final footY = size.height * 0.9;

    // Body silhouette (torso + legs), tapered
    final body = Path()
      ..moveTo(cx - 30, shoulderY)
      ..quadraticBezierTo(cx - 34, hipY - 10, cx - 20, hipY)
      ..lineTo(cx - 22, footY)
      ..lineTo(cx - 6, footY)
      ..lineTo(cx - 8, hipY + 4)
      ..lineTo(cx + 8, hipY + 4)
      ..lineTo(cx + 6, footY)
      ..lineTo(cx + 22, footY)
      ..lineTo(cx + 20, hipY)
      ..quadraticBezierTo(cx + 34, hipY - 10, cx + 30, shoulderY)
      ..quadraticBezierTo(cx, shoulderY - 10, cx - 30, shoulderY)
      ..close();
    canvas.drawPath(body, Paint()..color = _skin);
    canvas.drawPath(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = _skinShade.withValues(alpha: 0.5));

    // Arms slightly out from the body
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 42, shoulderY + 40), width: 14, height: 60), Paint()..color = _skin);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 42, shoulderY + 40), width: 14, height: 60), Paint()..color = _skin);

    // Head + hair
    canvas.drawCircle(Offset(cx, headCy), headR, Paint()..color = _skin);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, headCy), radius: headR), 3.3, 2.9, true, Paint()..color = _hair);

    // Cascading water — full-body coverage, staggered droplets
    final dropCols = [cx - 55, cx - 30, cx, cx + 30, cx + 55];
    for (var i = 0; i < dropCols.length; i++) {
      for (var row = 0; row < 3; row++) {
        final y = headCy - headR - 18 + row * 34.0 + (i.isOdd ? 14 : 0);
        _droplet(canvas, Offset(dropCols[i], y), 5, opacity: 0.85 - row * 0.15);
      }
    }

    _label(canvas, 'يعمّ الماء كل الجسد', Offset(cx, size.height * 0.06), fontSize: 11);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A water droplet with a checkmark — istinja, kept deliberately abstract
/// (non-figurative, per the original design decision) but with a softer
/// gradient fill instead of a bare outline.
class _IstinjaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.height * 0.28;
    final path = Path()
      ..moveTo(cx, cy - r)
      ..quadraticBezierTo(cx + r, cy + r * 0.5, cx, cy + r)
      ..quadraticBezierTo(cx - r, cy + r * 0.5, cx, cy - r)
      ..close();
    final shader = ui.Gradient.linear(Offset(cx, cy - r), Offset(cx, cy + r), [_water, _water.withValues(alpha: 0.65)]);
    canvas.drawPath(path, Paint()..shader = shader);

    final check = Path()
      ..moveTo(cx - r * 0.35, cy + r * 0.1)
      ..lineTo(cx - r * 0.05, cy + r * 0.4)
      ..lineTo(cx + r * 0.4, cy - r * 0.25);
    canvas.drawPath(check, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = Colors.white);

    _label(canvas, 'الطهارة والنظافة', Offset(cx, cy + r + 22));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Three properly-proportioned, filled figures — standing (قيام), bowing
/// (ركوع), prostrating (سجود) — labeled underneath, instead of thin stick
/// silhouettes.
class _SalahPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final third = size.width / 3;
    final baseY = size.height * 0.82;
    _standing(canvas, Offset(third * 0.5, baseY), size.height);
    _label(canvas, 'قيام', Offset(third * 0.5, size.height * 0.95));
    _bowing(canvas, Offset(third * 1.5, baseY), size.height);
    _label(canvas, 'ركوع', Offset(third * 1.5, size.height * 0.95));
    _prostrating(canvas, Offset(third * 2.5, baseY), size.height);
    _label(canvas, 'سجود', Offset(third * 2.5, size.height * 0.95));
  }

  Paint get _fill => Paint()..color = _robe;

  void _standing(Canvas canvas, Offset foot, double h) {
    final hipY = foot.dy - h * 0.34;
    final headR = h * 0.075;
    final headCy = hipY - h * 0.28 - headR;
    final body = Path()
      ..moveTo(foot.dx - 16, hipY)
      ..quadraticBezierTo(foot.dx - 18, headCy + headR + 8, foot.dx, headCy + headR + 4)
      ..quadraticBezierTo(foot.dx + 18, headCy + headR + 8, foot.dx + 16, hipY)
      ..close();
    canvas.drawPath(body, _fill);
    canvas.drawLine(Offset(foot.dx - 8, hipY), Offset(foot.dx - 8, foot.dy), Paint()..strokeWidth = 8..strokeCap = StrokeCap.round..color = _robeShade);
    canvas.drawLine(Offset(foot.dx + 8, hipY), Offset(foot.dx + 8, foot.dy), Paint()..strokeWidth = 8..strokeCap = StrokeCap.round..color = _robeShade);
    canvas.drawCircle(Offset(foot.dx, headCy), headR, Paint()..color = _skin);
    // Hands together at chest (qiyam posture)
    canvas.drawOval(Rect.fromCenter(center: Offset(foot.dx, hipY - h * 0.12), width: 16, height: 10), Paint()..color = _skin);
  }

  void _bowing(Canvas canvas, Offset foot, double h) {
    final hipX = foot.dx - 6;
    final hipY = foot.dy - h * 0.22;
    final headR = h * 0.07;
    final headCenter = Offset(hipX + h * 0.24, hipY - h * 0.02);
    final torso = Path()
      ..moveTo(hipX - 12, hipY + 6)
      ..quadraticBezierTo(hipX + h * 0.1, hipY - h * 0.08, headCenter.dx - headR * 0.6, headCenter.dy + headR * 0.5)
      ..quadraticBezierTo(headCenter.dx + headR * 0.3, headCenter.dy + headR, hipX + 10, hipY + 8)
      ..close();
    canvas.drawPath(torso, _fill);
    canvas.drawCircle(headCenter, headR, Paint()..color = _skin);
    canvas.drawLine(Offset(hipX - 6, hipY + 4), Offset(foot.dx - 8, foot.dy), Paint()..strokeWidth = 7..strokeCap = StrokeCap.round..color = _robeShade);
    canvas.drawLine(Offset(hipX + 6, hipY + 4), Offset(foot.dx + 8, foot.dy), Paint()..strokeWidth = 7..strokeCap = StrokeCap.round..color = _robeShade);
    // Hands on knees
    canvas.drawOval(Rect.fromCenter(center: Offset(hipX - 4, hipY + h * 0.16), width: 12, height: 8), Paint()..color = _skin);
  }

  void _prostrating(Canvas canvas, Offset foot, double h) {
    final groundY = foot.dy;
    final headR = h * 0.065;
    final headCenter = Offset(foot.dx - h * 0.22, groundY - headR * 0.6);
    final torso = Path()
      ..moveTo(headCenter.dx + headR * 0.4, groundY - headR * 1.6)
      ..quadraticBezierTo(foot.dx, groundY - h * 0.18, foot.dx + 14, groundY - 6)
      ..lineTo(foot.dx + 14, groundY)
      ..lineTo(headCenter.dx, groundY)
      ..close();
    canvas.drawPath(torso, _fill);
    canvas.drawCircle(headCenter, headR, Paint()..color = _skin);
    // Forearms on the ground
    canvas.drawOval(Rect.fromCenter(center: Offset(headCenter.dx + headR * 1.6, groundY - 3), width: 22, height: 8), Paint()..color = _skin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
