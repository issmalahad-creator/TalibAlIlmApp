# مساجدنا — Phase 1: current-state audit + proposed architecture

**No code was changed in Phase 1.** This is the design to approve before any
build. Vision: `docs/MOSQUE_PLATFORM_VISION.md`. Roadmap Phase 74.

Scope note (Ismail, 2026-09-02): the **mosque audio recordings** module
(`🎙️ التسجيلات` — imam lectures, khutbah audio) **is in scope** — it is a
`mosque_content` type + `mosque_media`, nothing to do with the Quran
reader's recitation-follow (`QuranAudioEngine` / التسميع), which is the only
audio feature that is deferred.

---

## 1. What the app is today (audit)

| Concern | Reality |
|---|---|
| Data store | **Local `sqflite` only** — `lib/db/database_helper.dart`, schema **v52**, incremental `_createVN` migrations. No hosted DB. |
| Users / auth | **None.** `profile` table is a single row `id = 1` — one student, on this device. No accounts, no login, no server identity. |
| Networking | `http: ^1.2.2` only. No Firebase / Supabase / gRPC / websockets. |
| Read APIs | `lib/services/turath_api_client.dart` → turath.io public API (read-only, no key, rate-limited). |
| "Backend" that exists | `telegram_relay/Code.gs` — a **Google Apps Script web-app**: a time trigger polls **one Telegram bot** (private chat, admin `749369573` only), appends messages to a **Google Sheet**, and `doGet()` serves a JSON feed. URL goes in gitignored `app_config.dart` `bookContentApiUrl`. **Never deployed for this app** (placeholder token — CLAUDE.md). `google_apps_script/life_plan_sync.gs` is a second Apps Script (life-plan ↔ Sheet). |
| Layering | `lib/models` · `lib/repositories` (one per feature, over `DatabaseHelper`) · `lib/services` · `lib/screens`. `basicText()` i18n, 13 languages, RTL-first. |
| Sync model | Offline-first. The only "live" data is turath.io (read) and the (unwired) Apps-Script content feed (read). Nothing writes to a server. |

**Conclusion:** the app has **no multi-user backend, no hosted database, no
auth**. The mosque platform needs all three (many mosques, many admins,
moderation, verification, content every app user reads). CLAUDE.md already
flags this as "a real architecture shift... needs an explicit infra
decision before it starts." **That decision is the Phase-1 blocker.**

---

## 2. The proposed Mosque Architecture (backend-agnostic)

```
Super Admin ─► Intake (Telegram bot OR n8n) ─► Backend API ─► Database ◄─ Flutter (read)
                                                    │
                                    mosque_id is the permanent identity
```

### 2.1 Entities (minimal start — do NOT create 15 tables up front)

- `mosques` — `id (MOSQ_000001)`, `name`, `imam_name`, `description`,
  `city`, `area`, `lat`, `lng`, `phone`, `image_url`, `verified (bool)`,
  `status (pending|active|suspended)`, `created_at`.
- `users` — real accounts now (needed for roles). `id`, `display_name`,
  `telegram_user_id?`, `created_at`.
- `mosque_users` — `mosque_id`, `user_id`, `role
  (owner|imam|moderator|viewer)`. (Super Admin is global, not per-mosque.)
- `mosque_telegram_connections` — `mosque_id`, `chat_id`, `group_title`,
  `connected_at`. **`chat_id` is NOT the mosque identity** — a group can be
  swapped; only `mosque_id` is permanent.
- `mosque_sections` — `mosque_id`, `type`, `title`, `icon`, `enabled`,
  `sort_order`, `permissions`. Data-driven visibility (no children's circle
  → no icon; donations show only when verified).
- `mosque_content` — `mosque_id`, `type (lesson|khutbah|announcement|
  library|recording|activity|need|…)`, `title`, `description`, `media_url`,
  `created_by`, `status (draft|pending|approved|published|rejected)`,
  `risk_tier (auto|review|mandatory)`, `created_at`. New sections later =
  new `type`, no app rebuild.
- `activities` + `activity_media` — activities are richer (date, start/end,
  location, organizer, status `upcoming→ongoing→ended→archived`, photos), so
  they get their own table, not `mosque_content`.
- `mosque_media` — `mosque_id`, `category (mosque|circle|activity|project|
  event)`, `activity_id?`, `url`, `uploaded_by`, `date`. **Photos never mix
  with lessons/announcements.**
- `pending_changes` — the daily change box per mosque.
- `moderation_actions` — audit log of approvals/rejections.

### 2.2 Backend API (shape, not implementation)

```
POST/GET/PATCH  /mosques            /mosques/:id
GET/POST        /mosques/:id/activities   /mosques/:id/media
GET/POST        /mosques/:id/announcements /mosques/:id/lessons
GET/POST        /mosques/:id/recordings   /mosques/:id/khutbahs
GET/POST        /mosques/:id/circles      /mosques/:id/needs
GET             /mosques/:id/sections     (drives the Flutter template)
POST            /mosques/:id/changes/:cid/approve | /reject
GET             /admin/daily-review
```
Intake (bot/n8n) and Flutter both go through this API. Nothing writes the
DB directly.

### 2.3 Flutter — ONE `MosqueProfileScreen(mosqueId)`

