---
name: lightweight-feature-rules
description: >-
  Load before adding ANY new feature, screen, dataset, asset, background job,
  permission prompt, or startup work to TalibAlIlmApp — and before touching
  main.dart, the splash, BootScheduler, or anything that runs at launch.
  The mandatory "lightweight by architecture, not by removing features" rules
  Ismail asked for (2026-09-27): the 10-question gate every feature must pass,
  where work is allowed to run, how data ships (bundled vs. content pack),
  and how to prove it on his real phone. Distilled from real measurements
  (Home 31 s → ~1 s; lite APK 459 → 308 MB), not generic advice.
---

# Lightweight feature rules — «طالب العلم لا يحمل التطبيق؛ يبنيه عند الحاجة»

Big features are welcome. What is forbidden is a feature that makes the app
slower to open, heavier to install, or noisier in the background **without
anyone deciding that on purpose**. This skill turns that into a checklist.

Deeper references (read when the task touches them):
`docs/architecture/ZERO_WAIT_PROGRESSIVE_ARCHITECTURE.md` (startup),
`docs/architecture/INTERACTION_FEEDBACK_ARCHITECTURE.md` (what users see while
waiting), `docs/APP_PERFORMANCE_AND_SIZE_ROADMAP.md` §8.4–8.5 (size), skill
`app-performance-optimization` (executing the size roadmap).

## 1. The gate — answer all 10 in your plan before writing code

Write the answers into the plan/PR, one line each. A "yes" to 1 or a missing
answer to 7–8 means redesign first.

1. **Does it need to run at startup?** Default answer: no.
2. **Can it be lazy?** Built on first open of its screen, not before.
3. **How much data, and where does it live?** (see §3) — bundled, content
   pack, or network-on-demand. Put the number (MB) in the plan.
4. **RAM:** what stays in memory while its screen is open, and what is
   released when it closes (HOT current item / WARM neighbours / COLD disk).
5. **CPU:** any parse/decode/compute > ~50 ms or > ~1 MB of text? → `compute`.
6. **Database:** new tables go through the `database-migrations` skill; queries
   project only needed columns and `LIMIT` lists; no `SELECT *` of big tables.
7. **When is it loaded?** (screen open / `BootScheduler` task / user action)
8. **When is it released?** (dispose, cache cap, eviction rule)
9. **Does it touch Home?** Home's first paint may only read small user tables.
10. **Does it ask the user for anything** (permission, download, sign-in)?
    Only from a screen the user opened, with a sentence explaining why.

## 2. Where work is allowed to run

| Kind of work | Allowed place | Never |
|---|---|---|
| Seeding/importing bundled data, syncs, catalog loads | `BootScheduler.instance.register(id, fn, priority: …)` in `main.dart` | `await` or fire-and-forget in `main()` / `initState` of the app |
| Anything a screen needs before it can show data | `await BootScheduler.instance.ensure(BootTasks.x)` at that screen/repository entry (idempotent, jumps the queue) | assuming the seed already ran |
| Notification scheduling, anything that may prompt | register with `afterHome: true` | running during onboarding |
| gzip/JSON/text parsing of assets > ~1 MB | `compute(topLevelFn, bytes)` (see `_parseTafsirJsonl`, `_decodeGzJson`) | the UI isolate (it froze Home for minutes) |
| Location | `LocationService().currentLocation(mayAskPermission: false)` from background/cards | calling the prompting variant outside a user-opened screen |
| Network | only from a user action or a registered low-priority task, always with offline fallback | blocking any first paint |

Home must call nothing heavy: its `_load()` reads a handful of small user
tables, then calls `BootScheduler.instance.markHomeReady()`. Keep it that way.

## 3. Where data ships

| Size / nature | Ships as |
|---|---|
| Tiny (< ~200 KB), needed offline on day one | bundled asset |
| Core Quran/app identity (mushaf, Quran text) | bundled in both flavors |
| Heavy, optional, or per-language (tafsir, translations, books, voices, big indexes) | **content pack** on a GitHub Release, downloaded on first use via the `QuranCorpusDownloadService` pattern (manifest, size shown, consent dialog, cache, honest "not downloaded" state) — full flavor may bundle it |
| Book PDFs / copyrighted scans | **never** in the public repo or Releases; extract small data (structure, short quotes, page refs) instead |
| Dead (no consumer in `lib/`) | delete (after `grep` for the path *and* dynamic path builders; tag a restore point) |

A new feature asks "is my pack present?", never "am I the lite flavor?".

## 4. Startup & splash invariants (do not regress)

- `main()` before `runApp`: only tiny prefs + `holdFirstFrameUntilBrandMarkReady()`.
- `BrandSplashGate` overlays the real first screen; it never waits on work
  itself. The first screen must call `markHomeReady()` / `markOnboardingShown()`.
- Anything drawn above the app's Scaffold needs a `Material` ancestor
  (otherwise release builds draw yellow underlines under text).
- Splash timers start from `brandFirstFrameReleased`, not from widget creation.
- Native launch window: ivory + the mark in `launch_background.xml`, ivory
  bars with `windowDrawsSystemBarBackgrounds` — Android 11 has no system splash.
- Back on the root screen moves the task to background (`popSystemNavigator`).

## 5. Waiting the user can see

Follow `INTERACTION_FEEDBACK_ARCHITECTURE.md`: press feedback at 0 ms, nothing
extra under 300 ms, in-place indicator ≥ 300 ms, contextual text ≥ 800 ms
("جاري فتح الكتاب…", never "Loading"), skeletons when the layout is known,
real progress only (no fake percentages), every new string via `basicText()`
in 13 languages (skill `app-translations`).

## 6. Prove it — numbers, on the real phone

- Build: `python tool/build_apk.py --flavor lite --abi arm64-v8a` → the only
  file to hand over is `dist/talib-lite-release-arm64-v8a.apk` (quote its sha
  from the `.sha256`). Old builds live in `dist/old/` — Ismail once tested an
  old APK and saw "no changes".
- Size: compare `dist/talib-lite-release-size.md` before/after; put the delta
  in the commit message.
- Startup: logcat line `BootScheduler: home ready at N ms` (emulator). On
  Ismail's phone (Realme RMX3263, Android 11, 720×1600, adb id
  `1C16294310DA114Y`) Flutter logs are hidden → `adb shell screenrecord`,
  pull, `ffmpeg -vf fps=8` and inspect frames.
- Install on the phone yourself with `adb -s 1C16294310DA114Y install -r …`
  when it is connected, then verify the actual screen.
- Tests: the feature's own tests + `flutter analyze`; widget tests use Timers
  (fake clock), never Stopwatch/DateTime for UI timing.

## 7. Red flags — stop and redesign

- A new `await` or un-registered call added to `_TalibAlIlmAppState.initState`.
- A loop over thousands of JSON lines with no `await compute`.
- A permission dialog that can appear without the user tapping something related.
- An asset folder added to `pubspec.yaml` without its MB in the plan.
- "It's only a few MB" repeated three times in one feature.
- A spinner in the middle of an empty screen.
