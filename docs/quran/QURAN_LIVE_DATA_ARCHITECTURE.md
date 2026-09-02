# Quran Learning — Hybrid Data Architecture (Offline‑first, not Offline‑only)

**Status: DESIGN — this is the OFFICIAL architecture decision. No code yet.**
How the Quran Learning Layer (`QURAN_LEARNING_LAYER.md`) gets its teaching
data — kept local when it should be, fetched online when that is better —
through **one gateway**, so the muṣḥaf never needs internet but the
knowledge on top of it can grow without limit.

Load the `quran-engineering` skill first. Companions:
`QURAN_LEARNING_LAYER.md`, `QURAN_DATA_VERIFICATION_TASKS.md` (licence
findings), `../QURAN_SOURCES_AND_LICENSES.md`, `../QURAN_DATA_CONTRACTS.md`.

---

## AD‑1 · Architecture Decision — Offline‑first, not Offline‑only

**The project principle is NOT "everything must be offline / inside the APK".**
It is:

> **Offline‑first, not Offline‑only. Keep local what must always work;
> fetch online what is better fetched; join the two behind one gateway.**

Rules that follow from AD‑1:

1. **Never reject a source for being Online.** If a scholarly source is
   good, rich, and legally reachable over the internet (its own API, or a
   documented access method), **build an adapter for it** — do not look for
   a reason to refuse it.
2. **Evaluate every source the same way** (see §3.5): API/access → licence &
   terms → what it actually provides → what can be used directly → what may
   be cached → what must stay online‑only → then an adapter.
3. **The core stays local and always works:** muṣḥaf, Qur'an text, word
   identity `(surah, ayah, word_index)`, pages, layout, the student's
   notebook, the lessons/data we hold a redistribution licence for, and all
   student data. Internet is **never** required to read the Qur'an or use
   the notebook.
4. **No single source is a dependency.** If a provider is down or absent →
   fall back to local verified data and show what exists. If nothing exists
   → *"لا توجد بيانات موثقة لهذا الموضع حاليًا."* **Guessing is forbidden.**
