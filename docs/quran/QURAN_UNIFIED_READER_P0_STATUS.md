# القارئ الموحّد — حالة P0 (2026-08-30)

الخطة الكاملة: `C:\Users\ismail\.claude\plans\jolly-wibbling-forest.md`
نظام التصميم: `docs/quran/QURAN_PREMIUM_UI.md` · `.claude/skills/quran-premium-3d-ui/SKILL.md`

## ما أُنجز في P0 (يعمل ومُختبَر على المحاكي: صفحات 1، 3، 50)

- **الفن**: كل 604 صفحة MushafDatabase V1.01 مضمَّنة gzip داخل التطبيق
  (`assets/mushaf/pages_svg/NNN.svg.gz`, ~75 ميغا؛ APK debug ~327 ميغا).
  خلفية كريمية دافئة `0xFFFBF6EE`. viewBox `382.68×547.09` = إحداثيات
  `mushaf_*` → لمس مباشر بلا تحويل.
- **`QuranSelection`** (`lib/models/quran_selection.dart`) — النموذج المركزي
  `{page, surah, ayah, wordIndex?, type (word|ayah), wordBox?, textUthmani?}`.
- **hit-test واحد** في `MushafPageView`:
  `MushafPageLayout.ayaMarkAtPoint` (علامة الآية) ثم `wordAtPoint` (جسم
  الكلمة) ثم لا شيء. لا `nearestWord`، لا `GestureDetector` لكل كلمة.
  مُتحقَّق: البقرة 6:1، الفاتحة 1:1#3، آل عمران 3:2#2 — كلها دقيقة.
- **Selection Layer** (`_SelectionOverlay` في `MushafPageView`) — تظليل ذهبي
  متحرك (كلمة: تعبئة 0.13 + حدّ 1px + تكبير 0.96→1 في 180ms؛ آية: أهدأ
  0.07 لكل سطر). `CustomPaint` علوي، لا يمسّ الـSVG.
- **Word Knowledge Surface** (`lib/screens/quran_learning/knowledge_surface.dart`)
  — لوحة سفلية قابلة للسحب (0.42–0.92)، حافة ذهب + `DepthShadows.modal`،
  المصحف يبقى مرئيًا. الرأس = الكلمة بخط `AmiriQuran`. جسم Progressive
  Disclosure: الطبقة 1 (الإعراب/العلامة/لماذا/أبرز علاقة) دائمًا ·
  «التفاصيل» → الصرف/الجذر/الوزن/بقية العلاقات/التجويد/التفسير المرتبط ·
  المصادر رقائق. مثبّت: «تعلّم هذا» (→ `LearningLessonScreen` عبر
  `conceptId`، وإلا `IrabViewScreen`) + «الإعراب التفاعلي».
- **Ayah Knowledge Surface** — الرأس (السورة·الصفحة + رقم الآية) + «ماذا
  أتعلم من هذه الآية؟» + Segmented control (التفسير · الترجمة · التجويد ·
  العلوم المرتبطة · المصادر). التفسير: رقائق طبعات + مقتطف + مصدر + «التفسير
  كاملًا» → `AyahStudyScreen`. مثبّت: «أضف إلى دفتري» + «إعراب الآية».
- **نقص بيانات** → «لا توجد بيانات موثقة لهذا العنصر حاليًا» (مفتاح
  `ql_no_data_element`)، لا فراغ صامت ولا تخمين.
- **Gateway**: `KnowledgeProvider.factsForAyah` (افتراضي `[]`)،
  `LocalKnowledgeProvider`/`LocalTafsirProvider` تُنفّذه،
  `KnowledgeGateway.factsForAyah` + `QuranLearningRepository.factsForAyah`.
- `flutter analyze` نظيف (6 infos سابقة) · اختبارات `mushaf_page_view`
  (5، +`onAyaMarkTap`) + `mushaf_layout` + `quran_learning` تمر.
- القارئ الدلالي أُعيد بناؤه ليكون القارئ الواحد؛ يحمل `QuranSelection`.
- **P2 اكتملت 2026-09-03**: `quran_reading_screen.dart` (2182 سطرًا) **حُذف**؛
  المداخل الثلاثة (`home_screen` / `wird_screen` / `companion_card`) تشير الآن
  إلى `MushafSemanticReaderScreen`؛ قائمة ☰ صار فيها التحفيظ الصوتي + تسميع
  الصفحة + سجل الأخطاء. `flutter analyze` نظيف · **445/445 اختبار** · APK يُبنى.
  المتبقّي وحيدًا: التسميع (recitation-follow) — مؤجَّل صراحةً.
  التالي: إعادة بناء محرك المصحف — `docs/quran/MUSHAF_ENGINE_REBUILD.md`.

## أُنجز في جولة الصقل (2026-09-02)

- **[1] «طبّق» يعيد التحديد** ✅ — `_learn()` صار يُبقي السطح تحت الدرس؛ حين
  يرجع الدرس `'applied'` يُغلَق السطح بإشارة `'applied'`، والقارئ لا يمسح
  `_selWord` عندها → تعود لنفس `(صفحة، آية، كلمة)` مظلَّلة.
