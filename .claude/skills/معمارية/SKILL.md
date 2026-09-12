---
name: معمارية
description: >-
  Load before ANY new feature, table, repository, or screen in TalibAlIlmApp
  that might touch a concept the app already models — Quran text/tafsir/
  translation/corpus, mushaf rendering, akhlaq/training, life planning,
  mosque platform, Supabase sync, study intelligence. This is the master
  index of every architecture document in the repo, one line each, so an
  existing system is found and extended BEFORE a parallel one gets built by
  accident. Also load when asked to "audit the architecture", "list the
  architectures", or improve/unify a weak one.
---

# معمارية — فهرس كل العمارات في طالب العلم

هذا الفهرس وُلد من درسٍ حقيقي: **نظاما تفسير منفصلان** (`tafsir_entries`
القديم مقابل `quran_tafsir_book`/`QuranBookCache` الأحدث) بُنيا بفارق ٥٢
نسخة قاعدة بيانات دون أن يعرف أحدهما بوجود الآخر — النتيجة: مستخدمٌ يختار
أحد ١٢٢ تفسيرًا في شاشةٍ، ويُفتَح له تفسيرٌ آخر تمامًا في الشاشة التالية
(`docs/quran/TAFSIR_UNIFIED_ARCHITECTURE.md §٢`). **هذا الفهرس موجودٌ
ليمنع تكرار هذا الخطأ**: قبل أن تبني جدولًا أو مستودعًا أو نظامًا جديدًا،
افحص أولًا إن كان هناك نظامٌ سابق لنفس المفهوم أدناه.

## قاعدة العمل

1. **قبل أي قرار معماري جديد**: ابحث في الجدول أدناه عن المجال الأقرب
   لما تبنيه. إن وجدت نظامًا قائمًا لنفس المفهوم (حتى لو باسمٍ مختلف)،
   **وسِّعه أو وحِّده — لا تُنشئ نظامًا موازيًا**.
2. **عند إضافة معمارية جديدة أو تعديل جوهري في معماريةٍ قائمة**: أضف
   سطرًا هنا (أو حدِّث السطر القائم) بمجرد إنشاء/تعديل الوثيقة — لا يُترَك
   الفهرس ليصبح قديمًا.
3. **عند رصد تشرذمٍ معماريّ** (نظامان يخدمان نفس المفهوم): وثِّقه في ملفٍ
   بنمط `docs/**/*_UNIFIED_ARCHITECTURE.md` (كما فُعل مع التفسير)، لا
   تُصلحه بترقيعٍ في الشاشة فقط.
4. **الحالة (تيّار/قديم) في هذا الفهرس معلوماتٌ لحظةَ الكتابة** — تحقّق من
   حداثتها بقراءة الوثيقة نفسها قبل الاعتماد عليها كمرجعٍ نهائي.

## فهرس العمارات بحسب المجال

