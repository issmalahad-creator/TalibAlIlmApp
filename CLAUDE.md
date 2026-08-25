# CLAUDE.md — TalibAlIlmApp (طالب العلم)

Single reference for this project. Read this before touching any code — same discipline as the sibling `DawahReportApp` and `Ethiopian_HMIS` projects.

## What this app is becoming

This started as a near-clone of `DawahReportApp` (same architecture, forked early). As of 2026-08-15 it is being rebuilt into a Quran memorization/understanding/application companion — full product spec, database schema, algorithms, and phased build order live in **[`QURAN_COMPANION_ROADMAP.md`](QURAN_COMPANION_ROADMAP.md)**. Read that file in full before writing any feature code. Don't re-derive the plan from scratch or from memory — the roadmap is long and was built deliberately (including real web research for every scholar/text named in it); trust it over improvisation.

## Where the project stands (updated 2026-08-25)

`TODO.md` is the authoritative live tracker — phase by phase, with commit hashes and verification notes. This section is only a compass, not a duplicate of it.

**Substantially done**: the core Quran companion — memorization/review engine (Ebbinghaus 6-station), daily session, understanding/application pillars, journey plan, level map, worship/prayer coach, companion chat, app-wide translation coverage, and Phase 71's real Mushaf page rendering (own-engine layout for all 604 pages, now being progressively replaced page-by-page with real Madinah-Mushaf art — 120/604 done as of this date, waiting on the rest from Ismail) plus Phase 72's ayah-centered tafsir study mode (source cards, reader, compare — cross-source search still open).

**Planned, not started yet, in this order** (see `TODO.md` for full numbered sub-steps of each): Phase 73 — deterministic Dawah/debate coach (no live AI, pre-authored objection trees + real cited answers + fuzzy-match scoring). Phase 74 — "مساجدنا" multi-tenant mosque platform (Telegram bot admin + backend API + database — a real architecture shift from this app's current offline-only design, needs an explicit infra decision before it starts). Phase 75 — ongoing research-grounded quality bar, not a one-time task.

**Not yet scoped into TODO.md phases at all**: the roadmap's "مكتبة النصوص الإسلامية" pillar (`QURAN_COMPANION_ROADMAP.md` §4.9) — 40 Nawawi Hadiths + Ibn Uthaymeen's explanation, Aqeedah Wasitiyyah, Zad al-Ma'ad excerpts, Madarij al-Salikin, full Fiqh/purification + prayer method, Hisn al-Muslim adhkar, Qaida Noorania, Asma-ul-Husna. This is most of the app's eventual scope and hasn't been started.

## The one rule that prevents scatter

**Work exactly one phase at a time, in the order listed in `TODO.md`.** Do not start Phase N+1 work while Phase N is incomplete or unverified, even if it looks quick. The roadmap covers an enormous final scope (Quran + Hadith + Aqeedah + Fiqh + more) — the only way this actually ships is strict sequencing, not parallel partial progress on five things at once. `TODO.md` in this folder is the live checklist; update it the moment a phase step finishes, before starting the next one.

## Git discipline

Baseline commit `a10664d` ("Baseline before Quran Companion rebuild") is the pre-rebuild reference point — the app in its original DawahReportApp-clone form. This project had **zero commits** before that baseline; there is no earlier history to fall back on. After finishing any phase step: verify the app still builds and `flutter analyze` is clean, then commit with a message naming the phase (e.g. "Phase -1: remove Report feature"). If something breaks, `git diff a10664d` (or the last known-good phase commit) is the fastest way to see what changed.

`lib/config/app_config.dart` is gitignored — currently holds only placeholder values (`REPLACE_WITH_NEW_BOT_TOKEN_FROM_BOTFATHER`), meaning Telegram/Sheets content sync was never actually configured live for this app. Don't assume it's wired up the way DawahReportApp's is.

## Running / building

Same toolchain and known machine setup as `DawahReportApp` (see that project's `CLAUDE.md` if a build issue looks unfamiliar — many were already solved there):

```bash
export PATH="/c/src/flutter/bin:$PATH"
export ANDROID_HOME="C:\Users\ismail\AppData\Local\Android\Sdk"
export ANDROID_SDK_ROOT="C:\Users\ismail\AppData\Local\Android\Sdk"
cd /f/TalibAlIlmApp
flutter pub get
flutter analyze
flutter build apk --debug --split-per-abi
```

This project already has the cross-drive Kotlin/Gradle fixes DawahReportApp needed (`compileSdk = 36` in `android/app/build.gradle.kts`, `kotlin.incremental=false` in `android/gradle.properties`, `file_picker: ^10.0.0`) — confirmed present as of 2026-08-15, don't reintroduce the old broken versions.

## Architecture

Original DawahReportApp-clone structure (`lib/models`, `repositories`, `services`, `screens`, `db/database_helper.dart` sqflite) — being extended, not replaced, per the roadmap. See the roadmap's own architecture/schema sections rather than duplicating them here; this file stays a pointer + discipline doc, not a second copy of the plan.
