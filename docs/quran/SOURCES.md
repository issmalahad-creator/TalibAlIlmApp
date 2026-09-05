# Quran & Mushaf — Source Register

Every external dataset, spec, font, or project that informs Quran/mushaf work
in TalibAlIlmApp. For each: what it is, its licence, **what we use it for**,
and **what we must NOT assume from it**.

> This file covers **text + layout** sources. The **teaching-content**
> sources (morphology, iʿrāb/syntax, tajwīd rule sets, tafsīr editions,
> word-meaning, hadith links) for the Quran Learning Engine live in
> **[`docs/QURAN_SOURCES_AND_LICENSES.md`](../QURAN_SOURCES_AND_LICENSES.md)**,
> together with the `CLAIM → APPROVED` provenance pipeline and the
> `CONFLICT` register. Architecture:
> [`docs/QURAN_LEARNING_ARCHITECTURE.md`](../QURAN_LEARNING_ARCHITECTURE.md).

Knowledge tags used across `docs/quran/`:

| tag | meaning |
|---|---|
| `VERIFIED` | cross-checked against this project's actual files/data, or ≥2 authoritative sources agree |
| `SOURCE-BACKED` | one authoritative external source states it; not independently re-verified here |
| `PROJECT-SPECIFIC` | true for *this* codebase's schema/decision, not a general Quran fact |
| `INFERENCE` | my synthesis/reasoning — **never** a basis for changing Quran text or mushaf data |
| `UNKNOWN` | identified gap; needs research or Ismail's input |

---

## 1. Tanzil Project — Quran text + metadata  ·  **USED (core)**

- **URL:** https://tanzil.net/ · text licence: https://tanzil.net/docs/text_license
- **Version:** text **v1.1 (Feb 2021)**; metadata `quran-data.js` "ver 1.0" (2008–2009 header).
- **Files in repo:** `assets/quran/quran-uthmani.txt` (`S|A|text` lines, Uthmani), `assets/quran/quran-data.js` (Sura/Juz/Page/HizbQuarter/Sajda arrays).
- **Licence:** **Creative Commons Attribution 3.0**. Conditions confirmed 2026‑08‑15: (1) **no modification** of the text, (2) visible attribution to "Tanzil.net" + link. A single "About sources" screen satisfies attribution.
- **What it contains:** the full Hafs Uthmani text (6236 ayat), plus structural boundary tables — juz (30), page (604), hizb-quarter (240), sajda list, sura metadata (start index, ayah count, revelation order, ruku count, name, type Meccan/Medinan).
- **What we use it for:** the `quran_ayat` table (`text_uthmani`, `text_normalized`, `juz_number`, `page_number`, `hizb_number`), `memorization_units` (604 page ranges), verse search, ayah display, the Ayah Notebook anchor `(surah, ayah)`.
- **What we must NOT assume:**
  - `PROJECT-SPECIFIC` Tanzil's `page` array is **one specific page scheme** (Madani 604). It is **not** guaranteed to be byte-identical to MushafDatabase's page/line placement — both are "604 Madani" but they are different editions of the layout. Never assume a Tanzil page's ayah set equals a MushafDatabase page's ayah set without checking. `INFERENCE`: in practice they align at the page level for standard Madani, but line placement differs (see MushafDatabase note).
  - Tanzil's word tokenisation = **split on spaces**. This is *a* segmentation, not "the" segmentation. MushafDatabase segments differently (ornaments ۞ ۩ are indexed words; some particles split). Do not equate a "Tanzil word index" with a "MushafDatabase `word_index`".
  - The text is **Uthmani rasm+dabt** — it is not the imlaei/simple form and must never be normalised for display.
  - `quran-data.js` sura names are **mojibake in the file** (Latin‑1 view of UTF‑8); the project uses `lib/data/quran_surahs.dart` for names instead.

## 2. King Fahd Complex (KFGQPC / مجمع الملك فهد)  ·  reference

