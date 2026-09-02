# Quran Learning — Data Verification Tasks & Findings

**Status: verification log. No code.** The four items the roadmap called
"blockers" are **Engineering Verification Tasks**, not project stoppers.
This file records what has been verified (with links) and what remains.

Rule: **never assume a licence; never treat "licence unknown" as a technical
impossibility.** Design the layer so the data source is swappable
(`QURAN_LIVE_DATA_ARCHITECTURE.md §3`); verify, then bundle or go live.

Classification legend in `docs/quran/SOURCES.md`.

---

## VT‑1 · Morphology & Syntax — QAC / MASAQ

**Question:** can we use QAC and MASAQ for ṣarf + iʿrāb, and may we
redistribute (bundle) them in the app?

### Findings (verified 2026‑08‑30)

**Quranic Arabic Corpus (QAC)** — https://corpus.quran.com/download/
- Terms quoted on the download page:
  - *"Permission is granted to copy and distribute **verbatim copies** of
    this file, but **CHANGING IT IS NOT ALLOWED**."*
  - *"This annotation **can be used in any website or application**, provided
    its source (the Quranic Arabic Corpus) is clearly indicated, and a link
    is made to http://corpus.quran.com"*
  - *"This copyright notice shall be included in all verbatim copies … and
    shall be reproduced appropriately in all works derived from or
    containing substantial portion of this file."*
- **Interpretation:** redistribution **is** permitted for **verbatim,
  unmodified** copies; explicit permission to use "in any application" with
  **source shown + link**. Commercial use not addressed (not prohibited).
  **Modification is prohibited.**
- **`license_use = bundled_ok`** with conditions: keep the QAC file
  **verbatim** in `assets/quran_learning/sources/`, show source + link,
  reproduce the copyright notice. Our normalized `knowledge_facts` table is
  a **separate derived structure that references** the verbatim file, not an
  edit of it.
- Data: morphology **v0.4**, 100% of words; syntax treebank **partial
  (~11,000 words)**.
- `classification = SOURCE-BACKED`; licence `VERIFIED`.

**MASAQ** — https://data.mendeley.com/datasets/9yvrzxktmr/5
- Version **5**, published **2024‑11‑11**. Authors: Majdi Sawalha, Sane
  Yagi, Faisal Alshargi, Bassam Hammo, Abdallah Alshdaifat.
- **Licence: CC BY 4.0** — sharing + adaptation + **commercial** use
  permitted with attribution.
- Content: >131K morphological entries, ~123K syntactic function instances,
  **72 iʿrāb roles**, traditional iʿrāb methodology; TSV/SQLite/CSV/JSON.
  Effectively **full** morphology + syntax coverage.
- **`license_use = bundled_ok`** (attribution: "MASAQ (Sawalha et al.,
  2024) — CC BY 4.0"). Pin **v5**.
- `classification = SOURCE-BACKED`; licence `VERIFIED`.

### Outcome
- **L04 (morphology) and L05 (syntax) are NOT licence‑blocked.** Primary =
  **MASAQ v5** (full coverage, CC BY 4.0). Cross‑check = **QAC** (verbatim,
  attribution+link). Both bundled **offline** (`QURAN_LIVE_DATA_ARCHITECTURE.md`
  L‑MORPH / L‑SYNTAX).
- Remaining work (engineering, not licence):
  1. build‑time importer MASAQ/QAC → compact `knowledge_facts` /
     `syntax_nodes` / `syntax_relations` / `syntax_coverage` tables;
  2. map the 72 MASAQ roles → our closed vocab (`../QURAN_DATA_CONTRACTS.md
     §6`); log unmapped, do not invent;
  3. segmentation mapping (VT‑3) before on‑page rendering;
  4. keep the verbatim QAC source file unmodified; add both to the
     "المصادر والتراخيص" screen.

---

## VT‑2 · Mushaf page visual (SVG)

**Question:** is the SVG art a licence problem? Is its size a reason to
change the design?

### Findings (verified — recorded in `docs/quran/SOURCES.md §3`)
- **MushafDatabase Ligature‑Based SVG V1.01**, licence **"Legal Use and
  Open Permission (Sadaqa‑e‑Jaria)"**: use / copy / modify / publish /
  distribute / derivative works, **including commercial**; only condition —
  no misleading alteration of Qur'anic content.
  https://github.com/mushafdatabase/MushafDatabase-Ligature-Based-SVG
- **Not a licence problem.** Redistribution of a derived/compressed form is
  permitted.
