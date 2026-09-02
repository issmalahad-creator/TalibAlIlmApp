# Quran Data Model — the correct hierarchy, identities, and sources of truth

Tags: see `SOURCES.md`. This file answers: *when I build a Quran feature, what
is the right model, what is the identity, what is the source of truth, what
must not be guessed?*

---

## 1. The hierarchy

```
Quran
└── Surah            1..114              (fixed, universal)
    └── Ayah         1..N per surah      (N depends on the counting school)
        └── Word     1..K per ayah       (K depends on the segmentation)
            └── Segment / grapheme       (morpheme, or base letter + marks)
                └── Character            (Unicode code point)
                    └── Diacritic        (combining mark on the base)
```

Two **orthogonal** axes cut across Word level and below:

- **Text form** — Uthmani vs Imlaei vs normalized vs visual-glyph (see §5).
- **Layout** — which page/line/position a word occupies in a *specific
  printed edition* (see `QURAN_LAYOUT.md`). Layout is **not** part of a
  word's identity.

---

## 2. Identities — what uniquely names each thing

| thing | canonical identity | notes |
|---|---|---|
| Surah | `surah` int `1..114` | `VERIFIED`. Name/ayah-count from `lib/data/quran_surahs.dart` (114 rows). |
| Ayah | `(surah, ayah)` ints | `VERIFIED`. This is the anchor the Ayah Notebook uses. Integers **do not drift** → no re-anchoring engine needed (unlike Turath text anchors). |
| Word (lexical) | `(surah, ayah, word_index)` | `word_index` is **1-based within the ayah** and is **segmentation-dependent** — always say *whose* index. Ours = MushafDatabase's `data-word-index-in-ayah`. |
| Word (on a page) | `(page, line, word_order)` | layout position, edition-specific. `word_order` = reading order on the page. **Not** an identity — a locator. |
| Verse-end marker | `(surah, ayah)` of the ayah it closes | a distinct element, not text (see §6). |
| Page | `page` int `1..604` | edition-specific (Madani). |
| Juz/Hizb/Rub/Ruku/Manzil | int in its range | structural; from `quran_ayat` / Tanzil metadata. |

**Rule:** if a semantic identity exists, use it. Never derive ayah identity
from a screen tap's pixel position when `(surah, ayah)` is already known from
the data (`ERRATA.md` E‑2).

---

## 3. Counting schools — why "number of ayat" is not one number

`SOURCE-BACKED` (SeekersGuidance, al‑Furqan). Six enumeration traditions:
**Madani-awwal, Madani-akhir, Makki, Basri, Shami, Kufi.** They differ only
in **where a verse boundary falls**, never in content.

- **Kufi = 6236** — attributed to ʿAlī via Kufa; the standard in printed
  masāḥif worldwide, including ours. `VERIFIED` (our data + canonical list).
- Per-riwāya totals (`SOURCE-BACKED`, quranpedia): Warsh/Qalun **6214**,
  Al-Douri **6218**, Hafs/Shuʿbah **6236**.
- Hafs counts the Basmala as al‑Fātiḥa 1; some schools don't and split the
  last verse instead → al‑Fātiḥa is 7 either way.
- Examples of boundary differences (`SOURCE-BACKED`): muqaṭṭaʿāt (e.g.
  الٓمٓ) counted as a verse by Kufa, not by others; 48:37 split differently
  by Basra.

**Rule:** our app is **Hafs / Kufi count / 6236**. Do not mix an ayah number
from one school with text/metadata from another. If we ever add Warsh etc.,
it is a *separate dataset*, not a tweak.

`kSurahAyahCounts` truth = `lib/data/quran_surahs.dart` (`QuranSurah.ayahCount`,
Σ = 6236). Used as the validation ground truth for `MushafLayoutSync`.

---

## 4. Word & letter counts — no canonical figure

`SOURCE-BACKED` (multiple): ≈ **77,430 words**, ≈ **320,000 letters**, but
every published count differs (77,000–80,000 words; 320k–330k letters)
because "a word" and "a letter" are defined differently per method
(connected particles, tashkīl, ḥurūf muqaṭṭaʿa, waqf marks).

**Rule:** never hard-code a global word/letter count as if canonical. If a
feature needs "words in ayah X", get it from the segmentation you're using
and name it (`MushafDatabase word count`, `Tanzil space-split count`, …).
`PROJECT-SPECIFIC`: our `mushaf_words` has **91,451 indexed tokens**
(91,237 `text` + 199 `juz-star` ۞ + 15 `sajda-mehrab` ۩) — that is a
*token* count for this layout, **not** a lexical word count.

---

## 5. Text forms — keep four things separate, never conflate

| form | what it is | where in project | use for |
|---|---|---|---|
| **Uthmani (rasm + dabt)** | the classical Quranic orthography: archaic spellings (زائد waw/alif/yā, dagger alif ٰ for omitted alif), ʿayn-head hamza, small-ṣād waṣla | `quran_ayat.text_uthmani` (Tanzil), `mushaf_words.text_uthmani` (`data-hafs`) | **display only** — the recited/printed text of record |
| **Imlaei / "simple"** | modern spelling rules (الصلاة, هذا) | `mushaf_words.text_imlaey` (`data-imlaey`) | readable secondary form, beginner aids, some matching |
| **Normalized (search)** | diacritics stripped, letter variants unified | `quran_ayat.text_normalized` via `normalizeArabicForSearch()` (`lib/utils/arabic_normalize.dart`) | **search/matching only** — never displayed |
| **Visual glyph** | PUA code points for a specific per-page font (QCF `code_v1/v2`), or vector paths (MushafDatabase SVG) | *not stored* (QCF); MushafDatabase SVG paths not yet used | pixel-perfect print rendering **with the matching font/asset only** |