- **URL:** https://qurancomplex.gov.sa/ · computer-typesetting division: https://nashr.qurancomplex.gov.sa/
- **What it is:** the publisher of the canonical **Mushaf al-Madinah** (Uthman Taha calligraphy, 604 pages, 15 lines, Hafs). Also publishes machine-readable Quran text (CSV/HTML/JSON/SQL/XLSX/XML) and the **KFGQPC Uthmanic Script HAFS** font and the per-page **QCF/QPC** glyph fonts.
- **Version:** three master calligraphy editions — **1405H (1984)**, **1422H (2001)**, **1439H (2017)**. QCF layout generations tracked by QUL as **V1 (1405H)**, **V2 (1421H)**, **V4 (1441H)**.
- **Licence:** `SOURCE-BACKED` KFGQPC masahif permit free non-commercial *digital* use; **commercial physical printing is reserved to the Complex**. The KFGQPC Uthmanic Hafs font is © KFGQPC 2010 with its own EULA — **the project does NOT bundle it** (CLAUDE-noted: its licence forbids redistribution without written approval). Digital-Khatt and Amiri are used instead.
- **What we use it for:** the *reference standard* the whole mushaf layer targets (604/15/Hafs/page-ends-on-ayah). Not a file dependency.
- **What we must NOT assume:** we may **not** ship the KFGQPC font or QCF per-page fonts. The three calligraphy editions differ in line placement — "the Madani mushaf" is not one fixed layout.

## 3. MushafDatabase — Ligature-Based SVG **V1.01**  ·  **USED (phase 79-mushaf)**

- **URL:** https://github.com/mushafdatabase/MushafDatabase-Ligature-Based-SVG · site: https://mushafdatabase.com/ · publisher: Altara Innovation Group.
- **Local path (git-ignored build input):** `MushafDatabase-Ligature-Based-SVG-main_2/MushafDatabase-Ligature-Based-SVG-main/SVG V1.01/` (604 `.svg`, ~380 MB).
- **Version:** **V1.01** (`data-md-version="1.01"`). V1.01 changelog vs V1.0: fixed mislabeled kasra on pages 1–2; added a missing small-noon at 21:88.
- **Licence:** **"Legal Use and Open Permission (Sadaqa-e-Jaria)"** — use/copy/modify/distribute/derive for any lawful purpose incl. **commercial**; only condition: do not alter Quranic content misleadingly. → OK to bundle a derived artifact.
- **What it contains:** 604 complete Madani pages as SVG. Per page: `md-page[data-page-number]` → `md-page-outer` (frame, page no, juz name, margin marks) + `md-page-inner[data-rect="x,y,w,h"]` → 15 `md-line-NN[data-line-number][data-type=text|surah-name|bismillah|empty]`. Every word = `md-word-NNN[data-surah, data-aya, data-line-number, data-hafs, data-imlaey, data-word-index-in-ayah, data-type]` (`data-type` ∈ text | juz-star | sajda-mehrab), optional `data-waw-alatf`. Below: `md-ligature-*` (letter paths, `data-text`), `md-diacritic-*` (25 named types + `data-dots` ∈ dot|two dots|three dots), `md-aya-mark-NNN[data-surah, data-aya, data-line-number]`. Path-level `data-waqf` ∈ waqf lazim|jaiz|sali|qila|taanuq. Canonical **`viewBox="0 0 382.68 547.09"`** for all 604.
- **What we use it for:** `79-mushaf` semantic layer — `assets/mushaf/mushaf_layout.json.gz` (extracted by `tool/extract_mushaf_svg.py`), the `mushaf_*` tables, per-word `(surah, ayah, word_index, hafs, imlaey, line, bbox)`. The visual (SVG paths) is **not** yet used — see `ERRATA.md` entry E-1.
- **What we must NOT assume:**
  - `VERIFIED` bboxes come from **glyph vector outlines** — they describe the *MushafDatabase glyphs only*. You **cannot** render `data-hafs` with another font at those boxes (see E-1). Bboxes are for hit-testing / highlight geometry over the *real SVG art*, nothing else.
  - `data-word-index-in-ayah` counts ornaments (۞, ۩) as words. So `MAX(word_index)` for an ayah ≠ its lexical word count. `VERIFIED` (measured: 91 237 text + 199 juz-star + 15 sajda-mehrab tokens).
  - `surah-name` / `bismillah` / margin `juz-hizb` / `sajda` markers carry **no** `data-surah`/`data-juz` — the surah a header introduces is **inferred** (`INFERENCE`), the juz number is **not in the file** at all (`UNKNOWN` from this source; get it from `quran_ayat.juz_number`).
  - It is a **specific layout edition**. Do not assume its page→line→ayah placement matches Tanzil's page array or any other mushaf beyond the page-boundary level.
  - `data-hafs` is *this dataset's* Uthmani rendering; treat it as the print form of record for *this layout*, cross-check against Tanzil for text identity, never the reverse.

