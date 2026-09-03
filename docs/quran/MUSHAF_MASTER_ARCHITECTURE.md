# The Mushaf — Master Architecture

> **أقوى مصحف في العالم.** One interactive muṣḥaf where the word on the page
> is the key to *everything* the ummah has written about it — iʿrāb, ṣarf,
> tajwīd, tafsīr, asbāb, nāsikh, غريب, فوائد, قراءات, translations, topics,
> āثār — sourced, offline‑first, and endless.

Status: **FOUNDATIONAL ARCHITECTURE.** This is the north‑star that every other
Quran doc now sits under. It does **not** authorise building everything at
once — it defines *what* is being built, *how the layers fit*, and *in what
order*. One phase at a time (CLAUDE.md).

This doc **umbrellas** (does not replace):
- **[`MUSHAF_ENGINE_REBUILD.md`](MUSHAF_ENGINE_REBUILD.md)** → Layer 7 (Rendering) — *Phase A, in progress: M0–M3 done*.
- **[`QURAN_CORPUS_INTEGRATION.md`](QURAN_CORPUS_INTEGRATION.md)** → Layers 1–4 (the Quranpedia corpus) — *Phases B–F*.
- **[`../QURAN_LEARNING_ARCHITECTURE.md`](../QURAN_LEARNING_ARCHITECTURE.md)** + `QURAN_LIVE_DATA_ARCHITECTURE.md` → Layers 6 & 10 (KnowledgeGateway + study loop).
- **[`../SUPABASE_ARCHITECTURE.md`](../SUPABASE_ARCHITECTURE.md)** → Layer 4b (cloud mirror + delta sync + on‑demand).
- **[`../QURAN_DATA_CONTRACTS.md`](../QURAN_DATA_CONTRACTS.md)** / `QURAN_DATA_VALIDATION.md` → Layer 2 (ingest contracts).
- **[`MUSHAF_ENGINEERING.md`](MUSHAF_ENGINEERING.md)** / `SOURCES.md` / `ERRATA.md` → the permanent engineering knowledge base.

---

## 0. Principles (non‑negotiable)

1. **Offline‑first, not offline‑only** (AD‑1). Reading — text, page, a bundled
   tafsīr, a bundled iʿrāb — is 100% local, always, no network. Online only
   *extends* (more tafsirs, audio, live corrections).
2. **One identity for the whole Quran.** Everything — every gloss, every
   book, every highlight — addresses the Quran through the **canonical Hafs
   spine**: `(surah, ayah, wordIndex)` where `wordIndex` is *our*
   `mushaf_words` segmentation. Foreign segmentations are mapped in at
   ingest, never leaked to consumers (Layer 5).
3. **Every scholarly datum carries a `SourceReference`.** No source → not
   shown. Missing datum → *"لا توجد بيانات موثقة لهذا العنصر حاليًا"* — never
   a guess, never AI‑generated as fact.
4. **The rasm is sacred.** No SVG edit, nothing painted over the glyphs or
   the tashkīl. The muṣḥaf renders exactly as MushafDatabase drew it.
5. **Licence is load‑bearing.** GPL morphology ships verbatim + credit;
   translations are per‑edition; classical works are free; `/v1/changes`
   keeps shipped text current (Quranpedia obligation).
6. **Endless by design.** New books, riwāyāt, reciters, languages plug in as
   new rows / providers — never a schema rewrite.
7. **One phase at a time.** The rendering engine finishes and is proven on
   604/604 + device *before* the corpus phases start.

---

## 1. The ten layers

```
 10  STUDY LOOP        learn a concept → notebook → "طبّق" back to the same word
                       (QURAN_LEARNING_ARCHITECTURE — pedagogy, spaced review)
  9  SURFACES          Word Knowledge · Ayah Knowledge · Notebook · Lesson · Topic view
  8  INTERACTION       ONE page-level hit-test → QuranRef → KnowledgeGateway
  7  RENDERING         MushafPageView · ScreenTransform · PageCache   (MUSHAF_ENGINE_REBUILD)
  6  KNOWLEDGE GATEWAY  many providers, per-fact mode (LOCAL/HYBRID/ONLINE) + provenance
  5  IDENTITY SPINE    QuranRef(surah,ayah,wordIndex[,charRange]) + align_* resolvers
  4  STORE + SYNC      local SQLite (primary)  ⇄  Supabase mirror  ⇄  /v1/changes delta
  3  CANONICAL SCHEMA  quran_ayat · mushaf_* · quran_corpus_* · align_* · *_meta
  2  INGEST + ALIGN    build tools: dumps → canonical rows + alignment maps + QA + manifest
  1  SOURCES           bundled dumps (offline) · APIs (online) · Tanzil · MushafDatabase
```

