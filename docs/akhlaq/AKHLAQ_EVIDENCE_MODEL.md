# AKHLAQ — نموذج الأدلّة (PHASE 12 + 13 + 17 + 18)

> الكتب الـ55 المكتشَفة (`AKHLAQ_SOURCE_SCAN` / `AKHLAQ_SOURCE_SHORTLIST`)
> **كوربوس يُغذّي النظام، لا المنتج نفسه**. هذه الوثيقة تحدّد: تراتب
> المصادر، مخطّط الدليل، حالاته، خطّ الإنتاج من الكتاب إلى الدرس،
> والمراجعة البشرية. الانضباط التفصيلي المكمّل في `AKHLAQ_SOURCES`.

---

## 1. تراتب المصادر (`source_tier`) — لا تساوي

| tier | المصدر | الاستعمال |
|---|---|---|
| 1 | **القرآن** | الأصل. يُجلَب عبر أداة موثّقة وقت الإدخال، يُقابَل بالكوربوس المحلّي؛ المحلّي يفوز. |
| 2 | **السنّة الصحيحة** | دليل، بشرط تخريج ودرجة **من مصدرٍ يحملهما**. |
| 3 | **الآثار الصحيحة** عن الصحابة | تُقوّي وتُفصّل، بمصدرها ودرجة ثبوتها إن وُجدت. |
| 4 | **أقوال أئمة الإسلام** | تُنقَل كما هي، منسوبةً لقائلها وكتابه؛ ليست حجّة برأسها. |
| 5 | **كتب الأدب/الأخلاق/التزكية المعتمدة** | مادّة للاستخراج والترتيب؛ ما فيها من مرفوع يخضع لـtier 2. |
| 6 | **الاجتهاد التربوي للتطبيق** | المبدأ، المؤشّر السلوكي، تصنيف الخيارات، الـfeedback — موسوم دائمًا «منهج التطبيق التربوي». |

قاعدة: **لا يُعرَض شيء من tier 5/6 بصيغة «سنّة» أو «قال ﷺ»**، ولا يُقدَّم
tier 4 كحكم قاطع. الواجهة تُظهر الـtier لكل مادّة.

---

## 2. مخطّط الدليل (`EvidenceItem`)

```text
id
subskill_slugs[]        المهارات التي يخدمها (كثير‑لكثير)
source_tier             §1
source_type             quran | hadith_marfu | athar_sahabi | qawl_tabii | qawl_alim | qissa | hikmah_ghayr_thabita
book_id                 معرّف Turath (أو 'quran')
author_id
book_title
edition_id              → akhlaq_source_edition
chapter                 الكتاب/الباب داخل المصدر
page                    رقم الصفحة / المجلّد+الصفحة
hadith_id               رقم الحديث في المصدر إن وُجد
locator                 (للقرآن) سورة:آية
text_ar                 النصّ كما ورد
meaning_ar              معنى ميسّر — منفصل، لا يُخلَط بالنصّ
narrator_top            الصحابي راوي الحديث (للمرفوع)
authentication          نصّ حكم أهل الشأن كما ورد
grader                  مَن حكم بالدرجة (كتاب/عالِم)
grading                 sahih | sahih_li_ghayrih | hasan | hasan_li_ghayrih | daif | daif_jiddan | mawdu | mukhtalaf_fih | lam_yudras
takhrij                 مواضع الحديث في الدواوين (نصّ/إحالة)
principle_refs[]        المبادئ المبنيّة عليه (interpretation_by = تربوي)
source_status           §3  (source_confirmed | source_located | source_uncertain | weak | disputed)
review_id               → akhlaq_review   (اختياريّ — طبقة مستقبليّة)
added_at / updated_at
```

**طبقات الترجمة** لا تُخزَّن هنا بل في `akhlaq_content_translation`
(`AKHLAQ_TRANSLATION_MODEL §4`)، مربوطةً بـ`ref_kind='evidence'` و
`ref_id=<id>` و`layer ∈ {text, meaning, explanation}`. الأصل العربيّ
(`text_ar` / `meaning_ar`) **لا يُستبدَل ولا يُنسَخ**؛ الترجمة **تمثيلٌ**
له، وعند اختلاف المعنى **العربيّ يفوز**. الترجمة **ليست مصدرًا مستقلًّا**.

