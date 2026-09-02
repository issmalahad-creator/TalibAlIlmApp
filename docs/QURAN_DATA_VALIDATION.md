# Quran Learning — Data Validation Rules

**Status: DESIGN ONLY.** How every piece of teaching data is checked before
it can be stored, and before it can be *displayed*. Companion to
`QURAN_DATA_CONTRACTS.md` (shapes), `QURAN_SOURCES_AND_LICENSES.md`
(provenance), `QURAN_LEARNING_ARCHITECTURE.md` (rules A1–A10).

Two gates:
- **Ingest gate** — a row may be stored only if it passes §I + its
  type-specific rules.
- **Display gate** — a stored row may be *shown as a scholarly claim* only
  if it passes §D.

---

## I. Ingest gate (all teaching rows)

`I1` The row has a `source_ref_id` resolving to a `SourceReference` with:
non-empty `name`, non-empty `license`, `license_use ∈ {bundled_ok,
link_only}` **for anything that will be bundled/shipped**. `study_only` /
`unknown` rows may be stored **only** in a `_staging` area, never in a
shipped asset.

`I2` `classification ∈ {VERIFIED, SOURCE-BACKED, PROJECT-SPECIFIC}` for any
row that will back a displayed claim. `INFERENCE` / `UNKNOWN` rows are
allowed only as gap annotations (`kind = gap_note`).

`I3` `KnowledgeAnchor` is well-formed:
- `surah ∈ 1..114`;
- `ayah ∈ 1..canonicalAyahCount(surah)` (from `lib/data/quran_surahs.dart`, Σ 6236);
- if `word_start`/`word_end` set: `1 ≤ word_start ≤ word_end`, and
  `word_end ≤ maxWordIndex(surah, ayah, segmentation)`;
- `segmentation` is present and known when `word_*` set;
- `char_*` only present if the source annotates character spans; if set,
  `0 ≤ char_start ≤ char_end ≤ len(rangeText)`.

`I4` **Segmentation mapping (§M).** If `segmentation ≠ "mushafdb-v1.01"`,
either a mapping row exists for every `(surah, ayah, sourceWordIndex)` in the
row's range, or the row is stored with `mapping_status = unmapped` and is
**excluded from any on-page rendering** (still usable in a text-only view
with a warning).

`I5` No duplicate primary key (`id`). Re-ingesting the same source version
replaces wholesale (like `TurathCatalogSync` / `MushafLayoutSync`), never
partial-merges.

`I6` Cross-field sanity per type (§§ below).

---

## D. Display gate (showing a row as a scholarly claim)

`D1` `classification ∈ {VERIFIED, SOURCE-BACKED}`. (`PROJECT-SPECIFIC` may be
shown only for app-internal facts, e.g. "this word is on page 49", not for
grammar/tajwīd/tafsīr.)

`D2` `SourceReference` is complete enough to cite: the student can see at
least `name` + (`author` or `book` or `url`) + `license`.

`D3` If a `CONFLICT` entry exists for this `(anchor, field)` → the UI shows
**all** options, each attributed, labelled "اختلفت المصادر"; it must **not**
show one silently.

`D4` If no passing row exists for the requested element → UI shows
*"لا توجد بيانات موثقة لهذا العنصر حاليًا."* Never a fabricated or
degraded-guess value.

`D5` On-page (over the mushaf) display additionally requires `mapping_status
= mapped` (from §M) so the highlight geometry is correct.

---

## C. Confidence

`confidence ∈ [0,1]` is a **stored** property of a `SourceReference` (or a
`cross_ref`), assigned by these rules — **never** computed by AI, never a
model probability:

