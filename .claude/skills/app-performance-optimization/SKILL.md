---
name: app-performance-optimization
description: >-
  Load before changing TalibAlIlmApp's APK size, startup time, memory usage,
  asset packaging, mushaf page loading, Quran corpus downloads, TTS packaging,
  database performance, or release build configuration. Enforces baseline-first,
  one-stage-at-a-time execution, real-device verification, and rollback safety.
---

# App Performance and Size Optimization

For the rules every *new feature* must follow (the 10-question gate, BootScheduler,
content packs, phone verification) load `lightweight-feature-rules` first.

The full plan is `docs/APP_PERFORMANCE_AND_SIZE_ROADMAP.md`. Read it before
editing performance, assets, startup, or build configuration.

This is the first execution track. The Ismail voice-training/in-app voice track
does not start until `SIZE-8` in `TODO.md` is verified on a real phone. After
that handoff, use `tts-audio-pipeline` and begin at `VOICE-0`; do not mix both
tracks in one change.

## Current known baseline

At the first audit on 2026-09-20:

- full debug APK: about 919 MB
- lite release APK: about 481 MB
- `assets/quran`: about 484 MB
- `assets/mushaf`: about 84.7 MB
- `assets/tts`: about 61.4 MB

These are size facts only. Do not claim a runtime improvement until startup,
mushaf, search, and memory are measured before and after.

## Mandatory workflow

1. Confirm the requested phase in the roadmap.
2. Inspect `git status` and create a restore point before the first edit.
3. Measure the current behavior relevant to that phase.
4. Make the smallest change that tests one hypothesis.
5. Run focused tests and `flutter analyze`.
6. Build the correct flavor explicitly (`full` or `lite`) and mode explicitly.
7. Verify on a real Android device when the change affects startup, memory,
   downloads, TTS, mushaf rendering, or lifecycle.
8. Record old/new numbers and update the roadmap only after verification.
9. Stop and report when the phase succeeds; do not silently start the next phase.

## Safety rules

- Never delete Quran, tafsir, translation, mushaf, or TTS assets before checking
  their source, license, consumers, and offline requirement.
- Never infer Quran identity from visual geometry; preserve the canonical
  `(surah, ayah, wordIndex)` spine.
- Never turn a local feature into a network-only feature without an explicit
  loading state, retry path, cache policy, and offline failure message.
- Do not enable SQLite WAL casually; it previously caused a real-device Home
  hang in this project. Load `database-migrations` before schema/PRAGMA work.
- Do not change database schema as a side effect of an asset optimization.
- Do not judge final size from debug APKs. Use release and, when distributing,
  ABI-split builds.
- Do not add an index, isolate, cache, or dependency removal without measuring
  the problem it is meant to solve.
- Do not bundle API keys or secrets into any public APK.

## Flavor rules

- `full`: everything currently bundled unless the roadmap changes that decision.
- `lite`: currently strips `assets/quran/corpus/translations` and
  `assets/quran/corpus/tafsir` through `tool/build_lite_apk.sh`; do not build
  lite directly with Flutter and assume the corpus was stripped.
- `assets/tts` is currently bundled in both flavors by project decision. Any
  change requires an explicit offline TTS test and user-facing download state.
- Every Flutter build must specify `--flavor full` or `--flavor lite`.

## Required report after each phase

Report briefly:

- phase and hypothesis
- files changed
- old/new APK sizes
- old/new timings or memory if relevant
- tests/analyze/build commands and actual result
- phone test steps
- known residual risk

If a focused check fails, repair only that phase and rerun the same check before
expanding scope. If the failure changes the hypothesis, take one nearby read,
then stop or revise the phase plan explicitly.
