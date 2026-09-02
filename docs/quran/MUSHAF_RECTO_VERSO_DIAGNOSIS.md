# "Some mushaf pages look shifted left / right" — root-cause diagnosis

Phase 80, before M3. Ismail: *"investigate the source of the SVG itself, not
add a random offset in Flutter. Diagnose → identify affected pages → prove
root cause → repair strategy → test → then modify. Do NOT edit the 604 SVGs
before proving the cause."*

Method: `tool/mushaf_svg_qa.py` over **all 604** bundled
`assets/mushaf/pages_svg/NNN.svg.gz`, using the same `svg.path` parser as the
extractor (resolves the relative `M … c …` glyph paths correctly). Raw output:
`docs/quran/reports/MUSHAF_SVG_QA.md` + `mushaf_svg_qa.json`. **Nothing was
modified.**

---

## What was measured (604 / 604 pages)

| property | result |
|---|---|
| distinct `viewBox` values | **1** — `0 0 382.68 547.09` on every page |
| pages with any `transform` / `translate` / `scale` (anywhere in the tree) | **0** |
| pages with geometry outside the viewBox | **0** |
| pages with non-painting paths skewing a bbox (`fill:none`, `opacity:0`, `display:none`) | **0** |
| text-block width (`md-page-inner` path bbox) | odd median **245.04**, even median **245.01** — uniform (Δ 0.03) |
| decorative-frame width (`md-page-outer` minus inner) | odd **282.8**, even **283.2** — uniform (Δ 0.4) |
| **text-block centre-x** | odd (recto) median **167.9**, even (verso) median **214.4** — **Δ ≈ 46.5** |
| **frame centre-x** | odd **168.1**, even **214.2** — **Δ ≈ 46.1**, tracks the text centre-x per page |
| viewBox centre-x | 191.34 |

Per page, frame-centre and text-centre are the same number (page 3: frame
168.10 / text 168.09; page 4: frame 214.60 / text 214.56). The **whole page
content** — border, 15 lines, margin marks, page number, headers — sits as
one block.

Correlation with recto/verso is exact: from page 3 onward, **every odd page**
has its content block centred at x ≈ 168 (≈ 23 units **left** of the viewBox
centre); **every even page** at x ≈ 214 (≈ 23 units **right**). (Pages 1–2,
al-Fātiḥa, are a narrower centred special case — text width ~185, centre ~191.)

The `frame centre-x` reads noisy (~188 / ~195) on the subset of odd pages
that carry a **margin ornament** (rubʿ ۞ / juz / sajda), because that
ornament sits far out in the wide margin and stretches the frame bbox on one
side — which is itself confirmation that the ornament lives *in the margin*,
exactly where a mushaf puts it. The reliable signal is `md-page-inner`
(the 15 lines), and it is unambiguous.

---

## Verdict

**Category A — it is in the SVG path coordinates themselves — but it is
CORRECT, deliberate, and faithful to the printed muṣḥaf. It is NOT an error.**

- **Not B (layout metadata).** `md-page-inner data-rect` and every
  `mushaf_words` bbox faithfully report where the content actually is on each
  page. The one real metadata defect (the `x0,y0,x1,y1` vs `x,y,w,h` misread)
  was already fixed in M1; the metadata is now internally consistent.
- **Not C alone (renderer).** The renderer currently draws each page where
  its SVG places it. That honesty is *why* the shift reaches the screen — but
  the renderer isn't introducing it.
- **Not D (layer interaction).** Nothing is fighting anything; there are no
  transforms, no competing origins.
- **It is A, and intentional.** Every page shares one viewBox, one text
  width (~245), one frame width (~283), zero transforms, all geometry inside
  the canvas. The *only* thing that varies is the x-origin of the whole
  content block, by exactly the amount of a bound book's **recto/verso gutter
  margin** (inner/binding-side margin wider than the outer margin).
  MushafDatabase digitised each physical page preserving that asymmetry
  inside a common 382.68 × 547.09 canvas. Pages 1–2 differ only because
  al-Fātiḥa is a short, centred page in the print original too.

---

## Repair strategy — and what NOT to do

**Do NOT edit the 604 SVGs.** They are provably internally consistent and
faithful; re-centring them would be *destroying* accurate source data to
paper over a rendering choice.

**Do NOT add per-page `+X` / `-X` offsets in Flutter.** There is no
page-specific SVG defect to correct — the variation is systematic (gutter),
not per-page error.

**The fix is one uniform rendering rule (M3), no special cases:** instead of
`ScaleToFit`-ing the raw viewBox (which shows the page where the print places
it → the recto/verso jump), fit-and-**centre the per-page content region** in
the viewport. Two candidate regions, both uniform-width and already reliable:

1. `md-page-inner data-rect` (M1-corrected) — the 15-line text box, width
   ~245 ± 2. Centring this makes the text land identically on every page; the
   decorative border may then sit a hair off-centre / slightly cropped on the
   gutter side.
2. the `md-page-outer` frame bbox — width ~283, also uniform. Centring this
   keeps the border symmetric on screen, at the cost of a little more blank
   margin around the text.

Because both regions have a **uniform width across all 604 pages**, one
`ScreenTransform.fit(region)` handles every page — no `if (page == N)`, no
SVG change, no offset table. `_contentBox` was a rough approximation of
exactly this (its "force symmetric about the viewBox centre" step already
cancels *most* of the recto/verso shift — which is why the current build only
*wobbles* rather than jumping the full 46 units).

**Choosing between region 1 and 2 is the M3 decision — for Ismail, not to be
made here.**

---

## Test evidence already captured (M2, behaviour-preserving build)

Android emulator (`Medium_Phone_API_35`, 1080×2400), debug APK: mushaf reader
opens; pages 1 (al-Fātiḥa), 3 (recto), 4 (verso), 255 (recto, surah header +
basmala) all render correctly; a word tap on page 3 resolves to
`ٱللَّهُ — al-Baqara 7, word 2` with the gold highlight on the right glyph.
The residual recto/verso wobble is visible and is **unchanged by M2** (M2's
`ScreenTransform` reproduces the pre-M2 `_contentBox` transform bit-for-bit —
`test/screen_transform_test.dart`). It is a pre-existing property, to be
addressed by the M3 region-centring rule above.

---

## If the SVGs ever DO need changing (not now)

Only after proving a genuine per-page SVG defect would we touch the art, and
then: report the old + new `art_set_sha256`, the count and list of changed
files, the reason per group, and a fresh emulator visual pass — per Ismail's
instruction. `tool/mushaf_svg_qa.py` is the gate; re-run it after any change.
