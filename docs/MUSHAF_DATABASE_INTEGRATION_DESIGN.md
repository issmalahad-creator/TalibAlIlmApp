# MushafDatabase integration — plan (Quran rendering, all 604 pages)

---
**STATUS 2026-08-29: `79-mushaf` IMPLEMENTED (semantic + rendering layers,
option 1).** Built exactly as recommended below: build-time structural
extraction (`tool/extract_mushaf_svg.py` → `assets/mushaf/mushaf_layout.json.gz`,
2.4 MB gz), migration v51 (`mushaf_pages` / `mushaf_lines` / `mushaf_words` /
`mushaf_aya_marks` / `mushaf_markers` / `mushaf_meta`), `MushafLayoutSync`
(seed + full internal validation + post-insert cross-check + reject-on-bad),
`MushafLayoutRepository` (pure reads), `MushafPageView` (rendering layer,
DB-free, one page-level hit-test), and `MushafSemanticReaderScreen` wired
into the reading-view menu **alongside** the existing reader. 17 new tests
(604-page integrity + widget). The **semantic layer and rendering layer are
separate** — the schema stores `(surah, ayah, word_index, hafs, imlaey,
line, bbox)` and knows nothing about how a page is drawn.

**NOT done (deliberately, awaiting device verification by Ismail):** the
cut-over — pointing the main reader at this layer and deleting the polygon
JSON. That is a future `79-mushaf-cutover` step, only after the layer is
proven on a real device across a full juz. Nothing else auto-starts.
Sections below are the original plan, kept for reference.

---

**Status: PLAN ONLY. No code.** Ismail 2026-08-29: the current own-engine
Mushaf reader only supports ayah long-press on **pages 1–2** (the ones with
hand-made polygon JSON); he wants **word / ayah / surah control on every
page**, driven deterministically (no AI), using the **MushafDatabase
Ligature-Based SVG** dataset (folder `MushafDatabase-Ligature-Based-SVG-main_2`,
`SVG V1.01`) to **replace** the existing renderer + the polygon JSON files.
This is priority 2 in `STUDY_INTELLIGENCE_VISION.md`. Build it after the
work currently in hand (`79-sa-E`).

## 1. What the dataset gives (verified)

604 SVG files, one per Mushaf page, license "Sadaqa-e-Jaria" (fully open,
incl. commercial). Per page: `g#md-page[data-page-number]` →
`md-page-outer` (surah header, page number, juz name, margin
juz/hizb/sajda/sakta) + `md-page-inner[data-rect="x,y,w,h"]` → 15
`md-line-NN[data-line-number][data-type=text|surah-name|bismillah|empty]`.

**Every word** is `g#md-word-NNN` with `data-surah` (3-digit), `data-aya`
(3-digit), `data-line-number`, `data-hafs` (Uthmani), `data-imlaey`
(simplified), `data-word-index-in-ayah` (1-based). Below: `md-ligature-*`
(letter paths, `data-text`), `md-diacritic-*` (25 diacritic types +
`data-dots`), `md-aya-mark-*` (verse markers, distinct from words),
path-level `data-waqf`. Canonical `viewBox="0 0 382.68 547.09"`.

