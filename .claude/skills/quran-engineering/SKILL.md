---
name: quran-engineering
description: >-
  Load before building, changing, or reviewing ANY Quran or mushaf feature in
  TalibAlIlmApp — mushaf rendering/layout, the 604-page Madani mushaf, Uthmani
  vs imlaei vs normalized text, word/ayah/surah identity, ayah & waqf markers,
  tashkeel, tajweed, qira'at, hifz/review scheduling, recitation follow, the
  Ayah Notebook, linking words/ayat to notes, or Quran search. It carries the
  engineering rules, the source register, and the mistakes log so Quran work
  starts from settled ground instead of re-derivation.
---

# Quran Engineering Skill

This skill points at the permanent knowledge base in **`docs/quran/`** and
gives the operational rules to follow. Read the relevant KB file before
writing code; update the KB when you learn something durable.

## Knowledge base map

| file | use it for |
|---|---|
| `docs/quran/SOURCES.md` | every dataset/spec/font: version, licence, what we use it for, **what we must NOT assume**. Start here for any new source. |
| `docs/quran/KNOWLEDGE.md` | requirement → model → source of truth → identity → what-not-to-guess, per feature kind (`R-1`…`R-17`). |
| `docs/quran/QURAN_DATA_MODEL.md` | Quran→Surah→Ayah→Word→Char hierarchy; the 4 text forms; counting schools; relationships that do / don't hold. |
| `docs/quran/MUSHAF_ENGINEERING.md` | the printed Madani mushaf; layout schema; what layout CAN / CANNOT tell you; the 2 valid render strategies; size handling. |
| `docs/quran/QURAN_LAYOUT.md` | pages/lines/placement/markers/divisions; edition-specificity; Tanzil-page vs MushafDatabase-page. |
| `docs/quran/QURAN_INTERACTION.md` | hit-testing, the coordinate transform, word-range selection, anchoring to the notebook, recitation/tajweed overlays. |
| `docs/quran/QURAN_TERMINOLOGY.md` | glossary (rasm, dabt, imlaei, riwaya, waqf types, juz/hizb/rub, sajda, …) defined for their code impact. |
| `docs/quran/ERRATA.md` | mistakes already made + the durable rule each produced. Check before repeating a pattern. |

## Knowledge classification — tag everything you add

`VERIFIED` (checked against our data or ≥2 authoritative sources) ·
`SOURCE-BACKED` (one authoritative source) · `PROJECT-SPECIFIC` (true for our
code, not a general fact) · `INFERENCE` (my synthesis) · `UNKNOWN` (a gap).

**Never** use `INFERENCE` or `UNKNOWN` as a basis for changing Quran **text**
or mushaf **data**. Those change only from `VERIFIED`/authoritative data.

## Pre-flight checklist — before modifying Quran rendering or layout

1. **Which source dataset?** (Text → Tanzil / `quran_ayat`. Mushaf layer →
   MushafDatabase V1.01 / `mushaf_*`.)
