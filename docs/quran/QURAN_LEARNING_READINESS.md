# Quran Learning Layer — Architecture Readiness Audit

**Method:** the actual code and data were opened and checked (not the design
docs). Date: 2026‑08‑30. Scope: everything `QURAN_LEARNING_LAYER.md`
depends on. **No "can" from design — only what the repo actually has.**

Files/tables inspected: `lib/db/database_helper.dart` (v51, every
`CREATE TABLE`), `quran_ayat`, `mushaf_*`, `ayah_study_entries` /
`ayah_entry_links`, `tafsir_entries` + `assets/quran/tafsir-*.jsonl.gz`,
`lib/repositories/*` (44 files), `lib/models/ayah_study_entry.dart`,
`lib/data/tajweed_curriculum.dart`, `lib/data/arabic_curriculum.dart`,
`lib/l10n/basic_translations.dart`, the mushaf/notebook/tafsir screens and
their navigation.

---

## 1. What actually exists (verified)

| thing | state | evidence |
|---|---|---|
| **`quran_ayat`** — `surah, ayah, text_uthmani, text_normalized, page_number, juz_number, hizb_number` (Tanzil v1.1), indexed on `text_normalized` + `page_number` | **populated** by `QuranImportService` on first run | `database_helper.dart:272`, `:1270` (hizb), `:1656` (page idx); `quran_import_service.dart` |
| **`mushaf_pages / mushaf_lines / mushaf_words / mushaf_aya_marks / mushaf_markers / mushaf_meta`** — word = `(page, line, word_order, surah, ayah, word_index, word_type, text_uthmani, text_imlaey, bbox_*)` | **seeded** from `assets/mushaf/mushaf_layout.json.gz` by `MushafLayoutSync`; 604 pages / 91 451 words / 6 236 aya‑marks, validated vs canonical counts | `database_helper.dart:1665`; `mushaf_layout_sync.dart`; 17 passing tests |
| **`MushafLayoutRepository`** — `pageLayout`, `wordsForAyah`, `pageForAyah`, `pageForReference`, `ayahBoxesOnPage`, `pageRangeForSurah`, `isReady`, `pageCount` | **works** (read‑only, pure) | `mushaf_layout_repository.dart` |
| **`MushafSemanticReaderScreen`** — RTL PageView over 604 pages; tap word → sheet(surah, ayah, word_index, page·line, type) + "دفتري لهذه الآية" → `AyahNotebookScreen`; long‑press → notebook | **word identity resolution works**; **visual render is broken** (`ERRATA` E‑1: `MushafPageView` draws `data-hafs` in `DigitalKhattMadina` inside each glyph bbox via `FittedBox` → garbled) | `mushaf_semantic_reader_screen.dart:251`; `mushaf_page_view.dart:164` |
| old **`quran_reading_screen`** mushaf render + tap | **ayah‑level tap only** (`_onAyahTap`); word `GestureDetector`s call the *ayah* handler; no word identity | `quran_reading_screen.dart:938, 1239, 1526` |
| **`ayah_study_entries`** (v50) — `surah, ayah, word_start?, word_end?, entry_type(14 vals incl. linguistic/fiqh/aqeedah/hadith/lesson_summary), topic, stance(naql/fahm/istinbat/sual), color_key, body, source_type/name/author/ref/date/detail (free text), status(none/open/resolved), sort_order, timestamps` | **works** | `database_helper.dart:1612`; `ayah_study_entry.dart` |
| **`AyahStudyRepository`** — add/update/setStatus/setSortOrder/delete/entryById/entriesForAyah/countForAyah/typeCountsForAyah/notebookEntries/ayatWithEntries/distinctTopics | **works** | `ayah_study_repository.dart` |
| **`AyahNotebookScreen(surah, ayah, openAdd)`** + **`QuranNotebookHomeScreen`** (cross‑ayah, search/filter/sort) | **works, deep‑linkable** | `ayah_notebook_screen.dart:24`; `quran_notebook_home_screen.dart` |
| **`tafsir_entries`** + **~48 editions** (AR: `ibn_kathir_full, almukhtasar, muyassar, saadi, ibn_ashur`; +~43 language editions) | **imported**, verbatim, per edition | `database_helper.dart:286`; `quran_import_service.dart:259`; `assets/quran/tafsir-*.jsonl.gz` |
| **`AyahStudyScreen`** (Phase 72) — every tafsir/translation source for an ayah as cards + reader + 2–4‑way compare; deterministic, no AI | **works, deep‑linkable** `(surah, ayah[, initialSource])` | `ayah_study_screen.dart`; `quran_reading_repository.dart` `tafsirEntriesForAyah` |
| **`tajweed_curriculum.dart`** — `TajweedRule{titleAr, titleEn, explanationEn, exampleAr, exampleNote}` in 3 tiers; original authored explanations; cites Tuḥfat al‑Aṭfāl + al‑Jazariyyah (citation‑only) | **exists** — this is *LearningLesson‑grade tajwīd content* already | `lib/data/tajweed_curriculum.dart`; `TajweedScreen`; `tajweed_resources_screen.dart`; `tajweed_progress` table + `TajweedRepository` |
| **`arabic_curriculum.dart`** — adult non‑native Arabic course, stages 1–3 populated (alphabet→reading→vocab), 4–5 outlined; cites Madīnah course + al‑ʿArabiyyah Bayna Yadayk | **exists** (general, not per‑ayah iʿrāb) | `lib/data/arabic_curriculum.dart`; `ArabicCurriculumScreen`; `arabic_curriculum_progress`; `arabic_resources_screen.dart` |
| **Islamic text libraries** — `nawawi_hadiths` (+`HadithRepository`), `wasitiyyah_sections` (aqīdah), `zad_almaad_chapters` (fiqh/sīrah), `madarij_sections` | **built**, own screens; **not yet ayah‑linked** | `database_helper.dart:451, 473, 497, 524` |
| **`KnowledgeReviewRepository`** — SM‑2‑style spaced repetition keyed by `(itemType, itemId)`: `startReviewing / recordReview / dueToday / dueTodayAll` | **works** — a usable review substrate (not the full maths engine) | `lib/repositories/knowledge_review_repository.dart`; `knowledge_review_progress` table |
| **`basic_translations.dart`** — `basicText()`, 13 languages, ~4560 lines | **works** (UI strings, not content) | `lib/l10n/basic_translations.dart` |