| situation | confidence |
|---|---|
| ≥2 independent authoritative sources agree, exact match | 0.95–1.00 → `VERIFIED` |
| 1 peer-reviewed/academic or classical-scholarly source, unchallenged | 0.80–0.90 → `SOURCE-BACKED` |
| 1 institutional/community source, plausible, unchallenged | 0.60–0.75 → `SOURCE-BACKED` |
| sources partially agree (same value, different detail) | 0.55–0.70, note the divergence |
| sources disagree on the value | **not a confidence — a `CONFLICT`** |
| our own synthesis / derivation | ≤0.50, `classification = INFERENCE`, **cannot be displayed as a claim** |

Confidence is shown to the student only as a coarse badge
(موثّق / مقبول / محل خلاف), not a number.

---

## Type-specific rules

### Morphology (§Mor)
- `Mor1` `pos` ∈ the closed POS tagset; `pos_ar` present.
- `Mor2` Verbal features (`aspect/mood/voice/form`) present ⇔ `pos = V`.
- `Mor3` Nominal features (`case/state`) present ⇔ `pos ∈ {N, PN, ADJ, PRON, …}`.
- `Mor4` `root` (if present) is 2–5 space-separated Arabic radicals.
- `Mor5` `segments` concatenate (surface) to the word's `text` in the row's
  segmentation (tolerance: diacritics).
- `Mor6` Cross-check against a **second** source (QAC ↔ MASAQ ↔ Treebank ↔
  quran.ai morphology). Match on `root` + `pos` at minimum. Mismatch →
  `cross_refs` entry; if `authority` equal → `CONFLICT`.

### Syntax (§Syn)
- `Syn1` `role` ∈ closed vocab (`QURAN_DATA_CONTRACTS.md §6`); unmapped
  source roles logged in `unmapped_roles` register, **not** invented.
- `Syn2` `SyntaxRelation.from_node_id` / `to_node_id` exist, same ayah,
  and `from ≠ to`.
- `Syn3` No relation cycle within an ayah (dependency graph is a forest).
- `Syn4` Every `SyntaxRelation` has a governor reachable to an ayah root
  (or is explicitly a root/`isti'naf` node).
- `Syn5` Coverage is **not** required — an ayah with no syntax rows is valid
  (partial datasets, A5). A `syntax_coverage` table records which ayat have
  a full tree, which partial, which none.
- `Syn6` `irab_text` (if present) is verbatim from the source; not rephrased.

### Tajwīd (§Taj)
- `Taj1` `rule_id` ∈ the closed tajwīd list; `rule_family` consistent with it.
- `Taj2` `anchor.scope ∈ {char_range, word, word_range}`; `char_*` present
  ⇒ they index the concatenated range text.
- `Taj3` **Offset provenance:** the row records which base text its
  `char_*`/`word_*` came from (`segmentation` + the base text file id). If
  base ≠ our display text, §M mapping is mandatory before §D5.
- `Taj4` `letters` are the actual letters the rule concerns (e.g. `[ن, ذ]`
  for that `ikhfa`), verifiable against the range text.
- `Taj5` `audio_ref_id` (if set) resolves to a `SourceReference` with
  `source_type = audio_recitation`, a named reciter, and a shippable licence.
- `Taj6` Colour is **absent** from the row (checked — no `color` field).

### Tafsīr (§Taf)
- `Taf1` `edition_id` ∈ known editions; `source_ref_id` is the per-edition
  reference.
- `Taf2` `text` is verbatim; markup sanitised for display but content
  unaltered; no truncation mid-sentence without an ellipsis marker.
- `Taf3` `ayah_from ≤ ayah_to` in muṣḥaf order.
- `Taf4` No merging of editions; each stored and shown separately.

### LearningConcept (§Con)
- `Con1` `domain` set; `title_ar` + `short_def_ar` present, and
  `short_def_ar` has a `source_ref_id`.
- `Con2` Each `block` of kind `definition/explanation/example` has a
  `source_ref_id` (a cited grammar/tajwīd reference or a public-domain matn).
- `Con3` `quranic_example` / `application` blocks have a resolvable
  `quran_ref` (`KnowledgeAnchor`) that passes §I3.
