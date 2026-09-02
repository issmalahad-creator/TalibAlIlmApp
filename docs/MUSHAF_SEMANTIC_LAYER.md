# Mushaf Semantic Layer — developer reference (`79-mushaf`)

**Status (2026-08-29):** implemented and unit-verified (411 tests, +17 for
this layer). **No cut-over yet** — the primary Quran reader still runs on the
Phase 71 own-engine renderer + hand-made polygon JSON. This layer ships
*alongside* it, reachable from the reading-view menu ("المصحف الدلالي —
تجريبي"), so it can be validated on a real device before anything is
replaced. See [§12](#12-cut-over-criteria-79-mushaf-cutover).

This document is the single reference for the layer: where the data comes
from, how it is extracted, its schema, its coordinate system, how hit-testing
works, its limits, and exactly how to regenerate the bundled artifact from
source. Another developer should be able to rebuild `mushaf_layout.json.gz`
byte-for-byte (raw JSON) from this document alone.

---

## 1. Design principle — no AI

The app's "intelligence" is **deterministic / mathematical**, never an
LLM/AI as the brain. Everything in this layer obeys that:

* every word carries a **fixed identity** `(surah, ayah, word_index)` taken
  verbatim from the source dataset — nothing is inferred or generated;
* selection, addressing and highlight are **pure geometry** against stored
  bounding boxes;
* validation is **counting + the canonical per-surah ayah list**, not a
  model's judgement;
* nothing here summarises, paraphrases, interprets, or claims to understand
  the text.

Downstream systems (Ayah Notebook, memorization, recitation tracking, the
future Mathematical Study Intelligence engine) consume this layer's stable
ids and geometry; they are **not** built into it.

---

## 2. Source dataset

| | |
|---|---|
| Name | **Mushaf Database — Ligature-Based SVG** |
| Version | **SVG V1.01** (`data-md-version="1.01"` on every `<svg>`) |
| Narration | Hafs ʿan ʿĀsim, 604-page Madani layout, 15 lines/page |
| Files | 604 SVG, one per page (`001.svg` … `604.svg`), ~380 MB total |
| Local path (build input, git-ignored) | `MushafDatabase-Ligature-Based-SVG-main_2/MushafDatabase-Ligature-Based-SVG-main/SVG V1.01/` |
| License | **"Legal Use and Open Permission (Sadaqa-e-Jaria)"** |

License text (verbatim, `LICENSE` in the dataset root):

> Permission is hereby granted to any person, without prior written
> approval, to use, copy, modify, publish, distribute, and create
> derivative works from this dataset, in whole or in part, for any lawful
> purpose, including personal, educational, research, nonprofit, and
> commercial use.
>
> Users must not knowingly alter the Quranic content in any way that
> misrepresents or compromises the integrity of the Holy Quran.
>
> This dataset is provided "as is", without warranty of any kind …

Commercial redistribution of derived data is explicitly permitted, which is
why the extracted artifact can be bundled in the APK. The raw 760 MB SVG
source (this set plus two earlier local copies) is in `.gitignore`; keep a
local copy to regenerate.

### What each SVG provides

```
<svg viewBox="0 0 382.68 547.09" data-md-version="1.01">
 └ g#md-page[data-page-number="001"]
    ├ g#md-page-outer                     decorative frame, page no, juz name, margin marks
    └ g#md-page-inner[data-rect="x,y,w,h"]   content rect
       └ g#md-line-NN[data-line-number="NN"][data-type]   15 of them
             data-type ∈ text | surah-name | bismillah | empty
          ├ g#md-word-NNN[...]            a word (see below)
          └ g#md-aya-mark-NNN[...]        a verse-end marker
```

Every **word** group:

| attribute | meaning | example |
|---|---|---|
| `data-surah` | 3-digit surah | `002` |
| `data-aya` | 3-digit ayah | `026` |
| `data-word-index-in-ayah` | 1-based position in the ayah | `2` |
| `data-line-number` | line it sits on (1–15) | `04` |
| `data-hafs` | Uthmani (print) form | `إِنَّ` |
| `data-imlaey` | simplified form | `إن` |
| `data-type` | `text` \| `juz-star` \| `sajda-mehrab` | `text` |

`juz-star` (۞ rubʿ el-hizb, 199 across the Mushaf) and `sajda-mehrab`
(۩ sajdat al-tilāwa, 15) are **indexed inside the ayah's word sequence** —
each occupies a real `data-word-index-in-ayah`. Dropping them would leave
`word_index` non-contiguous, so they are kept and tagged.

Every **aya-mark** group carries `data-surah` / `data-aya` /
`data-line-number` (no word text). One per ayah — 6236 total.

Below the word level the SVG also has `md-ligature-*` (letter paths,
`data-text`), `md-diacritic-*` (25 diacritic types, `data-dots`), and
path-level `data-waqf`. **None of that is extracted in v1** — see
[§11](#11-system-limits).

---

## 3. Layer architecture

```
        ┌─────────────────────────────────────────────┐
        │  Semantic Layer   (data — no Flutter)        │
        │  models/mushaf_layout.dart                   │
        │  mushaf_* tables (v51)                       │
        │  MushafLayoutSync  (seed + validate)         │
        │  MushafLayoutRepository  (pure reads)        │
        │  identity: (surah, ayah, word_index)        │
        │  location: (page, line, bbox)               │
        └───────────────┬─────────────────────────────┘
                        │  MushafPageLayout  (plain object)
        ┌───────────────▼─────────────────────────────┐
        │  Rendering Layer   (draw only)               │
        │  widgets/mushaf_page_view.dart               │
        │  viewBox→widget scale, word glyphs,          │
        │  one page-level hit-test, ayah highlight     │
        │  knows NOTHING about the DB or study systems │
        └───────────────┬─────────────────────────────┘
                        │  onWordTap / onAyahTap / onWordLongPress
        ┌───────────────▼─────────────────────────────┐
        │  Interaction / screen layer                  │
        │  screens/mushaf_semantic_reader_screen.dart  │
        │  turns callbacks into navigation / sheets    │
        └───────────────┬─────────────────────────────┘
                        │  (surah, ayah[, word range])
        ┌───────────────▼─────────────────────────────┐
        │  Independent consumers                       │
        │  Ayah Notebook · memorization · recitation   │
        │  tracking · Study Events · Math Study Engine  │
        └─────────────────────────────────────────────┘
```

**Rules that must hold:**

1. `models/mushaf_layout.dart` imports nothing from `dart:ui` / Flutter.
   The box is four `double`s (`MushafBox`), not a `Rect`.
2. The DB schema stores `(surah, ayah, word_index, hafs, imlaey, line,
   bbox)` column by column. It is **not** shaped by how a page is drawn —
   a different renderer (real print art, a canvas engine) is a drop-in
   replacement with no schema or repository change.
3. `MushafPageView` takes a `MushafPageLayout` and emits callbacks. It must
   never import a repository, a notebook screen, or any study/intelligence
   code. Wiring callbacks to features happens in the screen layer.
4. Consumers reference the layer by `(surah, ayah)` and, later, a word
   range `(word_start, word_end)` — never by screen coordinates.

---

## 4. The bundled artifact

| file | bytes | sha256 |
|---|---|---|
| `assets/mushaf/mushaf_layout.json.gz` (shipped) | 2 444 582 | `95ca3fdd6968393fb70be43cee40bf3538b1a366490b74b99316f872eb813293` |
| ↳ uncompressed JSON payload (**canonical**) | 10 492 606 | `6066f88dac87a70e8f2e09b6c0fa019c122d457fcdba01a48a4cae3f44e4f1e3` |
| `assets/mushaf/mushaf_manifest.json` | 16 926 | `45a3d5e0bd10cd6a59889799cc37ba6006234044473c3a407adbd32f8ad504ea` |

The **uncompressed-JSON sha256** is the integrity check to rely on: the
extractor emits deterministic JSON (stable page order, stable key order,
`separators=(",",":")`, `ensure_ascii=False`), so it reproduces
byte-for-byte on any machine. The `.gz` sha depends on the local zlib build
and is informational for this artifact only. `mushaf_manifest.json` embeds
`layout_sha256` = the canonical hash above.

### `mushaf_layout.json` format

```jsonc
{
  "version": 1,                       // kMushafLayoutVersion — bump on format change
  "source": "MushafDatabase-Ligature-Based-SVG V1.01 (Sadaqa-e-Jaria)",
  "viewBox": [0, 0, 382.68, 547.09],
  "page_count": 604,
  "pages": [
    {
      "page": 1,
      "rect": [x, y, w, h],           // md-page-inner content rect, or null
      "lines": [ {"n": 1, "type": "empty"}, … ],   // 1..15, in reading order
      "words": [
        {
          "s": 1, "a": 1, "w": 1,     // surah, ayah, word_index (1-based, verbatim)
          "ln": 7,                    // line number
          "o": 1,                     // word_order: 1..N reading order on this page
          "hafs": "بِسۡمِ",
          "iml": "بسم",
          "b": [215.33, 283.39, 30.3, 12.86],   // bbox [x,y,w,h] in viewBox units
          "t": "juz-star"             // omitted when "text"
        }, …
      ],
      "marks": [ {"s":1,"a":1,"ln":7,"b":[…]}, … ],       // one per ayah ending on this page
      "markers": [
        {"k":"surah-header","ln":6,"s":1},                // s = inferred surah it introduces
        {"k":"bismillah","ln":7},
        {"k":"sajda","b":[…]},
        {"k":"juz-hizb","b":[…]}
      ]
    }, …
  ]
}
```

### `mushaf_manifest.json` (validation aid, not loaded at runtime)

```jsonc
{
  "version": 1,
  "source": "…",
  "page_count": 604,
  "surah_count": 114,
  "total_words": 91451,
  "word_type_counts": { "text": 91237, "juz-star": 199, "sajda-mehrab": 15 },
  "total_aya_marks": 6236,
  "layout_sha256": "6066f88d…",       // of the uncompressed JSON
  "per_surah": { "1": { "ayah_count": 7, "max_ayah": 7, "word_count": 29,
                        "first_page": 1, "last_page": 1 }, … }
}
```

---

## 5. Extraction — how to regenerate

**Tool:** `tool/extract_mushaf_svg.py` (one-off, Python 3, not shipped).

**Dependencies:**

| package | version used | purpose |
|---|---|---|
| Python | 3.12.6 | — |
| `svg.path` | 7.0 (`pip install svg.path`) | parse `<path d>` into segments for bbox math |
| `xml.etree.ElementTree` | stdlib | SVG parsing |

**Run:**

```bash
cd f:/TalibAlIlmApp
python tool/extract_mushaf_svg.py \
  "MushafDatabase-Ligature-Based-SVG-main_2/MushafDatabase-Ligature-Based-SVG-main/SVG V1.01" \
  assets/mushaf
# ~3 min. Writes assets/mushaf/mushaf_layout.json.gz + mushaf_manifest.json
```

Both args are optional; the defaults are the paths above.

**What it does, per page:**

1. Read `md-page/@data-page-number`, `md-page-inner/@data-rect`.
2. Collect `md-line-NN` groups → `{n, type}`, sorted by `n`.
3. For every `md-word-NNN` whose `data-type ∈ {text, juz-star, sajda-mehrab}`,
   in document order (= RTL reading order), emit a record with the six
   metadata fields + `word_order` (running counter) + a computed bbox.
4. For every `md-aya-mark-NNN`, emit `{s, a, ln, bbox}`.
5. Markers: `md-non-quranic-margin-sajda` → `sajda`;
   `md-non-quranic-margin-juz-hisb`/`-juz-hizb` → `juz-hizb`; each
   `surah-name` line → `{k:"surah-header", ln, s}` where `s` is inferred as
   the surah of the first following word that starts an ayah 1 (else the
   first following word); each `bismillah` line → `{k:"bismillah", ln}`.
6. JSON-encode deterministically, gzip level 9, write; build the manifest
   (per-surah aggregation + sha256 of the raw JSON).

**Determinism:** page list sorted by number; within a page, everything is in
SVG document order; dict keys are emitted in fixed insertion order; floats
rounded to 2 dp. Same input SVGs → identical raw JSON → identical
`layout_sha256`.

---

## 6. Coordinate system & bounding boxes

* **Space:** the SVG `viewBox` `0 0 382.68 547.09`, identical on all 604
  pages. Constants `kMushafViewBoxWidth` / `kMushafViewBoxHeight` in
  `models/mushaf_layout.dart`. Origin top-left, x → right, y → down.
* **Box:** `MushafBox(x, y, w, h)` in viewBox units. `w > 0`, `h > 0`
  always (validated). Helpers: `right`, `bottom`, `centerX`, `centerY`,
  `contains`, `union`, `inflate`.
* **bbox computation (extractor):** for a word group, parse every
  descendant `<path d>` with `svg.path`; collect the absolute end-points
  **and Bezier control points** of every segment; the box is their
  min/max. Including control points makes the box *conservative* (never
  smaller than the visible glyph, occasionally a hair larger) — the right
  bias for tap targets and highlight coverage.
* **viewBox → widget scale (renderer):** `xMidYMid meet` — identical to the
  SVG's own `preserveAspectRatio`. `scale = min(W/vbW, H/vbH)`;
  `dx = (W - vbW·scale)/2`, `dy = (H - vbH·scale)/2` (letterbox). Never
  distorted.
* **widget point → viewBox point:** `((px - dx)/scale, (py - dy)/scale)`.

---

## 7. Database schema (migration v51)

All tables `CREATE TABLE IF NOT EXISTS`. Additive; touches nothing else.

```sql
mushaf_pages(
  page INTEGER PRIMARY KEY,               -- 1..604
  rect_x REAL, rect_y REAL, rect_w REAL, rect_h REAL,   -- md-page-inner rect (nullable)
  vb_w REAL NOT NULL, vb_h REAL NOT NULL, -- viewBox, stored for self-containment
  line_count INTEGER NOT NULL,            -- normally 15
  surah_first INTEGER NOT NULL, surah_last INTEGER NOT NULL,
  ayah_first INTEGER NOT NULL, ayah_last INTEGER NOT NULL,
  word_count INTEGER NOT NULL
)

mushaf_lines(
  page INTEGER NOT NULL, line INTEGER NOT NULL,         -- 1..15
  line_type TEXT NOT NULL,                              -- text|surah-name|bismillah|empty
  PRIMARY KEY (page, line)
)

mushaf_words(
  page INTEGER NOT NULL,
  line INTEGER NOT NULL,
  word_order INTEGER NOT NULL,            -- 1..N reading order on the page
  surah INTEGER NOT NULL,
  ayah INTEGER NOT NULL,
  word_index INTEGER NOT NULL,            -- 1-based in the ayah, verbatim from source
  word_type TEXT NOT NULL DEFAULT 'text', -- text|juz-star|sajda-mehrab
  text_uthmani TEXT NOT NULL,             -- data-hafs
  text_imlaey TEXT NOT NULL,              -- data-imlaey
  bbox_x REAL NOT NULL, bbox_y REAL NOT NULL, bbox_w REAL NOT NULL, bbox_h REAL NOT NULL,
  PRIMARY KEY (page, word_order)
)
CREATE INDEX idx_mushaf_words_ayah ON mushaf_words(surah, ayah);
CREATE INDEX idx_mushaf_words_page ON mushaf_words(page);

mushaf_aya_marks(
  surah INTEGER NOT NULL, ayah INTEGER NOT NULL,
  page INTEGER NOT NULL, line INTEGER NOT NULL,
  bbox_x REAL, bbox_y REAL, bbox_w REAL, bbox_h REAL, -- nullable
  PRIMARY KEY (surah, ayah)
)
CREATE INDEX idx_mushaf_aya_marks_page ON mushaf_aya_marks(page);

mushaf_markers(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  page INTEGER NOT NULL,
  kind TEXT NOT NULL,                     -- sajda|juz-hizb|surah-header|bismillah
  line INTEGER, surah INTEGER,            -- nullable, per kind
  bbox_x REAL, bbox_y REAL, bbox_w REAL, bbox_h REAL
)
CREATE INDEX idx_mushaf_markers_page ON mushaf_markers(page);

mushaf_meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)
-- keys: layout_version, source, seeded_at_ms, words, aya_marks
```

---

## 8. Seed & validation (`MushafLayoutSync`)

`sync()` runs once at startup (`main.dart`, next to the Turath catalog
sync). It seeds when `mushaf_pages` is empty **or** `mushaf_meta.layout_version`
differs from `kMushafLayoutVersion`. Bundled-only for v1 — no network. Every
failure is swallowed and reported via `MushafSyncResult`; the existing
reader is never affected.

**`validate(layout)` — pure, runs before any write. Fails (→ reject, no
write) on any of:**

* page count ≠ 604, or any page number in 1..604 missing;
* a page with 0 lines or > 15 lines;
* a page with 0 words;
* `word_order` not exactly `1..n` on some page;
* `word_index` not exactly `1..k` for some `(surah, ayah)`;
* distinct `(surah, ayah)` ≠ 6236;
* aya-mark count ≠ 6236, or the aya-mark `(surah,ayah)` set ≠ the word
  `(surah,ayah)` set;
* surah count ≠ 114, or any surah's `max(ayah)` ≠ the canonical count in
  `lib/data/quran_surahs.dart` (`quranSurahs`);
* any word box with `w ≤ 0`, `h ≤ 0`, or extending > 1 unit outside the
  viewBox.

**`_ingest` — after validation passes:** wipe the `mushaf_*` tables, batch-
insert everything in **one transaction**, then a **post-insert cross-check**
inside the same transaction: DB page rows = 604, word rows = validated
count, aya-mark rows = 6236, `COUNT(DISTINCT surah)` = 114. Any mismatch
throws → the transaction rolls back → the previous data is intact.

**`ingestFromJson(map)`** — `@visibleForTesting` seam that runs
validate + ingest against the real DB; used by the test suite.

Canonical ground truth = `quranSurahs` (114 rows, `number/name/ayahCount`,
Σ = 6236). No dependency on `quran_ayat` being populated, so it is safe at
first launch.

---

## 9. Repository API (`MushafLayoutRepository`, pure reads)

| method | returns |
|---|---|
| `isReady()` | `mushaf_pages` non-empty |
| `pageCount()` | seeded page count (604 when done) |
| `pageLayout(page)` | `MushafPageLayout?` — lines, words, aya-marks, markers for one page |
| `wordsForAyah(surah, ayah)` | `List<MushafWord>` in `word_index` order |
| `pageForAyah(surah, ayah)` | page number from the verse's aya-mark (fallback: its first word) |
| `pageForReference(surah, {ayah = 1})` | page to open a `(surah, ayah)` ref on; falls back to the surah's first page |
| `ayahBoxesOnPage(page, surah, ayah)` | `List<MushafBox>` — one union box per line the ayah occupies |
| `pageRangeForSurah(surah)` | `(first, last)` Mushaf pages |

`MushafPageLayout` also carries pure in-memory helpers: `wordAtPoint(x, y,
{pad})`, `ayahBoxes(surah, ayah)`, `ayat` (distinct `(surah,ayah)` in
reading order), `surahFirst` / `surahLast`.

---

## 10. Rendering layer contract (`MushafPageView`)

```dart
MushafPageView({
  required MushafPageLayout layout,
  ({int surah, int ayah})? selectedAyah,      // draws per-line highlight
  void Function(MushafWord)? onWordTap,
  void Function(int surah, int ayah)? onAyahTap,   // fires alongside onWordTap
  void Function(MushafWord)? onWordLongPress,
  String fontFamily = 'DigitalKhattMadina',
  Color highlightColor, Color textColor,
  bool debugBoxes = false,                     // outline every word box
})
```

* `LayoutBuilder` → `xMidYMid meet` scale → a `Stack` of `Positioned`
  word glyphs (`FittedBox` + `Text`, RTL) over a `CustomPaint` highlight.
* **One** page-level `GestureDetector` (`onTapUp`, `onLongPressStart`);
  word `Positioned`s are `IgnorePointer`. This is deliberate — 150
  per-word gesture detectors did not respond reliably to synthetic taps on
  the old own-engine pages; one page-level hit-test does.
* Imports: `flutter/material.dart` and `models/mushaf_layout.dart` only.

---

## 11. Hit-testing & the addressing chain

```
widget-local point
      │  ((px-dx)/scale, (py-dy)/scale)
viewBox point
      │  MushafPageLayout.wordAtPoint  — scans words in reading order,
      │  each box inflated by pad (default 1.5 u); nearest centre wins
MushafWord ── word_index, text_uthmani, text_imlaey, word_type
      │
      ├─ ayah   = (word.surah, word.ayah)
      ├─ line   = word.line
      ├─ page   = word.page
      └─ surah  = word.surah
```

**Word-range selection (foundation for the future).** Because every word on
a page has a stable `word_order` (page) and `word_index` (ayah), a drag or
multi-tap that yields a set of words converts to a range **without any
screen coordinate**:

```
words hit → filter to one (surah, ayah)
          → word_start = min(word_index), word_end = max(word_index)
```

`ayah_study_entries` already reserves `word_start` / `word_end` for exactly
this. The selection *gesture* and the `MushafWordRange` helper are **not
built yet** — they are the first task after device validation, not part of
this phase.

---

## 12. Canonical numbers

| quantity | value | check |
|---|---|---|
| pages | 604 | numbered 1..604, no gap |
| lines | 9060 | 15 × 604 |
| indexed tokens (`mushaf_words`) | **91 451** | `text` 91 237 + `juz-star` 199 + `sajda-mehrab` 15 |
| distinct ayat | **6 236** | = Σ `quranSurahs.ayahCount` |
| aya-marks | 6 236 | 1 : 1 with ayat |
| surahs | 114 | every `max(ayah)` == canonical count |
| orphan words | 0 | every `(surah,ayah)` is canonical |
| ayat with broken `word_index` | 0 | contiguous `1..k` |
| pages with broken `word_order` | 0 | contiguous `1..n` |
| word boxes outside viewBox / degenerate | 0 | |
| artifact | 2.44 MB gz / 10.2 MB JSON | |

Ayat span **one page each** — a defining property of the 15-line Madani
Mushaf (every page begins and ends on an ayah boundary), so
`wordsForAyah` returns words from a single page even for 2:282 (161 words,
several lines, page 48).

---

## 13. System limits

* **Visual fidelity is v1.** Words are rendered with the bundled
  `DigitalKhattMadina` font at the dataset's box positions — *not* the
  printed Madinah page art. A real-art rendering layer is a separate later
  step; it needs no change to the semantic layer.
* **Diacritic / tajweed data not extracted.** `md-diacritic-*` (25 types)
  and path-level `data-waqf` exist in the source but are dropped. Adding a
  diacritic/waqf layer = a new optional table + an extractor pass; the word
  identity model does not change.
* **Juz / hizb numbers not in the SVG.** Only ornament *positions* are
  captured (`mushaf_markers.kind = 'juz-hizb'`, `'sajda'`). The actual juz
  number for a page comes from `quran_ayat.juz_number` (not joined here).
* **`surah-header` marker surah is inferred**, not read from the SVG (the
  header line carries only decorative paths). Inference = the surah of the
  first following ayah-1 word; correct for standard layout, unverified for
  the handful of pages with two surah headers.
* **bbox is conservative**, slightly larger than the ink for glyphs with
  far-reaching Bezier control points. Fine for tap/highlight; not a
  pixel-exact glyph outline.
* **No network refresh.** The artifact is bundled-only. A hosted-refresh
  path (like `TurathCatalogSync`) is possible later but out of scope.
* **Word segmentation is the Mushaf's, not a lexical one.** Standalone
  waqf marks, ۞ and ۩ count as indexed tokens, so "91 451" is *tokens on
  the page*, not a linguistic word count (~77 430).

---

## 14. Device validation checklist

Run against the current debug APK (`build/app/outputs/flutter-apk/`), Quran
reader → menu "طريقة عرض المصحف" → "المصحف الدلالي (تجريبي)".
**Record problems here; do not fix ad-hoc** — the fixes are decided
together after this pass.

| # | check | result | note |
|---|---|---|---|
| 1 | all 604 pages open, no blank/stuck page | | |
| 2 | RTL paging: swipe left → next page, right → previous | | |
| 3 | pinch zoom (if the container supports it) | | |
| 4 | tap a word at the **start** of a line → correct word/ayah/surah | | |
| 5 | tap a word in the **middle** of a line | | |
| 6 | tap a word at the **end** of a line | | |
| 7 | tap two **adjacent** words → each resolves distinctly | | |
| 8 | tap a word in an ayah that **spans several lines** | | |
| 9 | **first** and **last** ayah on a page | | |
| 10 | **first** surah (al-Fātiḥa, p.1) and **last** surah (an-Nās, p.604) | | |
| 11 | a page with a ۞ mark → tapping it is sane | | |
| 12 | a page with a ۩ sajda mark | | |
| 13 | a long ayah — **2:282** (p.48): every line highlights, notebook opens | | |
| 14 | open the ayah notebook **from a word** → correct `(surah, ayah)` | | |
| 15 | **long-press** a word → ayah notebook opens directly | | |
| 16 | back from the notebook → returns to the **same page/position** | | |
| 17 | old reader still works, unchanged | | |

Findings log (fill after testing):

```
- (page N) …
```

---

## 15. Cut-over criteria — `79-mushaf-cutover` (NOT now)

Only after §14 passes on a real device across at least a full juz:

1. point the primary Quran reader's page render + ayah menu at
   `MushafLayoutRepository` / `MushafPageView` on **all** pages;
2. keep the own-engine renderer reachable behind a setting for one release;
3. remove the polygon-JSON loader and its `assets/quran/mushaf_borders/*.json`
   once the new path is confirmed for every page 1–2 case it covered;
4. then (separate steps, each its own decision): word-range selection
   gesture, diacritic/tajweed layer, real print-art rendering, and feeding
   word/ayah interaction events into Study Events for the Mathematical
   Study Intelligence engine.

Nothing in step 4 starts automatically.
