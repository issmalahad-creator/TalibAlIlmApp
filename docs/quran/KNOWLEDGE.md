# Quran Engineering — Applicable Knowledge Base

The working reference. For each kind of Quran feature: **the correct model,
the source of truth, the right identity, and what must not be guessed.**

Read `SOURCES.md` for the tag legend (`VERIFIED` / `SOURCE-BACKED` /
`PROJECT-SPECIFIC` / `INFERENCE` / `UNKNOWN`). Sibling files:
`QURAN_DATA_MODEL.md`, `MUSHAF_ENGINEERING.md`, `QURAN_LAYOUT.md`,
`QURAN_INTERACTION.md`, `QURAN_TERMINOLOGY.md`, `ERRATA.md`.

**Hard rule for the whole domain:** never use `INFERENCE` or `UNKNOWN`
knowledge as a basis for changing Quran **text** or mushaf **data**. Those
change only from `VERIFIED` / authoritative-source data.

---

## R‑1 · Show the Quran text of an ayah

- **Model:** ayah = `(surah, ayah)`; text = a stored field.
- **Source of truth:** `quran_ayat.text_uthmani` (Tanzil Uthmani v1.1,
  CC‑BY 3.0, **unmodified**). `VERIFIED`.
- **Identity:** `(surah, ayah)` ints.
- **Do NOT:** modify, re-spell, normalize, or reconstruct the text from
  glyphs/geometry. Do not display `text_normalized`. Attribute Tanzil.
- **When I generate/quote Quran text myself while coding:** use the
  `quran.ai` MCP (`fetch_quran`), never memory. Call `fetch_grounding_rules`
  first.

## R‑2 · Search for an ayah by typed Arabic

- **Model:** normalize query and corpus with the **same** function, substring match.
- **Source of truth:** `quran_ayat.text_normalized` (built by
  `normalizeArabicForSearch`, `lib/utils/arabic_normalize.dart`). `VERIFIED`.
- **Algorithm:** `normalizeArabicForSearch(query)` → `LIKE '%…%'` on
  `text_normalized` (see `QuranSearchRepository`).
- **Do NOT:** invent a second normalizer; display normalized text; assume
  the Turath anchor normalizer (`kNormVersion`) is the same thing — it isn't.
- **Known casework (`VERIFIED`):** dagger-alif restoration (الظالمين),
  U+0653 maddah strip (الفقراء), alef/hamza/tā-marbūṭa/alif-maqṣūra folding.

## R‑3 · Identify a word tapped on a mushaf page

- **Model:** point → viewBox point → `wordAtPoint` → `MushafWord`.
- **Correct identity:** `(surah, ayah, word_index)` (semantic).
- **Geometry:** `(page, line, bbox)` in viewBox `0 0 382.68 547.09`.
- **Source:** `mushaf_words` (MushafDatabase V1.01, `tool/extract_mushaf_svg.py`). `VERIFIED`.
- **Algorithm:** inverse `xMidYMid meet` transform + bbox hit-test
  (`QURAN_INTERACTION.md` §1–2).
- **Do NOT:** rely on screen coordinates after resolution; use per-word
  `GestureDetector`s (`ERRATA` E‑3); assume the tapped word's identity from
  page position when the data has it (`ERRATA` E‑2).

## R‑4 · Select a range of words (for a note / word-level anchor)

- **Model:** hit a set of words → filter to one `(surah, ayah)` →
  `word_start = min(word_index)`, `word_end = max(word_index)`.
- **Source:** `mushaf_words.word_index`. Storage: `ayah_study_entries.word_start/word_end` (already reserved). `PROJECT-SPECIFIC`.
- **Do NOT:** store screen coordinates; span two ayat in one range (split
  per ayah); build a text-offset anchor for Quran content — the numeric
  identity never drifts.
- **Status:** `INFERENCE` design; the selection gesture is **not built**.

## R‑5 · Highlight an ayah (or word range) on a mushaf page

- **Model:** geometric — one union bbox **per line** the span occupies.
- **Source:** `MushafPageLayout.ayahBoxes` / `MushafLayoutRepository.ayahBoxesOnPage`. `VERIFIED`.
- **Do NOT:** use `TextSpan.backgroundColor` (that's the Turath *text*
  reader — a different surface); draw one giant block over a multi-line ayah;
  merge adjacent ayat.

## R‑6 · Render the mushaf page visually (print fidelity)

- **Valid strategies (`SOURCE-BACKED`):** (A) per-page QCF ligature font
  [we lack the font], or (B) render the **real MushafDatabase SVG page**,
  overlay invisible bboxes for interaction. **B is our path.**
