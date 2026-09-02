# Quran Layout — pages, lines, placement, markers, divisions

Tags: see `SOURCES.md`. Companion to `MUSHAF_ENGINEERING.md` (which covers
the printed object and rendering strategy). This file is the reference for
*layout data* specifically.

---

## 1. Page & line grid  (`VERIFIED` for MushafDatabase V1.01)

- 604 pages, numbered `1..604`, no gap.
- Exactly **15 line slots** per page. `line_type` per slot ∈
  `text | surah-name | bismillah | empty`.
- `mushaf_pages.rect_*` = the `md-page-inner` content box in viewBox units
  (varies slightly per page, ~`99, 103, 283, 445`).
- Canonical **viewBox `0 0 382.68 547.09`** for all 604 pages. Origin
  top-left; x → right; y → down. `preserveAspectRatio = xMidYMid meet`.

## 2. Word placement

- `word_order` = reading order on the page (1 = first word read = rightmost
  on an RTL line). `VERIFIED` contiguous `1..N` per page.
- `line` = which of the 15 lines the word sits on.
- `word_index` = 1-based position **within its ayah** (MushafDatabase
  `data-word-index-in-ayah`, verbatim). `VERIFIED` contiguous `1..k` per ayah.
- `bbox` = `[x, y, w, h]` in viewBox units — the **union bounding box of the
  word's glyph vector paths** (on-curve points + Bézier control points →
  conservative, never smaller than the ink). `VERIFIED` all inside viewBox,
  `w>0, h>0`.
- Ornament "words": `word_type = juz-star` (۞, 199) and `sajda-mehrab`
  (۩, 15) occupy real `word_index` slots — they are indexed *between*
  lexical words. Skip or style them specially in a lexical view.

## 3. Ayah markers (verse-end medallions)

- `mushaf_aya_marks`: one row per `(surah, ayah)` — 6236 total, 1:1 with the
  ayah word-set. `VERIFIED`.
- Carries `page`, `line`, and a bbox (nullable — a few marks had no
  extractable path box).
- The medallion contains the ayah number as **Eastern-Arabic digits**, as a
  graphic — **not** part of `text_uthmani`, **not** recited.

## 4. Markers / furniture (`mushaf_markers`)

| `kind` | from | carries | notes |
|---|---|---|---|
| `surah-header` | `surah-name` line | `line`, `surah` (**inferred**) | banner position; surah id is `INFERENCE` (first following ayah-1 word) |
| `bismillah` | `bismillah` line | `line` | present for every surah except at-Tawba (9) |
| `sajda` | margin `md-non-quranic-margin-sajda` | bbox | position only; not the ayah, not the madhhab status |
| `juz-hizb` | margin `md-non-quranic-margin-juz-hizb` | bbox | position only; **no number** — juz/hizb number is not in the SVG |

## 5. Structural divisions — where the numbers live

| division | count | project source of truth |
|---|---|---|
| Surah | 114 | `lib/data/quran_surahs.dart` |
| Ayah | 6236 (Hafs/Kufi) | `quran_ayat` + `quran_surahs.ayahCount` |
| Juz | 30 | `quran_ayat.juz_number` (from Tanzil `quran-data.js` Juz array) |
| Hizb | 60 | `quran_ayat.hizb_number` (derived: `(hizbQuarter-1)~/4 + 1`) |
| Rub el-Hizb | 240 | Tanzil `HizbQuarter` array (not currently a column) |
| Manzil | 7 | not stored; derivable / `quran.ai` metadata |
| Ruku | ~540–558 | Tanzil per-surah `rukus` counts in `quran-data.js`; global numbering not stored |
| Page | 604 | `quran_ayat.page_number` (Tanzil Page array) **and** `mushaf_pages` (MushafDatabase) — two editions, see §7 |
| Sajda | 15 (14 agreed) | Tanzil Sajda array + `mushaf_words[word_type=sajda-mehrab]` |

`SOURCE-BACKED`: Madani mushaf marks **8 points per juz** (rub flowers);
IndoPak marks 4 + rukūʿ.

## 6. Edition-specificity — the recurring trap

Layout is **per-edition**. `VERIFIED` example: for al-Baqara's start,
- quran.ai `fetch_mushaf` (its KFGQPC edition) puts the first text on **page 2, line 10**;
- MushafDatabase V1.01 puts it on **page 2, line 8**.

Same "604-page Madani Hafs", different files, different line maps.

**Rules:**
- Never assume line N of "the mushaf" — always "line N of *MushafDatabase V1.01*".
- Never reuse a QUL / quran.com / quranpedia line index or word_id with our `mushaf_words`.
- A coordinate (bbox/polygon) is only valid in its own viewBox
  (MushafDatabase 382.68×547.09; quranpedia 345×550; QUL layouts have their
  own). Cross-use requires an explicit transform.

## 7. Tanzil page scheme vs MushafDatabase page scheme  (`INFERENCE` + `UNKNOWN`)

- `quran_ayat.page_number` = Tanzil's `Page` boundary array (used for
  `memorization_units`, the ḥifẓ page unit).
- `mushaf_pages` / `mushaf_words.page` = MushafDatabase V1.01's page numbers.
- `INFERENCE`: both are "standard Madani 604" and align at the **page
  level** for the vast majority of pages (spot-checks pass).
- `UNKNOWN`: a full 6236-row cross-check has **not** been done. Before any
  feature that assumes "Tanzil page N ⇔ MushafDatabase page N have the same
  ayat", run that diff and record the result here.
- They will **not** align at line level (MushafDatabase has line data; Tanzil
  has none).

## 8. The "page ends on an ayah" invariant

`VERIFIED` for MushafDatabase V1.01: every page begins a new ayah and ends
on an ayah boundary → each ayah's words are entirely on one page (checked
incl. 2:282, 161 words). This is a property of the **Madani edition**, not
of the Quran. If we ever support IndoPak/other layouts, this invariant does
**not** carry over.

## 9. Centered vs justified lines

- `text` lines: justified edge-to-edge (curvilinear stretch in print).
- `surah-name`, `bismillah` lines: **centred**. QUL exposes this as
  `is_centered`; MushafDatabase implies it from `line_type`.
- Our renderer must not justify a centred line.

## 10. What to store when adding a new layout-derived feature

Always record, alongside the feature data:
- `source` (e.g. `MushafDatabase V1.01`),
- `viewBox` / coordinate system,
- `layout_version` (`kMushafLayoutVersion`),
- whether a value is `VERIFIED` from data or `INFERENCE`.
