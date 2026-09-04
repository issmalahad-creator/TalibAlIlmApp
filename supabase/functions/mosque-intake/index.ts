// «مساجدنا» — Telegram bot intake (Phase 74.5, v1 / MVP).
//
// v1 scope is deliberately small: today there is one mosque and one admin
// (Ismail). Whoever messages this bot first becomes the super_admin
// (self-bootstrap); a super_admin can link a chat to a mosque and then
// add/list/pin/delete that mosque's content directly — status='published'
// immediately, no review queue. The pending-changes / risk-tier / daily-
// digest workflow in docs/MOSQUE_PLATFORM_VISION.md is real and designed,
// but it only earns its complexity once multiple mosques/admins actually
// need review. Build that layer when that day comes, not speculatively now.
//
// Secrets (Supabase dashboard → Edge Functions → Secrets), never in git:
//   TELEGRAM_BOT_TOKEN     — required, from @BotFather.
//   TELEGRAM_WEBHOOK_SECRET — optional but recommended; must match the
//     `secret_token` given to Telegram's setWebhook call (see
//     docs/mosque/TELEGRAM_BOT.md). Without it this function still works,
//     it just can't tell a real Telegram update from a forged POST.
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically by
// the Edge Functions runtime for every deployed function — never set these
// by hand, never put the service_role value anywhere else.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN') ?? '';
const WEBHOOK_SECRET = Deno.env.get('TELEGRAM_WEBHOOK_SECRET') ?? '';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

// Booleans only — never log the secret values themselves. Check this in
// the function's logs (Dashboard → Edge Functions → mosque-intake → Logs)
// first if the bot ever looks "dead": a false here means the matching
// secret wasn't actually saved (or was saved under the wrong name/into
// the wrong field) and every reply will fail silently.
console.log('mosque-intake boot: has BOT_TOKEN =', !!BOT_TOKEN,
  '| has WEBHOOK_SECRET =', !!WEBHOOK_SECRET,
  '| has SUPABASE_URL =', !!Deno.env.get('SUPABASE_URL'),
  '| has SERVICE_ROLE_KEY =', !!Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'));

const CONTENT_KINDS = [
  'lesson',
  'khutbah',
  'announcement',
  'recording',
  'library',
  'need',
  'activity',
] as const;
type ContentKind = (typeof CONTENT_KINDS)[number];

const KIND_LABEL_AR: Record<ContentKind, string> = {
  lesson: 'درس',
  khutbah: 'خطبة',
  announcement: 'إعلان',
  recording: 'تسجيل',
  library: 'مكتبة',
  need: 'حاجة',
  activity: 'نشاط',
};

function isContentKind(s: string | undefined): s is ContentKind {
  return !!s && (CONTENT_KINDS as readonly string[]).includes(s);
}

const HELP = `<b>أوامر «مساجدنا»</b>
/link [معرّف المسجد] — اربط هذه المحادثة بمسجد (يُختار تلقائيًا إن كان هناك مسجد واحد فقط)
/mymosque — أي مسجد ترتبط به هذه المحادثة

/add ${CONTENT_KINDS.join('|')}
ثم على أسطر تالية:
العنوان: ...
الوصف: ...
المكان: ... (اختياري)

/list &lt;النوع&gt; — آخر 10 عناصر من هذا القسم مع معرّفاتها
/delete &lt;المعرّف&gt; — يحذف عنصرًا
/pin &lt;المعرّف&gt; — يثبّت أو يلغي تثبيت عنصر
/help — هذه الرسالة`;

async function sendMessage(chatId: string, text: string) {
  const res = await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, text, parse_mode: 'HTML' }),
  });
  if (!res.ok) {
    // fetch() does NOT throw on 4xx/5xx — log it or a bad/missing
    // TELEGRAM_BOT_TOKEN fails completely silently (bot looks "dead").
    console.error('sendMessage failed', res.status, await res.text());
  }
}

/** Parses `المفتاح: القيمة` lines (order-independent) out of a free-text body. */
function parseFields(body: string): Record<string, string> {
  const out: Record<string, string> = {};
  for (const line of body.split('\n')) {
    const i = line.indexOf(':');
    if (i === -1) continue;
    const key = line.slice(0, i).trim();
    const value = line.slice(i + 1).trim();
    if (key && value) out[key] = value;
  }
  return out;
}

