# VISUAL_IDENTITY_STYLE_GUIDE.md — تدقيق بصري موثَّق + أمر تنفيذي جاهز للوكيل

**نطاق هذا الملف حصرًا: الأسلوب، الهوية البصرية، ترتيب الواجهات، الحركة، التفاعل — لا شيء آخر.**

**قاعدة صارمة يجب الالتزام بها عند تنفيذ هذا الملف**: هذا الملف **مستقل تمامًا** عن `docs/memorization/*` و`READING_SCREEN_REFERENCE_2026.md` و`KHATM_SYSTEM_AND_STYLE_REFERENCE.md` — تلك ملفات **ميزات ووظائف**، وهذا ملف **مظهر وأسلوب فقط**. لا يجوز لأي وكيل ينفّذ هذا الملف أن يضيف ميزة واحدة من تلك الملفات أثناء هذا العمل، ولا أن يستنتج شيئًا من محادثات سابقة — **المرجع الوحيد هو الفيديو نفسه**، والموقع المرجعي `https://web.wahy.net/ar` كسياق ثانوي فقط.

---

## 0. منهجية هذا التدقيق (لماذا يُوثَق به أكثر من وصف عام)

خلافًا لتحليل نصّي عام، هذا التدقيق **قِيسَ فعليًا**: استُخرِجت إطارات حقيقية من نفس الفيديو (`أفضل تطبيق للقرآن الكريم في 2026 #القرآن_الكريم.mp4`) عبر `ffmpeg`، ثم **أُخِذت عيّنات ألوان حقيقية (pixel sampling)** من مواضع دقيقة داخل تلك الإطارات — لا تخمين لفظي مثل "أخضر هادئ" بلا رقم. كل قيمة لونية أدناه مُقاسة من بيكسل حقيقي، مذكور موضعه.

---

## 1. التدقيق البصري (Visual Audit)

### 1.1 الخلفية والأسطح (Surfaces) — مُقاسة فعليًا

| الطبقة | اللون المُقاس | الوصف |
|---|---|---|
| خلفية عامة (خارج الهاتف في مشهد العرض) | **`#FBF2D9`** | كريمي/عاجي دافئ، ليس أبيض نقيًا إطلاقًا |
| بطاقات/أوراق سفلية (Sheets) | **`#EFE4C8`** تقريبًا (نطاق `#ECDFC0`–`#F6EED9`) | بيج فاتح، أفتح قليلًا من الخلفية العامة لكنه ليس أبيض |
| عناصر تحكّم/محتوى (حقول، صفحة المصحف نفسها) | **`#FFFFFF`**–`#FEF9F6` | أبيض تقريبًا، أفتح طبقة |
| الأخضر الأساسي (الشريط السفلي الثابت) | **`#25401F`**–`#264026` (متّسق جدًا عبر عدة عيّنات) | أخضر داكن جدًا يميل للزيتوني، **ليس** أخضر إشارة/نيون |
| الأخضر الثانوي (عناصر تحكّم تفاعلية، كمشغّل التلاوة المصغَّر) | **`#4F8D53`**–`#528B58` | أخضر متوسط أكثر حيوية من الأساسي، لا يزال مطفَّأ (muted) |

**استنتاج حاسم**: يوجد **مستويان من الأخضر لا مستوى واحد** — أخضر داكن جدًا للهوية/الحاوية الثابتة (الشريط السفلي)، وأخضر متوسط أفتح للعناصر التفاعلية المؤقتة (المشغّل، الأزرار النشطة). هذا تمييز دقيق لم يظهر في أي وصف عام سابق.

### 1.2 قاعدة استخدام الأخضر
من فحص كل الإطارات: الأخضر **محجوز** للشريط السفلي الثابت (خمس أيقونات) والعناصر التفاعلية النشطة (مشغّل التلاوة، تبويب مُختار، زر تحميل). **كل ما عدا ذلك أبيض/بيج/كريمي مع نص داكن** — لا يوجد إفراط في الأخضر عبر الشاشة.

