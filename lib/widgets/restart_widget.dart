import 'package:flutter/material.dart';

/// Forces the whole app to rebuild from scratch — every `State` object
/// disposed and recreated — by swapping the `Key` above [child]. 2026-08-17
/// (Ismail's "نفس الوندوز" idea, after `profile_screen.dart`'s language
/// dropdown was caught showing stale translations): a screen that reads
/// the current language into a local `State` field once (instead of a live
/// `ValueListenableBuilder` on `LanguagePreferenceService.languageNotifier`)
/// can otherwise keep showing the old language until it happens to
/// remount. A full restart makes that class of bug impossible everywhere,
/// not just in the screens already audited one by one.
class RestartWidget extends StatefulWidget {
  final Widget child;
  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restartApp() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}