function newContentId(): string {
  return `MC_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
}

Deno.serve(async (req) => {
  try {
    return await handle(req);
  } catch (e) {
    // Never let an unexpected error mean total silence — this is exactly
    // the "bot doesn't reply and nobody knows why" failure mode. Check
    // Dashboard → Edge Functions → mosque-intake → Logs for this line.
    console.error('mosque-intake unhandled error:', e);
    return new Response('ok'); // still 200 so Telegram doesn't retry forever
  }
});

async function handle(req: Request): Promise<Response> {
  if (WEBHOOK_SECRET) {
    const got = req.headers.get('X-Telegram-Bot-Api-Secret-Token');
    if (got !== WEBHOOK_SECRET) return new Response('forbidden', { status: 403 });
  }

  let update: Record<string, unknown>;
  try {
    update = await req.json();
  } catch {
    return new Response('ok'); // not JSON — nothing to do, don't error to Telegram
  }

  const msg = update?.message as Record<string, unknown> | undefined;
  if (!msg || typeof msg.text !== 'string') return new Response('ok');

  const chat = msg.chat as { id: number | string; title?: string };
  const from = msg.from as { id: number | string; first_name?: string };
  const chatId = String(chat.id);
  const tgUserId = String(from.id);
  const text = msg.text.trim();

  // ── super_admin check, with self-bootstrap for the very first sender ──
  const { count: adminCount } = await supabase
    .from('super_admins')
    .select('*', { count: 'exact', head: true });

  let isSuperAdmin: boolean;
  if ((adminCount ?? 0) === 0) {
    await supabase
      .from('super_admins')
      .insert({ tg_user_id: tgUserId, name: from.first_name ?? null });
    isSuperAdmin = true;
    await sendMessage(chatId, 'تم تسجيلك كمشرف عام أول لـ«مساجدنا». أرسل /help لرؤية الأوامر.');
  } else {
    const { data } = await supabase
      .from('super_admins')
      .select('tg_user_id')
      .eq('tg_user_id', tgUserId)
      .maybeSingle();
    isSuperAdmin = !!data;
  }

  if (text.startsWith('/start') || text.startsWith('/help')) {
    await sendMessage(chatId, HELP);
    return new Response('ok');
  }

  if (!isSuperAdmin) {
    // v1: only super_admins act — per-mosque roles aren't wired to
    // Telegram yet (mosque_users exists for when that's needed).
    await sendMessage(chatId, 'هذه المحادثة غير مخوَّلة لإدارة أي مسجد بعد.');
    return new Response('ok');
  }

  async function linkedMosqueId(): Promise<string | null> {
    const { data } = await supabase
      .from('mosque_telegram_connections')
      .select('mosque_id')
      .eq('chat_id', chatId)
      .maybeSingle();
    return (data?.mosque_id as string | undefined) ?? null;
  }

  if (text.startsWith('/link')) {
    let mosqueId = text.split(/\s+/)[1];
    if (!mosqueId) {
      const { data: mosques } = await supabase
        .from('mosques')
        .select('id, name')
        .eq('status', 'active');
      if (!mosques || mosques.length === 0) {
        await sendMessage(chatId, 'لا يوجد أي مسجد بعد.');
        return new Response('ok');
      }
      if (mosques.length > 1) {
        const list = mosques.map((m) => `${m.id} — ${m.name}`).join('\n');
        await sendMessage(chatId, `أكثر من مسجد موجود، حدّد أحدها:\n/link المعرّف\n\n${list}`);
        return new Response('ok');
      }
      mosqueId = mosques[0].id as string;
    }
    const { error } = await supabase.from('mosque_telegram_connections').upsert({
      mosque_id: mosqueId,
      chat_id: chatId,
      group_title: chat.title ?? null,
      linked_by: tgUserId,
    });
    await sendMessage(
      chatId,
      error ? `تعذّر الربط: ${error.message}` : `تم ربط هذه المحادثة بالمسجد: ${mosqueId}`,
    );
    return new Response('ok');
  }

  if (text.startsWith('/mymosque')) {
    const id = await linkedMosqueId();
    await sendMessage(chatId, id ? `هذه المحادثة مرتبطة بـ: ${id}` : 'غير مرتبطة بأي مسجد بعد — أرسل /link');
    return new Response('ok');
  }

  if (text.startsWith('/add')) {
    const mosqueId = await linkedMosqueId();
    if (!mosqueId) {
      await sendMessage(chatId, 'اربط هذه المحادثة أولًا بـ /link');
      return new Response('ok');
    }
    const lines = text.split('\n');
    const kind = lines[0].split(/\s+/)[1];
    if (!isContentKind(kind)) {
      await sendMessage(chatId, `اكتب نوع المحتوى بعد /add: ${CONTENT_KINDS.join(' | ')}`);
      return new Response('ok');
    }
    const fields = parseFields(lines.slice(1).join('\n'));
    const title = fields['العنوان'];
    if (!title) {
      await sendMessage(chatId, 'أرسل العنوان على الأقل:\nالعنوان: ...\nالوصف: ...\nالمكان: ...');
      return new Response('ok');
    }
    const id = newContentId();
    const { error } = await supabase.from('mosque_content').insert({
      id,
      mosque_id: mosqueId,
      kind,
      title,
      description: fields['الوصف'] ?? null,
      location: fields['المكان'] ?? null,
      status: 'published',
      created_by: tgUserId,
    });
    await sendMessage(
      chatId,
      error ? `تعذّر الحفظ: ${error.message}` : `أُضيف «${title}» (${KIND_LABEL_AR[kind]}) — ${id}`,
    );
    return new Response('ok');
  }

  if (text.startsWith('/list')) {
    const kind = text.split(/\s+/)[1];
    if (!isContentKind(kind)) {
      await sendMessage(chatId, `اكتب: /list <${CONTENT_KINDS.join('|')}>`);
      return new Response('ok');
    }
    const mosqueId = await linkedMosqueId();
    if (!mosqueId) {
      await sendMessage(chatId, 'اربط هذه المحادثة أولًا بـ /link');
      return new Response('ok');
    }
    const { data } = await supabase
      .from('mosque_content')
      .select('id, title, pinned')
      .eq('mosque_id', mosqueId)
      .eq('kind', kind)
      .order('updated_at', { ascending: false })
      .limit(10);
    if (!data || data.length === 0) {
      await sendMessage(chatId, 'لا يوجد شيء بعد في هذا القسم.');
    } else {
      const lines = data.map((r) => `${r.pinned ? '📌 ' : ''}${r.id} — ${r.title}`).join('\n');
      await sendMessage(chatId, lines);
    }
    return new Response('ok');
  }

  if (text.startsWith('/delete')) {
    const id = text.split(/\s+/)[1];
    if (!id) {
      await sendMessage(chatId, 'اكتب: /delete المعرّف');
      return new Response('ok');
    }
    const { error } = await supabase.from('mosque_content').delete().eq('id', id);
    await sendMessage(chatId, error ? `تعذّر الحذف: ${error.message}` : `تم حذف ${id}`);
    return new Response('ok');
  }

  if (text.startsWith('/pin')) {
    const id = text.split(/\s+/)[1];
    if (!id) {
      await sendMessage(chatId, 'اكتب: /pin المعرّف');
      return new Response('ok');
    }
    const { data: row } = await supabase
      .from('mosque_content')
      .select('pinned')
      .eq('id', id)
      .maybeSingle();
    if (!row) {
      await sendMessage(chatId, 'لم أجد هذا المعرّف.');
      return new Response('ok');
    }
    const { error } = await supabase
      .from('mosque_content')
      .update({ pinned: !row.pinned })
      .eq('id', id);
    await sendMessage(
      chatId,
      error ? `تعذّر: ${error.message}` : row.pinned ? `أُلغي تثبيت ${id}` : `تم تثبيت ${id}`,
    );
    return new Response('ok');
  }

  await sendMessage(chatId, 'أمر غير معروف. أرسل /help');
  return new Response('ok');
}
