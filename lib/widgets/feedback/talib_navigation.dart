import 'package:flutter/material.dart';

/// Navigation that behaves the same everywhere
/// (docs/architecture/INTERACTION_FEEDBACK_ARCHITECTURE.md §4, IF-1):
///
/// - **Deduplicated:** the same [key] pushed again while its route is still
///   being pushed/open — or within [dedupeWindow] of the last push — does
///   nothing. Three fast taps on «القرآن» open one page, not three.
/// - **One transition language:** a short fade + slide from the reading
///   direction's start edge (RTL-aware); no spinner — the motion itself is
///   the feedback for fast pages.
///
/// Returns the route's result, or null when the push was deduplicated.
Future<T?> talibPush<T>(
  BuildContext context,
  String key,
  WidgetBuilder builder, {
  Duration dedupeWindow = const Duration(milliseconds: 600),
}) async {
  final now = DateTime.now();
  final last = _lastPushAt[key];
  if (_inFlight.contains(key) || (last != null && now.difference(last) < dedupeWindow)) {
    return null;
  }
  _inFlight.add(key);
  _lastPushAt[key] = now;
  try {
    return await Navigator.of(context).push<T>(talibRoute<T>(builder));
  } finally {
    _inFlight.remove(key);
  }
}

final _inFlight = <String>{};
final _lastPushAt = <String, DateTime>{};

/// For tests only: forget every recorded push.
@visibleForTesting
void resetTalibNavigationForTest() {
  _inFlight.clear();
  _lastPushAt.clear();
}

/// The shared page transition: 260 ms in, 200 ms out; honours
/// "remove animations" in system accessibility settings.
PageRoute<T> talibRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) => builder(context),
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(rtl ? -0.06 : 0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
