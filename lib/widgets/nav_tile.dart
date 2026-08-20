import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Colorful icon-grid navigation tile, replacing the plain outlined
/// buttons that used to fill "الملف الشخصي" — Ismail's request 2026-08-16
/// ("أريد أيقونات جذابة نفس هذا"), matching the solid-color-circle +
/// white-icon style of the reference app screenshot he sent. Purely
/// visual: every tile still just calls the same `onTap` navigation that
/// existed before.
class NavTileData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const NavTileData({required this.icon, required this.label, required this.color, required this.onTap});
}

class NavTile extends StatelessWidget {
  final NavTileData data;

  /// Position within its [NavGrid] — drives the staggered entrance below.
  /// 0 when used standalone (no stagger, appears immediately).
  final int index;

  const NavTile({super.key, required this.data, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final content = InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
              child: Icon(data.icon, color: Colors.white, size: 25),
            ),
            const SizedBox(height: 6),
            Text(
              data.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
    if (index == 0) return content;

    // Staggered fade+scale entrance (Ismail's 2026-08-16 decorative-features
    // request, roadmap §4.34 point 5) — each tile's animation window starts
    // a little later than the one before it via `Interval`, so the grid
    // appears as a gentle wave instead of popping in all at once. Capped so
    // later tiles in a long grid (e.g. the full الملف الشخصي list) don't
    // end up waiting an unreasonably long time to appear.
    final delay = (index * 0.06).clamp(0.0, 0.5);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.premium,
      curve: Interval(delay, 1.0, curve: AppMotion.entranceCurve),
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
      ),
      child: content,
    );
  }
}

/// Fixed 4-per-row grid of [NavTile]s, sized to its content (embeds inside
/// a scrolling `ListView` rather than scrolling itself).
class NavGrid extends StatelessWidget {
  final List<NavTileData> items;
  const NavGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // 2026-08-17: was 0.78 — a screenshot caught a hairline
      // "BOTTOM OVERFLOWED BY 0.179 PIXELS" debug banner on tiles whose
      // 2-line label is close to the cell's fixed height (translated
      // labels can run a hair longer than the Arabic original). A touch
      // more height per cell removes the margin-of-error entirely.
      childAspectRatio: 0.74,
      children: [for (var i = 0; i < items.length; i++) NavTile(data: items[i], index: i + 1)],
    );
  }
}

/// A shared color palette so the same feature always gets the same color
/// wherever it appears (home quick-access row vs. the full profile grid).
class NavColors {
  static const teal = Color(0xFF0FA3B1);
  static const blue = Color(0xFF2F80ED);
  static const purple = Color(0xFF7C4DFF);
  static const orange = Color(0xFFFF8A3D);
  static const pink = Color(0xFFE85D9E);
  static const green = Color(0xFF2FAE60);
  static const gold = Color(0xFFD9A441);
  static const indigo = Color(0xFF5C6BC0);
  static const coral = Color(0xFFEF6461);
  static const brown = Color(0xFFB5651D);
  static const cyan = Color(0xFF17A2B8);
  static const deepPurple = Color(0xFF6A4C93);
}