- `Con4` No block text is AI-generated. Prose is authored from the cited
  source (paraphrase-with-citation is allowed; wholesale copying of a
  copyrighted edition is not — see `QURAN_SOURCES_AND_LICENSES.md §B3`).
- `Con5` `status = missing` allowed (link target with no lesson yet).

### StudyEvent (§Evt)
- `Evt1` `verb ∈ {opened, studied, noted, linked, applied, reviewed}` —
  **never** `answered/correct/incorrect` (no quiz; contract invariant 14.7).
- `Evt2` `ts` is ISO-8601 UTC, not in the future.
- `Evt3` `anchor` (if present) passes §I3.
- `Evt4` Append-only: events are never updated or deleted (Layer 12 needs a
  faithful history).

### KnowledgeEdge (§Edg)
- `Edg1` `from_id`/`to_id` reference existing entities of the stated kind.
- `Edg2` Scholarly edge types (`has_root`, `syntactic_role`, `tajweed_at`,
  `explained_by`, `illustrates`, `same_root_as`) require `source_ref_id`.
- `Edg3` Student edge types (`noted_by`, `learned_via`) require a
  `study_entry`/`learning_path_item` id and no source.
- `Edg4` `same_root_as` edges are **built once** from validated `Morphology`
  rows (both endpoints share `root`), not recomputed by string match at
  display time (A / graph rule).

---

## M. Segmentation mapping (the recurring hazard)

External datasets index words differently:

| dataset | segmentation id | notes |
|---|---|---|
| MushafDatabase V1.01 (ours) | `mushafdb-v1.01` | includes ۞ ۩ as indexed tokens |
| Tanzil space-split | `tanzil-space` | quran-align, cpfair-tajweed base |
| QAC | `qac` | its own morpheme-aware word boundaries |
| MASAQ | `masaq` | its own |

**Rule:** for each external `segmentation`, build and store a mapping
`(surah, ayah, sourceWordIndex) → mushafdb word_index` (or a small range
when tokens split/merge). Validation:
- every source token maps to ≥1 `mushafdb` token and vice-versa within an
  ayah (no orphan on either side);
- text of mapped tokens matches after `normalizeArabicForSearch` on both
  sides (tolerance: the known dabt differences);
- unmapped tokens are listed per dataset — the feature degrades gracefully
  (text view only) for those, never guesses.

Until a dataset's mapping is built and validated, its rows are
`mapping_status = unmapped` and **cannot render on the page** (§D5).

Open item (`UNKNOWN`, also in `docs/quran/`): is our
`quran_ayat.text_uthmani` (Tanzil v1.1) per-word identical to MushafDatabase
`data-hafs`? A full diff must run before trusting `tanzil-space` ⇔
`mushafdb-v1.01` at word level.

---

## K. Conflict register

A living list (`docs/QURAN_DATA_CONFLICTS.md`, created when the first
conflict is found). Each entry:

```
{ id, anchor, field,
  option_A: { value, source_ref_id, authority, confidence },
  option_B: { value, source_ref_id, authority, confidence },
  discovered: ISO, status: open | resolved,
  resolution?: { chosen, by: "higher-authority" | "ismail", note, ISO } }
```

Rules: never auto-resolve; UI shows all options attributed; a `resolved`
entry records *who* decided and *why*.

---

## V. Validation harness (design — tests to write when building)

Mirror `MushafLayoutSync`'s style: a pure `validate(...)` returning a report
with counts + failures, run before any ingest, plus a post-insert
cross-check inside the transaction. Reports:
- rows ingested / rejected per source, with reasons;
- coverage per layer (ayat with morphology / syntax / tajwīd / tafsīr);
- unmapped-token counts per segmentation;
- open conflicts;
- `study_only`/`unknown`-licence rows present in staging (must be 0 in any
  shipped asset).

Canonical ground truth for every check: 114 surahs, per-surah ayah counts
from `lib/data/quran_surahs.dart` (Σ 6236), `mushaf_words` for `word_index`
ranges.
