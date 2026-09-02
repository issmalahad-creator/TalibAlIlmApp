# Quranpedia Corpus — Integration Audit & Plan

Status: **AUDIT + PLAN. Not started, not approved for build.** Ismail brought
the Quranpedia.net data dumps (2026‑09‑03) and asked to fold them into the
Quran experience. This doc inventories what arrived, states the licences, and
sequences the work. **No integration code until the Mushaf Rendering Engine
ships (604/604 QA + real‑device)** — one active front at a time (CLAUDE.md).

This is **not a fifth parallel plan.** It folds into the two existing designs:
- teaching-content providers → `docs/QURAN_LEARNING_ARCHITECTURE.md` +
  `docs/quran/QURAN_LIVE_DATA_ARCHITECTURE.md` (the `KnowledgeGateway` +
  provider-mode model; several providers — e.g. `QacGrammarProvider` — are
  currently inert and this corpus fills them).
- the cloud mirror + delta sync + on-demand cache →
  `docs/SUPABASE_ARCHITECTURE.md` (reference tables + a `quran-proxy` Edge
  Function, the same shape as the planned `turath-proxy`).

Load `.claude/skills/quran-engineering` first. New sources added to
`docs/quran/SOURCES.md` §13 (Quranpedia corpus) + §14 (saikothasan API).

---

## 1. What arrived — inventory (verified 2026‑09‑03)

Raw dumps at repo root, **~1.15 GB total**, now git-ignored. Each file is a
Quranpedia **official versioned dump** (`{license, schema, data}` envelope,
`license.version` + `license.resync` fields) — obtained the sanctioned way,
not scraped.

| dump | size (zip) | content | grain | integrity |
|---|---|---|---|---|
| `mushafs-all.zip` | 5 MB | **14 riwāyāt** — full Quran text per canonical qirāʾa | per ayah | `mushafs-1` = مصحف حفص: **6236 ayat / 114 surahs ✓** canonical |
| `surahs.json.gz` | 193 KB | 114 surah info records (introduction, HTML `information`) | per surah | 114 ✓ |
| `services-all.zip` | 28 MB | **15 per-ayah service indexes**: `morphology` (6236), `e3rab` (6236), `meanings` (4799), `qiraat` (3455), `notes` (5653), `similar`, `syntax`, `tafsir`, `topics`, `translations`, `asbab`, `nasekh`, `fatwa`, `mutshabeh` | per `(surah,ayah)` | morphology & e3rab cover all 6236 |
| `tafsir_books-all.zip` | **900 MB** | **149 tafsir books**, full HTML content for all 6236 ayat each (Ṭabarī, Ibn Kathīr, Qurṭubī, Baghawī, Saʿdī, Muyassar, Jalālayn, …) | per `(book, surah, ayah)` | book 1 = 6236 ayat ✓ |
| `e3rab_books-all.zip` | 5 MB | 4 iʿrāb books (180 المجتبى · 309 · 316 إعراب القرآن · 318) | per `(book, surah, ayah)` | + `LICENSE.md` |
| `asbab_books-all.zip` | 713 KB | 2 asbāb al-nuzūl books (460 · 2919) | per `(book, surah, ayah)` | + `LICENSE.md` |
| `nasekh-book-2391.json.gz` | 135 KB | 1 nāsikh & mansūkh book (2391) | per ayah | |
| `fatwas.json.gz` | 4 MB | **3575 fatwas** (`ar_title/ar_question/ar_answer/…`) | per fatwa (ayah-tagged) | 3575 |
| `topics-index.json.gz` | 163 KB | **6100 Quranic topics**, each `{id, name, parent_id, ayahs:"7:26"}` (tree) | per topic | 6100 |
| `reciters-index.json.gz` | 13 KB | **253 reciters/recitations**, `{id, name, surahs_list}` | per reciter | 253 |
| `books-all.zip` | 2.6 MB | **16,296-book master catalog** (`books.json.gz`) + `related-books.json.gz`. by `type`: tafsir 3728, qiraat 2177, book 9084, asbab 284, nasekh 208, e3rab 264, translations 221, mutshabeh 137, … | per book | metadata only; content = the dumps above |
| `categories-all.zip` | 15 KB | category taxonomies (books / fatwas / notes / index) | | tiny |
| `other-all.zip` | 15 MB | `sayings.json.gz` (athar/aqwāl linked to ayat, 15 MB) · `attachments.json.gz` · `surahs-index.json.gz` | | |
| `translations-all.zip` | 62 MB | **139 translation editions** (`1947.json`..`~2085.json`, ~370 MB unzipped) | per `(edition, surah, ayah)` | **licence caveat — §3** |