### القرآن — النصّ والمصحف والتخطيط
| الوثيقة | الغرض | الحالة |
|---|---|---|
| `docs/quran/MUSHAF_MASTER_ARCHITECTURE.md` | العمارة الشمالية (north-star) لكل تجربة المصحف — ١٠ طبقات، خطّة بناء A→G | **متناقضة داخليًّا**: مخطّط الطبقة-٣ قديمٌ لم يُنفَّذ هكذا فعليًّا (وصف جدول SQL بدل ملفات gz فعلية)؛ جدول الحالة في آخرها محدَّث ومطابق للكود |
| `docs/quran/MUSHAF_ENGINEERING.md` | هندسة المصحف المطبوع؛ ما يمكن/لا يمكن لتخطيط الصفحة إخباره | حاليّة |
| `docs/quran/MUSHAF_ENGINE_REBUILD.md` | تدقيق إعادة بناء محرّك العرض | **تدقيقٌ مُسلَّم، لم يُبنَ بعد** |
| `docs/quran/QURAN_DATA_MODEL.md` | التسلسل الهرمي قرآن→سورة→آية→كلمة→حرف؛ أشكال النصّ الأربعة | مرجعيّة |
| `docs/quran/QURAN_LAYOUT.md` | صفحات/أسطر/علامات/تقسيمات؛ خصوصية الإصدار | حاليّة |
| `docs/quran/QURAN_INTERACTION.md` | اختبار النقر، تحويل الإحداثيات، التحديد | حاليّة |
| `docs/quran/QURAN_TERMINOLOGY.md` | قاموس المصطلحات (رسم، ضبط، رواية، وقف، جزء...) | مرجعيّة |
| `docs/quran/ERRATA.md` | أخطاءٌ سابقة + القاعدة الدائمة الناتجة عن كلٍّ منها | **اقرأه قبل تكرار نمط** |
| `docs/quran/QURAN_PREMIUM_UI.md` | لغة التصميم البصري/الحركي المتقنة لكل واجهات القرآن | حاليّة |
| `docs/quran/SOURCES.md` | سجلّ مصادر النصّ والتخطيط (Tanzil، KFGQPC، MushafDatabase) | حاليّة |
| `docs/quran/TAJWEED_RENDERING_ANALYSIS.md` | تحليل تلوين التجويد على مستوى الحرف | حاليّة، §٩ قائمة تحقّق الجهاز |
| `docs/quran/QURAN_WORD_ALIGNMENT_REPORT.md` | تقرير مطابقة Tanzil↔MushafDatabase | تقرير منجَز |
| `docs/quran/MUSHAF_RECTO_VERSO_DIAGNOSIS.md` | تشخيص وجهي الصفحة | تقرير |
| `docs/quran/QURAN_UNIFIED_READER_P0_STATUS.md` | حالة القارئ الموحَّد P0 | تقرير حالة |
| `docs/MUSHAF_DATABASE_INTEGRATION_DESIGN.md` | تصميم دمج MushafDatabase | تصميم |
| `docs/MUSHAF_SEMANTIC_LAYER.md` | الطبقة الدلالية فوق هندسة المصحف | تصميم |

### القرآن — التفسير والترجمة والكوربص (Corpus)
| الوثيقة | الغرض | الحالة |
|---|---|---|
| `docs/quran/TAFSIR_UNIFIED_ARCHITECTURE.md` | **وثيقة التوحيد** — ثلاث منظومات تفسير/ترجمة متوازية (A: `tafsir_entries` القديم، B: `quran_tafsir_book`/`QuranBookCache`، C: `quran_translation_edition`)، سبب عطل "٥ تفاسير فقط"، الإصلاح، وفجوة الحواشي التفسيرية للغات (أمهرية/أورومو) | **حاليّة، الأحدث** (٢٠٢٦-٠٩-١١) — المرجع الأول لأي عمل تفسير/ترجمة |
| `docs/quran/QURAN_CORPUS_INTEGRATION.md` | تكامل QC1-QC5a (المورفولوجيا، الإعراب، التفسير المُجمَّع، الأسباب، إلخ) | حاليّة إلى حدٍّ بعيد (٢٠٢٦-٠٩-٠٣)، لم تُحدَّث بعد بإصلاح ٢٠٢٦-٠٩-١١ |
| `docs/QURAN_DATA_CONTRACTS.md` | عقود البيانات لكل طبقة — يُشكِّل النظام A فقط (`TafsirEntry`) | **قديمة جزئيًّا** — لا تذكر النظام B/C إطلاقًا |
| `docs/QURAN_SOURCES_AND_LICENSES.md` | سجلّ تراخيص مصادر التفسير/الترجمة (QuranEnc، rwwad...) | حاليّة |
| `docs/quran/QURAN_LIVE_DATA_ARCHITECTURE.md` | خطّة البيانات الحيّة/مرآة Supabase | يشير للنظام A فقط؛ يحتاج تحديثًا بعد التوحيد |
| `QURAN_COMPANION_ROADMAP.md` (جذر المستودع) | خارطة الطريق الأصلية (النظام A نشأ هنا، Phase 0) | تاريخية، لا تزال تُستشهَد بها في تعليقات الكود |

