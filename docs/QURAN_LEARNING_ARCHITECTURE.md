# Quran Learning Architecture — the mushaf as a teaching engine

> **Canonical top-level design: [`docs/quran/QURAN_LEARNING_LAYER.md`](quran/QURAN_LEARNING_LAYER.md)**
> (single consolidated doc, in the `quran-engineering` knowledge base).
> This file + `QURAN_DATA_CONTRACTS.md` / `QURAN_SOURCES_AND_LICENSES.md` /
> `QURAN_DATA_VALIDATION.md` / `QURAN_LEARNING_ROADMAP.md` remain as detail
> annexes it references; read `QURAN_LEARNING_LAYER.md` first.

**Status: DESIGN ONLY. No code.** Approved-design gate: this document +
`QURAN_SOURCES_AND_LICENSES.md` + `QURAN_DATA_VALIDATION.md` +
`QURAN_LEARNING_ROADMAP.md` + `QURAN_DATA_CONTRACTS.md` must be reviewed by
Ismail before any implementation. First implementation = the **Prototype**
(`QURAN_LEARNING_ROADMAP.md` §P), a proof-of-chain on a handful of ayat, not
a full layer.

Load the `quran-engineering` skill and read `docs/quran/` before touching any
of this. Everything here obeys those rules — especially: **the Quran text is
never modified; identity is data, never geometry; no AI/LLM is the brain.**

---

## 0. The one-sentence goal

A student reads the mushaf; when an ayah or word makes them want to
understand something, they move **from that exact spot** into the knowledge
they need (grammar / iʿrāb / ṣarf / tajwīd / tafsīr / word-meaning /
benefits), learn it in the **Student Notebook / learning path**, and come
**back to the same spot** in the mushaf to see it applied.

```
        Quran  ──(tap word/ayah)──▶  "what is here"  ──("learn this")──▶  Student Notebook
          ▲                                                                     │
          └──────────────────  ("apply in the Quran")  ◀───────────────────────┘
```

Two directions, always: **Quran → learning** and **learning → Quran**.

**Not** a quiz system. **Not** a dictionary. **Not** an info popup. It is a
*bridge* between the mushaf and the student's own study, built on verified
scholarly data placed at `(surah, ayah, word_index)`.

---

## 1. Hard architectural rules (non-negotiable)

| # | rule | why |
|---|---|---|
| A1 | **No AI/LLM as a source or reasoner.** The engine does: Lookup + Relations + Rules + Validation + Scoring + Visualization. Never Prompt→AI→Answer. | trust; the whole app's principle |
| A2 | **Quran Layer ≠ Study Layer.** Text/rasm/ḍabṭ/ayah/word/page/line are immutable Quran data. Iʿrāb/naḥw/ṣarf/tajwīd/tafsīr/benefits/notes are *layers on top*, joined by anchors. | never corrupt the mushaf |
| A3 | **Every scholarly fact carries a `SourceReference`** (source, author, book, edition, volume, page, url, license, confidence). No sourced-fact without provenance. | "من أين جاءت هذه المعلومة؟" |
| A4 | **Anchors are semantic, never pixel.** A fact anchors to `(surah, ayah[, word_start, word_end][, char_start, char_end])`. Geometry (`bbox`) is looked up *from* the anchor via the Mushaf Semantic Layer, never the reverse. | `ERRATA` E‑2 |
| A5 | **Coverage is partial and honest.** If no verified data exists for an element, the UI says *"لا توجد بيانات موثقة لهذا العنصر حاليًا"* — it never fabricates or degrades to a guess. | A1 |
| A6 | **The 100 research points are hypotheses, not facts.** Nothing enters the app's data without passing the `CLAIM → verify → authority → version → license → cross‑check → APPROVED` pipeline (`QURAN_DATA_VALIDATION.md`). Source conflicts are logged as `CONFLICT`, never silently resolved by me. | A1, A3 |
| A7 | **Ṣarf (morphology) and naḥw (syntax) are separate sub‑layers** with separate models. A word *has* a morphological analysis *and* a syntactic function; they are not one blob. | future extensibility |
| A8 | **Ranges, not just words.** A rule/fact may span a character, a sub‑word, a word, two words, a phrase, or a whole ayah — the anchor model supports all; a source that only gives word‑level is stored at word‑level, not faked finer. | tajwīd spans, iḍāfa pairs, etc. |
| A9 | **Nothing existing is changed or removed.** The Mushaf Semantic Layer (`mushaf_*`), the old readers, `ayah_study_entries`, the tafsir tables — all untouched. This is additive. | continuity |
| A10 | **Deep-linkable both ways.** Every concept, lesson, example, and fact has a stable id and resolvable links to `(surah, ayah, word_index)` when applicable, and back. | the bridge |