Data flows **up**; a tap flows **down** (8 → 5 → 6 → 9).

---

## 2. Layer 1 — Sources (every input, one register)

`SOURCES.md` is the authoritative register. Summary of roles:

| source | role | offline? | licence |
|---|---|---|---|
| **Tanzil** `quran-uthmani.txt` + `quran-data.js` | **primary Uthmani text** + juz/hizb/page/sajda | bundled | CC‑BY, no‑modify |
| **MushafDatabase V1.01** (604 SVG + `mushaf_*`) | **the page art** + per‑word geometry & identity | bundled (gz) | Sadaqa‑e‑Jaria (open) |
| **Quranpedia — mushafs** (14 riwāyāt) | dabt/marker/`number_in_hafs`; Hafs = cross‑check, 13 others = mirror | Hafs bundled · rest mirror | free (in‑app) |
| **Quranpedia — morphology** (`services/morphology`) | **ṣarf** (segments, root, lemma, POS) | bundled verbatim | **GNU GPL** — credit `corpus.quran.com`, no‑modify |
| **Quranpedia — syntax** (`services/syntax`) | **iʿrāb dependency** (heads, relations) | bundled | MIT (Quranic Treebank) — attribute |
| **Quranpedia — iʿrāb books** (4) | iʿrāb **prose** per ayah | 1 bundled · rest mirror | classical = free |
| **Quranpedia — meanings** (`services/meanings`) | **غريب القرآن** word meanings | bundled | free (classical غريب books) |
| **Quranpedia — tafsir books** (149) | full per‑ayah tafsīr | ~3 curated bundled · ~146 mirror | classical free · modern per‑author |
| **Quranpedia — asbāb** (2) + **nāsikh** (1) | revelation context / abrogation | 1 asbāb + nāsikh bundled | classical = free |
| **Quranpedia — notes** (`services/notes`, 5653) | sourced **فوائد / وقفات** | trimmed subset bundled · rest mirror | free (named authors) |
| **Quranpedia — topics** (6100, tree) | topic → ayah‑range → **Knowledge Index** | bundled | free |
| **Quranpedia — qiraat** (`services/qiraat` + audio URLs) | per‑word variant readings + recitation audio | hybrid | free · audio TBD |
| **Quranpedia — reciters** (253) | recitation metadata | bundled index | free |
| **Quranpedia — translations** (139) | multilingual meaning | **per‑edition**: PD/CC bundled, rest online/omit | **author IP** |
| **Quranpedia — sayings / fatwas** | athar linked to ayat · 3575 fatwās | mirror | free |
| **QuranEnc / rwwad** (~40 editions, already in repo) | language tafsīr/translation | bundled jsonl | CC‑BY family |
| **cpfair/quran‑tajweed** or **QUL** | tajwīd rule spans (future) | bundled (later) | CC‑BY |
| **quran.com API v4 / quran.ai MCP** | dev‑time grounding + cross‑check | online (dev only) | API terms |
| **saikothasan/quran‑api** | fallback translation adapter | online only | MIT |

**`/v1/changes?since=<version>`** is a source too — the delta feed that keeps
every shipped dataset current (licence‑mandatory, Layer 4).

---

## 3. Layer 2 — Ingest + Align (the build tools)

One family of Python build tools under `tool/`, each: **read raw source →
map into the canonical spine → validate against ground truth → emit a
versioned artifact + a QA report.** Never ship a source's own schema.

| tool | in | out | validates |
|---|---|---|---|
| `extract_mushaf_svg.py` *(exists)* | MushafDatabase SVG | `mushaf_layout.json.gz` + manifest | 604 pages, 6236 marks, contiguous `word_index`, per‑surah counts, `contentRect` (M1) |
| `build_quran_corpus.py` *(new — QC1)* | Quranpedia dumps | `assets/quran/corpus/*.json.gz` (curated) + `quran_corpus_manifest.json` (per‑dataset `source_version` + sha256) | 6236/114, per‑surah counts, no orphan `(s,a)`, envelope licence captured |
| `build_alignments.py` *(new — QC1/VT‑3)* | QAC morphology ↔ `mushaf_words` ↔ Tanzil split | `align_qac.json.gz`, `align_tanzil.json.gz` + `QURAN_WORD_ALIGNMENT_REPORT.md` | every QAC word maps to exactly one `word_index`; residuals listed, never text‑edited |
| `mushaf_qa.py` *(new — M5)* | seeded DB + assets | `docs/quran/reports/MUSHAF_QA_REPORT.md` | geometry/data/visual PASS/FAIL over all 604 |
| `mushaf_svg_qa.py` *(exists)* | 604 SVGs | `docs/quran/reports/MUSHAF_SVG_QA.md` | one viewBox, zero transforms, uniform frames |

