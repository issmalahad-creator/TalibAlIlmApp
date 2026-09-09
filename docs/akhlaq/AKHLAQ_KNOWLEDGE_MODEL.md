> ⚠️ **مطويّة.** أُعيد تعريف المشروع كـ«نظام تدريب» (2026-09-09). المرجع الحاكم الآن: `docs/akhlaq/README.md` + الوثائق الست. هذه الوثيقة للسياق فقط.

# منظومة الأخلاق والآداب — نموذج المعرفة (Knowledge Model)

> الكيانات المفاهيمية وعلاقاتها، وكيف تركب على أنماط طالب العلم القائمة
> (`KnowledgeGateway` / `SourceReference` / نمط طبقات الكوربوس / محرّك
> التحشية في Turath). التنفيذ الحرفي في `AKHLAQ_DATA_SCHEMA`.

---

## 1. الكيانات

### 1.1 `AkhlaqNode` — العُقدة (خُلُق / أدب / آفة / أدب يومي / سياق / نبوي)
`slug` · `title_ar` · `node_kind` · `domain` · `content_class` ·
`summary_ar` · `level_hint` · `sort` · `status`.
(تفصيل الأنواع والحواف في `AKHLAQ_TAXONOMY`.)

### 1.2 `EvidenceItem` — الدليل
مربوط بعُقدة. الحقول كاملةً في `AKHLAQ_SOURCES §3`:
`evidence_type` · `text_ar` · `source_*` · `locator` · `grading?` ·
`takhrij?` · `lessons[]` · `status`. **لا يُعرَض وهو `draft`.**

### 1.3 `NodeCard` — بطاقة العُقدة (تجميعة عرض، ليست جدولاً)
تُركَّب وقت الطلب من العُقدة + أدلّتها + دروسها + مواقفها + تماريها +
روابطها. أقسامها الثابتة:

```text
التعريف · المنزلة · التصنيف (content_class ظاهر) ·
الأدلة [قرآن] [أحاديث مرفوعة] [آثار] [أقوال علماء] [قصص] [حِكَم يُنسب] ·
علامات المتحلّي به · ضدّه (عُقدة الآفة) · كيف أكتسبه ·
أمثلة يومية · أخطاء شائعة · تمارين عملية · اختبر نفسك ·
تطبيق اليوم · محاسبة · مراجعة ·
[دفتري]: فوائدي · اقتباساتي · موقفي · ما أحتاج إصلاحه
```

### 1.4 `LessonUnit` — وحدة الدرس (المنهج)
`level` (0..12) · `order` · `title_ar` · `body_ar` (شرح تربوي، منسوب
لمصدره إن نُقل) · `node_refs[]` · `objective_ar` · `est_minutes`.
تفصيل المستويات في `AKHLAQ_CURRICULUM`.

### 1.5 `Scenario` — الموقف (مختبر المواقف الأخلاقية)
`prompt_ar` (سيناريو يومي) · `context_tags[]` (غضب/نقد/مدح/نجاح/فشل…) ·
`options[]` (كل خيار: `text_ar` · `verdict` ∈ {صحيح/مقبول/خطأ} ·
`why_ar` · `evidence_refs[]`) · `node_refs[]` · `reflection_prompt_ar`.
لا «نقاط» تنافسية؛ الهدف تأمّل ومقارنة بالسنّة.

### 1.6 `PracticeTask` — التمرين العملي
`node_id` · `text_ar` (فِعل قابل للتنفيذ اليوم) · `cadence` (مرّة/يومي/
أسبوعي) · `reflect_prompt_ar`. يُصدَّر اختياريًّا كـ`life_task` في محور
«أخلاق» بمُحرّك الحياة (`AKHLAQ_NOTEBOOK §5`).

### 1.7 `NotebookEntry` — مدخل الدفتر
`kind` ∈ {فائدة · اقتباس · موقف‑أخطأت · موقف‑نجحت · خلق‑أريده ·
خطة‑إصلاح · سؤال‑لنفسي · محاسبة‑يومية · محاسبة‑أسبوعية} ·
`node_id?` · `evidence_id?` · `x_link?` (آية/كتاب/صفحة) · `body_ar` ·
`mood?` · `created_at`. يعيد استخدام محرّك تحشية Turath
(`saveResolvedAnchor` / `StudyAnnotation`) للاقتباس المرتبط بموضع نصّ.