**Everything on Ismail's list arrived.** Nothing missing from the dump set.
(See §7 for the smaller things that would still help.)

### Ayah record shape (`mushafs-1`)

```
{ id, number, surah, page_number, text, marker (ﰀ …), juz, hizb, ruku,
  manzil, options:[tafsir,meanings,similar,qiraat,e3rab,notes,asbab,
  translations,sayings], number_in_hafs:[…] }
```

`options[]` = which services exist for that ayah (this replaces guessing).
`page_number` is **Quranpedia's own** page scheme — see §5.

---

## 2. Licence — the crux

### 2.1 Quranpedia dump licence (`svg2/LICENSE.md`, version 2026‑09‑02)

- **Free to use inside apps, websites, bots, research tools — no attribution
  required** (a visible link to quranpedia.net is appreciated).
- **Attribution + dump-version required ONLY if we re-publish the dataset
  itself as a downloadable database.** Bundling a *derived, curated artifact*
  inside the app is "use inside an app" → free. We will still credit
  Quranpedia on the "About sources" screen (right thing to do).
- **Obligation: keep any shipped copy current** via
  `GET https://quranpedia.net/api/v1/changes?since=<version>` — *"distributing
  outdated Quranic text is the distributor's responsibility."* This is a
  **hard requirement**, not optional (§6).
- The public API is 120/min, 10k/day, *"not a download service"* — bulk
  scraping is prohibited; the **versioned dumps** (what we have) are the
  sanctioned bulk path.

### 2.2 Third-party carve-outs (the dump licence does NOT override these)

| field | source | licence | our obligation |
|---|---|---|---|
| **word morphology** (POS, root, lemma, case, mood, verb form) — `services/morphology.json.gz` | Quranic Arabic Corpus v0.4, Dr. Kais Dukes, Univ. Leeds | **GNU GPL** | bundle verbatim, **no modification**, **visible "Quranic Arabic Corpus — corpus.quran.com" credit + link**. GPL for *data* (not linked code): distribution is fine with attribution; if we ever transform it, the transform is GPL. Keep it in its own asset, un-forked. |
| **iʿrāb syntax** (dependency relations, heads, constituents) — `services/syntax.json.gz` | The Quranic Treebank (github.com/NoorBayan/Quranic) | **MIT** | attribution only |

### 2.3 Content that stays under its author's copyright

- **Translations** (`translations-all.zip`, 139 editions) — *"remain the IP of
  their respective authors and publishers."* Quranpedia's licence grants us
  **nothing** here. **Per-edition review required** (same discipline as
  `docs/QURAN_SOURCES_AND_LICENSES.md` for tafsir editions): ship bundled
  only the ones that are public-domain or explicitly CC/QuranEnc-licensed;
  everything else is online-fetch-only or omitted. We already ship ~40
  language editions via QuranEnc/rwwad — cross-check IDs, don't duplicate.
- **Contemporary tafsir / iʿrāb / fatwa books** — classical works
  (Ṭabarī, Qurṭubī, Ibn Kathīr, …) are *"shared heritage, no one claims
  ownership"* → free. **Modern editions with a living author** (e.g. some in
  the 149) — treat like translations: check `book.publish_year` / `author`,
  bundle only clearly-free ones, mirror the rest for online-fetch.

### 2.4 saikothasan/quran-api