5. **The API is never the source of Qur'anic truth.** `(surah, ayah,
   word_index)`, the text, the layout are local and verified. The network
   only adds knowledge *on top*; if a live provider returns Qur'an text /
   identity that disagrees with local data, **local wins**, silently, and
   the mismatch is logged.
6. **Cache only what the source's terms allow**, for only as long as they
   allow. A cache is a convenience mirror, never authoritative; every cached
   fact still carries its `SourceReference` and passes the display gate.

AD‑1 supersedes any earlier wording in `docs/quran/` that read as
"bundle‑or‑nothing". Where an older doc says a layer is "blocked" only
because it can't be bundled, re‑read it as: **that layer is an Online (or
Hybrid) provider**, not a blocked one — see §7.

---

## 2. What the licence check actually found  (see `QURAN_DATA_VERIFICATION_TASKS.md`)

| data | licence (verified 2026‑08‑30) | can we bundle offline? |
|---|---|---|
| **QAC** morphology (root/lemma/pattern/POS/features) | corpus.quran.com terms: verbatim copy + use "in any website or application" allowed **with source shown + link to corpus.quran.com**; **modification not allowed** | **YES — verbatim, no‑modify, attribution+link** |
| **MASAQ** v5 (morphology + syntax, 72 iʿrāb roles, ~full coverage) | **CC BY 4.0** (commercial OK, attribution) | **YES** |
| **cpfair/quran-tajweed** rule spans | **CC BY 4.0** (+ our offset remap to the muṣḥaf) | **YES** |
| **MushafDatabase SVG** page art | "Sadaqa‑e‑Jaria" (open, incl. commercial) | **YES** (packaging = engineering choice) |
| our **tafsīr editions** (`tafsir_entries`) | CC‑BY family via KFGQPC/QuranEnc/Tanzil | **YES** (already bundled) |
| public‑domain matns (تحفة الأطفال، الجزرية) for concept prose | public domain | **YES** |
| **QUL** resources (word meaning, mutashābihāt, topics) | **per‑resource**, varies (public domain … specific) | **verify each** before bundling |
| **Word‑level audio + timing** (Quran Foundation `word.audioUrl` / segments) | Developer Terms: **no storing QF Content > 1 week** except via Content Sync (re‑sync ≤ 7 days); **"not sold, sublicensed, or redistributed"** without a separate commercial licence; app may charge as long as content stays in the end‑user experience | **NO — API / stream only** |

**Net:** morphology, syntax, tajwīd rule data, and the muṣḥaf art are all
*legally reachable now* — most bundle‑able, audio online‑only. Under AD‑1
the split is not "bundle vs blocked" but **which provider mode fits each
source**: Local, Online, or Hybrid.

### 2.5 · Provider modes

| mode | meaning | when |
|---|---|---|
| **LOCAL** | data ships in the app (asset / seeded table); works with no internet | we hold a redistribution licence **and** the data is bounded in size **and** it changes rarely |
| **ONLINE** | fetched from a provider (its API, or our proxy) at the moment of use; **not** persisted | terms forbid storage/redistribution, **or** the data is huge / changes often / is better kept fresh |
| **HYBRID** | fetched online, then **cached locally** for fast re‑use, revalidated in the background | terms **allow** caching; the student benefits from offline re‑access (e.g. a surah they're studying) |

A domain can use **more than one** provider (e.g. tajwīd = a local core set
+ an online provider for editions/áreas we don't bundle). The gateway merges
them and reports `dataState` per fact.

### 2.6 · Domain map (the table AD‑1 requires)

`Cache?` = may a fetched copy be stored locally, per the source's terms.

| المجال (domain) | Local | Online | Hybrid | المصدر (source) | API / access | الترخيص (licence) | Cache مسموح؟ |
|---|:--:|:--:|:--:|---|---|---|:--:|
| المصحف: نص، هوية `(surah,ayah,word_index)`، صفحات، تخطيط | ✓ | | | Tanzil v1.1 · MushafDatabase V1.01 | bundled asset | CC‑BY 3.0 (no‑modify) · Sadaqa‑e‑Jaria | — (it *is* local) |
| رسم صفحة المصحف (فنّ SVG) | ✓ | ✓ | ✓ | MushafDatabase V1.01 SVG | GitHub repo → "Mushaf Data Package" (download‑all or lazy per‑page) | Sadaqa‑e‑Jaria | ✓ (permanent, integrity‑checked) |
| الصرف (root/lemma/pattern/POS/features) | ✓ | ✓ (if/when an API is found) | ✓ | MASAQ v5 (primary) · QAC v0.4 (cross‑check) | Mendeley download · corpus.quran.com download | CC BY 4.0 · verbatim+attr+link, no‑modify | ✓ (it's local; a future API copy would also be cacheable) |
| النحو / الإعراب (nodes + relations, 72‑role tagset) | ✓ | ✓ (future API) | ✓ | MASAQ v5 (+ QAC treebank ~11k words) | Mendeley download | CC BY 4.0 | ✓ |
| التجويد (rule spans per position) | ✓ | ✓ | ✓ | cpfair/quran‑tajweed (+ offset remap) · QUL Tajweed V4 (cross‑check, licence per‑resource) | GitHub · QUL | CC BY 4.0 · QUL per‑resource | ✓ (CC‑BY set); QUL: per its terms |
| التفسير | ✓ | ✓ | ✓ | 48 bundled editions · Quran Foundation `content` scope (live, if proxy built) | bundled asset · QF Content API | CC‑BY family · QF Developer Terms | ✓ (bundled); QF live: ≤ 1 week |
| معاني الكلمات (word gloss) | (if a QUL resource clears) | ✓ | ✓ | QUL word translations · other WBW sets | QUL · TBD | per‑resource — **unverified** | per its terms |
| الصوت + التوقيت (recitation, follow) | | ✓ | ✓ (session buffer only) | Quran Foundation `word.audioUrl` + segments (public CDN) · EveryAyah (fallback, no secret) | QF API (needs token proxy) · EveryAyah direct | QF Developer Terms: stream only, **no storage > 1 week**, no redistribution | ✗ (QF) — ephemeral only |
| حديث ↔ آية (روابط) | (curated subset) | ✓ | ✓ | Itqan / Parallel Quran (licences TBD) · our `nawawi_hadiths` | GitHub / site · bundled | TBD · own | per source |
| دفتر الطالب + مسار التعلم | ✓ | | | the student | — | n/a | — |
| منهج التجويد / العربية (دروس) | ✓ | | | `tajweed_curriculum.dart` · `arabic_curriculum.dart` (in‑app, citation‑only) | — | own authored + cited matns | — |
| المراجعة (SM‑2) | ✓ | | | `KnowledgeReviewRepository` (in‑app) | — | n/a | — |

`✓` in more than one column = the domain is served by a **Local core** and
can be **extended by Online/Hybrid providers** without rework.

---

## 3. The gateway pattern — one interface, many providers

The Flutter app never talks to QAC / MASAQ / an audio CDN directly. It talks
to **one `LearningGateway`** which routes each request to a **Provider
Adapter**, and each adapter resolves **locally, over the network, or from
cache**.

The Flutter app never talks to MASAQ / QAC / an audio CDN / QF directly. It
talks to **one `KnowledgeGateway`** which fans a request out to every
registered **Provider** for the requested domains, merges the results, and
reports the `dataState` of each fact.

```
Flutter UI
   │  gateway.factsFor( anchor, domains )        anchor = (surah, ayah[, word_range])
   ▼
