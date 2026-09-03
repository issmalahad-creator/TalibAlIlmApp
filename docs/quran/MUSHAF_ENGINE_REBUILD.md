# Mushaf Rendering Engine — Rebuild Audit & Plan

Status: **PHASE A COMPLETE 2026‑09‑03.** M0–M3 signed off by Ismail
(`ad49877` `7e59639` `434a773` `d90eb1a`); M4 cache (`76530d4`); M5 604‑page
QA gate — **geometry 604/604 · data 604/604 · visual 604/604** (`2c1b9aa`);
M6a legacy‑code deletion (`10794e1`); M7 close‑out (ERRATA E‑10..E‑12).
`flutter analyze` clean · `flutter test` 467/467 · emulator‑verified. M6b
(page_recitation off the old packer) deferred, non‑blocking. **Next: Phase B
of `MUSHAF_MASTER_ARCHITECTURE.md` — the corpus (iʿrāb / ṣarf / tafsīr).**
Ordered as Ismail asked: CURRENT ARCHITECTURE → PROBLEMS → ROOT CAUSES →
PROPOSED ARCHITECTURE → MIGRATION PLAN → QA PLAN.

Load `.claude/skills/quran-engineering` + `docs/quran/MUSHAF_ENGINEERING.md`
before acting on this. This doc does **not** restate what those already say
(the two valid render strategies, the coordinate space, ERRATA E‑1/E‑2, the
Madani "every page starts and ends on an ayah boundary" property).

Golden rule (unchanged): **not** "a beautiful mushaf with information beside
it" — **a mushaf where the word itself is the key to the knowledge.** The
rebuild is about correctness and honesty of the rendering, not new features.

Priority order for every decision below: **Correctness → Stability →
Performance → Realistic interaction → Beauty.**

---

## 1. CURRENT ARCHITECTURE

### 1.1 Layers as they exist today

```
Visual        assets/mushaf/pages_svg/NNN.svg.gz   — all 604 MushafDatabase
              Ligature-Based SVG V1.01 pages, gzip-compressed (~75 MB), the
              real hand-set page art. viewBox "0 0 382.68 547.09", xMidYMid meet.
   ↓
Geometry      mushaf_* tables (DB migration v51), seeded once from
              assets/mushaf/mushaf_layout.json.gz by MushafLayoutSync after
              structural validation. Per word: (page, line, word_order, surah,
              ayah, word_index, word_type, text_uthmani, text_imlaey, bbox).
              Per ayah: mushaf_aya_marks (surah,ayah) PK + page + line + bbox?.
   ↓
Interaction   lib/models/mushaf_layout.dart — MushafPageLayout, framework-free.
              wordAtPoint(x,y) / ayaMarkAtPoint(x,y) / ayahBoxes(surah,ayah).
   ↓
Selection     lib/models/quran_selection.dart — QuranSelection{page, surah,
              ayah, wordIndex?, type(word|ayah), wordBox?, textUthmani?}.
   ↓
Knowledge     KnowledgeGateway.factsFor / factsForAyah  (unchanged by this work)
   ↓
Presentation  knowledge_surface.dart word/ayah surfaces  (unchanged by this work)
```

### 1.2 The render path (what actually draws a page)

`MushafSemanticReaderScreen` → `PageView.builder` (one page per index, RTL) →
**`MushafPageView`** (`lib/widgets/mushaf_page_view.dart`, `StatelessWidget`):

1. `LayoutBuilder` gives `maxW × maxH`.
2. `_contentBox(layout)` computes a box in viewBox units meant to be "the
   inked content minus the wide print margins": min/max over every word +
   aya-mark + marker bbox, then **forced symmetric about the viewBox centre
   X** (`halfW = max(centreX−minX, maxX−centreX)`), then `± 0.5 · line-pitch`
   vertical headroom, then `× 1.045` on the longer side.
3. `scale = min(maxW/contentW, maxH/contentH)`; `dx,dy` centre the scaled
   content box in the viewport.
4. `Stack(clipBehavior: hardEdge)`:
   - `Positioned(left: dx, top: dy, width: vbW·scale, height: vbH·scale,
     child: _PageArt)` — `_PageArt` gzip-decodes `NNN.svg.gz` (static
     `Map<int,String?>` cache), renders `SvgPicture.string(fit: BoxFit.fill)`,
     optional `ColorFilter.srcIn` re-ink for night. Text fallback (`_lines` →
     `Positioned` + `FittedBox` + `Text`, RTL, per line) for a page with no
     bundled art — **unreachable in the shipped build** (all 604 bundled).
   - `Positioned.fill(_SelectionOverlay)` — `CustomPaint` gold word / calm
     ayah highlight, 180 ms grow-in. Never touches the SVG.
