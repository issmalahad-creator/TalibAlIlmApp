# Tajwīd rendering — analysis & re-architecture (2026-09-06)

Ismail's verdict on the Phase G-t3 build: the on‑page result is a
**rectangular‑highlight system**, not tajwīd typography. He is right. This
document is the audit he asked for before any more code: what exists, why it
looks wrong, and the glyph‑level architecture that replaces it.

---

## 1. Current tajwīd architecture (as shipped, `bc4bf5b` + `ce8becf`)

```
cpfair/quran-tajweed  (char offsets in a 2017 Tanzil file, CC BY 4.0)
        │  tool/build_tajweed_rules.py  — two‑stage normalised alignment
        ▼
assets/quran/corpus/tajweed.json.gz     {s,a,spans:[{w,cs,ce,r}]}
        │  QuranCorpusSync → quran_tajweed (DB v56), 1 row / ayah
        ▼
CorpusTajweedProvider  (KnowledgeGateway)      ← the knowledge surface reads this
QuranCorpusRepository.tajweedForAyah/ForWord   → AyahTajweed / TajweedSpan
        │
        ├─ knowledge_surface.dart  → family‑grouped list + «افتح الدرس»   (fine)
        │
        └─ ON‑PAGE  (the part being rejected):
             mushaf_semantic_reader_screen.dart
               _tajweedMode (pref) · _ensureTajweed(page) →
               buildTajweedPaintSpans(words × AyahTajweed × MushafWordGlyphs)
                 → List<TajweedPaintSpan>{ boxes:[MushafBox], color, underline }
             mushaf_page_view.dart  Stack:
               _PageArt  (the SVG, one flat picture)
               TajweedPageOverlay  ← IgnorePointer CustomPaint, draws RRects
               _SelectionOverlay
```

## 2. Current data source

- **`cpfair/quran-tajweed`**, pinned commit `496f71c`, rule DATA under
  **CC BY 4.0**. Char‑offset spans over a specific 2017 Tanzil Uthmani file.
- Remapped by `tool/build_tajweed_rules.py` onto our canonical
  `(surah, ayah, word_index)` + a **half‑open `[cs, ce)` char range in that
  word's own `text_uthmani` string** (diacritics included). Result:
  **6236/6236 ayāt clean, 0 flagged, 70 085 spans**
  (`docs/quran/reports/TAJWEED_ALIGNMENT_REPORT.md`).
- The span data is **already glyph‑precise** — `[cs, ce)` is exact to the
  codepoint. The precision loss is entirely downstream, in rendering.

## 3. Current rule taxonomy (what the source actually identifies — 18 ids)

| # | cpfair id | Arabic | notes on what it marks |
|---|---|---|---|
| 1 | `hamzat_wasl` | همزة الوصل | the ٱ that drops in continuation |
| 2 | `lam_shamsiyyah` | اللام الشمسية | the assimilated (silent) لـ of «الـ» |
| 3 | `silent` | حرف لا يُنطق | written, not pronounced (e.g. و in أُو۟لَٰٓئِكَ, صلة alifs) |
| 4 | `madd_2` | مدّ طبيعي (حركتان) | the natural 2‑count elongation letter |
| 5 | `madd_246` | مدّ عارض / لين | 2·4·6 at a stop |
| 6 | `madd_6` | مدّ لازم (٦) | obligatory 6‑count (e.g. الٓمٓ, ٱلضَّآلِّينَ) |
| 7 | `madd_muttasil` | مدّ متّصل واجب | madd + hamza, same word (4–5) |
| 8 | `madd_munfasil` | مدّ منفصل جائز | word‑final madd, next word hamza (4–5) |
| 9 | `ghunnah` | غنّة | نّ / مّ nasal hold |
| 10 | `qalqalah` | قلقلة | q ط b j d with sukūn — the bounce |
| 11 | `ikhfa` | إخفاء حقيقي | nūn‑sākinah hidden before 15 letters |
| 12 | `iqlab` | إقلاب | nūn → mīm before ب |
| 13 | `idghaam_ghunnah` | إدغام بغنّة | نْ/tanwīn merges (ينمو) with a hum |
| 14 | `idghaam_no_ghunnah` | إدغام بغير غنّة | نْ/tanwīn merges into ل / ر, no hum |
| 15 | `idghaam_mutajanisayn` | إدغام متجانسين | same‑makhraj pair (د/ت …) |
| 16 | `idghaam_mutaqaribayn` | إدغام متقاربين | near‑makhraj pair (ل/ر, ق/ك) |
| 17 | `ikhfa_shafawi` | إخفاء شفوي | mīm‑sākinah hidden before ب |
| 18 | `idghaam_shafawi` | إدغام شفوي | mīm‑sākinah merges into مّ |