## 2. What does NOT exist (verified absent)

| thing | evidence of absence |
|---|---|
| **`StudyItem` / `StudyEvent`** tables or code | grep: appear **only in comments** in `database_helper.dart` ("later, clean merge"); no `study_items` / `study_events` table; no model |
| **`KnowledgeAnchor` / `KnowledgeEdge` / `KnowledgeFact` / `KnowledgeConcept` / `LearningLesson` / `SourceReference`** | grep across `lib/`: **none** (design docs only) |
| **`knowledge_facts` / `syntax_nodes` / `syntax_relations` / `learning_lessons` / `learning_path_items` / `source_references`** tables | not in the 90 `CREATE TABLE` statements |
| **per‑word morphology (ṣarf)** data — root/lemma/pattern/POS/features | no table, no asset |
| **per‑word / per‑ayah syntax (iʿrāb)** data | no table, no asset |
| **per‑position tajwīd rule spans** ("which rule is at *this* spot") | `tajweed_curriculum.dart` has rule *lessons*, not spans; no `tajweed_rules` table |
| **word‑by‑word meaning (gloss)** data | tafsir editions are **ayah‑level**; no word‑level gloss |
| **`concept_id`** on `ayah_study_entries`; **`concept_note`** entry_type | schema `database_helper.dart:1612` has neither |
| **`ayah_entry_links`** usage | table created (`:1642`), **never read/written** in `lib/` — ships empty |
| **unified "المصادر والتراخيص" screen / `SourceReference` registry** | only per‑topic `*_resources_screen.dart` (arabic/salah/tajweed) with cited book titles; no central registry |
| **Mathematical Study Intelligence engine** | design only (`docs/STUDY_INTELLIGENCE_ENGINE_SPEC.md`) |
| **real mushaf visual (SVG page art) render** | SVGs exist locally (git‑ignored), not bundled, not rendered; `MushafPageView` fakes it (E‑1) |
| **word audio / recitation‑follow** | no audio adapter; `L‑AUDIO` is API‑only anyway |
| **Tanzil ↔ MushafDatabase word alignment (VT‑3)** | tool designed, **not written / not run**; no `assets/quran_learning/mapping/*.json` |

---

## 3. Capability table

Legend: ✅ = yes · ⚠️ = partial · ❌ = no.

