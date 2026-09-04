# مُحرّك الحياة — Life Engine (خطة الحياة داخل التطبيق)

> إسماعيل، 2026‑09‑04: «أريد أن أستخدم البرنامج لتغيّري أنا أولًا … تواصل
> دائم وتقدّم وتنبيهات … لا أريد أن ينتهي التقدّم بانتهاء الـ90 يومًا،
> أريد أن يكون الإبداع مستمرًّا … اتقان، عمل دائم، ليس تلفيقًا … بطريقة لم
> يسبق لها مثيل.»

المصدر الواقعي: شيت «🚀 خطة الحياة الشاملة»
(`1P2fCEdQnTdFPSpZn9STaSxquw1Ac8HVU4PuzeHLOCbw`) — قُرئ فعليًا عبر `gviz`
(3 تبويبات: `🎯 الأهداف` · `📅 الجدول اليومي` · `📊 تتبع الإنجاز`).

---

## 0. المبدأ — بلا نهاية

- **لا «90 يومًا» كعدّاد تنازلي.** `dayIndex = today − startDate` غير محدود.
  «اليوم» = اليوم دائمًا.
- الـ90 يومًا = **دورة (cycle)** — علامة فارقة ناعمة. عند حدّ كل دورة:
  طقس **مراجعة** (تأمل + تعديل المحاور/الفترات + ترحيل السلاسل). الدورات
  **نقاط تطوّر** لا نهايات — «الإبداع مستمرّ».
- التقدّم = **نوافذ متدحرجة** (اليوم / 7 / 30 / منذ البداية) + **سلسلة**
  (أيام متتالية فوق العتبة، مع **يوم سماح أسبوعي** فلا يُصفّرها خطأ واحد) +
  **زخم كل محور** (إنجاز حديث مُرجّح).
