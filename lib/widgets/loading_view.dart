import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reassuring loading state — Ismail's 2026-08-16 request ("الصفحة فارغة...
/// اعمل واجهة تحميل كي يحس المستخدم أن النظام يعمل وليس تالف"): a bare
/// centered spinner on an otherwise blank screen can read as frozen,
/// especially for waits longer than a second or two (location fixes,
/// first-load DB queries). Pairs a context-specific icon with an
/// explanatory message and a gentle pulse so the screen visibly feels
/// alive rather than static. Meant to be reused wherever a screen has an
/// initial async load, not just the Qibla screen that prompted it.
class AppLoadingView extends StatefulWidget {
  final IconData icon;
  final String message;
  const AppLoadingView({super.key, required this.icon, required this.message});

  @override
  State<AppLoadingView> createState() => _AppLoadingViewState();
}

class _AppLoadingViewState extends State<AppLoadingView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: 0.55 + 0.45 * _controller.value,
                child: Transform.scale(scale: 0.92 + 0.08 * _controller.value, child: child),
              ),
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: Icon(widget.icon, size: 30, color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
            ),
            const SizedBox(height: 14),
            Text(widget.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