- Size (~380 MB raw, ~46 MB xz, ~55 MB brotli, measured) is an
  **engineering packaging** question, **not** a reason to abandon real‑art
  rendering (`ERRATA.md` E‑1: rendering with a substitute font is the thing
  that was wrong, not the dataset).

### Outcome
- SVG art = the primary visual source. Delivery: a separate downloadable
  **"Mushaf Data Package"** (all 604, xz) or lazy per‑page, then fully
  offline + integrity‑checked (`QURAN_LIVE_DATA_ARCHITECTURE.md` L‑ART).
- Base APK stays light; a third‑party developer can consume the package
  independently.
- Decision still owned by Ismail: *package‑all download* vs *lazy per‑page*.
  No design rework either way.

---

## VT‑3 · Tanzil ↔ MushafDatabase word alignment

**Question:** is our Qur'an text (Tanzil v1.1, `quran_ayat.text_uthmani`)
per‑word identical to MushafDatabase `data-hafs`, and do their word
segmentations line up at `(surah, ayah, word_index)`?

### Status: **verification task, not yet run.** Not a blocker.

We already hold both: MushafDatabase gives `(surah, ayah, word_index)` +
`data-hafs`; Tanzil gives the text (`text_uthmani`) and its own
space‑split tokenisation.

### The tool to build (design only — no code now)

A one‑off, checked‑in verification script (Dart `tool/` or Python, like
`extract_mushaf_svg.py`) that does **only**:

```
for each (surah, ayah) in 1..6236:
    T  = tokens of quran_ayat.text_uthmani        (Tanzil space-split)
    M  = mushaf_words for (surah, ayah)           (MushafDatabase, word_index order,
                                                   excluding word_type ∈ {juz_star, sajda_mehrab})
    align T ↔ M by position, then by normalized-text match
    classify each pair:
        MATCH            normalizeArabicForSearch(T_i) == normalizeArabicForSearch(M_j)
        MISMATCH_TEXT    same position, different normalized text
        SPLIT/MERGE      one side's token maps to a range on the other
        UNMAPPED         no counterpart
    record raw + normalized forms, positions, and (for MISMATCH) the codepoint diff
emit assets/quran_learning/mapping/tanzil_to_mushafdb.json   (the mapping)
emit docs/quran/QURAN_WORD_ALIGNMENT_REPORT.md               (the summary)
```

**Rules:** it **never modifies** either text to make numbers match. A
MISMATCH is recorded with its cause (dabt difference, spelling variant,
tokenisation choice), not hidden.

### Report template → `docs/quran/QURAN_WORD_ALIGNMENT_REPORT.md`

```
# Tanzil ↔ MushafDatabase — Word Alignment Report
Generated:      <date>   |   Tanzil: v1.1   |   MushafDatabase: V1.01
Total ayat:                 6236
Total Tanzil tokens:        <n>
Total Mushaf text words:    <n>   (excl. 199 juz-star + 15 sajda-mehrab)
MATCH:                      <n>  (<pct>%)
MISMATCH_TEXT:              <n>   → table: (s,a,pos) Tanzil | Mushaf | diff | cause
SPLIT / MERGE:              <n>   → table of ranges
UNMAPPED:                   <n>   → table
Ayat fully aligned:         <n> / 6236
Notes / causes found:       <bullets>
Decision:                   tanzil-space ⇔ mushafdb-v1.01 mapping is
                            [reliable at word level] / [needs per-ayah exceptions]
```

### Why it matters
The learning chain is `Mushaf Word → Morphology → Syntax → Tajweed → Audio →
Notebook`. Word identity must be stable across all of them. Tajwīd offsets
(cpfair) are on the Tanzil base; morphology/syntax (MASAQ/QAC) are on their
own bases. All must resolve to **one** `mushafdb-v1.01` `word_index`. This
report + `assets/quran_learning/mapping/*.json` are the bridge. Until it's
run, external‑segmentation facts stay `mapping_status = unmapped` and render
in a text view only (`../QURAN_DATA_VALIDATION.md §M`, §D5).

---

## VT‑4 · Word‑level audio

**Question:** is there word‑by‑word audio + timing, and may we store /
bundle / redistribute it?

### Findings (verified 2026‑08‑30)

**Quran Foundation Audio API** —
https://api-docs.quran.com/docs/sdk/javascript/audio/
- `word.audioUrl` exists (relative `wbw/...`, resolved against
  `https://audio.qurancdn.com/`) — **public CDN assets**.
- Word‑level **segments / timestamps** available (`segments: true` on
  chapter/verse recitation; word‑level `segments` array).
- Multiple reciters (`reciterId` for chapter, `recitationId` for ayah — not
  interchangeable). Format e.g. `mp3`.
