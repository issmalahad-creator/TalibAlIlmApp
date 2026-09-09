# AKHLAQ — المعمارية الكاملة (Training System)

> يجمع الوثائق الخمس (`AKHLAQ_SYSTEM_PHILOSOPHY` · `AKHLAQ_ONTOLOGY` ·
> `AKHLAQ_BEHAVIOR_MODEL` · `AKHLAQ_SCENARIO_ENGINE` · `AKHLAQ_EVIDENCE_MODEL`)
> في معمارية واحدة، ويُثبِت أنّ كل قرار قابل للتحويل إلى **Flutter +
> SQLite + offline‑first** داخل المشروع الحالي. **لا كود، لا UI، لا
> migration** حتى تُعتمَد.

---

## 1. الطبقات (مطابِقة لمخطّط إسماعيل)

```text
┌──────────────────────────────┐
│  القرآن والسنة                │  tier 1–2  (AKHLAQ_EVIDENCE_MODEL §1)
└──────────────┬───────────────┘
┌──────────────▼───────────────┐
│  الكتب والشروح — Turath Corpus │  tier 3–5 · استخراج عبر tool/ فقط
└──────────────┬───────────────┘
┌──────────────▼───────────────┐
│  Evidence Layer               │  EvidenceItem + source_status (source_confirmed/
│  (التحقّق الآليّ + التخريج)   │  located/uncertain) · AKHLAQ_EVIDENCE_MODEL
└──────────────┬───────────────┘
┌──────────────▼───────────────┐
│  Translation Layer            │  الأصل العربيّ ثابت · ترجمة حرفيّة لكلّ لغةٍ
│  (العربيّة = SOURCE OF TRUTH) │  ممكنة · طبقات مفصولة · AKHLAQ_TRANSLATION_MODEL
└──────────────┬───────────────┘
┌──────────────▼───────────────┐
│  Character Ontology           │  domain → virtue → subskill → behavior
│  خلق → مهارة → سلوك           │  AKHLAQ_ONTOLOGY + AKHLAQ_BEHAVIOR_MODEL
└──────────────┬───────────────┘
        ┌──────┴──────┐
        ▼             ▼
 Knowledge Training   Behavioral Training
 درس / استرجاع        مواقف / محاكاة (Scenario + Conflict engines)
        └──────┬──────┘
┌──────────────▼───────────────┐
│  Reflection Engine            │  أسئلة سلوكية + تدوين + مهمّة يومية
│  محاسبة ومراجعة              │
└──────────────┬───────────────┘
┌──────────────▼───────────────┐
│  Spaced Repetition            │  §4 — يُعيد المعرفة + الموقف + المراجعة
└──────────────┬───────────────┘
┌──────────────▼───────────────┐
│  Progress Evidence            │  مؤشّر تدريبي لكل مهارة — لا حكم على الشخص
│  تقدّم تدريبي فقط             │  AKHLAQ_SYSTEM_PHILOSOPHY §6/§7
└──────────────────────────────┘
```

**سياسة الاعتماد (2026‑09‑10):** الخطّ الأساسيّ = `Source‑grounded
automated validation` (Claude ينفّذ البحث/التصنيف/الترجمة/بناء النموذج
التربويّ، ثمّ `tool/akhlaq_validate.py`). **المراجعة البشرية طبقةٌ
مستقبليّة اختياريّة**، لا تُوقِف الـpipeline؛ الـmetadata تُحفَظ للتتبّع
(`AKHLAQ_EVIDENCE_MODEL §4، §5`).

**القاعدة العابرة:** كل ما فوق «Translation Layer» يحدث في `tool/` وقت
التأليف. كل ما تحته يحدث **محليًّا على الجهاز**. لا تبعيّة إنترنت وقت
التشغيل.

---

## 2. حلقة التدريب (نواة المنتج)