| Capability | موجود فعليًا | قابل للتشغيل الآن | يحتاج بيانات خارجية | يحتاج ترخيص | يحتاج كود | المصدر / الملف |
|---|---|---|---|---|---|---|
| فتح المصحف والقراءة والتنقّل (جزء/سورة/صفحة) | ✅ | ✅ | ❌ | ❌ | ❌ | `quran_reading_screen`, `quran_ayat` |
| ضغط **الآية** → قائمة (تفسير/دفتر/تلاوة/ترجمة/استماع/مفضلة) | ✅ | ✅ | ❌ | ❌ | ❌ | `quran_reading_screen.dart:957` |
| ضغط **الكلمة** → استخراج `(surah, ayah, word_index)` | ✅ (بيانات+repo) | ⚠️ (الهوية تعمل، الرسم مشوَّه) | ❌ | ❌ | ✅ (إصلاح الرسم E‑1) | `mushaf_words`, `MushafLayoutRepository`, `MushafSemanticReaderScreen` |
| عرض **رسم صفحة المصحف الحقيقي** (فنّ الطباعة) | ⚠️ (SVG محليًّا، غير مُحزَّم) | ❌ | ❌ (المصدر موجود) | ❌ (صدقة جارية) | ✅ (`flutter_svg` + تحزيم/كسول) | MushafDatabase V1.01 SVG |
| **تفسير** متعدّد النسخ لكل آية (5 عربية + ~43 لغة)، حرفيًّا | ✅ | ✅ | ❌ | ❌ | ❌ | `tafsir_entries`, `AyahStudyScreen` |
| **معنى/ترجمة الآية** (~43 لغة، على مستوى الآية) | ✅ | ✅ | ❌ | ❌ | ❌ | `tafsir_entries` (نسخ لغوية) |
| **دفتر الآية**: كتابة ملاحظة + نوع + stance + مصدر حرّ + حالة + ترتيب | ✅ | ✅ | ❌ | ❌ | ❌ | `ayah_study_entries`, `AyahNotebookScreen` |
| **دفتر عبر الآيات** (بحث/فلترة/ترتيب/الأكثر ثراءً) | ✅ | ✅ | ❌ | ❌ | ❌ | `QuranNotebookHomeScreen` |
| deep‑link `(surah, ayah)` → الدفتر / الدراسة / صفحة المصحف | ✅ | ✅ | ❌ | ❌ | ❌ | repos + screens |
| **مرساة نطاق كلمات لملاحظة** (`word_start/word_end`) | ⚠️ (العمود موجود) | ❌ | ❌ | ❌ | ✅ (إيماءة تحديد + ربط) | `ayah_study_entries` |
| **محتوى دروس التجويد** (قواعد + شرح + أمثلة) | ✅ (مؤلَّف، معزوّ) | ✅ (شاشة التجويد) | ❌ | ❌ | ⚠️ (ربطه بالكلمة/الآية) | `tajweed_curriculum.dart` |
| **منهج تعلّم العربية** (مراحل 1–3) | ✅ | ✅ | ❌ | ❌ | ❌ | `arabic_curriculum.dart` |
| مكتبات **الحديث/العقيدة/الفقه** (نصوص) | ✅ | ✅ (شاشاتها) | ❌ | ❌ | ⚠️ (ربطها بالآية) | `nawawi_hadiths`, `wasitiyyah_sections`, `zad_almaad_chapters`, `madarij_sections` |
| جدولة **مراجعة** (SM‑2) لعنصر `(itemType, itemId)` | ✅ | ✅ | ❌ | ❌ | ⚠️ (ربط مفاهيم/آيات به) | `KnowledgeReviewRepository`, `knowledge_review_progress` |
| **الكلمة → الصرف** (جذر/لمّة/وزن/خصائص) | ❌ | ❌ | ✅ MASAQ/QAC | ✅ **واضح** (MASAQ CC BY 4.0 · QAC حرفي+عزو+رابط) | ✅ (مستورِد + جدول + VT‑3 + بطاقة) | MASAQ v5 / QAC v0.4 |
| **الكلمة → النحو/الإعراب** (رسم بياني تفاعلي) | ❌ | ❌ | ✅ MASAQ | ✅ **واضح** (CC BY 4.0) | ✅ (جداول + مستورِد + تعيين 72 دورًا + widget الرسم) | MASAQ v5 |
| **الموضع → حكم تجويدي** (أي حكم هنا) | ❌ | ❌ | ✅ cpfair/quran‑tajweed | ✅ **واضح** (CC BY 4.0) | ✅ (مستورِد + **إعادة تعيين الإزاحات VT‑3** + جدول + طبقة عرض) | cpfair/quran‑tajweed |
| **الكلمة → معنى مفرد (gloss)** | ❌ | ❌ | ✅ QUL word‑translations | ⚠️ **غير مؤكَّد لكل مورد** | ✅ | QUL |
| جداول **`KnowledgeConcept` / `LearningLesson` / `KnowledgeAnchor` / `KnowledgeEdge` / `KnowledgeFact`** + `LearningGateway` + adapters | ❌ | ❌ | ❌ | ❌ | ✅ (كود صرف) | `QURAN_DATA_CONTRACTS.md` |
| زر **«تعلّم هذا»** ونقل مفهوم إلى الدفتر (`concept_id` + `concept_note` + `learning_path_items`) | ❌ | ❌ | ❌ | ❌ | ✅ (migration صغيرة + UI) | `QURAN_LEARNING_LAYER.md` §9 |
| **سجل `StudyEvent`** + إسقاط `StudyItem` | ❌ | ❌ | ❌ | ❌ | ✅ (كود صرف) | `QURAN_DATA_CONTRACTS.md` §12–13 |
| **جدول `SourceReference` + شاشة «المصادر والتراخيص» موحّدة** | ❌ | ❌ | ❌ (سجلّنا نحن) | ❌ | ✅ (كود صرف) | `QURAN_SOURCES_AND_LICENSES.md` |
| **المحرك الرياضي** للحفظ/الدراسة | ❌ | ❌ | ❌ | ❌ | ✅ (يحتاج `StudyEvent` أولًا) | `STUDY_INTELLIGENCE_ENGINE_SPEC.md` |
| **صوت الكلمة + متابعة التلاوة** | ❌ | ⚠️ (بث فقط) | ✅ QF Audio API | ⚠️ **بث فقط، لا تحزيم** (Developer Terms) | ✅ (adapter بث) | Quran Foundation Audio API |
| **أداة محاذاة Tanzil ↔ MushafDatabase (VT‑3)** | ❌ | ❌ | ❌ | ❌ | ✅ (سكربت مرة واحدة) | `QURAN_WORD_ALIGNMENT_REPORT.md` |
| **بيانات الحركات (per‑diacritic)** | ❌ | ❌ | ⚠️ (لدينا المصدر، لم يُستخرَج) | ❌ (صدقة جارية) | ✅ (تمريرة استخراج جديدة من SVG) | MushafDatabase SVG |

