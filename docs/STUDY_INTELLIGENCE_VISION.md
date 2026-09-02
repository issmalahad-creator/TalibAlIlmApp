# Study Intelligence — vision & architecture direction

**Status: VISION ONLY. No implementation. No code is to be written from this
document.** It records the direction Ismail set on 2026-08-29 so the
architecture built between now and then does not close any of these doors.
After writing this, work returns to `79-sa-D`.

---

## 0. The one principle

طالب العلم's "intelligence" is a **Deterministic Study Intelligence Engine**,
not an LLM. Every result the system produces must be explainable from:

```
precise data  +  stored relations  +  counting  +  weights  +  scores
              +  algorithms  +  explicit rules  +  time & repetition
```

**Never**: LLM output, AI-generated recommendations, AI-generated
"understanding", AI-generated scores. If the app ever shows a number, we
must be able to point at the formula, the data it came from, the time
window, and a plain-language reason. This is the same "no live AI facing
the student" rule already in `CLAUDE.md` / `TODO.md`, extended to the whole
analytics layer.

The goal is not a dashboard full of scores. The goal is **math that makes
real decisions** — e.g. computing what to review next, or surfacing:

> You've read 14 books in العقيدة, but 73% of your time went to 3 of them,
> and 11 books you started and haven't returned to in 45 days.

…and then computing a **review priority** from the student's own rules — not
an AI saying "I recommend…".

---

## 1. The Quran as a measurable entity — "Mushaf Semantic Layout Layer"

The **MushafDatabase Ligature-Based SVG** dataset (folder
`MushafDatabase-Ligature-Based-SVG-main_2`, license: "Sadaqa-e-Jaria",
fully open incl. commercial) is not just display art. Every word group
carries machine-readable data:

```
Page → Line → Word → Ayah → Surah
```

Per `md-word-NNN`: `data-surah` (3-digit), `data-aya` (3-digit),
`data-line-number`, `data-hafs` (Uthmani), `data-imlaey` (simplified),
`data-word-index-in-ayah` (1-based). Plus `md-ligature-*` / `md-diacritic-*`
(25 diacritic types, dots) and `md-aya-mark-*` (verse markers, distinct
from words). 604 files, ~380 MB per version, standardise on **V1.01**.

**Do NOT integrate MushafDatabase now.** First design the right
architecture for it. When we do, it should become a real layout+data layer
enabling:

- tap a word / select a word range / select an ayah on the real Mushaf art
- ayah highlighting, recitation-follow highlighting (word cursor)
- saving the student's study position at word granularity
- measuring hifz progress and ayah review at ayah/word granularity
- anchoring notes to a specific ayah **and word index**, not just a page
- (later) tajweed colouring via the separated diacritic groups

This removes the need for the separate polygon/JSON files (closes the open
item at `TODO.md`, "JSON polygon files no longer needed").

### Mushaf as a stable semantic anchor

A study annotation on the Mushaf must resolve to:

```
سورة البقرة · آية 255 · الكلمات 12–17 · صفحة 42
```

not `page 532`. Surah + ayah + word-index is stable across Mushaf print
editions and page renderers; a raw page offset is not. This is the same
"three layers, semantic reference over coordinates" rule as
`STUDY_ANNOTATIONS_DESIGN.md`, applied to the Quran.

---

## 2. A shared Study Intelligence data model

One model across Quran, books, hadith, lessons — not a separate silo per
content type.

### `StudyItem` — anything studyable

| kind | anchor |
|---|---|
| `quran_ayah` | surah, ayah |
| `quran_word` | surah, ayah, word_index |
| `book_passage` | book_id, page, char range (existing `turath_annotations` anchor) |
| `highlight` | a `turath_annotations` row |
| `note` | a `turath_annotations` row / ayah note |
| `hadith` | collection, number |
| `lesson` | lesson_id |

`StudyItem` is a thin identity + metadata (importance weight, category,
source). It is **not** a copy of content — it points at existing rows
(`quran_ayat`, `turath_annotations`, `turath_catalog_books`, …), exactly
like the unified notebook is a view, not a copy.

### `StudyEvent` — what the student did, with a timestamp

```
opened · read · reread · completed
highlight · note
review · memorize
successful_recall · failed_recall
```

Every event: `(study_item, event_type, timestamp, duration?, payload?)`.
This append-only log is the **only raw material** the mathematical engine
consumes. Existing per-feature tables (`recitation_sessions`,
`memorization_progress`, `turath_last_read`, reading-minutes logs, …) are
either migrated into or projected onto this event stream — decided at
design time, not now.

---

## 3. A real Knowledge Graph — stored & computed, not AI

Relations stored explicitly and traversed with plain queries:

```
Quran ── Ayah ── Surah ── Juz ── Page
              │
              ├── Annotation
              └── Hadith ── Book ── Author ── Category
                                        │
                                        └── Annotation
```

Examples:

