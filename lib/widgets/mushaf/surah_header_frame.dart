import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The ornate frame behind a surah's title line (Ismail 2026-11-13: «نعم،
/// جرّبه… طوّر منها كثيرًا وحاول أن تصل إلى درجة عالية من الإتقان», after a
/// reference screenshot of another muṣḥaf app).
///
/// Drawn UNDER the page art, never over it: the title itself stays the
/// muṣḥaf's own glyphs. Anatomy, outside → in:
///  * a double gold rule with small square knots at the corners;
///  * two side panels on a deep lapis ground, tiled with an interlaced
///    8‑pointed‑star (khātam) pattern — gold stars, lapis octagrams inside,
///    a cream eye, and gold lozenges where four tiles meet;
///  * a pointed (ogee) cartouche in the centre on warm paper, double-ruled
///    in gold, with a teardrop finial at each tip — the title sits in it.
///
/// Lessons from the first attempt (cancelled 2026-09-26): no ornament made
/// of loose dots, and no white gap — the frame fills its band edge to edge.
/// Pure painting, no assets; one paint per frame per page.
class SurahHeaderFrame {
  /// The title line's band on screen (the full text width × one line).
  final Rect band;

  /// The title glyphs' box on screen, when known — sizes the cartouche.
  final Rect? title;
  const SurahHeaderFrame(this.band, [this.title]);
}

class SurahHeaderFramePainter extends CustomPainter {
  final List<SurahHeaderFrame> frames;
  final bool night;
  const SurahHeaderFramePainter({required this.frames, this.night = false});

