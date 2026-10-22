import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A real muṣḥaf cover drawn in code — leather, gold tooling and «القرآن
/// الكريم» (Ismail 2026-10-22: «غيّر الصورة إلى مصحف حقيقي مكتوب عليه القرآن
/// الكريم», and let the person choose). No image assets: every style is a
/// painter, so the choice costs nothing in APK size.
enum MushafCoverStyle { shamsa, classic, modern }

/// The cover a khatma was given, kept per goal in prefs (a cosmetic choice —
/// no schema change). Unset → [MushafCoverStyle.shamsa].
class MushafCoverPrefs {
  MushafCoverPrefs._();
  static String _key(int goalId) => 'khatm_cover_style_$goalId';

  static Future<MushafCoverStyle> get(int goalId) async {
    final i = (await SharedPreferences.getInstance()).getInt(_key(goalId));
    return i != null && i >= 0 && i < MushafCoverStyle.values.length ? MushafCoverStyle.values[i] : MushafCoverStyle.shamsa;
  }

  static Future<Map<int, MushafCoverStyle>> getAll(Iterable<int> goalIds) async {
    final p = await SharedPreferences.getInstance();
    return {
      for (final id in goalIds)
        id: switch (p.getInt(_key(id))) {
          final i? when i >= 0 && i < MushafCoverStyle.values.length => MushafCoverStyle.values[i],
          _ => MushafCoverStyle.shamsa,
        },
    };
  }

  static Future<void> set(int goalId, MushafCoverStyle s) async =>
      (await SharedPreferences.getInstance()).setInt(_key(goalId), s.index);
}

const _gold = Color(0xFFE2C27A);
const _goldLight = Color(0xFFF6E3AE);
const _goldDeep = Color(0xFFB08A3E);

/// Leather tone for a khatma colour: deeper and a little desaturated, so a
/// bright tab colour still reads as a bound book.
Color mushafLeather(Color c) {
  final h = HSLColor.fromColor(c);
  return h.withSaturation((h.saturation * 0.72).clamp(0.0, 1.0)).withLightness((h.lightness * 0.62).clamp(0.12, 0.42)).toColor();
}

/// The flat front cover, [width] × [width]·1.38.
class MushafCover extends StatelessWidget {
  final Color color;
  final MushafCoverStyle style;
  final double width;
  const MushafCover({super.key, required this.color, required this.style, required this.width});

  @override
  Widget build(BuildContext context) {
    final w = width, h = width * 1.38;
    final leather = mushafLeather(color);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(7), right: Radius.circular(3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(leather, Colors.white, 0.16)!, leather, Color.lerp(leather, Colors.black, 0.38)!],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: CustomPaint(
        painter: _CoverPainter(style),
        child: Align(
          alignment: style == MushafCoverStyle.modern ? const Alignment(0, -0.18) : Alignment.center,
          child: _Title(width: w, style: style),
        ),
      ),
    );
  }
}

/// «القرآن» over «الكريم» in gold, as on a printed muṣḥaf.
class _Title extends StatelessWidget {
  final double width;
  final MushafCoverStyle style;
  const _Title({required this.width, required this.style});

  @override
  Widget build(BuildContext context) {
    final fs = width * (style == MushafCoverStyle.shamsa ? 0.135 : 0.16);
    final t = TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.w700, fontSize: fs, height: 1.25, color: Colors.white);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_goldLight, _gold, _goldDeep],
      ).createShader(r),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('القرآن', textDirection: TextDirection.rtl, style: t),
        Text('الكريم', textDirection: TextDirection.rtl, style: t.copyWith(fontSize: fs * 0.82)),
      ]),
    );
  }
}

class _CoverPainter extends CustomPainter {
  final MushafCoverStyle style;
  _CoverPainter(this.style);

