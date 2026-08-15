# TODO.md — live phase tracker

Last updated: 2026-08-15. **Work top to bottom, one unchecked item at a time.** Don't skip ahead — see `CLAUDE.md`'s "one rule that prevents scatter". Full detail for every item lives in `QURAN_COMPANION_ROADMAP.md`; this file only tracks status.

## Prerequisites

- [x] Verify dev environment (Flutter/Android SDK/git all present, F:-drive Kotlin fix already in place)
- [x] Git baseline commit (`a10664d`)
- [x] `CLAUDE.md` + this `TODO.md` created

## Phase –1 — Delete the Report feature (roadmap §4.5) — ✅ DONE 2026-08-15 (commit d1de6ab)

- [x] Delete `lib/screens/report_screen.dart`
- [x] Delete `lib/services/report_builder.dart`, `lib/services/sync_service.dart`, `lib/services/sheets_service.dart`
- [x] Delete `lib/models/report_draft.dart`, `lib/repositories/report_draft_repository.dart`, `lib/repositories/submission_repository.dart`
- [x] Remove `report_drafts`/`submission_queue` tables from `lib/db/database_helper.dart`
- [x] Remove tab 4 (`ReportScreen`) + bottom nav item from `lib/screens/main_shell.dart` (app is now 4 tabs; Phase 1+ will bring it back to 5 with the new Quran-first tabs)
- [x] Remove `onSubmitReportTap` + "إرسال التقرير الشهري" card from `lib/screens/home_screen.dart`
- [x] Remove `SyncService`/`retryPending()` call from `lib/main.dart`'s connectivity listener (book-content polling kept)
- [x] Report-deadline reminder in `lib/services/notification_service.dart`: removed the scheduling call, cancels any already-scheduled one on old installs, id 1001 reserved + documented for Phase 2's real daily-session reminder
- [x] Confirmed `TelegramService` untouched/still used by `support_screen.dart`
- [x] `flutter pub get` clean, `flutter analyze` clean (2 pre-existing unrelated deprecation infos in quiz_screen.dart)
- [x] Committed

## Phase 0 — Quran + tafsir data foundation — ✅ Quran text DONE 2026-08-15 (commit d7a3fb5)

