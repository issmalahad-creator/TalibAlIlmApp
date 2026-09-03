# «مساجدنا» — going live on Supabase (Phase 74)

The app's read path, models, RLS design and the seed data are all built.
Bringing the backend online is three actions in the Supabase dashboard plus
one verification command.

## 0. Security (once)

- The **DB password** and any **`service_role` / `sb_secret_…`** key must
  never be pasted into chat, a doc, the app, or git. If one ever is,
  **rotate it** (Dashboard → Settings → Database → Reset for the password;
  Settings → API → rotate for keys).
- `tool/check_secrets.sh` (+ `.githooks/pre-commit`) blocks credential
  shapes from commits. Enable the hook once per clone:
  `git config core.hooksPath .githooks`.
- `lib/config/app_config.dart` is gitignored and holds **only** the project
  URL + the **publishable** key (`sb_publishable_…`). Those are safe to ship
  — RLS gates the data.

## 1. Apply the schema  (Dashboard → SQL Editor → Run)

Paste **all** of `docs/mosque/supabase_schema.sql` and run it. It is
idempotent (`create … if not exists`, `on conflict do nothing`,
`drop policy if exists`) — safe to re-run after edits.

It creates: `mosques`, `mosque_sections`, `mosque_content`, `mosque_media`
(public-readable via RLS: non-suspended mosque + `status='published'`
content only, **no** client writes) and the admin-only write-path tables
`super_admins`, `mosque_users`, `mosque_telegram_connections`,
`mosque_pending_changes`, `mosque_moderation_log` (RLS on, **no** policies →
the anon key has zero access; the intake writes with `service_role`). It
also seeds one pilot mosque (`MOSQ_PILOT_0001` — مسجد التقوى) with sections
and content so the app shows real data immediately.

## 2. Confirm the app's key

`lib/config/app_config.dart` should already have:

```dart
static const supabaseUrl     = 'https://smjvkprdnduakavcyubw.supabase.co';
static const supabaseAnonKey  = 'sb_publishable_…';   // publishable key only
```

If the project or its keys changed, update these (URL from Settings → API,
key = the **publishable** one). Never put the secret key here.

## 3. Verify

```sh
sh tool/mosque_probe.sh
```

All PASS → `MosqueRepository` reads the backend live (offline‑first: it
mirrors rows into the local sqflite cache, one background sync per run).
Then open the app → **المساجد** tile → مسجد التقوى should load from Supabase.

## 4. Next (the write path — separate build)

The Telegram intake as a **Supabase Edge Function** (`mosque-intake`):
webhook → `chat_id → mosque_id` (`mosque_telegram_connections`) → role
check (`super_admins` / `mosque_users`, tiers per TODO 74.7) → proposed
changes land in `mosque_pending_changes` by `risk_tier` → a daily digest
message to the Super Admin (74.8). The function reads `SERVICE_ROLE_KEY`
and `TELEGRAM_BOT_TOKEN` from its **Supabase function env** — never the app,
never git. Deployed with the `supabase` CLI.