**Alignment is the spine's backbone.** `align_qac` (the open VT‑3 task) is
what lets ṣarf/iʿrāb render *on the page* at the tapped word. Until it
exists, those facts still show in the Word Knowledge **Surface** (addressed
by our `word_index`), just not painted on the glyphs.

---

## 4. Layer 3 — Canonical schema (SQLite)

Additive only. Existing: `quran_ayat`, `mushaf_pages/lines/words/aya_marks/markers/meta`,
`tafsir_entries`, `knowledge_concepts/facts`, `source_references`,
`ayah_study_entries`. New `quran_corpus_*` family (QC2):

```
quran_corpus_meta(dataset, source, source_version, sha256, seeded_at, licence_tag)
quran_riwaya(id, name, rawi, qiraa, ayah_count)              -- 14 rows; app scope = Hafs
quran_text_riwaya(riwaya_id, surah, ayah, text, marker, page_number_qp)  -- Hafs bundled, 13 mirror
align_qac(surah, ayah, qac_word, word_index, confidence)     -- QAC → our segmentation
align_tanzil(surah, ayah, tanzil_word, word_index)
quran_morphology(surah, ayah, word_index, seg_no, form, role, root, lemma, pos, features_json, translation)   -- GPL asset, verbatim
quran_irab_syntax(surah, ayah, word_index, head_word_index, relation, constituent)   -- MIT
quran_irab_prose(book_id, surah, ayah, html)                 -- 1 book bundled, rest mirror
quran_word_meaning(surah, ayah, word_index, book_id, gloss)  -- غريب
quran_tafsir_entry(book_id, surah, ayah, html)               -- ~3 bundled, ~146 mirror  (extends tafsir_entries)
quran_ayah_context(surah, ayah, kind∈{asbab,nasekh,mansukh}, book_id, html, related_ref)
quran_note(surah, ayah, author, category, kind∈{note,waqfa}, body, media_json, source_ref_id)
quran_topic(id, name, parent_id)                             -- 6100, tree
quran_topic_ayah(topic_id, surah, ayah_from, ayah_to)
quran_qiraat(surah, ayah, word, variant_text, rawi, audio_url)
quran_translation_edition(id, lang, name, licence_tag, bundled bool)
quran_translation(edition_id, surah, ayah, text)             -- PD/CC bundled, rest online
quran_saying(id, surah, ayah, text, attribution, source_ref_id)   -- athar
quran_fatwa(id, surah, ayah, title, question, answer, category)   -- mirror
quran_book(id, type, name, short_name, author, year, language, category, is_classical bool)  -- 16k catalog (mirror)
quran_reciter(id, name, surahs_json, audio_base_url)
```

RLS/ownership on the Supabase side (Layer 4b) splits these into **reference**
(public read) vs the user's personal `notes`/`highlights`/`study_entries`
(per `SUPABASE_ARCHITECTURE`).

---

## 5. Layer 4 — Store + Sync

- **Local SQLite is primary.** Every read hits it. `QuranCorpusSync` (mirrors
  `MushafLayoutSync`): validate‑then‑ingest each `quran_corpus_*` dataset
  from its bundled asset, versioned by `quran_corpus_meta`.
- **`/v1/changes` delta** (QC5, licence‑mandatory): on launch / weekly,
  `GET /api/v1/changes?since=<stored_version>` per dataset → patch local rows
  + bump version. Offline → keep serving; "About sources" shows the date.
- **Supabase mirror** (QC6, needs `SUPABASE_ARCHITECTURE` S1–S4): the
  non‑bundled bulk (146 tafsirs, 13 riwāyāt, fatwas, athar, catalog, online
  translations) as **reference tables**; a **`quran-proxy` Edge Function**
  fetches a book’s ayah on demand and caches it (append‑only sync class).
  The app degrades to "bundled only" with zero errors when offline.
- **Personal layer** (notes, highlights, hifz, study entries) syncs per the
  Supabase per‑domain resolution classes — never LWW‑blind.

---

## 6. Layer 5 — Identity spine

```dart
class QuranRef {
  final int surah;        // 1..114
  final int ayah;         // 1..N
  final int? wordIndex;   // 1..k  — OUR mushaf_words segmentation (the canonical word id)
  final (int,int)? charRange; // sub-word span, for tajweed / qiraat highlights
  // resolvers:
  //   fromMushafHit(MushafWord)        -> exact
  //   fromMushafAyaMark(MushafAyaMark) -> ayah-level (wordIndex null)
  //   qacWord -> wordIndex   via align_qac
  //   tanzilWord -> wordIndex via align_tanzil
}
```

