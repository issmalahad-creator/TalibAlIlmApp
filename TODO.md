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

## Phase 3 — Understanding + Application pillars — ✅ DONE 2026-08-15 (commits 9222fbe, 40daf95, d6a8fe8)

- [x] Tafsir/benefits display per unit, `understanding_progress` — separate from memorization, uses the real Al-Mukhtasar tafsir already imported
- [x] `practical_lessons` + `application_log` ("مطبّق" pillar, roadmap §4.8) — 8 hand-curated lessons for short/juz-amma surahs (الفاتحة، الإخلاص، الفلق، الناس، العصر، الكوثر، الماعون، النصر), grows surah by surah later
- [x] Wired into جلسة اليوم — all 6 of 6 steps now real (اختبر نفسك added same day, generated from quran_ayat, no external bank needed — commit 26cc08d)
- [x] Commit

## Phase 4 — Journey plan — ✅ FULLY DONE 2026-08-15 (commit b68ff25)

- [x] SMART-wizard goal setup + "trial first week" pacing — `JourneyPlanRepository`, target years + level -> computed daily pace, first 7 days at half pace
- [x] Optional non-monetary "personal commitment" reminder — `journey_plan.personal_commitment_text`, purely self-displayed, app never acts on it
- [x] "رحلتي" dashboard — "أنت اليوم في اليوم X" + mastery % + current pace
- [x] `achievement_milestones` (roadmap §4.14) — confetti/celebration scaling with milestone size (surah/10-hadiths < juz/full-Arba'in < full Quran — page-level tier intentionally dropped, no page-level certificate exists), shareable certificate image via existing `share_plus` dependency, triggered from `memorization_progress` reaching station 6 across a whole unit
- [x] "شهاداتي" gallery screen — shows EVERY possible certificate (Quran + hadith; adhkar rows will slot in once 5هـ ships, pillar-agnostic design already supports it), locked/greyed for not-yet-earned with "complete X to unlock" text (tap shows the unlock hint), full-color + share button once earned
- [x] Commit

## Phase 4.15 — خطة الختم: generalized completion planner (roadmap §4.15) — ✅ FULLY DONE 2026-08-15 (commits 2d0ae59, 91632cd, 2cdec51, c4ad0df)

- [x] Design: one `completion_goals` table (content_type/book_ref discriminator) instead of per-content duplicate schemas; position always read live from the real progress table, never cached — commit 2d0ae59
- [x] Quran reading khatm: `quran_reading_progress` + قراءة القرآن screen, auto-saves position on screen close (`didChangeAppLifecycleState`/`dispose`, screen-scoped `WidgetsBindingObserver`) — commit 91632cd
- [x] `CompletionGoalRepository`: create/activeGoals/abandon/reschedule/statusFor with remaining/daysLeft/recalculated daily pace/ahead-onTrack-behind (15% tolerance band, non-punitive framing) — commit 2cdec51
- [x] Extended to Zad al-Ma'ad, Madarij, Wasitiyyah, Nawawi hadith, AND any personal-library PDF from "مكتبتي" (page count read live from existing `book_bookmarks`, no new input needed from the student) — commit c4ad0df
- [x] "خطط ختمي" screen: create/view/reschedule plans, wired into ProfileScreen — commit c4ad0df
- [x] Per-goal daily reminder notifications ("لم تكمل نصيبك اليوم") carrying a per-unit KPI (e.g. "15 صفحة اليوم"), auto-generalizes to any future book added to the fixed options or personal library, cancels itself the moment `hasProgressedToday()` is true — commit c4ad0df
- [x] `book_bookmarks.last_updated_date` (DB v13→v14) so personal-library PDFs can answer "touched today" like every other content type — commit c4ad0df

## Phase 4.16 — Optional Hijri/Gregorian display toggle (Ismail's request 2026-08-15) — ✅ DONE 2026-08-15 (commit 35471a3)

- [x] `CalendarPreferenceService` (shared_preferences-backed, display-only — every table stays Hijri-keyed storage regardless) + `formatDateForDisplay()` + toggle in ProfileScreen
- [x] Applied to CompletionGoalsScreen's target-date button and CertificateCard's date line — the two spots a raw Hijri string was actually shown to the student before this
- [ ] NOT retrofitted yet: any other screen that happens to display a raw date string to the user (most current screens only use dates as storage/grouping keys, not visible text, so there was nothing to fix there at audit time — but recheck when adding new date-visible UI)

## Phase 4.17 — ورد اليوم daily wird templates (Ismail's request 2026-08-15) — ✅ DONE 2026-08-15 (commit 877a1b6)

- [x] 5 fixed templates (data/wird_templates.dart): generic "الورد المقترح" + 4 scholar-flavored (Ibn Kathir, Ibn Uthaymeen, Ibn al-Qayyim, Ibn Taymiyyah) — each explicitly labeled as app-assembled content, NOT a wird attributed to that scholar himself. Al-'Ajlan requested too but has no sourced content in-app yet, so no track was built for him.
- [x] Every checklist item reuses an existing *_progress table's "touched today" signal (`WirdRepository`) — no duplicated state
- [x] New istighfar tally (istighfar_log, DB v16→v17, 100/day target, tap-to-increment)
- [x] WirdScreen: template picker + daily checklist, wired into ProfileScreen

## Phase 5 — Extended Islamic text library (roadmap §4.9, sub-phases 5أ–5د)

- [x] 5أ: Al-Arba'in Al-Nawawiyyah — ✅ DONE 2026-08-15 (commit e3940cb). Real text+commentary (osamayy/40-hadith-nawawi-db, verified), browse+mark-memorized, generalized quiz ("أكمل الحديث"). NOTE: commentary source ended up being the bundled dataset's own scholarly commentary, not confirmed as specifically Ibn Uthaymeen's — should verify/relabel later if that distinction matters. `achievement_milestones` rows not added yet (Phase 4 not started).
- [x] 5ب: Al-Aqidah Al-Wasitiyyah — ✅ DONE 2026-08-15 (commit c5f4f37). Original Ibn Taymiyyah text only (82 sections, verified verbatim via ar.wikisource.org raw wikitext), browse+mark-memorized, "ما المقطع التالي؟" quiz. Ibn Uthaymeen's commentary layer NOT sourced yet — original roadmap plan, still open.
- [x] 5ج: Zad al-Ma'ad Volume 1 (Seerah intro) — ✅ DONE 2026-08-15 (commit 2786c88). 65 chapters, verified verbatim via ar.wikisource.org. No quiz (reading/study material, not memorized verbatim). Remaining 4 volumes + Ibn Uthaymeen's specific commentary text still open, added incrementally.
- [x] 5ح: Madarij As-Salikin Part 1 — ✅ DONE 2026-08-15 (commit abcb44d). 71 sections, verified verbatim via ar.wikisource.org. Advanced-tier warning banner in the screen itself (no technical level-lock exists yet). No quiz (deep reading/reflection material). Remaining 2 parts still open, added incrementally.
- [x] 5د: "دليل المسلم الجديد" — ✅ DONE 2026-08-15 (commit 3364c2c). Step-by-step Wudu/Ghusl/Istinja/Salah guides, each in Arabic/English/Amharic (per-screen toggle, not full app i18n), one in-house CustomPainter line-art diagram per topic (no bundled/licensed image asset — sidesteps licensing entirely, same caution as Nabulsi). Amharic explicitly flagged (doc comment + in-UI notice) as AI-translated, NOT native-reviewed. NOTE: original fiqh-text plan (Ash-Sharh Al-Mumti' / Al-Shuwaie'r full text) NOT imported — ships as app-authored simplified steps instead, grounded in but not a translation of either book. Full per-step illustrated diagrams (vs. one per topic) still open, upgradable later.
- [x] 5هـ: Hisn al-Muslim daily adhkar — ✅ DONE 2026-08-15 (commits ee222be, 53727c6). Whole book (134 chapters/298 duas, source rn0x/hisn_almuslim_json, verified verbatim), tap-to-count-down UI, ~17 daily-core chapters pinned to top, fixed-time morning/evening notifications (honestly NOT true prayer-time-based yet — no prayer-time engine exists), 🔥 streak tracking, `achievement_milestones` 7/30/100-day streak certs. NOTE: streak is for the ONE merged "أذكار الصباح والمساء" chapter, not separate morning/evening certs as originally planned — the source book doesn't split them. "عمل اليوم والليلة" (Ibn al-Sunni/An-Nasa'i) citation NOT added to the UI yet — still open if wanted.
- [ ] 5و: Noorani Qaida for children — letters → harakat → madd → tanween → sukoon → words, `child_profiles` (multiple kids per device), display text ALWAYS fully vocalized (no tashkeel-stripped display, unlike the adult search feature), mandatory audio pronunciation per letter/word — audio source licensing/recording unresolved, must confirm before building
- [ ] 5ز: Names of Allah (Al-Nabulsi) — 99-names data + Quran cross-refs OK now; official-link-only for lessons; actual bundled audio/text download requires written permission from nabulsi.com's "الهدى للخدمات التقنية" first — do NOT bundle without it
- [ ] `cross_references` linking ayah↔hadith↔aqeedah with mandatory real-life example
- [ ] Sharh Ibn Kathir audio layer (Al-'Ajlan) — pending transcript-vs-audio-link decision

## Phase 4.18 — باب الأدب: character/manners pillar (Ismail's request 2026-08-15) — ✅ DONE 2026-08-15 (commit 9942a59)

- [x] Two curated lesson sets (character/manners, closeness to the Quran), data/adab_lessons_seed.dart, wired into ProfileScreen
- [ ] IMPORTANT sourcing note: Ismail asked for content translated from specific named books (Al-Adab Al-Mufrad by Al-Bukhari; a book on the virtue of Quran recitation, likely An-Nawawi's At-Tibyan). Neither had a source meeting this app's established bar (direct-from-Wikisource, matching Wasitiyyah/Zad al-Ma'ad/Madarij) — only a third-party GitHub scrape (no license file) and shamela.ws page-by-page browsing were found. Shipped instead as hand-written original lessons inspired by these themes, NOT verbatim translations of either book — same pattern as the §4.8 practical_lessons content. If Ismail specifically wants the two named books' actual text later, that still needs a cleaner source (or manual shamela.ws transcription) before it can be imported at this app's usual verification standard.

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

## Phase 9 — Qibla direction + prayer-times engine (Ismail's request 2026-08-15) — ✅ DONE 2026-08-15 (commit 4826f53)

Architecture Ismail specified and Claude agreed to (2026-08-15): `Location Service → Astronomical Calculation Engine → Prayer Jurisprudence Configuration → Validation Engine → Prayer Schedule → Notifications`, fully offline after an initial GPS fix. Used `adhan_dart` (MIT-licensed, published/audited astronomical formulas) as the verified calculation core, not hand-derived formulas.

- [x] Location service (GPS via `geolocator` + cached-last-fix + manual-entry fallback) — `lib/services/location_service.dart`
- [x] Prayer Calculation Engine wrapping `adhan_dart` — 13 calculation methods + madhab (Asr timing) configurable and persisted — `lib/repositories/prayer_times_repository.dart`
- [x] Independent Validation Engine — `test/prayer_times_validation_test.dart`, 201 assertions: chronological ordering across 8 real cities × 5 dates × 4 methods, Dhuhr cross-checked against solar noon computed independently via equation-of-time (not the library's own math). Genuinely caught a wrong assumption mid-development (Dhuhr isn't bit-identical across methods — some apply a small conventional offset) and the test was corrected, not the library.
- [x] Qibla compass — bearing via `adhan_dart`'s verified great-circle formula, heading via `flutter_compass` (magnetometer+accelerometer fusion), confidence indicator derived from the sensor's own reported accuracy (never claims precision it doesn't have), calibration prompt at low confidence
- [ ] Home screen integration: ships as standalone quick-access buttons (HomeScreen + ProfileScreen) for now — the FULL combined "رفيقك اليوم" card (prayer+Qibla+Quran+adhkar status together, Ismail's sketch) is NOT built yet, still open
- [ ] High-latitude rule (for far-north/south locations where twilight angles behave unusually) NOT exposed as a setting yet — `adhan_dart` supports it, just not wired into the UI

## Phase 10 — Multi-language basics + Arabic-learning curriculum for non-native speakers (Ismail's request 2026-08-15) — ✅ DONE 2026-08-15 (commits db5f927, bcfc1de)

Ismail's explicit scoping, in his own words: "ترجم ما استطعت الأساسيات، أما المتعمق عليه أن يتعلم العربية" (translate the basics as much as possible; for deep content, they should learn Arabic) — then asked for a full integrated Arabic-learning curriculum for non-Arabic speakers living inside this same app ("يتوفر كل شيء داخل مكان واحد"), explicitly so users can grow from translated-basics into reading the deep Arabic content themselves.

- [x] **Basics translation** (commit db5f927): `LanguagePreferenceService` + 16 navigation/hub labels translated into 13 languages (ar/en/am/fr/sw/ur/tr/id/bn/ha/so/fa/ms), applied to HomeScreen + ProfileScreen's main navigation, with a language picker. NOT a full app-wide i18n system — the other ~40 screens stay Arabic-only, which is correct per Ismail's own philosophy (deep content = learn Arabic), not a gap. AI-translation honesty flagging same as the new-Muslim guide's Amharic.
- [x] **Arabic-learning curriculum for non-natives** (commits bcfc1de, 8c0f8bd): 5-stage curriculum defined (alphabet → basic reading → vocabulary → grammar → Quranic-Arabic comprehension). Per Ismail's explicit follow-up request, researched real methodology before building further: Madinah Arabic Course (Dr. V. Abdur Rahim) and Al-'Arabiyyah Bayna Yadayk informed the stage sequencing; real Quranic-corpus word-frequency research (~100 words ≈ 50% of the Quran's text, ~500 words ≈ 85%) grounds Stage 3's vocabulary-by-frequency-tier approach instead of generic conversational topics. Stages 1-3 (alphabet, reading mechanics, 59 frequency-tiered words) are actually built; a "مصادر موصى بها" screen cites the two real courses above (title/author/description only, no bundled textbook content) for learners wanting a fuller course. Stages 4-5 (grammar, direct Quranic-text application) still show honestly as "قريبًا" — not written yet. Stage-1-completion certificate wired into `achievement_milestones`/شهاداتي. Distinct from 5و (Qaida, still for children) — this is the adult non-native track.

## Phase 11 — Tajweed curriculum, 3 tiers (Ismail's request 2026-08-15) — NOT scoped/started yet

Basic/intermediate/advanced Tajweed (Quran recitation rules) tracks, each with a real reference book (needs sourcing — same rigor as every other classical text: verified public-domain/licensed source, not a third-party scrape) and its own progress tracking. Ismail explicitly asked that certificates/motivation/streaks (the §4.14 `achievement_milestones` pattern already used for Quran/hadith/adhkar) be applied consistently here too, and as a general reminder for every future pillar — don't add a new content pillar without also wiring its completion into the certificate system.
