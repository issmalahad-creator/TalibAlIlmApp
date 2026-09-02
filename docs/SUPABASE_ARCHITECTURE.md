# Supabase as the Central Knowledge Layer — Architecture Audit & Plan

Status: **APPROVED AS DIRECTION 2026‑09‑03 (Ismail). NOT started.**
Sequenced strictly *after* the mushaf engine is complete and verified
(604/604 QA + real-device). No schema, no client code until then. The only
thing that happens now is S0: this doc + the `tool/check_secrets.sh`
pre-commit guard. Same section order Ismail asked for the mushaf engine:
CURRENT ARCHITECTURE → PROBLEMS/GOALS → ROOT CAUSES → PROPOSED ARCHITECTURE
→ LIFE‑PLAN INTEGRATION → MIGRATION PLAN → QA/VERIFICATION.

Governing principle (project law, `docs/quran/QURAN_LIVE_DATA_ARCHITECTURE.md`
AD‑1): **Offline‑first, NOT offline‑only.** Local SQLite stays the primary
store and the source of truth on any mismatch. Supabase is a **cloud mirror +
a shared search/knowledge index + the backend the mosque and life‑plan
features already need** — never a hard dependency. Airplane mode = every
existing feature still works.

Sibling docs this builds on / must not contradict:
`docs/mosque/01_ARCHITECTURE.md`, `docs/mosque/supabase_schema.sql` (already
written, the pilot slice), `docs/quran/QURAN_LIVE_DATA_ARCHITECTURE.md`,
`docs/TURATH_INTEGRATION.md`, `docs/QURAN_SOURCES_AND_LICENSES.md`.

---

## 1. CURRENT ARCHITECTURE

### 1.1 Storage & identity

- **One local SQLite database** (`sqflite`, `DatabaseHelper`, **schema
  version 53**, ~100 tables). Incremental `_createVNN` migrations. No ORM;
  hand-written repositories.
- **No authentication anywhere.** No user accounts, no `user_id` column on
  any table. `profile` is a single local row.
- **No server, no hosted database, no sync, no backup.** Uninstall / device
  loss / "clear data" = total, unrecoverable loss of all student progress
  (hifz, review schedule, notes, highlights, goals, journal, reading
  positions, life plan).
- **No per-device concept**, no conflict model, no outbox, no change log.
- `lib/config/app_config.dart` (git-ignored) holds `supabaseUrl` +
  `supabaseAnonKey` (publishable). The DB password / `service_role` key are
  **secrets** and are deliberately not in the repo, app, or any doc.

### 1.2 The ~100 local tables, grouped

| domain | representative tables |
|---|---|
| **Quran reference** | `quran_ayat`, `tafsir_entries`, `mushaf_pages/lines/words/aya_marks/markers/meta` |
| **Quran learning (deterministic)** | `knowledge_concepts`, `knowledge_facts`, `source_references`, `knowledge_cache`, `learning_path_items`, `ayah_study_entries`, `ayah_entry_links`, `study_events` |
| **Hifz / review** | `hifz_students/surah_status/daily_log/student_fields`, `memorization_progress/units`, `review_log`, `sabaq_repetition_log`, `knowledge_review_progress` |
| **Recitation** | `recitation_sessions`, `recitation_mistakes`, `mistake_log` |
| **Turath library** | `turath_catalog_books/authors/categories/category_books/meta`, `turath_book_cache`, `turath_page_cache`, `turath_favorites`, `turath_last_read`, `turath_notes`, `turath_annotations`, `turath_benefits`, `turath_quotes` |
| **Personal library / books** | `personal_books`, `personal_book_categories`, `book_bookmarks`, `book_reflection_log`, `book_application_log`, `reading_progress` |
| **Texts (Aqeedah/Fiqh/Hadith…)** | `nawawi_hadiths`, `wasitiyyah_sections/progress`, `madarij_sections/progress`, `zad_almaad_chapters/progress`, `hadith_progress`, `practical_lessons`, `salah_library_progress` |
| **Worship / adhkar** | `adhkar_*`, `salah_log/self_assessment`, `tasbih_log`, `istighfar_log`, `wird_selection`, `custom_*` |
| **Goals / planning / journal** | `goals`, `completion_goals`, `journey_plan`, `daily_tasks`, `daily_session_log`, `activities`, `personal_accountability`, `time_awareness_log`, `student_mission` |
| **Progress / gamification** | `achievement_milestones`, `placement_ratings`, `guide_progress`, `*_progress` (arabic_curriculum, tajweed, understanding, salah…) |
| **Companion** | `companion_chat_log`, `companion_memory` |
| **Mosque platform (v53)** | `mosques`, `mosque_sections`, `mosque_content`, `mosque_media`, `mosque_meta` |
| **infra** | `application_log` |