```text
تعلّم (Knowledge)
  → درس: نصّ verified + معنى + مبدأ تربوي موسوم + لماذا + ضدّه
شاهد (Recognition)
  → «هذا موقف يختبر <مهارة>» — تدريب وسم قصير
اختر (Practice)
  → موقف → 3–5 بدائل مصنّفة → probe قبل/بعد
أخطئ (Feedback)
  → السلوك الأقرب + لماذا + الدليل + المهارة المُدرَّبة + «ماذا لو؟»
افهم (Consolidation)
  → إعادة صياغة المبدأ بلغة المستخدم (تدوين اختياري)
جرّب (Mission)
  → مهمّة عملية صغيرة اليوم + رصد مسائي
راجع نفسك (Self‑monitoring)
  → سؤال سلوكي عن فعل مضى + تدوين
أعد بعد أيّام (Spaced Repetition)
  → استرجاع → موقف → موقف أصعب → مراجعة → موقف مركّب
واجه الأصعب (Difficulty ↑)
  → رفع المستوى بقواعد شفّافة بعد ثبات نسبي
```

---

## 3. المنهج (Curriculum — PHASE 14)

مراحل مبنيّة على التبعيّة (`prerequisite_for`)، لا «تعلّم 100 خلق»:

| STAGE | العنوان | فضائل النواة |
|---|---|---|
| 1 | أساس طالب العلم | الإخلاص · الصدق · تعظيم العلم · التواضع · قبول الحقّ |
| 2 | ضبط النفس | الغضب · الصبر · الحلم · العفو · ضبط الهوى |
| 3 | اللسان | الصمت · ترك الغيبة · ترك النميمة · ترك الجدال · ترك القول بلا علم |
| 4 | الناس | الرفق · الرحمة · حسن الظنّ · الأمانة · الوفاء |
| 5 | الخلاف | الإنصاف · أدب الحوار · الاعتراف بالخطأ · الرجوع للحقّ |
| 6 | العلم (الأدب التفصيلي) | أدب السؤال · أدب الشيخ · أدب المجلس · نسبة العلم · ترك التعالُم |
| 7 | الاختبار | مواقف مركّبة من المستوى 8 تجمع ما سبق |

- STAGE ليس قفلاً صارمًا؛ «تكليف اليوم» يقترح التالي، والمستخدم يختار
  «تركيز» فضيلةً واحدة أحيانًا.
- الآداب التفصيلية (المجلس/السؤال/الجواب/القراءة/الكتاب/الاستماع/النوم/
  الطعام/المسجد/الوالدين/الصحبة/المعلّم/المتعلّم/النصيحة/السفر/الجوار/
  الضيف — PHASE 15) تتوزّع على المراحل حسب صلتها، وكلٌّ بـ`node_class` (أدب
  / مستحبّ / واجب / حكم فقهي يُحال).

---

## 4. التكرار المتباعد (PHASE 7) — خوارزمية داخلية

ليست حفظ نصّ. وحدة الجدولة = **(مستخدم × مهارة فرعية)**، لها ثلاثة مسارات
متزامنة:

```text
K  Knowledge recall      استرجاع المبدأ/الدليل (اختيار من متعدّد أو تذكّر)
S  Scenario recall       موقف جديد بنفس المهارة، صعوبة = صعوبة المستخدم
R  Behavioral reflection  سؤال سلوكي عن الأسبوع الماضي
```

**الفواصل الأساسية** (تُعدَّل بالأداء): `Day 1 تعلّم · D2 K · D4 S · D7 S+
· D14 R · D30 موقف مركّب · D60 مراجعة طويلة`.

خوارزمية مبسّطة (SM‑2 مُكيَّفة):
```text
interval_next = interval_prev * ease
ease += (quality - 3) * 0.1     # quality من verdict الموقف (aqrab=5, maqbul=3, baid=1)
ease = clamp(ease, 1.3, 2.6)
if quality <= 1: interval_next = 1  (يُعاد قريبًا، وبصعوبة لا تُرفَع)
difficulty يُرفَع فقط عند ثبات §Scenario Engine §7
```
- المخرَج للمستخدم: «اليوم عندك: استرجاع (كظم الغيظ) · موقف جديد (الرفق) ·
  مراجعة أسبوع (حفظ اللسان)». لا عدّاد بطاقات جافّ.

---

## 5. الملف التدريبي (Character Profile — PHASE 11) — مؤشّر لا حكم

