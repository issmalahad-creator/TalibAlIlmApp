---
name: quran-memory-engine
description: >-
  Load before building, changing, or reviewing ANY hifz/review/memorization
  feature in TalibAlIlmApp — the sabaq/sabqi/manzil engine, VerseMemory,
  the adaptive spacing scheduler, journey/timeline plan presets (6/10/19/24/27
  months), error classification + repair cards, the 8 retrieval tests, or any
  memorization-related screen (Memory Lab, خريطتي, guided session, journey
  wizard). It carries the design decisions, the research grounding, the
  mistakes-to-avoid, and the constraints so this work starts from settled
  ground instead of re-derivation or silent re-invention.
---

# Quran Memory Engine Skill

This skill points at the permanent design base in **`docs/memorization/`**
(plus `docs/quran/HIFZ_TIMELINE_ENGINE.md`, its narrower sibling doc) and
gives the operational rules to follow. Read the relevant file before writing
code; update the base when a design decision changes or a mistake is found.

**Relationship to `quran-engineering` skill**: that skill owns mushaf
rendering/layout/tajweed/text identity — **never duplicate or bypass it**.
This skill owns *what to memorize, when to review it, how to test it, and
how the screens for that behave*. Anything touching `lib/widgets/mushaf*`,
`lib/services/mushaf/`, or `lib/theme/tajweed_palette.dart` is read-only from
here — load `quran-engineering` instead for changes there.

## Knowledge base map

