import 'package:flutter/material.dart';

/// A small book seen at an angle — cover, spine, page edge — for library
/// lists instead of a flat file icon (Ismail 2026-10-22: «2D إلى 3D»).
/// The cover colour comes from the title, so a book keeps its look.
class Book3D extends StatelessWidget {
  final String title;
  final double height;
  const Book3D({super.key, required this.title, this.height = 52});

  static const _covers = <Color>[
    Color(0xFF1F4E5F), Color(0xFF6B2D2D), Color(0xFF2E5A3A), Color(0xFF4A3B6B),
    Color(0xFF7A5A2E), Color(0xFF2B3F66), Color(0xFF5E2E4F), Color(0xFF3D4A3A),
  ];

  @override
  Widget build(BuildContext context) {
    final c = _covers[title.runes.fold<int>(7, (h, r) => (h * 31 + r) & 0x7fffffff) % _covers.length];
    final w = height * 0.72;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.003)
        ..rotateY(0.42),
      child: SizedBox(
        width: w + 5,
        height: height,
        child: Stack(children: [
          // page edge on the open side
          Positioned(
            left: 0,
            top: 2,
            bottom: 2,
            child: Container(
              width: w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(colors: [Color(0xFFE6DAC2), Color(0xFFFBF6EC)]),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 6, offset: const Offset(-2, 4))],
              ),
            ),
          ),
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: Container(
              width: w,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(3), right: Radius.circular(2)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(c, Colors.white, 0.18)!, c, Color.lerp(c, Colors.black, 0.35)!],
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(height: 1.2, margin: EdgeInsets.symmetric(horizontal: w * 0.18), color: const Color(0xFFE2C27A)),
                SizedBox(height: height * 0.12),
                Container(height: 1.2, margin: EdgeInsets.symmetric(horizontal: w * 0.18), color: const Color(0xFFE2C27A)),
              ]),
            ),
          ),
          // spine on the right
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3.5, color: Color.lerp(c, Colors.black, 0.45)),
          ),
        ]),
      ),
    );
  }
}
