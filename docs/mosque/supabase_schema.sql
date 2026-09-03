-- «مساجدنا» — Supabase schema for the one-mosque pilot (Phase 74).
-- Run ONCE in the Supabase dashboard → SQL Editor → paste → Run.
-- Mirrors the app's local v53 cache tables. The app reads with the
-- publishable (anon) key; Row-Level Security below makes that safe by
-- exposing only published / active rows and forbidding all client writes.
-- Writes happen later from the Telegram/n8n intake using the service_role
-- key (which bypasses RLS) — never from the app.

-- ── tables ──────────────────────────────────────────────────────────
create table if not exists public.mosques (
  id           text primary key,          -- 'MOSQ_000001'
  name         text not null,
  imam_name    text,
  description  text,
  city         text,
  area         text,
  lat          double precision,
  lng          double precision,
  phone        text,
  image_url    text,
  verified     boolean not null default false,
  status       text not null default 'active',   -- active | pending | suspended
  created_at   timestamptz not null default now()
);

create table if not exists public.mosque_sections (
  id          bigint generated always as identity primary key,
  mosque_id   text not null references public.mosques(id) on delete cascade,
  type        text not null,               -- lesson|khutbah|announcement|recording|library|need|activity
  title       text not null,
  icon        text,
  enabled     boolean not null default true,
  sort_order  int not null default 0,
  unique (mosque_id, type)
);

