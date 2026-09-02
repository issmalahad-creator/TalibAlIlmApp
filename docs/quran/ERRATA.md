# Quran Engineering — Mistakes & Corrections Log

When something Quran/mushaf-related went wrong, record it here so a month
later we don't restart from zero. Format per entry:

- **Mistake** — what was done/assumed
- **Correct understanding** — what's actually true
- **Cause** — why the mistake happened
- **New engineering rule** — the durable fix (also mirrored into `.claude/skills/quran-engineering/SKILL.md`)
- **Source** — evidence

---

## E‑1 · Rendered Quran text with a substitute font at glyph bounding boxes

- **Mistake:** For the `79-mushaf` reader (`MushafPageView`), the 380 MB of
  MushafDatabase SVG *art* was dropped to save APK size; the visual was
  "reconstructed" by drawing each word's `data-hafs` string in
  `DigitalKhattMadina` inside that word's **bbox** (which came from the
  original glyph's vector outline), scaled with `FittedBox`.
- **Result:** garbled, overlapping, staggered text — alarming for the Quran.
- **Correct understanding:** a word's bbox describes **that dataset's own
  glyph shapes only**. A different font has different widths, ligatures,
  kerning and mark stacking, so it will not fit the box. `FittedBox`
  additionally scales every word independently → inconsistent glyph sizes.
  Bounding boxes are for **hit-testing and highlight geometry over the real
  page art**, never for laying out substitute glyphs.
- **Cause:** over-optimising for APK size; treating a semantic-extraction
  artifact as if it were a rendering artifact.
- **New engineering rule:**
  1. The mushaf **visual** is the real page art (MushafDatabase SVG paths,
     rendered as SVG) or a per-page QCF font — nothing else.
  2. bboxes are an **invisible interaction overlay** on top of that art.
  3. Never render `text_uthmani` / `data-hafs` in an arbitrary font at
     data-derived boxes.
  4. Don't judge a dataset by a failed rendering shortcut — the
     MushafDatabase *data* extraction was correct and verified (604 pages,
     6236 ayat, 114 surahs matching canonical counts); only the render
     approach was wrong.
- **Source:** device screenshot 2026‑08‑29; `SOURCES.md` §3/§10; HarfBuzz +
  Amiri justification notes.

## E‑2 · (Rule) Inferring ayah identity from page position

- **Mistake pattern:** resolving "which ayah did the user mean" from where
  they tapped, when the underlying data already carries `(surah, ayah)`.
- **Correct understanding:** the tap is only a *query*. Once `wordAtPoint`
  returns a `MushafWord`, its `(surah, ayah, word_index)` **is** the
  identity — exact, from data.
- **Cause:** carrying a "screen-coordinates" mental model from generic UI.
- **New engineering rule:** never infer ayah/word identity from geometry
  when a semantic identity exists in the data. Geometry in → identity out →
  discard the geometry.
- **Source:** `QURAN_INTERACTION.md`; design constraints Ismail set for
  79‑mushaf ("word→ayah from data, not screen coords").

## E‑3 · 150 per-word GestureDetectors for tap targeting

- **Mistake:** the earlier own-engine reader put a `GestureDetector` per
  word for the ayah menu.