---

## 2. The twelve layers

Each layer's full spec (Data Model / Source / License / Validation /
Repository / UI / Tests / Deep Links) is a section in the roadmap. Here is
what each *is* and how it connects.

```
┌─ 01 Quran Semantic Layer ───────────────────────────────────────────────┐
│  quran_ayat (Tanzil text), quran_surahs, juz/hizb/page/sajda metadata.   │
│  SOURCE OF TRUTH for text + structure. Immutable. Already exists.        │
└───────────────┬────────────────────────────────────────────────────────┘
┌─ 02 Mushaf Rendering Layer ─────────────────────────────────────────────┐
│  The real page art (MushafDatabase SVG) + invisible interaction overlay. │
│  Draws pages; emits (surah, ayah, word_index) on tap. Already partly     │
│  built (mushaf_page_view.dart); visual render still to do (ERRATA E‑1).  │
└───────────────┬────────────────────────────────────────────────────────┘
┌─ 03 Word Layer ────────────────────────────────────────────────────────┐
│  The addressable unit: QuranWord = orthography (uthmani/imlaey) +        │
│  position (page,line,word_order,bbox) + identity (surah,ayah,word_index).│
│  Comes straight from mushaf_words. The spine every study layer hangs on. │
└───────┬───────────────┬───────────────┬───────────────┬────────────────┘
        │               │               │               │
┌─ 04 Morphology ─┐ ┌─ 05 Syntax ──┐ ┌─ 06 Tajwīd ──┐ ┌─ 07 Tafsīr ───────┐
│ root, lemma,     │ │ SyntaxNode + │ │ TajweedRule  │ │ TafsirEntry per   │
│ pattern (wazn),  │ │ SyntaxRelation│ │ over a range │ │ ayah/range, multi │
│ POS, tense,      │ │ = the iʿrāb   │ │ + rule_id +  │ │ edition, sourced. │
│ person, number,  │ │ graph per     │ │ reason +     │ │ Already have 5 AR │
│ gender, features │ │ ayah. Typed   │ │ articulation │ │ + ~40 lang tables.│
│ + SourceRef      │ │ edges.        │ │ + SourceRef  │ │                   │
└───────┬─────────┘ └──────┬───────┘ └──────┬───────┘ └────────┬─────────┘
        └───────────────┬──┴─────────────────┴───────────────┬─┘
┌─ 08 Study Notebook Layer ──────────────────────────────────────────────┐
│  ayah_study_entries (already built) + the "learning path" extension:     │
│  a concept the student chose to learn, with its explanation/examples/    │
│  Quranic examples, and a link back to the ayah/word it started from.     │
└───────────────┬────────────────────────────────────────────────────────┘
┌─ 09 Learn → Apply → Review Layer ──────────────────────────────────────┐
│  The flow, NOT a quiz. "تعلّم هذا" opens the concept in the notebook as  │
│  concept→explanation→examples→Quranic examples→application. "طبّق في     │
│  القرآن" returns to (surah, ayah, word_index). "راجِع" re-surfaces it.   │
└───────────────┬────────────────────────────────────────────────────────┘
┌─ 10 Knowledge Graph ──────────────────────────────────────────────────┐
│  Explicit stored edges: word──(has_root)──▶root, word──(faail_of)──▶verb,│
│  position──(tajweed_rule)──▶rule, ayah──(explained_by)──▶tafsir,         │
│  concept──(illustrated_by)──▶(surah,ayah,word). No edge is inferred at   │
│  display time if a stored edge exists.                                  │
└───────────────┬────────────────────────────────────────────────────────┘
┌─ 11 Study Events ─────────────────────────────────────────────────────┐
│  Append-only log: opened | studied | noted | linked | reviewed | applied │
│  keyed to (surah, ayah[, word_index]) + concept_id + layer. NOT click    │
│  counting — distinct verbs with distinct weights.                       │
└───────────────┬────────────────────────────────────────────────────────┘
┌─ 12 Mathematical Intelligence ────────────────────────────────────────┐
│  docs/STUDY_INTELLIGENCE_ENGINE_SPEC.md. Consumes Layer 11 events →      │
│  Coverage / Retention / Consistency / Depth / Neglect / ReviewPriority   │
│  per surah/juz/page/concept. Deterministic, explainable. Consumer only.  │
└──────────────────────────────────────────────────────────────────────┘
```