### 1.3 Existing external touchpoints (the only network code today)

- `lib/services/book_content_service.dart` — `http.get` a JSON feed
  ("كتاب الشهر" / banner), best-effort, empty on failure.
- `lib/services/turath_api_client.dart` — `api.turath.io` (keyless, v3):
  `search`, `book`, `page`, `author`; `files.turath.io/books/{id}.json`.
  Responses cached into `turath_book_cache` / `turath_page_cache`.
- `lib/services/mosque/supabase_mosque_api.dart` — **already wired this
  session**: PostgREST over `http` (no SDK), read-only, `apikey` +
  `Authorization: Bearer <anon>`, returns `[]`/null on any failure.
  `MosqueRepository` auto-selects it when `AppConfig.supabaseUrl` is set,
  else `LocalOnlyMosqueApi` (demo seed).
- `google_apps_script/life_plan_sync.gs` — Ismail's life-plan Google Sheet
  as an Apps Script web app: `doGet` (today's slots + `dayNumber`), `doPost`
  (toggle a slot, shared-secret gated), `onEditInstalled` (recompute
  pillar % into "📊 تتبع الإنجاز"). Not yet consumed by the app (Phase 77.11
  placeholder).

### 1.4 Search today

Local only, per feature. `normalizeArabicForSearch` for the Quran search
index; `LIKE`/FTS-ish scans elsewhere; Turath search is remote
(`api.turath.io`). **Nothing searches across domains** — you cannot ask "الصبر"
and get its ayat + tafsir + Turath pages + your own notes + a lesson in one
list.

---

## 2. PROBLEMS / GOALS

**G1 — Durability & continuity.** Reinstall or new phone must not wipe the
student's years of hifz/review/notes. Needs an account + a cloud copy.

**G2 — Multi-device.** Same student, phone + tablet, consistent state.

**G3 — Cross-content knowledge search (Ismail's core ask).** One query →
grouped hits across Quran, tafsir, Hadith, Turath, personal books, lessons,
and the student's own notes/highlights/benefits — with the links between
them ("this ayah ↔ this concept ↔ this lesson ↔ your note").

**G4 — Fast Turath fetch/open.** A shared server-side cache so a page other
users (or you, on another device) already opened returns instantly, instead
of every device re-hitting `api.turath.io`.

**G5 — The mosque platform needs a backend anyway** (multi-tenant, Telegram
intake, review-before-publish) — Supabase is already chosen and the pilot
slice is written.

**G6 — The life plan needs a home** the app can read/write without the
Sheet being the only surface.

**Non-goals (explicit):** no live AI facing the student as a source of
religious knowledge (unchanged project law); no realtime multiplayer beyond
leaderboards/courses/mosque; no moving the primary store off-device.

---

## 3. ROOT CAUSES

**RC‑1 — `sqflite` was inherited from the DawahReportApp clone**, designed
for a single offline user. Correct for v1; never revisited.

**RC‑2 — every feature since added its own local tables** with no shared
substrate for *identity* (whose data is this), *sync* (how does it move),
*change tracking* (what changed since when), or *search* (one index). ~100
tables, ~0 of that infrastructure.

**RC‑3 — search was always built per-screen**, so there is no unified
document model and no place for semantic/hybrid search to plug in.

**RC‑4 — external data (Turath) is cached per-device**, so the cost is paid
N times and nothing is shared.

---

## 4. PROPOSED ARCHITECTURE

### 4.1 Shape

```
        ┌─────────────── device (offline-first) ───────────────┐
        │  Flutter UI                                          │
        │  repositories  ──►  local sqflite (PRIMARY)          │
        │                     + sync_outbox / sync_state       │
        │        ▲                     │  background, resumable │
        │        │  read-through       │  push outbox / pull Δ  │
        └────────┼─────────────────────┼───────────────────────┘
                 │                     ▼
        ┌────────┴───────────── Supabase ──────────────────────┐
        │ Postgres:  reference (public RLS)  |  personal (RLS  │
        │                                       user_id=uid)   │
        │ Auth  ·  Storage  ·  Realtime(3 tbls)  ·  pgvector   │
        │ Edge Functions: search · embed · ask · turath-proxy  │
        │                 life-plan-sync · mosque-intake       │
        └─────────────────────────────────────────────────────┘
```

- **Local SQLite stays primary.** Repositories read/write local first,
  enqueue changes in `sync_outbox`. A background syncer pushes the outbox and
  pulls per-table deltas. Supabase unreachable → the app is unaffected.
- **Postgres is the mirror + the shared index.** It is never read
  synchronously on the UI path (except the mosque pilot, which has no local
  authored data).
- **The Quran, the mushaf, and the core text library never depend on
  Supabase.** Reading an ayah, opening a mushaf page, browsing a bundled
  text = 100% local, offline, always. If Supabase vanished tomorrow the only
  things lost are cross-device sync, cross-content search, the mosque
  platform, and the life-plan bridge — never the ability to read.

### 4.2 Auth & device identity

- **Supabase Auth.** Start with **anonymous sign-in** on first launch (zero
  friction, immediate `user_id`), offer **email OTP** upgrade to claim the
  account across devices. No passwords.
- New local + remote table **`devices`** `{device_id (uuid, local), user_id,
  platform, label, created_at, last_seen_at}`.
- **`user_id uuid` becomes the owner column on every personal table**
  (nullable during migration, backfilled to the anon user, then
  `NOT NULL`). Reference tables have no `user_id`.

### 4.3 Schema — two classes of table

**A. Reference (shared, read-mostly, RLS = public read, no client write)**

Mirrors of local reference data, versioned by a `dataset_version` row in
`reference_meta`. Client pulls when its stored version is behind; never
writes.

| table | source | notes |
|---|---|---|
| `quran_ayat` | **bundled local seed / Tanzil — local is primary** | a Supabase copy exists **only** to build `search_documents` server-side; the app never fetches it to render an ayah |
| `mushaf_pages/lines/words/aya_marks/markers` + page art | `assets/mushaf/*` (bundled) | **NOT mirrored to Supabase.** Local-only, never on any read path. Opening a mushaf page never touches the network. |
| `tafsir_editions`, `tafsir_entries` | licensed sources | per `QURAN_SOURCES_AND_LICENSES.md` — only bundle-able ones; bundled copy is primary |
| `knowledge_sources`, `concepts`, `knowledge_facts` | `prototype.json` → curated | deterministic learning layer |
| `turath_books`, `turath_authors`, `turath_categories`, `turath_category_books` | `api.turath.io` catalog | catalog only; page text via `turath_pages` cache |
| `texts_*` (nawawi_hadiths, wasitiyyah_sections, madarij_sections, zad_almaad_chapters, practical_lessons…) | curated | the "مكتبة النصوص" pillar |
| `mosques`, `mosque_sections`, `mosque_content`, `mosque_media` | Telegram/n8n intake | already in `docs/mosque/supabase_schema.sql` |

**B. Personal (per-user, RLS = `user_id = auth.uid()`)**

One row-shape per concern; the local table gains `user_id`, `updated_at`,
`deleted_at`, `rev`, `origin_device`.

| Supabase table | consolidates local |
|---|---|
| `library_items` | `personal_books`, `personal_book_categories`, `turath_favorites`, `book_bookmarks` |
| `reading_positions` | `turath_last_read`, `reading_progress`, `adhkar_session_position`, `audio_progress` |
| `notes` | `turath_notes`, `book_reflection_log`, `book_application_log`, `audio_reflection_log`, journal-type rows |
| `annotations` | `turath_annotations` (highlight + page_note), future Quran highlights |
| `benefits` (الفوائد) | `turath_benefits`, `turath_quotes` |
| `hifz_state` | `hifz_surah_status`, `memorization_progress`, `memorization_units` |
| `review_log` | `review_log`, `sabaq_repetition_log`, `knowledge_review_progress` |
| `recitation_log` | `recitation_sessions`, `recitation_mistakes`, `mistake_log` |
| `study_entries` | `ayah_study_entries`, `ayah_entry_links`, `study_events` |
| `goals` | `goals`, `completion_goals`, `achievement_milestones` |
| `daily_plan` | `daily_tasks`, `daily_session_log`, `journey_plan` |
| `progress_counters` | the many `*_progress` tables (subject, value, updated_at) |
| `courses`, `enrollments`, `quiz_attempts` | `quiz_results`, `placement_ratings`, `guide_progress` |
| `worship_log` | `salah_log`, `adhkar_completion`, `tasbih_log`, `istighfar_log`, `wird_selection` |
| `companion_state` | `companion_chat_log`, `companion_memory` |
| `life_plan_*` | the Google Sheet (see §5) |
| `hifz_students`, `hifz_student_fields`, `hifz_daily_log` | teacher-mode: `owner_user_id` + optional `student_user_id` |

Consolidation is a *modeling* choice for the mirror; the local schema can
migrate gradually (a `sync_map` translates local table/row ↔ remote
table/row).

### 4.4 Sync engine

- **Local**: `sync_outbox {id, table, row_pk, op(upsert|delete), payload,
  enqueued_at, tries}` · `sync_state {table, last_pulled_at, last_pushed_at,
  cursor}`.
- **Every personal remote row**: `updated_at timestamptz` (server-set via
  trigger), `deleted_at` (soft delete), `rev bigint`, `origin_device`.
- **Push**: drain `sync_outbox` → `upsert` / soft-delete via PostgREST or an
  Edge Function; on success advance `last_pushed_at`.
- **Pull**: per table `select … where user_id = uid and updated_at >
  cursor order by updated_at` → merge into local; advance `cursor`.
- **No blind last-write-wins.** Every domain is tagged with a resolution
  class and the syncer applies that class — never a single global rule:

  | class | tables | rule |
  |---|---|---|
  | **Append-only** | `review_log`, `recitation_log`, `study_events`, `worship_log`, `companion_chat_log`, `mistake_log`, `daily_session_log` | rows immutable once written; sync = set-union by `(user_id, id)`. No conflict possible. |
  | **Merge (monotonic / field-level)** | `hifz_state` (max station / progress — a stale device can never move it backward), `progress_counters` (`max`), `goals.progress` (`max`), `reading_positions` (latest `updated_at`, keep furthest page as a tiebreak) | field-level rule, not row replace. |
  | **LWW** | `notes.body`, `annotations` (colour / note), `benefits`, `library_items` metadata, `daily_plan` task text, `profile` / settings, `life_plan_day_slots.done` | small, user-edited, the last edit is the intended state. Loser still goes to `conflict_log`. |
  | **Client-authoritative** | `companion_memory`, the local `devices` row, `sync_outbox` / `sync_state`, unsent drafts | never written by the server. |
  | **Server-authoritative** | all reference tables, `mosques*`, `mosque_content`, `leaderboards`, `courses` catalog, `reference_meta`, quiz correct-answers | pull-only; the client never writes. |
  | **Conflict-required (surface, do not auto-resolve)** | materially divergent edits to the same `notes` / `benefits` body from two devices inside one sync window | write both, flag in `conflict_log`, show a "you edited this on two devices" resolver. Rare; only for content the user would be upset to lose. |

- `conflict_log` (local + remote) records every non-trivial loser regardless
  of class, so nothing is silently dropped and Ismail can audit.
- **Reference tables**: pull-only, gated by `reference_meta.dataset_version`;
  full-replace a domain when its version moves (same pattern as
  `MushafLayoutSync` today).
- **Properties**: runs in the background, resumable, offline-tolerant,
  idempotent (upserts keyed by natural PK + `user_id`), never blocks a
  screen.

### 4.5 Search — lexical + semantic + hybrid

- **Unified document table `search_documents`**
  `{doc_id, kind(ayah|tafsir|book_page|text_section|note|annotation|benefit|
  concept|lesson|mosque_content), ref jsonb, user_id uuid NULL, lang,
  title text, body text, body_norm text, tsv tsvector, embedding
  vector(N)}`.
  `user_id NULL` = public/reference doc; non-null = that user's private doc.
  RLS: `user_id is null or user_id = auth.uid()`.
- **Lexical**: `tsv` = `to_tsvector('arabic', body)` plus `body_norm` built
  with the same normalization the app's `normalizeArabicForSearch` uses
  (strip tashkīl, unify alef/ya/ta-marbuta) → a second `simple`-config
  `tsvector` so diacritic-insensitive matching works. GIN indexes on both.
- **Semantic**: `embedding` via `pgvector`, `ivfflat`/`hnsw` index.
  Embeddings are generated **server-side** by the `embed` Edge Function
  (calls an embedding provider with a key that lives only in Edge Function
  secrets) — **no embedding key ever ships in the app**.
- **Hybrid**: the `search` Edge Function runs both (FTS rank + vector
  distance), fuses with **Reciprocal Rank Fusion**, returns results already
  grouped by `kind` and expanded through the Knowledge Index (§4.6). The app
  calls one function; offline it falls back to the local lexical index.
- **Backfill/refresh**: `embed` runs on new/changed `search_documents` rows
  (trigger sets `embedding = null`; a scheduled function fills them).

### 4.6 Knowledge Index — deterministic links

- **`knowledge_links {from_kind, from_ref, to_kind, to_ref, relation,
  source_ref_id NULL, user_id NULL, weight}`** — a typed edge list.
  `relation ∈ {explains, mentions, about_concept, cites, applies, see_also,
  authored_by, in_category, part_of}`.
- **Public edges** (curated / derived, `user_id NULL`): ayah↔concept,
  ayah↔tafsir_entry, concept↔lesson, hadith↔topic, book↔author,
  book_page↔concept, text_section↔concept.
- **Private edges** (`user_id` set): note↔ayah, annotation↔book_page,
  benefit↔concept, study_entry↔ayah — created as the student works.
- **"Search a topic"** = FTS/vector over `search_documents` → seed docs →
  one hop over `knowledge_links` → grouped, cross-content result ("الصبر:
  12 ayat · 3 tafsir passages · 2 hadiths · 5 Turath pages · your 4 notes ·
  concept 'الصبر' + its lesson"). **No AI needed for the index** — it is
  edges + full-text. AI is optional only for (a) embeddings and (b) an
  opt-in "اسأل" that must always cite `source_references` and is gated by
  the same policy discussion as the debate coach (Phase 73).

### 4.7 Storage

Buckets, each RLS-scoped: `recitations/{user_id}/…` (private),
`mosque-media/{mosque_id}/…` (public read), `book-pdf/…` (licence-gated),
`user-uploads/{user_id}/…` (private). The app **streams** from Storage; it
never bundles this media. Mosque audio recordings (`mosque_content.kind =
recording`) live here — in scope, distinct from the deferred Quran
recitation-follow.

### 4.8 Realtime — deliberately minimal

Only `leaderboards`, `course_activity`, and `mosque_content` (pilot)
subscribe to Postgres changes. Everything else is pull-sync. Keeps battery,
quota, and complexity down.

### 4.9 Edge Functions

| function | purpose | secret it holds |
|---|---|---|
| `search` | hybrid RRF over `search_documents` + link expansion | — (uses anon/user JWT) |
| `embed` | (re)generate embeddings for changed docs | embedding-provider key |
| `ask` | opt-in, always-cited answer over retrieved passages | model key |
| `turath-proxy` | fetch `api.turath.io` once, cache into `turath_pages` / `turath_books`, serve everyone (G4) | — |
| `life-plan-sync` | bridge the Google Sheet ↔ `life_plan_*` (§5) | Sheet shared-secret |
| `mosque-intake` | Telegram/n8n → validated writes with `service_role` | `service_role` |

### 4.10 Keys & security

- Ships in the app: `supabaseUrl` + **publishable anon key** only. RLS makes
  that safe (public reads limited to reference + published/active rows; every
  personal read/write gated by `auth.uid()`).
- **Server-only secrets**: DB password, `service_role` key, embedding/model
  keys, Sheet shared-secret — Edge Function / dashboard secrets, never repo,
  app, or docs.
- **Action item (Ismail, now)**: the Supabase **DB password was shared in
  plaintext chat** during setup → rotate it (Dashboard → Settings →
  Database → Reset). It is not used by the app (URL + anon key only), and a
  repo-wide scan on 2026‑09‑03 confirmed the password string appears
  **nowhere** in the tree (tracked or untracked).
- **Mechanical guard (S0)**: a git `pre-commit` hook + CI step —
  `tool/check_secrets.sh` — greps staged content for `service_role`, the
  `postgres://postgres:<pw>@` pattern, `sb_secret_`, and known
  embedding/model key prefixes, and **blocks the commit** on a hit.
- RLS default-deny: no table is readable/writable without an explicit policy.
  Reference tables get `select` policies only. `search_documents` and
  `knowledge_links` policies must union public + own.

---

## 5. LIFE-PLAN INTEGRATION ("مشروع الحياة / all need")

Source: `https://docs.google.com/spreadsheets/d/1P2fCEdQnTdFPSpZn9STaSxquw1Ac8HVU4PuzeHLOCbw/`
Existing bridge: `google_apps_script/life_plan_sync.gs` (verified against the
real sheet — 23 time-slots × 7 day-columns in "📅 الجدول اليومي"; 90 "اليوم N"
rows × 8 pillar columns + %/status in "📊 تتبع الإنجاز"; `START_DATE`
config; `PILLAR_ROW_MAP` ties slots → pillars).

### 5.1 Schema (personal, `user_id` = Ismail only, never public)

| table | shape |
|---|---|
| `life_plan_config` | `{user_id, start_date, day_count(90), pillars text[]}` |
| `life_plan_pillars` | `{user_id, key, label, sort}` — `['قرآن','كتاب 1','كتاب 2','Python','ERP عميل','Microworkers','محتوى','توظيف']` |
| `life_plan_slots` | `{user_id, slot_no, time_label, title, pillar_key NULL}` — the 23 daily slots |
| `life_plan_day_slots` | `{user_id, day_no 1..90, slot_no, done bool, done_at}` — the per-day checkboxes |
| `life_plan_day_summary` | `{user_id, day_no, overall_percent, status, pillar_done jsonb}` — mirrors what the .gs writes into "تتبع الإنجاز" |

### 5.2 Bridge — two options

- **Option A (recommended first — zero disruption).** The Sheet stays the
  editing surface. `life-plan-sync` Edge Function calls the existing Apps
  Script `doGet` on a schedule (and on app request) → writes `life_plan_*`.
  App writes (toggling a slot from the phone) go back through `doPost`
  (shared secret). The `.gs` already does the pillar-% math — reuse it.
- **Option B (later).** Move the source of truth into Supabase; the app's
  own plan screen becomes the editing surface; the Sheet becomes a
  read-only export (a scheduled function writes back). Do this once the
  in-app plan UI exists.

### 5.3 Placement

This is Ismail's **personal, single-user** data — strict `user_id` RLS, never
in any public/reference table, never in `search_documents` as a public doc.
It surfaces on the home screen's daily companion / accountability area, not
in the shared knowledge index. Roadmap-wise it is a small feature riding on
the sync engine, not a new pillar. Its build stays sequenced after the
mushaf engine and the core sync template (§6), per the "one phase at a time"
rule.

---

## 6. MIGRATION PLAN (phased — each step ships offline-safe, secret-free)

**S0** — this doc approved. No code.

**S1 — mosque pilot (already built, just run it).** Ismail runs
`docs/mosque/supabase_schema.sql` once in the SQL Editor. Verify «مساجدنا»
shows `MOSQ_PILOT_0001` from Supabase on device. This is the smallest
possible end-to-end proof that URL + anon key + RLS + PostgREST work.

**S2 — identity & sync scaffolding.** Supabase Auth (anonymous sign-in +
email-OTP upgrade). Local `devices`, `sync_outbox`, `sync_state`,
`conflict_log`. Add `user_id`/`updated_at`/`deleted_at`/`rev` to personal
local tables (nullable; backfill to the anon user). No behaviour change yet.

**S3 — one personal domain end-to-end (the template).** Pick **`notes` +
`annotations`** (small, already have a model + repo + tests
`turath_annotations`). Build push, pull, soft-delete, conflict-log. Prove on
**two devices**: edit the same row on both → converges, loser in
`conflict_log`. Everything else copies this template.

**S4 — reference mirror.** `reference_meta.dataset_version` + pull-only
`quran_ayat`, `turath_books/authors/categories`. App pulls when behind.
`knowledge_sources` + `concepts` + `knowledge_facts`.

**S5 — unified search.** `search_documents` + `tsv`/`body_norm` + GIN
indexes; populate from reference + the S3 personal domains. Then `pgvector`
+ `embed` + `search` Edge Functions + hybrid RRF. Wire a single
cross-content search screen; offline → local lexical fallback.

**S6 — Knowledge Index.** `knowledge_links` + the curated public edges +
private-edge creation as the student works + the grouped "topic across
everything" result view.

**S7 — remaining personal domains onto the S3 template.** hifz/review,
goals/daily_plan, progress_counters, courses/quiz_attempts,
reading_positions, worship_log, companion_state. One at a time, each with a
two-device test.

**S8 — life plan (Option A).** `life_plan_*` + `life-plan-sync` Edge
Function bridging the existing `.gs`.

**S9 — Storage + Turath proxy cache.** Buckets + RLS; `turath-proxy` Edge
Function so fetch/open is instant on a warm page (G4). Mosque media +
recitations upload paths.

Every step: airplane-mode regression pass (all existing features still
work); a repo key-scan (no `service_role` / password / model keys); RLS
check for the tables it touched.

---

## 7. QA / VERIFICATION

- **Offline matrix** — airplane mode: hifz session, review, notes,
  highlights, Turath reader (cached pages), mushaf reader, goals, journal,
  adhkar all fully functional. Automated where possible; manual checklist
  otherwise.
- **Sync convergence** — 2 devices, scripted: create/edit/delete the same
  row on both; assert both converge to the newer `updated_at`; assert the
  older payload is in `conflict_log` on both.
- **RLS** — a script (or pgTAP) with two users' JWTs: user A cannot
  `select`/`update` user B's `notes`/`annotations`/`life_plan_*`; the anon
  key cannot `insert`/`update`/`delete` any reference table; `search`
  returns A's private docs only to A.
- **Search relevance** — a fixed set of ~20 topic queries (الصبر، التوكل،
  أحكام الصلاة، بر الوالدين، الربا، …) with expected cross-content hits;
  track precision@10 as embeddings/edges evolve; assert hybrid ≥ lexical-only.
- **Reference parity** — row counts + checksums local vs remote per
  reference domain after a pull; `dataset_version` gating actually skips
  up-to-date pulls.
- **Key hygiene CI** — grep the repo for `service_role`, the DB password
  pattern, `sb_secret`, provider key prefixes → fail the build on a hit.
- **Life plan round-trip** — `day_no` from `START_DATE` matches the `.gs`
  `computeDayNumber_`; toggling a slot in-app reflects in the Sheet and the
  pillar-% recompute matches "📊 تتبع الإنجاز".
- **Cost guardrails** — a monthly check on Supabase row/egress/function
  usage against the free tier before enabling `embed` at scale.

---

## 8. Binding constraints

- Local SQLite stays primary. Supabase down / absent = app unaffected. Local
  wins on any data mismatch (AD‑1).
- **Reading is never networked.** Quran text, mushaf pages, and the bundled
  text library are local-only; `mushaf_*` + page art are **not mirrored** to
  Supabase at all. No screen that shows content blocks on a Supabase call.
- **No global last-write-wins.** Every synced domain carries an explicit
  resolution class (§4.4); the syncer honours it. Append-only and monotonic
  data can never be clobbered by a stale device.
- No live-AI religious authority facing the student. `ask` is opt-in,
  retrieval-only, always cites `source_references`, and needs the Phase‑73
  policy discussion before build.
- Only the publishable anon key ships. `service_role` / DB password /
  model keys are server-only. Rotate the plaintext-shared DB password.
- Every scholarly fact keeps its `source_ref_id` through the mirror and the
  index — the provenance gate is not weakened by going to Postgres.
- Licence-gated content (tafsir editions, Turath page text, PDFs) is mirrored
  only where `docs/QURAN_SOURCES_AND_LICENSES.md` / Turath terms allow;
  otherwise it stays online-fetch + per-terms cache.
- New user-facing strings → `basicText`, 13 languages, RTL/LTR aware.
- One phase at a time, after the mushaf engine, in `TODO.md` order.