- **Correct understanding:** they did **not** respond to synthetic
  `adb input tap` (couldn't verify on device) and add layout cost. One
  page-level `GestureDetector` + a geometric hit-test against stored bboxes
  is reliable and testable.
- **Cause:** treating each word as an independent widget instead of a
  hit-test region.
- **New engineering rule:** one page-level hit-test; word `Positioned`s are
  `IgnorePointer`. `MushafPageLayout.wordAtPoint` is the single resolver.
- **Source:** 79‑mushaf work; `mushaf_page_view.dart` comment.

## E‑4 · Turath highlight saved only the first word when the selection had a space

- **Mistake:** `_startHighlight` passed `selection.start/end` and re-sliced
  `_normText`. When `editableTextState.textEditingValue.text != _normText`
  (any span injecting characters, or a stale value), the substring
  truncated at the first space.
- **Correct understanding:** `selected_text` must be captured as the
  **verbatim string** from `selection.textInside(value.text)` and stored as
  the source of truth; the numeric offset is only a *locate hint*, verified
  by `text.substring(hint, hint+len) == selected` else `indexOf` nearest.
- **Cause:** assuming the flattened span text always equals the reference
  normalized string.
- **New engineering rule (Turath, but the principle is general):** the
  **verbatim selected text** is authoritative; offsets are hints to be
  re-verified. For **Quran**, this doesn't even arise — the anchor is
  `(surah, ayah[, word range])`, numeric, no text slicing.
- **Source:** `study_annotation_anchor.dart` + repo `_anchorFields`;
  Ismail's device report ("أول كلمة فقط عند وجود فراغ").

## E‑5 · Catastrophic regex backtracking in page-text normalization

- **Mistake:** `normalizePageText` used `RegExp(r' *\n *')` and `<[^>]*>`.
  On long space runs / unclosed `<`, these are O(n²) — measured 5.9 s on 20k
  spaces — running synchronously in `setState`, hanging the reader on a
  spinner.
- **Correct understanding:** use literal-string `replaceAll` + a linear
  `_stripTags` scanner (`if (!s.contains('<') || !s.contains('>')) return s;`
  then `indexOf`-based). Bumped `kNormVersion` 1→2 (re-anchors on next open).
- **Cause:** convenience regex on untrusted long input on the UI thread.
- **New engineering rule:** no unbounded/backtracking regex on page-sized
  text on the main thread; prefer linear scanners; version the normalizer
  and re-derive anchors when it changes.
- **Source:** Ismail's device report ("لا يفتح اي صفحه ... فقط يدور
  التحميل"); regression perf test added.

## E‑6 · Search normalizer deleted an omitted-alif and missed U+0653

- **Mistake:** an earlier `normalizeArabicForSearch` deleted the dagger
  alif in *all* cases — so genuinely-omitted-alif words (ٱلظَّـٰلِمِينَ)
  became `الظلمين` and never matched a plainly-typed `الظالمين`. It also
  didn't strip U+0653 MADDAH ABOVE, so `الفقراء` (spelled with U+0653 in
  Tanzil) was unsearchable.
- **Correct understanding:** dagger alif has ≥4 roles (waw+dagger → ا;
  maqṣūra+dagger → ى; a closed everyday-word set → drop; **everything else →
  restore a real ا**). The mark-stripping range must include U+0650–0655.
- **Cause:** treating one Unicode mark as having one meaning; guessing the
  strip range instead of verifying against the actual bundled text.
- **New engineering rule:** verify normalization casework against **every
  distinct form in the actual corpus file**, not a sample; document the
  casework inline; when a mark is polysemous, enumerate its roles.
- **Source:** `lib/utils/arabic_normalize.dart` (inline comments, "verified
  against ~2650 forms").

## E‑7 · A tafsir edition imported with 156 empty ayahs

- **Mistake:** an early `ibn_ashur` import produced 156 empty-text rows; the
  self-heal loop only re-imports a source with **zero** rows, so it would
  never repair a partially-bad edition.
- **Correct understanding:** per-edition self-heal must detect a *marker of
  the bad version* (here: `text = ''`) and delete+re-trigger, not gate on
  "table empty".
- **Cause:** all-or-nothing import guard.
- **New engineering rule:** importers self-heal per source with a concrete
  bad-data marker, not just a row-count check.
- **Source:** `QuranImportService` (inline comment, 2026‑08‑18 repair).

## E‑8 · (Rule) Three version counters are independent

- **Mistake pattern:** conflating `kNormVersion` (Turath page-text anchor
  normalizer), `kMushafLayoutVersion` (the extracted `mushaf_layout.json.gz`
  asset), and the un-versioned `normalizeArabicForSearch`.
- **Correct understanding:** three different normalizations, three purposes,
  three lifecycles. Bumping one does nothing to the others.
- **New engineering rule:** name the exact normalizer/version when
  discussing "the normalized text"; never assume a shared version.
- **Source:** `study_annotation_anchor.dart`, `mushaf_layout.dart`,
  `arabic_normalize.dart`.

## E‑9 · Nearly abandoned the right dataset after a rendering failure

- **Mistake:** after E‑1, treated "switch the Quran source" as a live option.
- **Correct understanding:** MushafDatabase V1.01 is the correct source —
  the only one giving both the real Madani visual **and** word-level
  `(surah, ayah, word_index)` under an open commercial licence. `svg2/`
  (quranpedia) has **no text glyphs** and never will; `svg/` is frame art.
  The failure was the render shortcut, not the data.
- **Cause:** conflating "the render is broken" with "the data is wrong".
- **New engineering rule:** separate *data correctness* (validate against
  canonical counts / Tanzil) from *rendering correctness* (a visual QA).
  A bad render never condemns validated data.
- **Source:** this conversation, 2026‑08‑29; `SOURCES.md` §3/§4.