- [x] Source Tanzil Uthmani Quran text (6236 ayat, verified against real Mushaf facts), confirm license terms (CC-BY 3.0)
- [x] Source Tanzil's Juz/Page boundary metadata (quran-data.js) — unblocks memorization_units generation
- [x] Build `quran_ayat` (with `text_normalized` + index), `tafsir_entries` (with `asbab_nuzul_excerpt`) — DB migration v1→v2, additive
- [x] One-time import service wired into app startup (`quran_import_service.dart`)
- [ ] Source/prepare the three tafsir mukhtasars (Al-Misbah Al-Munir, Sabuni, Ahmad Shakir's Umdat — note incomplete) — NOT done yet, bigger sourcing task than the Quran text itself
- [x] Commit

## Phase 1 — Ayah search + memorization engine

- [x] "Search an ayah" screen — full-word/phrase search across the whole Quran (tashkeel-insensitive) + direct "surah number" reference lookup, both return surah name + ayah text (commit 8cc3da5)
- [ ] `memorization_units` (604 pages, auto-generated from the now-available page boundaries) + `memorization_progress`
- [ ] "القرآن" browse tab
- [ ] Commit
- [ ] Known follow-up, not a blocker: bundle a proper Uthmani-script font (e.g. Amiri, SIL license) — ayah text currently renders in the system font

## Phase 2 — Review engine + daily session

- [ ] 6-station Ebbinghaus review algorithm (roadmap §4)
- [ ] "المراجعة" tab, "اليوم" session flow (6 steps incl. "طبّق")
- [ ] Non-punitive catch-up/return logic
- [ ] Commit

## Phase 3 — Understanding + Application pillars

- [ ] Tafsir/benefits display per unit, `understanding_progress`
- [ ] `practical_lessons` + `application_log` ("مطبّق" pillar, roadmap §4.8) — start with short/juz-amma surahs only
- [ ] Commit

## Phase 4 — Journey plan

- [ ] SMART-wizard goal setup + "trial first week" pacing
- [ ] Optional non-monetary "personal commitment" reminder
- [ ] "رحلتي" dashboard
- [ ] `achievement_milestones` (roadmap §4.14) — confetti/celebration scaling with milestone size (page < surah < juz < full Quran), shareable certificate image via existing `share_plus` dependency, triggered from `memorization_progress` reaching station 6 across a whole unit
- [ ] Commit

## Phase 5 — Extended Islamic text library (roadmap §4.9, sub-phases 5أ–5د)

- [ ] 5أ: Al-Arba'in Al-Nawawiyyah + Ibn Uthaymeen's commentary
- [ ] 5ب: Al-Aqidah Al-Wasitiyyah + Ibn Uthaymeen's commentary
- [ ] 5ج: Zad al-Ma'ad selected chapters + Ibn Uthaymeen's commentary (mark which chapters only)
- [ ] 5د: Fiqh al-Taharah (Ash-Sharh Al-Mumti') + Salah method (Al-Shuwaie'r) + visual aid SVGs
- [ ] 5هـ: Hisn al-Muslim daily adhkar — tap-to-count-down UI, smart after-Fajr/after-Asr reminders, streak, home-screen quick-access button (not buried in a tab); reference "عمل اليوم والليلة" (Ibn al-Sunni/An-Nasa'i) as the classical root source
- [ ] 5و: Noorani Qaida for children — letters → harakat → madd → tanween → sukoon → words, `child_profiles` (multiple kids per device), display text ALWAYS fully vocalized (no tashkeel-stripped display, unlike the adult search feature), mandatory audio pronunciation per letter/word — audio source licensing/recording unresolved, must confirm before building
- [ ] 5ز: Names of Allah (Al-Nabulsi) — 99-names data + Quran cross-refs OK now; official-link-only for lessons; actual bundled audio/text download requires written permission from nabulsi.com's "الهدى للخدمات التقنية" first — do NOT bundle without it
- [ ] `cross_references` linking ayah↔hadith↔aqeedah with mandatory real-life example
- [ ] Sharh Ibn Kathir audio layer (Al-'Ajlan) — pending transcript-vs-audio-link decision

## Phase 6 — Additional languages (roadmap §4.10)

- [ ] i18n infrastructure for UI strings (Arabic/English/Amharic via ARB files) — only after the Arabic content core is stable
- [ ] `translation_am`/`translation_en` columns on `quran_ayat` sourced from Tanzil (Amharic: Sadiq/Habib; English: Saheeh International or similar)
- [ ] Explicitly NOT promised: full translation of tafsir/hadith-commentary/fiqh content — no ready-made trusted source exists

## Phase 7 — Level map: "zero to scholar" (roadmap §4.11)

- [ ] `curriculum_levels` (1=beginner, 2=intermediate, 3=advanced), `curriculum_items`, `user_level_progress`
- [ ] Recommendation-only, never a hard lock — matches the "companion not manager" principle
- [ ] Fill `curriculum_items` incrementally as each content pillar ships (start with 5و/Qaida → level 1 as soon as it exists), don't wait for everything
- [ ] Expand "رحلتي" (Phase 4) into this level-map screen rather than building a second separate screen

## Phase 8 — AI recitation listener (roadmap §4.13) — hardest phase, needs a separate go/no-go decision first

- [ ] BLOCKING DECISION from Ismail before any code: accept a cloud dependency (Gemini Live API) and its real per-use cost, given every other feature in this app is local/offline-first?
- [ ] If yes: explicit opt-in consent screen before first use (audio leaves the device)
- [ ] `recitation_sessions` table, integrate `flutter_quran_tajwid` or equivalent
- [ ] Research actual Gemini Live API pricing before committing — not done yet
