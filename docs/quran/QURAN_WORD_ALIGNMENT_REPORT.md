# Tanzil ↔ MushafDatabase — Word Alignment Report

**Status: NOT YET RUN.** This file is the output slot for the verification
tool specified in `QURAN_DATA_VERIFICATION_TASKS.md` VT‑3. It will be filled
by a one‑off checked‑in script that compares `quran_ayat.text_uthmani`
(Tanzil v1.1) against `mushaf_words.text_uthmani` (MushafDatabase V1.01) at
`(surah, ayah, word_index)` and emits both this summary and
`assets/quran_learning/mapping/tanzil_to_mushafdb.json`.

**The tool must never modify either text to make the numbers match.** A
MISMATCH is recorded with its cause, not hidden.

---

## Template (to be populated)

```
Generated:                  <date>
Tanzil:                     v1.1        MushafDatabase: V1.01
kNorm used for comparison:  normalizeArabicForSearch()

Total ayat:                 6236
Total Tanzil tokens:        <n>
Total Mushaf text words:    <n>   (excludes 199 juz-star + 15 sajda-mehrab)

MATCH:                      <n>   (<pct>%)
MISMATCH_TEXT:              <n>
SPLIT / MERGE:              <n>
UNMAPPED:                   <n>
Ayat fully aligned:         <n> / 6236

MISMATCH_TEXT table:
  (surah, ayah, pos) | Tanzil raw | Mushaf raw | normalized diff | likely cause

SPLIT/MERGE table:
  (surah, ayah) | Tanzil range | Mushaf range | note

UNMAPPED table:
  (surah, ayah, side, pos) | token | note

Causes observed:
  - <e.g. dabt difference: U+0653 placement>
  - <e.g. waṣla alif spelled differently>
  - <e.g. tokenisation: particle joined in one source, split in the other>

Decision:
  tanzil-space ⇔ mushafdb-v1.01 mapping is
     [ reliable at word level ]  /  [ needs <n> per-ayah exceptions ]
  → external-segmentation facts may render on the page: [ yes / only where mapped ]
```

---

## Why this exists

The learning chain `Mushaf Word → Morphology → Syntax → Tajweed → Audio →
Notebook` requires one stable word identity. External datasets index words
in their own segmentations:

- **tanzil-space** — cpfair/quran-tajweed offsets, quran-align timing
- **masaq** — MASAQ morphology + syntax
- **qac** — Quranic Arabic Corpus morphology (cross-check)
- **mushafdb-v1.01** — ours (the on-page truth)

Every fact must resolve to a `mushafdb-v1.01` `word_index` before it can be
shown over the muṣḥaf. This report + the mapping JSON are that bridge. Until
it is run, external-segmentation facts stay `mapping_status = unmapped` and
appear only in a text view with a warning
(`../QURAN_DATA_VALIDATION.md §M`, §D5).