MIT. 11 languages + transliteration, no audio, data source unstated. Minor —
redundant with the Quranpedia mushafs for text. Keep only as a **fallback
translation provider adapter** (AD‑1 style) or a cross-check, low priority.

---

## 3. Role per dataset

Driven by size (APK is already ~250–330 MB) and licence.

### BUNDLE (curated subset → `assets/quran/…`, offline-first)

| what | why bundle | size est. |
|---|---|---|
| **Hafs mushaf text** (`mushafs-1`) — as a cross-check / `text_imlaey` companion to our Tanzil `quran_ayat` | already have Tanzil Uthmani; this adds Quranpedia's dabt + `marker` + `number_in_hafs` | ~0.4 MB gz |
| **`surahs.json.gz`** — surah introductions | small, high value for the reader header / study | ~0.2 MB gz |
| **`services/morphology.json.gz`** (QAC, GPL, verbatim) | fills the inert `QacGrammarProvider` — the ṣarf layer the Learning Engine was designed around | 3.5 MB gz |
| **`services/syntax.json.gz`** (Treebank iʿrāb, MIT) | fills the naḥw/iʿrāb layer | ~1 MB gz |
| **`services/meanings.json.gz`** — غريب القرآن word meanings | per-word meaning tier of the Word Knowledge Surface | ~0.7 MB gz |
| **`services/notes.json.gz`** — sourced فوائد/وقفات | the "notes" tier + seeds for the Ayah Notebook | 9.8 MB gz — maybe trim to top authors |
| **`topics-index.json.gz`** (6100) | **the Knowledge Index backbone** (topic → ayah-range), `SUPABASE_ARCHITECTURE §4.6` | 0.16 MB gz |
| **`reciters-index.json.gz`** (253) | reciter picker metadata (audio URLs constructed / from `qiraat`) | 13 KB gz |
| **1 asbāb book** (460 or 2919) + **`nasekh-book-2391`** | classical, small, per-ayah, high study value | ~0.4 + 0.13 MB gz |
| **2–3 curated tafsirs** from the 149 — e.g. **Muyassar** (KFGQPC, official), **Saʿdī**, **Jalālayn** | the ayah-study mode already ships Muyassar/Saʿdī via jsonl; reconcile, don't double | ~5–10 MB gz each |
| **1 curated iʿrāb book** (316 «إعراب القرآن») | per-ayah iʿrāb prose for the "الإعراب" surface | ~1.5 MB gz |

Target added bundle: **~40–60 MB gz**, gated by an updated APK-size decision.

### MIRROR + ON-DEMAND CACHE (Supabase reference tables + `quran-proxy`)

Too big or too many to bundle; licence-OK to mirror:

- the other **~146 tafsir books** (900 MB) → `quran_tafsir_entries` keyed
  `(book_id, surah, ayah)`, pulled per-ayah on demand, cached per
  `SUPABASE_ARCHITECTURE` sync-class **append-only**.
- the other **13 riwāyāt** → `quran_mushaf_text(riwaya_id, surah, ayah)`.
- **`fatwas.json.gz`** (3575), **`other/sayings.json.gz`** (athar) → reference
  tables, ayah-tagged, searchable via `search_documents`.
- the **16,296-book catalog** (`books.json.gz`) → `quran_books` reference
  table (drives "which books discuss this ayah").
- `services/qiraat.json.gz` (+ its `files.quranpedia.net` audio URLs),
  `similar.json.gz`, `mutshabeh.json.gz`.

### ONLINE-ONLY / ADAPTER (AD‑1 provider, no storage)

- Quranpedia live API for anything not in a dump (rare) and the
  `/v1/changes` delta feed (§6).
- saikothasan API as a fallback translation source.

### SKIP for now

- `translations-all.zip` wholesale — **licence**. Revisit per-edition; keep
  our existing QuranEnc set.
- `categories-all.zip` — trivial; fold into whatever consumes it.
- `attachments.json.gz` — media pointers; only if a feature needs them.

---

## 4. How it plugs in (no new architecture)

