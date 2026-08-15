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

## Phase 0 — Quran + tafsir data foundation — ✅ FULLY DONE 2026-08-15 (commits d7a3fb5, ccd4f5c)

- [x] Source Tanzil Uthmani Quran text (6236 ayat, verified against real Mushaf facts), confirm license terms (CC-BY 3.0)
- [x] Source Tanzil's Juz/Page boundary metadata (quran-data.js) — unblocks memorization_units generation
- [x] Build `quran_ayat` (with `text_normalized` + index), `tafsir_entries` (with `asbab_nuzul_excerpt`) — DB migration v1→v2, additive
- [x] One-time import service wired into app startup (`quran_import_service.dart`)
- [x] Tafsir: imported the FULL unabridged Ibn Kathir (6236/6236 ayat, zero errors), gzip-compressed 89.7MB->9.6MB, wired into search results. The three specific mukhtasars (Al-Misbah Al-Munir, Sabuni, Ahmad Shakir's Umdat) remain unsourced — no comparable structured source found; add as additional `tafsir_entries.source` rows later if/when found
- [x] Commit

## Phase 1 — Ayah search + memorization engine — ✅ DONE 2026-08-15 (commits 8cc3da5, 5b8f271, 5aa0ff5)

- [x] "Search an ayah" screen — full-word/phrase search across the whole Quran (tashkeel-insensitive) + direct "surah number" reference lookup, both return surah name + ayah text
- [x] `memorization_units` (604 pages, auto-generated from the now-available page boundaries) + `memorization_progress`
- [x] "القرآن" browse screen (not yet a bottom-nav tab — reachable from Home, matching this app's existing pattern; nav restructure to 5 tabs is Phase 7 territory) — grouped by Juz, mark-memorized action
- [x] Commit
- [ ] Known follow-up, not a blocker: bundle a proper Uthmani-script font (e.g. Amiri, SIL license) — ayah text currently renders in the system font

## Phase 2 — Review engine + daily session — ✅ DONE 2026-08-15 (commits 9107fa6, 022ad19, 5e3e833)

- [x] 6-station Ebbinghaus review algorithm (roadmap §4) — `memorization_repository.dart`
- [x] "المراجعة" screen (reachable from Home) — due-today queue, rate ممتاز/جيد/يحتاج مراجعة
- [x] Non-punitive catch-up/return logic — dueToday() caps overdue backlog (default 5 extra), never dumps it all at once
- [x] "جلسة اليوم" shell — قراءة/حفظ جديد/مراجعة real and auto-tracked, فهم/تطبيق/اختبار honestly shown as "قريبًا" (blocked on Phase 3 data, not faked)
- [x] Personal accountability (roadmap §4.7 expansion, Ismail's explicit request): self-chosen reward + optional self-chosen punishment, app only ever reminds, never enforces — `personal_accountability_screen.dart`, reward reminder wired into review completion
- [x] Commit

## Phase 3 — Understanding + Application pillars

- [ ] Tafsir/benefits display per unit, `understanding_progress`
- [ ] `practical_lessons` + `application_log` ("مطبّق" pillar, roadmap §4.8) — start with short/juz-amma surahs only
- [ ] Commit

## Phase 4 — Journey plan

- [ ] SMART-wizard goal setup + "trial first week" pacing
- [ ] Optional non-monetary "personal commitment" reminder
- [ ] "رحلتي" dashboard
- [ ] `achievement_milestones` (roadmap §4.14) — confetti/celebration scaling with milestone size (page < surah < juz < full Quran), shareable certificate image via existing `share_plus` dependency, triggered from `memorization_progress` reaching station 6 across a whole unit
- [ ] "شهاداتي" gallery screen — shows EVERY possible certificate (Quran ones first, since Phase 4 ships before 5أ/5هـ), locked/greyed for not-yet-earned with "complete X to unlock" text, full-color + share button once earned. Design this to be pillar-agnostic from the start so hadith/adhkar rows slot in later without a rebuild.
- [ ] Commit

## Phase 5 — Extended Islamic text library (roadmap §4.9, sub-phases 5أ–5د)

- [ ] 5أ: Al-Arba'in Al-Nawawiyyah + Ibn Uthaymeen's commentary (+ add its `achievement_milestones` rows: full-completion certificate + one every 10 hadiths, per §4.14)
- [ ] 5ب: Al-Aqidah Al-Wasitiyyah + Ibn Uthaymeen's commentary
- [ ] 5ج: Zad al-Ma'ad selected chapters + Ibn Uthaymeen's commentary (mark which chapters only) — study-order breakdown designed in roadmap section 5ج (7 topic units, level-tagged), evaluate "مختصر زاد المعاد" (Dr. Ahmad, alukah.net PDF) as a simpler entry point
- [ ] 5ح: Madarij As-Salikin (Ibn al-Qayyim) — advanced tier ONLY, no confirmed mukhtasar found yet, source for madarij_sections.text_excerpt still unresolved
- [ ] 5د: Fiqh al-Taharah (Ash-Sharh Al-Mumti') + Salah method (Al-Shuwaie'r) + visual aid SVGs
- [ ] 5هـ: Hisn al-Muslim daily adhkar — tap-to-count-down UI, smart after-Fajr/after-Asr reminders, streak, home-screen quick-access button (not buried in a tab); reference "عمل اليوم والليلة" (Ibn al-Sunni/An-Nasa'i) as the classical root source (+ add its `achievement_milestones` rows: 7/30/100-day streak certificates per §4.14, for morning and evening adhkar separately)
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

## Phase 8 — AI recitation listener (roadmap §4.13) — ⏸ POSTPONED 2026-08-15 by Ismail, no work until explicitly revisited

- [ ] BLOCKING DECISION from Ismail before any code: accept a cloud dependency (Gemini Live API) and its real per-use cost, given every other feature in this app is local/offline-first?
- [ ] If yes: explicit opt-in consent screen before first use (audio leaves the device)
- [ ] `recitation_sessions` table, integrate `flutter_quran_tajwid` or equivalent
- [ ] Research actual Gemini Live API pricing before committing — not done yet