**قيود اتّساق (تُفحَص آليًّا في خطّ الإنتاج):**
- `source_type=quran` ⇒ `locator` غير فارغ + مُقابَل بالكوربوس المحلّي.
- `source_type=hadith_marfu` ⇒ `grader` + `grading` + `takhrij` غير فارغة
  لأيّ `source_status=source_confirmed`.
- `grading ∈ {daif, daif_jiddan, mawdu}` ⇒ **لا يُدرَج كدليل**؛ يجوز فقط
  في مادّة «ما لا يصحّ» بوسمٍ صريح وبمصدر الحكم.
- `review_id` **اختياريّ** (طبقة مستقبليّة). غيابه لا يمنع النشر.

---

## 3. حالات الدليل (`source_status`) — درجة التحقّق من المصدر نفسه

> تعديل 2026‑09‑10: `verified/needs_review` لم تَعُد بوّابةً بشريّة. الحالة
> تعكس **مدى التحقّق من المصدر آليًّا**، لا مراجعة إنسان.

| الحالة | المعنى | يُبنى عليه محتوًى منشور؟ |
|---|---|---|
| `source_confirmed` | وُصِل إلى النصّ الأصليّ من المصدر · الكتاب والطبعة والموضع (مج/ص/رقم) محدَّدة · وللمرفوع: التخريج والدرجة موجودان في المصدر المُدخَل (الصحيحان، أو طبعةٌ فيها أحكام) | **نعم** |
| `source_located` | المصدر والكتاب محدَّدان، لكن بعض البيانات (الصفحة الدقيقة/رقم الحديث/ضبط اللفظ) لم تُثبَّت بعد | نعم، بوسمٍ «المصدر محدَّد، بعض البيانات غير مثبَّتة» |
| `source_uncertain` | النسبة أو النصّ لم يستقرّا | **لا** |
| `weak` | ثبت ضعفه (بمصدر الحكم) | فقط في «ما لا يصحّ»، موسومًا |
| `disputed` | مختلَفٌ في ثبوته/فهمه | يُعرَض مع بيان الخلاف، لا يُبنى عليه موقفٌ قاطع |

**الواجهة تُظهر وسم الحالة دائمًا**؛ «موثّق التوثيق» تُطلَق على
`source_confirmed` فقط (بمعنى: تحقّقنا من المصدر، لا: راجعه عالِم).

---

## 4. خطّ الإنتاج (Content Pipeline) — الخطّ الأساسيّ آليّ

```text
SOURCE
  ▼ FETCH ORIGINAL            من api.turath.io / المصحف المحلّي (tool/، وقت التأليف)
  ▼ VERIFY AVAILABLE METADATA الكتاب · الطبعة · المجلّد/الصفحة · رقم الحديث · التخريج/الدرجة الموجودة
  ▼ EXTRACT                   النصّ كما ورد
  ▼ CLASSIFY                  content_class · source_type · source_status (§3)
  ▼ TRANSLATE                 حرفيّة أمينة، كل لغةٍ ممكنة (AKHLAQ_TRANSLATION_MODEL)
  ▼ PEDAGOGICAL MODEL         مبدأ → مؤشّرات → مواقف  (موسومة «منهج تطبيق تربوي»)
  ▼ CONTENT VALIDATION        tool/akhlaq_validate.py  (§4‑bis)
  ▼ PUBLISHABLE CONTENT
```

- **لا يتوقّف الـpipeline لغياب مراجعةٍ بشريّة.** الـ`Human Review` طبقةٌ
  **مستقبليّة اختياريّة**؛ الـmetadata تُحفَظ للتتبّع.
- **ممنوع:** انتقال مادّةٍ من Turath إلى المستخدم دون المرور بـ CLASSIFY +
  TRANSLATE + PEDAGOGICAL MODEL + VALIDATION.
- الأداة: `tool/build_akhlaq_corpus.py` تُنتج `assets/akhlaq/*.json.gz`
  وتُفشِل البناء عند خرق أيّ قيد §2 أو فشل `akhlaq_validate`.

## 4‑bis. التحقّق الآليّ من المحتوى (CONTENT VALIDATION)

