# Quran Learning — Scholarly Sources & Licences

**Status: DESIGN ONLY. No data ingested.** Companion to
`QURAN_LEARNING_ARCHITECTURE.md`. This registers the **teaching-content**
sources (morphology, iʿrāb/syntax, tajwīd, tafsīr, word-meaning, hadith
links). The **text + layout** sources (Tanzil, MushafDatabase, KFGQPC, …)
are in `docs/quran/SOURCES.md` — not repeated here.

For every source: **what we take · licence · what we must NOT take ·
coverage · classification**. Nothing here is confirmed for bundling until it
passes the pipeline in §Z and `QURAN_DATA_VALIDATION.md`.

Classification legend: `VERIFIED | SOURCE-BACKED | PROJECT-SPECIFIC |
INFERENCE | UNKNOWN` (see `docs/quran/SOURCES.md`).

---

## A. Morphology (ṣarf) — Layer 04

### A1 · Quranic Arabic Corpus (QAC) — morphology  ·  **licence VERIFIED 2026‑08‑30**
- **URL:** https://corpus.quran.com/ · download https://corpus.quran.com/download/
- **Version:** morphology **v0.4** (100% of words); syntax treebank **partial (~11k words)**.
- **Licence (verified, quoted on the download page):** copy + distribute
  **verbatim** copies allowed; **CHANGING IT IS NOT ALLOWED**; *"can be used
  in any website or application, provided its source (the Quranic Arabic
  Corpus) is clearly indicated, and a link is made to http://corpus.quran.com"*;
  copyright notice reproduced in derived works. Commercial use not
  addressed (not prohibited).
- **`license_use = bundled_ok`** — conditions: keep the QAC file **verbatim**
  in `assets/quran_learning/sources/` (no edits), show source + link,
  reproduce the notice. Our normalized tables are a **separate derived
  structure referencing** it, not an edit.
- **What we take:** per-word `root`, `lemma`, `stem`, POS, morpheme
  segments, features, pattern — as a **cross-check** against MASAQ.
- **What we must NOT do:** modify the QAC file; omit the link; treat its
  word index as `mushafdb-v1.01` (needs the VT‑3 mapping).
- **Class:** `SOURCE-BACKED` (content); licence `VERIFIED`.

### A2 · MASAQ — Morphologically-Analyzed & Syntactically-Annotated Quran  ·  **licence VERIFIED 2026‑08‑30**
- **URL:** Mendeley Data https://data.mendeley.com/datasets/9yvrzxktmr/5 ·
  ScienceDirect (Data in Brief, 2024) · PubMed 39830618.
- **Version:** **v5**, published 2024‑11‑11. Authors: Majdi Sawalha, Sane
  Yagi, Faisal Alshargi, Bassam Hammo, Abdallah Alshdaifat. **Pin v5.**
- **Licence:** **CC BY 4.0** (verified on the v5 page) — share + adapt +
  **commercial**, with attribution.
- **`license_use = bundled_ok`** — attribution: "MASAQ (Sawalha et al.,
  2024) — CC BY 4.0".
- **What we take:** >131K morphological entries + ~123K syntactic function
  instances; **72-role** iʿrāb tagset; traditional-iʿrāb methodology;
  TSV/SQLite/CSV/JSON. **Primary source for Layers 04 + 05** (effectively
  full coverage).
- **What we must NOT do:** assume the 72 roles map 1:1 to our closed vocab
  (`QURAN_DATA_CONTRACTS.md §6`) — map, log unmapped, don't invent; treat
  its segmentation as ours (needs the VT‑3 mapping).
- **Class:** `SOURCE-BACKED` (content); licence `VERIFIED`.

### A3 · The Quranic Treebank (NoorBayan/Quranic)
- **URL:** https://github.com/NoorBayan/Quranic
- **What it is:** extended **CoNLL-X** per-token treebank bridging computation
  to traditional iʿrāb; multi-layered hybrid syntactic annotation.
- **Licence:** repo licence — **verify** (`unknown`).
- **Use:** cross-check / second opinion for Layer 04–05; not primary.
- **Class:** `SOURCE-BACKED`.

### A4 · Community morphology mirrors (e.g. `mustafa0x/quran-morphology`)
- Derived from QAC → **inherits GPL**. Convenience only; same licence limit.
- **Class:** `INFERENCE` (mirror fidelity not audited).

---