```
mushafs-1 text ......... cross-check → quran_ayat (Tanzil stays primary)
morphology (QAC) ....... KnowledgeGateway  ← QacGrammarProvider (now LOCAL, was inert)
syntax / e3rab book .... KnowledgeGateway  ← IrabProvider (new, LOCAL)
meanings ............... KnowledgeGateway  ← WordMeaningProvider (new, LOCAL)
notes ................. KnowledgeGateway  ← NotesProvider (new, LOCAL) + Ayah Notebook seeds
tafsir (curated) ...... LocalTafsirProvider (extend the existing one)
tafsir (rest) ......... TafsirProvider mode=HYBRID  → Supabase quran_tafsir_entries + cache
asbab / nasekh ........ AyahContextProvider (new, LOCAL for the 1–2 bundled books)
topics-index .......... knowledge_links seed (topic ↔ ayah)  → the Knowledge Index
reciters-index ........ QuranAudioProviderRegistry (metadata)
books catalog ......... quran_books reference table
```

Every provider keeps a `SourceReference` (Quranpedia dump version, or QAC /
Treebank for the carve-outs) so the existing provenance gate is unchanged.
Missing datum → *"لا توجد بيانات موثقة لهذا العنصر حاليًا"*, never a guess.

---

## 5. Identity mapping (do NOT assume)

Quranpedia has its own IDs; align once, with a tool + a committed report:

- ayah `id` (global 1..6236) and `number_in_hafs[]` → our `(surah, ayah)`.
  Verify the 6236 map 1:1 to `quran_ayat` (they should — both Hafs/Kufi).
- **`page_number`** is Quranpedia's page scheme — **not** guaranteed equal to
  Tanzil's `quran_ayat.page_number` or MushafDatabase's `mushaf_*` page.
  Never route a "go to page" through it. (Same rule as ERRATA on Tanzil vs
  MushafDatabase pages.)
- riwāya `id` (1..14) and rawi metadata → a `riwaya` enum; app scope stays
  **Hafs** (CLAUDE.md / quran-engineering checklist item 12) — other riwāyāt
  are a separate dataset, not a toggle, unless Ismail scopes them in.
- `book.id` — Quranpedia's; our `tafsir_editions` use their own keys.
  A `book_id` cross-walk table.
- morphology word `number` follows **QAC segmentation** — **not**
  `mushaf_words.word_index` and **not** Tanzil space-split. A
  `(surah,ayah,qac_word) ↔ mushaf_words.word_index` map is required before
  morphology can render **on the mushaf page** (this is the open `VT‑3`
  alignment task in `docs/quran/QURAN_WORD_ALIGNMENT_REPORT.md`). Until then,
  morphology shows in the Word Knowledge **Surface** (which addresses by
  `(surah,ayah,word_index)` from our geometry) only after that map exists.

---

## 6. The `/v1/changes` obligation (licence-mandatory)

- Store the dump `license.version` per dataset in `quran_corpus_meta`.
- A `QuranCorpusSync` (mirrors `MushafLayoutSync`): on launch / periodically,
  `GET /api/v1/changes?since=<stored_version>` → apply deltas to the local
  bundled copies + the Supabase mirror; bump the stored version.
- If offline / API down: keep serving the bundled version (offline-first) —
  but the app's "About sources" screen shows the dump date so staleness is
  visible.
- This is the reason Ismail included the `changes` endpoint. It is not
  optional — shipping stale Quran text is on us per the licence.

---

## 7. What would still help (Ismail: "tell me what miss")

Everything on the list arrived. Still useful, if easy to pull as **official
versioned dumps** (not scraping):

1. **`services/syntax.json.gz` provenance confirmation** — confirm it is the
   NoorBayan Treebank (MIT), so we can bundle iʿrāb without the GPL caveat.
2. **A word-alignment map** Quranpedia↔(our `mushaf_words`) if Quranpedia
   publishes one — otherwise we build it (VT‑3). Needed for on-page ṣarf.
3. **Per-edition licence list for `translations-all`** (or just the subset
   that is CC/PD) — so we know which translations may ship offline.
