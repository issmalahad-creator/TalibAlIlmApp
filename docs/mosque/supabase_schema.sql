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
-- مسجد التوفيق (Tofik mesjid) — Addis Ababa · XP59+Q49 · 9.0177536,38.7579904
-- corrected 2026-09-04: Ismail's first pin/name ("مسجد التقوى") was wrong;
-- this is the real place from his Google Maps link, resolved via the
-- place's own preview-API payload (not the redirect's viewport `center`,
-- which drifted between fetches) — Amharic name on the pin: «ቶፊቅ መስጂድ».
-- imam_name is a clearly-placeholder value; Ismail will replace every
-- placeholder below with the mosque's real programme once he has it.
insert into public.mosques (id, name, imam_name, description, city, area, lat, lng, verified, status)
values ('MOSQ_PILOT_0001', 'مسجد التوفيق', 'إمام المسجد (بيانات مبدئية)',
        'مسجد التوفيق — يُعرف بالأمهرية باسم «ቶፊቅ መስጂድ». هذا مثال كامل بمحتوى '
        'افتراضي يوضّح كل ما تقدّمه «مساجدنا»: دروس وخطب وتسجيلات ومكتبة '
        'واحتياجات وأنشطة وصور — سيُستبدل بالبيانات الحقيقية للمسجد لاحقًا.',
        'أديس أبابا', 'أديس أبابا', 9.0177536, 38.7579904, true, 'active')
on conflict (id) do nothing;

-- re-running the script keeps `on conflict do nothing` above harmless but
-- still refreshes the pilot's editable fields:
update public.mosques set
  name        = 'مسجد التوفيق',
  imam_name   = 'إمام المسجد (بيانات مبدئية)',
  description = 'مسجد التوفيق — يُعرف بالأمهرية باسم «ቶፊቅ መስጂድ». هذا مثال كامل بمحتوى '
                 'افتراضي يوضّح كل ما تقدّمه «مساجدنا»: دروس وخطب وتسجيلات ومكتبة '
                 'واحتياجات وأنشطة وصور — سيُستبدل بالبيانات الحقيقية للمسجد لاحقًا.',
  city        = 'أديس أبابا',
  area        = 'أديس أبابا',
  lat         = 9.0177536,
  lng         = 38.7579904,
  verified    = true,
  status      = 'active'
where id = 'MOSQ_PILOT_0001';