---

## 4. Path test — `Quran Page → Word → Knowledge → Learning Lesson → Student Notebook → Return to Quran`

| step | state | detail |
|---|---|---|
| **Quran Page → Word** | ⚠️ | `MushafSemanticReaderScreen` tap → `(surah, ayah, word_index)` **works**; the **page visual is garbled** (E‑1). The old `quran_reading_screen` gives **ayah‑level** tap only (visual fine). So: word identity ✅, word‑level *usable UI* ❌ until the SVG render is built. |
| **Word → Knowledge** | ❌ | **This is the one broken link.** No `knowledge_facts`; no morphology/syntax/tajwīd‑span data; the word sheet shows only position facts (surah/ayah/word_index/page/line). |
| **Knowledge → Learning Lesson** | ⚠️ | Tajwīd **lessons exist** (`tajweed_curriculum.dart`, cited) but are **not linked** from a word/ayah; no `learning_lessons` / `knowledge_concepts` table; no `concept_id`. |
| **Learning Lesson → Student Notebook** | ⚠️ | Notebook **exists** and takes `entry_type` + free‑text source; **no `concept_id` link, no "تعلّم هذا" action, no `learning_path_items`**. |
| **Student Notebook → Return to Quran** | ✅ | `AyahNotebookScreen(surah, ayah)` is deep‑linkable; `MushafLayoutRepository.pageForAyah` resolves the page + `ayahBoxesOnPage` gives highlight geometry. Word‑level return anchor (`word_start/word_end`) is a **column, not a wired UI**. |

**Conclusion:** the chain's **two ends work today**. It is severed in the
middle at **Word → Knowledge** (no data + no tables) and only loosely joined
at **Knowledge → Lesson → Notebook** (tables + link + action missing, but the
*content* for tajwīd already exists).

---

## READY NOW

Buildable today with data present + licence clear + only ordinary code:

1. **`SourceReference` table + a unified "المصادر والتراخيص" screen.** Pure
   code over our own registry (`QURAN_SOURCES_AND_LICENSES.md`). Unblocks
   every "من أين جاء هذا؟".