`tool/akhlaq_validate.py` يُفشِل عند أيٍّ من:
1. نصٌّ بلا `source` (أو `[TARBAWI]` صريح للمحتوى التربويّ).
2. ترجمةٌ بلا `original_arabic`.
3. نسبةٌ لعالِمٍ بلا `source`.
4. `pedagogical_interpretation` منسوبٌ لعالِمٍ (يجب `interpretation_by =
   منهج التطبيق التربوي`).
5. `behavior` بلا `evidence` وبلا `[TARBAWI]`.
6. `scenario` بلا `subskill` أو بلا `difficulty`.
7. أيّ حقلٍ عليه علامة «بيانات وهمية / نصّ مختلَق» (placeholder/lorem/…).
8. `source_type=hadith_marfu` و`source_status=source_confirmed` بلا
   `grading`+`takhrij`.
9. `translation_type=QURAN_MEANING` و`translator` = "Claude"/آليّ.

---

## 5. المراجعة البشرية — طبقةٌ مستقبليّة اختياريّة (تتبّعٌ لا بوّابة)

**الأتمتة/Claude تنفّذ البحث والتحليل والتصنيف والترجمة في هذه المرحلة.**
الـmetadata تُحفَظ كاملةً للتتبّع؛ ومَن أراد لاحقًا مراجعةً بشريّة يجدها
جاهزة.

| تفعله الأتمتة الآن | يبقى مسجَّلًا للتتبّع/المراجعة المستقبليّة |
|---|---|
| الوصول للنصّ الأصليّ + تحديد الكتاب/الطبعة/الموضع | حالة `source_status` ومصدرها |
| نقل التخريج/الدرجة **الموجودة في المصدر** (لا اختلاقها) | `grader` + `grading` + `takhrij` كما وردت |
| التصنيف · الترجمة الحرفيّة · بناء المبادئ/المواقف | وسم `translation_status` و`interpretation_by` |

```text
akhlaq_review   (اختياريّ — يُملأ إن/حين تُجرى مراجعة)
  ref_kind · ref_id · state (pending|approved|changes_requested)
  reviewer · checked[] · note · reviewed_at
```
- غياب `akhlaq_review` **لا يمنع** النشر. وجوده يُثري التتبّع فقط.

---

## 6. الربط المتقاطع (Cross‑reference — PHASE 12)

- مبدأ واحد ← عدّة أدلّة عبر مصادر مختلفة (`akhlaq_principle_evidence`).
- دليل واحد → عدّة مهارات فرعية (`subskill_slugs[]`).
- كشف التكرار: نصّان بنفس المعنى من مصدرين → يُربطان لا يُكرَّران في
  الواجهة.
- تفسير الآية للشرح فقط من الكوربوس المحلّي (`quran_tafsir`)، لا كنصّ ولا
  كحكم.

---

## 7. سجلّ الطبعات (`akhlaq_source_edition`)

`edition_id` · `title` · `author` · `editor_tahqiq` · `publisher` · `year`
· `turath_book_id` · `notes`. كل `EvidenceItem.edition_id` يشير إليه.
يمنع «صفحة كذا» بلا طبعة معلومة. يُملأ عند فحص كل كتاب فعليًّا في A2.

---

## 8. الترجمة إلى التنفيذ (SQLite/Flutter)

- جداول المعرفة (مبذورة، للقراءة): `akhlaq_evidence` ·
  `akhlaq_source_edition` · `akhlaq_principle` · `akhlaq_principle_evidence`.
- جدول العمليات: `akhlaq_review` (يُصدَّر مع الأصول كمرجع «مَن راجع ماذا»،
  ولا يقبل تعديلًا من المستخدم).
- البذر: `AkhlaqSync` من `assets/akhlaq/evidence/<subskill>.json.gz`
  (ملفّ لكل مهارة/فضيلة) + `editions.json.gz`.
- FTS للبحث لاحقًا (`AKHLAQ_ARCHITECTURE §Search`)، بإعادة استخدام
  `normalizeArabicForSearch`.
- اختبار `akhlaq_evidence_qa_test`: يفحص قيود §2، ويكتب تقرير تغطية (كم
  `verified` لكل مهارة، كم `hadith_marfu` بلا `grading` = يجب 0 في
  المنشور، توزيع `source_tier`).