KnowledgeGateway            (single interface; per-fact dataState; graceful fallback)
   ├── LocalQuranProvider        (surah/ayah/word identity, layout)      [LOCAL]
   ├── LocalCurriculumProvider   (tajwīd + Arabic lessons in-app)        [LOCAL]
   ├── MorphologyProvider        (MASAQ v5 + QAC, seeded table)          [LOCAL] (+ONLINE if an API appears)
   ├── SyntaxProvider            (MASAQ v5, seeded table)                [LOCAL] (+ONLINE …)
   ├── TajweedProvider           (cpfair/quran-tajweed core + QUL V4)    [LOCAL] (+HYBRID for QUL)
   ├── TafsirProvider            (48 bundled editions)                   [LOCAL] (+ONLINE QF `content`)
   ├── MeaningProvider           (word gloss)                           [ONLINE|HYBRID]
   ├── AudioProvider             (QF via token-proxy; EveryAyah fallback)[ONLINE] (session buffer)
   ├── HadithLinkProvider        (curated now; Itqan/Parallel later)     [LOCAL|HYBRID]
   ├── SourceRegistryProvider    (our `source_references` table)         [LOCAL]
   └── <FutureProvider>          (any new online knowledge API)          [ONLINE|HYBRID]
   ▼
result: { domain → [ Fact(+SourceReference) ] , dataState: local | online | cached | unavailable }
```

- **No provider is a dependency.** `unavailable` from one never fails the
  panel; the other providers' facts still render, each labelled with its
  `dataState`. If *all* providers return nothing for a domain →
  *"لا توجد بيانات موثقة لهذا الموضع حاليًا."*
- **Adding a source later = registering one Provider.** Same
  `KnowledgeFact` / `SourceReference` contracts
  (`../QURAN_DATA_CONTRACTS.md`); no schema change, no UI change — the panel
  just gains rows.
- **Swappability:** if a source or its licence changes, we replace **one
  provider** (and, for an online one, a server route). No app
  re‑architecture.
- **Server side (only if/when a live layer exists):** a thin
  `Quran Learning API` in front of the live providers (audio now; possibly
  QUL meaning later) so the app depends on *our* stable endpoint, not a
  third party's shape. For the offline layers there is **no server** — the
  adapter reads a bundled SQLite/asset. The app doesn't care which.
  - **Quran Foundation is a *confidential* OAuth client.** Its
    `client_secret` **cannot ship in the APK** (decompilable) and QF's docs
    forbid calling the token endpoint from mobile code. So the *first*
    server piece is a **token‑proxy endpoint** (`AppConfig.qfTokenProxyUrl`):
    the app calls it, it does the `client_credentials` exchange with
    `oauth2.quran.foundation` (holding the secret + `offline_access` refresh
    token), and returns a short‑lived access token. `QuranFoundationProvider`
    (`lib/services/quran_audio/quran_foundation_provider.dart`) is already
    scaffolded and inert (`isConfigured = false`) awaiting exactly this.
    Until the proxy exists, `L‑AUDIO` falls through to `EveryAyahProvider`
    (no secret) and QF `content` is not used.
- **`dataState` is always returned** so the UI can label a card
  `● محلي` / `☁ مباشر` / `⚡ محفوظ مؤقتًا` / `— يحتاج اتصالًا`.

### 3.5 · How to onboard a source (AD‑1 §2) — the fixed procedure

When a source (especially an Online one) is proposed, run **all** of these,
record the result in `../QURAN_SOURCES_AND_LICENSES.md`, and only then wire
an adapter. **Do not skip to a "no".**

1. **Inspect the API / access method** — endpoints, auth, shape, rate limits.
2. **Read the licence + terms of use** — redistribution? caching? storage
   window? commercial? attribution?
3. **Enumerate exactly what it provides** — which domains, at what grain
   (word / range / ayah), which segmentation.
4. **Decide what may be used directly** (rendered live).
5. **Decide what may be cached** (and for how long) — per the terms.
6. **Decide what must stay strictly online** (no persistence).
7. **Build a Provider adapter** in the gateway → `KnowledgeFact` +
   `SourceReference`; pick mode LOCAL / ONLINE / HYBRID from §2.5.
8. **Make the system degrade without it** — the feature still works from
   local/other providers when this source is unavailable; it is **never** a
   hard dependency, and a missing datum is *"لا توجد بيانات موثقة"*, never a
   guess.

---

## 4. Per‑layer contract

Each layer specified as: **Source · Licence · Online/Offline · Cache Policy ·
Identity · Failure Behavior · Attribution.**

### L‑ID · Qur'an & Word Identity  (the spine)
- **Source:** Tanzil (`quran_ayat`) + MushafDatabase V1.01 (`mushaf_*`).
- **Licence:** Tanzil CC‑BY 3.0 (no modification) · MushafDatabase Sadaqa‑e‑Jaria.
- **Online/Offline:** **OFFLINE, always.** Ships in the APK/DB.
- **Cache Policy:** n/a — it *is* the local truth. Never fetched.
- **Identity:** `(surah, ayah, word_index)` + `(page, line, bbox)`.
- **Failure Behavior:** cannot fail; if the DB is missing the app re‑seeds
  from bundled assets (`QuranImportService` / `MushafLayoutSync`).
- **Attribution:** "Tanzil.net" + link; "MushafDatabase (Sadaqa‑e‑Jaria)".

### L‑LAYOUT · Mushaf Semantic Layer
- **Source:** MushafDatabase V1.01 → `assets/mushaf/mushaf_layout.json.gz`.
- **Licence:** Sadaqa‑e‑Jaria.
- **Online/Offline:** **OFFLINE** (2.4 MB gz, already bundled).
- **Failure Behavior:** re‑seed from asset. No network path.
- **Attribution:** MushafDatabase.

### L‑ART · Mushaf page visual (SVG)
- **Source:** MushafDatabase V1.01 SVG pages (~380 MB raw / ~46 MB xz).
- **Licence:** Sadaqa‑e‑Jaria — **redistribution OK**.
- **Online/Offline:** **HYBRID (engineering choice, not licence):**
  - Base APK: **no** SVGs.
  - Delivery: a separate **"Mushaf Data Package"** — downloaded once
    (all 604, xz) **or** lazy per‑page on first view.
  - After download: fully offline.
- **Cache Policy:** permanent local store; integrity‑checked (sha256 per
  page); re‑downloadable; user can delete to reclaim space.
- **Identity:** page number ↔ `mushaf_*`.
- **Failure Behavior:** page not yet downloaded + offline → show the current
  own‑engine reader (unchanged) and a "نزّل حزمة المصحف لعرض الرسم الحقيقي"
  prompt. Reading never blocked.
- **Attribution:** MushafDatabase, in the package + an "About sources" line.

### L‑MORPH · Morphology (ṣarf)
- **Source:** **MASAQ v5** (primary) cross‑checked with **QAC v0.4**.
- **Licence:** MASAQ CC BY 4.0 · QAC verbatim‑only + attribution+link + no‑modify.
- **Online/Offline:** **OFFLINE.** Bundled as a compact local table
  (`knowledge_facts` domain=`sarf` + `morph_*`), built from the datasets by
  a build‑time importer. The **verbatim QAC file** is kept unmodified in
  `assets/quran_learning/sources/` (licence: no‑modify); our normalized
  table is a *separate derived structure* that references it.
- **Cache Policy:** n/a (bundled). Dataset version pinned in a meta row;
  a new version = an app update.
- **Identity:** `KnowledgeAnchor` scope=word, `segmentation` = the dataset's;
  mapped to `mushafdb-v1.01` at build time (see `QURAN_WORD_ALIGNMENT_REPORT.md`).
- **Failure Behavior:** if a word has no row → *"لا توجد بيانات موثقة"*.
  Never guessed.
- **Attribution:** "MASAQ (Sawalha et al., 2024, CC BY 4.0)" and/or
  "Quranic Arabic Corpus — corpus.quran.com" per fact's `source_ref_id`.

### L‑SYNTAX · Syntax / iʿrāb (naḥw)
- **Source:** **MASAQ v5** (72 iʿrāb roles, ~full). QAC treebank
  (~11k words) as a secondary/cross‑check.
- **Licence:** CC BY 4.0 (MASAQ) · QAC verbatim‑only.
- **Online/Offline:** **OFFLINE.** `syntax_nodes` + `syntax_relations` +
  `syntax_coverage` bundled.
- **Cache Policy:** n/a. Version‑pinned.
- **Identity:** anchors word / word_range; role vocab = closed list
  (`../QURAN_DATA_CONTRACTS.md §6`); MASAQ's 72 roles mapped, unmapped ones
  logged, not invented.
- **Failure Behavior:** ayah with no tree → the iʿrāb view is absent for it
  (honest partial coverage). No fabrication.
- **Attribution:** per fact.

### L‑TAJWEED · Tajwīd rule spans
- **Source:** **cpfair/quran-tajweed** (CC BY 4.0), cross‑checked vs QUL
  Tajweed V4 where a QUL licence allows.
- **Online/Offline:** **OFFLINE.** `tajweed_rules` bundled after the
  **offset remap** from its Tanzil base to our text/`mushafdb-v1.01`
  (mandatory — its `start/end` are codepoint offsets into a specific file).
- **Cache Policy:** n/a.
- **Identity:** anchor scope ∈ char_range | word | word_range; `rule_id`
  from the closed list; **colour chosen in‑app**, never stored.
- **Failure Behavior:** span not mapped / no data → not shown on the page;
  no colour guessed.
- **Attribution:** "quran-tajweed (CC BY 4.0)".

### L‑MEANING · Word‑by‑word meaning
- **Source:** **QUL word translations** (per‑resource licence — **verify
  before bundling**). Fallback: none (no guessing).
- **Licence:** `UNKNOWN per resource` until checked.
- **Online/Offline:** **HYBRID.** If a QUL resource is verified
  bundle‑able → OFFLINE. Else → LIVE via the gateway (our server proxies
  it) + cache.
- **Cache Policy (live mode):** on open, fetch → display → store in
  `learning_cache` keyed by `(word_identity, layer, source_version)`; next
  open = instant from cache; background revalidate (see §5).
- **Identity:** anchor scope=word.
- **Failure Behavior:** offline + not cached → *"هذا المعنى يحتاج اتصالًا
  بالإنترنت."*
- **Attribution:** per QUL resource.

### L‑TAFSIR · Tafsīr / translation‑meaning
- **Source:** existing `tafsir_entries` (~45 editions).
- **Licence:** CC‑BY family (already cleared, already bundled).
- **Online/Offline:** **OFFLINE.**
- **Failure Behavior:** edition not present → offer another; never merge or
  summarise.
- **Attribution:** per edition, verbatim, on the card.

### L‑AUDIO · Word / ayah recitation + timing
- **Source:** Quran Foundation `word.audioUrl` (public CDN
  `audio.qurancdn.com`) + `segments`/`timestamps`. (Also candidates:
  EveryAyah ayah‑level; QUL segments — each with its own licence.)
- **Licence:** **Developer Terms — no storing QF Content > 1 week; no
  redistribution without a commercial licence.**
- **Online/Offline:** **LIVE ONLY.** Streamed at playback. **Not bundled,
  not permanently cached.**
- **Cache Policy:** **ephemeral** — buffer for the current session only;
  purge on app exit / within 7 days max; never packaged, never exported.
  (If we ever adopt Content Sync APIs, follow their ≤7‑day re‑sync rule
  exactly — a deliberate, separate decision.)
- **Identity:** `recitationId`/`reciterId` (not interchangeable) +
  `(surah, ayah[, word segment index])`; word‑segment index is the
  provider's segmentation → map to `mushafdb-v1.01` for word highlight.
- **Failure Behavior:** offline → the "🔊 استماع" control is disabled with
  *"الاستماع يحتاج اتصالًا بالإنترنت."* Text tajwīd/iʿrāb still work.
- **Attribution:** reciter name + "عبر Quran Foundation API" shown at play
  time. Never presented as our file.

### L‑HADITH (future) · Ayah ↔ ḥadīth links
- **Source:** Itqan / Parallel Quran (licences to verify).
- **Online/Offline:** **HYBRID**, default LIVE until a licence clears bundling.
- **Failure Behavior:** offline → row hidden or "يحتاج اتصالًا".
- **Attribution:** the ḥadīth's own collection + grading, always.

### L‑NOTEBOOK · Student Notebook
- **Source:** the student. `ayah_study_entries` + new small tables.
- **Online/Offline:** **OFFLINE, always.** (Optional user‑owned cloud
  backup is a separate, later, opt‑in feature — never a dependency.)
- **Failure Behavior:** cannot fail offline. If a note links a concept
  whose lesson is a live layer and we're offline → the note shows, the
  linked lesson shows "يحتاج اتصالًا".
- **Attribution:** n/a (the student's own words); any source *they* cite is
  their free text.

---

## 5. Smart cache (for any HYBRID/LIVE layer that permits caching)

```
open word/ayah for layer X
   │
   ├─ in learning_cache and not stale?  → show instantly (dataState = cached)
   │        └─ background: gateway revalidates (version/etag); if changed,
   │           update the row silently and refresh if still on screen
   │
   └─ not cached:
        ├─ online  → fetch → show (dataState = live) → store in cache
        └─ offline → show "هذه المعلومة تحتاج اتصالًا بالإنترنت"