## 4. quranpedia / quran-svg  ·  present locally (`svg2/`), **fallback only**

- **URL:** https://github.com/quranpedia/quran-svg
- **Local path:** `svg2/` (partial, ~150 `NNN.svg` + `NNN.json` pairs, plus `.svg.br`, `.ai` extras) and `svg/` (75 files).
- **Version:** unversioned snapshot; `svg2/` is incomplete.
- **Licence:** the **polygon overlay + metadata are CC0 1.0** (public domain). Underlying KFGQPC page art: "free digital use", commercial physical printing reserved.
- **What it contains:** SVG pages + a **transparent clickable ayah-polygon layer** for 5 qira'at (Hafs 604p/6236, Warsh 604/6214, Qalun 604/6214, Al-Douri 604/6218, Shu'bah 604/6236). Per-ayah JSON: `{surahNumber, ayahNumber, x, y (medallion centre), polygon (multi-rect path)}`; `viewBox 0 0 345 550` (Warsh/Qalun `-6 0 345 550`); ids `verse-N`.
- **What we use it for:** **nothing currently.** `VERIFIED` (inspected 2026‑08‑29): the `svg2/*.svg` files contain **only** ayah-marker ornaments + `ayahPolygon` shapes — **no Quran text glyphs**. Kept as a possible *ayah-region tap fallback* only.
- **What we must NOT assume:** it is **not** a visual mushaf source and never will be, however many pages are added. Its coordinate system (345×550) is **different** from MushafDatabase (382.68×547.09) — polygons are not interchangeable without a transform. Ayah counts differ per qira'a — only use the Hafs set.

## 5. Quranic Universal Library (QUL) — Tarteel  ·  reference / potential

- **URL:** https://qul.tarteel.ai/ · docs https://qul.tarteel.ai/docs · repo https://github.com/TarteelAI/quranic-universal-library
- **What it is:** an open CMS + downloadable corpus: **mushaf layouts** (KFGQPC V1/V2/V4, IndoPak 13/15/16, DigitalKhatt, Nastaleeq, Ligature-Based SVG), quran scripts (word-by-word, ayah-by-ayah, with tajweed), fonts (QPC V1/V2/V4), translations (+ footnote formats), tafsirs, word translations & transliterations, **recitations with word segments**, **mutashabihat** (near-identical ayah pairs), tajweed-rule data, surah info, topics/themes, grammar/corpus data.
- **Formats:** **SQLite** and **JSON**.
- **Layout schema (`SOURCE-BACKED`):** `pages` table rows = one per line: `page_number, line_number, line_type ∈ {ayah, surah_name, basmallah}, is_centered, first_word_id, last_word_id, surah_number`. `words` table: `word_index (global), word_key "S:A", surah, ayah, position, text`. Render = for each `ayah` line, fetch words `BETWEEN first_word_id AND last_word_id`, place in order; `surah_name`/`basmallah` lines are centred.
- **Licence:** per-resource (mostly open; check each). Fonts inherit KFGQPC terms.
- **What we use it for:** *reference model* for how serious apps structure mushaf layout data (our `mushaf_*` schema mirrors it). A candidate source for: mutashabihat (hifz revision), tajweed rule spans, word translations, recitation segments — **if** we add those features.
- **What we must NOT assume:** QUL layouts are edition-specific (a QUL "KFGQPC V2" line map ≠ our MushafDatabase line map). Don't mix a QUL `word_index` with our `mushaf_words.word_order`.

