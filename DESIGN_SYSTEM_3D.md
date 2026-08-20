# DESIGN_SYSTEM_3D.md — طالب العلم's global depth/materials language

Written 2026-08-17. Started as a request to give the Quran reading screen a "premium 3D" feel (from a ChatGPT-sourced design mockup, CSS that doesn't run in Flutter). Ismail then explicitly widened the scope: **this is not a Quran-reader-only effect — it's meant to become the visual language of the whole app**, with each section free to pick its own accent color rather than one palette forced everywhere, and with explicit creative freedom given ("اعمل كما تحب وما يناسبك" / "لا أريد التحكم في كل التفاصيل، استخدم حكمك").

## The core idea

What actually reads as "one coherent product" when moving between screens is **shared shadow/elevation mechanics**, not identical colors. So the system splits into two layers:

1. **`lib/theme/depth.dart`** — `DepthShadows` (3 tiers: `soft`/`floating`/`modal`, same naming spirit as `AppMotion`'s `fast`/`normal`/`premium`/`ambient`) + `DepthPalette` (a per-section accent color, several named presets: `quran` gold, `dashboard` green, `knowledge` indigo, `calm` gray).
2. **`lib/widgets/depth_surface.dart`** — reusable materials built on those tokens: `DepthCard` (a card with real physical depth + press-in feedback) and `DepthIconButton` (circular floating icon button, same press-in language). More materials get added here as real screens actually need them — not all ten named in the original request invented up front.

Same discipline as `AppMotion`/`AppRadius`/`AppTextStyles` before it: **a named vocabulary for NEW work**. Existing screens migrate opportunistically when touched for another reason anyway, never a forced rewrite of all 71+ screens in one pass.

## What "3D" means here, concretely

Real Flutter depth (`BoxShadow` layering, `BackdropFilter` blur, `Transform`/`Matrix4`, `AnimatedContainer`/`TweenAnimationBuilder`), not literal CSS properties translated 1:1 — `perspective`/`transform-style: preserve-3d`/`:hover` have no meaning in Flutter's renderer, and mouse-parallax doesn't exist on a touch phone. Where the original design asked for something that doesn't map to this platform, it was translated to its Flutter/touch equivalent (mouse-hover → tap/press feedback; mouse-parallax → real device-tilt parallax via the rotation sensor already used in `qibla_screen.dart`) rather than skipped or faked.

## Rollout status

| Piece | Status | Files |
|---|---|---|
| Mushaf page depth (layered shadow, tilt-parallax light, page-turn transition) | ✅ Done | `quran_reading_screen.dart` |
| `PremiumModal`/`showPremiumDialogTransition` (BackdropFilter blur, gold-tinted floating panel) | ✅ Done, 3 template sites | `premium_modal.dart`, `celebration_overlay.dart`, `add_task_screen.dart`, `goals_screen.dart` |
| `DepthShadows`/`DepthPalette` token layer | ✅ Done | `lib/theme/depth.dart` |
| `DepthCard`/`DepthIconButton` reusable materials | ✅ Done | `lib/widgets/depth_surface.dart` |
| First real-screen application (الرئيسية/Dashboard) | ✅ Done, 1 card | `home_screen.dart`'s `_ProgressCard` |
| Everything else (68+ screens: hadith/aqeedah, library, learning screens, profile/settings, forms, empty states, etc.) | ⏳ Not started | — |

## Per-section intensity (Ismail's own guidance)

Not every screen should be equally "loud":

- **القرآن/المكتبة** (`DepthPalette.quran`, gold) — deepest treatment. Already has the Mushaf page's shadow+parallax.
- **الرئيسية/لوحة القيادة** (`DepthPalette.dashboard`, green) — modern, moderate depth. Started with `_ProgressCard`.
- **الحديث/العقيدة** (`DepthPalette.knowledge`, indigo) — a visually distinct accent from Quran gold, moderate depth.
- **الإعدادات وما شابه** (`DepthPalette.calm`, gray) — deliberately light. Skip 3D where it would hurt readability or usability, per Ismail's own explicit instruction — flatter stays flatter when that's the right call.

## What's deliberately NOT done (with reasons)

- **Not all 71+ screens redesigned in one pass** — the same "prove it on real screens first" discipline used for every other design-system rollout this project has ever done (`AppMotion`'s 5 template screens, `AppRadius`, the tafsir library's 2-languages-first). A full-app visual rewrite done blind, unverified, in one shot is the single highest-risk kind of change to a 71-screen app with real working functionality — it gets done in small, checkable batches instead.
- **No business logic, features, or working screens removed or replaced** — every application of this system so far has been additive (a shadow added to an existing decoration, a dialog's shell swapped for a styled equivalent with identical `actions`/return values). Functional behavior is unchanged everywhere it's been applied.
- **No isolated mockup screens** — every change lands on a real, already-shipped screen.