`QuranSelection` (already built) is the UI‑facing carrier; `QuranRef` is the
data‑facing key every provider and every table speaks. **No screen and no
provider ever handles a foreign word index directly.**

---

## 7. Layer 6 — KnowledgeGateway + the providers ("كل شيء")

One `KnowledgeGateway`. Many providers. Each returns `KnowledgeFact`s with a
`SourceReference` and a `dataState` (LOCAL / HYBRID‑cached / ONLINE / MISSING).
The gateway merges, orders by tier, and the surface renders — progressive
disclosure, never a wall of tabs.

| # | domain | provider | mode | source (licence) | tier |
|---|---|---|---|---|---|
| 1 | Uthmani text + dabt | *(core)* + `QuranpediaTextProvider` | LOCAL | Tanzil (CC‑BY) + Quranpedia (free) | — |
| 2 | **ṣarf** (root/lemma/pattern/POS) | `QacGrammarProvider` *(inert → LOCAL)* | LOCAL | QAC v0.4 (**GPL**, credit+no‑mod) | Word · Tier 2 |
| 3 | **iʿrāb — dependency** | `TreebankSyntaxProvider` *(new)* | LOCAL | Quranic Treebank (MIT) | Word · Tier 1 (role/sign/why) |
| 4 | **iʿrāb — prose books** | `IrabBookProvider` *(new)* | LOCAL(1)+MIRROR | Quranpedia iʿrāb books (classical) | Word/Ayah · "الإعراب" |
| 5 | **غريب** (word meaning) | `WordMeaningProvider` *(new)* | LOCAL | Quranpedia meanings (free) | Word · Tier 1 |
| 6 | **tajwīd** (rule spans) | `TajweedProvider` *(later)* | LOCAL | cpfair / QUL (CC‑BY) | Word · charRange overlay |
| 7 | **tafsīr** | `LocalTafsirProvider` *(extend)* + `TafsirProvider` | LOCAL(≈3)+HYBRID(≈146) | Quranpedia + QuranEnc | Ayah · segmented |
| 8 | **asbāb al‑nuzūl** | `AyahContextProvider` *(new)* | LOCAL(1)+MIRROR | Quranpedia asbāb (classical) | Ayah · "سبب النزول" |
| 9 | **nāsikh / mansūkh** | `AyahContextProvider` | LOCAL | Quranpedia nāsikh | Ayah · badge + note |
| 10 | **فوائد / وقفات** | `NotesProvider` *(new)* | LOCAL(trim)+MIRROR | Quranpedia notes (named authors) | Ayah · "فوائد" + Notebook seed |
| 11 | **topics** | `TopicsProvider` *(new)* → Knowledge Index | LOCAL | Quranpedia topics (free) | Ayah · "موضوعات" + cross‑search |
| 12 | **qirāʾāt variants** | `QiraatProvider` *(new)* | HYBRID | Quranpedia qiraat + audio | Word · "قراءات" |
| 13 | **translations** | `TranslationProvider` *(extend)* | LOCAL(PD/CC)+ONLINE | QuranEnc + Quranpedia per‑edition | Ayah · "الترجمة" (language‑aware) |
| 14 | **athar / أقوال السلف** | `SayingsProvider` *(new)* | MIRROR | Quranpedia sayings (free) | Ayah · "آثار" |
| 15 | **fatāwā** | `FatwaProvider` *(new)* | MIRROR | Quranpedia fatwas (free) | Ayah · "فتاوى مرتبطة" |
| 16 | **mutashābihāt** | `MutashabihatProvider` *(later)* | LOCAL | QUL / Quranpedia | Ayah · hifz revision |
| 17 | **recitation audio** | `QuranAudioEngine` *(exists)* + reciters index | ONLINE + cache | EveryAyah / Quranpedia files | audio bar |
| 18 | **related books** | `BookIndexProvider` *(new)* | MIRROR | Quranpedia 16k catalog | Ayah · "كتب تناولت الآية" |

Adding domain #19 later = one provider + one table + one manifest entry.
Nothing above it changes.

---

## 8. Layers 7–9 — Rendering, Interaction, Surfaces

- **Layer 7 (Rendering)** = the engine rebuild. `MushafPageView` +
  `ScreenTransform` (M2) + `contentRect` fit (M3) + `MushafPageCache` (M4) +
  604‑page QA (M5). Draws the SVG, nothing reflows, horizontal scroll
  impossible, the recto/verso gutter handled by one uniform rule.