```
Annotation → Book: العقيدة الواسطية → Category: العقيدة → Author: ابن تيمية
Ayah 2:255 → Surah البقرة → Juz 3 → Page 42 → Annotation(s)
```

Edges come from data we already have or can derive (catalog `cat_id`,
author, Quran surah/juz/page tables, annotation `book_id`/ayah anchor,
`cross_references` when Phase 5 builds it). No embeddings, no AI graph —
just a `knowledge_edges(from_kind, from_id, rel, to_kind, to_id)` style
table plus derivations. Later this lets the engine answer "how much have I
studied around ayah X" or "which authors dominate my aqeedah notes"
without any model.

---

## 4. The mathematical metrics (design targets, not built)

Each metric, when designed, ships with: **Formula · Data source · Time
window · Explanation**. No metric is allowed without all four.

| metric | intent | inputs (from `StudyEvent` + graph) |
|---|---|---|
| **Study Coverage** | more than `read/total` | pages_read, reading_time, rereads, annotations, reviews, completion |
| **Retention** | how well it's held | review_count, successful/failed reviews, interval, time_since_last_review |
| **Review Priority** | what to review first | failure rate ↑, days since last review ↑, importance ↑, recent reviews ↓ |
| **Knowledge Strength** | depth of study of a topic/book/ayah | weighted sum of real events over time |
| **Neglect Score** | what the student is under-studying vs the rest | distribution of time/events across items in a category |
| **Consistency Score** | regularity across days/weeks | event density per day/week, gaps |
| **Depth Score** | "opened the book" vs "read + highlight + note + review + reread" | event-type mix per item |

### No fake dashboard

Never `"You're 87% ahead"` with no basis. Every displayed number expands
to its reasoning, e.g.:

```
Review Priority = 82
  + high failure count
  + 9 days since last review
  + high importance
  − reviewed twice this week
```

---

## 5. Study Annotation → this engine (hooks only, not now)

The Study Annotation system already built is more than a highlight. Its
future path:

```
Highlight → StudyItem → StudyEvent(highlight) → Review History → Mathematical Score
```

**Do not add any of this to `79-sa-D`.** Only make sure the current schema
doesn't block it: `turath_annotations` already has stable ids, timestamps
(`created_at`/`updated_at`), a colour/type, and a semantic anchor — enough
to become a `StudyItem` and emit `StudyEvent`s later. The unified notebook
(`79-sa-D`) is already the right shape (a view over annotations). Nothing
new is needed now beyond keeping that decoupling.

---

## 6. Independent ayah notebook — "دفتر ملاحظات الآيات"

Parallel to the Turath study notebook (`79-sa-D`), a **separate** notebook
over ayah-anchored notes/highlights: filter by surah / juz / theme, search
note text, tap → open the ayah in the reader at the exact spot. Same "view
over an annotations table, not a copy" rule. Its annotation rows are
anchored by `(surah, ayah, word_index range)` — the Mushaf semantic anchor
from §1 — rather than `(book_id, page, char range)`.

Whether Quran notes and Turath notes share one `turath_annotations`-style
table (with a nullable ayah anchor) or use a sibling table is a design
decision for the Unified Data Model phase (§2), not now. Keeping them
separate-but-symmetrical is the safe default until then.

---

## 7. PDF download

Stays an independent project. **No work** until a per-source rights review
is done (see `PDF_DOWNLOAD_DESIGN.md`, `has_pdf` is a hint, `pdf_links` is
the truth, downloads are user-opt-in per book).

---

## 8. Priority order (after the current stage)

```
1. Study Annotation / Notebook          (79-sa-D — current, nearly done)
2. Mushaf Architecture                   (design; MushafDatabase layout+data layer)
3. Unified Study Intelligence Data Model (StudyItem + StudyEvent)
4. Mathematical Study Engine             (metrics, formulas, algorithms)
5. Quran integration                     (Mushaf layer wired to items/events)
6. Review / Spaced Repetition            (unify recitation + memorization + notes)
7. Knowledge Map                         (graph + queries + views)
8. Dashboard                             (every number explainable)
9. PDF Download                          (after rights review)
```

Not the reverse.

---

## 9. Deliverables required when the Mathematical Study Engine is designed

> **Done (spec only, 2026-08-29): `docs/STUDY_INTELLIGENCE_ENGINE_SPEC.md`**
> — the full mathematical specification (causal DAG, all variables/formulas,
> normalization/weighting/decay/confidence, review & recommendation
> algorithms, 13 mathematical-weakness analyses + mitigations,
> anti-fake-number rules, 3 hand-worked numeric examples, 13 golden test
> vectors). To be approved before any implementation.

When (and only when) we reach step 4, the design must include, with **real
numeric worked examples that can be checked by hand**:

- Data Model
- Variables
- Metrics
- Formulas
- Normalization
- Weighting
- Time decay
- Confidence
- Review algorithm
- Coverage algorithm
- Consistency algorithm
- Knowledge-strength algorithm

**No AI. No LLM. No guessing. Only interpretable algorithms, mathematics,
and data.**