```

- Cache key: `(word_or_ayah_identity, layer, source_id, source_version)`.
- Cache scope: **respect each source's terms.** Audio (`L‑AUDIO`) is
  **excluded** from persistent cache (Developer Terms: ≤1 week, no
  redistribution) — session buffer only. Bundle‑able layers are never
  cached because they're already local.
- A student who studies a whole surah accumulates that surah's HYBRID data
  locally, page by page — without ever downloading the whole Qur'an's
  worth.
- Cache is a **convenience mirror**, never authoritative: a cached fact
  still carries its `SourceReference` and `classification`; the display
  gate (`../QURAN_DATA_VALIDATION.md §D`) still applies.

---

## 6. Failure behavior — the rules

1. **Offline never blocks:** Mushaf render, Qur'an reading, ayah navigation,
   the Ayah Notebook, and any OFFLINE layer (morphology, syntax, tajwīd,
   tafsīr) all work with no internet.
2. **Live layers degrade visibly:** each card shows its `dataState`; an
   unavailable live layer shows *"هذه المعلومة تحتاج اتصالًا بالإنترنت"* —
   never a blank, never a guess, never a stale value presented as current
   without the `⚡ محفوظ مؤقتًا` label.
3. **No unverified data just because we're online:** the display gate is
   licence + classification + source completeness. Being online does not
   lower the bar.
4. **The API is not the Qur'an:** if a live provider returns Qur'an text or
   an ayah/word identity that disagrees with our local data, **our local
   data wins** and the mismatch is logged (it must never be shown).
5. **One source down ≠ feature down:** the gateway isolates adapters; a
   dead audio CDN doesn't affect iʿrāb.

---

## 7. Attribution — always shown, never hidden

Every knowledge card renders, beneath the fact:

```
المصدر:   <name>
الكتاب/المجموعة:  <book>            (if any)
المؤلف:   <author>                  (if any)
الإصدار:  <edition / dataset version>
الرخصة:   <license>  ·  <link>
الحالة:   ● غير متصل | ☁ مباشر | ⚡ محفوظ مؤقتًا
```

- If a source's licence does **not** permit redistribution, the app still
  *names* it and links out to the owner's permitted access method (e.g. the
  API, the website) — it just doesn't hold the data.
- A single "المصادر والتراخيص" screen aggregates every source + licence +
  link (Tanzil, MushafDatabase, MASAQ, QAC, quran-tajweed, tafsīr editions,
  audio provider, …).

---

## 8. What this changes in the earlier docs

- `QURAN_LEARNING_ROADMAP.md`: the "blockers" table → **verification
  tasks**; L04/L05 (morphology/syntax) are **no longer licence‑blocked**
  (MASAQ CC BY 4.0, QAC verbatim‑ok); only **audio** is forced online; the
  **Mushaf SVG size** is an engineering packaging choice, not a blocker.
- `../QURAN_SOURCES_AND_LICENSES.md`: `license_use` updated —
  MASAQ = `bundled_ok`, QAC = `bundled_ok (verbatim, no‑modify, attr+link)`,
  QF audio = `link_only / api_stream_only`, QUL = `verify_per_resource`.
- `QURAN_LEARNING_LAYER.md §15`: the offline/online split above supersedes
  the earlier "needs external data + licence decision" list for
  morphology/syntax/tajwīd (now: **bundle**), keeps audio and QUL‑meaning
  as hybrid/live.

## 9. Re‑evaluation of the four "blockers" under AD‑1

None of these is a project stopper. Each is a **provider‑mode decision**.

| item | old framing | under AD‑1 |
|---|---|---|
| **1 · MASAQ / QAC licence** | "blocked, study‑only" | **LOCAL provider** — MASAQ CC BY 4.0, QAC verbatim+attr+link (verified). Seed a table. *If* a live morphology API is ever found, register it as an **additional ONLINE provider** — but not needed. Never a blocker. |
| **2 · Mushaf SVG ~46 MB** | "size blocker" | **HYBRID provider** — a "Mushaf Data Package": download‑all *or* lazy per‑page → cache → offline. APK stays light. Not a blocker; a packaging choice for Ismail. |
| **3 · Tanzil ↔ MushafDatabase segmentation diff** | "unknown blocker" | **Mapping Layer, not a rejection.** `source segmentation → canonical (surah, ayah, word_index) → mushaf geometry`. Build `assets/quran_learning/mapping/*.json` via the VT‑3 tool; every provider's anchors pass through it. The source is kept, always. |
| **4 · Word audio** | "can't bundle → can't use" | **ONLINE provider.** Streaming is a *valid* mode. QF via a token‑proxy (credentials obtained); `EveryAyah` as a no‑secret fallback. Session buffer only (QF terms). Recitation‑follow works online; disabled offline with a clear message — the feature is **not refused**. |

## 10. Still open (tracked in `QURAN_DATA_VERIFICATION_TASKS.md`)

- QUL per‑resource licences for word meaning / mutashābihāt / topics →
  decide LOCAL vs HYBRID per resource.
- Whether **quran.foundation's public API exposes morphology / iʿrāb**
  (would add an ONLINE morphology provider). Not assumed; to check.
- Itqan / Parallel Quran licences for the ḥadīth‑link provider.
- The Tanzil ↔ MushafDatabase word alignment (VT‑3 tool + report — designed,
  not yet run).
- The QF **token‑proxy** endpoint (`AppConfig.qfTokenProxyUrl`) — the one
  server piece; without it `AudioProvider` uses `EveryAyah` and QF
  `content` is dormant.
- Whether to adopt QF **Content Sync** for a longer audio cache (≤7‑day
  re‑sync obligation).
