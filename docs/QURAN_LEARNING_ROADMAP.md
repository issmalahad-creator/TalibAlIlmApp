# Quran Learning — Build Roadmap

**Status (2026-08-30): PROTOTYPE BUILT** — the full chain runs on al-Fātiḥa
+ al-Ikhlāṣ (see "Prototype — DONE" below). Widening = more seed data, no
re-architecture.

**Priority order (Ismail 2026-08-30, P0 critical):**

1. **P0 — إعراب القرآن + النطق + الربط بالمصحف** (Quran grammar / iʿrāb, its
   effect on pronunciation, tapped inside the mushaf, interactive relations).
2. **P1 — الصرف** (morphology).
3. **P2 — التجويد** (tajwīd rule spans).
4. **P3 — التفسير ومعاني الكلمات**.
5. then the rest.

Do not spread across domains equally — the iʿrāb loop *is* the pattern every
other science reuses.

Order principle: build a tiny end-to-end slice first to prove the chain
holds, *then* widen. Do **not** build the ṣarf layer fully and discover a
month later it doesn't join to naḥw / tajwīd / the mushaf.

Every phase below carries the same 8 facets: **Data Model · Source ·
License · Validation · Repository · UI · Tests · Deep Links**. They are
sketched here; the full spec for a phase is written (and approved) just
before that phase starts.

Nothing existing is changed or removed at any phase (`ARCH` A9).

---

## §P · PROTOTYPE — **DONE 2026-08-30** (phase `79-ql`)

Proves the P0 chain — *tap word → iʿrāb + relation + reason + pronunciation
+ source → «تعلّم هذا» → lesson in the notebook → «طبّق» back to the word* —
on **Sūrat al-Fātiḥa (1:1–1:7) + al-Ikhlāṣ (112:1–4)**. Also carries ṣarf
(P1) and tajwīd (P2) for the same words, so all three domains share one
gateway.

**Built:**
- **Data** `assets/quran_learning/prototype.json` (built by
  `tool/build_quran_learning_prototype.py`): **117 sourced facts** — 47 naḥw
  (every word, each with typed relations + العلامة + السبب), 47 ṣarf
  (root/lemma/pattern/POS/features), 23 tajwīd — + **17 concepts** + **7
  `SourceReference`s**. Sources: **Quranic Arabic Corpus** (ṣarf; verbatim +
  attribution + link) · derived iʿrāb of these universally-parsed verses
  (`src:nahw-basic`, cites QAC + agreed grammar) · **cpfair/quran-tajweed**
  (CC BY 4.0, remapped Tanzil-offset → `mushafdb-v1.01`) · public-domain
  matns (تحفة الأطفال، الجزرية) for concept prose. **No AI.**
- **Schema** migration **v52**: `source_references`, `knowledge_facts`,
  `knowledge_concepts`, `learning_path_items`, `study_events` (append-only,
  no quiz verbs), `knowledge_cache`, `quran_learning_meta`, +
  `ayah_study_entries.concept_id` (guarded ALTER). `mushaf_*`, `quran_ayat`,
  `tafsir_entries`, `ayah_study_entries` structure untouched.
- **`QuranLearningSync`** — seed + validate (every fact → a bundleable,
  displayable source; anchors valid) + reject-on-bad + post-insert
  cross-check.
- **`KnowledgeGateway`** (AD‑1): `QacGrammarProvider` (ONLINE, first grammar
  provider, **inert** until a real endpoint + online licence — Ismail's
  P0 note) → `LocalKnowledgeProvider` → `LocalTafsirProvider`. Per-fact
  `dataState`; no provider is a dependency; missing = "لا توجد بيانات موثقة".
- **`QuranLearningRepository`** — `factsForWord`, `irabForAyah`,
  `availableDomainsOrdered` (naḥw first), concepts, `startLearning`,
  learning-path, `logEvent`.
- **UI**: `showWordKnowledgeSheet` (launcher, **الإعراب first**) →
  `IrabViewScreen` (ayah words as chips + role labels; tap a word → full
  card: الوظيفة / العلامة / لماذا / العلاقات / أثر العلامة في النطق + 🔊
  استماع via EveryAyah; tap a relation → the linked word lights up;
  «تعلّم هذا») → `LearningLessonScreen` (concept → blocks, each sourced;
  «طبّق ما تعلمت» → back to the origin word; «أضف إلى دفتري» →
  `AyahNotebookScreen` with `concept_id`). Wired into
  `MushafSemanticReaderScreen` word-tap.