## 6. quran.com / Quran Foundation API v4  ·  reference

- **URL:** https://api-docs.quran.foundation/
- **What it is:** the API behind quran.com. Per-word fields `text_uthmani, text_qpc_hafs, text_indopak, code_v1, code_v2` (QCF PUA glyph codes), page-layout endpoint (`/pages/lookup`), word `page_number/line_number/position`, `char_type_name ∈ {word, end}` (the ayah-number token is a separate "end" element with its own glyph).
- **Licence:** API terms; data largely from Tanzil + KFGQPC.
- **What we use it for:** reference for the render recipe (group words by `page-{p}-line-{l}`) and the fact that the **ayah-number marker is a first-class element, not text**.
- **What we must NOT assume:** `code_v1/code_v2` are **not readable text** — they are PUA points that only mean anything with the matching per-page QCF font. We do not have that font.

## 7. Quranic Arabic Corpus (corpus.quran.com)  ·  reference / **licence caution**

- **URL:** https://corpus.quran.com/ · download https://corpus.quran.com/download/
- **What it is:** morphological + syntactic (dependency treebank) annotation of every Quran word — segment, POS, **lemma**, **root**, grammatical features.
- **Version:** morphology **v0.4**.
- **Licence:** **GNU GPL** — visible "corpus.quran.com" credit + link required, **no modification**. For *data* (not linked code), redistribution with attribution is OK; any transform we make of it is itself GPL. Keep it in its own un-forked asset.
- **Present locally** as `services/morphology.json.gz` inside the **Quranpedia dumps** (§13), which redistributes it verbatim under its own GPL terms. 6236 ayat, per-word segments (role/POS, root, lemma, translation, phonetic).
- **What we use it for:** *(planned, §13 QC1–QC3)* the ṣarf tier of the Word Knowledge Surface — fills the currently-inert `QacGrammarProvider`.
- **What we must NOT assume:** its word `number` = **QAC segmentation** — **not** `mushaf_words.word_index`, **not** Tanzil space-split. On-mushaf-page rendering needs the VT‑3 alignment map first.

## 8. quran-align (cpfair) + QUL segments  ·  reference (recitation timing)

- **URL:** https://github.com/cpfair/quran-align
- **What it is:** per-word **start/end timestamps (ms)** within an ayah's recorded audio, per reciter. Words defined by **space-splitting `quran-uthmani.txt` (Tanzil)**.
- **Licence:** code MIT; timing data derived, per-reciter.
- **What we use it for:** *reference* for the recitation-follow / word-highlight-with-audio feature (not yet built).
- **What we must NOT assume:** its word indices = Tanzil segmentation, **not** MushafDatabase segmentation. Mapping table required. Timing is per-reciter — never global.

## 9. cpfair/quran-tajweed  ·  **USED** (Phase G-t1 — tajwīd rule spans, all 6236)