```text
CharacterProfile (مشتقّ، غالبًا غير مخزَّن)
  per subskill:
    trend          متوسّط متدحرج لجودة اختيار الاستجابة (AKHLAQ_BEHAVIOR_MODEL §2.4)
    band           مبتدئ | ممارسة | ثبات | مراجعة | تمكّن سلوكي   (وصف مسار)
    attempts       عدد المواقف التدريبية
    weak_dimension أضعف بُعد استجابة ظهر مؤخّرًا
    last_seen
```
- يُعرَض: أشرطة «مجالات تدريب» (الصدق ██████░░ · ضبط اللسان ████░░░░ …).
- **إلزامي** أسفل كل عرض:
  > «هذا مؤشّر تدريبي مبني على إجاباتك وتدريباتك داخل التطبيق، وليس حكمًا
  > على أخلاقك ولا على صلاحك. حقيقة الخُلُق يعلمها الله.»
- **لا**: رقم واحد للشخص · «درجة صلاح» · مقارنة · leaderboard · «أنت
  متواضع».

---

## 6. المحاسبة والمراجعة (Reflection — PHASE 6 + 10)

- **مهمّة يومية**: فضيلة اليوم → آية/حديث verified → فهم مختصر → موقف واحد
  → اختيار → تفسير → سؤال محاسبة → مهمّة عملية صغيرة.
- **رصد مسائي**: هل حصل موقف؟ ماذا فعلت؟ ماذا كنت تستطيع؟ ماذا ستفعل المرّة
  القادمة؟ (تدوين حرّ + مزاج اختياري).
- **أسئلة المحاسبة سلوكية لا هُوّية** (PHASE 10):
  - ✗ «هل أنت متواضع؟»
  - ✓ «آخر مرّة صُحّح لك خطأ أمام الناس، ماذا فعلت؟»
  - ✓ «هل شعرت برغبة في الدفاع قبل فهم كلامه؟»
  - ✓ «هل بقي أثر الغضب بعد المجلس؟»
- **تكامل اختياري** مع مُحرّك الحياة: مهمّة الرفق اليومية تُصدَّر
  كـ`life_task`؛ رصد المساء يُربَط بـ«ملاحظة اليوم» — بلا تكرار، وباختيار
  المستخدم.

---

## 7. النموذج العلائقي (PHASE 16) — تصميم، لا migration

> الإصدار الحالي للقاعدة **v60**. جداول الأخلاق تبدأ من **v61** على دفعات
> (كل مرحلة في `§Roadmap` تأخذ رقمها). نمط الترحيل: `_createVNTables` +
> استدعاء غير مشروط في `onCreate` (كبقيّة التطبيق).

### 7.1 المعرفة (مبذورة من `assets/akhlaq/*.json.gz` عبر `AkhlaqSync`)
```
akhlaq_domain(slug PK, title_ar, sort)
akhlaq_node(slug PK, title_ar, node_type, node_class, domain_slug,
            parent_slug, summary_ar, why_ar, opposite_slug, stage_hint,
            sensitivity, status)
akhlaq_edge(from_slug, edge_type, to_slug, note_ar, PRIMARY KEY(from_slug,edge_type,to_slug))
akhlaq_source_edition(edition_id PK, title, author, editor_tahqiq, publisher, year, turath_book_id, notes)
akhlaq_evidence(id PK, source_tier, source_type, book_id, author_id, book_title,
               edition_id, chapter, page, hadith_id, locator, text_ar, meaning_ar,
               narrator_top, authentication, grader, grading, takhrij,
               source_status, review_id, added_at, updated_at)
akhlaq_evidence_subskill(evidence_id, subskill_slug, PRIMARY KEY(evidence_id,subskill_slug))
akhlaq_principle(slug PK, statement_ar, subskill_slug, interpretation_by, scope_note_ar, status)
akhlaq_principle_evidence(principle_slug, evidence_id, PRIMARY KEY(principle_slug,evidence_id))
akhlaq_behavior(slug PK, principle_slug, text_ar, polarity, observability, difficulty_floor)
akhlaq_scenario(slug PK, stem_ar, setting, difficulty, pressure_tags, evidence_ids, review_status)
akhlaq_scenario_subskill(scenario_slug, subskill_slug, PRIMARY KEY(scenario_slug,subskill_slug))
akhlaq_scenario_option(id PK, scenario_slug, ord, text_ar, dimension_tags, verdict, why_ar, evidence_ref)
akhlaq_probe(id PK, scenario_slug, phase, text_ar)          -- phase: before|after
akhlaq_conflict_script(slug PK, subskill_slugs, opening_ar, review_status)
akhlaq_conflict_turn(id PK, script_slug, ord, prompt_ar, options_json, transitions_json)
akhlaq_lesson(id PK, stage, ord, subskill_slug, title_ar, body_ar, mission_ar, est_minutes, status)
akhlaq_curriculum_stage(stage PK, title_ar, intro_ar, outcome_ar)
akhlaq_content_translation(ref_kind, ref_id, layer, lang, translation_type,
    text, translator, machine_model, translation_status, notes,
    reviewed_by, reviewed_at, PRIMARY KEY(ref_kind, ref_id, layer, lang))
    -- الأصل العربيّ يبقى في جداوله؛ هذا للترجمات فقط (AKHLAQ_TRANSLATION_MODEL §4)
akhlaq_review(id PK, ref_kind, ref_id, state, reviewer, checked_json, note_ar, reviewed_at)
    -- اختياريّ: طبقة مراجعة بشرية مستقبليّة؛ غيابه لا يمنع النشر
```