-- a full worked example (2026-09-04, Ismail: "استغل كل ميزات مساجدنا في
-- مثال كامل بمعلومات افتراضية") — clear the pilot's old placeholder
-- content/media first so re-running this script always leaves exactly
-- this example, never a mix of two content sets. Safe: MOSQ_PILOT_0001 is
-- the pilot/demo mosque, not a mosque with real moderated submissions yet.
delete from public.mosque_content where mosque_id = 'MOSQ_PILOT_0001';
delete from public.mosque_media   where mosque_id = 'MOSQ_PILOT_0001';

insert into public.mosque_sections (mosque_id, type, title, sort_order) values
  ('MOSQ_PILOT_0001','lesson','الدروس والمحاضرات',0),
  ('MOSQ_PILOT_0001','recording','التسجيلات الصوتية',1),
  ('MOSQ_PILOT_0001','khutbah','خطبة الجمعة',2),
  ('MOSQ_PILOT_0001','announcement','الإعلانات',3),
  ('MOSQ_PILOT_0001','activity','الأنشطة والفعاليات',4),
  ('MOSQ_PILOT_0001','library','مكتبة المسجد',5),
  ('MOSQ_PILOT_0001','need','احتياجات المسجد',6)
on conflict (mosque_id, type) do nothing;

insert into public.mosque_content (id, mosque_id, kind, title, description, location, media_kind, media_url, pinned) values
  ('MC_TOFIK_L1','MOSQ_PILOT_0001','lesson','تفسير جزء عمّ','درس أسبوعي بعد صلاة المغرب، كل ثلاثاء — للرجال والنساء.','قاعة المسجد',null,null,true),
  ('MC_TOFIK_L2','MOSQ_PILOT_0001','lesson','حلقة تحفيظ القرآن للمبتدئين','من السبت إلى الخميس، بعد صلاة العصر.','الطابق العلوي',null,null,false),
  ('MC_TOFIK_K1','MOSQ_PILOT_0001','khutbah','خطبة: حسن الخلق مع الجيران','ملخص خطبة الجمعة الماضية مع رابط الاستماع الكامل.',null,'audio',null,true),
  ('MC_TOFIK_K2','MOSQ_PILOT_0001','khutbah','خطبة: بر الوالدين','خطبة الجمعة، مسجّلة كاملة.',null,'audio',null,false),
  ('MC_TOFIK_A1','MOSQ_PILOT_0001','announcement','صلاة التراويح تبدأ هذا الأسبوع','تُقام بعد صلاة العشاء مباشرة — نرحّب بالجميع.',null,null,null,true),
  ('MC_TOFIK_A2','MOSQ_PILOT_0001','announcement','تنبيه: تحديث مؤقت لموعد صلاة الفجر','بسبب توقيت الشروق هذا الشهر — راجع اللوحة عند المدخل.',null,null,null,false),
  ('MC_TOFIK_R1','MOSQ_PILOT_0001','recording','محاضرة: فقه الصيام','تسجيل صوتي كامل لمحاضرة رمضانية.',null,'audio',null,false),
  ('MC_TOFIK_R2','MOSQ_PILOT_0001','recording','محاضرة: قصص الأنبياء للأطفال','حلقة مبسّطة للأطفال، بصوت واضح وهادئ.',null,'audio',null,false),
  ('MC_TOFIK_LIB1','MOSQ_PILOT_0001','library','رياض الصالحين (نسخة إلكترونية)','نسخة PDF متاحة للتحميل من مكتبة المسجد.',null,'pdf',null,false),
  ('MC_TOFIK_LIB2','MOSQ_PILOT_0001','library','حصن المسلم — أذكار وأدعية','نسخة مصوَّرة، مناسبة للطباعة.',null,'pdf',null,false),
  ('MC_TOFIK_N1','MOSQ_PILOT_0001','need','تبريد المصلى الرئيسي','الحاجة إلى مكيّفات هواء قبل فصل الصيف — قيد التوثيق من الإدارة.',null,null,null,true),
  ('MC_TOFIK_N2','MOSQ_PILOT_0001','need','صيانة الواجهة الخارجية','طلاء وإصلاحات بسيطة للواجهة والسور.',null,null,null,false),
  ('MC_TOFIK_AC1','MOSQ_PILOT_0001','activity','يوم مفتوح لتعريف الجيران بالمسجد','جولة قصيرة وشرح لدور المسجد في الحي.','ساحة المسجد',null,null,false),
  ('MC_TOFIK_AC2','MOSQ_PILOT_0001','activity','دورة الوضوء والصلاة للأطفال','دورة عملية قصيرة كل جمعة بعد العصر.','المصلى الرئيسي',null,null,true)
on conflict (id) do nothing;

-- 📸 gallery — free placeholder photos (picsum.photos, stable/no-auth) so
-- the profile's gallery strip + full-screen viewer have something real to
-- render; swap for the mosque's actual photos whenever they're available.
insert into public.mosque_media (id, mosque_id, category, url, caption, date) values
  ('MM_TOFIK_1','MOSQ_PILOT_0001','mosque','https://picsum.photos/seed/tofik-facade/900/700','الواجهة الخارجية للمسجد',null),
  ('MM_TOFIK_2','MOSQ_PILOT_0001','mosque','https://picsum.photos/seed/tofik-hall/900/700','المصلى الرئيسي',null),
  ('MM_TOFIK_3','MOSQ_PILOT_0001','circle','https://picsum.photos/seed/tofik-lesson/900/700','الدرس الأسبوعي',null),
  ('MM_TOFIK_4','MOSQ_PILOT_0001','activity','https://picsum.photos/seed/tofik-kids/900/700','دورة الأطفال',null),
  ('MM_TOFIK_5','MOSQ_PILOT_0001','project','https://picsum.photos/seed/tofik-renovation/900/700','أعمال الصيانة الأخيرة',null)
on conflict (id) do nothing;
