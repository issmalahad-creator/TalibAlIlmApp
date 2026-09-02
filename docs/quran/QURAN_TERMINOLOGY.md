# Quran & Mushaf Terminology — engineering glossary

Tags: see `SOURCES.md`. Terms defined for *how they affect data/code*, not
devotional detail.

---

## Text & orthography

- **Rasm (رسم) / al-rasm al-ʿUthmānī** — the consonantal skeleton: ~18
  distinct letter shapes, no dots, no vowels. **Fixed / sacred** — masahif
  may not alter it beyond the reported Uthmanic codices. Madani mushaf
  follows Abū Dāwūd Sulaymān b. Najāḥ (d. 496H); IndoPak follows al-Shāṭibī
  (d. 590H).
- **Dabt (ضبط) / tashkīl** — the *added* layer: consonant dots (iʿjām) +
  vowels/marks (ḥarakāt). Developed after the rasm (Abū al-Aswad al-Duʾalī →
  al-Khalīl b. Aḥmad). **May legitimately differ** between editions.
- **Uthmani text** — rasm + dabt in the classical Quranic orthography:
  archaic spellings, dagger alif (ٰ, U+0670) for omitted alif, ʿayn-head for
  hamzat al-qaṭʿ, small-ṣād for hamzat al-waṣl (ٱ). → `text_uthmani`.
  **Display only, never modified.**
- **Imlāʾī / "simple" (إملائي)** — modern Arabic spelling rules
  (الصلاة, هذا). → `text_imlaey`. A real orthography, not a folded index.
- **Normalized text** — diacritics stripped + letter variants unified for
  **search/matching only**. → `text_normalized` /
  `normalizeArabicForSearch()`. Lossy. **Never displayed.** ≠ Imlāʾī.
- **Visual glyph** — PUA code points for a per-page QCF font (`code_v1/v2`),
  or SVG vector paths. Meaningless without the matching font/asset.
- **Dagger alif (alif khanjariyya, ٰ, U+0670)** — a superscript stroke
  marking an alif omitted from the rasm. Plays several roles; our normalizer
  has verified casework for it.
- **Tatweel / kashida (ـ, U+0640)** — a stretch character; carries no letter
  identity; stripped in normalization; used (in print) for justification.
- **Hamza forms** — ء (U+0621), أ إ (seated), ؤ ئ (on wāw/yāʾ), آ (madda),
  ٱ (waṣla). Search normalization folds alef variants → ا, ؤئ → ء.
- **Muqaṭṭaʿāt (الحروف المقطّعة)** — the isolated letters opening 29 surahs
  (e.g. الٓمٓ). Counted as a verse by the Kufa school, not by all — a source
  of ayah-count differences.

## Structure & division

- **Surah (سورة)** — chapter; 1..114, universal.
- **Ayah (آية)** — verse; numbering depends on the **counting school**
  (Madani-awwal/akhir, Makki, Basri, Shami, **Kufi**). Ours = Kufi, 6236.
- **Word (كلمة)** — segmentation-dependent; always name whose (Tanzil
  space-split vs MushafDatabase `word_index` — they differ).
- **Juzʾ (جزء)** — 1/30. **Ḥizb (حزب)** — 1/60 (2 per juzʾ). **Rubʿ el-ḥizb
  (ربع الحزب)** — 1/240 (¼ ḥizb), marked with the ۞ ornament (U+06DE).
  **Manzil (منزل)** — 1/7 (weekly khatma). **Rukūʿ (ركوع)** — thematic
  paragraph, ≈540–558; ع mark (IndoPak).
- **Page (صفحة)** — layout unit; **edition-specific**. Madani = 604.
- **Sajdat al-tilāwa (سجدة التلاوة)** — recitation prostration; **15** verses
  (14 agreed); wājib (Ḥanafī) / sunna (others); Shāfiʿī list differs on
  38:24 vs 22:77. Mark: ۩ (U+06E9).