| file | use it for |
|---|---|
| `docs/memorization/00-MEMORY-SYSTEM-MASTER.md` | the whole architecture: golden principle, 7 memory layers, `VerseMemory` state machine, the 9-step encoding protocol, verse-graph test directions, hybrid memory architecture, ordering modes, post-khatm perpetual maintenance, the honest science-vs-hype table (§15), mandatory architectural constraints (§17) |
| `docs/quran/HIFZ_TIMELINE_ENGINE.md` | the narrower, lower-risk extension of the *existing* Phase 28/56 hifz-coaching work (sabaq/sabqi/manzil labelling, mastery-gate advisory, pace ceilings, ordering) + the 5 timeline presets' page/day math |
| `docs/memorization/03-SPACING-ENGINE.md` | the adaptive scheduler formula (`R(t)=e^-t/S`, `S_new=S×F`) + a fully worked day-0→day-60 walkthrough incl. one failure/repair cycle — use this as the reference test-case table before touching scheduler code |
| `docs/memorization/06-QURAN-MEMORIZATION-MODEL.md` | the actual `verse_memory` SQL schema, the 604-page reference (read from `mushafs-1.json.gz`, never recomputed), the surah-boundary-aware sabaq-sizing algorithm, and the 5-stage migration plan |
| `docs/memorization/09-ERROR-REPAIR-ENGINE.md` | the 10-type error taxonomy, repair-card logic per type, and the 8 retrieval tests (6 mirrored from a reviewed competitor app + 2 new: Boundary, Random Entry) |
| `docs/memorization/11-SCREENS-UX-PLAN.md` | 40 planned screen/UI points, grouped by theme — planning only, none implemented yet; check here before inventing a new screen pattern that already has a planned spec |
| `docs/memorization/12-RESEARCH-BACKED-ADDENDUM.md` | 50 points from real web research (FSRS/Anki/SuperMemo, habit-formation/implementation-intentions, gamification's dark side + anxiety research, desirable difficulties/generation effect) — read before adding any gamification, streak, or difficulty-related feature |
| `docs/memorization/TODO.md` | the phased implementation checklist for this initiative specifically (does not replace the root `TODO.md`) — read before picking the next grain to build |
| `docs/memorization/13-VIDEO-FINDINGS-AND-50-ADDITIONS.md` | verified test-mechanics details from a real reviewed-app screen recording (per-test surah picker, full/partial + hard-mode toggles, live best-score/wrong-count/quality-bar feedback, numbered multi-blank fill-in) + 50 concrete additions to the test engine — read before implementing Grain 5 (the 8 retrieval tests) in `TODO.md` |
| `docs/memorization/14-TARTEEL-REVIEW-FINDINGS.md` | verified feature findings from a Tarteel-app review video (progressive word/ayah hiding with numbered placeholders, a persistent errors button) — take the display pattern, **reject the paywall/subscription model** (this app has no payment system), and **do not** treat this as reopening paused Phase 8 (cloud voice-follow stays paused) |

## Knowledge classification — tag anything you add (same scheme as `quran-engineering`)

`VERIFIED` (checked against real data or ≥2 authoritative sources) ·
`SOURCE-BACKED` (one authoritative source, e.g. one of the WebSearch results
in `12-RESEARCH-BACKED-ADDENDUM.md`) · `PROJECT-SPECIFIC` (true for this
codebase, not a general fact) · `INFERENCE` (synthesis, not directly sourced)
· `UNKNOWN` (an open gap — say so, never fabricate to fill it).

**Never** use `INFERENCE` to justify a claim about Quran-memorization-specific
neuroscience (§15 of the master doc already documents the real null result:
hifz does not confer general "supercharged" memory). General learning-science
findings (spacing, retrieval practice, desirable difficulties) are
`SOURCE-BACKED`; anything Quran-specific beyond the one ERP study already
cited stays `UNKNOWN` until a real source is found.

## Pre-flight checklist — before touching anything scheduling-related

1. **لا تُمس القرآن إطلاقًا.** Any new column/engine (`verse_memory`,
   `manzil_bucket`, the new scheduler) is additive, behind a `feature_flag`,
   defaulting to **off**. Never mutate `next_review_date` or any live
   scheduling value for real memorized-progress data without a tested,
   reversible migration (see the 5-stage plan in `06-QURAN-MEMORIZATION-MODEL.md`
   §4). This is the single most important rule in this skill.
2. **The operational unit stays the page** (604 units, per the original
   pivot decision). `verse_memory` is an *additive fine-grained layer under*
   the page, never a replacement of it. Page status is always a roll-up
   query over its ayat's states — never a separately maintained duplicate.
3. **Every gate is advisory, never a hard lock** — mastery gates, pace
   warnings, repair-card suggestions: all recommend, none block the student
   from acting anyway. This matches the app's standing "companion not
   manager" principle everywhere else.
4. **No fabricated content.** The mutashabihat (similar-verses) engine
   (§9 of the master doc, §8.4 of `09-ERROR-REPAIR-ENGINE.md`) has **no
   verified data source yet** — do not build it with invented verse pairs.
   Leave it as a documented gap until a real source is found and verified,
   same discipline this project already applies everywhere (tafsir
   substitutions, wird attribution, Arabic curriculum sourcing — see
   `QURAN_COMPANION_ROADMAP.md`'s recurring pattern).
5. **Cite, don't invent, science.** Any claim about memory/learning science
   must trace to `00-MEMORY-SYSTEM-MASTER.md` §15 or
   `12-RESEARCH-BACKED-ADDENDUM.md` — never assert a neuroscience "fact" that
   isn't already tagged there with its real source.
6. **Reuse existing data, don't re-derive.** Page/juz/hizb/rub' boundaries →
   `mushafs-1.json.gz`. Surah metadata → `surahs.json.gz`. Tafsir for the
   "quick meaning" layer → `tafsir_entries` (already bundled, 3+ editions).
   Never hardcode a new boundary number that already exists in these assets.
7. **Gamification needs a matching recovery mechanism.** Per
   `12-RESEARCH-BACKED-ADDENDUM.md` §c: any new challenge/difficulty/streak
   feature ships together with an explicit recovery/rest/non-punitive
   re-plan mechanism in the *same* grain — never as a separate later add-on.
8. **One grain at a time, `flutter analyze` + `flutter test` clean after
   each** — same discipline as every other phase in this project's history.
   Follow the grain order in `docs/memorization/TODO.md`, don't skip ahead
   to a later, riskier grain for a quick visual win.

## When you finish work in this area

- If a design decision changed from what's documented → update the relevant
  `docs/memorization/*.md` file directly (don't leave the base stale).
- If you found a real mistake or a wrong assumption → note it inline where
  it was made (this base doesn't yet have a dedicated ERRATA file the way
  `quran-engineering` does; add one — `docs/memorization/ERRATA.md` — the
  first time this happens rather than losing the lesson).
- If a check/decision couldn't be completed → record it as `UNKNOWN` in the
  relevant file, same as `quran-engineering`'s convention — don't leave it
  only in conversation.

## Current open questions

- Mutashabihat data source — no verified structured dataset found yet
  (§9 of the master doc, §8 of the research addendum touches related
  interleaving research but not a Quran-specific similar-verse dataset).
- Whether to adopt FSRS-style parameterization instead of the four fixed
  `F` constants in `03-SPACING-ENGINE.md` — flagged as a future upgrade
  (`12-RESEARCH-BACKED-ADDENDUM.md` §a), not decided, needs ≥30 days of
  real usage data first (§7 of the master doc) before it's even evaluable.
- Whether `docs/memorization/TODO.md`'s grains get their own lines added to
  the root `TODO.md` when implementation actually starts, or stay tracked
  separately — not decided; ask Ismail before assuming either way.