2. **Which mushaf edition/version?** (Madani; MushafDatabase **V1.01**;
   `kMushafLayoutVersion`. Not the KFGQPC QCF fonts — we don't have them.)
3. **Which coordinate system?** (viewBox `0 0 382.68 547.09`, `xMidYMid
   meet`. quranpedia's `345×550` is a *different* space.)
4. **Semantic layer or rendering layer?** Keep them separate. The DB schema
   must not encode a rendering choice. `MushafPageView` must not import a
   repository or a feature screen.
5. **Never reconstruct Quran text from visual geometry.** Text identity is a
   data field (`text_uthmani`), verified against Tanzil / `quran.ai` MCP.
6. **Never infer ayah/word identity from page position** when `(surah,
   ayah[, word_index])` is in the data (`ERRATA` E‑2).
7. **Never carry a bbox / polygon across editions** without an explicit
   coordinate transform.
8. **Juz / hizb / ruku / sajda NUMBERS** → `quran_ayat` / Tanzil metadata.
   The mushaf SVG gives ornament **positions** only.
9. **The verse-end medallion is a first-class element, not text** — its own
   `(surah, ayah)` identity and geometry; never "the last word".
10. **`لا` waqf glyph is inverted** between Madani ("don't stop") and IndoPak
    ("must stop"). Never explain a waqf glyph without the tradition.
11. **Comparing two texts?** Normalize both with the **same** function; never
    eyeball rasm. Know which of the 3 normalizers you mean (`kNormVersion` =
    Turath anchor; `kMushafLayoutVersion` = layout asset; `normalizeArabic
    ForSearch` = search index).
12. **App scope is fixed:** Hafs ʿan ʿĀṣim, Kufi count, **6236** ayat, 114
    surahs, 604 Madani pages. Another riwāya = a separate dataset, not a
    toggle.

## Pre-flight checklist — before consuming an external Quran dataset

1. Add it to `docs/quran/SOURCES.md` with: URL, version, licence, what it
   contains, what we use it for, **what we must NOT assume**.
2. Confirm the **licence** allows bundling a derived artifact (GPL / "no
   redistribution" → study only, don't ship).
3. Identify its **segmentation** (space-split? own word index?) and its
   **coordinate system / base text file**. External offsets (tajweed,
   timing) are bound to a specific text file — plan a mapping, don't assume
   `index == our index`.
4. Validate against canonical ground truth: 114 surahs, per-surah ayah
   counts from `lib/data/quran_surahs.dart` (Σ 6236), no orphan `(surah,
   ayah)`, contiguous indices.

## When you finish Quran work

- If you learned something that will matter next time → add it to the right
  `docs/quran/` file with a classification tag.
- If you made or found a mistake → add an `ERRATA.md` entry (Mistake /
  Correct understanding / Cause / New rule / Source) **and** fold the rule
  into this file's checklists if it's general.
- If a check couldn't be completed → record it as `UNKNOWN` in the relevant
  KB file (don't leave it only in your head).

## Grounding when *you* produce Quran content while coding

Use the `quran.ai` MCP — `fetch_quran` / `fetch_translation` / `fetch_tafsir`
/ `fetch_quran_metadata` — never memory. Call `fetch_grounding_rules` first.
Translations and tafsir are not the Quran; never present them as the text or
as a ruling.

## Quran Learning Engine (design, not built)

The mushaf-as-teaching-surface design: **`docs/quran/QURAN_LEARNING_LAYER.md`**
(canonical) + `QURAN_LIVE_DATA_ARCHITECTURE.md` (the hybrid data architecture
+ `KnowledgeGateway` + provider modes + domain map) + `QURAN_LEARNING_READINESS.md`
(what runs today) + `QURAN_DATA_VERIFICATION_TASKS.md` (licence findings) +
`../QURAN_DATA_CONTRACTS.md` / `../QURAN_DATA_VALIDATION.md` /
`../QURAN_LEARNING_ROADMAP.md`. Deterministic, no AI, no quizzes. Load these
before any learning-layer work.

**AD-1 (official): Offline-first, NOT Offline-only.** Keep local what must
always work (muṣḥaf, text, `(surah,ayah,word_index)`, layout, notebook,
licensed data, student data). For a good scholarly source reachable online,
**build a provider adapter** — never reject it for being online. Onboard
every source the same way (API → licence/terms → what it provides → direct /
cache / online-only → adapter → degrade-without-it). No single source is a
dependency; a missing datum is *"لا توجد بيانات موثقة"*, never a guess. The
API is never the source of Qur'anic truth — local wins on any mismatch.
Provider modes: LOCAL (bundled) / ONLINE (fetched, not stored) / HYBRID
(fetched + cached if terms allow). One `KnowledgeGateway`, many providers,
per-fact `dataState`.

Verified licences (2026-08-30): MASAQ v5 CC BY 4.0 = bundle · QAC verbatim +
attribution + link, no-modify = bundle (cross-check) · cpfair/quran-tajweed
CC BY 4.0 = bundle (+ offset remap) · MushafDatabase Sadaqa-e-Jaria = bundle
· Quran Foundation word audio = LIVE ONLY (no bundling, <=1-week cache) · QUL
= per-resource, verify each.

## Current open questions (keep in sync with the KB)

- Do Tanzil `page_number` and MushafDatabase `page` place every one of the
  6236 ayat on the same page? (Page-level spot-checks pass; full diff not
  run.) — `QURAN_LAYOUT.md` §7.
- **VT-3:** run the Tanzil <-> MushafDatabase word-alignment tool once ->
  `QURAN_WORD_ALIGNMENT_REPORT.md` + `assets/quran_learning/mapping/*.json`.
  Never modify the text to make numbers match. Blocks on-page rendering of
  external-segmentation (MASAQ/QAC/tajweed) facts until done.
- Mushaf visual delivery: bundle xz-compressed SVGs (~46 MB) vs
  download-per-page + cache — Ismail's call, not made. — `MUSHAF_ENGINEERING.md` §7.
- QUL per-resource licences; a bundle-able word-segmented audio source;
  Itqan / Parallel Quran licences.
- Diacritic / tajweed / recitation-timing layers: not extracted / not built.
