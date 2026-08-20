import 'package:flutter/animation.dart';

/// Talib Al-Ilm's shared motion vocabulary — Ismail's 2026-08-16 request
/// after an app-wide audit found 19 existing animation call sites each
/// picking their own duration ad hoc (200/250/300/350/400/450/550/700/900/
/// 1100ms, no shared pattern). See `ANIMATION_ASSET_PLAN.md` for the full
/// audit. This file doesn't change any of those existing call sites (out
/// of scope for this pass) — it's the shared vocabulary new work should
/// use going forward, and a reference point for gradually consolidating
/// old call sites onto it.
///
/// Four tiers, derived from what's already proven to feel right in this
/// app (not invented numbers):
/// - [fast]: a state flips instantly and needs to feel responsive —
///   selection highlights, small toggles. Matches the existing
///   `_BorderedOptionTile` (200ms) and counter-badge (250ms) precedent.
/// - [normal]: an ordinary UI transition — fade/slide/color change.
///   Matches the existing Qibla-glow (350ms) and chrome-fade (400ms)
///   precedent.
/// - [premium]: something worth noticing — an entrance, a completion
///   flash. Matches the existing banner entrance (450ms) and adhkar glow
///   (700ms) precedent.
/// - [ambient]: a continuous or looping indicator (pulses, breathing
///   icons) — never a one-shot transition. Matches the existing
///   pulsing-badge precedent (900-1100ms per cycle).
class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 350);
  static const premium = Duration(milliseconds: 600);
  static const ambient = Duration(milliseconds: 1000);

  /// Entrances (something appearing/growing into place).
  static const entranceCurve = Curves.easeOutCubic;

  /// Exits/fades (something leaving/shrinking).
  static const exitCurve = Curves.easeIn;

  /// Ordinary state-to-state transitions (color/size/position changes
  /// that aren't specifically an entrance or exit).
  static const stateCurve = Curves.easeInOut;
}
