import 'package:flutter/widgets.dart';

/// Two-finger pinch for the mushaf reader — a raw [Listener], so it never
/// enters the gesture arena and never steals a one-finger swipe, scroll or
/// word tap from the views underneath.
///
/// While two fingers are down [onPinchActive] is true (the reader freezes
/// its scroll views so the page doesn't slide under the pinch) and
/// [onUpdate] reports the scale relative to the pinch start plus the focal
/// point, in this widget's local coordinates.
class PinchZoomListener extends StatefulWidget {
  final Widget child;
  final VoidCallback onStart;
  final void Function(double scaleSinceStart, Offset focalLocal) onUpdate;
  final ValueChanged<bool> onPinchActive;

  const PinchZoomListener({
    super.key,
    required this.child,
    required this.onStart,
    required this.onUpdate,
    required this.onPinchActive,
  });

  @override
  State<PinchZoomListener> createState() => _PinchZoomListenerState();
}

class _PinchZoomListenerState extends State<PinchZoomListener> {
  final _pointers = <int, Offset>{};
  double? _startDistance;

  double get _distance {
    final p = _pointers.values.take(2).toList();
    return (p[0] - p[1]).distance;
  }

  Offset get _focal {
    final p = _pointers.values.take(2).toList();
    return (p[0] + p[1]) / 2;
  }

  void _down(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 2) {
      _startDistance = _distance;
      widget.onPinchActive(true);
      widget.onStart();
    }
  }

  void _move(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    final start = _startDistance;
    if (_pointers.length >= 2 && start != null && start > 8) {
      widget.onUpdate(_distance / start, _focal);
    }
  }

  void _up(PointerEvent e) {
    final wasPinching = _pointers.length >= 2;
    _pointers.remove(e.pointer);
    if (wasPinching && _pointers.length < 2) {
      _startDistance = null;
      widget.onPinchActive(false);
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: widget.child,
      );
}
