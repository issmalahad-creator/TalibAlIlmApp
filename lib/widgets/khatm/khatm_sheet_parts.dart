import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'mushaf_cover.dart';

export 'mushaf_cover.dart';

/// Building blocks of the «ختمة جديدة» sheet's premium look (Ismail
/// 2026-10-13: «التصميم بدائي، نريد طابع ٣د»). Depth with Flutter-native
/// means only — Matrix4 perspective, layered gradients, soft shadows — no
/// 3D engine, no continuous animation (motion only when a value changes).

/// A muṣḥaf in 3/4 view: the real cover ([MushafCover], in the khatma's
/// colour and the chosen [style]), its spine on the right as an Arabic book
/// is bound, and the page block on the open side. Turns a little whenever
/// [turn] changes (plan length, colour, style), then rests.
class KhatmBook3D extends StatelessWidget {
  final Color color;
  final Object turn;
  final double size;
  final MushafCoverStyle style;
  const KhatmBook3D({
    super.key,
    required this.color,
    required this.turn,
    this.size = 92,
    this.style = MushafCoverStyle.shamsa,
  });

  @override
  Widget build(BuildContext context) {
    final w = size, h = size * 1.38;
    final spine = size * 0.09;
    final leather = mushafLeather(color);
    return TweenAnimationBuilder<double>(
      key: ValueKey(turn),
      tween: Tween(begin: 0.55, end: 0.30),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, angle, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateX(0.10)
          ..rotateY(angle),
        child: child,
      ),
      child: SizedBox(
        width: w + spine + 8,
        height: h + 8,
        child: Stack(children: [
          // page block, peeking out on the open (left) side
          Positioned(
            left: 0,
            top: 4,
            child: Container(
              width: w,
              height: h - 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(colors: [Color(0xFFE9DCC4), Color(0xFFFDF8EE)]),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.24), blurRadius: 16, offset: const Offset(-4, 10))],
              ),
              child: CustomPaint(painter: _PageLinesPainter()),
            ),
          ),
          // spine
          Positioned(
            left: 8 + w - 2,
            top: 0,
            child: Container(
              width: spine,
              height: h,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                gradient: LinearGradient(colors: [
                  Color.lerp(leather, Colors.black, 0.35)!,
                  Color.lerp(leather, Colors.white, 0.10)!,
                  Color.lerp(leather, Colors.black, 0.45)!,
                ]),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                for (var i = 0; i < 4; i++) Container(height: 1.2, color: const Color(0xFFE2C27A)),
              ]),
            ),
          ),
          Positioned(left: 8, top: 0, child: MushafCover(color: color, style: style, width: w)),
        ]),
      ),
    );
  }
}

class _PageLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 0.6;
    for (var x = 2.0; x < 10; x += 2) {
      canvas.drawLine(Offset(x, 4), Offset(x, s.height - 4), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A colour «coin»: raised when chosen (shadow + ring + lift).
class KhatmColorCoin extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const KhatmColorCoin({super.key, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 38,
          height: 38,
          transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.4),
              colors: [Color.lerp(color, Colors.white, 0.35)!, color, Color.lerp(color, Colors.black, 0.25)!],
              stops: const [0, 0.6, 1],
            ),
            border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: selected ? 0.55 : 0.25),
                blurRadius: selected ? 14 : 6,
                offset: Offset(0, selected ? 7 : 3),
              ),
            ],
          ),
          child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
        ),
      );
}

/// A ready-made plan: a small raised card with a big number.
class KhatmPresetCard extends StatelessWidget {
  final String big;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const KhatmPresetCard({
    super.key,
    required this.big,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          transform: Matrix4.translationValues(0, selected ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? accent : AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: (selected ? accent : Colors.black).withValues(alpha: selected ? 0.35 : 0.06),
                blurRadius: selected ? 16 : 8,
                offset: Offset(0, selected ? 8 : 3),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(big,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, height: 1.1, color: selected ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: 10.5, height: 1.3, color: selected ? Colors.white.withValues(alpha: 0.92) : AppColors.textMuted)),
          ]),
        ),
      );
}

/// A soft section card grouping related options.
class KhatmSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const KhatmSection({super.key, required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          child,
        ]),
      );
}
