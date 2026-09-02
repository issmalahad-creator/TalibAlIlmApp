# Quran Interaction — hit-testing, coordinate transforms, selection, anchoring

Tags: see `SOURCES.md`. How a user touch on a mushaf page becomes a
`(surah, ayah[, word range])` — deterministically, no AI, no screen-coord
guessing.

---

## 1. The addressing chain  (`VERIFIED` — implemented in `mushaf_layout.dart` / `mushaf_page_view.dart`)

```
widget-local point  (dx, dy in logical px)
   │  inverse of the render transform (§2)
viewBox point  (x, y in 0..382.68 × 0..547.09)
   │  MushafPageLayout.wordAtPoint(x, y, pad)  — scan words in reading order,
   │  each bbox inflated by pad; nearest centre wins
MushafWord
   ├─ ayah   = (word.surah, word.ayah)      ← semantic identity
   ├─ line   = word.line
   ├─ page   = word.page
   ├─ surah  = word.surah
   └─ word_index (1-based in ayah)          ← for word-range anchoring
```

**Rule (`ERRATA` E‑2):** the output identity is `(surah, ayah, word_index)`
from the data. The pixel position is only the *query*. Never store or reason
from screen coordinates once the word is resolved.

---

## 2. Coordinate transform  (`VERIFIED`)

Source viewBox `0 0 382.68 547.09`, rendered with `xMidYMid meet`
(letterbox, never distort — identical to the SVG's own
`preserveAspectRatio`).

```
scale = min(W / vbW, H / vbH)
drawW = vbW * scale ;  drawH = vbH * scale
dx = (W - drawW) / 2 ;  dy = (H - drawH) / 2

widget → viewBox :  ( (px - dx) / scale , (py - dy) / scale )
viewBox → widget :  ( dx + x * scale     , dy + y * scale     )
```

Constants: `kMushafViewBoxWidth = 382.68`, `kMushafViewBoxHeight = 547.09`
in `lib/models/mushaf_layout.dart`.

**Rule:** one page-level `GestureDetector` + this transform + `wordAtPoint`.
**Not** 150 per-word `GestureDetector`s — `ERRATA` E‑3 (they don't fire
reliably for synthetic taps and cost layout).

---

## 3. Word-range selection → `(word_start, word_end)`  (`INFERENCE` — design, not yet built)

Because every word has a stable `word_index` within its ayah, a drag / two
taps that yield a **set of words** convert to a range with **no screen
coordinate stored**:

```
words hit  →  filter to a single (surah, ayah)
           →  word_start = min(word_index)
              word_end   = max(word_index)
```

- `ayah_study_entries` already reserves `word_start` / `word_end` columns
  for exactly this (`PROJECT-SPECIFIC`).
- Cross-ayah selection is a future concern — for now a range is within one
  ayah. If a drag spans two ayat, split into per-ayah ranges.
- The selection *gesture* + a `MushafWordRange` value type are **not built**.
  When built: pure geometry (rects from bboxes), no `SelectableText`.

---

## 4. Highlight geometry  (`VERIFIED` — `MushafPageLayout.ayahBoxes`)

An ayah's highlight = **one union box per line it occupies** (not one big
block, not per-glyph). Built from the ayah's word bboxes grouped by `line`.
This covers a multi-line ayah correctly and keeps adjacent ayat visually
distinct.

For the **text-based** Turath reader (a different surface), highlight is a
character-range problem, not geometry — see
`docs/STUDY_ANNOTATIONS_DESIGN.md` and `ERRATA` E‑4/E‑5. **Do not** reuse the
Turath `SelectableText`/`TextSpan.backgroundColor` approach for the mushaf;
the mushaf is geometric.

---

## 5. Anchoring interactions to the notebook  (`VERIFIED` design)

| surface | anchor | drift risk | re-anchor engine |
|---|---|---|---|
| Ayah Notebook (Quran) | `(surah, ayah)` ints, optional `word_start/word_end` | **none** (integers) | **not needed** |
| Turath reader | char offsets + verbatim `selected_text` + head/tail/context | page text can drift | `resolveAnchor` chain (`study_annotation_anchor.dart`) |

**Rule:** for anything Quran, the anchor is numeric `(surah, ayah[, word
range])`. Never build a text-offset anchor for Quran content — the identity
already exists and never drifts.

---

## 6. Opening the right page for a `(surah, ayah)` reference  (`VERIFIED` — `MushafLayoutRepository`)

- `pageForAyah(surah, ayah)` → from the verse's `mushaf_aya_marks.page`
  (fallback: its first word's page).
- `pageForReference(surah, ayah=1)` → that, with fallback to the surah's
  first page (`MIN(page)`), for surah-level navigation.
- `ayahBoxesOnPage(page, surah, ayah)` → per-line highlight boxes.

`PROJECT-SPECIFIC`: this uses `mushaf_*` (MushafDatabase pages). The Turath
reader and the old own-engine Quran reader use *other* page notions — keep
them straight.

---

## 7. Recitation-follow (word highlight during audio)  (`SOURCE-BACKED` — not built)

- Per-word timing is **external, per-reciter** (quran-align / QUL segments),
  tokenised by **Tanzil space-split**.
- To highlight the current word on a mushaf page you need a mapping:
  `Tanzil (surah, ayah, tokenIndex)` → `mushaf_words (surah, ayah, word_index)`.
  These segmentations differ (ornaments, particle splits) — the mapping is a
  real artifact, build and store it; do not assume `tokenIndex == word_index`.
- Highlight geometry then = that word's bbox (`§4`).

---

## 8. Tajweed colour overlay  (`SOURCE-BACKED` — not built)

- Rule spans (e.g. cpfair/quran-tajweed) are **character offsets into a
  specific Tanzil text file**. They do **not** transfer to another edition
  or to MushafDatabase glyph geometry without rebuilding.
- Store the **rule id**; pick the colour in-app (publishers disagree on
  colours). KFGQPC "Tajweed V4" palette is the de-facto default.
- On a glyph-SVG page, a per-character colour overlay needs the
  `md-diacritic-*` / `md-ligature-*` sub-groups (MushafDatabase exposes
  them) — a separate, later extraction pass; not in `mushaf_layout.json.gz`.

---

## 9. Interaction rules (summary)

1. Resolve to `(surah, ayah, word_index)`; then forget the pixels.
2. One page-level hit-test, not per-word gesture detectors.
3. Coordinate transform is `xMidYMid meet` — inverse it exactly.
4. A bbox is only valid in its own viewBox — never cross editions raw.
5. Quran anchors are numeric; never text-offset anchors for Quran.
6. Word ranges come from `word_index` min/max, not from screen geometry.
7. External timing/tajweed data is edition-bound — map, don't assume.
8. Highlight = per-line union boxes, geometric, not `TextSpan` background.