5. One page-level `GestureDetector(onTapUp, onLongPressStart)`. `handleTap`:
   `toLocalViewBox(point)` → `ayaMarkAtPoint` first → else `wordAtPoint` →
   else nothing. No per-word `GestureDetector`.

### 1.3 Data build

`tool/extract_mushaf_svg.py` (Python, build-time, local only):
- Reads the 604 `SVG V1.01/NNN.svg` (git-ignored source tree).
- **Drops all glyph paths.** Keeps, verbatim, every `md-word`'s
  `data-surah / data-aya / data-word-index-in-ayah / data-line-number /
  data-hafs / data-imlaey`, plus `juz-star` (۞) and `sajda-mehrab` (۩)
  ornament words (they hold a real `word_index`).
- `bbox` per word/mark/marker = **union of every descendant `<path d>`
  segment end-point and Bézier control point** → a conservative (never too
  small) box.
- Parses `md-page-inner data-rect` into `rect` **and emits it** — but the 4
  numbers are `x0,y0,x1,y1` (corners) and the app misreads them as
  `x,y,w,h`. See §1.6 (verified 2026‑09‑03) and P2.
- Emits `mushaf_layout.json.gz` + `mushaf_manifest.json` (counts, sha256).

`MushafLayoutSync`: validates (604 pages, contiguous per-ayah `word_index`,
contiguous per-page `word_order`, 6236 aya-marks, aya-mark set == word-ayat
set, per-surah ayah counts vs `lib/data/quran_surahs.dart`, no degenerate /
out-of-viewBox boxes, no page with zero words) → bulk-seeds `mushaf_*` in one
transaction → post-insert cross-check → writes `mushaf_meta`.

### 1.4 The parallel (legacy) stack — still partly alive

`lib/services/mushaf_page_layout.dart` — the **Phase 71 own-engine** text
packer: `flattenAyatToWords` → `packWordsIntoLines` (greedy, `TextPainter`
width measurement) → `computeMushafPageLayout` (font-size fit to 15 lines).
Defines its **own** `MushafWord` / `MushafLine` / `MushafPageLayout` types
(name-collides with `models/mushaf_layout.dart`).

- `quran_reading_screen.dart` (its only real consumer) — **deleted** in the
  unified-reader cutover (2026‑09‑03).
- **Still used by `lib/screens/page_recitation_screen.dart`** (lines 78, 225)
  — the page-recitation checker packs the page's words into lines with
  `TextPainter`, independent of and inconsistent with the real SVG line
  breaks.

### 1.5 Identity & coordinates (for the record)

- Page number = **MushafDatabase page 1..604**, *not* Tanzil `page_number`.
  `quran_ayat.page_number` (Tanzil) and `favorites.pageNumber` are a
  different numbering — the favourites-jump bug came from mixing them; fixed
  by routing through `MushafLayoutRepository.pageForReference`.
- Coordinate space: `382.68 × 547.09`, `preserveAspectRatio="xMidYMid meet"`,
  identical for all 604 pages. `mushaf_*` bbox columns are in this space.
- We do **not** have QUL layout data or the KFGQPC QCF/QPC per-page fonts in
  this repo (licence). See 4.6.

### 1.6 Verified facts about `data-rect` and line geometry (2026‑09‑03)

Checked against the raw `svg/003.svg`, the bundled `003.svg.gz`, and the
extracted `mushaf_layout.json.gz` — not assumed:

- **`md-page-inner data-rect` is present on all 604 pages.** Not partial.
- **Its 4 numbers are `x0, y0, x1, y1` (corners), NOT `x, y, w, h`.**
  Parsed as corners → 604/604 valid and inside the viewBox. Parsed as
  `x,y,w,h` (what `MushafBox.fromList` does today) → only **255/604** stay
  inside the viewBox; `mushaf_pages.rect_w` / `rect_h` currently hold
  `x_max` / `y_max`. This is a real bug — **not** "the column is null" (P2
  corrected).
- **What `data-rect` actually bounds:** that page's 15 laid-out lines (plus
  a little top padding). On dense text pages it equals the word-bbox union
  exactly; on header / short pages it is a bit taller at the top.
- **Frame width is near-uniform:** `x1−x0` median 245.0, p10–p90 = 243–247.
  → a single consistent on-screen scale is achievable.