This is a **data layer**, not just art — it removes the need for the
polygon JSON entirely (closes the `TODO.md` "JSON polygon files no longer
needed" item).

## 2. The size problem & bundling strategy

`SVG V1.01` is ~380 MB (files 200–720 KB). Cannot bundle raw.

**Decision needed** — options, in order of preference:
1. **Build-time extraction to a compact per-page data model** — a Dart/CI
   script parses each SVG once into `assets/mushaf/pages/NNN.json.gz`
   containing only: page rect, lines (`[{n,type}]`), words
   (`[{id,surah,aya,line,wordIndex,hafs,imlaey,bbox:[x,y,w,h]}]`), aya-marks
   (`[{surah,aya,line,bbox}]`), sajda/juz-hizb markers. **The glyph paths
   are dropped** — the app renders text with the existing Uthmani/Amiri
   font at the given bbox positions, OR keeps a low-detail path set only
   where the font differs from print. Estimated < 5 MB gzipped for all 604
   pages of structural data. This gives full addressing without the art
   weight.
2. **Bundle the SVGs but heavily minified** (strip precision to 1 dp, drop
   `md-*` id strings after parsing offsets, gzip) + lazy-load per page.
   Still likely 60–120 MB — probably too big for the APK; would need a
   post-install download.
3. **On-demand download** of `NNN.svg` from a hosted mirror (the dataset is
   openly licensed) into app storage, first-visit per page, cached. Reuses
   the exact pattern from `PDF_DOWNLOAD_DESIGN.md` (Range-resume, integrity).

Recommendation: **option 1** — a structural data model is what the app
actually needs (addressing + layout), and it's tiny. The *visual* can stay
the current own-engine text render (or a later real-art layer) with the
MushafDatabase bboxes as the hit-test + highlight geometry.

## 3. Data model (local)

```
mushaf_pages(page INTEGER PK, rect_json, line_count, surah_start, surah_end)
mushaf_words(
  page INTEGER, line INTEGER, word_order INTEGER,   -- position on page
  surah INTEGER, ayah INTEGER, word_index INTEGER,  -- 1-based in ayah
  hafs TEXT, imlaey TEXT,
  x REAL, y REAL, w REAL, h REAL,                    -- bbox in the 382.68×547.09 viewBox
  PRIMARY KEY (page, line, word_order)
)
mushaf_aya_marks(page, line, surah, ayah, x, y, w, h)
mushaf_markers(page, kind TEXT /*sajda|juz|hizb|sakta*/, x, y, w, h, label TEXT)
```
Seeded once from the bundled `assets/mushaf/pages/*.json.gz` (migration
~v51). Indexed on `(surah, ayah)` and `(page)`.

## 4. Rendering & interaction

- **Layout**: place each word at its bbox (scaled from the viewBox to the
  widget size, `xMidYMid meet`). Lines and justification come straight from
  the bboxes — no re-flow guesswork.
- **Tap targeting**: a `GestureDetector` per word (or one page-level
  hit-test against `mushaf_words` bboxes). A tap → the existing ayah menu
  (`_onAyahTap`) **on every page**, plus a new word-level long-press for
  word actions (add ayah-notebook entry anchored to `word_index`).
- **Highlighting**: ayah highlight = union of that ayah's word bboxes on
  the page; word cursor for recitation-follow = one word's bbox. Reuses
  the `AnnotatedPageText`-style tinting idea but geometric, not text-range.
- **Diacritic layer** (later): `data-diacritic` groups allow tajweed
  colouring without touching the letter body.

## 5. Integration points (what this unblocks)

- **Ayah notebook** (`79-sa-D-ayah`): the reserved `word_start`/`word_end`
  columns become usable — anchor an entry to "الكلمات 12–17 من آية الكرسي".
  "📓 دفتري لهذه الآية (N)" reachable from any page.
- **Recitation** (`recitation_mistakes` has surah/ayah): map a mistake to a
  word bbox → a real **word-level weak-spot map** on the page.
- **Hifz / review**: KnowledgeStrength per surah/juz/page (Study
  Intelligence spec §9) gets real geometry to visualise.
- **Study Intelligence** `knowledge_edges`: `word on_page`, `ayah in_page`
  edges become exact.

## 6. Migration / phasing

1. **Extraction script** (`tool/extract_mushaf_svg.dart` or CI) → 604
   `assets/mushaf/pages/NNN.json.gz` + a checked-in manifest with counts to
   validate (total words per surah must match the Quran text; ayah count
   per page must match). Verify against `quran_ayat`.
2. Migration v51 + seed service (bundled asset → `mushaf_*` tables),
   validated like `TurathCatalogSync` (word totals, no orphan ayat, every
   `(surah,ayah)` in `quran_ayat` present).
3. `MushafLayoutRepository` (pure reads: `pageLayout(page)`, `wordsForAyah`,
   `bboxForAyah(page, surah, ayah)`).
4. New `MushafPageView` widget (geometry render + per-word hit-test) behind
   a feature flag; wire the ayah menu to it on **all** pages.
5. Replace the polygon-JSON path in `quran_reading_screen`; delete the
   `.json` polygon assets and their loader.
6. Word-level actions (ayah-notebook word anchor, recitation word map).

## 7. Risks

| # | risk | mitigation |
|---|---|---|
| R1 | 380 MB dataset | option 1 — structural extraction, drop glyph paths (~<5 MB gz) |
| R2 | extraction correctness (missing/dup words) | manifest validation vs `quran_ayat`: total words/ayat per surah + per page must match |
| R3 | visual fidelity vs the printed Madinah page | v1 keeps the current text render with MushafDatabase geometry for hit-test/highlight only; a real-art layer is a separate later step |
| R4 | `data-hafs` font-version drift | store both `hafs` + `imlaey`; render with the app's bundled Uthmani font; treat `hafs` as the print form of record |
| R5 | word bbox vs rendered glyph mismatch on some devices | scale-invariant layout from the viewBox; test on Ismail's device before replacing the old path |
| R6 | dropping polygon JSON breaks pages 1–2 during transition | keep both paths until `MushafPageView` is verified on ≥ a full juz on a real device |