## B. Syntax / iʿrāb (naḥw) — Layer 05

### B1 · Quranic Arabic Dependency Treebank (QADT, part of QAC)
- **URL:** https://corpus.quran.com/treebank.jsp · guidelines PDF (Dukes &
  Buckwalter).
- **Coverage:** **PARTIAL — ~11,000 words** manually annotated as a gold
  standard (out of 77,430). `VERIFIED` from the source.
- **Model:** dependency edges, tag set taken from **traditional Arabic
  grammar** (iʿrāb), mapped to English terms; VSO order handled.
- **Licence:** QAC terms (verbatim-ok + attribution+link + no-modify — see
  A1). `license_use = bundled_ok` (verbatim, no-modify).
- **What we must NOT assume:** that every ayah has a tree — most don't.
  `QURAN_LEARNING_ARCHITECTURE.md` A5 (honest gaps) is mandatory here. Use
  only as a **cross-check** of MASAQ where both exist.
- **Class:** `VERIFIED` (coverage + licence), `SOURCE-BACKED` (content).

### B2 · MASAQ syntax  — see A2.  ·  **PRIMARY for Layer 05**
- Full iʿrāb coverage, 72-role tagset, **CC BY 4.0 (verified)** →
  `license_use = bundled_ok`. Offline (`QURAN_LIVE_DATA_ARCHITECTURE.md`
  L‑SYNTAX). QAC treebank is the ~11k-word cross-check.

### B3 · Classical iʿrāb reference works — **the authoritative basis for P0**
The iʿrāb layer must be built on **named classical Quran-iʿrāb works**, not
on "derived from morphology + agreed grammar" (Ismail 2026-08-30: that
phrasing must not pose as an independent authentic source).

| work | author (d.) | notes | digitised |
|---|---|---|---|
| **التبيان في إعراب القرآن** | أبو البقاء العكبري (616هـ) | 2 vols, taḥqīq al-Bajāwī | shamela.ws/book/22928 · archive.org/details/tfiqtfiq |
| **الجدول في إعراب القرآن** | محمود صافي (contemporary) | 16 juzʾ; iʿrāb + ṣarf + bayān + naḥw notes — the most feature-complete | shamela.ws/book/22916 |
| **إعراب القرآن وبيانه** | محيي الدين الدرويش (1403هـ) | 10 vols | shamela.ws/book/2163 |
| **مشكل إعراب القرآن** | مكي بن أبي طالب القيسي (437هـ) | contested/difficult spots | — |
| **إعراب القرآن** | أبو جعفر النحاس (338هـ) | earliest of the five | — |

- **Licence:** the *works* are public-domain; a specific **printed edition /
  digital typesetting** may carry publisher rights. Shamela/archive.org
  digitisations are widely cited. `license_use` per edition — for the app,
  **author the block with a citation** (`book / vol / page`), a faithful
  rendering, **not** a wholesale copy of a copyrighted edition, **not**
  AI-written. → `src:irab-classical` (Prototype: `bundled_ok` as a faithful
  cited rendering; `SOURCE-BACKED`, `classical_scholarly`).
- **When MASAQ's file is placed**, its 72-role iʿrāb tagset (CC BY 4.0)
  becomes the structured primary; the classical works stay the prose +
  cross-check.
- **Class:** `SOURCE-BACKED` per citation.
- No public **REST API** dedicated to Quran iʿrāb was found (QAC/
  corpus.quran.com expose no documented iʿrāb endpoint; MASAQ is
  download-only). If one appears → register it as an ONLINE grammar
  provider adapter in the gateway (`QacGrammarProvider` is the slot).

---

## H. Balāgha / iʿjāz — the البيان/الإعجاز track (design only, NOT P0)

A **parallel** domain family to iʿrāb: *ayah → a documented rhetorical /
linguistic aspect → its source → explanation → Quranic examples*. Sub-kinds:
`ijaz_bayani`, `nazm`, `balagha`, `taqdim_takhir`, `hadhf_dhikr`,
`tarif_tankir`, `ikhtiyar_alfaz`, `tanasub`.

**Hard rule:** the app **never infers iʿjāz**. Every aspect cites a **named**
work by book / edition / page. Candidate classical/authoritative sources:

| work | author (d.) |
|---|---|
| **دلائل الإعجاز** · **أسرار البلاغة** | عبد القاهر الجرجاني (471هـ) |
| **الكشاف** | الزمخشري (538هـ) |
| **البرهان في علوم القرآن** | الزركشي (794هـ) |
| **الإتقان في علوم القرآن** | السيوطي (911هـ) |
| **إعجاز القرآن** | الباقلاني (403هـ) |
| **الإيضاح في علوم البلاغة** | الخطيب القزويني (739هـ) |
| **النبأ العظيم** / **من بلاغة القرآن** | محمد عبد الله دراز / أحمد أحمد بدوي |
| **التحرير والتنوير** | ابن عاشور (1393هـ) — already bundled as tafsīr |

- **Licence:** works public-domain; modern printed editions per publisher →
  `link_only` unless an openly-licensed digital text is found.
- No structured open dataset of "rhetorical aspect per ayah" exists — this
  is a **curation task** citing the above.
- `src:balagha-classical` is registered (`UNKNOWN` / `link_only`, **not used
  by any fact**) as the placeholder.
- **Class:** `SOURCE-BACKED` per future citation.

---

## C. Tajwīd — Layer 06

### C1 · cpfair/quran-tajweed
- **URL:** https://github.com/cpfair/quran-tajweed
- **Version:** rule file dated 2017-04-06.
- **Licence:** rule data **CC BY 4.0**; underlying text = Tanzil terms.
  `license_use = bundled_ok` for the rule annotations (with attribution).
- **What we take:** 18 rules (`ghunnah`; `idghaam` ×5; `ikhfa` ×2; `iqlab`;
  `madd` ×5; `qalqalah`; `hamzat_wasl`; `lam_shamsiyyah`; `silent`) as
  `{surah, ayah, annotations:[{rule, start, end}]}`.
- **What we must NOT assume:** `start/end` are **codepoint offsets into that
  exact Tanzil Uthmani file**. They do **not** transfer to our
  `quran_ayat.text_uthmani` (if it differs by one mark) or to MushafDatabase
  geometry without rebuilding. → a mapping/rebuild step is mandatory
  (`QURAN_DATA_VALIDATION.md §M`).
- **What we must NOT do:** hard-code its (or any) colours. Store `rule_id`.
- **Class:** `SOURCE-BACKED`; offsets `PROJECT-SPECIFIC` risk.

### C2 · QUL "Tajweed V4" / QPC tajwīd word data
- **URL:** https://qul.tarteel.ai/docs/v4-tajweed · https://qul.tarteel.ai/resources
- **What it is:** word-level tajwīd rule data aligned to QPC glyph fonts;
  the de-facto standard **palette** reference (KFGQPC).
- **Licence:** per-resource on QUL — **verify**; fonts inherit KFGQPC terms.
- **Use:** cross-check C1; the palette *reference* (we still store `rule_id`
  and pick colour in-app).
- **Class:** `SOURCE-BACKED`.

### C3 · Classical tajwīd references (for `LearningConcept` blocks)
- e.g. *التمهيد في علم التجويد* (ابن الجزري), *هداية القاري*, *غاية المريد*,
  matn *تحفة الأطفال* / *المقدمة الجزرية* (public-domain matns).
- **Use:** the explanation/cause/articulation prose in tajwīd concepts, with
  citation. Matns (تحفة الأطفال، الجزرية) are safely public-domain.
- **Class:** `SOURCE-BACKED` per citation.

### C4 · Audio for a marked spot (`TajweedRule.audio_ref_id`)
- Only a **verified recitation** with a known reciter + licence. Candidates:
  Tarteel/QUL recitations with word segments, EveryAyah (per-ayah, various
  licences).
- **What we must NOT do:** clip audio we don't have rights to; present a
  clip without reciter attribution.
- **Class:** `UNKNOWN` until a licensed word-segmented source is chosen.

---

## D. Tafsīr & word-meaning — Layer 07

### D1 · Tafsīr editions already in the repo
- `assets/quran/tafsir-*.jsonl.gz`: AR — `ibn_kathir`, `saadi`, `muyassar`,
  `ibn_ashur`, `almukhtasar`; + **44** language translation-tafsir editions
  (added `oromo_ababor` 2026-09-12, translator Ghali/Gali Ababor — Ismail
  is in Ethiopia and asked specifically about Oromo; verified live on
  quranenc.com, complete for all 114 sūrahs).
- **Source/licence:** mostly via KFGQPC (spa.qurancomplex.gov.sa) / QuranEnc
  / Tanzil trans — **CC-BY family**; attribution on the "About sources"
  screen. `TafsirMuyassar` is an official KFGQPC edition.