- **URL:** https://github.com/cpfair/quran-tajweed  ·  pinned commit `496f71cd191da00fa2a37ded79dbbddb033bb0ad` (2021‑10‑12).
- **What it is:** 18 tajweed rules (ghunnah; idghaam ×5; ikhfa ×2; iqlab; madd ×5; qalqalah; hamzat_wasl; lam_shamsiyyah; silent) as `{surah, ayah, annotations:[{rule, start, end}]}` where `start/end` are **Unicode codepoint offsets into a specific Tanzil Uthmani text file (`quran-uthmani.txt`, the copy attached to the repo ca. 2017‑04‑06)** — the first ayah of every surah except 1 & 9 has the Basmala prepended in that file.
- **Licence:** rule DATA **CC BY 4.0** (Chris Pearce / cpfair) — attribution + link required, shown in `SourcesScreen` via `src:cpfair-tajweed`. The base Tanzil text is build-input only, never shipped.
- **What we use it for:** `assets/quran/corpus/tajweed.json.gz` — per `(surah, ayah, word_index)` + a `[cs, ce)` char range in that word's own Uthmani text; seeded into `quran_tajweed` (DB v56) by `QuranCorpusSync`, served by `CorpusTajweedProvider` for the knowledge surface. Colours are **not** stored — derived from the 6-family map in `lib/theme/tajweed_palette.dart` + `lib/data/tajweed_rules_ref.dart`.
- **How the remap is built:** `tool/fetch_tajweed_source.sh` (pinned inputs → gitignored `tool/vendor/`) → `tool/build_tajweed_rules.py` (two-stage **normalised** alignment: our clitic-split words → cpfair whole words, then cpfair char offsets → our per-word `[cs,ce)` at letter-group granularity; a group that will not align cleanly is **skipped and listed**, never guessed). Result 2026-09-05: **6236/6236 ayāt clean, 0 flagged, 70 085 spans** — `docs/quran/reports/TAJWEED_ALIGNMENT_REPORT.md`.
- **What we must NOT assume:** the offsets are **bound to that exact 2017 text file** — the fetch script asserts a byte-exact 1 376 504-byte download. Any change to our layout `hafs` text ⇒ re-run `build_tajweed_rules.py` and re-check the report. Colours vary by publisher — we store only the **rule id**. The two same/close-makhraj idghām rules and hamzat al-waṣl / lām shamsiyyah / silent have **no direct curriculum lesson** — they carry a label + colour only.

## 10. Fonts in the repo  ·  **USED**

