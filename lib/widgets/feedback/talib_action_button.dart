import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../services/language_preference_service.dart';
import 'talib_pressable.dart';

/// Where a [TalibActionButton] is in its life
/// (docs/architecture/INTERACTION_FEEDBACK_ARCHITECTURE.md §4). A slow run is
/// still `running` — "slow" is only a presentation tier, never a failure.
enum TalibActionState { idle, running, success, failed }

/// A button that always tells the user what happened to their tap — without
/// making fast actions look slow:
///
/// | elapsed | shown |
/// |---|---|
/// | 0 ms | press response ([TalibPressable]); taps now ignored (no double run) |
/// | ≥ 300 ms | small in-place spinner next to the label |
/// | ≥ 800 ms | the contextual [runningLabel] ("جاري الحفظ…") |
/// | done | ✓ + [successLabel] for [successHold], then back to idle |
/// | error | ! + [failureLabel] (plain words, never an exception) — the next tap retries |
///
/// Colour is never the only signal: every state has its own icon and words.
class TalibActionButton extends StatefulWidget {
  final String label;

  /// The action. Return `false` when nothing was done (e.g. an empty field
  /// the handler ignored) — the button goes quietly back to idle instead of
  /// claiming «تم». Any other result (including plain `Future<void>`) is a
  /// success; a thrown error is a failure.
  final Future<Object?> Function() onPressed;
  final String? runningLabel;
  final String? successLabel;
  final String? failureLabel;
  final IconData? icon;
  final Duration successHold;
  final bool filled;

  const TalibActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.runningLabel,
    this.successLabel,
    this.failureLabel,
    this.icon,
    this.successHold = const Duration(milliseconds: 1400),
    this.filled = true,
  });

  @override
  State<TalibActionButton> createState() => TalibActionButtonState();
}

@visibleForTesting
class TalibActionButtonState extends State<TalibActionButton> {
  TalibActionState state = TalibActionState.idle;
  bool showSpinner = false;
  bool showRunningLabel = false;
  Timer? _spinnerTimer;
  Timer? _labelTimer;
  Timer? _resetTimer;

  Future<void> _run() async {
    if (state == TalibActionState.running) return; // dedupe: one run at a time
    _resetTimer?.cancel();
    setState(() {
      state = TalibActionState.running;
      showSpinner = false;
      showRunningLabel = false;
    });
    _spinnerTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && state == TalibActionState.running) setState(() => showSpinner = true);
    });
    _labelTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && state == TalibActionState.running) setState(() => showRunningLabel = true);
    });
    var ok = true;
    var nothingDone = false;
    try {
      nothingDone = (await widget.onPressed()) == false;
    } catch (e, st) {
      ok = false;
      // Details stay in the log; the user gets words, not an exception.
      debugPrint('TalibActionButton "${widget.label}" failed: $e\n$st');
    }
    _spinnerTimer?.cancel();
    _labelTimer?.cancel();
    if (!mounted) return;
    if (nothingDone) {
      setState(() => state = TalibActionState.idle);
      return;
    }
    setState(() => state = ok ? TalibActionState.success : TalibActionState.failed);
    if (ok) {
      _resetTimer = Timer(widget.successHold, () {
        if (mounted) setState(() => state = TalibActionState.idle);
      });
    }
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    _labelTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final scheme = Theme.of(context).colorScheme;
    final (Widget? lead, String text) = switch (state) {
      TalibActionState.idle => (widget.icon == null ? null : Icon(widget.icon, size: 18), widget.label),
      TalibActionState.running => (
          showSpinner
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : null,
          showRunningLabel ? (widget.runningLabel ?? basicText('feedback_working', lang)) : widget.label,
        ),
      TalibActionState.success => (
          const Icon(Icons.check_rounded, size: 18),
          widget.successLabel ?? basicText('feedback_done', lang),
        ),
      TalibActionState.failed => (
          const Icon(Icons.error_outline_rounded, size: 18),
          '${widget.failureLabel ?? basicText('feedback_failed', lang)} · ${basicText('feedback_retry', lang)}',
        ),
    };

    final content = AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lead != null) ...[lead, const SizedBox(width: 8)],
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(text, key: ValueKey(text), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );

    final failed = state == TalibActionState.failed;
    final style = widget.filled
        ? FilledButton.styleFrom(
            backgroundColor: failed ? scheme.errorContainer : null,
            foregroundColor: failed ? scheme.onErrorContainer : null,
          )
        : OutlinedButton.styleFrom(foregroundColor: failed ? scheme.error : null);

    // The button stays tappable-looking while running (never "dead"), but
    // _run ignores taps until the current run ends.
    final onPressed = _run;
    final button = widget.filled
        ? FilledButton(onPressed: onPressed, style: style, child: content)
        : OutlinedButton(onPressed: onPressed, style: style, child: content);

    return Semantics(
      liveRegion: true,
      child: TalibPressable(onTap: null, child: button), // press visual only
    );
  }
}