- **[2] سطر المصدر** ✅ — `_sourceLine`/`_sources` صارت `{name} · {badgeAr}`
  (موثّق/مقبول/داخلي) بدل نصّ الترخيص الطويل؛ قسم «المصادر» سطر واحد مضغوط.
- **[3] تفسير الآية** ✅ — أُضيفت 5 صفوف `src:tafsir:*` إلى
  `assets/quran_learning/prototype.json` (`version` 2→3، إعادة بذر تلقائية)
  → بوابة العرض تمرّرها → تبويب التفسير يظهر.
- **[4] رأس بطاقة الآية** ✅ — يعرض نصّ الآية بخط `AmiriQuran`
  (`QuranReadingRepository.ayahAt`) بجانب رقمها.
- **[6] دمج المصادر** ✅ — كما في [2].
- **[8] تراكب زر المحادثة** ✅ — `CompanionFloatingBubble.suppressed`
  (عدّاد)؛ القارئ يرفعه في `initState` ويُنزله في `dispose` → البابل مخفيّ
  داخل القارئ.
- **الوضع الليلي** ✅ (شريحة من P1) — مفتاح في الشريط + قائمة، يحفظ
  `quran_reading_night_mode`، خلفية داكنة دافئة + `MushafPageView.artInk`
  يعيد حبر الـSVG أحادي اللون إلى لون فاتح (`BlendMode.srcIn`).
- **قائمة ☰ + فهرس السور** ✅ (شريحة من P1) — `_openMenu` (الفهرس/اذهب
  لصفحة/دفتر القرآن/الوضع الليلي) + `_openSurahIndex` عبر
  `MushafLayoutRepository.pageForReference` (صفحة MushafDatabase الصحيحة، لا
  صفحة Tanzil).

## أُنجز أيضًا (جولة 3)

- **P1 قائمة ☰ (بلا صوت)** ✅ — الفهرس صار تبويبين (السور + **الأجزاء**،
  `MushafLayoutRepository.pageForJuz` جديد عبر `quran_ayat.juz_number`) +
  البحث (`QuranSearchScreen`) + المفضلة (ورقة آيات → قفزة بـ`pageForReference`
  لا `f.pageNumber`) + حدّد ما حفظته (`QuranBrowseScreen`) + رحلتي
  (`JourneyScreen`). كل مفاتيحها 13 لغة. المتبقّي: الصوت (مؤجَّل)، جلسة
  قراءة بوقت (صغير).
- **تراث — تجميد تمرير الصفحة أثناء التحديد** ✅ — `AnnotatedPageText.onSelectionActive`
  → `turath_reader_screen` يضع `physics: NeverScrollableScrollPhysics` أثناء
  وجود تحديد، فلا يسرق `SingleChildScrollView` سحب المقبض («المقبض الأيسر
  متعب»). + اختبار K. يبقى التصعيد الأكبر (`SelectionArea`) إن لم يكفِ على
  الجهاز.

## أُنجز أيضًا (جولة 2)

- **[5] حركة الدخول** (جزئيًّا) ✅ — `sheetAnimationStyle` (رفع أبطأ
  `easeOutCubic` 380ms + استقرار 240ms) + «تفتّح» على السطح
  (`TweenAnimationBuilder` scale 0.975→1 + fade من الأسفل). **الطموح
  الكامل** (container-transform يخرج من مستطيل الكلمة نفسه) لا يزال مؤجَّلًا.
- **[7] 13 لغة** ✅ — كل مفاتيح `ql_*` الـ43 رُقّيت إلى 13 لغة كاملة
  (`.claude/skills/app-translations` + سكربت). مفاتيح تراث/الليلي/الفهرس
  الجديدة كذلك 13 لغة.
- **[22] مؤشّر ملاحظات الصفحة في الفهرس** ✅ — `annotatedPagesForBook`
  (`{page → color_key}`) + نقطة ملوّنة في `TurathIndexScreen` بجانب رقم
  الصفحة إن كانت تحمل تظليلًا أو ملاحظة صفحة.

## متبقٍّ للصقل (P0-polish)

5. **حركة الدخول — الطموح الكامل**: morph من مستطيل الكلمة (custom
   `PageRouteBuilder` + `RectTween`)، spring physics حقيقي. الحالي تحسّن
   لكنه ليس container-transform.

## المراحل القادمة (من الخطة)

- **P1**: دمج مزايا `quran_reading_screen.dart` حول المعمارية الجديدة —
  قائمة «طريقة عرض المصحف» (فهرس/بحث/دفتر القرآن/حدّد ما حفظته/رحلتي/جلسة/
  ليلي/مفضلة) · شريط الصوت (`QuranAudioEngine` + مزامنة `QuranSelection`) ·
  الجلسة · الرحلة · مداخل التسميع.
- **P2**: Feature Parity Checklist ثم حذف `quran_reading_screen.dart` +
  مسار polygon JSON، وتوجيه `home_screen.dart:167` / `wird_screen.dart:85`
  / `companion_card.dart:52` → القارئ الموحّد.
- **لاحقًا**: تجربة `mushaf_borders` كفنّ بديل (تحويل إحداثيات صريح) ·
  تصغير APK إن لزم.