## Recitation

- **Qirāʾa (قراءة)** — a canonical reading (10 total: 7 mutawātir + 3),
  transmitted via 2 principal **rāwīs** each → ~20 **riwāyāt**.
- **Riwāya (رواية)** — a transmission of a qirāʾa. Ours: **Ḥafs ʿan ʿĀṣim**
  (ʿĀṣim of Kūfa). ~95%+ of printed Qurans today.
- **Warsh / Qālūn ʿan Nāfiʿ** — dominant in N/W Africa (Warsh) and
  Libya/Tunisia (Qālūn); Maghribī script; different madd/imāla/tashīl;
  6214 verses; **different mushaf** if ever added.
- **Tajwīd (تجويد)** — recitation rules; commonly colour-coded (KFGQPC
  "Tajweed V4" palette is the de-facto standard, but publishers vary — store
  the rule, not the colour).
- **Ghunna** (nasalisation), **Idghām** (merging), **Ikhfāʾ** (concealment),
  **Iqlāb** (conversion), **Madd** (elongation, several lengths),
  **Qalqala** (echo on ق ط ب ج د with sukūn), **Lām shamsiyya**,
  **Hamzat al-waṣl**, **silent letters** — the rule families in tajweed
  datasets.

## Pause marks (waqf, وقف)

Madani set (King Fuʾād I committee):

| glyph | name | meaning |
|---|---|---|
| مـ | lāzim | must stop |
| ط | muṭlaq | preferred stop |
| ج | jāʾiz | permissible stop |
| قلى | al-waqf awlā | stop is better |
| صلى | al-waṣl awlā | continuing is better |
| قف | — | stop (reminder where a reader tends not to) |
| س / ۜ | sakta | brief pause, no breath |
| **لا** | lā | **do NOT stop** |
| ∴ … ∴ | muʿānaqa (taʿānuq) | stop at exactly one of the pair |

**IndoPak / al-Sajāwandī system inverts لا** → "must stop". Never explain a
waqf glyph without knowing the mushaf's waqf tradition.

## Layout data terms

- **Mushaf layout** — structured per-line data (page, line, line_type,
  word boundaries) that lets an app reproduce a printed edition.
- **line_type** — `text` (justified) | `surah-name` (centred banner) |
  `bismillah` (centred) | `empty`.
- **Aya-mark / verse-end medallion** — the ۝-style ornament + number; a
  first-class element, not text, not recited.
- **bbox** — a word's bounding box in the source viewBox (MushafDatabase:
  glyph vector-path extent; conservative).
- **viewBox** — the SVG coordinate space; MushafDatabase `0 0 382.68
  547.09` for all 604 pages; quranpedia `345×550`.
- **Ligature-based rendering** — glyphs as vector paths (SVG) with semantic
  groups; vs **QCF per-page font** where one glyph = one whole word and each
  page has its own font.
- **Segmentation** — how text is split into "words". No universal one:
  Tanzil = split on spaces; MushafDatabase = `data-word-index-in-ayah`
  including ornaments. Mapping between them is a real artifact.

## Editions / projects (short)

- **Mushaf al-Madinah** — KFGQPC, Uthman Taha, 604p/15-line, Hafs. 3
  calligraphy editions (1405/1422/1439H); QCF generations V1/V2/V4.
- **IndoPak / "ʿAjamī"** — Taj Company (Lahore, 1929); simplified dabt;
  13-line common (also 15/16); more waqf signs; adds rukūʿ; **لا inverted**.
- **Tanzil** — reference digital text + metadata (CC-BY 3.0). Our text
  source.
- **MushafDatabase Ligature-Based SVG V1.01** — our semantic-layer source
  (Sadaqa-e-Jaria licence).
- **QUL (Tarteel)** — open corpus of layouts/scripts/fonts/data; our schema
  model.
- **Quranic Arabic Corpus** — morphology + syntax treebank (GPL — study
  only).