  // ── palette ──────────────────────────────────────────────────────────
  Color get _gold => night ? const Color(0xFFC8962E) : const Color(0xFFC29A3E);
  Color get _goldLight => night ? const Color(0xFFE0B860) : const Color(0xFFEBD28E);
  Color get _goldDeep => night ? const Color(0xFF8A6624) : const Color(0xFF8C6526);
  Color get _ink => night ? const Color(0xFF0B0F14) : const Color(0xFF4A3618);
  Color get _lapisTop => night ? const Color(0xFF123248) : const Color(0xFF1F5778);
  Color get _lapisBottom => night ? const Color(0xFF0B2233) : const Color(0xFF143E58);
  Color get _lapisInner => night ? const Color(0xFF1A4A66) : const Color(0xFF2B6E92);
  Color get _eye => night ? const Color(0xFFD9C79A) : const Color(0xFFFFF6DE);
  Color get _paperIn => night ? const Color(0xFF2A251C) : const Color(0xFFFFFCF3);
  Color get _paperOut => night ? const Color(0xFF1C1914) : const Color(0xFFF3E6C6);

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in frames) {
      if (f.band.width < 40 || f.band.height < 8) continue;
      _paintFrame(canvas, f);
    }
  }

  void _paintFrame(Canvas canvas, SurahHeaderFrame f) {
    final r = f.band;
    final h = r.height;
    final rule = math.max(1.0, h * 0.045); // one gold rule's width
    final outer = r.deflate(rule / 2);
    final inner = r.deflate(h * 0.14); // the patterned field

    // 1 · the lapis field, edge to edge inside the rules
    canvas.drawRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lapisTop, _lapisBottom],
        ).createShader(inner),
    );

    // 2 · the khātam pattern, tiled from each end inward (mirror-symmetric)
    canvas.save();
    canvas.clipRect(inner);
    final g = _geom(f, inner, rule);
    // no star under the cartouche or its finials
    _paintPattern(canvas, inner, clearFrom: g.cx - g.reach, clearTo: g.cx + g.reach);
    canvas.restore();

    // 3 · the border: a gold band between two rules, with corner knots
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_goldLight, _gold, _goldDeep],
      ).createShader(r);
    final border = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(r)
      ..addRect(inner);
    canvas.drawPath(border, bandPaint);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = _ink.withValues(alpha: night ? 0.9 : 0.55)
      ..strokeWidth = rule * 0.6;
    canvas.drawRect(outer, line);
    canvas.drawRect(inner, line);
    // a fine light rule inside the gold band — the "double rule"
    final mid = Rect.fromLTRB(
      (outer.left + inner.left) / 2,
      (outer.top + inner.top) / 2,
      (outer.right + inner.right) / 2,
      (outer.bottom + inner.bottom) / 2,
    );
    canvas.drawRect(
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _goldLight.withValues(alpha: 0.9)
        ..strokeWidth = rule * 0.45,
    );
    final knot = (inner.top - r.top);
    for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
      final kx = c.dx == r.left ? r.left : r.right - knot;
      final ky = c.dy == r.top ? r.top : r.bottom - knot;
      final k = Rect.fromLTWH(kx, ky, knot, knot);
      canvas.drawRect(k, Paint()..color = _goldDeep);
      canvas.drawRect(k.deflate(knot * 0.28), Paint()..color = _goldLight);
    }

    // 4 · the cartouche
    _paintCartouche(canvas, f, inner, rule);
  }

  /// The cartouche's centre x, half-width and half-height for a frame, and
  /// where its finials end ([reach], from the centre). The half-width is
  /// stretched so each finial ends exactly on a tile boundary: the star
  /// rows run whole up to the finial — no cut star, no empty tile.
  ({double cx, double halfW, double b, double reach}) _geom(SurahHeaderFrame f, Rect field, double rule) {
    final b = field.height * 0.45; // a lapis margin shows above and below
    final cell = field.height;
    final cx = field.center.dx; // the title is centred on the line
    final titleW = f.title?.width ?? field.width * 0.32;
    var halfW = (titleW / 2 + b * 2.4).clamp(field.width * 0.22, field.width * 0.36);
    final span = rule * 1.6 * 1.8 + b * (0.08 + 0.17 * 1.1 + 0.48) + rule;
    final room = cx - field.left - halfW - span; // space left of the finial
    // snap to the nearest boundary — shrinking only while the title keeps
    // comfortable paper on both sides
    final minHalfW = titleW / 2 + b * 1.6;
    final extra = room - (room / cell).floor() * cell; // grow by this…
    if (room >= cell) {
      final shrink = cell - extra; // …or shrink by this
      halfW = (shrink < extra && halfW - shrink >= minHalfW) ? halfW - shrink : halfW + extra;
    }
    return (cx: cx, halfW: halfW, b: b, reach: halfW + span);
  }

  /// 8-pointed stars on a square grid, cell = the field's height, tiled from
  /// both ends toward the centre so the two panels mirror each other.
  void _paintPattern(Canvas canvas, Rect field, {required double clearFrom, required double clearTo}) {
    final cell = field.height;
    final cy = field.center.dy;
    final n = (field.width / 2 / cell).ceil() + 1;
    final starFill = Paint();
    final starEdge = Paint()
      ..style = PaintingStyle.stroke
      ..color = _ink.withValues(alpha: night ? 0.85 : 0.45)
      ..strokeWidth = math.max(0.6, cell * 0.025);
    final octFill = Paint()..color = _lapisInner;
    final eye = Paint()..color = _eye;
    final lozenge = Paint()..color = _gold;

    void star(Offset c) {
      if (c.dx > clearFrom && c.dx < clearTo) return;
      final big = _khatam(c, cell * 0.44);
      // the gradient is relative to the canvas, re-centre it per star
      starFill.shader = RadialGradient(colors: [_goldLight, _gold, _goldDeep], stops: const [0.0, 0.55, 1.0])
          .createShader(Rect.fromCircle(center: c, radius: cell * 0.46));
      canvas.drawPath(big, starFill);
      canvas.drawPath(big, starEdge);
      final small = _khatam(c, cell * 0.25);
      canvas.drawPath(small, octFill);
      canvas.drawPath(small, starEdge);
      canvas.drawCircle(c, cell * 0.075, eye);
    }

    void diamond(Offset c, double s) {
      final p = Path()
        ..moveTo(c.dx, c.dy - s)
        ..lineTo(c.dx + s * 0.7, c.dy)
        ..lineTo(c.dx, c.dy + s)
        ..lineTo(c.dx - s * 0.7, c.dy)
        ..close();
      canvas.drawPath(p, lozenge);
      canvas.drawPath(p, starEdge);
    }

    // the interlace: gold straps on every cell diagonal, under the stars —
    // they cross between the stars, so the panel reads as one woven field
    final strapW = math.max(1.0, cell * 0.07);
    final strap = Paint()
      ..color = _gold
      ..strokeWidth = strapW
      ..strokeCap = StrokeCap.butt;
    final strapEdge = Paint()
      ..color = _ink.withValues(alpha: night ? 0.9 : 0.5)
      ..strokeWidth = strapW + math.max(0.8, cell * 0.035);
    for (final paint in [strapEdge, strap]) {
      for (var i = -1; i <= n; i++) {
        for (final x0 in [field.left + i * cell, field.right - (i + 1) * cell]) {
          canvas.drawLine(Offset(x0, field.top), Offset(x0 + cell, field.bottom), paint);
          canvas.drawLine(Offset(x0, field.bottom), Offset(x0 + cell, field.top), paint);
        }
      }
    }

    for (var i = 0; i < n; i++) {
      final off = cell / 2 + i * cell;
      star(Offset(field.left + off, cy));
      star(Offset(field.right - off, cy));
      // where four tiles meet, on the top and bottom edges
      for (final y in [field.top, field.bottom]) {
        diamond(Offset(field.left + (i + 1) * cell, y), cell * 0.16);
        diamond(Offset(field.right - (i + 1) * cell, y), cell * 0.16);
      }
    }
  }

  /// A khātam: two squares, one turned 45°, as one 16-vertex outline.
  Path _khatam(Offset c, double radius) {
    final p = Path();
    final inner = radius * math.cos(math.pi / 4) / math.cos(math.pi / 8);
    for (var k = 0; k < 16; k++) {
      final a = -math.pi / 2 + k * math.pi / 8;
      final rr = k.isEven ? radius : inner;
      final pt = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  void _paintCartouche(Canvas canvas, SurahHeaderFrame f, Rect field, double rule) {
    final g = _geom(f, field, rule);
    final cx = g.cx, halfW = g.halfW, b = g.b;
    final cy = field.center.dy;

    Path shape(double grow) {
      final top = cy - b - grow, bottom = cy + b + grow;
      final bb = b + grow;
      final xl = cx - halfW + bb * 1.35, xr = cx + halfW - bb * 1.35;
      final tipL = cx - halfW - grow * 1.8, tipR = cx + halfW + grow * 1.8;
      // each end is an ogee: it leaves the long edge flat, bellies out, then
      // turns in and meets the other half in a sharp point on the axis
      return Path()
        ..moveTo(xl, top)
        ..lineTo(xr, top)
        ..cubicTo(xr + bb * 0.95, top, tipR - bb * 0.85, cy - bb * 0.02, tipR, cy)
        ..cubicTo(tipR - bb * 0.85, cy + bb * 0.02, xr + bb * 0.95, bottom, xr, bottom)
        ..lineTo(xl, bottom)
        ..cubicTo(xl - bb * 0.95, bottom, tipL + bb * 0.85, cy + bb * 0.02, tipL, cy)
        ..cubicTo(tipL + bb * 0.85, cy - bb * 0.02, xl - bb * 0.95, top, xl, top)
        ..close();
    }

    // a gold halo first — the cartouche is cut out of the pattern
    final halo = shape(rule * 1.6);
    canvas.drawPath(halo, Paint()..color = _goldDeep);
    canvas.drawPath(shape(rule * 0.8), Paint()..color = _goldLight);
    final body = shape(0);
    final bounds = body.getBounds();
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [_paperIn, _paperOut],
        ).createShader(bounds),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _ink.withValues(alpha: night ? 0.9 : 0.5)
        ..strokeWidth = rule * 0.6,
    );
    // an inner hairline, inset — the classic double rule of a cartouche
    final inset = shape(-rule * 1.4);
    canvas.drawPath(
      inset,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _gold.withValues(alpha: 0.85)
        ..strokeWidth = rule * 0.5,
    );

    // finials: a gold trefoil just past each tip — a pointed lobe outward
    // and two small round lobes, on a short stem
    final finFill = Paint()..color = _goldLight;
    final finEdge = Paint()
      ..style = PaintingStyle.stroke
      ..color = _goldDeep
      ..strokeWidth = rule * 0.55;
    for (final dir in [-1.0, 1.0]) {
      final base = cx + dir * (halfW + rule * 1.6 * 1.8);
      final stem = b * 0.08;
      final lobeR = b * 0.17;
      final head = base + dir * (stem + lobeR * 1.1);
      canvas.drawLine(Offset(base, cy), Offset(head, cy),
          Paint()
            ..color = _goldDeep
            ..strokeWidth = rule * 1.1);
      for (final dy in [-1.0, 1.0]) {
        final c = Offset(head, cy + dy * lobeR * 1.05);
        canvas.drawCircle(c, lobeR, finFill);
        canvas.drawCircle(c, lobeR, finEdge);
      }
      final pointLen = b * 0.48;
      final lobe = Path()
        ..moveTo(head, cy - lobeR * 0.95)
        ..quadraticBezierTo(head + dir * pointLen * 0.55, cy - lobeR * 0.9, head + dir * pointLen, cy)
        ..quadraticBezierTo(head + dir * pointLen * 0.55, cy + lobeR * 0.9, head, cy + lobeR * 0.95)
        ..close();
      canvas.drawPath(lobe, finFill);
      canvas.drawPath(lobe, finEdge);
      canvas.drawCircle(Offset(head, cy), lobeR * 0.42, Paint()..color = _lapisInner);
    }
  }

  @override
  bool shouldRepaint(SurahHeaderFramePainter old) =>
      old.night != night ||
      old.frames.length != frames.length ||
      [for (var i = 0; i < frames.length; i++) frames[i].band != old.frames[i].band].any((x) => x);
}