`VERIFIED` rules:
1. **Uthmani text is never modified.** Tanzil's CC-BY 3.0 requires it; the
   grounding principle requires it. `normalizeArabicForSearch` explicitly
   documents "Never use this for display".
2. **Normalized ≠ Imlaei.** Normalization is lossy folding for a search
   index; Imlaei is a real orthography. Don't substitute one for the other.
3. **Visual glyph codes are not text.** `code_v1/v2` mean nothing without
   their font. MushafDatabase bboxes describe *its* glyphs only — you
   cannot lay `data-hafs` in another font at those boxes (`ERRATA.md` E‑1).
4. To compare two texts for *identity* (same ayah?), normalize both with the
   **same** function and compare; never eyeball rasm differences.

### `normalizeArabicForSearch` — what it actually does  (`VERIFIED`, read the file)

Order matters. Roughly:
1. Dagger alif (U+0670) disambiguation, verified against every dagger-alif
   word form in the bundled text: `وٰ→ا`, `ىٰ→ى`, keep-bare for a closed set
   (هذا/هذه/هؤلاء, ذلك/كذلك, لكن, الرحمن), remaining `ٰ→ا`.
2. Strip tashkīl + combining madda/hamza (U+064B–06AF gap incl. U+0653) +
   the Quranic small-mark/waqf block (U+06D6–U+06ED).
3. Strip tatweel U+0640.
4. Alef variants `[أإآٱ]→ا`.
5. `ى→ي`, `ة→ه`.

Matches the standard Arabic-search normalization (Lucene `ArabicNormalizer`,
adelpro Quran-search guide): alef unification, hamza fold, tā-marbūṭa→hā,
alif-maqṣūra→yā, diacritic + tatweel removal, NFC. `PROJECT-SPECIFIC`
additions: the dagger-alif casework (because omitted-alif words like
الظالمين must restore the ا to be searchable) and the U+0653 fix (الفقراء).

`kNormVersion`-style versioning: the **Turath** anchor normalizer
(`lib/utils/study_annotation_anchor.dart`, `kNormVersion = 2`) is a
*different* normalizer for a *different* purpose (page-text drift anchoring).
Do not confuse the two. `mushaf_layout.dart` has `kMushafLayoutVersion` for
the extracted layout asset. Three independent version counters.

---

## 6. The verse-end marker is a first-class element, not text

`VERIFIED` (quran.ai `fetch_mushaf`: `char_type_name:"end"`; MushafDatabase
`md-aya-mark-*`). The ۝-style medallion with the ayah number:

- is **not** part of `text_uthmani` and **not** recited;
- has its own identity `(surah, ayah)` and its own geometry (`mushaf_aya_marks`);
- the number inside is rendered in **Eastern-Arabic digits ٠–٩** as a graphic.

**Rule:** treat aya-marks as their own layer. Never concatenate the number
into ayah text; never let a tap on the medallion be "the last word".

---

## 7. Relationships that always hold  (`VERIFIED` against our data)

- every `(surah, ayah)` in `mushaf_words` exists in `lib/data/quran_surahs.dart`'s range and in `quran_ayat`;
- `word_index` is contiguous `1..k` within every one of the 6236 ayat;
- exactly one `mushaf_aya_marks` row per `(surah, ayah)`; the mark set == the word-ayah set;
- every surah's `MAX(ayah)` == its canonical ayah count; ayat are `1..N` with no gap;
- in the **Madani** layout every page **begins** a new ayah and **ends** on an ayah boundary → an ayah's words are all on **one page** (`VERIFIED`: 2:282, 161 words, single page). This is a property of *this edition*, not of "the Quran".

## 8. Relationships that do NOT hold / must be checked

- page boundaries ≠ surah boundaries (a page can span two surahs);
- page boundaries ≠ juz boundaries (a juz starts mid-page often);
- Tanzil page N's ayah set is **not guaranteed** identical to MushafDatabase page N's line-level content — same *edition family*, different *files* (`INFERENCE`: page-level they match for standard Madani; verify before relying on line-level equivalence);
- a "word index" is meaningless without naming its segmentation;
- juz/hizb/ruku numbers are **not** in the MushafDatabase SVGs — source them from `quran_ayat`.

## 9. Open questions (`UNKNOWN`)

- Does Tanzil's `page` array (our `quran_ayat.page_number`) place every ayah on the same page as MushafDatabase V1.01? (Spot-checks pass; a full 6236-row diff has not been run.)
- Our `quran_ayat.text_uthmani` (Tanzil v1.1) vs MushafDatabase `data-hafs` — are they byte-identical per word after normalization, or are there dabt-level differences? (Not audited.)
- Ruku count in our data (Tanzil `quran-data.js` has per-surah ruku counts) vs the 558 figure — not reconciled.
