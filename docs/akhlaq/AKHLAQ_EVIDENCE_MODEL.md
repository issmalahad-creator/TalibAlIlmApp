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
source_status           §3
review_id               → akhlaq_review
added_at / updated_at
```

**قيود اتّساق (تُفحَص في خطّ الإنتاج، لا في SQLite):**
- `source_type=quran` ⇒ `locator` غير فارغ + مُقابَل بالكوربوس المحلّي.
- `source_type=hadith_marfu` ⇒ `grader` + `grading` + `takhrij` غير
  فارغة، و`grading ∉ {lam_yudras}` لأيّ `source_status=verified`.
- `grading ∈ {daif, daif_jiddan, mawdu}` ⇒ **لا يُدرَج كدليل**؛ يجوز فقط
  في مادّة «ما لا يصحّ» بوسمٍ صريح وبمصدر الحكم.
- كل `EvidenceItem` منشور له `review_id` بحالة `approved`.

---

## 3. حالات الدليل (`source_status`)

| الحالة | المعنى | يظهر للمستخدم؟ |
|---|---|---|
| `not_verified` | لم يُتحقّق منه بعد | لا |
| `needs_review` | مُدخَل، بانتظار مراجعة بشرية | لا |
| `weak` | ثبت ضعفه | فقط في «ما لا يصحّ»، موسومًا |
| `disputed` | مختلَف في ثبوته/فهمه | يُعرَض مع بيان الخلاف، لا يُبنى عليه موقف قاطع |
| `verified` | مصدر + (للمرفوع) تخريج ودرجة + مراجعة `approved` | نعم، وتظهر له علامة «موثّق» |

**الواجهة تُظهر «موثّق» حصرًا لـ`verified`.** أيّ مادّة أخرى إمّا لا تظهر
أو تظهر بوسم حالتها.

---

## 4. خطّ الإنتاج (Content Pipeline — PHASE 17)

```text
Turath  ─(tool/, وقت التأليف فقط)─►  Book  ─►  Page  ─►  استخراج نصّ
        ─►  Candidate evidence (source_status = not_verified)
        ─►  إدخال الحقول §2 + جلب القرآن عبر أداة موثّقة
        ─►  needs_review
        ─►  ┌ مراجعة بشرية (PHASE 18) ┐
            └────────────┬────────────┘
                         ▼
        approved ─►  verified evidence
        ─►  EthicalPrinciple (تربوي، موسوم)
        ─►  BehavioralIndicators
        ─►  Scenarios (+ options + probes + feedback + evidence_ref)
        ─►  Lesson (درس يومي)
        ─►  Curriculum (مرحلة)
```

**ممنوع منعًا باتًّا:** انتقال مادّة من Turath إلى المستخدم مباشرة.

- الأداة: `tool/build_akhlaq_corpus.py` — تقرأ ملفّات مصدر منظّمة (نتيجة
  البحث والاستخراج) وتُنتج `assets/akhlaq/*.json.gz`، وتُفشِل البناء عند
  خرق أيّ قيد §2 أو وجود `published` بلا `review approved`.
- البحث والاستخراج من Turath: عملية تطوير عبر `TurathApiClient.search` /
  `getPage` — **ليست تبعيّة وقت تشغيل**؛ التطبيق النهائي offline‑first
  بالكامل.

---

## 5. المراجعة البشرية (`akhlaq_review` — PHASE 18)

هذا مشروع ديني: **الأتمتة/AI أداة، لا مرجع.**

| يجوز للأتمتة | لا يجوز لها |
|---|---|
| البحث في الكتب | الحكم بأنّ حديثًا صحيح/ضعيف |
| التصنيف الأوّلي، الربط، كشف التكرار | نسبة تفسير سلوكي إلى عالِم |
| اقتراح مبادئ/مؤشّرات/مواقف كـ`draft` | نشر مادّة حسّاسة |
| بناء مسودّات خطّ الإنتاج | تقرير `grading` أو `source_status=verified` |

```text
akhlaq_review
  ref_kind        evidence | principle | behavior | scenario | conflict_script | lesson
  ref_id
  state           pending | approved | rejected | changes_requested
  reviewer        اسم/دور المراجع (بشري)
  checked[]       source_ok · grading_ok · classification_ok · no_new_ruling ·
                  interpretation_labeled · not_judgmental · scenario_fair
  note_ar
  reviewed_at
```
- كل عُقدة `sensitivity=high` (من الأنطولوجيا) تحتاج مراجعة أدقّ وموسّعة.
- لا `published` بلا `state=approved`.

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