2. **`StudyEvent` append‑only log + `StudyItem` projection.** Pure code.
   Nothing else needs it yet, but it un‑gates the maths engine later and is
   cheap now.
3. **Notebook ↔ concept plumbing:** add `concept_id` (nullable) +
   `concept_note` entry_type to `ayah_study_entries`; add `learning_path_items`;
   wire **«تعلّم هذا»** and **«طبّق ما تعلمت»** (deep‑link back to
   `(surah, ayah)`). Tiny migration + UI. No external data.
4. **`KnowledgeConcept` / `LearningLesson` tables seeded from
   `tajweed_curriculum.dart`.** The tajwīd lesson content already exists and
   is cited — turn each `TajweedRule` into a `LearningConcept` +
   `LearningLesson` and link concepts to the notebook. **Zero new data.**
5. **Fix the semantic reader visual** — render the real MushafDatabase SVG
   (`flutter_svg`) + a "Mushaf Data Package" (download‑all or lazy). Data +
   licence ready; engineering only. This makes **Quran Page → Word** a real
   UI.
6. **Wire `word_start/word_end`** — a word‑range selection gesture on the
   mushaf → store on a note. Our own segmentation, no VT‑3 needed for this.
7. **Link the existing Islamic text libraries to ayat** — a
   `KnowledgeEdge` `ayah ──related_to──▶ {hadith|aqeedah|fiqh section}`,
   hand‑curated at first. Content is already in the app.
8. **Multi‑edition tafsīr / ~43‑language meaning per ayah** — already live;
   just surface it as a launcher row in the word/ayah panel.

The smallest end‑to‑end proof combining 3–5 above is the **MVLD** below.

## BLOCKED BY DATA

Missing a data source (licence would be fine or is not the gate):