### 1.8 `MoralProfile` — الملف الأخلاقي (سِجِلّ، لا حكم)
مشتقّ لا مُخزَّن غالبًا: عدد العُقَد المدروسة/قيد العمل · التمارين المكتملة ·
المواقف المسجَّلة · المراجعات · «تركيز هذا الأسبوع» (عُقدة يختارها الطالب) ·
سلسلة المحاسبة. **لا سِمات شخصية، لا تشخيص.**

### 1.9 `SourceRef` — الإحالة
يُعاد استخدام `SourceReference` القائم في `KnowledgeGateway` (id · title ·
author · licence · url) مع إضافة حقول التوثيق من `AKHLAQ_SOURCES` (طبعة ·
تخريج · درجة).

---

## 2. العلاقات (نظرة عليا)

```text
AkhlaqNode 1───* EvidenceItem
AkhlaqNode *───* AkhlaqNode         (akhlaq_edge: child_of/opposite_of/requires/…)
AkhlaqNode *───* LessonUnit          (node_refs)
AkhlaqNode 1───* Scenario
AkhlaqNode 1───* PracticeTask
AkhlaqNode 1───* NotebookEntry       (اختياري: مدخل حرّ بلا عُقدة)
EvidenceItem 1──* NotebookEntry      (اقتباس/فائدة على دليل بعينه)
EvidenceItem *──* SourceRef
AkhlaqNode *───* ExternalEntity      (x_link: ayah / turath / sira / lesson / life_pillar)
LessonUnit  *──1 Level (0..12)
```

---

## 3. الركوب على أنماط طالب العلم القائمة

| المفهوم هنا | النمط القائم المُعاد استخدامه | ملاحظة |
|---|---|---|
| عرض عُقدة/دليل في واجهات أخرى | `KnowledgeProvider` جديد `AkhlaqProvider` (domain: `akhlaq`) داخل `KnowledgeGateway` | يعيد `KnowledgeFact` + `SourceReference` + `dataState:local` |
| الإحالة والمصدر | `SourceReference` + جدول `source_editions` جديد | لا يُخترع نظام مصادر ثانٍ |
| الاقتباس المربوط بموضع نصّ | `TurathRepository.saveResolvedAnchor` + `StudyAnnotation` | «دفتر الأخلاق» طبقة عرض فوقه |
| المراجعة المتباعدة | `knowledge_review_repository` | جدولة مراجعة العُقَد/الأدلّة |
| المستويات/الطبقات | نمط `TajweedTierScreen` + طبقة التعلّم | «رحلة الأدب» 0→12 |
| التدريب اليومي + المحاسبة | مُحرّك الحياة (محور + مهامّ + دفتر يوم) | محور «أخلاق» + `PracticeTask→life_task` |
| البحث | `quran_search_repository` + `arabic_normalize` (FTS + تطبيع) | `AKHLAQ_SEARCH` |
| الموضوعات/الرسم | `quran_topic` + تصميم `knowledge_links` | `akhlaq_node`/`akhlaq_edge` بنفس الفكرة، محليًّا |

**قاعدة:** لا يُعاد بناء شيء من هذه؛ يُوسَّع أو يُركَب عليه. ما يُبنى جديدًا
محصور في: جداول `akhlaq_*`، `AkhlaqProvider`، شاشات المنظومة، أداة البناء
`build_akhlaq_corpus.py`، وطبقة «مختبر المواقف».

---

## 4. حالة البيانات (offline-first)

- كل المنظومة **محلّية** (SQLite + أصول `assets/akhlaq/*.json.gz` مبذورة
  كطبقات الكوربوس). `dataState: local`.
- Turath (بحث/اقتباس) هو الجزء **الأونلاين** الوحيد، وهو مساعد لا شرط:
  المنظومة تعمل كاملةً بلا إنترنت.
- المزامنة (Supabase) خارج نطاق المرحلة الأولى؛ الجداول تُصمَّم بحيث
  تُضاف لها لاحقًا أعمدة `updated_at/deleted_at/rev` بلا كسر
  (`AKHLAQ_DATA_SCHEMA §6`).
