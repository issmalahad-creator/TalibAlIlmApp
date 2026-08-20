import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/depth.dart';
import '../theme/motion.dart';

/// A card with real physical depth (`DepthShadows.floating`) and a
/// physical-feeling press-in when tappable — the "3DCard" material from
/// quirky-gliding-shell.md's global design-language plan, generalized from
/// what `quran_reading_screen.dart`/`premium_modal.dart` already proved.
/// Reach for this on NEW cards, or when upgrading an existing plain
/// `Container` card for another reason anyway — not a forced replacement
/// of every card in the app.
class DepthCard extends StatefulWidget {
  final Widget child;
  final DepthPalette palette;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  const DepthCard({
    super.key,
    required this.child,
    this.palette = DepthPalette.dashboard,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.lg,
    this.color,
  });

  @override
  State<DepthCard> createState() => _DepthCardState();
}

class _DepthCardState extends State<DepthCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.stateCurve,
      padding: widget.padding,
      transform: _pressed ? (Matrix4.identity()..scaleByDouble(0.985, 0.985, 0.985, 1.0)) : Matrix4.identity(),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: widget.palette.accent.withValues(alpha: 0.14)),
        boxShadow: _pressed ? DepthShadows.soft(widget.palette.accent) : DepthShadows.floating(widget.palette.accent),
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return content;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: content,
    );
  }
}

/// A circular floating icon button with real depth — the "3DIconButton"
/// material. Press-in via a shrinking shadow + slight scale, the touch
/// equivalent of a physical button's give (no `:hover` — this is a touch
/// app).
class DepthIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final DepthPalette palette;
  final double size;
  const DepthIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.palette = DepthPalette.dashboard,
    this.size = 44,
  });

  @override
  State<DepthIconButton> createState() => _DepthIconButtonState();
}

class _DepthIconButtonState extends State<DepthIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.stateCurve,
        width: widget.size,
        height: widget.size,
        transform: _pressed ? (Matrix4.identity()..scaleByDouble(0.94, 0.94, 0.94, 1.0)) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          boxShadow: _pressed ? DepthShadows.soft(widget.palette.accent) : DepthShadows.floating(widget.palette.accent),
        ),
        child: Icon(widget.icon, color: widget.palette.accent, size: widget.size * 0.45),
      ),
    );
  }
}