**Dependency direction:** 01 → 02 → 03 → {04,05,06,07} → 08 → 09; 10
indexes 03–08; 11 records interactions with 08–09; 12 reads 11. Nothing
lower depends on anything higher.

---

## 3. The "tap and learn" interaction (Layer 02 → 03 → panel)

```
        mushaf page (Rendering Layer)
              │  tap → hit-test → MushafWord
              ▼
   ┌───────────────────────────────────────────┐
   │  يَعْلَمُونَ            (surah, ayah, word_index) │
   ├───────────────────────────────────────────┤
   │  📖  دفتر الآية            (Layer 08)        │
   │  📚  النحو والإعراب        (Layer 05)        │
   │  🔤  الصرف                (Layer 04)        │
   │  🟢  التجويد              (Layer 06)        │
   │  📜  التفسير              (Layer 07)        │
   │  💡  الفوائد / ملاحظاتي    (Layer 08)        │
   └───────────────────────────────────────────┘
```

- The panel is a **launcher**, not the lesson. Each row shows *whether data
  exists* for this word/ayah (count / "—") and opens the relevant surface.
- Choosing e.g. **النحو والإعراب**:
  1. shows the *verified iʿrāb for this word in this ayah* (Layer 05 data,
     with its `SourceReference`), and the local structure (see §4);
  2. offers **«تعلّم هذا»** → opens the underlying *concept*
     (e.g. "خبر إنّ") in the Student Notebook as a learning-path item
     (Layer 09): `concept → explanation → examples → Quranic examples →
     application`;
  3. offers **«طبّق ما تعلمت في القرآن»** → returns to `(surah, ayah,
     word_index)` with that concept's occurrences highlighted on the page.
- No answer is generated. Everything shown is a lookup of stored, sourced
  data. If a row has no data: *"لا توجد بيانات موثقة لهذا العنصر حاليًا."*

---

## 4. The iʿrāb graph (Layer 05) — interactive structure, not a paragraph

Per ayah, a **stored** graph:

```
Ayah (surah, ayah)
 ├─ SyntaxNode  n1  → word_index 1  "إِنَّ"      role: حرف توكيد ونصب
 ├─ SyntaxNode  n2  → word_index 2  "ٱللَّهَ"     role: اسم إنّ منصوب
 ├─ SyntaxNode  n3  → word_index 3  "غَفُورٌ"     role: خبر إنّ مرفوع
 └─ SyntaxNode  n4  → word_index 4  "رَحِيمٌ"     role: خبر ثانٍ مرفوع  (per source)

SyntaxRelation edges (typed, stored, each with SourceReference):
  n2 ──(اسم إنّ / ism inna)──▶ n1
  n3 ──(خبر إنّ / khabar inna)──▶ n1
  n4 ──(خبر ثانٍ)──▶ n1
```

