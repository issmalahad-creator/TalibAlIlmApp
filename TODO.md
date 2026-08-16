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
- [x] Uthmani-script font — ✅ DONE 2026-08-16 (commit c264640). Amiri Quran + Amiri Regular/Bold bundled (SIL OFL 1.1, official alif-type/amiri project via Google Fonts' mirror), applied to the 3 screens that render ayah text directly (search, review, reading).

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

## Phase 14 — Adaptive memorization pace engine (Ismail's request 2026-08-16) — ✅ Sub-phases A + B DONE (commits 4d1d7b5, f1ce946)

Ismail strongly criticized the memorization system as "رص صفحات لا اتقان" (page-stacking, not mastery) and pasted a detailed external design brief demanding a real adaptive "personal coach." Explicitly required a full project analysis before any code — see `C:\Users\ismail\.claude\plans\quirky-gliding-shell.md` for the saved plan. Honest correction delivered to Ismail as part of the plan: the 6-station Ebbinghaus review engine (`memorization_repository.dart`) already IS real mastery tracking, not page-stacking — but several genuine gaps existed and are catalogued below.

- [x] **Real architectural discovery**: `CompletionGoalRepository` (§4.15, خطة الختم) already had exactly the "live ahead/on-track/behind + reschedule" engine the brief asked for, and already supported `content_type: 'quran_memorization'` — it was simply never wired to any UI. `رحلتي` used a separate, simpler, frozen-pace system (`journey_plan`) instead. No new adaptive-planning logic was built from scratch — `JourneyPlanRepository` was rebuilt to ride entirely on the existing engine.
- [x] `MemorizationRepository.nextRecommendedUnit()` — "تكليف اليوم": the first never-started page in Mushaf order, deterministic (same style as `dueToday()`), closing the literal root of the "page-stacking" complaint (previously the student had to browse the whole Mushaf and pick a page manually with zero guidance).
- [x] `رحلتي` dashboard: live متقدم/بالموعد/متأخر badge, "تكليف اليوم" card with a direct "ابدأ الحفظ" deep link into `QuranBrowseScreen` (new optional `highlightUnitId` param), and a non-judgmental "أعِد التخطيط" choice screen when behind (extend at current pace / intensify to the original date) — reuses `CompletionGoalRepository.reschedule()` directly, no new re-planning math written.
- [x] Found-and-fixed in passing: `CompletionGoal.unitLabel` for `quran_memorization` said "آية" (ayah) but the actual counting is per-page — never surfaced before since this code path was dead until now.
- [x] Deliberately simplified vs. the old design: dropped the old "trial week at half pace" softening — the live-recalculation engine doesn't false-flag "behind" on day 1 anyway (daysLeft ≈ totalDays on a fresh plan), so the extra mechanism wasn't needed.
- [x] **Sub-phase B DONE (commit f1ce946)**: `session_time_budget.dart` splits a chosen session length across 5 phases (مراجعة سريعة/حفظ جديد/تكرار/تسميع/فهم) by explicit, documented level-based ratios (labeled honestly as a design heuristic, not a scientific standard). `GuidedSessionScreen` walks through the phases in order, each opening the real existing screen for it (no duplicated logic), ending in a self-rated difficulty (سهلة/مناسبة/صعبة) + optional note, stored as 3 new columns on `daily_session_log` (DB v22→v23, no new table). `رحلتي` shows a non-forced advisory card when 3 consecutive sessions were all hard or all easy, linking directly into the existing "أعِد التخطيط" dialog from Sub-phase A — never a silent automatic pace change. Entry point: a "جلسة موجّهة بالوقت" button atop the existing free-order "جلسة اليوم" checklist, which stays available for whoever prefers it.
- [ ] Structured تسميع (recitation-test) UX improvement (progressive text-hiding before self-rating) — still deferred, lower priority, still just a blind self-rate today.
- [ ] **Not yet tested on-device**: neither Sub-phase A (plan creation → behind/ahead/on-track over real days) nor Sub-phase B (the guided session flow end-to-end) has been exercised on a real phone yet — `flutter analyze` is clean and the arithmetic was reviewed carefully, but this needs Ismail's manual confirmation.

## Phase 15 — Colorful icon-grid navigation redesign (Ismail's request 2026-08-16) — ✅ DONE (commit 9e56cc5)

Ismail sent a reference screenshot from another app (a grid of solid-color circular icons with white glyphs, 4 per row, label below each) and asked for the same treatment. Purely visual — no logic, data, or navigation destinations changed.

- [x] `widgets/nav_tile.dart` — reusable `NavTile`/`NavGrid` + a shared `NavColors` 12-color palette so the same feature always gets the same color everywhere it appears (e.g. إقامة الصلاة is teal on both the home quick-access row and the profile grid).
- [x] `profile_screen.dart` — all ~19 vertical `OutlinedButton.icon` entries replaced by one `NavGrid`, same destinations/i18n labels (`basicText`) unchanged.
- [x] `home_screen.dart` — same treatment for the 5-item quick-access row (مواقيت الصلاة/القبلة/الأذكار/إقامة الصلاة/كتب صوتية). The larger data-driven cards (الحفظ، المراجعة، رفيقك اليوم، progress ring) were deliberately left alone — they're not simple nav shortcuts and don't fit the icon-tile pattern.
- [ ] **Not visually verified yet** — a fresh debug APK was built and sent to Ismail after this change so he can actually look at it; this is a pure UI change that benefits more than most from an on-device look rather than just `flutter analyze` passing.

## Phase 16 — Two correctness bugs from Ismail's on-device testing (2026-08-16) — ✅ DONE

- [x] **Prayer times displayed in UTC, not local time** (commit 8783aa7) — `adhan_dart` builds every prayer time internally as a UTC `DateTime` (`DateTime.utc(...)`, confirmed by reading the package source directly); 3 separate `_formatTime` implementations (`prayer_times_screen.dart` ×2, `daily_companion_card.dart`) read `.hour`/`.minute` straight off the UTC value with no `.toLocal()`. Fixed all 3. The prayer-selection logic itself (`currentPrayer`/`nextPrayer`) was never affected — Dart `DateTime` comparisons are correct regardless of UTC/local flag, only the *display* was wrong. Re-ran the full 201-assertion `prayer_times_validation_test.dart` suite after the fix — still 100% passing, confirming the underlying astronomical calculation was never the problem.
- [x] **Quran search missed words containing madd marks** (commit 1852857) — e.g. searching "الفقراء" returned nothing despite the word existing. Root-caused by directly inspecting every non-base-letter character actually present in the bundled Tanzil Uthmani text (not guessed): the word is spelled with a combining MADDA ABOVE (U+0653) before the hamza, and `arabic_normalize.dart`'s search-stripping regex only covered basic tashkeel (U+064B-0652), missing U+0653-0655 (madda/hamza-above/hamza-below) and the entire Quranic small-mark/waqf-annotation block (U+06D6-06ED) — both used thousands of times across the real text. Fixed the regex, **plus** a DB v23→v24 data migration recomputing `quran_ayat.text_normalized` for all 6236 ayat, since that column is computed once at import time (not live per search) — existing installs (including Ismail's phone) had the stale under-stripped values baked in and needed the recompute, not just the regex fix.
- [ ] Not yet re-tested on-device by Ismail after either fix.