### 7.2 بيانات المستخدم (لا تُبذَر أبدًا)
```
akhlaq_attempt(id PK, subskill_slug, scenario_slug, chosen_option_id,
               dim_score_json, verdict, difficulty, answered_at)
akhlaq_probe_answer(attempt_id, probe_id, answer_text, PRIMARY KEY(attempt_id,probe_id))
akhlaq_conflict_run(id PK, script_slug, path_json, dim_totals_json, end_state, ran_at)
akhlaq_reflection(id PK, subskill_slug, kind, body_ar, mood, created_at)  -- kind: evening|weekly|note
akhlaq_mission_log(date TEXT, subskill_slug, done INTEGER, note_ar, PRIMARY KEY(date,subskill_slug))
akhlaq_sr_state(subskill_slug PK, track, interval_days, ease, difficulty, due_date, last_quality)
akhlaq_progress(subskill_slug PK, trend REAL, band TEXT, attempts INT, weak_dim TEXT, last_seen)
akhlaq_focus(week_start TEXT PRIMARY KEY, subskill_slug, note_ar)
akhlaq_meta(k PK, v)
```

### 7.3 المحرّكات = دوال نقيّة (isolate‑safe، كنمط `tajweed_svg.dart`)
- `evaluateOption(option) → DimScore`
- `rollSubskillTrend(attempts) → trend/band`
- `pickNextScenario(userState, subskill) → scenarioId`
- `conflictStep(runState, choice) → (nextTurn | endState, debrief)`
- `scheduleNext(srState, quality) → srState'`
- `todayPlan(allSrStates, focus) → List<TrainingItem>`
تُختبَر وحدةً بمدخلات ثابتة؛ لا I/O داخلها.

### 7.4 الطبقات (Flutter)
```
Widget  →  AkhlaqRepository (sqflite)  →  المحرّكات النقيّة
                    │
              AkhlaqSync (بذر من الأصول)
                    │
        assets/akhlaq/*.json.gz  ←  tool/build_akhlaq_corpus.py  ←  استخراج Turath
```
- `AkhlaqProvider` في `KnowledgeGateway` (domain `akhlaq`, dataState
  `local`) لعرض مادّة أخلاق مرتبطة في شاشات أخرى (فقه/حديث/سيرة/آية) عبر
  روابط `x_link`.
- إعادة استخدام: `knowledge_review_repository` (يمكن أن يستضيف مسار K)؛
  محرّك تحشية Turath للاقتباس في التدوين؛ `normalizeArabicForSearch` +
  FTS للبحث؛ `basicText()` ×13؛ نمط الترحيل ونمط `*Sync`.

---

## 8. البحث (لاحقًا) — محلّي، ليس محادثة AI

`akhlaq_fts` على (العُقَد + الأدلّة + الدروس)؛ تطبيع عربي؛ فهم نيّة
بالقواعد؛ نتائج مجمّعة بالمهارة مع مصادرها. تفصيله يُلحَق عند مرحلته.

---

## 9. الجودة (QA) — تحقّقٌ آليٌّ (`tool/akhlaq_validate.py`)