- **Frame horizontal position is bimodal:** ~half the pages sit at
  `x0 ≈ 45`, ~half at `x0 ≈ 90` (**301/604** differ from the median by
  > 40 units). This is the **recto/verso gutter** of the printed mushaf
  (odd vs even page inner margin), faithfully preserved. **It is the actual
  cause of "some pages shift left/right."** Not a rendering bug.
- **There is no per-line geometry anywhere.** `mushaf_lines` =
  `(page, line, type)` only. A `LineGeometry.rect` (§4.1) can only be the
  union of that line's word bboxes — derived, never authored.

**Consequence for the design:** rendering the raw viewBox + letterbox
(what §3 RC‑A first proposed) would *re-expose* the recto/verso shift. The
correct move is to **centre the corrected per-page `data-rect`** in the
viewport. Because the frame width is uniform, every page then renders at
nearly one scale, centred, with no shift — and the art is never touched
(we only choose which region of the fixed-size page to centre on screen).
`_contentBox` was a crude approximation of exactly this; the fix is to
drive it from corrected authored data, not a runtime word-box heuristic.

---

## 2. PROBLEMS (observed, concrete)

**P1 — the render transform is a per-page heuristic, not the page.**
`_contentBox` recomputes "where the content is" from word boxes every build,
with three tuned fudge factors (symmetric-X reflection about centre, `0.5 ·
line-pitch` headroom, `× 1.045`). This is the direct source of every
"الحجم … مستحي في اخر الصفحة / كبّره" complaint: the crop is estimated, so
it is sometimes too tight, sometimes off-centre, and it changes character
between pages with different margin content (surah headers, basmala lines,
short final pages).

**P2 — the authoritative content rect is parsed wrong, then ignored anyway.**
`md-page-inner data-rect` is the mushaf's own statement of where the 15-line
box sits, and it is present for **all 604 pages** (§1.6). But it is
`x0,y0,x1,y1` and the app reads it as `x,y,w,h`, so `mushaf_pages.rect_w/h`
currently store `x_max/y_max` (255/604 pass an inside-viewBox check). And
`_contentBox` uses none of it regardless — it re-derives a worse answer from
glyph geometry with three fudge factors.

**P3 — nothing structurally enforces "aspect ratio preserved."**
`_PageArt` uses `fit: BoxFit.fill` into a box sized `vbW·scale × vbH·scale`.
It is non-distorting *today* only because that box happens to keep the
viewBox aspect ratio — a coincidence of the current `_contentBox` math, not
an invariant. Any future change to the box computation silently stretches the
mushaf. (The rebuild removes the risk: the SVG box becomes a literal
`const Size(viewBox.w, viewBox.h)` and all scaling moves into the single
`ScreenTransform` — §4.3.)

**P4 — the page widget still contains a text-reflow renderer.**
`_lines` / `_RenderedLine` / `Stack` + `Positioned` + `FittedBox` + `Text`
is exactly the "Flutter decides the layout" path the rebuild is meant to
forbid. It is dead in the shipped build but present, tested, and a
maintenance trap; it also anchors the second `MushafPageLayout` type.

**P5 — hit-test has a soft "nearest" fallback.**
`wordAtPoint` / `ayaMarkAtPoint` inflate every box by `pad` (1.5 / 2.0) and,
among inflated boxes that contain the point, pick the one whose **centre is
closest**. That is a distance tie-break — a mild `nearestWord`. It only
triggers on overlap, but the spec is "strict, no proximity."

**P6 — box precision ceiling is unmeasured and unstated.**
bbox = union of Bézier control points → (a) adjacent words' boxes overlap
horizontally, (b) a word with tall stacked diacritics has a box much taller
than its ink, (c) some `mushaf_aya_marks.bbox` is **null** (mark
un-hit-testable). Real precision is "word-level, roughly box-sized." Nothing
documents or QA's this; `pad` tuning cannot fix it.

**P7 — no preload, no eviction.**
`_PageArt` loads only the current page, on first build, one frame late — a
page turn shows a blank `ColoredBox` until gunzip+parse finishes. The static
`_cache` never evicts; a long session holds every visited page's SVG string
in memory.

