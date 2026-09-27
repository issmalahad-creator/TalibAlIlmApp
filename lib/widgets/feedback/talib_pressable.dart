import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The one press response for important tappables
/// (docs/architecture/INTERACTION_FEEDBACK_ARCHITECTURE.md §3–4): at 0 ms the
/// child sinks to 0.97 and dims a touch, so the user *sees* the tap landed —
/// before any navigation or work starts. Cheap: one 90 ms controller that
/// only runs while a finger is down.
///
/// Haptics are off by default (Ismail: no noisy defaults); pass [haptic] for
/// the few places where a physical tick genuinely helps.
///
/// With [onTap] null it only adds the press *visual* around a child that
/// handles its own taps (e.g. a Material button) — it never steals the tap.
class TalibPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;
  final double pressedScale;
  final String? semanticLabel;

  const TalibPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.haptic = false,
    this.pressedScale = 0.97,
    this.semanticLabel,
  });

  @override
  State<TalibPressable> createState() => _TalibPressableState();
}

class _TalibPressableState extends State<TalibPressable> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 160),
  );

  Offset? _downAt;

  void _down(PointerDownEvent e) {
    _downAt = e.position;
    if (widget.haptic) HapticFeedback.selectionClick();
    _press.forward();
  }

  /// A finger that travels is scrolling, not pressing — let go visually.
  void _move(PointerMoveEvent e) {
    final from = _downAt;
    if (from != null && (e.position - from).distance > 12) _up(null);
  }

  void _up(Object? _) {
    _downAt = null;
    _press.reverse();
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    Widget visual = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_press.value);
          final scale = reduceMotion ? 1.0 : 1 - (1 - widget.pressedScale) * t;
          return Transform.scale(
            scale: scale,
            child: Opacity(opacity: 1 - 0.08 * t, child: child),
          );
        },
        child: widget.child,
      ),
    );
    if (widget.onTap == null) return visual;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: visual),
    );
  }
}
