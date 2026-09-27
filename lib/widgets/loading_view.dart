import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'feedback/light_trail.dart';

/// Contextual loading state for a screen's initial async load — Ismail's
/// 2026-08-16 request ("الصفحة فارغة... اعمل واجهة تحميل كي يحس المستخدم أن
/// النظام يعمل وليس تالف"), upgraded in IF-2 (2026-09-27) to the timing
/// rules of docs/architecture/INTERACTION_FEEDBACK_ARCHITECTURE.md §3:
///
/// | elapsed | shown |
/// |---|---|
/// | < 300 ms | nothing (a fast load must never *look* like loading) |
/// | ≥ 300 ms | the screen's icon, breathing, + the gold light trail |
/// | ≥ 800 ms | the contextual [message] ("جاري فتح الكتاب…", never "Loading") |
///
/// Same API as before, so every screen using it gets the new behaviour.
/// No spinner in the middle of an empty page: the light trail is the app's
/// one "working" mark, shared with the brand splash.
class AppLoadingView extends StatefulWidget {
  final IconData icon;
  final String message;

  /// Overridable for tests; production uses the §3 thresholds.
  final Duration revealAfter;
  final Duration messageAfter;

  const AppLoadingView({
    super.key,
    required this.icon,
    required this.message,
    this.revealAfter = const Duration(milliseconds: 300),
    this.messageAfter = const Duration(milliseconds: 800),
  });

  @override
  State<AppLoadingView> createState() => _AppLoadingViewState();
}

class _AppLoadingViewState extends State<AppLoadingView> with SingleTickerProviderStateMixin {
  // Created only when we actually reveal — a fast load costs no animation.
  AnimationController? _loop;
  Timer? _revealTimer;
  Timer? _messageTimer;
  bool _revealed = false;
  bool _showMessage = false;

  @override
  void initState() {
    super.initState();
    _revealTimer = Timer(widget.revealAfter, () {
      if (!mounted) return;
      _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
      setState(() => _revealed = true);
    });
    _messageTimer = Timer(widget.messageAfter, () {
      if (mounted) setState(() => _showMessage = true);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _messageTimer?.cancel();
    _loop?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loop = _loop;
    if (!_revealed || loop == null) {
      // Occupies the space silently; semantics still announce the wait.
      return Semantics(label: widget.message, liveRegion: true, child: const SizedBox.expand());
    }
    return Semantics(
      label: widget.message,
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 260),
            builder: (context, fade, child) => Opacity(opacity: fade, child: child),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: loop,
                  builder: (context, child) {
                    // One slow breath per loop (calm, not busy).
                    final v = 0.5 - 0.5 * math.cos(loop.value * 2 * math.pi);
                    return Opacity(
                      opacity: 0.6 + 0.4 * v,
                      child: Transform.scale(scale: 0.95 + 0.05 * v, child: child),
                    );
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: Icon(widget.icon, size: 30, color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(height: 18),
                LightTrail(animation: loop, passes: 2),
                const SizedBox(height: 14),
                AnimatedOpacity(
                  opacity: _showMessage ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