**Not in the source (so we must NOT claim them):** إظهار (ḥalqī / shafawī /
muṭlaq) — cpfair marks these by the *absence* of a rule, not a span; and
**تفخيم / ترقيق** of ر and ل — no spans at all. The knowledge‑surface
curriculum (`tajweedTiers`) teaches those, but the on‑page layer cannot
colour them.

## 4. Current rendering method — and 5. why the rectangles happen

- **The page is one rasterised picture.** `_PageArt` →
  `SvgPicture.string(svg, fit: BoxFit.fill, colorFilter: night ? srcIn(ink))`.
  The whole MushafDatabase page SVG is parsed and painted as a single unit.
  Night mode recolours the *entire* picture with one `ColorFilter`. There is
  **no per‑glyph paint handle at render time.**
- **G‑t2 gave bounding boxes, not outlines.** `mushaf_glyphs` stores, per
  ligature / diacritic, an axis‑aligned `[x,y,w,h]` box. A box is a
  rectangle. Anything drawn from it is a rectangle.
- **`buildTajweedPaintSpans` then unions.** For each rule it takes the run of
  glyph boxes and `union`s them into **one** bounding rect, and
  `_TajweedPainter` fills that as a single `RRect` at α 0.24. So a rule that
  touches two glyphs becomes one block; a rule inside a 2–3‑letter ligature
  colours the whole ligature box; the α‑0.24 wash sits *over* the black ink
  like a text‑selection highlight.
- Net effect exactly as Ismail describes: `[ pink rect ][ black ][ purple rect ]`.

**The SVG itself is fully glyph‑structured** (verified): every glyph is a
discrete `<path id="md-path-{word}-{lig}[-{dia}]" data-type="text|diacritic|dots"
data-text="ٱ" | data-diacritic="kasra" d="…">`, **no `fill` attribute** (so
every path defaults to black), no `<style>`/`<defs>`/CSS. ~1008 paths/page.
45 % of `data-text` ligatures are a single letter, 26 % two, 17 % three.
→ **We can colour the real glyph outlines by setting `fill` on exactly those
`<path>` elements and rendering the modified SVG.** That is the fix.

---

## 6. Proposed glyph‑aware rendering architecture

Keep the data pipeline (§1 top) **unchanged** — it is already codepoint‑exact.
Replace only the on‑page renderer.

```
quran_tajweed  (AyahTajweed / TajweedSpan  — [cs,ce) per word, EXACT)
        +
mushaf_glyphs v2   ← re‑extract: each glyph keeps its  <path> id  + kind + [cs,ce)
        │
        ▼
TajweedSvgPainter (pure, per page, in the decode isolate):
   for each rule span on the page:
     resolve [cs,ce) → the set of <path> ids it covers
       · a diacritic path is coloured iff its codepoint index ∈ [cs,ce)
       · a base ligature path is coloured iff [cs,ce) overlaps the
         letters it draws  (whole‑ligature when the rule is a strict
         subset of a multi‑letter ligature — documented limit, ~1 in 3
         spans, still a glyph not a word)
   emit a *modified SVG string*: inject  fill="#RRGGBB"  on those paths;
   inject a default  fill  on every OTHER path so night mode still works
   WITHOUT the wholesale ColorFilter (which would erase the tajwīd colours).
        │
        ▼
_PageArt renders the modified string when tajwīd mode is ON, the original
when OFF.  ONE SvgPicture, no overlay, no CustomPaint, no rectangles.
```