## Phase 17 — Visual redesign push: hero card + Quran reading UI (Ismail's request 2026-08-16) — ✅ DONE (commit 62164c9)

Ismail sent screenshots of a reference app and asked explicitly for a much richer visual language ("ليس صفحة بيضاء وكتابات سود" — not a white page with black text), including the exact "طريقة عرض المصحف" options-menu structure and a tap-an-ayah contextual popup. Explicit boundary stated to Ismail: match the *style* with original design work, not literally clone the reference app's specific artwork/branding.

- [x] `daily_companion_card.dart` — gradient hero card, a live-ticking (1s) countdown to the next prayer, and an original CustomPainter dome-and-minarets silhouette (simple geometric shapes, not traced from any reference app).
- [x] `quran_reading_screen.dart` — full "طريقة عرض المصحف" options sheet matching the reference's structure: الفهرس (surah index, tap to jump), البحث, حدّد ما حفظته, التفسير (real, working), المعاني/الصوتيات/الترجمة (visibly present but honestly disabled — tapping explains no trustworthy data source exists yet, not invented), الوضع الليلي (dark reading mode), لون مصحفك (5 color themes affecting the page border), المفضلة (bookmarks list).
- [x] Tap-an-ayah contextual popup menu (opens at the exact tap position, matching the reference): التفسير (shows that ayah's tafsir in a sheet), الترجمة/الاستماع (disabled, same honesty), أضف للمفضلة (real — new `quran_favorites` table, DB v24→v25), نشر (real — shares the ayah text via `share_plus`, already a dependency).
- [ ] **Not yet visually verified by Ismail** — a fresh APK was built and sent specifically for this, since a design-quality change can't be confirmed by `flutter analyze` passing.
- [ ] Home screen icon grid (Phase 15) and other screens beyond home-hero/Quran-reading were NOT touched in this pass — if Ismail wants the same visual treatment (gradients, decorative framing) applied elsewhere, that's an explicit follow-up, not assumed.

## Phase 18 — محاسبة الوقت: time-accountability reminder (Ismail's request 2026-08-16) — ✅ DONE (commit 619f85c)

Ismail asked for a real (not invented) reminder feature: hours in a year, how to benefit from each one, hours "wasted" that day, and that every hour is accounted for on the Day of Judgment.

- [x] Grounded in the actual hadith (Sunan al-Tirmidhi #2417 — "لا تزول قدما عبد يوم القيامة حتى يُسأل عن عمره فيما أفناه..."), cited by its known standard wording with real attribution (At-Tirmidhi's own "حسن صحيح" grading, Al-Albani's "صحيح" in Sahih al-Jami) — not paraphrased or invented.
- [x] Year-hours stat uses the Hijri year (354×24 = 8496 hours), consistent with the app being Hijri-dated throughout, not Gregorian.
- [x] Daily reflection ("كم ساعة استفدت منها اليوم؟") is purely self-reported via a slider — same non-inferring, non-punitive self-rating pattern as khushu ratings and guided-session difficulty elsewhere; the app never claims to measure how anyone's time was actually spent.
- [x] 5 original practical tips for using time well, matching the `practical_lessons_seed.dart` house style (grounded, not a translation of any single book).
- [ ] Not yet tested on-device.

## Phase 19 — Two blank-screen bugs + Mushaf page header + رحلتي visibility (Ismail's report 2026-08-16) — ✅ DONE (commit 72cde00)

Ismail reported two screens rendering completely blank (app bar title showing, body empty): "القرآن" (browse/mark-memorized) and "جلسة موجّهة" after tapping "ابدأ الجلسة". He also said "رحلتي"/the memorization coach was hard to find, and asked for the reading page's header to show the surah name on top with جزء/page number below, matching real Mushaf page conventions.

- [x] **Found and fixed the likely root cause for the guided-session blank screen**: `_buildPhase()` used a `Spacer()` inside a `Column` set directly as the Scaffold body (no `ListView`/scrollable wrapper) — a known-fragile pattern that can fail under unbounded/degenerate layout constraints. Rewrote it as a `ListView`, which structurally cannot hit that failure mode. Audited every other `Spacer()` usage in the app (`grep`) — all others are safely inside a bounded `Row`, so this was an isolated instance, not systemic.
- [x] **Could not reproduce the القرآن-browse blank screen directly** — added real error-visibility instead of silence: `QuranBrowseScreen` now wraps its load in try/catch and shows a visible error message + retry button, or an empty-state message + retry, instead of rendering nothing. If it recurs, the next screenshot will show the actual cause.
- [x] Fixed a secondary risk in the same area: the "حدّد ما حفظته" flow did `Navigator.pop()` then immediately `Navigator.push()` in the same synchronous callback — deferred the push via `addPostFrameCallback` to avoid same-frame navigation timing issues.
- [x] Quran reading page header redesigned: surah name on top, "الجزء X · الصفحة Y" below, replacing the plain "صفحة N" title — matches real printed Mushaf page header convention. `QuranAyahText`/`ayatForPage` extended with `juzNumber`.
- [x] رحلتي surfaced more visibly inside the القرآن screen: a persistent tappable banner above the reading content, plus a "رحلتي ومدرب الحفظ" entry in the "طريقة عرض المصحف" sheet (previously only reachable via the profile grid).
- [ ] **Not yet re-tested on-device** — fresh APK built and sent for this batch specifically since blank-screen bugs need real confirmation they're actually gone, not just that analyze passes.

## Phase 20 — Second, deeper Quran search fix: dagger alef U+0670 (Ismail's report 2026-08-16) — ✅ DONE (commit d76f2e8)

The Phase-17-era search fix (commit 1852857) closed the "الفقراء" bug but not the whole problem — Ismail sent a follow-up screenshot showing "الظالمين" still returned no results. See `QURAN_COMPANION_ROADMAP.md` §4.26 for the full technical writeup (three distinct roles the dagger alef plays in the Uthmani rasm, verified against all ~2650 word forms containing it, not guessed).

- [x] `lib/utils/arabic_normalize.dart` rewritten with the 4-case handling (waw+dagger, alif-maqsura+dagger, closed exception list, omitted-letter default)
- [x] DB migration v26→v27 (`_fixQuranNormalizedTextV27`) recomputes `quran_ayat.text_normalized` for existing installs, same pattern as v24
- [x] New regression test `test/arabic_normalize_dagger_alif_test.dart` — 11 cases across all 4 categories, all passing against the real Dart implementation (not just a Python simulation)
- [x] `flutter analyze` clean, `flutter test` clean (the one pre-existing `widget_test.dart` failure is an unrelated `sqflite`/test-harness limitation, confirmed by isolating it — not caused by this change)
- [ ] Not yet re-tested on-device by Ismail with a fresh APK — next APK build should include this.

## Phase 21 — "مسح الخطة" plan-delete action (Ismail's request 2026-08-16) — ✅ DONE (commit 31090bb)

`CompletionGoalRepository.abandon()` already existed but had no UI path to it. Added a confirm dialog + delete button on each خطط ختمي goal card; marks the goal abandoned (not deleted, so past progress on the underlying content is untouched) and cancels its daily reminder notification.

## Phase 22 — محاسبة الوقت v2: home-screen dashboard + structured time-entry + benefit calculator (Ismail's request 2026-08-16)

Ismail asked to move محاسبة الوقت onto the home screen with year/month/week/day cards each showing a countdown, and to replace the single self-rated slider with independent time-entry fields (slept/wasted/studied/worked) that the app computes benefit-vs-loss FROM — sleep within a reasonable cap counts as neither benefit nor loss, sleep beyond it counts as loss, and any unlogged/unaccounted hours also count as loss ("الباقي ضائع", his explicit closing instruction), plus a daily reminder notification to log the day.

- [x] DB migration v27→v28: 4 new nullable columns on `time_awareness_log` (`hours_slept`/`hours_wasted`/`hours_studied`/`hours_worked`), additive — `hours_well_spent` kept and now written as a derived value so the pre-existing recent-days trend view needed no changes
- [x] `DailyTimeEntry` (repository) — the actual benefit/waste arithmetic, with an 8-hour sleep cap documented as a heuristic (adjustable), and unaccounted-hours-default-to-wasted per Ismail's explicit instruction. Unit-tested (`test/daily_time_entry_test.dart`, 4 cases).
- [x] `TimeAwarenessScreen` rebuilt: 4 numeric entry fields instead of a slider, live-computed benefit/waste breakdown shown as you type, gratitude message on save (his "تشكره كل يوم" ask)
- [x] `TimeAccountabilityDashboard` widget — 4 compact home-screen cards (اليوم/الأسبوع/الشهر/السنة), each with a countdown (hours-left-today, days-left-this-week/month/year) and that period's summed benefit/waste totals, tappable into the full screen
- [x] Wired into `home_screen.dart`, right after the daily-companion card
- [x] `NotificationService.scheduleTimeLogReminder()` — fixed daily evening reminder (9pm), same always-recurring pattern as the adhkar reminders (generalized `_scheduleDailyAt` to take channel params instead of hardcoding adhkar's), new id range 9000 (clear of every existing range, and of the still-unbuilt prayer-notification range planned at 8000+)
- [x] `flutter analyze` clean, `flutter test` clean (206 passing, same one pre-existing unrelated `widget_test.dart` failure)
- [ ] Not yet tested on-device.

## Phase 23 — Audio player: broken YouTube-fallback link + دفتر الفوائد edit/delete/resume-point (Ismail's report 2026-08-16) — ✅ DONE (commit 0fe0a29)

Ismail reported (with screenshots showing a "This video is unavailable — Error code: 152" embed failure) that "افتح هذه الحلقة في يوتيوب" did nothing when tapped, and asked for the ability to edit/delete دفتر الفوائد notes plus a manual "where did I stop" field as a fallback for when the embedded player breaks.

- [x] Root cause found: `_currentVideoId` was only ever set reactively from the player's metadata stream, which never fires when a video fails to embed — so the fallback link (and the reflections filter) had no video id on exactly the broken videos. Now set synchronously whenever a video is cued (`_setCurrentVideo`), independent of embed success.
- [x] `AudioLibraryRepository.updateReflection()`/`deleteReflection()` — UI edit (dialog) and delete (confirm) icons added to each note
- [x] Optional `resume_note` free-text field (DB v28→v29, additive column) saved alongside each reflection — a manual position record (link or "دقيقة 15") that survives a broken embed, shown on the note card
- [x] `flutter analyze`/`flutter test` clean
- [ ] Not yet tested on-device.
- [ ] **Not built this round, flagged as a much larger follow-up**: Ismail shared his own personal tracking spreadsheet (`life_project.xlsx`, 19 sheets — Quran memorization, tafsir listening, Wasitiyyah, Zad al-Ma'ad, daily wird, Arba'in, takbir, congregation prayer, tasbih/istighfar, plus secular sheets: sleep, exercise, programming, work/freelance, social media, monthly review) as the target level of detail: per-entry link/status/start-end datetime/rich benefit notes/weekly-report field/hours-total, applied uniformly across every content pillar. This is a genuinely large structural expansion (a generalized daily-log-with-weekly-report pattern reused across every existing pillar, not just audio) — architecturally fits the local-SQLite model fine, no blocker, but is a multi-session undertaking on its own, not a quick add-on. Needs explicit prioritization from Ismail before starting, same as the "prayer OS" scoping in §4.25.

## Phase 24 — خريطتي التعليمية redesign: real game-style path map (Ismail's request 2026-08-16) — ✅ DONE (commit 5388fcb)

Ismail called the Phase-7 plain vertical list "بدائية وليس فيها تعب ولا تكنلوجيا ولا ابداع حقيقي" (primitive, no real effort/tech/creativity) and asked for a real skill-tree/path map (Duolingo-style) with animation and KPIs, called it one of the most important pages after Quran/tafsir, and explicitly asked for it on its own prominent home-screen entry point.

- [x] `CurriculumItemStatus` extended with a real `progressFraction` (0.0-1.0, computed from the same done/total counts already used for `detailAr`, not string-parsed) for progress-ring rendering
- [x] `CurriculumMapScreen` rebuilt: a winding snake-lane path (3 lanes, cycling left/center/right/center) connecting nodes via smooth cubic-bezier curves drawn with a `CustomPainter` — solid colored segments for passed/completed steps, dashed grey for not-yet-reached
- [x] Real progress rings on in-progress nodes (an actual `CircularProgressIndicator` reflecting `progressFraction`, not decorative), filled+glowing nodes for completed items, a pulsing glow animation + "أنت هنا" badge on the one real "next actionable step" (first non-completed, non-comingSoon item in level+item order — derived live, not a separate tracked field)
- [x] KPI header card: overall completion percent + "$completed من $total محطة مكتملة", gradient-styled matching the app's established hero-card visual language
- [x] Added as its own `NavGrid` tile on the home screen (`NavColors.gold`, `Icons.map_rounded`) — still also reachable from رحلتي as before
- [x] `flutter analyze` clean; debug APK built and sent for visual verification (design-quality changes can't be confirmed by analyze alone)
- [ ] Not yet visually confirmed by Ismail on-device.

## Phase 25 — Professional certificate redesign + photo + Almosaly competitive analysis (Ismail's request 2026-08-16) — ✅ DONE (commit 9ea3dae)

Ismail sent a certificate-design reference screenshot asking for the same professional level with photo support (explicit color freedom given: "تقدر تعمل لون الشهادة الذي تحبه انت"), and separately asked to browse almosaly.com (the "المصلي" competitor app) to find real feature gaps without copying design/code. A third, much larger ask in the same message — a rule-based "Personal Worship Coach Engine" spanning Salah/Quran/Dhikr — was explicitly paused by Ismail when asked two scoping questions via `AskUserQuestion` ("do not proceed, wait for next instruction"); **not built, research preserved in session memory** (`project_talibalilm_pivot.md`) for a future explicit resume, not re-derived from scratch.

- [x] `certificate_card.dart` rebuilt: gradient green/gold background (app's own identity colors, not the reference's navy/gold), original `CustomPainter` medallion badge (star + ribbon tails) and corner flourishes, banner title, signature/date footer row matching the reference's layout without tracing its artwork
- [x] Certificate photo: DB v29→v30 (`profile.photo_path`), chosen once via `file_picker` (existing dependency, no new `image_picker`) on the profile screen, copied into the app's persistent documents directory, reused automatically by every certificate via `showCelebration()`
- [x] `WebFetch` of almosaly.com succeeded (full feature list gathered); Google Play listing failed twice (JS-rendered, un-fetchable) — noted honestly rather than guessing at its content
- [x] Honest gap analysis documented in `QURAN_COMPANION_ROADMAP.md` §4.28: most of Almosaly's features are already matched/exceeded here; one genuine locally-buildable gap found (multi-method Qibla-finding — sun/moon/shadow/map, not just compass), documented but not built this round; live-streaming/reviews/trending require a real backend (same §4.25 scope boundary)
- [x] `flutter analyze`/`flutter test` clean (206 passing, same pre-existing unrelated `widget_test.dart` failure)
- [ ] Not yet tested on-device (photo picker + certificate render).

## Phase 26 — Qibla rebuilt into a 4-method tabbed screen (Ismail's request 2026-08-16) — ✅ DONE (commit 752fbde)

After the §4.28 gap analysis flagged multi-method Qibla as the one real, locally-buildable gap vs. Almosaly, Ismail sent screenshots of that app's actual compass/map/AR/sun-moon tabs and asked directly whether the same could be built here, better and with original assets.

- [x] Compass tab: rebuilt with a real `CustomPainter` dial (5° tick marks, 8 cardinal/intercardinal labels), bearing/degrees-from-north stat cards, and a hand-drawn Kaaba glyph — same underlying verified `adhan_dart` bearing calculation as before, purely a visual upgrade
- [x] Map tab ("المرئية"): new `qibla_map_view.dart` using `flutter_map` + OpenStreetMap tiles (free, no API key — Google Maps would need Ismail's own billing account), straight-line distance to the Kaaba
- [x] AR tab ("الواقع المعزز"): new `qibla_ar_view.dart` — live camera background with a heading-based Kaaba overlay (centers when facing Qibla, slides toward the edge otherwise); deliberately not true ARCore plane-anchoring (no `ar_flutter_plugin`/ARCore dependency added) — same practical orientation aid, much lighter/more reliable
- [x] Sun/moon tab: left as an honest "قريبًا" rather than shipping an unverified solar-position calculation
- [x] Kaaba coordinates (21.4225241, 39.8261818) verified against `adhan_dart`'s own `Qibla.makkah` constant directly from its package source, not guessed separately
- [x] New deps: `flutter_map`, `latlong2`, `camera` (+ `CAMERA` permission) — `flutter analyze` clean, full debug APK build succeeded (native Gradle integration verified, not just Dart analysis), `flutter test` clean (206 passing, same pre-existing unrelated failure)
- [ ] Not yet tested on-device, especially the AR camera mode and permission flow.

## Phase 27 — Personal Worship Coach Engine, Phase A (Ismail's request 2026-08-16, resumed after a pause) — ✅ DONE (commit 9616555)

Ismail's spec, explicitly no AI/LLM: observe consistency across Salah/Quran/Dhikr, focus on ONE weak area via a plain IF/ELSE waterfall, recommend ONE small task, never a full checklist. Two scoping questions asked via `AskUserQuestion` were dismissed ("do not proceed, wait for next instruction"); Ismail later said "ابدا" (start) without answering them directly, so both were resolved by engineering judgment rather than guessed re-asking: (1) added as a new home-screen card alongside جلسة اليوم rather than replacing it — a bigger UX change to an already-daily-used screen deserves explicit sign-off, not an assumption from a dismissed question; (2) scoped to Salah+Quran+Dhikr only, since those are the only three domains with any real tracking data — "أعمال إضافية" (qiyam al-layl/witr/sadaqah/voluntary fasting/dua) confirmed to have zero existing tracking anywhere in the codebase, and building 5 new habit tables in the same pass as the whole rule engine would itself be starting with everything at once, which Ismail's own spec explicitly said not to do.

- [x] `WorshipCoachRepository` — rolling 7-day consistency % per domain computed entirely from existing tables (`salah_log` via `SalahRepository`, `daily_session_log`'s activity flags, `adhkar_completion` via `AdhkarRepository`) — no new tracking schema
- [x] `focusAreaFor()` — pure, DB-free function implementing the exact prayer→quran→dhikr waterfall, unit-tested directly (`test/worship_coach_focus_test.dart`, 5 cases, no fake DB needed)
- [x] `WorshipCoachCard` (home screen, added not replacing) + `WorshipCoachScreen` (stage, one task with a direct button into the relevant screen, honest 3-number consistency breakdown instead of an opaque "AI suggests")
- [x] "أعمال إضافية" shown as an honest "قريبًا" note in the detail screen rather than silently absent
- [x] `flutter analyze` clean, `flutter test` clean (211 passing, same pre-existing unrelated failure), debug APK built
- [ ] Not yet tested on-device.

## Phase 28 — Real hifz coaching methodology: سبق/سبقي/منزل, "حبة حبة" (Ismail's request 2026-08-16) — 🔄 IN PROGRESS

Ismail: "ركّز وابحث كيف تكون مدرب شخصي لتطوير المستخدم في القرآن والتعلم، ابحث اونلاين اولًا وبعدين تعال" — real research (`WebSearch`/`WebFetch`) before any code. Found the traditional Sabaq-Sabqi-Manzil hifz-teaching system (real institute methodology, not a blog) with concrete numbers: real daily new-memorization pace by level, the "must be flawless before advancing" mastery rule, the 15-day سبقي window, and the weekly-proportional منزل rotation. Full findings in `QURAN_COMPANION_ROADMAP.md` §4.31. Ismail confirmed: "نعم وسنطور اكثر حبه حبه" (yes, and we'll develop it further step by step) — building incrementally, not all at once.

- [x] Grain 1 (commit 1913ec3): `MemorizationUnit.hifzCategory()` — pure function categorizing a page as سبق/سبقي/منزل by age since memorized, unit-tested (`test/hifz_category_test.dart`, 4 cases). Wired into the review screen, browse screen status label, and Worship Coach's Quran task wording. Purely a labeling layer — no scheduling math changed.
- [x] Grain 2 (commit 277b981): non-blocking realistic-pace advisory in رحلتي's SMART wizard — warns (doesn't restrict) when the chosen duration implies a daily pace exceeding real hifz-institute ceilings for the selected level.
- [ ] Grain 3+ (not started, queued): a real mastery gate (don't recommend new سبق until yesterday's is confirmed solid — advisory, not a lock), true weekly-proportional منزل rotation replacing the fixed 30-day cycle, and tying the real per-level pace numbers into "تكليف اليوم" itself, not just the wizard's warning.
- [x] `flutter analyze`/`flutter test` clean after each grain (215 passing as of grain 2, same pre-existing unrelated failure)

## Phase 29 — Fix genuinely-empty "حدد ما حفظته"/"ابدأ الحفظ" (Ismail's report 2026-08-16) — ✅ DONE (commit 3c67fdc)

The Phase 19 blank-screen fix added error-visibility but never found the actual root cause. Ismail's follow-up report was concrete: "عند الضغط يطلع فاضي فقط" (opens to genuinely empty, no error) — which narrows it to `memorization_units` having zero rows, since a `LEFT JOIN` from that table can only return zero rows if the table itself is empty.

- [x] Root cause: `_generateMemorizationUnits` only ever runs inside `QuranImportService`'s `quran_ayat`-empty onboarding branch — any device where `quran_ayat` ended up populated but `memorization_units` didn't (schema drift, an interrupted early install) would never get it backfilled, permanently, no matter how many retries.
- [x] `QuranImportService` now checks `memorization_units` independently and regenerates it straight from the already-imported `quran_ayat` rows if ever found empty — self-heals on next launch regardless of root cause, cheap no-op otherwise.
- [x] Also hardened the browse screen itself: every Juz `ExpansionTile` started collapsed, which alone could read as "empty" at a glance — now auto-expands the Juz containing today's highlighted assignment (or Juz 1) on load.
- [x] `flutter analyze`/`flutter test` clean, debug APK built and sent.
- [ ] Not yet confirmed fixed by Ismail on his actual device — this was reasoned from the exact symptom description ("empty, not an error"), not a live repro, so needs his confirmation.

## Phase 30 — أهل القرآن research + طبّق gap fix in the Worship Coach (Ismail's request 2026-08-16) — ✅ DONE (commit 94df17c)

Ismail: "تعلّم زيادة عن توجيه المستخدم كي يكون مسلم ذو خلق وأهل القرآن ومقيم الصلاة، ليس فقط يصلي." Real `WebSearch` research first, per roadmap §4.32.

- [x] أهل القرآن confirmed (via the authentic hadith and classical usage) to be defined by acting on the Quran, not reciting/memorizing it — found `WorshipCoachRepository.quranConsistency()` never counted `did_application` ("طبّق") days despite that column existing since Phase 3. Fixed.
- [x] إقامة الصلاة vs. mere أداء researched and confirmed — no gap found, the existing Salah companion already tracks khushu/consistency/punctuality/congregation exactly as the concept requires.
- [x] `flutter analyze`/`flutter test` clean.

## Phase 31 — 4 new memorization-coach features + "تعديل ما حفظت" (Ismail's request 2026-08-16) — ✅ DONE (commits 4e6dc30, fcd541e)

Ismail: "اسمح بالتعديل في ما حفظت واضف 4 مزايه في مدرب التحفيض جديده ابحث في الانترنت ان لم تكن تعلم." All 4 features build on the already-researched سبق/سبقي/منزل methodology (§4.31), plus new research on repetition counts (§4.33).

- [x] `MemorizationRepository.resetProgress(unitId)` — undo a mistakenly-marked memorized page (clears progress + review/mistake history), edit icon on each memorized page in تصفح القرآن behind a confirm dialog
- [x] Mastery-gate advisory: مدرب العبادة now recommends completing due reviews before a new سبق when there's real review debt — advisory (routes to المراجعة), never a hard block
- [x] Real منزل weekly target (`manzilDailyPortionSize()`) shown as an informational stat in مدرب العبادة — doesn't touch the live scheduling engine
- [x] Recurring weak-spot detector (`recurringWeakSpots()`) — reuses existing `mistake_log`, surfaces the most-repeated-mistake pages from the last 30 days
- [x] Repetition counter for today's سبق — new `sabaq_repetition_log` table (DB v30→v31), simple tap counter on the "تكليف اليوم" card showing the researched 10-40 range honestly, not an invented precise number
- [x] `flutter analyze`/`flutter test` clean (215 passing, same pre-existing unrelated failure).
- [ ] Not yet tested on-device.

## Phase 32 — Page/Juz-based Quran navigation (Ismail's request 2026-08-16) — ✅ DONE (commit 8958b38)

Ismail: "اريد التنقل بين صفحات القران وليس السور فقط... من الفهرس ومن اماكن اخرى انت فكر فيها" — الفهرس was surah-only; asked for page-level navigation from the index and other entry points of my own choosing.

- [x] الفهرس rebuilt as 3 tabs: السور (unchanged), الأجزاء (new — `firstPageOfJuz()`, 30 entries), رقم الصفحة (new — direct page-number entry, 1-604)
- [x] Second entry point: the page/Juz header in the app bar is now tappable, opening a lightweight quick-jump dialog — faster than the full الفهرس sheet
- [x] Existing next/previous page buttons unchanged
- [x] Deliberately did NOT add swipe-gesture page-turning this round — RTL swipe-direction semantics are easy to get backwards (a wrong direction would be a more confusing regression than not having it), and the two tap-based entry points already cover the ask; flagged as a possible future addition, not silently dropped
- [x] `flutter analyze`/`flutter test` clean (215 passing, same pre-existing unrelated failure)
- [ ] Not yet tested on-device.

## Phase 6 — Additional languages (roadmap §4.10)

- [ ] i18n infrastructure for UI strings (Arabic/English/Amharic via ARB files) — only after the Arabic content core is stable
- [ ] `translation_am`/`translation_en` columns on `quran_ayat` sourced from Tanzil (Amharic: Sadiq/Habib; English: Saheeh International or similar)
- [ ] Explicitly NOT promised: full translation of tafsir/hadith-commentary/fiqh content — no ready-made trusted source exists

## Phase 7 — Level map: "zero to scholar" (roadmap §4.11) — ✅ DONE 2026-08-16 (commit 456d26c)

- [x] Deviated from the roadmap's literal SQL slightly for simplicity: no `curriculum_levels`/`curriculum_items`/`user_level_progress` DB tables. The 3 levels + their items are a fixed const list (`data/curriculum_levels.dart`, same pattern as `wird_templates.dart`), and `CurriculumRepository` computes each item's status LIVE by querying the *existing* progress table it points at (memorization_progress, hadith_progress, wasitiyyah_progress, guide_progress, zad_almaad_progress, madarij_progress, adhkar_completion, application_log, audio_reflection_log) — nothing is duplicated or cached, so it can never drift, same principle as the §4.15 completion planner
- [x] Recommendation-only, never a hard lock — `CurriculumMapScreen` just navigates to the real screen for whatever's tapped, any level openable in any order
- [x] Items with no content yet (القاعدة النورانية, still blocked on 5و) show an honest "قريبًا" state rather than disappearing or erroring
- [x] Expanded "رحلتي" (Phase 4) with a "خريطتي التعليمية" button opening the level map, rather than building a second fully separate/undiscoverable screen — matches the roadmap's explicit intent to grow this same screen, short of a full structural merge (kept as its own screen for now, reachable in one tap from رحلتي)

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
- [x] Home screen integration — ✅ DONE 2026-08-15 (commit 0dd0c5b). "رفيقك اليوم" combined card (`widgets/daily_companion_card.dart`) shows next prayer + today's Quran/adhkar status + a Qibla quick-link together, reusing existing repositories rather than duplicating status logic. Silently hides if location isn't available; standalone screens/buttons stay too.
- [x] High-latitude rule — ✅ DONE 2026-08-15 (commit d48521c). Exposed as a setting in PrayerTimesScreen (auto/middleOfTheNight/seventhOfTheNight/twilightAngle), defaults to `adhan_dart`'s own `HighLatitudeRule.recommended()`.

## Phase 10 — Multi-language basics + Arabic-learning curriculum for non-native speakers (Ismail's request 2026-08-15) — ✅ DONE 2026-08-15 (commits db5f927, bcfc1de)

Ismail's explicit scoping, in his own words: "ترجم ما استطعت الأساسيات، أما المتعمق عليه أن يتعلم العربية" (translate the basics as much as possible; for deep content, they should learn Arabic) — then asked for a full integrated Arabic-learning curriculum for non-Arabic speakers living inside this same app ("يتوفر كل شيء داخل مكان واحد"), explicitly so users can grow from translated-basics into reading the deep Arabic content themselves.

- [x] **Basics translation** (commit db5f927): `LanguagePreferenceService` + 16 navigation/hub labels translated into 13 languages (ar/en/am/fr/sw/ur/tr/id/bn/ha/so/fa/ms), applied to HomeScreen + ProfileScreen's main navigation, with a language picker. NOT a full app-wide i18n system — the other ~40 screens stay Arabic-only, which is correct per Ismail's own philosophy (deep content = learn Arabic), not a gap. AI-translation honesty flagging same as the new-Muslim guide's Amharic.
- [x] **Arabic-learning curriculum for non-natives** — ✅ FULLY DONE 2026-08-15 (commits bcfc1de, 8c0f8bd, 4c3db8f): all 5 stages built (alphabet → reading mechanics → frequency-tiered vocabulary → grammar → Quranic-text application). Per Ismail's explicit follow-up request, researched real methodology before building further: Madinah Arabic Course (Dr. V. Abdur Rahim) and Al-'Arabiyyah Bayna Yadayk informed the stage sequencing; real Quranic-corpus word-frequency research (~100 words ≈ 50% of the Quran's text, ~500 words ≈ 85%) grounds Stage 3 instead of generic conversational topics. Stage 5 word-by-word breaks down Al-Fatihah + Al-Ikhlas using the app's existing bundled Tanzil text. A "مصادر موصى بها" screen cites the two real courses (title/author/description only) for learners wanting a fuller course. Stage-1-completion certificate wired into `achievement_milestones`/شهاداتي — further stage certificates not added yet (still open, low priority). Distinct from 5و (Qaida, still for children) — this is the adult non-native track.

## Phase 11 — Tajweed curriculum, 3 tiers (Ismail's request 2026-08-15) — ✅ DONE 2026-08-15 (commit 8ab735c)

Basic/intermediate/advanced Tajweed (Quran recitation rules) tracks. Researched real sources first (same rigor as the Arabic curriculum): verified Tuhfat al-Atfal (Al-Jamzuri, 18th century, standard beginner poem) and Al-Muqaddimah Al-Jazariyyah (Ibn al-Jazari, d. 833 AH, the most authoritative classical text) are real — cited by title/author in a "مصادر موصى بها" screen, not reproduced.

- [x] Basic tier: makharij overview + 4 noon sakinah/tanween rules (izhar, idgham, iqlab, ikhfa)
- [x] Intermediate tier: 3 meem sakinah rules, qalqalah, laam/ra tafkheem-tarqeeq
- [x] Advanced tier: 5 madd types, waqf symbols
- [x] Per-tier completion certificates wired into `achievement_milestones`/شهاداتي from the start, per Ismail's standing request that every pillar get one — not a follow-up add-on this time

## Phase 12 — إقامة الصلاة: Salah companion (Ismail's request 2026-08-16) — ✅ DONE 2026-08-16 (commit 4d0276e)

Ismail relayed a detailed design (apparently from a separate planning conversation) for a non-judgmental daily Salah tracker with self-assessment, then explicitly asked for it as its own distinct module ("خانه مودل جديد اقامة الصلاة") rather than folded into the existing PrayerTimesScreen, plus stories of the Salaf's stillness/khushu in prayer. Core stated principle carried over from that design and applied throughout: AI must never invent or assert a fiqh ruling, and khushu specifically can never be measured/inferred by the app — only self-rated by the user.

- [x] DB schema v21: `salah_log` (per-day/per-prayer status: on-time/jamaah/late/missed), `salah_self_assessment` (weekly, 7 dimensions, star ratings, 100% user-entered), `salah_library_progress` (mark-read tracking) — `lib/db/database_helper.dart`
- [x] `lib/repositories/salah_repository.dart` — status tracking, hijri-week-start computation, weekly completion count (out of 35 possible slots), assessment CRUD, no scoring/inference logic anywhere
- [x] `lib/data/salah_content.dart` — 11 original lesson categories (arkan/wajibat/sunan/mubtilat/khushu/adhkar_salah/tafsir_fatiha/rawatib/qiyam/jamaah) grounded in well-established, non-controversial fiqh, hand-written (not translated book excerpts, same sourcing discipline as باب الأدب); 3 well-known Salaf stories about khushu, explicitly framed as widely-circulated accounts rather than chain-verified hadith; 6 real book citations (title/author/neutral note only, no reproduced text) — صفة صلاة النبي (Albani & Ibn Baz), شرح صفة صلاة النبي (Ibn Uthaymeen), الخشوع في الصلاة (Ibn Rajab), الوابل الصيب and مدارج السالكين (Ibn al-Qayyim)
- [x] 5 screens: `salah_tracker_screen.dart` (main entry, per-prayer status picker), `salah_assessment_screen.dart` (weekly star ratings, "لا أحد سيراها سواك" framing), `salah_library_screen.dart`, `salah_stories_screen.dart`, `salah_resources_screen.dart`
- [x] Wired as a standalone entry point (not merged into PrayerTimesScreen) in both HomeScreen and ProfileScreen, per Ismail's explicit instruction
- [x] The two remaining pieces from the original design — ✅ DONE 2026-08-16 (commit 33dd3eb), built as a natural follow-up rather than waiting for a fresh explicit request: "مهمة اليوم" (a deterministic day-of-year rotating lesson card on `SalahTrackerScreen`, drawn from the existing library content — no new content, no separate tracking table) and a per-day/per-prayer 5×7 weekly grid added to `SalahAssessmentScreen` (computed live from `salah_log`, no new schema) so the "weekly report" combines the tracker's daily detail with the self-assessment stars in one place.

## Phase 13 — كتب صوتية من اليوتيوب: audio lecture library (Ismail's request 2026-08-16) — ✅ DONE 2026-08-16 (commit 3d0f050)

Ismail sent 3 YouTube links asking to add them as an in-app "audio books from YouTube" section, first explicitly checking whether this is allowed. Confirmed: streaming through YouTube's own official embedded player (`youtube_player_iframe`, wraps the IFrame Player API) is fully compliant and standard practice — the app never downloads/rehosts the actual media, only metadata (video/playlist IDs). Ismail separately asked whether downloading audio to the device is possible — confirmed no, that would require stream-extraction (yt-dlp-style), which violates YouTube's ToS and the uploader's copyright; declined to build it, same boundary as the earlier Nabulsi-audio decision.

- [x] `youtube_player_iframe` dependency added, resolved cleanly (pulls in `webview_flutter`), Android INTERNET permission already present from an earlier phase
- [x] DB v21→v22: `audio_progress` (resume video+position per series), `audio_reflection_log` (user's own written notes per episode), `custom_audio_series` (user's self-added links)
- [x] 3 curated series verified via their actual YouTube metadata before adding (`data/audio_series_seed.dart`, fixed const list like `wird_templates.dart`): البداية والنهاية (Ibn Kathir, audio narration), مدارج السالكين (Ibn al-Qayyim, audio companion to the text already in the app), وتفسير ابن كثير لسورة البقرة — شرح الشيخ عبدالرحمن العجلان (**closes the long-open "Sharh Ibn Kathir audio layer (Al-'Ajlan)" TODO item from §5** — confirmed the playlist Ismail sent is itself scoped to Al-Baqarah only, not a mixed all-Quran playlist, so no slicing was needed)
- [x] Auto-resume: `AudioPlayerScreen` tracks playback position every 15s and on dispose, reopening a series cues the exact video+timestamp last left off at — Ismail's explicit ask ("يسجل أين توقف")
- [x] "دفتر الفوائد" reflection notes per episode, with 4 example prompts as tap-to-insert chips to encourage writing (Ismail's explicit ask for "امثله كي يتشجع للكتابه") — wired into `achievement_milestones` at 1/10/50 saved reflections, per the standing every-pillar-gets-certificates rule
- [x] Self-service "أضف سلسلة صوتية" — Ismail asked whether new series could be added going forward beyond what he'd sent; besides the trivial answer (send more links, they get added to the const list), built an in-app add-your-own-link screen (paste any YouTube video/playlist URL + title) so he isn't blocked waiting on a future session, matching the existing "مكتبتي" personal-library pattern (self-added, no curation/review, clearly separated in the UI from the 3 app-curated series)
- [x] **Tested on-device by Ismail — surfaced two real problems, both fixed 2026-08-16 (commit 22ad834)**: (1) some individual videos fail to embed ("Error code: 152" — a video-side embedding restriction the app cannot override without stream-extraction, which stays off-limits; mitigated with a per-episode "افتح هذه الحلقة في يوتيوب" fallback). (2) the flat single-player screen had no way to browse other episodes in a series and jump around — rebuilt into a real قسم→حلقات (series→episodes) structure: `AudioPlayerScreen` reads the actual ordered episode-video-ID list straight from YouTube's own embedded player (`controller.playlist`, no Data API key needed), shows a tappable "الحلقات" list with السابقة/التالية navigation, and `AudioLibraryRepository.reflectionsFor` now filters "دفتر الفوائد" per episode (`video_id`) instead of mixing every note from the whole series together.
- [x] Found in passing (pre-existing, unrelated to this phase): Tajweed's 3-tier completion certificates were awarded correctly but never rendered in the "شهاداتي" gallery screen — spun off as a separate small task, fixed same day (added the missing `tajweed_*` `_section()` call to `certificates_screen.dart`).