### القرآن — طبقة التعلّم (Quran Learning Engine)
| الوثيقة | الغرض | الحالة |
|---|---|---|
| `docs/quran/QURAN_LEARNING_LAYER.md` | التصميم المُوحَّد المرجعي لمحرّك التعلّم | تصميم، غير مُعتمَد للبناء الكامل بعد |
| `docs/quran/QURAN_LEARNING_READINESS.md` | تدقيق قدرات مبنيّ على الكود | **قديمة** — تسبق QC2/QC3 (لا تذكر النظام B/`AyahTafsirPanel` إطلاقًا) |
| `docs/QURAN_LEARNING_ARCHITECTURE.md` | مؤشّرٌ رقيق يحيل لِـ`QURAN_LEARNING_LAYER.md` | ملحق |
| `docs/QURAN_LEARNING_ROADMAP.md` | خارطة طريق طبقة التعلّم | ملحق |
| `docs/QURAN_DATA_VALIDATION.md` | قواعد تحقّق بيانات التعلّم | ملحق |
| `docs/quran/QURAN_DATA_VERIFICATION_TASKS.md` | نتائج فحص التراخيص | تقرير |
| `docs/quran/KNOWLEDGE.md` | خريطة متطلَّب→نموذج→مصدر حقيقة لكل نوع ميزة (R-1..R-17) | مرجعيّة أساسية |

### الأخلاق والآداب (AKHLAQ) — نظام تدريب كامل
| الوثيقة | الغرض | الحالة |
|---|---|---|
| `docs/akhlaq/README.md` | نقطة الدخول + سياسة الاعتماد | حاليّة |
| `docs/akhlaq/AKHLAQ_ARCHITECTURE.md` | العمارة الكاملة (الطبقات السبع، حلقة SR، schema، خارطة المراحل P0-P9) | حاليّة، الأدقّ |
| `docs/akhlaq/AKHLAQ_SYSTEM_PHILOSOPHY.md` | الفرق بين المعرفة الخلقية والخُلُق؛ منع المؤشّر المزيَّف | حاليّة |
| `docs/akhlaq/AKHLAQ_ONTOLOGY.md` | مجال→فضيلة→مهارة فرعية→رذيلة؛ أنواع الحواف | حاليّة |
| `docs/akhlaq/AKHLAQ_BEHAVIOR_MODEL.md` | مصدر→إسناد→نصّ→معنى→مبدأ→سلوك→موقف→تأمّل→تكرار | حاليّة |
| `docs/akhlaq/AKHLAQ_SCENARIO_ENGINE.md` | مخطّط الموقف/الخيار، سلّم الصعوبة، محاكي الخلاف | حاليّة |
| `docs/akhlaq/AKHLAQ_EVIDENCE_MODEL.md` | هرم المصادر الستّ، `source_status`، خطّ الأنابيب | حاليّة (سياسة التحقّق الآلي ٢٠٢٦-٠٩-١٠) |
| `docs/akhlaq/AKHLAQ_TRANSLATION_MODEL.md` | طبقة الترجمة (العربية أصل الحقيقة، الفصل الرباعي) | حاليّة |
| `docs/akhlaq/AKHLAQ_CURRICULUM.md` / `AKHLAQ_NOTEBOOK.md` / `AKHLAQ_SEARCH.md` / `AKHLAQ_QA.md` | تفاصيل المنهج/الدفتر/البحث/الجودة | حاليّة |
| `docs/akhlaq/AKHLAQ_ROADMAP.md` / `AKHLAQ_EXECUTION_PLAN.md` | خارطة الطريق وقرارات إسماعيل | حاليّة |
| `docs/akhlaq/HUSN_AL_KHULUQ_MASTER.md` وملفّات `AKHLAQ_TAXONOMY/KNOWLEDGE_MODEL/DATA_SCHEMA/SOURCES/SOURCE_SCAN/SOURCE_SHORTLIST` | **الجولة الأولى (A0)** — تصنيف سداسي، مصادر أوّلية | **يحمل بعضها لافتة «تجاوزتها جولةٌ لاحقة»** — مدخلاتٌ لنموذج الأدلّة، ليست مرجعًا معماريًّا نهائيًّا |
| `docs/akhlaq/adab_book/ADAB_UNWAN_ALSAADAH_SOURCE*.md` (P1-P8) | بحث مصدر كتيّب «الأدب عنوان السعادة» — ٣٩ دليلًا | حاليّة، بحثٌ منتهٍ |
| `docs/akhlaq/adab_book/AR-IYADAH_BEHAVIOR_MAP.md` + `_SCENARIOS.md` | الشريحة الرأسية الثانية «عيادة المريض» | حاليّة، منفَّذة كودًا |
| `docs/akhlaq/alrifq/*.md` | الشريحة الرأسية الأولى «الرفق» (المرجع القالبي) | حاليّة، منفَّذة كودًا وشاشات |