- **توثيق:** كل `hadith_marfu` بحالة `source_confirmed` له
  `grader`+`grading`+`takhrij` **كما وردت في المصدر** (لا تُختلَق)؛ القرآن
  مُقابَل بالمصحف المحلّي.
- **فصل رباعيّ:** Source / Translation / Explanation / Pedagogical —
  لا دمج. كل `principle`/`behavior` موسوم `interpretation_by = منهج
  التطبيق التربوي`؛ لا نسبة تفسير لعالِم؛ لا نسبة داخل الترجمة.
- **الترجمة:** لا ترجمة بلا `original_arabic`؛ `QURAN_MEANING` مترجمُه
  إصدارٌ مُرخَّص لا آليّ؛ كل وحدةٍ لها `translation_status` صريح.
- **عدم الحُكم:** لا سطر تقدّم يُخرج رقمًا للشخص؛ قائمة كلمات ممنوعة في
  المؤشّرات وأسئلة المحاسبة.
- **إنصاف المواقف:** لا موقف يجعل طرفَ مسألةٍ خلافيّةٍ «الخطأ»؛ كل
  `scenario` له `subskill` و`difficulty`.
- **الأنطولوجيا:** DAG على `requires`/`prerequisite_for`؛ لا يتامى؛ كل
  `vice` لها `opposite_of`.
- **لا بيانات وهمية ولا نصّ مختلَق** (فحص placeholders).
- تقرير `docs/akhlaq/reports/AKHLAQ_COVERAGE.md` + تقرير تحقّقٍ لكل شريحة
  (`AR-RIFQ_VALIDATION.md`).
- **المراجعة البشرية:** طبقةٌ اختياريّة مستقبليّة، **ليست شرط إطلاق**؛
  سجلّها (`akhlaq_review`) يُملأ إن/حين تُجرى.

اختبارات: `akhlaq_ontology_test` · `akhlaq_evidence_qa_test` ·
`akhlaq_behavior_test` · `akhlaq_scenario_engine_test` (تقييم/اختيار
تالٍ/محاكي خلاف كدوال نقيّة) · `akhlaq_sr_test` (الجدولة) ·
`akhlaq_repository_test`.

---

## 10. خارطة المراحل

| مرحلة | المحتوى | مُخرَج |
|---|---|---|
| **P0** ✅ | الفلسفة + الأنطولوجيا + نموذج السلوك + محرّك المواقف + نموذج الأدلّة + هذه المعمارية | وثائق، بلا كود |
| **P1 — Vertical Slice «الرفق»** | §11 | نموذج مرجعي كامل، على المحاكي |
| P2 | تكرار القالب: الصدق · التواضع · كظم الغيظ · حفظ اللسان · قبول الحقّ · أدب الخلاف | 6 وحدات |
| P3 | الهيكل التقني: ترحيلات v61+، `AkhlaqSync`، `AkhlaqRepository`، `build_akhlaq_corpus.py`، المحرّكات النقيّة + اختباراتها | كود أساس |
| P4 | شاشات: الرئيسية · الدرس · الموقف · المحاكي · المراجعة · الملف التدريبي | UI، تحقّق جهاز |
| P5 | التكرار المتباعد الحيّ + خطّة اليوم + التكامل مع مُحرّك الحياة | حلقة كاملة |
| P6 | المنهج (المراحل 1–7) دفعةً دفعة | منهج |
| P7 | محاكي الخلاف الموسّع + المستوى 8 (تزاحم الفضائل) | تدريب متقدّم |
| P8 | البحث المحلّي + الربط العرضي في الشاشات الأخرى | تكامل |
| P9 | بقيّة الفضائل والآداب + تقرير تغطية نهائي | توسيع |

> الترتيب مع الالتزامات الجارية (مُحرّك الحياة L6‑DYN) = قرار إسماعيل.

---

## 11. الشريحة الرأسية المرجعية: «الرفق» — **مُنجَزة كمواصفة محتوى**

المعمارية معتمَدة، ومرحلة CONTENT RESEARCH + TRANSLATION منجَزة:
`docs/akhlaq/alrifq/` (`AR-RIFQ_*` + `AR-RIFQ_TRANSLATION` + `ar-rifq.json`
+ `AR-RIFQ_VALIDATION`). التحقّق الآليّ أخضر. جاهزة للانتقال إلى **التنفيذ
البرمجيّ** (P3). الخطوات الأصليّة للقالب تبقى مرجعًا:

```text
1. الأنطولوجيا:
   virtue: الرفق (domain: rel_people)
   subskills: اختيار أرفق عبارة · تليين الصوت · التدرّج في البيان ·
              عدم التعنيف على الخطأ · الرفق بالسائل · احتمال جفاء الطالب
   opposite: الغلظة/العنف   |   tension_with: الغيرة على الحقّ
2. الأدلّة (A2، من الكوربوس المرشّح — الأدب المفرد، الآداب الشرعية،
   الشمائل، …): لكل subskill 2–4 نصوص verified (مصدر + تخريج/درجة من
   مصدرهما + معنى ميسّر).
3. المبادئ (تربوي، موسوم): مثل «الرفق لا يُناقض بيان الحقّ، بل هو طريقه
   الأبلغ».
4. المؤشّرات السلوكية: 5–8 لكل subskill (يختار أرفق عبارة قبل التصحيح ·
   لا يرفع صوته على المخطئ · يبدأ بالسؤال لا بالحكم · يُمهِل قبل الإنكار …).
5. المواقف: 10–12 موقفًا موزّعة على الصعوبات 1–8 (زميل أخطأ في مجلس ·
   سائل ألحّ بجفاء · مبتدئ كرّر السؤال · مخالف تعنيف · تصحيح أمام الناس ·
   خطأ في بحث منشور · موقف يجمع رفقًا + غيرةً + سترًا …)، خياراتها موسومة
   بالأبعاد + verdict + why + evidence_ref.
6. probes: «ما أوّل ما تحرّك فيك؟» / «أتريد تعليمه أم إسكاته؟».
7. الدرس اليومي + مهمّة: «اليوم إذا أخطأ معك أحد، لا تبدأ بالتصحيح؛ توقّف،
   ثمّ اختر أرفق عبارة تبيّن بها الخطأ».
8. المراجعة السلوكية: «آخر مرّة صحّحت لأحدٍ خطأً — بأيّ نبرة بدأت؟».
9. التكرار المتباعد: K/S/R على subskills الرفق بالفواصل §4.
10. الملف التدريبي: شريط «الرفق» + أضعف بُعد + جملة التحذير.
11. الترجمة الحرفيّة لكلّ نصٍّ وعنصر (`AR-RIFQ_TRANSLATION`) + تحقّقٌ آليّ
    (`tool/akhlaq_validate.py`) → PUBLISHABLE (المراجعة البشرية اختياريّة
    لاحقة).
```

معيار نجاح الشريحة: يمرّ متطوّع بها أسبوعًا، فيلاحظ في مواقف حقيقية أنّه
**توقّف واختار أرفق عبارة** — لا أنّه «قرأ عن الرفق». إن نجحت، تُنسَخ
حرفيًّا لبقيّة الفضائل.

---

## 12. المواءمة مع الوثائق السابقة

هذه المعمارية والوثائق الخمس **+ `AKHLAQ_TRANSLATION_MODEL`** هي **المرجع
الحاكم**. من `docs/akhlaq/` السابقة:
- **يبقى مرجعًا:** `AKHLAQ_SOURCES` · `AKHLAQ_SOURCE_SCAN` ·
  `AKHLAQ_SOURCE_SHORTLIST` (تُغذّي `AKHLAQ_EVIDENCE_MODEL`).
- **مطويّ هنا:** `AKHLAQ_KNOWLEDGE_MODEL` · `AKHLAQ_DATA_SCHEMA` ·
  `AKHLAQ_TAXONOMY` · `AKHLAQ_CURRICULUM` · `AKHLAQ_NOTEBOOK` ·
  `AKHLAQ_SEARCH` · `AKHLAQ_QA` · `AKHLAQ_ROADMAP` · `AKHLAQ_EXECUTION_PLAN`
  · `HUSN_AL_KHULUQ_MASTER` — محتواها الصالح انتقل إلى الوثائق الخمس +
  هذه؛ تُقرأ للسياق لا كمرجع أوّل. (`README.md` يوضّح ترتيب القراءة.)