- **What we take:** verbatim entries per ayah/range, per edition.
- **What we must NOT do:** summarise, paraphrase, merge editions into "the
  tafsīr", or present a translation as the Quran (mirrors `quran.ai` MCP
  grounding rules).
- **Class:** `VERIFIED` (present, in use since Phase 72).
- **2026-09-12 upgrade — footnotes field**: every one of the 44 language
  editions was re-fetched via `tool/fetch_quranenc_footnotes.py`, this time
  keeping QuranEnc's `footnotes` field (real explanatory notes — e.g. a
  hadith on a sūrah's virtue) alongside `translation`, which the original
  `tool/fetch_quranenc_translations.dart` discarded. 26,871 real footnote
  rows captured across the 44 editions (0 fabricated — many editions
  genuinely have none; Urdu/Bengali/Japanese have thousands). Stored in a
  new `tafsir_entries.footnote` column (DB v62), shown as a separate
  labelled "شرح توضيحي من المصدر" layer in `AyahStudyScreen`'s reader —
  never merged into the translation text itself. See
  `docs/quran/TAFSIR_UNIFIED_ARCHITECTURE.md §5`.
- **2026-09-12 follow-up — 3 dead/deprecated keys found and swapped**: a
  full live audit of all 43 non-Arabic keys (`tool/audit_quranenc_editions.py`)
  after the Somali finding turned up two more editions that were both
  missing from quranenc.com's current catalog *and* footnote-less —
  `albanian_rwwad` (→ **`albanian_nahi`**, 405 real footnotes) and
  `uzbek_rwwad` (→ **`uzbek_mansour`**, 527 real footnotes) — on top of the
  earlier `somali_abduh` → `somali_yacob` swap. DB v64. 7 languages
  (Bulgarian, Belarusian, Kazakh, Circassian, Malay, Luganda, Greek) were
  confirmed to have **no** footnote-bearing edition currently offered by
  QuranEnc at all — a genuine source gap, not a bug, left as-is.

### D2 · Word-by-word meaning
- **QUL word-by-word translations** (multi-language, JSON/CSV/SQL, open) —
  https://qul.tarteel.ai/resources — the preferred source.
- **quranwbw** (github.com/marwan/quranwbw) — word-by-word companion; check
  data licence.
- **rootwordsofquran.com** — root-grouped meanings; licence `unknown`.
- **What we must NOT do:** treat a word gloss as tafsīr; use `Kalimat API`
  (AI-powered — violates A1).
- **Class:** `SOURCE-BACKED` (QUL), `UNKNOWN` (others).

### D3 · Asbāb al-nuzūl
- Present as `tafsir_entries.asbab_nuzul_excerpt`. Also standalone works
  (الواحدي, السيوطي — public-domain). Attribute per excerpt.
- **Class:** `SOURCE-BACKED`.

---

## E. Hadith ↔ ayah linkage — Layer 10 (future)

### E1 · Itqan (R3GENESI5/Itqan)
- **URL:** https://github.com/R3GENESI5/Itqan
- **What it is:** computational Quran–Hadith concordance (~1.5M links,
  96.3% root coverage) + open narrator DB (115,735 profiles).
- **Licence:** **verify** repo licence (`unknown`).
- **Use (future):** `KnowledgeEdge` `ayah ──explained_by/related_to──▶ hadith`
  for the "📚 الأحاديث المرتبطة" row. Must show the hadith's own
  source/grading, not just a link.
- **Class:** `SOURCE-BACKED` (claims), `UNKNOWN` (licence, per-link precision).

### E2 · Parallel Quran cross-references
- **URL:** https://parallelquran.com/cross-references/
- Verse↔hadith↔tafsīr↔theme cross-references. Licence `unknown`.
- **Class:** `INFERENCE` until audited.

### E3 · Existing project hadith assets
- `assets/hadith/nawawi40.json` (40 Nawawi). Small, curated. Attribute.
- **Class:** `VERIFIED` (present).

---

## F. Structural / thematic — Layer 10

- **QUL topics & themes**, **mutashābihāt** (near-identical ayah pairs — high
  value for ḥifẓ review), **surah info** — https://qul.tarteel.ai/resources.
  Licence per-resource. `SOURCE-BACKED`.