### 1.3 البطاقات والأوراق السفلية (Cards / Bottom Sheets)
حواف مستديرة بوضوح (radius واضح، ليست حادة)، بلا ظلال قوية ملحوظة في الإطارات المُفحوصة، تنزلق من الأسفل (bottom sheet قياسي)، محتواها مُقسَّم بعناوين/تبويبات واضحة لا جدارًا نصيًا واحدًا.

### 1.4 الشريط السفلي الثابت
خمس أيقونات دائرية بيضاء على خلفية خضراء داكنة موحَّدة، مضغوط (لا يأخذ ارتفاعًا كبيرًا)، يبقى ظاهرًا عبر تنقّل المستخدم بين الأوراق السفلية المختلفة (فهرس، تلاوات، تحميل) — **جزء ثابت من هوية الشاشة، لا عنصر تنقّل عادي يختفي**.

### 1.5 نص القرآن مقابل نص الواجهة (تمييز طباعي حقيقي، مؤكَّد من الإطارات)
- نص القرآن: أسود على أبيض، حجم أكبر نسبيًا، خط عربي تقليدي (نمط مصحفي)، مساحة سطر مريحة.
- نص الواجهة (عناوين الأقسام، تسميات الأزرار): أصغر، ألوان مختلفة حسب السياق (أخضر داكن على أبيض في العناوين، أبيض على أخضر في الأزرار)، بلا خط منفصل مؤكَّد بصريًا — **لا يُخمَّن اسم خط بعينه** (نفس تحذير النص المُقدَّم لي: لا اسم خط من الصورة وحدها).

### 1.6 الزخرفة
ظهرت فقط حول عناوين/بطاقات محدَّدة في لقطات أخرى مشابهة (وليست في كل شاشة من هذا الفيديو تحديدًا) — **عنصر تمييزي محدود الاستخدام، لا زخرفة معمَّمة على كل عنصر**.

### 1.7 الاتجاه RTL
كل الشاشات المفحوصة عربية أصيلة الاتجاه: النص من اليمين، الأيقونات وترتيب العناصر يتبع نفس المنطق (لا واجهة إنجليزية معكوسة). **لا تفاصيل حركة سهم/تنقّل رجوع كافية في اللقطات الثابتة لتأكيد قاعدة إضافية أدق من هذا**.

### 1.8 الحركة (Motion) — حدود الصدق هنا مهمة
**لا يمكن تأكيد منحنى/توقيت حركة فعلي من إطارات ثابتة**، تمامًا كما وُثِّق سابقًا في `READING_SCREEN_REFERENCE_2026.md` §8. المؤكَّد من السياق فقط: الأوراق السفلية تنزلق من الأسفل (نمط قياسي)، لا يوجد أي دليل بصري على حركة استعراضية (لا توهج نيون، لا انتقالات ثلاثية الأبعاد). **أي وصف "حركة هادئة وظيفية" أبعد من هذا هو استنتاج معقول لا حقيقة مُقاسة** — يُذكَر للوكيل كتوجيه معقول لا كقاعدة صارمة.

---

## 2. نظام الرموز (Design Tokens) المقترَح — مبني على القياس أعلاه

```
color.background.base        = #FBF2D9   // الخلفية العامة الدافئة
color.surface.card           = #EFE4C8   // البطاقات/الأوراق السفلية
color.surface.control        = #FFFFFF   // حقول الإدخال/عناصر التحكّم/خلفية المصحف
color.brand.green.deep       = #26402A   // الهوية الثابتة: الشريط السفلي، عناوين مهمة
color.brand.green.medium     = #4F8D53   // عناصر تفاعلية نشطة: تشغيل، تبويب مُختار، تحميل
color.text.onLight           = "أسود/شبه أسود تقليدي"   // غير مُقاس بدقة (خطوط رفيعة)، لا يُخترَع رقم
color.text.onGreen           = #FFFFFF
radius.card                  = "واضح، متوسط-كبير"        // لا رقم بكسل دقيق من فيديو مضغوط، يُقاس من الكود الفعلي عند التنفيذ
```