**P8 — there is no 604-page QA artifact.**
`MushafValidation` checks the *data* at seed time. Nothing renders or
inspects *every page* and emits a per-page PASS/FAIL for geometry, data, and
visual integrity. "Test all 604 pages" (Ismail's completion bar) has no tool.

**P9 — `page_recitation_screen.dart` is a second, divergent mushaf renderer.**
It packs the same ayat into lines with `TextPainter`, producing line breaks
that do not match the real page. Two "mushaf page" layouts in one app.

**P10 — "page number" means three things.**
MushafDatabase page (`mushaf_*`), Tanzil `page_number` (`quran_ayat`),
favourites `pageNumber`. One rule doc is needed so a fourth consumer doesn't
reintroduce the bug.

---

## 3. ROOT CAUSES

**RC‑A — the reader crops with a runtime heuristic instead of the mushaf's
own authored frame.** `_contentBox` guesses the content region from glyph
geometry every build. The mushaf already states it: `md-page-inner data-rect`
(§1.6). The fix is to resolve that rect **once at extract time** (correcting
the `x0,y0,x1,y1` → `x,y,w,h` bug), store it per page, and **centre it** in
the viewport. Note: simply ScaleToFit-ing the *raw viewBox* is not enough —
the source pages carry a real recto/verso gutter (§1.6), so the raw viewBox
would make the text visibly jump left/right between pages. Centring the
corrected per-page frame removes that while touching nothing in the art.
P1, P2 collapse into this.

**RC‑B — geometry is a conservative control-point union, not glyph-ink
bounds.** Good enough for "is this tap on this word"; structurally incapable
of pixel-tight selection. Tightening needs per-word glyph-outline bboxes from
the SVG paths (a real extractor change, deliberately **out of v1 scope**).
The honest answer is to **measure and publish the ceiling**, keep strict
containment, and never paper over it with distance math. P5, P6.

**RC‑C — page geometry and screen geometry are computed together.**
`MushafPageView.build` mixes a *data* concern (where words are, in viewBox
units — fixed, identical on every device, a property of page N) with a
*layout* concern (scale + offset for this viewport — changes with every
resize). They must be separate objects: a pure `PageGeometry` value and a
pure `ScreenTransform` function. P1, P3.

**RC‑D — the page widget inherited a fallback renderer it should never own.**
Leftover from the Phase 71 own-engine era. One renderer, one path: the SVG.
No `Text` / `RichText` / `Wrap` / `ListView` / `Column`-of-`Text` anywhere in
the page-drawing widget. P4, P9.

**RC‑E — there is no build-time rendering gate.** Validation proves the data
is *internally consistent*; it never proves *every page renders* and *every
page's geometry sits inside its frame*. P8.

---

## 4. PROPOSED ARCHITECTURE

### 4.1 Value objects — page geometry (no pixels, no screen)

```
PageGeometry            // one per page, viewBox units, built from mushaf_*
  page                  1..604
  viewBox               const Size(382.68, 547.09)
  contentRect           Rect  — md-page-inner data-rect, CORRECTED from the
                        source's x0,y0,x1,y1 to x,y,w,h at extract time (§1.6)
  lines    [ LineGeometry { line 1..15, type, rect } ]   // rect = union of the
                        line's word bboxes — derived, no authored line geometry
  words    [ WordGeometry { wordId, surah, ayah, wordIndex, line, order,
                            type(text|juzStar|sajdaMehrab), rect } ]
  ayaMarks [ AyaMarkGeometry { surah, ayah, line, rect? } ]
  markers  [ MarkerGeometry { kind, line?, surah?, rect? } ]
```

Immutable, `dart:ui`-free except `Rect`. This is the rename/tighten of
`models/mushaf_layout.dart`. **`contentRect` is new and required** (4.5).

### 4.2 `ScreenTransform` — the only coordinate bridge

```
ScreenTransform.fit(contentRect, available):     // ScaleToFit, aspect ALWAYS kept
  scale  = min(available.w / contentRect.w, available.h / contentRect.h)
  offset = centre the scaled contentRect in `available`
  Rect   toScreen(Rect viewBoxRect)              // still in viewBox units in
  Offset toViewBox(Offset screenPoint)           // → out; contentRect just
                                                 //   decides scale + centring
```

- The transform fits the **corrected per-page `contentRect`**, not the raw
  viewBox — so the recto/verso gutter (§1.6) never reaches the screen and
  every page lands at ~one scale, centred. The rest of the page art is drawn
  and clipped.
- Aspect ratio is preserved by construction — there is no code path that
  stretches.
- **Horizontal scroll is structurally impossible:** after `fit`, the drawn
  content width ≤ viewport width; the page widget is a fixed `SizedBox`;
  there is no `Scrollable` around an individual page (the `PageView` only
  turns pages).
- The renderer, the hit-test, and the selection overlay all take the *same*
  `ScreenTransform` instance — they cannot drift apart.
- Unit-testable with zero widgets: scale/offset for known sizes, round-trip
  `toViewBox(toScreen(r)) == r`, "longest line's right edge ≤ viewport width
  for all 604 pages."

### 4.3 `MushafPageRenderer` — paints the art, nothing else

```
RepaintBoundary
  child: ClipRect(                               // gutter falls outside → clipped
    child: Transform(scale + offset from ScreenTransform)
      child: SizedBox(viewBox.w × viewBox.h)     // the whole page, viewBox units
        child: SvgPicture.string(
                 svg, fit: BoxFit.fill,          // 1:1 viewBox→box, aspect kept
                 colorFilter: night ? srcIn(ink) : null))
```

The whole SVG page is laid out at its natural viewBox size, then the single
`ScreenTransform` scales + offsets it so `contentRect` is centred in the
viewport; the recto/verso margin lands outside the `ClipRect` and is clipped.
`BoxFit.fill` is safe here because the box is exactly `viewBox.w × viewBox.h`
(aspect ratio identical) — the transform, not the fit, does the scaling.
No `Text`. No reflow. No `if (page == N)`. Night mode = whole-art re-ink
only. Placeholder during decode = warm cream (light) / transparent (night).

### 4.4 `MushafInteractionLayer` — one strict hit-test

```
point
  -> transform.toViewBox
  -> ayaMarkAtPoint  : first AyaMarkGeometry whose rect CONTAINS the point
                       (marks with null rect are skipped — see 4.5)
  -> else wordAtPoint : first WordGeometry (reading order) whose rect
                        CONTAINS the point
  -> else null (reading, no selection, no popup)
  => QuranSelection
```

**Strict `contains`. No inflate-and-pick-nearest. No distance.** Ordered by
`word_order`, so on the rare overlap the earlier (right-most, first-read)
word wins deterministically. The measured precision ceiling is published
(QA, §6) and surfaced in `ERRATA` — not hidden.

### 4.5 Data-pipeline changes (one version bump, re-seed)

`tool/extract_mushaf_svg.py`:
- Read `md-page-inner data-rect` (present for all 604 — §1.6), **convert
  `x0,y0,x1,y1` → `x,y,w,h`**, assert `w>0 && h>0` and the box is inside the
  viewBox, and emit it as `contentRect` for all 604 pages. Assert 604/604 or
  fail the build. (No page lacks it; the line-rect-union fallback is dead
  code we don't add.)
- Fix `MushafBox.fromList` / the `rect_*` read path to match (or store
  `contentRect` in its own explicit 4 columns and stop reusing the
  mis-parsed `rect_*`).
- Emit `art_sha256` per page (sha256 of `NNN.svg.gz`) for the QA tool.
- Optionally emit per-page `aya_mark` rects reconstructed from the last word
  of the ayah when `md-aya-mark` has no own paths, so no mark is
  un-hit-testable (fixes P6c). Flag these as `derived`.

`kMushafLayoutVersion` 1 → **2**. `MushafLayoutSync` re-seeds automatically
(existing "version moved on" path). `MushafValidation` gains: `contentRect`
present and inside viewBox for 604/604; `art_sha256` present for 604/604;
zero `derived` aya-mark rect outside its line's rect.

**No new tables.** `mushaf_pages.rect_*` already exists — it just gets
populated for every page. Schema `mushaf_*` (v51) is unchanged.

### 4.6 QUL — explicit decision

We do not have QUL layout data in the repo. We do not need it as a source:

- QUL's value is a **15-line text layout for a font-based renderer**
  (strategy A, `MUSHAF_ENGINEERING.md` §6). We cannot use strategy A — no
  KFGQPC fonts (licence).
- MushafDatabase V1.01 is a **stronger** source for our renderer (strategy
  B): the real page art **and** per-word `(surah, ayah, word_index)` +
  `line_number` + geometry, all from one SVG, one coordinate system, one
  open licence ("Sadaqa‑e‑Jaria").
- If Ismail wants QUL as a **cross-check**: it enters only as an optional QA
  input — compare our per-page `(surah,ayah)` range table against QUL's
  page→word-range mapping and report mismatches. It is never the source of
  truth for text or geometry. Recorded here so this isn't re-litigated.

### 4.7 Paging & cache

```
MushafPageCache
  load(page)      gunzip + parse off the UI frame (compute/isolate or
                  scheduler microtask), returns a ready SvgPicture source
  preload         current ± 1 on every settled page
  evict           LRU, hard cap (default 7 pages of SVG string + parsed pic)
```

`MushafSemanticReaderScreen` keeps its `PageController`; `_PageArt`'s ad-hoc
static map is replaced by this. A page turn shows the preloaded neighbour
instantly; a jump shows the warm placeholder for one decode.

### 4.8 What shrinks / moves / dies

| file | change |
|---|---|
| `lib/widgets/mushaf_page_view.dart` | delete `_contentBox`, `_lines`, `_RenderedLine`, `_PageArt` text fallback. Widget = `ScreenTransform` + `MushafPageRenderer` + `MushafInteractionLayer` + `MushafSelectionLayer`. Stays thin. |
| `lib/models/mushaf_layout.dart` | rename render-agnostic parts to `*Geometry`; add `contentRect`; hit-test → strict `contains`, ordered; drop the distance tie-break. |
| `lib/repositories/mushaf_layout_repository.dart` | read the **corrected** `contentRect` (§4.5); unchanged otherwise. |
| `lib/services/mushaf_layout_sync.dart` | extended validation (4.5). |
| `tool/extract_mushaf_svg.py` | `contentRect` + `art_sha256` (+ optional derived mark rects). |
| new `lib/widgets/mushaf/…` | `screen_transform.dart`, `mushaf_page_renderer.dart`, `mushaf_page_cache.dart` (small, focused, unit-tested). |
| `lib/screens/page_recitation_screen.dart` | later step: consume `mushaf_*` real lines instead of `packWordsIntoLines`. |
| `lib/services/mushaf_page_layout.dart` + `test/mushaf_page_layout_test.dart` | delete once `page_recitation_screen` is migrated. |
| `tool/mushaf_qa.dart` (new) | the 604-page QA harness (§6). |

No change to `QuranSelection`, `KnowledgeGateway`, the knowledge surfaces, or
the DB schema.

---

## 5. MIGRATION PLAN (phased — no page left untested)

**M0** — this doc reviewed & approved by Ismail. No code.

**M1 — data only. ✅ DONE 2026‑09‑03 (commit `ad49877`).**
Verified `data-rect` on all 604 bundled `SVG V1.01` pages (present, no
transforms, `viewBox 0 0 382.68 547.09`, format `x0,y0,x1,y1` — 604/604 valid
as corners vs 255/604 as `x,y,w,h`). `MushafBox.fromCorners` converts →
`x,y,w,h`; `MushafPageLayout.fromJson` uses it; `kMushafLayoutVersion` 1→2
(auto re-seed); `MushafValidation.badContentRects` gates 604/604;
`art_set_sha256` (`tool/mushaf_art_hash.py`, `8bf64d88…67d0`) added to the
manifest + `mushaf_meta` — identical before/after ⇒ artwork untouched.
`flutter analyze` clean · `flutter test` 447/447 · `pages_svg/` +
`mushaf_layout.json.gz` byte‑identical. **No renderer/transform/interaction
change.** The extractor itself was not modified — the asset already carried
the raw 4 numbers; only the Dart interpretation was wrong.

**M2 — geometry / transform, behaviour-preserving. ✅ DONE 2026‑09‑03
(commit `7e59639`).** `lib/widgets/mushaf/screen_transform.dart` —
`ScreenTransform` (one scalar scale + offset; `.fit` takes raw doubles so it
mirrors the pre‑M2 inline math term‑for‑term) + `MushafFitSource` flag
(`legacyContentBox` default = no visual change; `contentRect` = M3, wired but
unused). `MushafPageView` now derives `scale`/`dx`/`dy` from `ScreenTransform`
via `MushafFitSource.legacyContentBox`; the rest of `build` is unchanged.
`test/screen_transform_test.dart` (10 tests) proves it reproduces the legacy
`(scale, dx, dy)` **bit‑for‑bit** on 7 realistic frame/viewport cases + exact
inverse + aspect‑preserved. `flutter analyze` clean · `flutter test` 457/457.
**Emulator‑verified** (`Medium_Phone_API_35`): pages 1/3/4/255 render
unchanged; word tap on p3 → `ٱللَّهُ` (al‑Baqara 7, w2) with correct
highlight. The `PageGeometry`/`*Geometry` model rename in §4.1 was **not**
bundled here — a wide rename would defeat "prove nothing changed"; do it as
its own isolated mechanical step (M2b) or fold into M3.

**Recto/verso shift — root cause proven before M3.** `tool/mushaf_svg_qa.py`
over all 604 SVGs + `docs/quran/MUSHAF_RECTO_VERSO_DIAGNOSIS.md`: one viewBox,
**zero transforms**, uniform text width (~245) and frame width (~283); the
whole content block's x‑origin alternates ~±23 units recto/verso = the bound
muṣḥaf's gutter margin, faithfully digitised. **Category A but correct** — do
NOT edit the SVGs, do NOT add per‑page offsets. M3 = one uniform rule: centre
the per‑page content region (M1‑corrected `data-rect`, or the frame bbox —
Ismail's choice) instead of the raw viewBox.

**M3 — renderer switch. ✅ DONE 2026‑09‑03 (commit `434a773`).**
`MushafSemanticReaderScreen` passes `fitSource: MushafFitSource.contentRect`
→ `ScreenTransform` fits+centres the M1‑corrected `data-rect` + a 3%‑of‑width
uniform breathing margin (`_kContentRectPad`), for all 604 pages, no per‑page
logic, no SVG change. `test/mushaf_page_view_test.dart` +1 test (hit‑test
still resolves under the new transform). `flutter analyze` clean ·
`flutter test` 458/458 · `art_set_sha256` unchanged · zero asset edits.
**Emulator‑verified** (`Medium_Phone_API_35`, 1080×2400): pages 3/4/5 now
share the exact horizontal position (recto/verso shift **gone**); content
noticeably larger, justified edge‑to‑edge, al‑Fātiḥa banner visible, no
horizontal overflow, medallions round; word tap p5 → `فَيَعْلَمُونَ`
(al‑Baqara 26, w17). **Open tradeoff:** the far‑margin juz/surah name repeats
(outside the 15‑line block) clip slightly — region‑1 (`data-rect`) vs
region‑2 (`md-page-outer` frame) is Ismail's call; region 2 needs a new
extract‑time per‑page frame‑bbox field (runtime bbox is too slow).
**M3b (`d90eb1a`)** — Ismail signed off M3 but flagged the far-margin
juz-name / surah-name headers + foot page number were clipped. Measured all
604: those overhang `data-rect` by ≤ 0.088 of its width (median 0.078); the
deep ornaments (۞ ۩) overhang up to 0.25 and stay in the margin by design.
`_kContentRectPad` 0.03 → **0.09** — every header back on-screen on all 604,
per-page centring unchanged (shift still cancelled), still larger than
`_contentBox`. Region-1 (`data-rect`) confirmed; region-2 not needed.
`analyze` clean · `test` 458/458 · art unchanged · emulator pp. 8/3/77 OK.

The `_contentBox` heuristic, the text fallback, and `_lines` are **not yet
deleted** — kept behind `MushafFitSource.legacyContentBox` as the comparison
baseline; remove them in M6.

**M4 — cache. ✅ DONE (`76530d4`).** `lib/widgets/mushaf/mushaf_page_cache.dart`
— `MushafPageCache` singleton: gunzip+utf8 decode in a background isolate
(`compute`), `preloadAround(p)` decodes p±1, bounded LRU (cap 7), shared
in-flight decode. `_PageArt` uses it; warm placeholder while decoding.
`onPageChanged` also preloads. 8 tests. Emulator: 5 fast flings 1→5, zero
blank frames. (Same commit reversed the page-turn direction per Ismail —
swipe left→right = next.)

**M5 — 604-page QA gate. ✅ DONE (`2c1b9aa`).** `test/mushaf_qa_604_test.dart`
iterates every page and checks geometry + data + visual (incl. the real
`flutter_svg` parse). Writes `docs/quran/reports/{mushaf_qa_report.json,
MUSHAF_QA_REPORT.md}`. Result: **geometry 604/604 · data 604/604 · visual
604/604 — ALL PASS**. No `if (page == N)` anywhere. This is Ismail's
completion bar.

**M6a — delete the legacy layout code. ✅ DONE (`10794e1`).** Removed
`_contentBox`, `_lines`/`_RenderedLine`, the `Text` fallback, the
`MushafFitSource` enum, and the dead params. `MushafPageView` fits directly
from `layout.rect` + `_kContentRectPad`. Behaviour-identical to M3b.
467 tests. Emulator re-verified.
**M6b — deferred.** `lib/services/mushaf_page_layout.dart` (the `TextPainter`
packer) is now used **only** by `page_recitation_screen.dart` (a separate
feature, no engine coupling, no name-collision — nothing imports both). Its
migration to `mushaf_*` real lines + deletion is a low-priority cleanup,
not an engine blocker.

**M7 — close-out. ✅ DONE.** `flutter analyze` clean (6 pre-existing infos) ·
`flutter test` 467/467 · APK builds · emulator re-verified across M3b/M4/M6a.
`ERRATA.md` E‑10 (`data-rect` corner order), E‑11 (recto/verso was
faithful), E‑12 (`_contentBox` = runtime heuristic where authored data
existed). Docs updated.

**Phase A (rendering engine) is functionally complete:** 604/604 QA + real
emulator across the visual milestones. Remaining polish (M6b, a scripted
screenshot walk of the full M3 page set) is non-blocking. **Next:
`MUSHAF_MASTER_ARCHITECTURE.md` Phase B — the corpus.**

---

## 6. QA PLAN

### 6.1 The 604-page tool — `tool/mushaf_qa.dart`

Runs over the **seeded `mushaf_*` DB + the bundled `NNN.svg.gz` assets**
(via `flutter test` harness so `flutter_svg` parsing is real). For every page
1..604 emit a row `{page, geometry: PASS|FAIL, data: PASS|FAIL, visual:
PASS|FAIL, notes:[…]}`, then a summary and two artifacts:

- `docs/quran/reports/mushaf_qa_report.json` (machine)
- `docs/quran/reports/MUSHAF_QA_REPORT.md` (human — per-page table + failures)

### 6.2 Geometry checks (per page)

- `line_count ∈ 1..15`; every `mushaf_words.line` exists in `mushaf_lines`.
- every word `rect` fully inside `viewBox` (ε = 1.0 unit); no NaN, no `w<=0`,
  no `h<=0`.
- `word_order` contiguous `1..N`.
- `contentRect` present, inside `viewBox`, `w>0 && h>0`.
- union of the page's word rects ⊆ `contentRect` inflated by ε.
- every non-null aya-mark `rect` inside `viewBox`; `derived` marks (4.5)
  inside their line's rect.

### 6.3 Data checks (per page)

- per `(surah, ayah)` appearing on the page, its `word_index` values are
  contiguous `1..k` (ornament words included — that's why they're kept).
- page's aya-mark `(surah,ayah)` set **==** page's word `(surah,ayah)` set
  (ERRATA E‑2 guard).
- `text_uthmani` non-empty for every `word_type = text` word.
- **Madani boundary property:** the page's first word has `word_index == 1`
  (new ayah starts the page) **and** the page's last content element is an
  aya-mark or the last word of its ayah (page ends on an ayah boundary).
  Report violations — do not auto-fix.
- `surah` then `ayah` monotonic non-decreasing in `word_order`.

### 6.4 Visual checks (per page)

- `NNN.svg.gz` exists, gunzips, decoded string contains `<svg`.
- `viewBox="0 0 382.68 547.09"` and `preserveAspectRatio` present.
- `<path` count `> 0`.
- `flutter_svg` parses it without throwing.
- intrinsic aspect ratio == `382.68 / 547.09` within ε.
- `art_sha256` matches `mushaf_meta` / manifest.

### 6.5 Cross-source (optional, report-only)

Our per-page `(surah,ayah)` range vs Tanzil `quran_ayat.page_number` — list
mismatches. Never modify text or geometry to make them agree (open question
`QURAN_LAYOUT.md` §7 / VT‑3).

### 6.6 Pass bar

**604/604 pages `geometry == PASS && data == PASS && visual == PASS`.**
Anything less blocks "done". The committed report is the evidence.

### 6.7 Device QA (what a test runner cannot check)

Scripted walk with screenshots, stored under `docs/quran/reports/device/`:
pages 1, 2, 3, 50, 77, 128, 255, 300, 355, 434, 528, 604 + 10 random. Each
screenshot shows a word tap resolving to the correct `(surah, ayah,
word_index)` in a debug overlay, and an aya-mark tap resolving to the correct
ayah; plus one "tap empty margin → nothing happens" per page. Then a
free-scroll sample of ~30 pages confirming art renders and paging shows no
blank frame.

---

## 7. Binding constraints (carried from the plan — do not cross)

- No AI as a source or an inferer. Missing datum → *"لا توجد بيانات موثقة
  لهذا العنصر حاليًا"*, never a guess.
- **Never** alter the mushaf rasm / ḍabṭ. No SVG edits. Nothing painted over
  the glyphs that harms reading or the tashkīl. The Selection Layer is a
  translucent wash **behind nothing**, above the art, never darkening ink.
- One page-level hit-test. No `GestureDetector` per word.
- Never reconstruct Quran text from geometry (ERRATA E‑1).
- Never infer ayah/word identity from page position when `(surah, ayah[,
  word_index])` is in the data (ERRATA E‑2).
- No cross-edition bbox reuse without an explicit coordinate transform
  (`mushaf_borders` / quranpedia stays untouched; optional future art path
  only, never deleted).
- Offline-first: mushaf + geometry + licensed data + notebook all work with
  no network.
- Every new user-facing string → `basicText` in 13 languages, RTL/LTR aware.
- No `if (page == N)` anywhere. Fix the data, the renderer, or the geometry.
