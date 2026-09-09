# docs/akhlaq/ — دليل القراءة

**المشروع:** *Akhlaq Training System for the Ṭālib al‑ʿIlm* — نظام تدريب
طالب العلم على حسن الخلق (معرفة → تدريب سلوكي → تكرار متباعد → عادة)، لا
مكتبة أخلاق. الحالة: **معمارية معتمَدة القراءة، بلا كود بعد.**

## الترتيب

1. **`AKHLAQ_SYSTEM_PHILOSOPHY.md`** — لماذا، وما الذي يُدرَّب، وما لا
   يجوز قياسه، وكيف نتجنّب score زائف. (يحكم كل ما بعده.)
2. **`AKHLAQ_ONTOLOGY.md`** — بنية الشخصية: 8 مجالات → فضائل → مهارات
   فرعية → أضداد، وعلاقاتها.
3. **`AKHLAQ_BEHAVIOR_MODEL.md`** — SOURCE → PRINCIPLE → BEHAVIOR، وفصل
   النصّ عن الاجتهاد التربوي، وما معنى «تحسّن».
4. **`AKHLAQ_SCENARIO_ENGINE.md`** — المواقف، الصعوبة 1–8، محاكي الخلاف
   (قواعد لا LLM)، ممنوعات gamification.
5. **`AKHLAQ_EVIDENCE_MODEL.md`** — تراتب المصادر، مخطّط الدليل، حالاته،
   خطّ الإنتاج، المراجعة البشرية.
6. **`AKHLAQ_TRANSLATION_MODEL.md`** — طبقة الترجمة: العربيّة = SOURCE OF
   TRUTH؛ ترجمة حرفيّة أمينة لكلّ لغةٍ ممكنة؛ الطبقات الأربع منفصلة
   (Source / Translation / Explanation / Pedagogical)؛ `translation_status`
   منفصلة عن `source_status`.
7. **`AKHLAQ_ARCHITECTURE.md`** — تجمع الكلّ، النموذج العلائقي، التكرار
   المتباعد، الملف التدريبي، خارطة المراحل، ومواصفة الشريحة الرأسية
   «الرفق».

## سياسة الاعتماد (2026‑09‑10)

**المراجعة البشرية ليست شرطًا.** الخطّ الأساسيّ = `Source‑grounded
automated validation`: SOURCE → FETCH → VERIFY METADATA → EXTRACT →
CLASSIFY → TRANSLATE → PEDAGOGICAL MODEL → `tool/akhlaq_validate.py` →
PUBLISHABLE. الـ`Human Review` طبقةٌ مستقبليّة اختياريّة؛ الـmetadata
تُحفَظ للتتبّع. `source_status` = درجة التحقّق من المصدر نفسه
(`source_confirmed` / `source_located` / `source_uncertain`)، لا تعني
«راجعها بشريّ».

## مراجع مساندة (تُغذّي نموذج الأدلّة)

- `AKHLAQ_SOURCES.md` — الانضباط التوثيقي التفصيلي.
- `AKHLAQ_SOURCE_SCAN.md` — فحص فعلي لفهرس Turath (40 تصنيفًا، 8593 كتابًا).
- `AKHLAQ_SOURCE_SHORTLIST.md` — ~55 كتابًا مرشّحًا بمعرّفاتها.
- `tool/scan_akhlaq_sources.py` — أداة المسح (قابلة لإعادة التشغيل).

## وثائق سابقة (مطويّة في الست أعلاه — للسياق فقط)

`HUSN_AL_KHULUQ_MASTER` · `AKHLAQ_KNOWLEDGE_MODEL` · `AKHLAQ_DATA_SCHEMA` ·
`AKHLAQ_TAXONOMY` · `AKHLAQ_CURRICULUM` · `AKHLAQ_NOTEBOOK` ·
`AKHLAQ_SEARCH` · `AKHLAQ_QA` · `AKHLAQ_ROADMAP` · `AKHLAQ_EXECUTION_PLAN`.
كُتِبت في جولة أولى بإطار «نظام معرفة»؛ محتواها الصالح انتقل إلى الوثائق
الست. لا تُعتمَد كمرجع أوّل.

## القرار المطلوب قبل P1

اعتماد المعمارية → ثمّ تبدأ **الشريحة الرأسية «الرفق»** (`AKHLAQ_ARCHITECTURE
§11`) وحدها، كنموذج مرجعي، قبل استخراج أيّ محتوى واسع. الترتيب مع مُحرّك
الحياة L6‑DYN = قرار إسماعيل.