- The docs state: *"Audio returned by the APIs is QF Content. Review the
  Quran Foundation Developer Terms before implementing storage, offline
  playback, redistribution, or commercial use."*

**Quran Foundation Developer Terms** —
https://api-docs.quran.foundation/legal/developer-terms/
- *No caching / storing QF Content longer than **1 week***, except via the
  **Content Sync APIs** (which require re‑syncing **at least every 7 days**);
  Content Sync **excludes** Mushaf font files / images.
- *"QF Content and raw API data are **not sold, sublicensed, or
  redistributed**"* without a separate commercial licence.
- Commercial apps allowed (charge / subscription / ads / freemium) **as
  long as** QF Content is *"displayed only as part of the Application's
  end‑user experience"* and not resold.
- Attribution: preserve original context; explicit attribution text not
  mandated but expected in an "About sources" surface.

### Outcome
- **Audio = LIVE / stream only.** **Do NOT bundle. Do NOT persistently
  cache.** Session buffer only; purge within 7 days / on exit
  (`QURAN_LIVE_DATA_ARCHITECTURE.md` L‑AUDIO).
- The "🔊 استماع" control is disabled offline with a clear message. Text
  layers (iʿrāb, ṣarf, tajwīd) are unaffected.
- Reciter name + "عبر Quran Foundation API" shown at play time; never
  presented as our file.
- **Open:** find a word‑segmented recitation whose licence **does** allow
  bundling (would let audio go offline). None found yet. Or make a
  deliberate decision to adopt **Content Sync** (accepting the ≤7‑day
  re‑sync obligation) for a longer local audio window.

### Credentials status (2026‑08‑30)
- Ismail has registered **QF OAuth clients** (a *confidential* client:
  `client_id` + `client_secret`), scopes granted: **`content`**
  (translations/tafsirs), **`offline_access`** (refresh tokens),
  `comment.read` / `post.read` (QuranReflect).
- The secret **must never ship in the app** (extractable by decompiling) and
  **QF docs forbid calling the token endpoint from mobile code**. Secrets
  therefore live **server‑side only** or in gitignored `lib/config/app_config.dart`
  as a stopgap — **never in a tracked file, never in these docs.** If they
  were pasted into a chat, **rotate them** in the QF dashboard.
- The scaffold already exists and is deliberately inert:
  `lib/services/quran_audio/quran_foundation_provider.dart`
  (`isConfigured = false`); `EveryAyahProvider` serves audio meanwhile.
- **Real dependency to build first:** a tiny **server‑side token‑proxy
  endpoint** the app calls (`AppConfig.qfTokenProxyUrl`) that does the
  `client_credentials` exchange with `oauth2.quran.foundation` and returns a
  short‑lived access token. Only then can `QuranFoundationProvider` /
  `L‑AUDIO` / QF `content` go live. The Developer‑Terms constraints above
  are **unchanged** by having credentials — still LIVE‑only, ≤1‑week cache,
  no redistribution.
- This does **not** affect the main learning‑chain gap (Word → Knowledge =
  MASAQ/QAC/tajwīd‑span data, unrelated to QF), and the **MVLD**
  deliberately excludes audio for this reason.

---

## VT‑5 · QUL per‑resource licences  (added)

**Findings:** https://qul.tarteel.ai/faq — *"resources … vary in their
copyright status. Some are in the public domain, while others may be subject
to specific licenses … review the licensing information provided by each
resource's author."* Commercial use allowed **per resource**.

**Outcome:** QUL is **not** one licence. Each resource we want (word‑by‑word
meaning, mutashābihāt, topics, Tajweed V4 cross‑check) must be verified
individually before bundling. Until then: `license_use = verify_per_resource`;
in the gateway, treat as **HYBRID** (live via our proxy + cache) rather than
bundling.

---

## Summary — what these tasks changed

| item | old framing | verified outcome |
|---|---|---|
| QAC / MASAQ (morphology, iʿrāb) | "licence-blocked, study-only" | **bundle-able** — MASAQ CC BY 4.0; QAC verbatim + attribution+link. Offline. |
| Mushaf SVG art | "size blocker" | not a licence issue; **packaging choice** (downloadable package / lazy). |
| Tanzil ↔ MushafDatabase | "unknown blocker" | a **verification task** — tool + report designed; run once, don't fudge. |
| Word audio | "no source / unknown" | **source exists**; **licence forbids bundling** → **LIVE only**, ephemeral. |
| QUL resources | (implicit) | **per-resource** — verify each; HYBRID until then. |

The learning architecture does not need redesigning for any of this — only
the adapter per layer and its offline/online flag change.