- Tapping a **node** → its full morphological + syntactic card.
- Tapping an **edge (relation)** → highlights *both* endpoints on the
  mushaf and explains the relation *type* (a concept, Layer 09-linkable).
- Relation types are a **closed vocabulary** (see `QURAN_DATA_CONTRACTS.md`
  §SyntaxRelation): فاعل، مفعول به، مبتدأ، خبر، اسم إنّ، خبر إنّ، مضاف،
  مضاف إليه، صفة، موصوف، بدل، عطف، معطوف عليه، جار ومجرور، متعلَّق، حال،
  ظرف، تمييز، نعت، … — extended only when a source uses one we lack.
- Where the source dataset only annotates *some* ayat (QAC syntax covers
  ~11k words, MASAQ ~full — see `QURAN_SOURCES_AND_LICENSES.md`), the graph
  for un-annotated ayat is simply absent → A5.

---

## 5. Tajwīd over the mushaf (Layer 06)

```
TajweedRule
  anchor: (surah, ayah, word_start, word_end[, char_start, char_end])
  rule_id: e.g. "ikhfa"            ← STORED id, never a colour
  rule_family: أحكام النون الساكنة والتنوين
  cause: "نون ساكنة يليها حرف الذال"      ← from source
  letters: [ن, ذ]
  articulation: "..."                    ← from source (how to pronounce)
  audio_ref?: SourceReference to a verified recitation clip of this spot
  source: SourceReference
```

- Rendering = look up the rule's `word_start..word_end` → Mushaf Semantic
  Layer gives the per-line union `bbox` → draw the emphasis over the real
  page art.
- Colour is chosen **in-app** from `rule_id` (publishers disagree —
  `docs/quran/KNOWLEDGE.md` R‑14). Store the id; the palette is a UI
  setting.
- Tapping a marked span → the rule card (cause / letter / articulation /
  listen if a sourced clip exists) → **«تعلّم هذا»** opens the rule *family*
  concept in Layer 09.

Rule families to support (only with data): إظهار، إدغام (بغنة/بغير غنة)،
إخفاء، إقلاب، غنّة، قلقلة، تفخيم، ترقيق، المدود (طبيعي/متصل/منفصل/لازم/عارض/بدل/…)،
أحكام النون الساكنة والتنوين، أحكام الميم الساكنة، أحكام اللام، الوقف والابتداء.

---

## 6. Learn → Apply → Review (Layer 09) — the replacement for "test mode"

There is **no quiz, no score-on-answer, no "try first then reveal"**. The
loop is:

```
1. LEARN     student picks a concept (from a word's iʿrāb / ṣarf / tajwīd
             card, or browses the notebook). It opens as a learning-path
             item:  المفهوم → الشرح → أمثلة → أمثلة قرآنية → التطبيق
             All content is sourced (Layer style: SourceReference on every
             block). If the app has no lesson for a concept yet → it shows
             the raw sourced fact + "درس هذا المفهوم غير متوفر بعد".

2. APPLY     "طبّق ما تعلمت في القرآن" → jumps to the (surah, ayah,
             word_index) it started from, and can highlight *other*
             occurrences of the same concept on the current page/surah
             (from Layer 10 stored edges), so the student sees the rule
             live in the text.

3. REVIEW    the concept + its origin ayah become a StudyItem. The
             Mathematical Intelligence engine (Layer 12) schedules it for
             review by Neglect/Retention — surfacing it again later at the
             same mushaf spot. "راجعت" is a StudyEvent, not a grade.
```

`StudyEvent` verbs for this layer: `opened`, `studied` (dwell + scrolled
the learning path), `noted` (wrote in the notebook), `linked` (attached the
concept to an ayah/word), `applied` (used "طبّق"), `reviewed`. **No**
`answered/correct/incorrect`.

