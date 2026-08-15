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

## Phase 0 — Quran + tafsir data foundation (roadmap §2, §4.9 pending)

- [ ] Source Tanzil Uthmani Quran text, confirm license terms
- [ ] Source/prepare the three tafsir mukhtasars (Al-Misbah Al-Munir, Sabuni, Ahmad Shakir's Umdat — note incomplete)
- [ ] Build `quran_ayat`, `tafsir_entries` (with `asbab_nuzul_excerpt`), `text_normalized` column + index
- [ ] DB migration to version 2 (additive only)
- [ ] Commit: "Phase 0: Quran + tafsir data foundation"

## Phase 1 — Ayah search + memorization engine

- [ ] "Search an ayah" screen (number/text search, tashkeel-insensitive)
- [ ] `memorization_units` (604 pages, auto-generated) + `memorization_progress`
- [ ] "القرآن" browse tab
- [ ] Commit

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
- [ ] Commit

## Phase 5 — Extended Islamic text library (roadmap §4.9, sub-phases 5أ–5د)

- [ ] 5أ: Al-Arba'in Al-Nawawiyyah + Ibn Uthaymeen's commentary
- [ ] 5ب: Al-Aqidah Al-Wasitiyyah + Ibn Uthaymeen's commentary
- [ ] 5ج: Zad al-Ma'ad selected chapters + Ibn Uthaymeen's commentary (mark which chapters only)
- [ ] 5د: Fiqh al-Taharah (Ash-Sharh Al-Mumti') + Salah method (Al-Shuwaie'r) + visual aid SVGs
- [ ] `cross_references` linking ayah↔hadith↔aqeedah with mandatory real-life example
- [ ] Sharh Ibn Kathir audio layer (Al-'Ajlan) — pending transcript-vs-audio-link decision