**ملاحظة أمانة**: لا تُختلَق أرقام radius/spacing بالبكسل من فيديو — هذه تُضبَط عمليًا أثناء التنفيذ الفعلي على الشاشة الحقيقية، لا من تخمين إطار مضغوط.

---

## 3. ممنوعات صريحة (لأي وكيل ينفّذ هذا)

- لا Dark UI كامل، لا Neon، لا Glassmorphism، لا تدرّجات قوية، لا لوحة ألوان SaaS أرجوانية/زرقاء.
- لا تصميم ثلاثي الأبعاد، لا بطاقات ضخمة تُغرِق الشاشة، لا خطوط غربية للنص العربي.
- **لا ميزات جديدة، لا شاشات لم تظهر في الفيديو، لا استيراد أي فكرة من `docs/memorization/` أو ملفات الميزات الأخرى في هذه الجولة تحديدًا** — أسلوب بصري فقط.
- لا اختراع اسم خط أو رقم بكسل دقيق غير مُقاس فعليًا.
- لا جعل كل شيء أخضر، ولا جعل كل شيء أبيض.

---

## 4. الأمر التنفيذي الجاهز للصق لأي وكيل Claude (إنجليزي، تنفيذي مباشر)

```text
You are the UI/UX lead transforming this application's VISUAL STYLE ONLY,
based strictly on the measured audit in
docs/quran/VISUAL_IDENTITY_STYLE_GUIDE.md.

SCOPE LOCK — read this first:
- This pass changes PRESENTATION ONLY. Do not add, remove, or redesign
  any feature or screen flow.
- Do not consult or import anything from docs/memorization/ or any
  feature-spec doc in docs/quran/ other than this style guide.
- Do not invent colors, fonts, or spacing values not present in the
  token table in §2 of the style guide. If a value is genuinely needed
  and not measured, flag it as a question — do not guess.

PHASE 1 — AUDIT CONFIRMATION (no code yet)
Read docs/quran/VISUAL_IDENTITY_STYLE_GUIDE.md §1 and §2 in full.
Report back: which existing widgets/theme files in this Flutter app
already define colors that conflict with these tokens, and where the
app's current theme configuration lives. Do not edit anything yet.

PHASE 2 — DESIGN TOKENS
Implement the token table from §2 as the app's actual theme source
(wherever Flutter theme/color constants currently live). Reuse the
existing theme-switching mechanism (night mode, the 5 color templates
already in this app) — do not build a parallel theme system.

PHASE 3 — SHARED COMPONENTS
Update shared button, card, and bottom-sheet widgets to the new tokens.
Reuse existing widgets; do not create duplicate one-off styled copies.

PHASE 4 — ONE SCREEN, THEN STOP
Migrate exactly ONE representative screen (propose which one, wait for
confirmation). Stop. Do not continue to further screens until this one
is visually verified against the audit.

PHASE 5 — VERIFY, THEN CONTINUE
After confirmation, continue one screen at a time, same tokens, no new
one-off styling per screen.

REFERENCE FIDELITY RULE: when in doubt, match §1's measured observations,
not personal design preference. When something isn't in the audit,
don't invent it — ask.
```

---

*مصدر القياس: إطارات حقيقية مستخرجة عبر `ffmpeg` من `أفضل تطبيق للقرآن الكريم في 2026 #القرآن_الكريم.mp4` + عيّنات ألوان بيكسل فعلية (لا تخمين). لا علاقة لهذا الملف بمحتوى `docs/memorization/` أو مواصفات الميزات الأخرى — أسلوب بصري مستقل بالكامل.*