  Paint _line(double w, [Color c = _gold]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w;

  @override
  void paint(Canvas canvas, Size s) {
    final u = s.width / 100; // one «unit» = 1% of the cover width
    switch (style) {
      case MushafCoverStyle.shamsa:
        _frame(canvas, s, u, inset: 6 * u, double: true);
        _corners(canvas, s, u, inset: 6 * u);
        _shamsa(canvas, s, u);
      case MushafCoverStyle.classic:
        _frame(canvas, s, u, inset: 5 * u, double: true);
        _band(canvas, s, u, inset: 9 * u);
        _star(canvas, Offset(s.width / 2, s.height * 0.25), 7 * u);
        _star(canvas, Offset(s.width / 2, s.height * 0.75), 7 * u);
      case MushafCoverStyle.modern:
        _frame(canvas, s, u, inset: 8 * u, double: false);
        final y = s.height * 0.63;
        canvas.drawLine(Offset(s.width * 0.3, y), Offset(s.width * 0.7, y), _line(0.9 * u));
        _star(canvas, Offset(s.width / 2, s.height * 0.76), 6 * u);
    }
    // soft leather sheen
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.6),
          radius: 0.9,
          colors: [Colors.white.withValues(alpha: 0.10), Colors.transparent],
        ).createShader(Offset.zero & s),
    );
  }

  void _frame(Canvas c, Size s, double u, {required double inset, required bool double}) {
    final r = Rect.fromLTRB(inset, inset, s.width - inset, s.height - inset);
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(2 * u)), _line(1.1 * u));
    if (double) {
      c.drawRRect(RRect.fromRectAndRadius(r.deflate(3 * u), Radius.circular(1.5 * u)), _line(0.6 * u, _goldDeep));
    }
  }

  /// Quarter-fan ornaments in the four inner corners.
  void _corners(Canvas c, Size s, double u, {required double inset}) {
    final i = inset + 3 * u;
    final pts = [Offset(i, i), Offset(s.width - i, i), Offset(i, s.height - i), Offset(s.width - i, s.height - i)];
    final starts = [0.0, math.pi / 2, -math.pi / 2, math.pi];
    for (var k = 0; k < 4; k++) {
      final p = pts[k];
      for (final r in [9 * u, 14 * u]) {
        c.drawArc(Rect.fromCircle(center: p, radius: r), starts[k], math.pi / 2, false, _line(0.8 * u));
      }
      c.drawCircle(p + Offset.fromDirection(starts[k] + math.pi / 4, 5 * u), 1.4 * u, Paint()..color = _gold);
    }
  }

  /// The central «شمسة»: a scalloped oval medallion.
  void _shamsa(Canvas c, Size s, double u) {
    final ctr = s.center(Offset.zero);
    final rx = 30 * u, ry = 40 * u;
    final path = Path();
    const n = 28;
    for (var k = 0; k <= n * 4; k++) {
      final t = k / (n * 4) * 2 * math.pi;
      final bump = 1 + 0.045 * math.cos(n * t).abs();
      final p = Offset(ctr.dx + rx * bump * math.cos(t), ctr.dy + ry * bump * math.sin(t));
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    c.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.16));
    c.drawPath(path, _line(1.0 * u));
    c.drawOval(Rect.fromCenter(center: ctr, width: rx * 1.72, height: ry * 1.72), _line(0.6 * u, _goldDeep));
    // pendants above and below
    for (final dy in [-1.0, 1.0]) {
      final tip = ctr + Offset(0, dy * (ry + 9 * u));
      c.drawLine(ctr + Offset(0, dy * (ry * 1.05)), tip, _line(0.8 * u));
      _diamond(c, tip, 3 * u);
    }
  }

  /// A band of small diamonds just inside the frame.
  void _band(Canvas c, Size s, double u, {required double inset}) {
    final r = Rect.fromLTRB(inset, inset, s.width - inset, s.height - inset);
    final step = 6 * u;
    for (var x = r.left + step; x < r.right - step / 2; x += step) {
      _diamond(c, Offset(x, r.top), 1.6 * u);
      _diamond(c, Offset(x, r.bottom), 1.6 * u);
    }
    for (var y = r.top + step; y < r.bottom - step / 2; y += step) {
      _diamond(c, Offset(r.left, y), 1.6 * u);
      _diamond(c, Offset(r.right, y), 1.6 * u);
    }
  }

  void _diamond(Canvas c, Offset p, double r) {
    c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - r)
        ..lineTo(p.dx + r, p.dy)
        ..lineTo(p.dx, p.dy + r)
        ..lineTo(p.dx - r, p.dy)
        ..close(),
      Paint()..color = _gold,
    );
  }

  /// Eight-point star (two squares).
  void _star(Canvas c, Offset p, double r) {
    for (final a in [0.0, math.pi / 4]) {
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(a);
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 1.4, height: r * 1.4), _line(r * 0.14));
      c.restore();
    }
    c.drawCircle(p, r * 0.22, Paint()..color = _gold);
  }

  @override
  bool shouldRepaint(covariant _CoverPainter old) => old.style != style;
}

/// A small tappable cover thumbnail for the «تصميم الغلاف» picker.
class MushafCoverChoice extends StatelessWidget {
  final Color color;
  final MushafCoverStyle style;
  final bool selected;
  final VoidCallback onTap;
  const MushafCoverChoice({super.key, required this.color, required this.style, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(4),
          transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? _goldDeep : Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.28 : 0.12),
                blurRadius: selected ? 12 : 5,
                offset: Offset(0, selected ? 6 : 2),
              ),
            ],
          ),
          child: MushafCover(color: color, style: style, width: 50),
        ),
      );
}