- **تنبّؤ** (اتجاه 2026): تحذير حين يهبط زخم محور
  («محور Python هبط 3 أيام — انتبه»). بحث UCL: تكوين العادة ~66 يومًا لا
  21 ولا 90 → التصميم مرن، لا «رسوب» من يوم فائت
  ([Reclaim](https://reclaim.ai/blog/habit-tracker-apps),
  [State of Habit Tracking 2026](https://habit-streak.com/en/blog/habit-tracking/state-of-habit-tracking-2026)).

## 1. البيانات الحقيقية (مضمّنة كبذرة، قابلة للتعديل)

**7 محاور** (`🎯 الأهداف`):

| key | label | الهدف | إيقاع |
|---|---|---|---|
| quran | 📖 القرآن الكريم | يومي | daily |
| books | 📚 الكتب الـ5 | مقطع/يوم | daily |
| social | 🎬 السوشل ميديا | 3–4 فيديو/أسبوع | weekly(4) |
| coding | 💻 Python وبرمجة | ساعة/يوم | daily |
| erp | 🏪 ERP العملاء | 7 عملاء نشط | weekly(7) |
| micro | 🌐 Microworkers | 5 مهام/أسبوع | weekly(5) |
| jobs | 💼 البحث عن عمل | 3 طلبات/أسبوع | weekly(3) |

**23 فترة زمنية** (`📅 الجدول اليومي` — الوقت · النشاط · المحور · محور
مُتتبَّع؟): فجر/روحي → حفظ القرآن(quran) → رياضة/صحة → فطور/حياة →
كتاب صوتي(books) → Python(coding) → ERP(erp) → استراحة/تنظيم →
إنتاج محتوى(social) → ظهر/روحي → Microworkers(micro) → تفسير(quran) →
وظائف(jobs) → عصر/روحي → كتاب ثانٍ(books) → مشروع ERP(coding) →
مغرب/روحي → تحرير فيديو(social) → عشاء/حياة → مراجعة الحفظ(quran) →
ورد مسائي/روحي → تدوين الإنجازات/تنظيم → تحضير الغد + نوم/نوم.
(الفترات بلا محور مُتتبَّع — روحي/صحة/حياة/نوم/تنظيم — تدخل نسبة اليوم
الكلية لا نسبة محور.)

## 2. النموذج (`lib/models/life_plan.dart`) + مخطّط v55

- `life_pillars(key PK, label, emoji, target_text, cadence, weekly_target, sort)`
- `life_slots(slot_no PK, start_min, end_min, activity, mihwar, pillar_key NULL, sort)`
- `life_day_slots(date TEXT, slot_no INT, done INT, done_at INT, PK(date,slot_no))`
  — المفتاح `date` (YYYY‑MM‑DD) لا `day_no` ⇒ غير محدود.
- `life_day_notes(date PK, note, tomorrow_goal, mood NULL)` — «ملاحظة اليوم /
  هدف الغد» من تبويب التتبع. طبقة التأمل.
- `life_meta(k PK, v)` — `start_date`, `cycle_len=90`, `streak_threshold=0.6`,
  `grace_per_week=1`, `sheet_url?`, `tg_chat_id?`.

**SoT محليًّا**: النقر (tick) يُكتب فورًا في sqflite — offline‑first، لحظي.

## 3. التفاعل ثلاثي الأبعاد (يعيد استخدام `quran-premium-3d-ui`)

- **بطاقة «الآن»**: الفترة الحالية، كبيرة، تتنفّس؛ spring‑in عند تغيّر
  الفترة؛ نقر لإكمال → `HapticFeedback.mediumImpact` + الحلقة تمتلئ بنابض؛
  «تفتّح» هادئ بلا استعراض.
- **حلقة التقدّم**: `CustomPaint` + محاكاة نابض (`AppMotion`)، نسبة اليوم في
  المركز؛ ضغط مطوّل → النوافذ المتدحرجة تتوسّع.
- **الخريطة الحرارية اللانهائية**: شريط شهور أفقي من نقاط الأيام (تدرّج
  أخضر بنسبة اليوم)، اليوم ينبض؛ يتمرّر للخلف حتى البداية، الأمام «غدًا»
  شبح.
- **ورقة المراجعة الأسبوعية**: تصعد من شريط الأسبوع؛ «ملخص الأسبوع».
- بلا حزم جديدة — `depth.dart` / `motion.dart` + `HapticFeedback` من
  `flutter/services`
  ([micro‑interactions](https://medium.com/@flutter-app/animations-micro-interactions-in-flutter-make-your-ui-delightful-592fb9da6e11),
  [physics sim](https://flutter.dev/docs/cookbook/animation/physics-simulation)).

## 4. التنبيهات (تكيّفية)

`NotificationService` قائم (قنوات لكل مجال، `zonedSchedule`). نضيف قناة
`life_slots`:
- تذكير لكل فترة عند `start_min` لفترات **اليوم** (يُعاد جدولته كل فتح +
  منتصف الليل): «⏰ 08:30 — 💻 Python / برمجة (اليوم N)».
- **موجز الصباح** (05:00): مهام MIT الثلاث + فترات اليوم.
- **حاسب نفسك ليلًا** (21:30): «أنجزت X/23 اليوم. اكتب ملاحظتك وهدف الغد.»
- تكيّفي (L4+): إزاحة تذكير الفترة نحو وقت إنجازها الفعلي (من `done_at`).

## 5. الجسور (اختيارية — المحرّك يعمل كاملًا بدونها)

- **الشيت (Option A)**: `google_apps_script/life_plan_sync.gs` — `doGet`
  يُغذّي/يُحدّث المحاور+الفترات؛ `doPost` يعكس النقر في «📅 الجدول اليومي»
  فيبقى الشيت مرآةً. التطبيق ↔ Apps Script Web App مباشرة عبر `http`
  (الرابط في `app_config.dart` المُتجاهَل من git).
- **Supabase (L7)**: جداول `life_*` (إسماعيل فقط، RLS صارم) للمزامنة عبر
  الأجهزة + `life-plan-sync` Edge Function. **تليجرام**: DM شخصي عبر نفس
  الدالة (موجز فترات الصباح · نبضة كل فترة · «حاسب نفسك» ليلًا) — «تواصل
  دائم».

## 6. ترتيب البناء (مرحلة مُتقنة في كل مرة، لا تلفيق)

| | ماذا |
|---|---|
| **L1** ✅ *(هذه)* | النموذج + مخطّط v55 + البذرة (7 محاور + 23 فترة حقيقية) + `LifePlanRepository` (رقم يوم غير محدود، نوافذ متدحرجة، سلسلة بسماح) + اختبارات. **بلا واجهة.** |
| **L2** | شاشة «اليوم»: بطاقة الفترة الحالية + النقر + حلقة اليوم + قائمة الفترات. بلاطة الرئيسية. `basicText` ×13. تحقّق على المحاكي. |
| **L3** | التقدّم: النوافذ المتدحرجة، السلسلة+السماح، الخريطة الحرارية اللانهائية، زخم المحاور + التنبّؤ. |
| **L4** ✅ | `lib/services/life_plan_notifications.dart` (مُخطِّط نقيّ قابل للاختبار) + `NotificationService.scheduleLifePlanReminders()` على قناة `life_slots` (id 12000+): تذكير لقطة‑واحدة لكل فترة **اليوم** غير المنجَزة والقادمة عند `start_min`، «حاسب نفسك» 21:30 بعدّاد X/23 الحيّ، موجز صباح 05:00 متكرّر ثابت. يُعاد جدولته من `main.dart` + `LifePlanScreen` (تحميل/استئناف/منتصف الليل عبر `Timer`) فتسقط الفترة المنجَزة أو الفائتة. أصلح `_ready` في `NotificationService` إلى `static` (كان كل `NotificationService()` محلّي في شاشة لا يجدول شيئًا بصمت). 5 اختبارات نقية، تحقّق على الجهاز (36 منبّهًا، تفقد منبّه الفترة عند إتمامها). |
| **L5** | المراجعة الأسبوعية + ملاحظة اليوم/هدف الغد + انتقال الدورة. |
| **L6** | جسر الشيت (`doGet`/`doPost` + `LifePlanApiClient`). |
| **L7** | Supabase `life_*` + تليجرام DM عبر Edge Function. |

## المصادر
- <https://reclaim.ai/blog/habit-tracker-apps>
- <https://habit-streak.com/en/blog/habit-tracking/state-of-habit-tracking-2026>
- <https://medium.com/@flutter-app/animations-micro-interactions-in-flutter-make-your-ui-delightful-592fb9da6e11>
- <https://flutter.dev/docs/cookbook/animation/physics-simulation>