### مُحرّك الحياة (Life Engine)
| الوثيقة | الغرض | الحالة |
|---|---|---|
| `docs/LIFE_ENGINE.md` | العمارة الكاملة: ٧ ركائز، ٢٣ خانة، `dayIndex` مفتوح، §٧ خارطة L6-DYN (١٥ ترقية) | حاليّة، مرجعٌ حيّ يُحدَّث مع كل ترقية |

### مسجدنا (Mosque Platform)
| الوثيقة | الغرض | الحالة |
|---|---|---|
| `docs/mosque/01_ARCHITECTURE.md` | العمارة الخلفية (Backend + Telegram bot + API) | حاليّة |
| `docs/mosque/ACTIVATION.md` | تفعيل مسجدٍ جديد | دليل تشغيلي |
| `docs/mosque/TELEGRAM_BOT.md` | بوت تيليجرام | دليل تشغيلي |
| `docs/MOSQUE_PLATFORM_VISION.md` | الرؤية الأصلية قبل التنفيذ | تاريخية |

### Supabase والمزامنة السحابية
| الوثيقة | الغرض | الحالة |
|---|---|---|
| `docs/SUPABASE_ARCHITECTURE.md` | طبقة معرفة مركزية: مرآة offline-first، محرّك مزامنة، بحث هجين | **مصمَّمة، غير مبنيّة** — تشير لـ`tafsir_entries`/`tafsir_editions` (إطار النظام A فقط، يحتاج مراجعة بعد `TAFSIR_UNIFIED_ARCHITECTURE.md`) |

### الذكاء الدراسي والدفاتر (Study Intelligence / Annotations)
| الوثيقة | الغرض | الحالة |
|---|---|---|
| `docs/STUDY_INTELLIGENCE_VISION.md` / `STUDY_INTELLIGENCE_ENGINE_SPEC.md` | محرّكٌ حتميّ (لا AI) لترتيب الأولويات الدراسية | تصميم، الكود لا يزال على مرحلة ٧٩-sa-D |
| `docs/STUDY_ANNOTATIONS_DESIGN.md` | نموذج التظليل/الملاحظات الموحَّد | حاليّة (`turath-study-annotations` مهارة شقيقة) |
| `docs/AYAH_STUDY_NOTEBOOK_DESIGN.md` | دفتر دراسة الآية | تصميم |
| `docs/TURATH_INTEGRATION.md` | تكامل مكتبة تراث | حاليّة |

### أخرى (تصميم/محتوى، لا عمارة بيانات)
`docs/PDF_DOWNLOAD_DESIGN.md`، `docs/ANIMATION_ASSET_PLAN.md`،
`docs/DESIGN_SYSTEM_3D.md`، `docs/MOTION_BIBLE.md`،
`docs/ADHKAR_AUDIO_SOURCES.md`، `docs/CUSTOMIZATION_IDEAS.md`،
`docs/COMPANION_CHAT_100_IDEAS.md`، `LICENSED_CONTENT_SOURCES.md`،
`100_IDEAS_FOR_IMPROVEMENT.md` — أفكار/تصميم بصري/تراخيص، لا تتطلّب نفس
انضباط "افحص قبل أن تبني نظامًا موازيًا"، لكنها مذكورة للاكتمال.

## مهارات شقيقة (لا تكرّرها هنا، حمِّلها إن كان عملك يمسّها)

`quran-engineering` (قواعد هندسة القرآن العامة) ·
`quran-unified-reader` (معمارية القارئ التشغيلية) ·
`quran-premium-3d-ui` (لغة التصميم) ·
`turath-study-annotations` (نموذج التظليل/الملاحظات) ·
`app-translations` (نمط `basicText()`) ·
`device-testing-adb` (التحقّق على الجهاز/المحاكي).