- **Layer 8 (Interaction)** = one page‑level hit‑test → `MushafWord` /
  `MushafAyaMark` → `QuranRef` → `KnowledgeGateway`. Strict containment, no
  proximity, no per‑word `GestureDetector`.
- **Layer 9 (Surfaces)** = `showWordKnowledgeSurface` / `showAyahKnowledgeSurface`
  (built), extended with the Tier map from §7; the **Notebook**; the
  **Lesson** ("تعلّم هذا" → concept → "طبّق" back to the *same* `QuranRef`);
  the **Topic view** (§7 #11 → cross‑content results via the Knowledge Index).
  Premium 3D presentation per `QURAN_PREMIUM_UI.md` — *depth, motion, order,
  space; never colour on the rasm.*

---

## 9. Layer 10 — Study loop

`QURAN_LEARNING_ARCHITECTURE` unchanged: deterministic, no quizzes, no AI
brain. The corpus makes its providers *real* instead of prototype‑only. A
concept learned in the notebook links back to its `QuranRef`s; spaced review
(Ebbinghaus 6‑station, already built) schedules them.

---

## 10. Master build order

Each phase = its own commits, `flutter analyze` + `flutter test` + Android
emulator, and a written PASS/FAIL report. **Do not start a phase before the
previous one is signed off.**

| phase | what | gates on | docs |
|---|---|---|---|
| **A — Rendering engine** ✅ **COMPLETE 2026‑09‑03** | M0–M3 signed off · M4 cache · **M5 604‑page QA: geometry/data/visual 604/604 PASS** · M6a legacy‑code deletion · M7 close‑out. 467 tests, emulator‑verified. (M6b page_recitation cleanup deferred, non‑blocking.) | — | `MUSHAF_ENGINE_REBUILD.md` |
| **B — Identity spine & ingest** *(NEXT)* | `build_quran_corpus.py` + `build_alignments.py` (VT‑3); `quran_corpus_*` schema; curated bundle (~40–60 MB, size budget = Ismail); QA reports | Phase A done ✅ | `QURAN_CORPUS_INTEGRATION.md` QC1–QC2 |
| **C — Knowledge planes, offline** | providers #2,3,4,5,7(local),8,9,10 in LOCAL mode → wired into the Surfaces (§7 tiers). *This is when "فيه الإعراب وكل شيء" is real on‑device.* | Phase B | QC3 |
| **D — Knowledge Index** | topics → `knowledge_links`; the topic → cross‑content view (Quran + tafsīr + notes + books) | Phase C | QC4 + `SUPABASE_ARCHITECTURE` §4.6 |
| **E — Sync & mirror** | `/v1/changes` delta (licence); Supabase reference mirror + `quran-proxy` + on‑demand cache for the 146 tafsirs / 13 riwāyāt / fatwas / athar | Phase C + `SUPABASE_ARCHITECTURE` S1–S4 | QC5–QC6 |
| **F — Online expansion** | translations per‑edition (online + PD bundle); 253 reciters' audio + cache; saikothasan fallback; live cross‑check | Phase E | QC7 + `SOURCES.md` §13–14 |
| **G — On‑page everything** | with `align_qac` done: ṣarf / iʿrāb / tajwīd / qiraat rendered **on the glyph** at the tapped word (charRange overlays) | Phase B alignment + Phase C | QC7 + `QURAN_INTERACTION.md` |

Endgame after G: tap any word on any of the 604 pages → its exact identity →
ṣarf, iʿrāb (dependency + prose), غريب, tajwīd, the reading it carries, the
tafsīr of its ayah across dozens of books, why it was revealed, whether it
abrogates, the فوائد scholars drew, the topics it belongs to, translations in
13+ languages, the athar and fatāwā about it — sourced, mostly offline, the
rest one tap away, always current. **That is the strongest muṣḥaf.**

---

## 11. What this does NOT change

- Tanzil stays the **primary** Uthmani text. Quranpedia is cross‑check +
  companion. Text mismatch → investigate, never silently overwrite.
- No riwāya toggle in the reader unless Ismail scopes it in — app scope is
  **Hafs** (`quran-engineering` checklist #12).
- Quranpedia `page_number` ≠ our page schemes — navigation never routes
  through it.
- GPL morphology: own asset, verbatim, visible credit, never forked.
- Translations: per‑edition licence gate; no wholesale bundle.
- No AI as a source. Missing = *"لا توجد بيانات موثقة"*.
- Rasm/dabt visually untouchable.
- One phase at a time.