- **Tanzil metadata** (`quran-data.js`) — juz/hizb-quarter/sajda/ruku — CC-BY
  3.0, already in repo. `VERIFIED`.

---

## G. Runtime grounding tool (not shipped)

- **quran.ai MCP** — `fetch_word_morphology`, `fetch_word_concordance`,
  `fetch_word_paradigm`, `fetch_tafsir`, `fetch_quran_metadata`. Use **while
  designing/authoring** to verify a claim or a `LearningConcept` example
  against canonical data. **Not** a build dependency; **not** an in-app
  data source (it's a dev-session tool). Its morphology output can serve as
  a **cross-check** against MASAQ/QAC during validation.

---

## Z. From a research point to shippable data — the pipeline

Applies to **every** teaching fact, including all 100 research points from
the earlier learning task. **A point in a list is a `CLAIM`, not data.**

```
CLAIM               a statement we might put in the app
  │
  ├─ SOURCE VERIFICATION   name the exact source, retrieve it, read it
  │
  ├─ AUTHORITY             classical_scholarly | academic_peer_reviewed |
  │                        institutional | community | unverified
  │
  ├─ VERSION               pin the dataset/edition version
  │
  ├─ LICENSE               SPDX/exact; set license_use ∈
  │                        {bundled_ok, link_only, study_only, unknown}
  │
  ├─ CROSS-CHECK           ≥2 independent sources agree  → VERIFIED
  │                        1 authoritative source        → SOURCE-BACKED
  │                        sources disagree              → CONFLICT (below)
  │
  └─ APPROVED DATA         a row with a SourceReference and a classification;
                           only VERIFIED / SOURCE-BACKED may back a displayed
                           scholarly claim. INFERENCE/UNKNOWN may only annotate
                           gaps.
```

### CONFLICT handling
- Two sources disagree on a fact (e.g. POS of a word, an iʿrāb role, a
  tajwīd rule at a spot) → **do not pick one myself**.
- Record a `CONFLICT` entry: `{anchor, field, option_A:{value, source_ref_id},
  option_B:{value, source_ref_id}, status: open}`.
- UI behaviour: show **both**, each attributed, marked "اختلفت المصادر".
- A `CONFLICT` is resolved only by: (a) a higher-authority source settling
  it, or (b) Ismail's explicit decision — logged.
- `CONFLICT`s are listed in `QURAN_DATA_VALIDATION.md`'s conflict register.

### License gate (hard)  ·  updated after `docs/quran/QURAN_DATA_VERIFICATION_TASKS.md` (2026‑08‑30)
- `license_use ∈ {study_only, unknown}` → **may inform design, must not be
  bundled or shipped**. Currently: **QUL resources** (per-resource,
  unverified), **classical iʿrāb/tajwīd printed editions** (per edition),
  **Itqan / Parallel Quran** (unverified), **quranwbw** (unverified).
- `license_use = link_only / api_stream_only` (use live, never bundle):
  **Quran Foundation word audio + timing** — Developer Terms forbid storing
  QF Content > 1 week / redistribution.
- **Cleared to bundle (offline):**
  - **MASAQ v5** — CC BY 4.0 *(verified)* — primary for morphology + syntax;
  - **QAC** — verbatim + attribution + link, **no modification** *(verified)* — cross-check;
  - **cpfair/quran-tajweed** — CC BY 4.0 (+ offset remap);
  - our existing tafsīr editions (CC-BY family);
  - Tanzil text + metadata (CC-BY 3.0, no modification);
  - **MushafDatabase V1.01** SVG + layout (Sadaqa-e-Jaria);
  - public-domain matns (تحفة الأطفال، الجزرية) for concept prose.

### Open licence questions (`UNKNOWN` — must resolve before ingesting *those*)
1. QUL per-resource licences (word-by-word meaning, mutashābihāt, topics,
   Tajweed V4 cross-check).
2. A word-segmented recitation audio source whose terms **allow bundling**
   (would let `L‑AUDIO` go offline). None found — audio stays live.
3. Itqan / Parallel Quran licences for the ḥadīth-link layer.
4. Openly-licensed digital editions of classical iʿrāb/tajwīd books for
   `LearningConcept` prose (else authored-with-citation only).

*(Resolved 2026‑08‑30: MASAQ = CC BY 4.0, bundle-able. QAC = verbatim
redistribution permitted with attribution + link, bundle-able. Mushaf SVG
size = an engineering packaging choice, not a licence blocker.)*