4. **Recitation audio base URL + path scheme** (the `qiraat` audio is
   `files.quranpedia.net/recitations/…`; need the pattern for `reciters-index`
   too), and whether hot-linking is allowed or we mirror to Supabase Storage.
5. **Tajwīd rule spans** — not in these dumps; still the `cpfair/quran-tajweed`
   or QUL path (`SOURCES.md` §9) for a future colour layer.
6. Nothing else. The corpus is very complete.

---

## 8. Phased plan (sequenced AFTER the mushaf engine)

Prereq: **Mushaf Rendering Engine M0–M7 done, 604/604 QA + device pass.**
Then, one phase at a time, each its own commit + verification:

- **QC0** — this doc approved. Decide the APK-size budget for the bundled
  subset; decide the curated tafsir / iʿrāb / translation set.
- **QC1** — ingest tool `tool/build_quran_corpus.py`: reads the raw dumps,
  emits the curated `assets/quran/corpus/*.json.gz` (morphology, syntax,
  meanings, notes-trimmed, topics, reciters, 1 asbab, nasikh, N tafsirs, 1
  iʿrāb, surah info), + `quran_corpus_manifest.json` with per-dataset
  `source_version` + sha256. Identity-map + validate (6236 / 114 / per-surah
  counts) → `docs/quran/reports/QURAN_CORPUS_QA.md`.
- **QC2** — schema (DB migration): `quran_corpus_meta`, `quran_morphology`,
  `quran_irab`, `quran_word_meanings`, `quran_notes`, `quran_topics`,
  `quran_asbab`, `quran_nasekh`, `quran_books`, extend `tafsir_*`. Seed from
  the QC1 assets via a `QuranCorpusSync` (validate-then-ingest, versioned).
- **QC3** — providers: make `QacGrammarProvider` LOCAL (morphology); add
  `IrabProvider`, `WordMeaningProvider`, `NotesProvider`, `AyahContextProvider`
  (asbab/nasekh); extend `LocalTafsirProvider` with the curated set. All
  behind `KnowledgeGateway`, all with `SourceReference`. Wire into the Word /
  Ayah Knowledge Surfaces (progressive disclosure — don't bloat the tiers).
- **QC4** — Knowledge Index: `topics-index` → `knowledge_links` (topic↔ayah);
  the "search a topic → its places across Quran + tafsir + notes + …" view.
- **QC5** — `/v1/changes` sync (§6) + "About sources" screen updates (QAC +
  Treebank + Quranpedia credits, dump dates).
- **QC6** — Supabase mirror (needs `SUPABASE_ARCHITECTURE` S1–S4 done first):
  the ~146 non-bundled tafsirs, 13 riwāyāt, fatwas, sayings, full book
  catalog → reference tables + `quran-proxy` Edge Function + per-ayah
  on-demand cache. Translations per §2.3.
- **QC7** — on-page ṣarf: once VT‑3 word alignment exists, render morphology
  at the tapped word on the mushaf page itself.

---

## 9. Constraints (do not cross)

- **Not now.** Zero corpus code until the mushaf engine is done + verified.
- Tanzil `quran_ayat` stays the **primary** Quran text; Quranpedia is a
  cross-check + dabt/marker companion. On any text mismatch, investigate —
  never silently overwrite (quran-engineering checklist).
- **GPL morphology**: bundle verbatim, own asset, visible QAC credit + link,
  never fork/modify in place.
- **Translations**: per-edition licence gate; no wholesale bundle.
- **Modern books**: check author/year; classical = free, living author =
  mirror-only / per-permission.
- **`/v1/changes` sync is mandatory** (licence) — build it in QC5, not "later".
- Curated bundle size is an explicit Ismail decision (APK already large).
- Quranpedia `page_number` ≠ our page schemes — never route navigation
  through it.
- morphology word index = QAC segmentation ≠ `mushaf_words.word_index` —
  on-page rendering waits on VT‑3.
- Every fact keeps a `SourceReference`; missing = *"لا توجد بيانات موثقة"*.
- New user-facing strings → `basicText`, 13 languages, RTL/LTR.
