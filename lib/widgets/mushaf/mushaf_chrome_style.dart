import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The reader's own warm palette — cream paper, brown leather, gold — shared
/// by the reader chrome, its menu, the index and the mushaf search so they
/// read as one place (Ismail's reference screenshots, 2026-10-10).
abstract final class MushafChrome {
  static const cream = Color(0xFFFFF8F0);
  static const paper = Color(0xFFFBF6EE);
  static const brown = Color(0xFF9C7A5B);
  static const brownDark = Color(0xFF6F5238);
  static const tan = Color(0xFFEFE2CF);
  static const gold = Color(0xFFC8962E);

  static Color bg(bool night) => night ? AppColors.backgroundNight : cream;
  static Color fg(bool night) => night ? AppColors.textDarkNight : AppColors.textDark;
  static Color line(bool night) =>
      (night ? Colors.white : brown).withValues(alpha: 0.18);
}

/// `صفحة ١` — Arabic-Indic digits in Arabic, Western digits elsewhere.
String mushafDigits(int n, String lang) {
  if (lang != 'ar') return '$n';
  const d = '٠١٢٣٤٥٦٧٨٩';
  return '$n'.split('').map((c) => d[int.parse(c)]).join();
}

/// The reference screens' back arrow points left («←») in every direction;
/// Material's arrows mirror under RTL, so pick the one that lands on «←».
IconData mushafBackIcon(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
        ? Icons.arrow_forward_rounded
        : Icons.arrow_back_rounded;

/// The rounded square icon button of the reader screens (back, search…).
class MushafSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool night;
  const MushafSquareButton(
      {super.key, required this.icon, required this.onTap, this.tooltip, this.night = false});

  @override
  Widget build(BuildContext context) {
    final b = Material(
      color: night ? AppColors.surfaceNight : MushafChrome.tan,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: MushafChrome.line(night)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, size: 22, color: night ? MushafChrome.gold : const Color(0xFF1F2A44)),
        ),
      ),
    );
    return tooltip == null ? b : Tooltip(message: tooltip!, child: b);
  }
}

/// Two-option pill toggle (سورة | أجزاء, رأسي | أفقي) — the selected half is
/// filled brown, the other stays paper.
class MushafSegmented extends StatelessWidget {
  final List<({String label, IconData? icon})> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool night;
  const MushafSegmented(
      {super.key, required this.options, required this.selected, required this.onChanged, this.night = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: night ? AppColors.surfaceNight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MushafChrome.brown.withValues(alpha: 0.7)),
      ),
      child: Row(children: [
        for (var i = 0; i < options.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: i == selected ? MushafChrome.brown : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (options[i].icon != null) ...[
                    Icon(options[i].icon,
                        size: 18,
                        color: i == selected ? Colors.white : MushafChrome.fg(night)),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(options[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: i == selected ? Colors.white : MushafChrome.fg(night))),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}
