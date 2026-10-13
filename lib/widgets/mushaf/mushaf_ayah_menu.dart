import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/depth.dart';
import '../../theme/motion.dart';

/// One row of the ayah menu.
class MushafAyahMenuItem<T> {
  final T value;
  final IconData icon;
  final String label;
  const MushafAyahMenuItem(this.value, this.icon, this.label);
}

const _kGold = Color(0xFFD9A441);
const _kCream = Color(0xFFFBF6EE);
const _kBrown = Color(0xFF8B6F47);

/// The floating ayah menu (long-press an ayah in the reader): a warm cream
/// card with a gold edge that grows out of the ayah — placed above it when
/// there is room, else below, never on top of the selected lines.
///
/// Returns the picked item's value, or null when dismissed.
Future<T?> showMushafAyahMenu<T>({
  required BuildContext context,
  required Rect anchor,
  required List<MushafAyahMenuItem<T>> items,
  required bool night,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.06),
    transitionDuration: AppMotion.fast,
    pageBuilder: (ctx, _, _) =>
        _AyahMenuLayout(anchor: anchor, items: items, night: night),
    transitionBuilder: (ctx, anim, _, child) {
      final reduce = MediaQuery.maybeDisableAnimationsOf(ctx) ?? false;
      if (reduce) return child;
      final t = CurvedAnimation(parent: anim, curve: AppMotion.entranceCurve);
      return FadeTransition(
        opacity: t,
        child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(t), child: child),
      );
    },
  );
}

class _AyahMenuLayout<T> extends StatelessWidget {
  final Rect anchor;
  final List<MushafAyahMenuItem<T>> items;
  final bool night;
  const _AyahMenuLayout(
      {required this.anchor, required this.items, required this.night});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screen = mq.size;
    const rowH = 52.0;
    const width = 236.0;
    final height = rowH * items.length + 12;
    final top0 = mq.padding.top + 8;
    final bottom0 = screen.height - mq.padding.bottom - 8;

    double top;
    if (anchor.top - height - 8 >= top0) {
      top = anchor.top - height - 8; // above the ayah
    } else if (anchor.bottom + height + 8 <= bottom0) {
      top = anchor.bottom + 8; // below it
    } else {
      // a very long ayah fills the screen — float centred over it
      top = (screen.height - height) / 2;
    }
    top = top.clamp(top0, (bottom0 - height).clamp(top0, double.infinity));
    final left = (anchor.center.dx - width / 2).clamp(12.0, screen.width - width - 12);

    final bg = night ? AppColors.surfaceNight : _kCream;
    final fg = night ? AppColors.textDarkNight : AppColors.textDark;
    final iconBg = night ? _kGold.withValues(alpha: 0.18) : _kBrown;
    final iconFg = night ? _kGold : Colors.white;
    final divider = (night ? Colors.white : _kBrown).withValues(alpha: 0.14);

    return Stack(children: [
      Positioned(
        left: left,
        top: top,
        width: width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGold.withValues(alpha: 0.55), width: 1.2),
              boxShadow: DepthShadows.floating(_kBrown),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 1, indent: 18, endIndent: 18, color: divider),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(items[i].value),
                    child: SizedBox(
                      height: rowH - 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                color: iconBg, borderRadius: BorderRadius.circular(9)),
                            child: Icon(items[i].icon, size: 17, color: iconFg),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(items[i].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: fg)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}