create table if not exists public.mosque_content (
  id           text primary key,
  mosque_id    text not null references public.mosques(id) on delete cascade,
  kind         text not null,
  title        text,
  description  text,
  media_url    text,
  media_kind   text,                       -- audio|pdf|video|image|link
  event_date   text,
  starts_at    text,
  ends_at      text,
  location     text,
  organizer    text,
  status       text not null default 'published',  -- draft|pending|approved|published|rejected
  pinned       boolean not null default false,
  created_by   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists idx_mosque_content_mosque_kind
  on public.mosque_content (mosque_id, kind, status);

create table if not exists public.mosque_media (
  id          text primary key,
  mosque_id   text not null references public.mosques(id) on delete cascade,
  category    text not null,               -- mosque|circle|activity|project|event
  content_id  text,
  url         text not null,
  caption     text,
  date        text
);

-- ── Row-Level Security: public may READ safe rows only, never write ──
alter table public.mosques         enable row level security;
alter table public.mosque_sections enable row level security;
alter table public.mosque_content  enable row level security;
alter table public.mosque_media    enable row level security;

drop policy if exists "public read active mosques" on public.mosques;
create policy "public read active mosques" on public.mosques
  for select using (status <> 'suspended');

drop policy if exists "public read sections" on public.mosque_sections;
create policy "public read sections" on public.mosque_sections
  for select using (
    enabled and exists (
      select 1 from public.mosques m
      where m.id = mosque_id and m.status <> 'suspended'));

drop policy if exists "public read published content" on public.mosque_content;
create policy "public read published content" on public.mosque_content
  for select using (
    status = 'published' and exists (
      select 1 from public.mosques m
      where m.id = mosque_id and m.status <> 'suspended'));

drop policy if exists "public read media" on public.mosque_media;
create policy "public read media" on public.mosque_media
  for select using (
    exists (select 1 from public.mosques m
            where m.id = mosque_id and m.status <> 'suspended'));

-- No INSERT / UPDATE / DELETE policies → the anon key cannot write.
-- The intake writes with the service_role key, which bypasses RLS.

-- ── write-path / admin tables (Phase 74.2c–e · 74.5–74.8) ───────────
-- These are ADMIN-ONLY: RLS is enabled with NO policies, so the anon key
-- can neither read nor write them. Only the Telegram-intake Edge Function
-- (service_role, bypasses RLS) touches these.

-- global operators — the "everything, incl. mosque approval" tier
create table if not exists public.super_admins (
  tg_user_id  text primary key,
  name        text,
  added_at    timestamptz not null default now()
);

-- who may do what, per mosque
create table if not exists public.mosque_users (
  id          bigint generated always as identity primary key,
  mosque_id   text not null references public.mosques(id) on delete cascade,
  tg_user_id  text not null,
  tg_username text,
  role        text not null,   -- mosque_owner | imam | moderator | viewer
  added_by    text,
  created_at  timestamptz not null default now(),
  unique (mosque_id, tg_user_id)
);

-- the durable link: mosque_id is permanent, chat_id can change (74.5)
create table if not exists public.mosque_telegram_connections (
  mosque_id     text primary key references public.mosques(id) on delete cascade,
  chat_id       text not null unique,
  group_title   text,
  linked_by     text,
  connected_at  timestamptz not null default now()
);

-- every submitted change waits here for the daily digest (74.8)
create table if not exists public.mosque_pending_changes (
  id            text primary key,
  mosque_id     text not null references public.mosques(id) on delete cascade,
  content_id    text,
  action        text not null,          -- create | update | delete | link | donation_toggle | ...
  payload       jsonb,                  -- the proposed row
  risk_tier     text not null default 'medium',   -- low | medium | high
  status        text not null default 'pending',  -- pending | approved | rejected | auto_published
  submitted_by  text,
  submitted_at  timestamptz not null default now(),
  reviewed_by   text,
  reviewed_at   timestamptz,
  note          text
);
create index if not exists idx_pending_mosque_status
  on public.mosque_pending_changes (mosque_id, status, submitted_at);

-- an append-only audit trail of every approve/reject (74.9)
create table if not exists public.mosque_moderation_log (
  id          bigint generated always as identity primary key,
  mosque_id   text,
  change_id   text,
  actor       text,
  decision    text,                     -- approved | rejected | auto_published | promoted | linked
  detail      text,
  at          timestamptz not null default now()
);

alter table public.super_admins                  enable row level security;
alter table public.mosque_users                  enable row level security;
alter table public.mosque_telegram_connections   enable row level security;
alter table public.mosque_pending_changes        enable row level security;
alter table public.mosque_moderation_log         enable row level security;
-- (no policies on purpose → anon has zero access; service_role bypasses RLS)

-- ── one pilot mosque so the app shows real data immediately ─────────
-- مسجد التقوى (Taqwa mesjid) — Addis Ababa · XPC8+6W9 · 9.0079232,38.7678208
-- الإمام: الشيخ عبد الجليل  (from Ismail's Google Maps pin, 2026-09-04)
insert into public.mosques (id, name, imam_name, description, city, area, lat, lng, verified, status)
values ('MOSQ_PILOT_0001', 'مسجد التقوى', 'الشيخ عبد الجليل',
        'أول مسجد في «مساجدنا» — تُدار محتوياته من تيليجرام وتُراجَع قبل النشر.',
        'أديس أبابا', 'أديس أبابا', 9.0079232, 38.7678208, true, 'active')
on conflict (id) do nothing;

-- re-running the script keeps `on conflict do nothing` above harmless but
-- still refreshes the pilot's editable fields:
update public.mosques set
  name       = 'مسجد التقوى',
  imam_name  = 'الشيخ عبد الجليل',
  city       = 'أديس أبابا',
  area       = 'أديس أبابا',
  lat        = 9.0079232,
  lng        = 38.7678208,
  verified   = true,
  status     = 'active'
where id = 'MOSQ_PILOT_0001';

insert into public.mosque_sections (mosque_id, type, title, sort_order) values
  ('MOSQ_PILOT_0001','lesson','الدروس والمحاضرات',0),
  ('MOSQ_PILOT_0001','recording','التسجيلات الصوتية',1),
  ('MOSQ_PILOT_0001','khutbah','خطبة الجمعة',2),
  ('MOSQ_PILOT_0001','announcement','الإعلانات',3),
  ('MOSQ_PILOT_0001','activity','الأنشطة والفعاليات',4),
  ('MOSQ_PILOT_0001','library','مكتبة المسجد',5),
  ('MOSQ_PILOT_0001','need','احتياجات المسجد',6)
on conflict (mosque_id, type) do nothing;

insert into public.mosque_content (id, mosque_id, kind, title, description, location, media_kind) values
  ('MC_PILOT_L1','MOSQ_PILOT_0001','lesson','تفسير سورة البقرة','درس أسبوعي بعد المغرب — الشيخ أحمد.','قاعة المسجد',null),
  ('MC_PILOT_L2','MOSQ_PILOT_0001','lesson','شرح الأربعين النووية','كل خميس بعد العشاء.','المصلى الرئيسي',null),
  ('MC_PILOT_K1','MOSQ_PILOT_0001','khutbah','خطبة: الإخلاص في العمل','ملخص خطبة الجمعة مع رابط التسجيل.',null,'audio'),
  ('MC_PILOT_A1','MOSQ_PILOT_0001','announcement','حملة تنظيف المسجد','السبت بعد الفجر — نرحّب بالجميع.',null,null),
  ('MC_PILOT_AC1','MOSQ_PILOT_0001','activity','مسابقة حفظ القرآن للأطفال','الجمعة بعد العصر — جوائز قيّمة.','ساحة المسجد',null),
  ('MC_PILOT_R1','MOSQ_PILOT_0001','recording','محاضرة: بر الوالدين','تسجيل صوتي كامل.',null,'audio'),
  ('MC_PILOT_N1','MOSQ_PILOT_0001','need','سجّاد جديد للمصلى','الحاجة قيد التوثيق من الإدارة.',null,null)
on conflict (id) do nothing;