- **`MushafPageView`** legibility fix — one glyph size per page (no
  per-word `FittedBox`), partial `ERRATA` E‑1 mitigation; real print-art
  SVG render is still the next widening step.
- **Tests** `test/quran_learning_test.dart` (12): validation passes;
  no-source fact rejected + DB untouched; every seeded fact → bundleable
  displayable source; tap 1:1 w1 → ṣarf+naḥw+source; tap 1:1 w3 → sourced
  tajwīd (همزة الوصل); 112:1 iʿrāb covers all 4 words with typed relations;
  launcher orders naḥw first; «تعلّم هذا» → concept + learning-path item +
  non-quiz event; quiz verb dropped; learning path grouped by domain.
- `flutter analyze` clean · **421 tests pass** (+12) + the pre-existing
  `widget_test.dart` failure · APK built.

**Widen next (P0 → P1 → P2 → P3):** regenerate `prototype.json` for more
surahs — the ṣarf side already has a clear licence (QAC / MASAQ once its
file is placed); naḥw widens via MASAQ syntax or authored-with-citation;
tajwīd is the full 6236-ayah cpfair set once VT‑3 mapping is generalised.

## (superseded) §P — original plan: prove the whole chain on ~5 ayat

**Goal:** tap a word on a real mushaf page → see its **ṣarf**, its **naḥw
(iʿrāb)**, its **tajwīd**, each with its **source** → **"أضف إلى دفتر
الآية"**. On ≤5 hand-curated ayat (e.g. al-Fātiḥa 1–2, al-Baqara 255,
al-Ikhlāṣ 1–2). If this holds, widen.

- **Data Model:** the contracts in `QURAN_DATA_CONTRACTS.md`, but only the
  rows for the chosen ayat, hand-entered into a small checked-in JSON
  asset (`assets/quran_learning/prototype.json`) — every row with a real
  `SourceReference`.
- **Source:** for the prototype, author the ~50 rows from **openly-usable**
  sources only: cpfair/quran-tajweed (CC-BY 4.0) for tajwīd; quran.ai MCP
  `fetch_word_morphology` + a public-domain iʿrāb reference for ṣarf/naḥw,
  each cited. No `study_only` data.
- **License:** every prototype row `license_use = bundled_ok`; the asset
  header lists them.
- **Validation:** a `validate()` over `prototype.json` enforcing
  `QURAN_DATA_VALIDATION.md` §I + §D + the segmentation mapping (§M) for the
  5 ayat only. Must pass before the screen renders.
- **Repository:** one read-only `QuranLearningRepository` (prototype scope):
  `factsForWord(surah, ayah, word_index)` → `{morphology?, syntaxNode?,
  syntaxRelations[], tajweed[], sources[]}`.
- **UI:** extend the existing `MushafSemanticReaderScreen` word-tap sheet
  (do **not** fork it): the launcher panel (§ARCH 3) with rows enabled only
  where prototype data exists; a card per layer showing the sourced fact +
  a "المصدر" line; an "أضف إلى دفتر الآية" button wired to the existing
  `AyahNotebookScreen` (`ayah_study_entries`, new `entry_type =
  concept_note`, new nullable `concept_id`).
- **Tests:** widget test (tap → panel → card shows sourced text); repo test
  (`factsForWord` returns exactly the curated rows); validation test
  (a deliberately broken row is rejected); a "no data" test (a word with no
  rows shows *"لا توجد بيانات موثقة"*).
- **Deep Links:** `word → concept` (stub `LearningConcept` with
  `status = stub`); `card → AyahNotebookScreen(surah, ayah)`; back-link
  from a notebook `concept_note` entry to `(surah, ayah, word_index)`.

**Exit criterion:** Ismail taps 5 words across those ayat on his device and
each shows correct ṣarf + naḥw + tajwīd + source, and the note round-trips.

---

## Phase L01 · Quran Semantic Layer  (already exists — formalise the read model)

- Wrap `quran_ayat` + `quran_surahs` + Tanzil metadata behind a stable
  `QuranTextRepository` returning `QuranAyah` with structure fields.
- Validation: already done by `QuranImportService` + `MushafLayoutSync`.
- Deep links: `(surah, ayah)` ⇄ juz/hizb/page/sajda.
- **New code:** minimal (a thin repo); no schema change.