---

## 7. Integration with what already exists

| existing thing | how this plugs in | change to it |
|---|---|---|
| **Mushaf Semantic Layer** (`mushaf_*`, `MushafLayoutRepository`) | the spatial index: `(surah, ayah, word_index) → (page, line, bbox)`. Every study fact resolves its on-page location through this. | **none** — read-only consumer |
| **AyahStudyNotebook** (`ayah_study_entries`, `AyahNotebookScreen`) | Layer 08. "أضف إلى دفتري" from any study card creates an `ayah_study_entry`; the new *learning-path* item is a new `entry_type` / sibling table, TBD in contracts. | additive (new entry types / a sibling `learning_path_items` table); no schema break |
| **StudyItem / StudyEvent** (Study Intelligence direction) | Layer 11/12. Each concept, lesson, tafsir-read, tajwīd-study becomes a `StudyItem`; interactions become `StudyEvent`s. | this design *defines* the Quran-side `StudyItem` kinds and `StudyEvent` verbs |
| **Study Intelligence Engine** (`docs/STUDY_INTELLIGENCE_ENGINE_SPEC.md`) | Layer 12. Pure consumer of Layer 11. | none — its spec already anticipates `quran_ayah` / `quran_word` items |
| **Tafsir tables** (`tafsir_entries`, ~45 editions) | Layer 07 source. Wrapped with `SourceReference` per edition. | none |
| **quran_ayat / quran_surahs** | Layer 01. | none |
| **`docs/quran/` KB + `quran-engineering` skill** | the rules this whole design obeys; new sources get registered there too. | extended, not replaced |

---

## 8. Data-flow summary

```
MushafDatabase SVG ─▶ mushaf_* (Semantic Layer) ─▶ QuranWord (Layer 03)
                                                        │
   verified scholarly datasets ─(validation pipeline)─▶ morphology / syntax /
   (MASAQ, QAC, tajwīd sets,      each fact + SourceRef   tajweed / tafsir rows
    tafsir editions, …)                                   (Layers 04–07)
                                                        │
                              Knowledge Graph edges (Layer 10) index them
                                                        │
   student taps word ─▶ launcher panel ─▶ study card ─▶ "تعلّم هذا"
                                                        │
                              learning-path item in notebook (Layer 08/09)
                                                        │
                              StudyEvents (Layer 11) ─▶ Math Intelligence (Layer 12)
                                                        │
                              review resurfaces it at the same mushaf spot
```

---

## 9. What this design deliberately does NOT include

- No quizzes / graded answers / "teacher asks, student types" (removed per
  Ismail's correction).
- No AI generation of iʿrāb, ṣarf, tajwīd, meaning, or tafsir summary.
- No new *riwāya* (stays Hafs/Kufi/6236).
- No modification of Quran text or the mushaf layer.
- No build work now — the first code is the Prototype in the roadmap, after
  design approval.

---

## 10. Companion documents

- `docs/QURAN_SOURCES_AND_LICENSES.md` — every scholarly data source, what
  we take, licence, what we do **not** take, coverage, and the per-fact
  provenance + `CLAIM→APPROVED` pipeline + `CONFLICT` handling.
- `docs/QURAN_DATA_VALIDATION.md` — validation rules per data type + the
  knowledge-classification gates.
- `docs/QURAN_LEARNING_ROADMAP.md` — layer-by-layer build order, and the
  Prototype spec (§P).
- `docs/QURAN_DATA_CONTRACTS.md` — `QuranWord`, `Morphology`, `SyntaxNode`,
  `SyntaxRelation`, `TajweedRule`, `TafsirEntry`, `StudyEntry`,
  `StudyEvent`, `SourceReference` (+ `LearningConcept`, `LearningExample`,
  `KnowledgeAnchor`, `KnowledgeEdge`).
- `docs/quran/` — the engineering knowledge base this all sits on.