New under `lib/screens/mosque/`: `MosquesScreen` (list + search + nearby +
مسجدي), `MosqueCard`, `MosqueProfileScreen` (header + per-module curated
previews + services grid), then one screen per module. New
`lib/repositories/mosque_repository.dart` + `lib/services/mosque_api_client.dart`
(mirrors the `turath_api_client` / `TurathRepository` split). **Zero
hardcoded mosque data; no `if (mosque == "...")`; no per-mosque screen.**
Local `sqflite` is used only as a **read cache** of API responses so the
list/last-viewed mosque work offline; the API is the source of truth for
mosque data (mirrors the existing "API is never Qur'anic truth, local wins
for Qur'an" rule, inverted here: server wins for mosque data).

### 2.4 Moderation flow

`Draft → Pending Review → Approved → Published` (or `Rejected`). Daily
batch per mosque; ~22:00 report to Super Admin → `[Publish all] [Review]
[Reject]`. Risk tiers: `auto` (activity photos, time tweaks) · `review`
(announcements, lessons, recordings) · `mandatory` (donations, money needs,
mosque info / imam change). After approval the DB row goes `published`;
Flutter queries `published` rows for that `mosque_id`.

---

## 3. THE Phase-1 decision — infra (needs Ismail)

Everything else is settled; this one gates the build.

### Option A — extend what exists (Apps Script + Google Sheets + 1 bot)
- **Ismail (2026-09-02):** wants to **reuse the existing Telegram relay bot**
  (`telegram_relay/Code.gs`, `@talib_alilm_adhkar_bot`) for the mosque
  platform if possible — so at minimum the intake bot is shared, even under
  Option B (the bot posts to whichever backend we pick).
- **How:** a bigger `Code.gs`; Sheets tabs as tables (`mosques`, `content`,
  `pending`, …); the bot is the only intake; Flutter reads `doGet()` JSON.
- **Pros:** free, zero server ops, Ismail already runs this pattern,
  deployable this week.
- **Cons:** Sheets is not a database — no real queries/joins, fragile
  concurrent writes, ~hundreds-of-rows ceiling before it drags, media
  hosting awkward (Drive links leak the bot token — see `DEPLOY.md`), no
  row-level permissions, hard to add real user auth. Fine for a **pilot of
  1–20 mosques**, not for "1,000 → 100,000".

### Option B — a real lightweight backend (recommended for the stated goal)
- **How:** **Supabase** (managed Postgres + auth + storage + row-level
  security + auto REST/realtime, generous free tier) as DB+API+media;
  **n8n** (Phase-2 decision) or a small bot service for Telegram intake +
  the daily-approval automation, calling Supabase.
- **Pros:** real schema/queries, proper media buckets, real roles via RLS,
  scales to thousands of mosques, offline cache stays trivial in `sqflite`.
- **Cons:** a new dependency + eventually a small monthly cost past the free
  tier; ~1–2 days to stand up; one more dashboard to hand a successor
  (documented in `/docs`).

**Recommendation:** **B**, because the vision is explicitly "1 → 10 → 1,000
→ 100,000 mosques" and a صدقة جارية that outlives the founder — Sheets can't
carry that, and starting on A means a painful migration later. Use A only if
the real intent is a small permanent pilot.

---

## 4. n8n — deferred to Phase 2 (per Ismail), criteria to decide then

Evaluate n8n vs a small custom bot service on: (1) can it hold the
per-mosque daily-change state + the 22:00 report cleanly; (2) Telegram
group/permission handling; (3) who can maintain it after Ismail
(no-code favors n8n); (4) hosting (n8n cloud vs self-host) and cost;
(5) does it call the API cleanly without business logic leaking into
workflow nodes. Whatever wins, it talks to the **Backend API only**, never
the DB, never Flutter.

---

## 4b. Built so far (2026-09-02) — Phase 3 + Phase 5, local-first

Real, tested code that does NOT wait on the infra decision — it works
offline against a seeded demo mosque and becomes the read-cache for
whichever backend wins:

- **Schema v53** (`database_helper.dart` `_createV53Tables`): `mosques`,
  `mosque_sections`, `mosque_content` (polymorphic — `kind` + event
  columns), `mosque_media`, `mosque_meta`. Lean on purpose.
- **Models** `lib/models/mosque.dart` — `Mosque`, `MosqueSection`,
  `MosqueContent`, `MosqueMediaItem`, `MosqueProfile`, `MosqueContentKind`.
- **`MosqueRepository`** — directory + search + `مسجدي` (single exclusive)
  + per-section content + `profile()` (one read) + `syncFromApi()` (inert
  now) + seeds one demo mosque if empty.
- **`MosqueApiClient`** seam — `LocalOnlyMosqueApi` (inert) today; a
  `SupabaseMosqueApi` / `AppsScriptMosqueApi` drops in later, no caller
  changes.
- **UI** `lib/screens/mosque/`: `MosquesScreen` (list + search + مسجدي),
  **one** `MosqueProfileScreen(mosqueId)` (header + directions/contact +
  per-section curated previews + services grid), `MosqueContentListScreen`
  ("عرض الكل"), `MosqueContentDetailScreen` (audio player for
  `media_kind='audio'`, attachment open otherwise). **Zero hardcoded mosque
  data.** Home-screen tile added.
- 25 i18n keys × 13 languages. 4 repo tests. `flutter analyze` clean, all
  444 tests pass, APK builds.

What is NOT built (needs the infra decision): the backend itself, the
Telegram/n8n intake, verification/approval, real accounts/roles, media
hosting, `syncFromApi`'s concrete transport.

## 5. Phase-2 plan (only after the infra decision)

Design the concrete schema + API contract for the chosen backend, the
`mosque_sections` seed, the risk-tier policy table, and the n8n-vs-bot
decision with a recommendation — presented before any code. Then Phases
3–12 from `MOSQUE_PLATFORM_VISION.md`, one at a time, each self-documented
under `docs/mosque/`.