## Phase L02 · Mushaf Rendering Layer  (real page art)

- Resolve `ERRATA` E‑1: render the **MushafDatabase SVG page art** (via
  `flutter_svg`) + the invisible bbox overlay for interaction.
- Size decision (Ismail): bundle xz-compressed SVGs (~46 MB) **or**
  download-per-page + cache. **Blocked on his call.**
- Validation: visual QA on ≥1 full juz on device; overlay hit-test still
  passes `mushaf_page_view_test`.
- Deep links: page ⇄ `(surah, ayah, word_index)` (already via
  `MushafLayoutRepository`).

## Phase L03 · Word Layer  (the spine)

- `QuranWord` read model (`QURAN_DATA_CONTRACTS.md §2`) assembled from
  `mushaf_words` + `quran_ayat`.
- `QuranLearningRepository.wordAt(surah, ayah, word_index)` and
  `wordsForAyah(...)`.
- Tests: identity + position round-trip for representative pages.

## Phase L04 · Morphology Layer

- **Blocked on licence** (`QURAN_SOURCES_AND_LICENSES.md §Z`): resolve MASAQ
  / QAC redistribution. If unresolved → prototype-style curated subset only,
  widened as licence clears.
- Build `Morphology` rows + `has_root`/`has_lemma`/`has_pattern`/
  `same_root_as` `KnowledgeEdge`s. Segmentation mapping (§M) to
  `mushafdb-v1.01`.
- UI: ṣarf card (root/pattern/POS/features/segments + source); tap root →
  same-root words (from stored edges) highlighted across the surah/page.
- Validation: §Mor + §M + cross-check vs quran.ai morphology.

## Phase L05 · Syntax Layer  (iʿrāb graph)

- `SyntaxNode` + `SyntaxRelation` (`QURAN_DATA_CONTRACTS.md §4–6`).
  Primary source = MASAQ (full coverage) if licence permits; else QAD
  treebank (~11k words) + curated, with honest gaps (`ARCH` A5).
- UI: the interactive graph (§ARCH 4) — tap node → card; tap edge →
  highlight both endpoints on the mushaf + explain the relation type.
- `syntax_coverage` table records full/partial/none per ayah.
- Validation: §Syn (closed vocab, forest, endpoints exist).

## Phase L06 · Tajwīd Layer

- Ingest cpfair/quran-tajweed (CC-BY 4.0) → `TajweedRule` rows; **rebuild
  offsets** against our text / map to `mushafdb-v1.01` (§M) — mandatory.
  Cross-check with QUL Tajweed V4.
- UI: emphasis over the real page art from `rule_id` (colour = in-app
  palette setting); tap span → rule card (cause/letter/articulation/listen
  if a licensed clip exists) → "تعلّم هذا" → rule-family concept.
- Validation: §Taj (`rule_id` closed, no colour field, offset provenance,
  letters verifiable).

## Phase L07 · Tafsīr Layer

- Wrap existing `tafsir_entries` (~45 editions) as `TafsirEntry` +
  `SourceReference` per edition. Multi-edition side-by-side, verbatim.
- Add word-by-word **meaning** (QUL word translations, licence permitting).
- UI: "📜 التفسير" row → edition picker → verbatim text + attribution.
- Validation: §Taf (verbatim, no merge, no summary).

## Phase L08 · Study Notebook Layer  (extend the existing notebook)

- `ayah_study_entries`: add `entry_type = concept_note`, nullable
  `concept_id`. New sibling table `learning_path_items`
  (`QURAN_DATA_CONTRACTS.md §10`). **No break** to the current notebook.
- UI: "أضف إلى دفتري" from any study card → prefilled `concept_note`;
  a concept's notebook page shows the student's entries + the learning-path
  state.
- Deep links: `learning_path_item ⇄ (surah, ayah, word_index)`;
  `concept_note ⇄ concept`.

## Phase L09 · Learn → Apply → Review Layer  (no quiz)

- `LearningConcept` + `LearningBlock` content, authored from cited
  grammar/tajwīd references + public-domain matns (تحفة الأطفال، الجزرية).
  `status ∈ {authored, stub, missing}`.
- Flow: **"تعلّم هذا"** (opens concept as
  `المفهوم → الشرح → أمثلة → أمثلة قرآنية → التطبيق`) →
  **"طبّق ما تعلمت في القرآن"** (returns to origin `KnowledgeAnchor`,
  highlights other occurrences from Layer 10 edges) →
  **"راجعت"** (a `reviewed` `StudyEvent`).
