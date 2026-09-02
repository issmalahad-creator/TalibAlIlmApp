import 'package:flutter/material.dart';

import '../main.dart' show navigatorKey;
import '../theme/app_theme.dart';
import 'companion_chat_body.dart';

const _bubbleSize = 54.0;

/// "أيقونة رفيق عائمة تفتح المحادثة كنافذة منبثقة من أي صفحة" — Ismail,
/// 2026-08-18: sits above the whole app (wired into `main.dart`'s
/// `MaterialApp.builder`, outside any single screen's widget tree) so it's
/// reachable from the Quran reading screen, home, anywhere — tapping it
/// opens the same `CompanionChatBody` used by the full chat screen, as a
/// bottom sheet instead of a full navigation push.
///
/// Draggable ("عشان لا تغطي على اي شى" — Ismail, same day): the student can
/// drag it out of the way of whatever it's covering; position resets each
/// app launch rather than being persisted — this is "move it out of my way
/// right now", not a saved preference worth its own storage.
///
/// BUG FIX (found live on Ismail's device, 2026-08-18: "عند الضغط لايفتح اي
/// شى" — tap did nothing on the Quran reading screen): `builder`'s own
/// `context` sits ABOVE `MaterialApp`'s internal `Navigator` (it wraps the
/// Navigator, doesn't sit inside it), so `showModalBottomSheet(context:
/// context, ...)` had no Navigator ancestor to attach the route to and
/// silently failed. Fixed by using `navigatorKey.currentContext` — the same
/// global key `main.dart` already exposes for notification deep-links —
/// which IS inside the Navigator.
class CompanionFloatingBubble extends StatefulWidget {
  const CompanionFloatingBubble({super.key});

  /// Immersive full-bleed reading surfaces (the mushaf reader) bump this on
  /// entry and drop it on exit so the bubble doesn't float over the page /
  /// its app bar. `> 0` → hidden. A counter, not a bool, so nested pushes
  /// are safe.
  static final ValueNotifier<int> suppressed = ValueNotifier<int>(0);

  @override
  State<CompanionFloatingBubble> createState() => _CompanionFloatingBubbleState();
}

class _CompanionFloatingBubbleState extends State<CompanionFloatingBubble> {
  Offset? _position;
  bool _dragging = false;
  bool _sheetOpen = false;

  /// "اذا ضغطت مرتين تفتح مرتين" (Ismail, 2026-08-18) — the bubble stayed
  /// visible and tappable underneath its own open bottom sheet, so a second
  /// tap stacked a second sheet on top. Guarded with `_sheetOpen`, reset via
  /// `whenComplete` when the sheet is dismissed however it's dismissed
  /// (swipe down, back button, or code).
  void _open() {
    if (_sheetOpen) return;
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;
    setState(() => _sheetOpen = true);
    showModalBottomSheet(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: const CompanionChatBody(),
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _sheetOpen = false);
    });
  }

  void _clampToScreen(Size screenSize) {
    final pos = _position;
    if (pos == null) return;
    final clampedX = pos.dx.clamp(0.0, screenSize.width - _bubbleSize);
    final clampedY = pos.dy.clamp(0.0, screenSize.height - _bubbleSize);
    _position = Offset(clampedX, clampedY);
  }

  @override
  Widget build(BuildContext context) {
    // Hidden while its own sheet is open — it was visible floating on top
    // of the open chat in Ismail's screenshot, which is both confusing and
    // what let a second tap open a second sheet.
    if (_sheetOpen) return const SizedBox.shrink();

    return ValueListenableBuilder<int>(
      valueListenable: CompanionFloatingBubble.suppressed,
      builder: (context, n, _) =>
          n > 0 ? const SizedBox.shrink() : _bubble(context),
    );
  }

  Widget _bubble(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final defaultPosition = Offset(screenSize.width - _bubbleSize - 16, screenSize.height - _bubbleSize - 100);
    _position ??= defaultPosition;
    _clampToScreen(screenSize);
    final pos = _position!;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (details) => setState(() => _position = pos + details.delta),
        onPanEnd: (_) => setState(() => _dragging = false),
        onTap: _dragging ? null : _open,
        child: Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          elevation: _dragging ? 8 : 4,
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
