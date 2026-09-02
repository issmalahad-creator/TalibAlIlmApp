# Quran Learning Layer — architectural design

**Status: DESIGN ONLY. No code. No change to the mushaf or any existing
data.** This is the single canonical design for turning the mushaf into an
entry point for organised study inside the Student Notebook.

It builds on the engineering knowledge base in `docs/quran/` (load the
`quran-engineering` skill first). **Readiness audit (what actually runs
today vs. what's blocked): [`QURAN_LEARNING_READINESS.md`](QURAN_LEARNING_READINESS.md).**
Deeper annexes written earlier — keep for detail, this doc is the top-level
authority:
`docs/QURAN_DATA_CONTRACTS.md` (exact field shapes),
`docs/QURAN_SOURCES_AND_LICENSES.md` (per-source provenance + `CLAIM→APPROVED`
pipeline + `CONFLICT` register), `docs/QURAN_DATA_VALIDATION.md` (ingest /
display gates), `docs/QURAN_LEARNING_ROADMAP.md` (build order + Prototype).

---

## P0 — the priority (Ismail 2026-08-30)

The **first and most important** function of this layer is **teaching the
Qurʾān's iʿrāb from inside the muṣḥaf itself** — not a data readout beside
the page, but: tap a word → its real iʿrāb → its relation to what's before
and after → *why* it's parsed that way → *how the case-sign changed the
pronunciation* → listen → the relations light up in the ayah → «تعلّم هذا»
→ a lesson in the notebook → back to the same word to apply it.

Priority: **P0 naḥw/iʿrāb + pronunciation + mushaf link · P1 ṣarf · P2
tajwīd · P3 tafsīr / word-meaning · then the rest.** The iʿrāb loop is the
pattern every other science reuses — build it first, prove it, then widen.
QAC is the first grammar provider (`QURAN_LIVE_DATA_ARCHITECTURE.md`
L-SYNTAX / L-MORPH).

**Status:** Prototype built for al-Fātiḥa + al-Ikhlāṣ — phase `79-ql`,
`docs/QURAN_LEARNING_ROADMAP.md §P`.

## 0. The primary path

```
        المصحف (Mushaf Semantic Layer — real, verified)
           │  اضغط كلمة / آية
           ▼
        ماذا أريد أن أتعلّم؟   ← launcher, not a lesson, not a popup of facts
           ├── الإعراب        ┐
           ├── النحو          │
           ├── الصرف          │  each row = "is there verified data here?"
           ├── التجويد        │  → open the sourced fact + «تعلّم هذا»
           ├── معاني الكلمات   │
           ├── التفسير        │
           └── فائدة شخصية    ┘  → دفتر الآية (AyahStudyNotebook)
                   │
                   ▼  «تعلّم هذا»
        دفتر الطالب — درس علمي منظّم
           المفهوم → القاعدة → الشرح → أمثلة → أمثلة قرآنية → تطبيق
           (كل جزء له مصدر)
                   │
                   ▼  «افتح المثال في المصحف» / «طبّق ما تعلمت»
        العودة إلى نفس الآية ونفس الكلمة  (+ إبراز المواضع الأخرى للمفهوم)
                   │
                   ▼  لاحقًا
        مراجعة  — يُعاد المفهوم للطالب عند موضعه في المصحف
```

Two directions always: **القرآن → العلم** و **العلم → القرآن**.
No AI. No quizzes. No fact-dump popup.

---

## 1. What the Quran Learning Layer is

A **bridge layer** between three things that already exist or are designed,
plus one new content layer:

| # | level | what it holds | project home |
|---|---|---|---|
| 1 | **Quran** | Surah → Ayah → Word, the real mushaf | `quran_ayat`, `mushaf_*`, `MushafLayoutRepository` (exists) |
| 2 | **Knowledge** | one verified scholarly fact: this word's iʿrāb / ṣarf / tajwīd rule / meaning / a tafsīr passage — **with its source** | new: `knowledge_facts` (+ `source_references`) |
| 3 | **Learning** | organised teaching material: a Concept → its Lesson → Examples → Quran References | new: `knowledge_concepts`, `learning_lessons` |
| 4 | **Student Notebook** | what the *student* wrote / understood / heard / benefited from / wants to revisit | `ayah_study_entries` (exists) + new `student_learning_state` |

The layer's job is only: **look up, relate, present, record**. It never
generates knowledge.

Generic naming (not naḥw-specific):

```
QuranReference  ──▶  KnowledgeConcept  ──▶  LearningLesson  ──▶  StudentStudyEntry
   (surah,ayah         (المفعول به,          (تعريف + شرح       (ملاحظة الطالب /
    [,word_index])      إن وأخواتها,           + أمثلة قرآنية)     حالة تعلّمه)
                        حكم الإخفاء, …)
```

Every arrow is a **stored, typed link**, resolvable both ways.

---

## 2. AyahStudyNotebook vs Learning Lesson — different, linked

They are **not** the same thing and must not be merged.

| | **دفتر الآية** (AyahStudyNotebook) | **درس علمي** (LearningLesson) |
|---|---|---|
| owner | the student | the app's curated content |
| content | free writing: "استمعت إلى شرح الشيخ فلان وذكر…", فائدة، فهمي، سؤال | fixed structure: تعريف → قاعدة → شرح → أمثلة → أمثلة قرآنية → تطبيق |
| source | optional (the student may cite a shaykh/lesson) | **mandatory** — every block cites a book / edition / matn |
| anchored to | `(surah, ayah[, word range])` | a `KnowledgeConcept` (not an ayah) |
| table | `ayah_study_entries` (shipped) | `learning_lessons` (new) |
| changes over years | yes — a personal study history per ayah | no — stable teaching material, versioned by source edition |

**The link:** a student, reading الدرس on "إنّ وأخواتها", can attach a
personal note to it *and* to البقرة 255 *and* see both from either side:

```
LearningLesson "إنّ وأخواتها"
        ↕  (illustrated_by)      →  QuranReference 2:255 (word "إِنَّ")
        ↕  (has_student_note)    →  StudentStudyEntry (ayah_study_entries row,
                                     entry_type = concept_note, concept_id set)
QuranReference 2:255
        ↕  (has_student_note)    →  the student's own "دفتر الآية" entries
```

---

## 3. How the Quran links to knowledge

A `KnowledgeFact` (level 2) carries a **`KnowledgeAnchor`** — the semantic
address, never a pixel:

```
KnowledgeAnchor { surah, ayah, word_start?, word_end?, char_start?, char_end?,
                  scope ∈ {ayah, word, word_range, char_range},
                  segmentation ∈ {mushafdb-v1.01, tanzil-space, qac, masaq, …} }
```

- `2:255` (scope=ayah) → a tafsīr passage, a benefit, a linked ḥadīth.
- `2:255` word 1 (scope=word) → the iʿrāb of "إِنَّ", its ṣarf, its meaning.
- `2:255` words 3–4 (scope=word_range) → a tajwīd rule spanning two words,
  or the مضاف/مضاف إليه pair.

So the same ayah fans out to many kinds of knowledge:

```
2:255 ──▶ الإعراب        (word-level facts)
      ──▶ التوحيد/العقيدة (ayah-level concept link)
      ──▶ التفسير         (ayah-range tafsīr entries, multi-edition)
      ──▶ التجويد         (char/word-range rule spans)
      ──▶ فائدة الطالب    (ayah_study_entries)
```

The system is **not** naḥw-only. `KnowledgeFact.domain ∈ {nahw, irab, sarf,
tajweed, tafsir, meaning, hadith, aqeedah, fiqh, balagha, …}` — new domains
add a value, not a schema change.

---

## 4. How a word links to knowledge

The word is the spine. From `mushaf_words` we already have the identity
`(surah, ayah, word_index)` and the geometry `(page, line, bbox)`.

```
QuranWord (2:255:1  "إِنَّ")
  ├── KnowledgeFact  domain=irab     → "حرف توكيد ونصب"        + source
  ├── KnowledgeFact  domain=sarf     → (حرف — لا تحليل صرفي)    + source
  ├── KnowledgeFact  domain=meaning  → "for emphasis: indeed"   + source
  ├── KnowledgeFact  domain=tajweed  → (span may start here)    + source
  └── KnowledgeEdge  concept_link    → KnowledgeConcept "إنّ وأخواتها"
```

- The word-tap panel shows one row per domain, **enabled only where a
  verified fact exists**; empty → *"لا توجد بيانات موثقة لهذا العنصر
  حاليًا."*
- Choosing a domain shows the fact + its source, then offers **«تعلّم هذا»**
  → opens the linked `KnowledgeConcept`'s `LearningLesson`.
- The iʿrāb view is a small **graph** (nodes = words with their role, edges =
  typed relations فاعل/خبر إنّ/مضاف إليه…). Tapping an **edge** highlights
  both endpoint words on the mushaf. (Detail: `QURAN_DATA_CONTRACTS.md §4–6`.)

---

## 5. How a lesson links to multiple ayat

A `LearningLesson` belongs to a `KnowledgeConcept`, and a concept is
illustrated by **many** Quran references:

```
KnowledgeConcept "المبتدأ والخبر"
        │
        ├── illustrated_by → 2:255  word "اللَّهُ"      (مبتدأ)
        ├── illustrated_by → 112:1  word "اللَّهُ"      (…)
        ├── illustrated_by → 2:2    word "ذَٰلِكَ"       (…)
        └── illustrated_by → …
```

- Each `illustrated_by` edge is stored, typed, and carries a
  `KnowledgeAnchor` + a `source_ref_id` (which grammar reference cites this
  ayah for this concept).
- In the lesson's "أمثلة قرآنية" block, each example is one such edge; the
  student taps it to jump to that ayah/word.
- Conversely, from a word: "دروس مرتبطة بها" = query `illustrated_by` edges
  pointing at this `(surah, ayah, word_index)`.

A lesson never contains ayah *text* by value — it holds `KnowledgeAnchor`s,
and the text is rendered from `quran_ayat` / the mushaf at display time
(Quran Layer stays the single source of the text).

---

## 6. How a lesson returns to the mushaf

Every lesson block of kind `quranic_example` or `application` has a
resolvable `KnowledgeAnchor`. The UI action **«افتح المثال في المصحف»**:

```
lesson block.anchor (surah, ayah, word_start..word_end, segmentation)
   │  (if segmentation ≠ mushafdb-v1.01 → map to it, §11 / §M)
   ▼
MushafLayoutRepository.pageForAyah(surah, ayah)  → page
MushafLayoutRepository.ayahBoxesOnPage(page, …)  → highlight geometry
   ▼
open MushafSemanticReaderScreen(initialPage: page)
   with the example word(s) highlighted, and — from KnowledgeEdge
   illustrated_by — the *other* occurrences of the same concept on that
   page/surah also marked, so the rule is seen live in the text.
```

Then the student is back exactly where they started (the origin
`KnowledgeAnchor` is remembered on the `StudentLearningState`), and a
`returned_to_ayah` event is recorded (§9).

---

## 7. How sources link to knowledge — knowledge ≠ source

A `KnowledgeConcept` / `KnowledgeFact` / `LearningBlock` **is not** its
source. Each points to one or more `SourceReference`s:

```
KnowledgeConcept "المفعول به"
   ├── source_ref → كتاب نحوي (edition, vol, page)
   ├── source_ref → شرح شيخ (audio/text, attribution)
   ├── source_ref → matn public-domain (تحفة الأطفال … for tajwīd concepts)
   └── source_ref → تفسير (edition) — where it discusses the iʿrāb

KnowledgeFact  2:255:2  domain=irab  "اسم إنّ منصوب"
   └── source_ref → MASAQ v2  (dataset, license, confidence, classification)
       cross_refs → [ QAC treebank: agrees ; إعراب الدرويش vol/page: agrees ]
```

`SourceReference` fields (full list in `QURAN_DATA_CONTRACTS.md §1`):
`source_type, name, author, book, edition, volume, page, reference, url,
license, license_use, authority, retrieved_at, confidence, classification`.

Rules:
- **No scholarly fact without a `source_ref_id`.**
- One concept, many sources — the student can ask "من أين جاء هذا؟" and see
  all of them.
- Two sources disagree → a `CONFLICT` entry; the UI shows both, attributed,
  labelled "اختلفت المصادر"; **I never pick one silently**
  (`QURAN_DATA_VALIDATION.md §K`).
- `license_use ∈ {study_only, unknown}` → informs design, **not shipped**.

---

## 8. Integration with the Mushaf Semantic Layer

The Mushaf Semantic Layer (`mushaf_*`, `MushafLayoutRepository`,
`MushafPageView`) is the **spatial index** and the **tap source**. This
layer is a **read-only consumer** of it. Nothing in `mushaf_*` changes.

| this layer needs | it calls |
|---|---|
| "which word did the user tap?" | `MushafPageView` callback → `(surah, ayah, word_index)` |
| "where is `(surah, ayah, word_index)` on the page?" | `MushafLayoutRepository` → `(page, line, bbox)` |
| "which page opens `(surah, ayah)`?" | `pageForAyah` / `pageForReference` |
| "highlight this ayah / word range" | `ayahBoxesOnPage` → per-line union boxes |

`KnowledgeAnchor.word_*` are in a named `segmentation`. Only
`mushafdb-v1.01` renders directly; other segmentations must be mapped first
(§11). Geometry is **always** resolved from the anchor via this repository —
never stored in a knowledge/lesson row, never inferred from a screen tap
(`docs/quran/ERRATA.md` E‑2).

---

## 9. Integration with StudyItem and StudyEvent

Every meaningful interaction becomes an **append-only `StudyEvent`**; every
learnable thing projects to a **`StudyItem`**. (Shapes:
`QURAN_DATA_CONTRACTS.md §12–13`.)

**Event verbs for this layer** (deterministic, no grading):

```
opened_lesson         opened the LearningLesson for a concept
opened_quran_example  tapped a "أمثلة قرآنية" reference
opened_source         viewed a SourceReference ("من أين جاء هذا؟")
created_note          wrote a StudentStudyEntry (daftar / concept note)
linked_ayah           attached a concept/lesson to a (surah, ayah[, word])
returned_to_ayah      used "افتح المثال في المصحف" / "طبّق ما تعلمت"
reviewed_note         re-opened a note/lesson in a review pass
```

(Also `opened` for the launcher panel, `studied` for dwell on a lesson.)
Explicitly **not** present: `answered / correct / incorrect` — no quiz.

**StudyItem kinds** from this layer: `concept` (a `KnowledgeConcept`),
`quran_word`, `quran_ayah`, plus roll-up items `surah / juz / page`.
Each `StudentLearningState` row (a concept the student is learning, with its
origin anchor and state `learning | applied | reviewing`) is a `StudyItem`
of kind `concept`.

The events carry `anchor` (the mushaf spot), `layer` (which domain),
`target_kind` + `target_id`, `ts` (UTC). Append-only — never updated.

---

## 10. Future integration with the Mathematical Intelligence engine

**Not built now.** The engine (`docs/STUDY_INTELLIGENCE_ENGINE_SPEC.md`) is
a **pure consumer** of the `StudyEvent` log. This layer's only obligation:
emit faithful, well-typed events with distinct verbs so the engine can tell
apart:

```
فتح معلومة        (opened_lesson / opened_source)      ← low weight
دراسة             (studied — dwell + scrolled to end)  ← higher
تطبيق             (returned_to_ayah after a lesson)     ← higher
مراجعة            (reviewed_note)                       ← retention signal
كتابة ملاحظة      (created_note)                        ← depth signal
```

From those the engine derives, per `surah / juz / page / concept`:
**Coverage, Retention, Consistency, Depth, Neglect, ReviewPriority** — every
number explainable (Formula + Data source + Time window + reason), **no
cosmetic dashboard**, no AI. The review scheduler re-surfaces a concept at
its **origin mushaf spot**.

Design obligation now: keep `StudyEvent` shape stable and the verb set
closed; keep `StudentLearningState` id stable per `(concept_id, origin
anchor)`.

---

## 11. Preventing the mix of rasm / data / source

Three things that are constantly confused elsewhere — kept strictly apart:

| kept apart | which is which | rule |
|---|---|---|
| **Quran Layer** (rasm/ḍabṭ/text/ayah/word/page/line) | immutable; from Tanzil + MushafDatabase, validated against canonical counts | **never modified** to attach teaching info |
| **Knowledge data** (the fact: "اسم إنّ منصوب", "حكم إخفاء") | a `KnowledgeFact` row with a `domain`, anchored, typed | stored **on top**, joined by `KnowledgeAnchor`; carries no text of the Quran by value |
| **Source** (where the fact came from) | a `SourceReference` row | **separate** from the fact; a fact points to ≥1 source; a source is reusable across facts and concepts |

Plus the three text forms already governed by `docs/quran/QURAN_DATA_MODEL.md`
(§5): **Uthmani ≠ Imlaei ≠ normalized ≠ visual glyph** — a lesson quotes the
Quran only by `KnowledgeAnchor`, and the text is rendered from
`text_uthmani` at display time.

And the segmentation guard: a `KnowledgeAnchor` from an external dataset
records its `segmentation`; if it is not `mushafdb-v1.01`, a validated
mapping to our word indices must exist before the fact can render on the
page (`QURAN_DATA_VALIDATION.md §M`). Until then the fact is stored with
`mapping_status = unmapped` and shows in a text view only.

---

## 12. Extending to naḥw / ṣarf / tajwīd / tafsīr / ḥadīth / ʿaqīdah / fiqh …

The layer is generic from day one. To add a domain:

1. add a value to `KnowledgeFact.domain` (and, if needed, a `KnowledgeConcept`
   `domain`);
2. register the source(s) in `docs/QURAN_SOURCES_AND_LICENSES.md` and pass
   the `CLAIM → APPROVED` pipeline;
3. ingest `KnowledgeFact` rows with `KnowledgeAnchor`s (word / range / ayah)
   + `source_ref_id`; build a segmentation mapping if the source isn't
   `mushafdb-v1.01`;
4. author `KnowledgeConcept` + `LearningLesson` for the concepts, each block
   cited;
5. add `KnowledgeEdge` links (`illustrated_by`, `explained_by`,
   `same_root_as`, `related_concept`, …);
6. add a launcher row + a card renderer in the UI.

**No schema migration** for a new domain — only data + a UI card. Examples
of what each domain anchors:

```
naḥw / iʿrāb   → word / word_range   (roles + typed relations, the graph) — P0.
                 Built on named classical iʿrāb works (التبيان، الجدول، …) +
                 MASAQ's 72-role tagset. NOT "derived from morphology".
ṣarf           → word                (root, lemma, pattern, features)
tajwīd         → char_range / word_range  (rule_id + cause + articulation)
معاني الكلمات  → word                (a gloss, sourced)
تفسير          → ayah / ayah_range   (verbatim, multi-edition)
حديث           → ayah / ayah_range   (KnowledgeEdge to a hadith + its grading)
عقيدة / توحيد  → ayah / concept      (concept link + tafsīr/ʿaqīdah citation)
فقه            → ayah / ayah_range   (aḥkām, cited to a fiqh reference)
بيان / إعجاز   → word_range / ayah   a PARALLEL track (not P0): sub-kinds
                 ijaz_bayani · nazm · balagha · taqdim_takhir · hadhf_dhikr ·
                 tarif_tankir · ikhtiyar_alfaz · tanasub. **The app never
                 infers iʿjāz** — every aspect cites a named work
                 (دلائل الإعجاز، الكشاف، البرهان، …) by book/edition/page.
                 See QURAN_SOURCES_AND_LICENSES.md §H.
```

The Student Notebook view "ما تعلمته من القرآن" then groups the student's
`StudentLearningState` + notes **by domain**: النحو، الصرف، التجويد،
التفسير، … — same structure regardless of which domains have data.

---

## 13. Full worked examples

### Example A — a word → iʿrāb → lesson → notebook → back to the Quran

```
1. المصحف: صفحة 42، يضغط الطالب على «غَفُورٌ» في «إِنَّ ٱللَّهَ غَفُورٌ رَّحِيمٌ» (2:173 مثلًا)
   → MushafPageView → (surah=2, ayah=173, word_index=k)

2. لوحة «ماذا أريد أن أتعلّم؟» — الصفوف المفعّلة: الإعراب، الصرف، المعنى، التفسير، فائدة
   (التجويد: لا بيانات موثقة لهذا الموضع بعد → الصف مطفأ برسالة)

3. يختار «الإعراب»:
   بطاقة:  «غفورٌ: خبر إنّ مرفوع وعلامة رفعه الضمة»
   المصدر: MASAQ v2  ·  متوافق مع: إعراب الدرويش (مج/ص)  ·  التصنيف: موثّق
   رسم صغير:  إنَّ ──(اسم إنّ)── ٱللَّهَ      إنَّ ──(خبر إنّ)── غفورٌ ──(خبر ثانٍ)── رحيمٌ
   زر:  «📚 تعلّم الإعراب المتعلق بهذه الكلمة»

4. «تعلّم هذا» → KnowledgeConcept «إنّ وأخواتها» → LearningLesson:
      المفهوم:   حروف تنصب الاسم وترفع الخبر …            [مصدر: matn/كتاب نحوي، ص]
      القاعدة:   إنَّ، أنَّ، كأنَّ، لكنَّ، ليت، لعلَّ …     [مصدر …]
      الشرح:     …                                        [مصدر …]
      أمثلة:     أمثلة نحوية عامة                          [مصدر …]
      أمثلة قرآنية:  • 2:173 «إنَّ اللهَ غفورٌ رحيمٌ»  ← الموضع الحالي
                     • 112:1 …    • 2:255 «إنَّ …» (إن وُجد)   [كل مثال: edge + مصدر]
      تطبيق:     «طبّق ما تعلمت في القرآن»

5. الطالب يكتب في «دفتر الآية»:
   entry_type = concept_note، concept_id = concept:nahw:inna_wa_akhawatuha
   body = «فهمت أن (غفور) خبر إنّ مرفوع، وأن (الله) اسمها منصوب …»
   → StudyEvent: created_note  +  linked_ayah  (2:173 ↔ الدرس)

6. «افتح المثال في المصحف» على مثال 2:173 →
   MushafLayoutRepository.pageForAyah(2,173) → صفحة 42
   → يفتح القارئ الدلالي، يُبرز «إنَّ … غفورٌ رحيمٌ»، ويُبرز مواضع أخرى لـ«إنّ»
     على الصفحة/السورة (من edges illustrated_by)
   → StudyEvent: returned_to_ayah

7. بعد أيام: محرك المراجعة (لاحقًا) يعيد المفهوم عند 2:173 →
   الطالب يفتحه ويراجع  → StudyEvent: reviewed_note
```

### Example B — an ayah → tafsīr + benefit + linked lesson

```
يضغط الطالب على رقم آية / وسط الآية 2:255 (scope = ayah)
لوحة «الآية»:  دفتري لهذه الآية · ماذا تعلمت منها؟ · دروس مرتبطة بها ·
              تفاسير · فوائد · تطبيقات علمية

«تفاسير» → قائمة نُسخ (ابن كثير، السعدي، الميسّر، المختصر، ابن عاشور) —
           كل نص حرفيًّا مع عزوه للنسخة. لا تلخيص، لا دمج.
«دروس مرتبطة بها» → KnowledgeEdge illustrated_by المشيرة إلى 2:255:
           • «إنّ وأخواتها» (على «إنّ» إن وُجدت)  • «المبتدأ والخبر» (على «الله»)
           • «صفات الله: الحيّ القيّوم» (concept عقيدة، إن أُضيف لاحقًا)
«ماذا تعلمت منها؟» → يعرض StudentLearningState + notes المرتبطة بهذه الآية،
           مجمّعة حسب الـdomain.
```

### Example C — the Student Notebook view

```
دفتر الطالب ▸ «ما تعلمته من القرآن»
  النحو (7 مفاهيم · 5 قيد التعلم · 2 مطبَّقة)
     - إنّ وأخواتها      ← من 2:173      [تعلّمته] [راجعه]
     - المبتدأ والخبر    ← من 2:255      [قيد التعلم]
  الصرف (3)
     - وزن «يَفْعُلُونَ»  ← من 2:26        [قيد التعلم]
  التجويد (0)  — لا دروس بعد
  التفسير (12 آية قرأت تفسيرها)
  …
كل عنصر → يفتح الدرس أو يعود لموضعه في المصحف.
```

---

## 14. Boundaries the system must not cross

1. **No AI/LLM** generates iʿrāb, ṣarf, tajwīd, meaning, a tafsīr summary, or
   a scholarly attribution. Engine = Lookup + Relations + Rules + Validation
   + Scoring + Visualization.
2. **No fact without a source.** If a source is missing, the fact does not
   exist for the app.
3. **No guess on missing data.** Empty → *"لا توجد بيانات موثقة لهذا العنصر
   حاليًا."*
4. **No modification of the Quran** (text / rasm / ḍabṭ / ayah / word / page)
   to attach teaching content.
5. **No merging or paraphrasing of tafsīr/translation.** Verbatim, per
   edition, attributed. A translation is never presented as the Quran.
6. **No silent conflict resolution.** Disagreeing sources → `CONFLICT`, both
   shown, decided only by higher authority or Ismail (logged).
7. **No quizzes / grading / "try then reveal".** The loop is learn → apply →
   review, not test.
8. **No cross-edition coordinate reuse.** A `word_index` / bbox is valid only
   in its declared `segmentation` / viewBox.
9. **No shipping `study_only` / `unknown`-licence data.**
10. **No scope creep of the riwāya.** Hafs / Kufi / 6236 / 604 Madani pages.
    Another riwāya is a separate dataset.
11. **The mathematical engine is not built here** — this layer only produces
    its input events.

---

## 15. Offline vs Live — what ships in the app, what is fetched

Full detail: **`QURAN_LIVE_DATA_ARCHITECTURE.md`** (per-layer Source /
Licence / Online-or-Offline / Cache Policy / Identity / Failure Behavior /
Attribution) + the licence findings in **`QURAN_DATA_VERIFICATION_TASKS.md`**
(2026‑08‑30). Principle: **bundle what has a clear redistribution licence
and isn't huge; fetch live what doesn't or is heavy; internet never blocks
reading the muṣḥaf.**

### OFFLINE — bundled, work with no internet

| layer | source | licence (verified) |
|---|---|---|
| Word identity + geometry, ayah text, juz/hizb/page/sajda | `mushaf_*`, `quran_ayat`, `quran_surahs`, Tanzil metadata (shipped) | Tanzil CC‑BY 3.0 · MushafDatabase Sadaqa‑e‑Jaria |
| **Morphology (ṣarf)** | **MASAQ v5** (primary) + **QAC v0.4** (cross‑check) | MASAQ **CC BY 4.0** · QAC **verbatim + attribution + link, no‑modify** |
| **Syntax / iʿrāb (naḥw)** — full coverage, 72‑role tagset | **MASAQ v5** (+ QAC treebank ~11k words as cross‑check) | **CC BY 4.0** |
| **Tajwīd rule spans** | cpfair/quran-tajweed (+ offset remap, VT‑3) | **CC BY 4.0** |
| Tafsīr, verbatim, multi‑edition | `tafsir_entries` (~45 editions, shipped) | CC‑BY family |
| `KnowledgeConcept` / `LearningLesson` prose | authored from public‑domain matns (تحفة الأطفال، الجزرية) + cited grammar refs | public domain / cite |
| Student Notebook, learn→apply→review flow, event log, whole layer schema/UI | `ayah_study_entries` (shipped) + new small tables | n/a |

### HYBRID — bundled if a resource's licence clears, else live‑via‑gateway + cache

| capability | source | why hybrid |
|---|---|---|
| Word‑by‑word meaning | QUL word translations | **per‑resource licence** (VT‑5) — verify each; live+cache until then |
| Mutashābihāt, topics/themes | QUL | per‑resource licence |
| Ḥadīth ↔ ayah links | Itqan / Parallel Quran | licences unverified (VT); live until cleared; always show the ḥadīth's own grading |

### LIVE ONLY — never bundled, ephemeral cache

| capability | source | constraint |
|---|---|---|
| Word / ayah **audio + timing** ("🔊 استماع", recitation‑follow) | Quran Foundation `word.audioUrl` + `segments` (public CDN) | **Developer Terms**: no storing QF Content > 1 week, no redistribution without a commercial licence → **stream only**, session buffer, disabled offline with a clear message |

### Engineering choice (not a licence issue)

- **Mushaf SVG page art** (Sadaqa‑e‑Jaria, redistribution OK): a separate
  **"Mushaf Data Package"** — download‑all (xz ≈46 MB) **or** lazy per‑page,
  then fully offline + integrity‑checked. Base APK stays light. Ismail's
  call; no design rework either way.

### Remaining verification tasks (bounded, not blockers) — `QURAN_DATA_VERIFICATION_TASKS.md`

- **VT‑3** run the Tanzil ↔ MushafDatabase word‑alignment tool once →
  `QURAN_WORD_ALIGNMENT_REPORT.md` + `assets/quran_learning/mapping/*.json`;
  never fudge the text to match. Until run, external‑segmentation facts
  render text‑only.
- **VT‑5** verify each QUL resource before bundling.
- Find a bundle‑able word‑segmented audio source (would let audio go
  offline), or decide on QF Content Sync (≤7‑day re‑sync).
- Verify Itqan / Parallel Quran licences for the ḥadīth layer.

---

## Next step (not now)

On approval, the first code is the **Prototype** in
`docs/QURAN_LEARNING_ROADMAP.md §P`: the full chain (tap word → sourced ṣarf
+ naḥw + tajwīd + source → «أضف إلى دفتر الآية» → «افتح في المصحف») on ~5
curated ayat using only openly-licensed data. If it holds, widen layer by
layer. Nothing existing is changed.
