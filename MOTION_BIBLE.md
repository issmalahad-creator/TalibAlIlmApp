# MOTION_BIBLE.md — Talib Al-Ilm's motion language

Written 2026-08-16 after a full codebase audit (see `ANIMATION_ASSET_PLAN.md` §A) found the app's existing motion — 5 `AnimationController`s, 1 `TweenSequence`, 1 `TweenAnimationBuilder`, 14 implicit-animation widgets — is real and already good, but each site picked its own duration independently (200/250/300/350/400/450/550/700/900/1100ms scattered with no shared pattern). This document doesn't add a new animation technology. It names the pattern that was already emerging so new work stops re-deriving it.

## The four tiers

Defined as real code in `lib/theme/motion.dart` (`AppMotion`), not just numbers on a page:

| Tier | Duration | When | Existing precedent |
|---|---|---|---|
| `AppMotion.fast` | 180ms | A state flips and needs to feel instant — selection highlights, small toggles | `_BorderedOptionTile` (200ms), adhkar counter badge (250ms) |
| `AppMotion.normal` | 350ms | An ordinary transition — fade, slide, color change | Qibla-facing glow (350ms), adhkar chrome fade (400ms) |
| `AppMotion.premium` | 600ms | Something worth noticing — an entrance, a completion flash | Home banner entrance (450ms), adhkar golden glow (700ms) |
| `AppMotion.ambient` | 1000ms/cycle | A continuous or looping indicator — never a one-shot | Pulsing focus badge (900ms), map "you are here" pulse (1100ms) |

Plus three named curves: `entranceCurve` (`easeOutCubic`, for things appearing), `exitCurve` (`easeIn`, for things leaving), `stateCurve` (`easeInOut`, for ordinary state changes).

## Scope of this pass

This is the vocabulary, not a rewrite. The 19 existing call sites listed in `ANIMATION_ASSET_PLAN.md` are **not** changed here — that would be scope creep beyond "build the simple thing first." New animation work should reach for `AppMotion` constants; existing call sites migrate opportunistically whenever that file is touched for another reason anyway, not as a dedicated sweep.

## The 5 template screens

Ismail's own scoping: prove the motion language on 5 screens before touching the other 66. Status (rollout completed 2026-08-17):

1. **الرئيسية (Home)** — `NavTile` entrance now uses `AppMotion.premium`/`entranceCurve` (was a bespoke 550ms), `AnimatedBanner`'s fade+slide now uses `AppMotion.premium`/`entranceCurve` (was 450ms/`easeOut`).
2. **جلسة اليوم (Daily Session)** — `GuidedSessionScreen`'s body wrapped in an `AnimatedSwitcher` (`AppMotion.normal`, `entranceCurve`/`exitCurve`), keyed by `_step`, so moving between the picker/each phase/the reflection step now crossfades instead of jumping.
3. **الحفظ (Memorization/Review)** — `ReviewScreen`'s current-unit card wrapped in an `AnimatedSwitcher` (`AppMotion.normal`), keyed by `unit.id`, so advancing to the next due page crossfades.
4. **خريطة الرحلة (Journey Map)** — `CurriculumMapScreen`'s pulsing "you are here" node now uses `AppMotion.ambient` (was a bespoke 1100ms — the two were already close, now exactly aligned).
5. **الشهادة (Certificate)** — still fully delegated to the `confetti` package; deliberately left untouched, matching the original scoping decision (no native-motion gap to close here).

All 5 now consume `AppMotion` constants rather than ad-hoc duration literals. The other 66 screens are unaffected — this was a targeted proof, not an app-wide sweep.