- **AmiriQuran-Regular.ttf**, **Amiri-Regular/Bold.ttf** — SIL OFL 1.1 (`assets/fonts/AMIRI_QURAN_LICENSE.txt`). Used for ayah/Turath classical-Arabic display (has glyphs for rare ligatures the theme font lacks, e.g. U+FD4A).
- **DigitalKhattMadina.otf** — SIL OFL 1.1 (`assets/fonts/DIGITALKHATT_MADINA_LICENSE.txt`), from github.com/DigitalKhatt/madinafont (Tarteel-sponsored). Madani-1420H-style script; offered as an alternative Quran font. `SOURCE-BACKED`: DigitalKhatt's *justification* magic (curvilinear letter stretching) needs its LuaLaTeX typesetter + a forked HarfBuzz — the plain OTF in a Flutter `Text` does **not** do parametric line-filling.
- **What we must NOT assume:** a generic OpenType Quran font + runtime justification (kashida) is unreliable for fully-vocalised text (HarfBuzz doesn't insert kashida; Amiri devs document erroneous tatweel in full justify). This is *why* print masahif use per-word shaped glyphs.

## 11. Tafsir / translation editions in the repo  ·  **USED**

- `assets/quran/tafsir-*.jsonl.gz` — Arabic: `ibn_kathir`, `saadi`, `muyassar`, `ibn_ashur`, `almukhtasar`; plus ~40 language translation-tafsir editions (rwwad/qtafsir family).
- **Source/licence:** mostly via **spa.qurancomplex.gov.sa / QuranEnc / Tanzil trans** — CC-BY family; the roadmap's "About sources" screen carries attribution. `TafsirMuyassar` is an official KFGQPC edition.
- **What we use it for:** the ayah-centred tafsir study mode (Phase 72), Understanding pillar.
- **What we must NOT assume:** these are **translations/tafsir, not the Quran** — never present a translation as the text; never quote tafsir as ruling. (Matches the `quran.ai` MCP grounding rules.)

## 12. quran.ai MCP server  ·  runtime tool (this dev session)

- Canonical `fetch_quran` / `fetch_translation` / `fetch_tafsir` / `fetch_quran_metadata` / `fetch_mushaf` / morphology tools, sourced from quran.com.
- **Use for:** grounding any Quran text/translation/tafsir *I* produce while working; verifying structural metadata (juz/page/hizb/ruku/sajda of an ayah). **Call `fetch_grounding_rules` first.**
- **Not** a build-time dependency — it does not ship in the app.

## 13. Quranpedia.net data corpus  ·  present locally (raw dumps), **plan only**

- **URL:** https://quranpedia.net/ · API https://quranpedia.net/api-docs · changes feed `https://quranpedia.net/api/v1/changes?since=<version>`
- **Local:** raw official versioned dumps at repo root (~1.15 GB, git-ignored), brought by Ismail 2026‑09‑03. Full inventory + plan: **[`QURAN_CORPUS_INTEGRATION.md`](QURAN_CORPUS_INTEGRATION.md)**.
- **Version:** each dump carries `license.version` (2026‑09‑02 snapshot) + `license.resync`. Envelope `{license, schema, data}`.
- **Licence (`svg2/LICENSE.md` v2026‑09‑02):** **free to use inside apps** — no attribution required (link appreciated); attribution + dump-version required **only** to re-publish the dataset as a downloadable database. **Obligation:** keep any shipped copy current via `/v1/changes` — distributing stale Quranic text is the distributor's responsibility. Public API is *not* a download service (120/min, 10k/day) — the versioned dumps are the sanctioned bulk path.
- **Third-party carve-outs (NOT covered by the above):**
  - **`services/morphology.json.gz`** = **Quranic Arabic Corpus v0.4** (Dr. Kais Dukes, Leeds) — **GNU GPL**, visible "corpus.quran.com" credit + link required, **no modification**. Cross-ref §7.
  - **`services/syntax.json.gz`** = The Quranic Treebank (NoorBayan/Quranic) — **MIT**, attribution.
  - **Translations** (`translations-all.zip`, 139 editions) — **IP of their authors/publishers**; Quranpedia grants nothing. Per-edition review; ship only PD/CC ones.
- **What it contains:** 14 riwāyāt full text (Hafs = 6236/114 `VERIFIED`); 149 tafsir books (900 MB, full per-ayah HTML); 4 iʿrāb + 2 asbāb + 1 nāsikh books; 15 per-ayah service indexes (morphology, syntax, meanings, notes, qiraat, …); 6100 topics (tree, `topic → ayah-range`); 253 reciters; 3575 fatwas; 16,296-book catalog; athar/sayings.
- **What we use it for:** *(planned, not built)* fill the inert Learning-Engine providers (ṣarf via QAC morphology, naḥw/iʿrāb, word-meaning, notes), curated extra tafsirs, the Knowledge Index topic graph, reciter metadata. Bundled = a curated ~40–60 MB subset; the rest = Supabase mirror + on-demand cache. **Sequenced AFTER the Mushaf Rendering Engine.**
- **What we must NOT assume:** `page_number` is Quranpedia's own scheme — **not** Tanzil's / MushafDatabase's; never route navigation through it. morphology word `number` follows **QAC segmentation** — **not** `mushaf_words.word_index` (on-page ṣarf waits on VT‑3 alignment). Tanzil `quran_ayat` stays primary text; Quranpedia is cross-check + dabt/marker companion. Modern books/translations = per-author licence, not "shared heritage".

## 14. saikothasan/quran-api  ·  reference / fallback only

- **URL:** https://github.com/saikothasan/quran-api · https://alquran-api.pages.dev/api/quran
- **Licence:** **MIT**. Next.js on Vercel/Pages, CORS, no auth, no documented rate limit.
- **What it contains:** 114 surahs + verses; 11 languages + transliteration; search. **No audio.** Original data source unstated ("The Noble Quran").
- **What we use it for:** *nothing planned* — redundant with the Quranpedia mushafs for text. Kept as a possible **online-only fallback translation provider** (AD‑1 adapter) or a cross-check. Low priority.
- **What we must NOT assume:** unstated provenance → do not treat as authoritative for the Uthmani text; verify against Tanzil / quran.ai MCP before using any string from it.
