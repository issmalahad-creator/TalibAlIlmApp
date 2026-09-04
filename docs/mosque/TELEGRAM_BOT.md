# «مساجدنا» — Telegram bot (Phase 74.5, v1)

`supabase/functions/mosque-intake/index.ts` is the whole backend for this:
one Supabase Edge Function, no separate server. **v1 scope is deliberately
small** — Ismail is the only admin today, so the bot writes content
directly (`status='published'`) instead of building the full
`mosque_pending_changes` / risk-tier / daily-digest review workflow from
`docs/MOSQUE_PLATFORM_VISION.md`. That workflow is real and designed; build
it once there are actually multiple mosques/admins who need review.

## Deploy (once, from Ismail's machine)

Needs the [Supabase CLI](https://supabase.com/docs/guides/cli) installed
and logged in (`supabase login`), and the project linked
(`supabase link --project-ref smjvkprdnduakavcyubw`).

```sh
cd /f/TalibAlIlmApp
supabase functions deploy mosque-intake --no-verify-jwt
```

`--no-verify-jwt` is required — Telegram's webhook calls this URL directly,
with no Supabase auth header, so the platform's default JWT check would
reject every request. The function is protected instead by the
`TELEGRAM_WEBHOOK_SECRET` check described below.

## Secrets (Dashboard → Edge Functions → Secrets — never in chat, never in git)

| Name | Value | Required |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | from `@BotFather` | yes |
| `TELEGRAM_WEBHOOK_SECRET` | any random string you make up (e.g. 32 random characters) | recommended |

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided automatically
to every deployed Edge Function — do **not** add them yourself.

## Register the webhook (once, after deploying)

Run this with `curl` — replace `<TOKEN>` with the real bot token and
`<SECRET>` with the same string you put in `TELEGRAM_WEBHOOK_SECRET` above.
Run it from your own terminal, never paste the filled-in command anywhere
public (it contains the live token in the URL):

```sh
curl -X POST "https://api.telegram.org/bot<TOKEN>/setWebhook" \
  -H "content-type: application/json" \
  -d '{
    "url": "https://smjvkprdnduakavcyubw.supabase.co/functions/v1/mosque-intake",
    "secret_token": "<SECRET>"
  }'
```

A reply with `"ok":true` means Telegram will now POST every message the bot
receives to the function. Check it any time with:

```sh
curl "https://api.telegram.org/bot<TOKEN>/getWebhookInfo"
```

## Using it (Telegram, after deploy)

1. Message the bot (`t.me/talib_alilm_adhkar_bot`) with `/start` — the
   *first* person to ever do this becomes the super_admin automatically.
   Do this yourself, first, right after deploying.
2. `/link` — links this chat to a mosque. With only one active mosque
   today it links automatically; once there's more than one it will ask
   you to pick by id (`/link MOSQ_PILOT_0001`).
3. Add content:
   ```
   /add lesson
   العنوان: تفسير سورة آل عمران
   الوصف: درس أسبوعي بعد صلاة العشاء
   المكان: قاعة المسجد
   ```
   `kind` is one of `lesson | khutbah | announcement | recording | library
   | need | activity` (the same set the app already renders — see
   `MosqueContentKind` in `lib/models/mosque.dart`). `المكان` is optional.
4. `/list lesson` — see the last 10 items in a section with their ids.
5. `/pin <id>` / `/delete <id>` — pin or remove one item.
6. `/mymosque` — which mosque this chat currently manages.
7. `/help` — the command list, any time.

The app already reads Supabase live, so anything added here appears in
«مساجدنا» on the next open (offline‑first cache mirrors it in the
background — see `MosqueRepository.syncFromApi`).

## Not built yet (intentionally deferred)

- Per-mosque roles via Telegram (`mosque_users` — imam/moderator/owner)
  and multi-mosque group chats. Everything in v1 assumes the super_admin
  is managing the mosque directly.
- The daily digest / pending-review queue (`mosque_pending_changes`,
  `mosque_moderation_log`) — needed once content comes from people who
  shouldn't publish unreviewed (a new imam, a volunteer).
- Photos/audio via Telegram file uploads (`mosque_media`, `media_url` on
  recordings) — v1 is text-only; a photo/voice message handler that calls
  Telegram's `getFile` and re-hosts the file is a natural v2 addition.
- `/edit` for an existing item (today: `/delete` + `/add` again).
