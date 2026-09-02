# «مساجدنا» — Mosque Platform Vision

**Status: VISION CAPTURED — NOT APPROVED FOR BUILD.** Roadmap Phase 74.
Ismail pasted this in full on 2026-09-02; this file preserves it so the
plan survives past any one chat. First code only after an explicit "go" and
a Phase-1 (read-only) exploration.

> Golden rule (Ismail): **One Mosque UI template → unlimited mosques.** The
> Flutter app contains exactly **one** reusable `MosqueProfileScreen`, an
> instance per `mosqueId`. No mosque-specific data, names, IDs, icons, or
> sections are ever hardcoded or duplicated in Dart. When the Telegram bot
> (or n8n) creates a mosque, the backend creates the record + assigns a
> `mosqueId`; the existing template renders it. Claude must never create new
> Dart screens per mosque.

## Why

Ismail wants the app to serve real mosques (a صدقة جارية he can hand off).
Not a "mosque page" — a **digital platform for mosques** inside the app:
user ↔ mosque ↔ community. Each mosque is an independent entity, verified
before it goes live, managed from Telegram, rendered by one Flutter
template.

## Architecture

```
👑 Super Admin  ──►  🤖 Telegram Bot / n8n  ──►  🧠 Backend API  ──►  🗄️ Database
                                                        │
                        ┌───────────────────────────────┼───────────────────────────────┐
                     🕌 MOSQ_0001                    🕌 MOSQ_0002                    🕌 MOSQ_0003
                    Telegram group                  Telegram group                  Telegram group
                        └───────────────────────────────┼───────────────────────────────┘
                                                        ▼
                                                  📱 Flutter (one MosqueProfileScreen)
                                                        │
                                              👤 users / "مسجدي" / "مساجدنا"
```

- **Database is the source of truth**, never Telegram. A mosque's Telegram
  group can change; `mosqueId` is permanent. `mosque_telegram_connections`
  maps `chat_id → mosque_id`, so the bot knows which mosque a message
  belongs to. Re-link a new group to the same `mosqueId` and nothing else
  moves.
- **One bot**, many mosque "spaces" — never one bot per mosque.
- **n8n** (Ismail's mention, 2026-09-02): candidate for the automation
  layer — the Telegram intake, the daily change-batching, the end-of-day
  approval report, the "publish all" → API calls. To be evaluated against a
  custom bot service in Phase 2. Either way it talks to the **Backend API**,
  never the DB directly, and never touches Flutter.

## Flutter — `MosqueProfileScreen(mosqueId)`

Structured **modular** page, not one long mixed feed. Header (image, name,
imam, city, verified badge, نبذة, location/directions), then curated
**previews** per module with "View All" → the module's own page:

`📸 Gallery · 📅 Activities & Events · 📢 Announcements · 📚 Lessons ·
🕌 Friday Khutbahs · 🎙️ Audio Recordings · 📚 Library · 👨‍🏫 Quran Circles ·
👶 Children Programs · 🧑‍🎓 Knowledge Programs · 📅 Weekly Schedule ·
❤️ Mosque Needs · 💰 Donations · 📊 Achievements & Statistics ·
📍 Location & Directions`

Every content type = its own model, table, UI component, route,
permissions, workflow. **Never mix content types** in one component or one
table. Sections are **data-driven** (`mosque_sections`: type, title, icon,
enabled, sort_order, permissions) — a mosque with no children's circle just
doesn't show that icon; donations show only when verified.

The `مساجدنا` list: search by name, nearby (location permission), and
`مسجدي` (the user picks their mosque → it feeds their daily view:
prayer times, after-fajr circle, tonight's lesson, admin announcement,
Friday khutbah). Logically separate from the Quran/prayer core.

## Roles & moderation

- **Super Admin**: create/approve/reject/verify/suspend mosque, review &
  publish content, manage admins, transfer administration (succession — so
  the project isn't tied to one person).
- **Mosque Owner** → mosque info, all content, submit for review, admins.
- **Imam** → lessons, khutbahs, recordings, Quran, religious announcements.
- **Moderator** → activities, photos, announcements, schedule.
- **User** → view only.

**Daily change box** per mosque: edits queue as `Draft → Pending Review`.
At ~22:00 the Super Admin gets one report (`📸 18 · 📅 2 · 📢 3 · 📚 1 ·
🎙️ 1`) → `[Publish all] [Review] [Reject]`. Risk tiers:
`🟢 auto-publishable` (activity photos, time tweaks) · `🟡 needs review`
(announcements, lessons) · `🔴 mandatory review` (donations, money needs,
mosque info / imam changes).

Creating a mosque: bot Q&A → `mosqueId` generated → `🟡 Pending
Verification`, not public → Super Admin approves → published. Then link the
Telegram group.

## Minimal starting schema (do not build 15+ tables up front)

`users · mosques · mosque_users · mosque_telegram_connections ·
mosque_sections · mosque_content · activities · activity_media ·
mosque_media · pending_changes · moderation_actions`

`mosque_content`: `mosque_id, type (lesson|khutbah|announcement|library|
recording|activity|need|…), title, description, media_url, created_by,
status (draft|pending|approved|published|rejected), created_at`. New
sections later = new `type`, no app rebuild.

## Secrets & continuity

Bot token, DB keys, payment keys → Secret Manager, never in docs. Docs name
the secret (`TELEGRAM_BOT_TOKEN`), not its value. Automatic DB backups
(daily/weekly/monthly) + a written recovery runbook. A `/docs` set
(`00_PROJECT_OVERVIEW … 12_TROUBLESHOOTING`, `CHANGELOG`) that documents
**why**, not just how — written as each feature is built, so a non-programmer
can operate it and another developer can maintain it without asking Ismail
what he intended.

## Phased build order (when approved)

1. Explore current app (Flutter, backend, DB, auth) — **no code changes**.
2. Design Mosque Architecture (entities + relations) + evaluate n8n vs
   custom bot — present before coding.
3. Database + relations.
4. Backend API (`/mosques`, `/mosques/:id/activities`, `/mosques/:id/media`,
   …).
5. Flutter Mosque Template (`MosquesScreen`, `MosqueCard`,
   `MosqueProfileScreen`, header + module previews + services grid).
6. Module pages (Gallery, Activities, …) — one at a time.
7. Telegram/n8n intake — after the API is real.
8. `chat_id → mosque_id` linking.
9. Roles & permissions.
10. Draft → review → publish workflow.
11. Daily review report.
12. **One test mosque end-to-end**, then open to more.

## Hard "do NOT" list

No per-mosque Flutter screen or duplicated UI. No mosque data in Dart. No
hardcoded mosque name / `if (mosque == "...")`. Bot/n8n never runs SQL
directly or edits Flutter. Not everyone can create a mosque. Not every
group member can publish. No donations without verification + approval.
Don't mix photos/activities/lessons in one table. Don't put everything on
one screen. Telegram is not the database. Not one bot per mosque.