1. **Word‑by‑word meaning (gloss).** No source in the app. QUL word‑
   translations is the candidate — see *Blocked by licence* (its licence is
   also unverified, so it's doubly gated).
2. **Ḥadīth ↔ ayah automatic links at scale.** We have ḥadīth *text*
   (`nawawi_hadiths`) but no verse↔narration concordance. Itqan / Parallel
   Quran would supply it; until then hand‑curation only.
3. **Per‑diacritic data** (tajwīd colouring at the mark level, fine
   articulation). We *have* the source (MushafDatabase `md-diacritic-*`) but
   the current extraction (`mushaf_layout.json.gz`) dropped sub‑word paths —
   needs a **new extraction pass** (data exists, not yet pulled).
4. **Word‑level recitation timing that we may store.** Timing exists (QF
   `segments`, quran‑align) but every source is either licence‑restricted
   (QF) or bound to Tanzil segmentation needing VT‑3 — no *storable* source
   identified.

## BLOCKED BY LICENSE

> **Under AD‑1 (`QURAN_LIVE_DATA_ARCHITECTURE.md`): "can't bundle" ≠
> "can't use".** The items below cannot be *redistributed inside the APK*
> until a licence clears — but each may still be an **ONLINE** or **HYBRID**
> provider (streamed / fetched‑and‑cached‑per‑terms). "Blocked by licence"
> here means **blocked from bundling**, not blocked from the feature.

Data exists somewhere but we cannot **bundle** it until a licence is settled:

1. **Word / ayah audio + recitation‑follow.** Quran Foundation
   `word.audioUrl` + `segments` exist, but Developer Terms forbid storing QF
   Content > 1 week and forbid redistribution without a commercial licence.
   → **usable online now (stream)**, **not offline**, not bundled.
2. **QUL word‑meaning / mutashābihāt / topics.** QUL is per‑resource
   licensed; none of these verified yet → cannot bundle until each is
   checked (`VT‑5`).
3. **Classical iʿrāb / tajwīd *printed editions*** (الدرويش، الجدول، …) for
   lesson prose. Public‑domain as works, but a given digital typesetting may
   be under publisher rights → author‑with‑citation instead of copying.
4. **Itqan / Parallel Quran** ḥadīth‑link data — licences unverified.

> Explicitly **NOT** blocked by licence (verified 2026‑08‑30): **MASAQ v5**
> (CC BY 4.0), **QAC** (verbatim + attribution + link, no‑modify),
> **cpfair/quran‑tajweed** (CC BY 4.0), **MushafDatabase V1.01 SVG**
> (Sadaqa‑e‑Jaria), our **tafsīr editions** (CC‑BY family), **Tanzil**
> (CC‑BY 3.0), public‑domain matns (تحفة الأطفال، الجزرية).

## BLOCKED BY ENGINEERING

Data present + licence clear — needs new code only:

1. **Word → morphology (ṣarf) card.** MASAQ/QAC ready → build‑time importer →
   `knowledge_facts` + `morph_*` tables → `KnowledgeAnchor` resolution → the
   card UI. Needs **VT‑3** for on‑page rendering (text‑only view works
   without it).
2. **Word → syntax / iʿrāb graph.** MASAQ ready → `syntax_nodes` +
   `syntax_relations` + `syntax_coverage` tables + importer + **72‑role →
   closed‑vocab mapping** + the interactive graph widget + edge→highlight.
3. **Position → tajwīd rule span + on‑page overlay.** cpfair/quran‑tajweed
   ready → importer + **offset remap (VT‑3)** + `tajweed_rules` table +
   overlay driven by `rule_id` (colour = in‑app palette).
4. **VT‑3 alignment tool** — one‑off script → `assets/quran_learning/mapping/
   tanzil_to_mushafdb.json` + `QURAN_WORD_ALIGNMENT_REPORT.md`. Blocks
   *on‑page* rendering of every external‑segmentation fact.
5. **`LearningGateway` + Provider Adapters** (`QURAN_LIVE_DATA_ARCHITECTURE.md`)
   — the one interface the UI talks to; offline adapters read bundled
   tables, `L‑AUDIO` streams.
6. **Real mushaf SVG render** + Mushaf Data Package (also listed in READY
   NOW — the data/licence side is done, only code remains).
7. **`KnowledgeConcept` / `LearningLesson` / `KnowledgeAnchor` /
   `KnowledgeEdge` / `KnowledgeFact` tables** + repositories.
8. **`StudyEvent` emission wiring** from every learning surface.
9. **The maths engine** — after `StudyEvent` exists.

## MINIMUM VIABLE LEARNING DATASET

The smallest **licensed** bundle that makes the full loop
— *tap a word → learn something sourced → add it to the notebook → return to
the word in the mushaf* — actually run:

| piece | content | size | source · licence |
|---|---|---|---|
| Text + identity + geometry | already bundled | 0 new | `quran_ayat` (Tanzil CC‑BY 3.0) + `mushaf_*` (MushafDatabase, Sadaqa‑e‑Jaria) |
| **Knowledge for the slice** | **cpfair/quran‑tajweed** rule spans for **Sūrat al‑Fātiḥa (1) + al‑Ikhlāṣ (112) + an‑Nās (114)** only, remapped via a **mini VT‑3** to `mushafdb‑v1.01` | ~a few dozen `TajweedRule` rows | cpfair/quran‑tajweed · **CC BY 4.0** |
| **Learning content for the slice** | the matching tajwīd **concept lessons** from the **existing** `tajweed_curriculum.dart` (already authored + cited to Tuḥfat al‑Aṭfāl / al‑Jazariyyah) | 0 new | in‑app, citation‑only |
| **Source registry** | 4–5 hand‑written `SourceReference` rows: Tanzil, MushafDatabase, quran‑tajweed, Tuḥfat al‑Aṭfāl, al‑Jazariyyah | ~5 rows | our registry |
| **Notebook link** | `concept_id` column + `concept_note` entry_type on `ayah_study_entries` (mini migration) | schema only | — |

**Why this specific slice:** it is the *only* combination where every layer
of the chain has a **clearly‑licensed, already‑present or tiny** input —
tajwīd is the one domain whose *lesson content already exists in the app*,
and quran‑tajweed is the one external dataset that is CC BY 4.0 **and**
already anchored near word level. Three short surahs keep the VT‑3 remap to
minutes of manual verification.

**Optional add‑on to also prove ṣarf + naḥw in the MVLD** (matches
`QURAN_LEARNING_ROADMAP.md §P` "tap word → ṣarf + naḥw + tajwīd + source"):
add **MASAQ v5 rows for those same 3 surahs only** (CC BY 4.0) — ~20 ayat,
still a "minimum" set, proving the morphology card + the iʿrāb graph on real
data without touching the other 6216 ayat.

Everything beyond the MVLD (full‑Qurʾān morphology/syntax/tajwīd, word
meaning, audio, the maths engine) is added **layer by layer through the same
`LearningGateway` + `KnowledgeAnchor` contracts** — no re‑architecture.