- **Do NOT:** lay `text_uthmani`/`data-hafs` in a substitute font at the
  glyph bboxes (`ERRATA` E‑1 — produced garbled overlapping text). Do NOT
  rely on runtime kashida/justification with a generic font (HarfBuzz
  doesn't insert kashida; documented as unreliable for vocalised Quran).
- **Size:** compress the 604 SVGs losslessly (xz ≈46 MB / gzip ≈76 MB) and
  bundle, **or** download-per-page + cache. Decision pending (`UNKNOWN`).

## R‑7 · Open the mushaf at a `(surah, ayah)` reference

- **Source of truth:** `MushafLayoutRepository.pageForAyah` /
  `pageForReference` (from `mushaf_aya_marks.page`). `VERIFIED`.
- **Note:** this is the **MushafDatabase** page number. `quran_ayat.page_number`
  (Tanzil scheme) is used for **ḥifẓ units** and may differ at line level;
  page-level they align for standard Madani (`INFERENCE`, full diff `UNKNOWN`).

## R‑8 · Memorization (ḥifẓ) unit & scheduling

- **Model (`PROJECT-SPECIFIC`, roadmap-decided):** the **scheduling/review
  unit is the page** (604 units), not the ayah. Ayah stays the unit of
  *display / understanding / difficulty marking*.
- **Source:** `memorization_units` (604 rows, generated from
  `quran_ayat.page_number` first/last ayah per page, in
  `QuranImportService`). `VERIFIED`.
- **Do NOT:** create 6236 per-ayah SRS cards; assume page boundaries align
  to surah or juz boundaries (they don't).

## R‑9 · Ayah Study Notebook — link notes to a verse / word

- **Anchor:** `(surah, ayah)` ints, optional `word_start/word_end`.
  **No re-anchoring engine** (integers don't drift). `VERIFIED` design,
  built (79‑sa‑D‑ayah).
- **Source of truth for identity:** the data, never a page tap's pixels.
- **Do NOT:** anchor Quran notes by text offset (that's Turath's problem,
  not Quran's).

## R‑10 · Juz / Hizb / Rub / Ruku / Manzil / Sajda numbers

- **Source of truth:** `quran_ayat` (`juz_number`, `hizb_number`) +
  Tanzil `quran-data.js` (HizbQuarter, Sajda, per-surah ruku counts) +
  `quran.ai` metadata for cross-check. `VERIFIED` / `SOURCE-BACKED`.
- **Do NOT:** read these **numbers** from the MushafDatabase SVG — it has
  only the ornament **positions** (`mushaf_markers`), no numbers.
- **Counts (`SOURCE-BACKED`):** 30 / 60 / 240 / ~540–558 / 7 / 15 (sajda).

## R‑11 · Verse-end markers (medallions)

- **Model:** first-class element, `(surah, ayah)` identity, own geometry
  (`mushaf_aya_marks`), 1:1 with ayat (6236). Number rendered as Eastern-
  Arabic digits, graphic only.
- **Do NOT:** treat the medallion as "the last word"; concatenate the number
  into ayah text; let a tap on it resolve as a word.

## R‑12 · Waqf (pause) marks

- **Model:** glyph **position** ≠ glyph **meaning**. Meaning depends on the
  mushaf's waqf tradition.
- **Danger (`VERIFIED`):** **لا** = "do not stop" (Madani) but "must stop"
  (IndoPak/Sajāwandī).
- **Source:** MushafDatabase `data-waqf` (positions) + a **rules table** for
  meaning (not built). Do NOT explain a waqf glyph without the tradition.

## R‑13 · Tashkīl / diacritics (per-character)

- **Model:** base letter + combining marks; MushafDatabase names 25
  diacritic types under `md-diacritic-*` and `data-dots ∈ dot|two dots|three
  dots`.
- **Not in `mushaf_layout.json.gz`** — that extraction dropped sub-word
  paths. A per-diacritic layer needs a new extraction pass. `UNKNOWN` scope.
- **Do NOT:** derive tashkīl by parsing glyph shapes; the marks are named in
  the source, use those names.

## R‑14 · Tajwīd colour coding

- **Model:** rule spans + a rule→colour map chosen in-app. **Identity:**
  `(surah, ayah, word_index)` + a `[cs, ce)` char range in that word's own
  Uthmani text. Colour is by **family** (six), never the 18 rule ids.
- **Source:** cpfair/quran-tajweed (18 rules, **CC BY 4.0**), pinned commit
  `496f71c`; offsets into the 2017 Tanzil `quran-uthmani.txt` (Basmala
  prepended to ayah 1 of every surah bar 1 & 9). See SOURCES §9.
- **Do NOT:** assume spans transfer to another text without re-running
  `tool/build_tajweed_rules.py` + re-checking the report; hard-code one
  publisher's colours; treat the two same/close-makhraj idghām rules or
  hamzat al-waṣl / lām shamsiyyah / silent as having a curriculum lesson.
- **Status (Phase G-t, 2026-09-05): fully built.**
  - **G-t1** — `quran_tajweed` (DB v56) from `tajweed.json.gz`,
    **6236/6236 ayāt, 0 flagged, 70 085 spans**; `CorpusTajweedProvider`
    feeds the ayah/word knowledge surface (grouped by family, tap → tier
    lesson). `tajweed_rules_ref.dart` + `tajweed_palette.dart` = the
    family/colour/lesson map.
  - **G-t2** — `mushaf_glyphs` (DB v57, `kMushafLayoutVersion` 3) from
    `mushaf_glyphs.json.gz` (per ligature + diacritic box, 486k, 604/604 QA).
  - **G-t3 → v2 (glyph-level)** — `lib/services/mushaf/tajweed_svg.dart`.
    Colour on the **exact glyph `<path>`** (diacritic + single-letter
    ligature, ≈ 82 %) or a `clipPath` **band** inside a multi-letter
    ligature (≈ 18 %, a region not the whole word); ≈ 3 % unplaceable stay
    black + on tap. Six-**category** Quran palette (`tajweed_palette.dart`).
    No overlay, no rectangle — `TajweedPageOverlay` deleted. Opt-in «وضع
    التجويد» (`mushaf_tajweed_mode`); `تجويد ▾` pill → legend sheet.
    Coverage report: `docs/quran/reports/TAJWEED_GLYPH_COVERAGE.md`. Full
    audit: `docs/quran/TAJWEED_RENDERING_ANALYSIS.md`.
  - **Data limit:** MushafDatabase ligates whole words → true per-letter
    geometry needs a different art source / an in-app shaping renderer (v3).

## R‑15 · Qirāʾāt / riwāyāt

- **Model (`PROJECT-SPECIFIC`):** the app is **Hafs ʿan ʿĀṣim, Kufi count,
  6236 ayat** everywhere. Another riwāya = a **separate dataset**
  (different text, different verse count: Warsh/Qālūn 6214, Douri 6218),
  not a toggle on the existing data.
- **Do NOT:** mix an ayah number or text from one riwāya with metadata from
  another.

## R‑16 · Recitation follow / word timing

- **Model:** per-word `start/end ms`, **per reciter**, tokenised by
  **Tanzil space-split**.
- **Source (reference):** quran-align, QUL segments.
- **Required artifact:** a mapping `Tanzil token index` →
  `mushaf_words.word_index` (segmentations differ). Build & store it.
- **Do NOT:** assume `tokenIndex == word_index`; treat timing as global.
- **Status:** not built.

## R‑17 · Future: mathematical tracking of ḥifẓ / recitation

- **Model:** see `docs/STUDY_INTELLIGENCE_ENGINE_SPEC.md` — deterministic,
  every number expands to Formula + Data source + Time window + reason.
- **Quran inputs (`PROJECT-SPECIFIC` when built):** `StudyEvent`s keyed by
  `(surah, ayah)` or page; `mushaf_words`/`mushaf_aya_marks` give the
  geometry to *visualise* strength per surah/juz/page.
- **Do NOT:** feed AI-generated "understanding"/"scores"; use `INFERENCE`
  numbers as if measured.

---

## Cross-cutting facts worth keeping (`SOURCE-BACKED` unless noted)

1. Mushaf al-Madinah: 604p / 15 lines / Hafs / Uthman Taha / KFGQPC; every
   page ends on an ayah boundary (`VERIFIED` for MushafDatabase V1.01).
2. Three KFGQPC calligraphy editions (1405/1422/1439H); QCF layout V1/V2/V4
   → "the Madani mushaf" is an edition *family*, not one pixel layout.
3. Six ayah-counting schools; Kufi 6236 is the printed standard; differences
   are verse-boundary placement only.
4. No canonical word/letter count (~77,430 / ~320k, method-dependent).
5. Rasm is fixed; dabt may differ; imlāʾī ≠ normalized ≠ visual glyph.
6. Standard Arabic search normalization: strip tashkīl + tatweel + Quranic
   marks (U+06D6–U+06ED), fold alef variants → ا, ؤئ → ء, ة → ه, ى → ي, NFC.
7. QUL layout schema (`pages`: page/line/line_type/is_centered/first_word_id/
   last_word_id; `words`: word_index/word_key/surah/ayah/position/text) — the
   model our `mushaf_*` mirrors.
8. Verse-end medallion is a first-class element (`char_type "end"`), not text.
9. Two valid print-render strategies: per-page QCF font, or ligature SVG.
   Generic font + runtime kashida is not one.
10. `لا` waqf glyph means opposite things in Madani vs IndoPak.
11. 15 sajda verses (14 agreed); wājib Ḥanafī / sunna others; Shāfiʿī swaps
    38:24 for 22:77.
12. MushafDatabase viewBox `382.68×547.09`; quranpedia `345×550` — never mix
    coordinates across editions.
13. External datasets (timing, tajweed) are bound to a specific text file /
    segmentation — map, don't assume.
14. `svg2/` (quranpedia) has **no Quran text glyphs** — polygon overlay only
    (`VERIFIED` 2026‑08‑29).
15. Three independent version counters: `kNormVersion` (Turath anchor
    normalizer), `kMushafLayoutVersion` (layout asset), and the un-versioned
    `normalizeArabicForSearch`. Don't conflate.