- Explicitly **not** built: quizzes, graded answers, "try then reveal".
- Validation: §Con.

## Phase L10 · Knowledge Graph

- Materialise `KnowledgeEdge` rows from Layers 04–08 (all scholarly edges
  sourced; student edges from notebook). Query API:
  `edgesFrom(kind, id, type?)`.
- Powers: "words from this root", "other occurrences of this iʿrāb role",
  "ayat explained by this hadith" (when Layer E lands), "concepts that
  illustrate here".
- Validation: §Edg (endpoints exist, sourced where required, `same_root_as`
  built from validated Morphology only).

## Phase L11 · Study Events

- Append-only `study_events` (`QURAN_DATA_CONTRACTS.md §12`). Emit from
  Layers 08–09 UI: `opened / studied / noted / linked / applied / reviewed`.
- `StudyItem` projection (`§13`) for `quran_ayah / quran_word / concept /
  tajweed_family / surah / juz / page`.
- Validation: §Evt (verb set, UTC, append-only).

## Phase L12 · Mathematical Intelligence

- Consumer only. Wire `study_events` → the engine in
  `docs/STUDY_INTELLIGENCE_ENGINE_SPEC.md` → Coverage / Retention /
  Consistency / Depth / Neglect / ReviewPriority per surah/juz/page/concept.
- **No cosmetic dashboard.** Every number expands to Formula + Data source +
  Time window + reason. `opened` ≠ `studied` ≠ `reviewed` ≠ `applied` in the
  weights.
- Review scheduler re-surfaces a concept at its origin mushaf spot.

---

## Cross-phase verification tasks (not blockers)

Per `docs/quran/QURAN_DATA_VERIFICATION_TASKS.md` (findings 2026‑08‑30) and
**AD‑1** (`docs/quran/QURAN_LIVE_DATA_ARCHITECTURE.md` — *Offline‑first, not
Offline‑only*). None of these stops the project; each is a **provider‑mode
decision** (LOCAL / ONLINE / HYBRID) behind the one `KnowledgeGateway`, and
every source is swappable as a single provider adapter. "Can't bundle" ≠
"can't use" — an online source becomes an ONLINE/HYBRID provider, not a
blocker.

| task | affects | status |
|---|---|---|
| **VT‑1** MASAQ / QAC licences | L04, L05 | **RESOLVED** — MASAQ v5 CC BY 4.0 (bundle-able); QAC verbatim + attribution + link, no-modify (bundle-able as cross-check). L04/L05 **offline**, not blocked. Remaining = build-time importer + 72-role mapping + VT‑3. |
| **VT‑2** Mushaf SVG art | L02 | **RESOLVED (licence)** — Sadaqa-e-Jaria, redistribution OK. Open = *packaging choice* (download-all vs lazy-per-page), Ismail's call, no rework either way. |
| **VT‑3** Tanzil ↔ MushafDatabase word alignment | L04–L06 on-page rendering, any `tanzil-space` mapping | **TASK — tool + report designed, not run.** `docs/quran/QURAN_WORD_ALIGNMENT_REPORT.md`. Until run, external-segmentation facts render text-only. |
| **VT‑4** Word audio | L06 "listen" | **RESOLVED (direction)** — source exists (QF `word.audioUrl` + segments); Developer Terms forbid bundling / >1-week cache → **LIVE/stream only**, ephemeral. Open = find a bundle-able audio source, or adopt QF Content Sync (≤7-day re-sync). |
| **VT‑5** QUL per-resource licences | L07 (meaning), L10 (mutashābihāt/topics) | **TASK** — verify each resource before bundling; treat as HYBRID (live proxy + cache) until then. |
| Itqan / Parallel Quran licences | future ḥadīth-link sub-layer of L10 | **TASK** — HYBRID/live until cleared. |

---

## What "done" looks like (the north star)

The mushaf is no longer a viewer. It is **a muṣḥaf + a grammar book + a ṣarf
book + a tajwīd book + tafsīr + the student's own notebook + a practice
ground** — every part anchored to `(surah, ayah, word_index)`, every fact
sourced, no AI as the brain. A student reads; hits an ayah or word they want
to understand; steps from it into the exact knowledge; learns it in their
notebook; steps back to the same spot to see it applied; and the engine
quietly schedules it for review.