Consequences:
- **Colour is on the ink**, following the exact glyph boundaries the
  typesetter drew. Black text stays black; only rule glyphs change hue.
- **No second layer.** `TajweedPageOverlay` / `TajweedPaintSpan` /
  `buildTajweedPaintSpans` are deleted. `mushaf_page_view.dart` loses its
  extra `Positioned.fill`.
- **Night mode** = inject `fill="#E9E1D2"` as the base instead of the
  `srcIn` filter, tajwīd glyphs keep their (night‑tuned) hue.
- **Performance**: the SVG string is already re‑parsed every page turn
  (~200 KB, ~1000 paths). The transform is one regex pass over the string in
  the **same `compute` isolate** that already gunzips it — no new isolate,
  no per‑glyph widgets, no gesture recognisers. Cache the modified string in
  `MushafPageCache` keyed by `(page, tajwīdMode, night)`.
- **Interaction** stays exactly as today: the page‑level hit‑test
  (`layout.wordAtPoint`) is untouched; tapping a coloured glyph selects its
  word and the caption shows the rule name. No per‑glyph recognisers.
- **Sub‑ligature precision** (the ~1/3 multi‑letter case): acceptable for v1
  (colour the ligature). If Ismail wants true per‑letter later, the path‑`d`
  can be split at the letter boundary using the per‑glyph boxes — a separate,
  heavier follow‑up, not v1.

## 7. Proposed colour system — a Quran‑reading palette, not Material

Designed from the **Dar al‑Maʿrifah / King Fahd Complex** coloured‑muṣḥaf
tradition, muted for long sessions, one hue per *sound behaviour* (not 18
hues). Every hue is a low‑chroma, mid‑value tone that reads as "ink that
happens to be coloured", never as a marker. Dark‑theme values are separate,
lifted for the dark ground.

| Category (cpfair ids) | Light | Dark | Rationale | Example |
|---|---|---|---|---|
| **المدّ** — `madd_2` `madd_246` `madd_6` `madd_muttasil` `madd_munfasil` | `#A63D2E` muted brick‑red | `#E08A73` | Madd is red in every printed tajwīd muṣḥaf; softened from fire‑red so it doesn't vibrate against black. All madd share one hue — the *length* is a lesson, not a colour. | ٱلرَّحۡمَ**ٰ**ن · ٱلضَّ**آ**لِّين |
| **الغُنّة والإدغام بغُنّة** — `ghunnah` `idghaam_ghunnah` `iqlab` | `#1F7A6B` deep teal‑green | `#5FC2AE` | All three hold a nasal hum in the خيشوم; green = the classic إخفاء/غنّة family colour. | إِنَّ · مِن نِّعۡمَة · مِنۢ بَعۡد |
| **الإخفاء** — `ikhfa` `ikhfa_shafawi` | `#2E6F4E` forest‑green (a shade darker than غنّة) | `#66B98A` | Same green family (also a hum) but distinct value so إخفاء ≠ غنّة at a glance. | مِن**تَ**حۡتِهَا · تَرۡمِيهِم **بِ**حِجَارَة |
| **القلقلة** — `qalqalah` | `#25506E` deep muted blue | `#6FA8CE` | The "bounce" — a percussive, contained sound; blue reads as a beat, not a stretch. Dar al‑Maʿrifah uses blue for qalqalah. | أَحَ**دْ** · ٱقۡ**رَ**أ |
| **الإدغام بغير غُنّة والمتماثل/المتجانس/المتقارب** — `idghaam_no_ghunnah` `idghaam_mutajanisayn` `idghaam_mutaqaribayn` | `#5B6570` slate‑grey (receding) | `#9AA4B0` | These letters **disappear** into the next; grey = "this letter steps back". | مِن رَّبِّهِم · قَد تَّبَيَّن |
| **الحرف الذي لا يُنطق** — `silent` `hamzat_wasl` `lam_shamsiyyah` | `#8A8072` warm stone‑grey (lighter, quieter than إدغام grey) | `#B9AFA0` | Written but silent — the faintest tone, so the eye skips it the way the tongue does. | **ٱ**للَّه · وَأُو**ْ**لَٰٓئِك · **ٱل**شَّمۡس |

