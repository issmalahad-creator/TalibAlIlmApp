# Mushaf Engineering — the printed Madani mushaf, and how to represent it

Tags: see `SOURCES.md`.

---

## 1. What "Mushaf al-Madinah" is  (`SOURCE-BACKED`, cross-checked)

- Hand-written in full by calligrapher **Uthman Taha**; published by the
  **King Fahd Complex** (est. 1984–85, Madinah). Riwāya **Hafs ʿan ʿĀṣim**.
- **604 pages, 15 lines/page.** > 128 million copies distributed.
- **Three master calligraphy editions**: 1405H (1984), 1422H (2001),
  1439H (2017). Each is a fresh hand-copy; changes = less letter stacking,
  better spacing, hand-written margin notes. QUL tracks QCF layout
  generations as **V1 (1405H), V2 (1421H), V4 (1441H)**.
- **Defining layout property:** every page **starts** a new ayah and
  **ends** on an ayah boundary. Deliberate — it's what makes page-by-page
  ḥifẓ and page-position visual memory work.
- Consequence: line breaks are **not** uniform; each line's words are
  **stretched or compressed** (curvilinear letter extension, not straight
  kashida) so the line fills edge-to-edge and the page ends cleanly.

**Rule:** "the Madani mushaf" is **not one fixed pixel layout** — it is an
edition family. Always pin *which* edition/file a layout came from.

---

## 2. Anatomy of a page

```
page frame (md-page-outer): decorative border, page number (bottom, centred),
   surah name (top corner), juz name (top corner),
   margin marks: juz start, hizb / rub-el-hizb (۞), sajda (۩), sakta
content box (md-page-inner, data-rect): the 15 lines
   line: one of
     - text        : justified edge-to-edge; a run of words + aya-marks
     - surah-name   : centred ornamental banner (surah header)
     - bismillah    : centred بسم الله الرحمن الرحيم (every surah except at-Tawba)
     - empty        : blank (e.g. spacing lines on pages 1–2)
```

`VERIFIED` (MushafDatabase + quran.ai `fetch_mushaf` page 2): early pages
reserve lines for the header, so text can start on line 8, 10, … — the line
number where surah text begins is **edition-specific and per-page**, never
assume line 1.

Each page carries a **surah-header record**: which surah begins, whether a
bismillah precedes it, and before which line the banner sits.

---

## 3. Layout data model  (mirrors QUL; ours = `mushaf_*` tables)

| table | grain | key fields |
|---|---|---|
| `mushaf_pages` | page | `page`, `rect_*`, `vb_w/vb_h`, `line_count`, `surah_first/last`, `ayah_first/last`, `word_count` |
| `mushaf_lines` | line | `page`, `line` (1..15), `line_type ∈ text\|surah-name\|bismillah\|empty` |
| `mushaf_words` | word | `page`, `line`, `word_order` (1..N reading order), `surah`, `ayah`, `word_index` (1-based in ayah), `word_type ∈ text\|juz-star\|sajda-mehrab`, `text_uthmani`, `text_imlaey`, `bbox_*` |
| `mushaf_aya_marks` | ayah | `(surah, ayah)` PK, `page`, `line`, `bbox_*` (nullable) |
| `mushaf_markers` | misc | `page`, `kind ∈ sajda\|juz-hizb\|surah-header\|bismillah`, `line?`, `surah?`, `bbox_*` |
| `mushaf_meta` | kv | `layout_version`, `source`, `seeded_at_ms`, `words`, `aya_marks` |

QUL's canonical render loop, adapted: for each `text` line, take its words
in `word_order`; for `surah-name`/`bismillah` lines, render the centred
element; skip `empty`.

---

## 4. What layout data CAN tell you  (`VERIFIED`)

- which `(surah, ayah, word_index)` a given screen point is over (via bbox hit-test);
- the full set of ayat on a page, in reading order;
- which line(s) an ayah occupies, and the union box per line (for highlight);
- where a surah starts / where a bismillah / juz mark / sajda mark sits (position);
- the page an ayah is on (from its aya-mark);
- page ↔ ayah ranges (for ḥifẓ page units).

## 5. What layout data CANNOT tell you  (do not infer)

- **The recited text.** Reconstructing Quran text by reading glyphs off the
  page is forbidden (`ERRATA` E‑1 rationale). Text identity comes from
  `text_uthmani` (a data field), verified against Tanzil.
- **Juz / hizb / ruku numbers** — not in the MushafDatabase SVG. Only the
  *ornament position* is there. Numbers come from `quran_ayat`.
- **The surah a header introduces** — the header line has no `data-surah`;
  we **infer** it (first following ayah-1 word). `INFERENCE`, flag as such.
- **Tajweed rules** — not in layout data. Separate dataset, bound to a
  specific text edition (`SOURCES.md` §9).
- **Pause (waqf) semantics** — MushafDatabase marks *waqf glyph positions*
  (`data-waqf` on paths); the *meaning* (lāzim vs jāʾiz vs …) and especially
  the IndoPak↔Madani inversion of لا must come from a rules table, not
  guessed from the glyph.
- **Word timing for recitation** — external, per-reciter (`SOURCES.md` §8).
- **Cross-edition equivalence** — a bbox/polygon from one edition's
  coordinate system is meaningless in another's without a transform
  (MushafDatabase 382.68×547.09 vs quranpedia 345×550).

---

## 6. Rendering the visual — the two valid strategies  (`SOURCE-BACKED`)

There are exactly two ways serious projects get pixel-perfect print fidelity:

