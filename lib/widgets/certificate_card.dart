import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/date_display.dart';

const _gold = Color(0xFFD9A441);
const _goldLight = Color(0xFFF0D9A0);
const _deepGreen = Color(0xFF14261E);

/// The shareable certificate design — QURAN_COMPANION_ROADMAP.md §4.14,
/// redesigned 2026-08-16 to a professional layout (Ismail's request, with
/// explicit freedom on color choice — "تقدر تعمل لون الشهادة الذي تحبه
/// انت"). Kept in the app's own green identity + gold accents rather than
/// copying the reference screenshot's navy/gold palette — same "match
/// structure, never clone a specific product's actual look" line held
/// throughout this app's other visual redesigns. Deliberately fixed-size
/// (not responsive) since it's captured as an image via [RepaintBoundary]
/// for sharing, not meant to be laid out on-page.
class CertificateCard extends StatelessWidget {
  final String studentName;
  final String title;

  /// Stored-format Hijri date string ("1447-01-15") — rendered honoring the
  /// student's Hijri/Gregorian display preference, see `formatDateForDisplay`.
  final String hijriDate;
  final bool grand; // true only for the "ختم القرآن كاملًا" certificate
  final String? photoPath; // optional local file path, ProfileRepository

  const CertificateCard({
    super.key,
    required this.studentName,
    required this.title,
    required this.hijriDate,
    this.grand = false,
    this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    final accent = grand ? _goldLight : _gold;
    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: grand ? [const Color(0xFF2F5C46), _deepGreen] : [AppColors.primaryDark, _deepGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 2.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: -6, left: -6, child: _CornerFlourish(color: accent)),
          Positioned(
            top: -6,
            right: -6,
            child: Transform.flip(flipX: true, child: _CornerFlourish(color: accent)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(size: const Size(64, 78), painter: _MedallionPainter(color: accent)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: accent, width: 1), bottom: BorderSide(color: accent, width: 1)),
                ),
                child: Text('شهادة تقدير', style: TextStyle(fontSize: 15, color: accent, fontWeight: FontWeight.w800, letterSpacing: 2)),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 18),
              const Text('تُمنح هذه الشهادة إلى', style: TextStyle(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 6),
              Text(
                studentName.trim().isEmpty ? 'طالب العلم' : studentName,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: accent),
              ),
              const SizedBox(height: 22),
              Divider(color: accent.withValues(alpha: 0.35), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('التوقيع', style: TextStyle(fontSize: 10, color: Colors.white54)),
                      SizedBox(height: 2),
                      Text('تطبيق طالب العلم', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('التاريخ', style: TextStyle(fontSize: 10, color: Colors.white54)),
                      const SizedBox(height: 2),
                      Text(formatDateForDisplay(hijriDate), style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (photoPath != null && File(photoPath!).existsSync())
            Positioned(
              bottom: -14,
              left: -14,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _deepGreen, border: Border.all(color: accent, width: 2.5)),
                child: ClipOval(child: Image.file(File(photoPath!), width: 52, height: 52, fit: BoxFit.cover)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Simple original geometric medal-and-ribbon badge — circular seal with an
/// inner star plus two ribbon tails, drawn from scratch (arcs/paths/lines),
/// not traced from any reference app's actual artwork.
class _MedallionPainter extends CustomPainter {
  final Color color;
  const _MedallionPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 26);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color;
    canvas.drawCircle(center, 22, ring);
    canvas.drawCircle(center, 22, Paint()..color = color.withValues(alpha: 0.12));

    // 5-point star in the center.
    final starPath = Path();
    const points = 5;
    const outerR = 12.0;
    const innerR = 5.0;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (math.pi / points) * i - math.pi / 2;
      final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        starPath.moveTo(p.dx, p.dy);
      } else {
        starPath.lineTo(p.dx, p.dy);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, Paint()..color = color);

    // Two ribbon tails hanging below the medal.
    final ribbon = Paint()..color = color.withValues(alpha: 0.9);
    final leftTail = Path()
      ..moveTo(center.dx - 12, center.dy + 16)
      ..lineTo(center.dx - 4, center.dy + 16)
      ..lineTo(center.dx - 6, size.height)
      ..lineTo(center.dx - 16, size.height - 8)
      ..close();
    final rightTail = Path()
      ..moveTo(center.dx + 12, center.dy + 16)
      ..lineTo(center.dx + 4, center.dy + 16)
      ..lineTo(center.dx + 6, size.height)
      ..lineTo(center.dx + 16, size.height - 8)
      ..close();
    canvas.drawPath(leftTail, ribbon);
    canvas.drawPath(rightTail, ribbon);
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter oldDelegate) => oldDelegate.color != color;
}

class _CornerFlourish extends StatelessWidget {
  final Color color;
  const _CornerFlourish({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(painter: _CornerFlourishPainter(color: color)),
    );
  }
}

class _CornerFlourishPainter extends CustomPainter {
  final Color color;
  const _CornerFlourishPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.6);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect.deflate(4), math.pi, math.pi / 2, false, paint);
    canvas.drawArc(rect, math.pi, math.pi / 2, false, paint..color = color.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant _CornerFlourishPainter oldDelegate) => oldDelegate.color != color;
}