7 hues, 3 grey‑adjacent tones separated by *value* so they survive
colour‑blind viewing (a deuteranope sees red‑vs‑greens‑vs‑blue‑vs‑greys as 4
distinct lightness bands). If a CVD check still fails, the fallback is a
1 px dotted underline on the two greys, **not** more colours.

`izhar` and `tafkhīm/tarqīq` get **no colour** — the source doesn't mark
them; claiming them would be inventing data.

## 8. Proposed legend — a collapsed chip that opens a sheet

- On the page: a single small pill in the bottom bar — `تجويد ▾` — not the
  6‑swatch strip. It shows only while tajwīd mode is on.
- Tap → a `DraggableScrollableSheet` (same language as the Knowledge
  Surface): each category = its swatch · Arabic name · one‑line definition ·
  a real Quranic example rendered in the muṣḥaf font with the rule glyph in
  its colour · «افتح الدرس» → `TajweedTierScreen` where a lesson exists.
- Grouped: المدّ · الغُنّة والإخفاء والإدغام بغُنّة · القلقلة · الإدغام · حرف
  لا يُنطق. Collapsible, scrollable, dismissible. Zero permanent screen cost.

## 9. Validation strategy

**Data / mapping (unit):**
- `tajweed_rules_sync_test` (exists) — 6236 coverage, every `[cs,ce)` in
  bounds, every id known. Keep.
- `tajweed_alignment_golden_test` (exists) — al‑Fātiḥa + al‑Baqara 1–5,
  hand‑verified `(word,rule)`. Keep.
- **NEW** `tajweed_svg_paint_test` — for a set of hand‑checked ayāt, run the
  SVG transform and assert: (a) the expected `md-path-*` ids got a `fill`,
  (b) **no other** path got one, (c) diacritic paths coloured only when
  their codepoint ∈ span, (d) turning mode off yields a byte‑identical SVG
  to the bundled one.
- **NEW** `tajweed_svg_paint_604_test` — over all 604 pages: transform never
  throws, never injects a malformed attribute, never touches a
  non‑`md-path` element, output still parses (`<svg` present, path count
  unchanged).

**Visual (device, before "done"):**
- Screens at 2–3× zoom of: al‑Fātiḥa p1 (madd, hamzat waṣl, lām shamsiyyah,
  the 6‑count in ٱلضَّآلِّين); a qalqalah page; a page dense in إخفاء/إدغام;
  a page with الٓمٓ‑type muqaṭṭaʿāt. Check per screenshot:
  1 rule glyph coloured, 2 its marks the same colour, 3 neighbours black,
  4 shadda/sukūn/madd marks intact, 5 ayah medallions + waqf glyphs
  untouched, 6 baseline/line‑spacing unchanged, 7 **no rectangle anywhere**,
  8 black text still dominant, 9 tap selects the word normally,
  10 toggle off → pixel‑identical to plain reading.
- Night mode repeat.
- Scroll 10 pages with mode on — no jank (the transform is in the decode
  isolate; page‑turn cost unchanged).

**Sign‑off:** not "it looks prettier" — the checklist above, with screenshots
in this doc.