### A. Per-page ligature font (QCF / QPC)
- Each **glyph = an entire word**; a word is shaped differently on different
  pages to justify its line → **604 separate fonts**, one per page.
- A page render = a string of PUA code points fed to *that page's* font.
- You **cannot restyle** it with another font. Load current + prev + next
  page fonts only.
- We do **not** have these fonts (KFGQPC licence).

### B. Ligature-based SVG (MushafDatabase)
- One standalone SVG per page; glyphs are **vector paths**; semantic groups
  for line / word / ligature / diacritic / aya-mark.
- Gives the exact visual **and** machine addressing in one artifact.
- Cost: large (~380 MB raw for 604). Needs lossless compression
  (`gzip` ≈5×, `xz` ≈8×) + lazy load, or on-demand download + cache.
- **This is our path.** Render the real SVG; overlay invisible bboxes for
  interaction (see `QURAN_INTERACTION.md`).

### Not valid: generic font + runtime justification
- HarfBuzz (standard shaper) does **not** insert kashida for justification;
  only LibreOffice does. Mark positioning in fully-vocalised Quranic text is
  a documented unsolved problem (Amiri devs note erroneous tatweel in full
  justify). DigitalKhatt's curvilinear stretching needs its LuaLaTeX
  typesetter + forked HarfBuzz, not a plain `.otf` in a Flutter `Text`.
- `ERRATA` E‑1: we tried "substitute font at glyph bboxes" — it produced
  garbled, overlapping text. Never again.

---

## 7. Size handling for the SVG art  (`SOURCE-BACKED` compression ratios, measured on `003.svg`)

| method | ratio | 604 pages ≈ |
|---|---|---|
| raw | 1× | 380 MB |
| gzip -9 | ~5× | ~76 MB |
| brotli | ~6× | ~55 MB |
| xz / lzma | ~8.3× | ~46 MB |

All **lossless** — nothing deleted, every path and glyph preserved. Ismail's
constraint ("no lossy shrinking") is satisfied by any of these. Decision
between *bundle compressed* vs *download-per-page + cache* is Ismail's
(APK size vs first-view network). Not yet made — `UNKNOWN`.

---

## 8. Divisions marked in the mushaf  (`SOURCE-BACKED`)

- 30 **juzʾ** · 60 **ḥizb** · 240 **rubʿ el-ḥizb** (the ۞ flower, ¼ ḥizb) · 7 **manzil** · ≈ 540–558 **rukūʿ**.
- Madani mushaf marks **8 sub-points per juzʾ** (the rubʿ flowers); IndoPak marks 4 + rukūʿ (topic units, ع).
- Sources for numbers: `quran_ayat` (`juz_number`, `hizb_number`) + Tanzil `quran-data.js` (HizbQuarter, Sajda, ruku counts). MushafDatabase gives only the **positions** of the ornaments.

## 9. Sajda (sujūd al-tilāwa)  (`SOURCE-BACKED`)

- **15** sajda verses in the text; **14 agreed** by all; the 15th disputed.
- Legal status: **wājib (Hanafī)**; **sunna muʾakkada (Mālikī, Shāfiʿī, Ḥanbalī)**.
- Shāfiʿī list differs: **excludes Ṣād 38:24**, **includes the 2nd sajda of al-Ḥajj 22:77**.
- Our data: `quran-data.js` Sajda array (Tanzil) + MushafDatabase `md-word[data-type=sajda-mehrab]` (15 tokens) + margin `sajda` markers. `VERIFIED` count 15.
- **Rule:** if we ever surface "is this a sajda ayah / obligatory?", the
  madhhab matters — store the verse list + a per-madhhab flag, don't
  hard-code one school.

## 10. Waqf (pause) marks  (`SOURCE-BACKED`)

Madani set (King Fuʾād I committee): **مـ** lāzim (must stop) · **ط** muṭlaq
· **ج** jāʾiz · **قلى** waṣl-permitted-stop-better · **صلى** waqf-permitted-
continue-better · **قف** · **س / ۜ** sakta · **لا** do NOT stop ·
**∴ … ∴** muʿānaqa (stop at one of the pair only).

**Danger (`VERIFIED`, MuslimMatters):** **لا** = "do not stop" in the Madani
mushaf but "**you must stop**" in the IndoPak/Sajāwandī system. The single
most dangerous cross-edition confusion — never render/explain a waqf glyph
without knowing the mushaf's waqf tradition.

MushafDatabase encodes `data-waqf` ∈ {lāzim, jāʾiz, ṣali, qila, taʿānuq} at
path level. We do not yet consume it.

---

## 11. Engineering checklist — before touching mushaf rendering/layout

1. **Which source dataset?** (MushafDatabase V1.01 for our semantic layer.)
2. **Which mushaf edition/version?** (Madani; MushafDatabase V1.01; not KFGQPC V1/V2/V4 fonts.)
3. **Which coordinate system?** (viewBox `0 0 382.68 547.09`, `xMidYMid meet`.)
4. **Semantic layer or rendering layer?** Keep them separate; the DB schema must not encode a rendering choice.
5. **Never** reconstruct Quran text from visual geometry.
6. **Never** infer ayah identity from page position when `(surah, ayah)` is in the data.
7. **Never** carry a bbox/polygon across editions without an explicit coordinate transform.
8. Juz/hizb/ruku/sajda **numbers** → `quran_ayat`; the mushaf gives **positions** only.
9. If comparing texts, normalize both with the same function; never eyeball rasm.
10. Log anything surprising into `ERRATA.md` with cause + new rule.
