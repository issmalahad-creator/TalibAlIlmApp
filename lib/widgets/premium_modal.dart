import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Same gold accent already used elsewhere in the app (Qibla glow, the
/// home-screen Quran hero card) — reused exactly, not a new gold.
const _goldAccent = Color(0xFFD9A441);

/// "طابع الـ3D" (quirky-gliding-shell.md's premium-depth plan) — one
/// reusable "floating panel" replacing raw `AlertDialog`/`showDialog`
/// chrome, applied to a few template sites first (see the plan for why
/// only 3 of the app's 19 dialog-using files, not all of them at once).
///
/// Real depth via `BackdropFilter` blur (the app's first use of this
/// technique — confirmed via a full-codebase grep before adding it, no
/// existing pattern it might conflict with) + layered `BoxShadow` + a thin
/// gold-tinted border, not literal CSS `translateZ`/`perspective` (those
/// have no equivalent meaning in Flutter's renderer — a web design's
/// intent, not its mechanism, is what's translated here).
Future<T?> showPremiumModal<T>(
  BuildContext context, {
  required String title,
  IconData? icon,
  required Widget child,
  List<Widget>? actions,
}) {
  return showPremiumDialogTransition<T>(
    context,
    barrierLabel: title,
    builder: (context) => _PremiumModalSurface(title: title, icon: icon, actions: actions, child: child),
  );
}

/// The lower-level entrance-transition (blur + fade + scale + rise) without
/// the titled-card shell — for content that already has its own bespoke
/// layout and shouldn't be boxed into a generic card (e.g.
/// `celebration_overlay.dart`'s confetti + certificate, which needs a
/// full-bleed dark backdrop, not a bordered surface).
Future<T?> showPremiumDialogTransition<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String barrierLabel = '',
  Color barrierColor = const Color(0x59000000),
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    transitionDuration: AppMotion.premium,
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, _) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.entranceCurve, reverseCurve: AppMotion.exitCurve);
      return AnimatedBuilder(
        animation: curved,
        builder: (context, child) {
          final t = curved.value.clamp(0.0, 1.0);
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6 * t, sigmaY: 6 * t),
            child: Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 18),
                child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
              ),
            ),
          );
        },
        child: Center(child: Builder(builder: builder)),
      );
    },
  );
}

class _PremiumModalSurface extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final List<Widget>? actions;
  const _PremiumModalSurface({required this.title, this.icon, required this.child, this.actions});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: _goldAccent.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 40, offset: const Offset(0, 20)),
            BoxShadow(color: _goldAccent.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 30, color: _goldAccent),
              const SizedBox(height: 8),
            ],
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.headline),
            const SizedBox(height: 14),
            Flexible(child: SingleChildScrollView(child: child)),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [for (final a in actions!) Padding(padding: const EdgeInsets.only(left: 8), child: a)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