---

## Addendum (2026-09-06) — what shipped, and the whole-word-ligature finding

During the build the SVG structure turned out worse than §5 assumed:
MushafDatabase's "Ligature-Based" SVG draws **2–10 letters — often a whole
word — as ONE `<path>`** (`«لعلمين»`, `«لمستقيم»`, `«ينفقو»`). Only **36 %**
of tajwīd-hit base glyphs are a single-letter path. So "inject `fill` on the
base path" would colour whole words. There is **no per-letter path** on this
art.

A spike passed (pixel-tested): flutter_svg honours `fill` inherited from
`<g id="md-page">` with per-`<path>` override. So the shipped renderer
(`lib/services/mushaf/tajweed_svg.dart`) does:

1. **Direct `fill`** on the exact `<path>` — every covered **diacritic**
   glyph (wasla, maddah, shadda, superscript-alef, tanwīn, sukūn…) and
   every **single-letter** base ligature. **≈ 80 % of spans. Fully
   precise.**
2. `lam_shamsiyyah` also colours the following shadda (the assimilation) —
   render-time, span data untouched.
3. A rule that lands **only inside a whole-word ligature with no diacritic
   anchor** (≈ 20 %, much of `madd_246` at verse ends, some `madd_2`) is
   **not coloured on the page** — it stays black, and is shown in the
   knowledge surface + on tap. Every skip is counted in the coverage
   report — never a silent gap. (A clip-path x-slice "band" was tried and
   dropped: on a calligraphic word-ligature it renders as a faint
   baseline stroke, an artefact, not a coloured letter — Ismail's call.)

Base ink moves to `<g id="md-page" fill>` (replaces the night `ColorFilter`).
Runs in `MushafPageCache`'s `compute` isolate, cached per `(page, night)`.
`TajweedPageOverlay` / `TajweedPaintSpan` / `buildTajweedPaintSpans` deleted.

**Coverage (all 604 pages, generated by `tajweed_svg_paint_604_test`):**
`docs/quran/reports/TAJWEED_GLYPH_COVERAGE.md` — DIRECT / BAND / SKIPPED per
rule + band examples.

**Name:** *Glyph-level Tajwīd rendering with documented ligature fallback.*
Not "per-letter precision" — v3 needs a different art source or an in-app
Arabic-shaping renderer.

## Build order

1. `tool/extract_mushaf_glyphs.py` → also emit each glyph's `<path>` id
   (`md-path-{o}-{lig}[-{dia}]`) + kind + `[cs,ce)`; `mushaf_glyphs.json.gz`
   v2, re‑seed (still one row/page, no `kMushafLayoutVersion` bump).
2. `lib/theme/tajweed_palette.dart` → the 7‑category system above (light +
   dark), replacing the 6 Material families. `tajweed_rules_ref.dart` →
   remap 18 ids to the 7 categories.
3. `lib/services/mushaf/tajweed_svg.dart` → `paintTajweedIntoSvg(svg,
   pageGlyphs, pageSpans, {night}) → String` (pure, isolate‑safe).
4. `MushafPageCache` → key by `(page, mode, night)`; run the transform in
   `_decode`'s existing `compute`.
5. `mushaf_page_view.dart` / `_PageArt` → render the painted string; **delete**
   `TajweedPageOverlay`, `TajweedPaintSpan`, `buildTajweedPaintSpans`, the
   extra `Positioned.fill`, the `tajweedSpans` param.
6. `mushaf_semantic_reader_screen.dart` → drop `_tajweedCache` of paint
   spans; pass `tajweedMode`/`night` down; legend pill → bottom sheet.
7. Tests §9 + docs (`QURAN_PREMIUM_UI.md` §8‑bis rewritten for glyph
   colouring, `QURAN_INTERACTION.md` §8, `KNOWLEDGE.md` R‑14, this file's
   validation section filled with screenshots).
