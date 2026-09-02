# Ayah Study Notebook — design (`79-sa-D-ayah`)

**Status: APPROVED 2026-08-29 (design + these clarifications). Implementation
in progress.** Do **not** change `turath_annotations` or the highlight
engine while building this.

A **«دفتر دراسة شخصي لكل آية»** — not a Quran highlight, not a copy of the
Turath notebook. Open any ayah and it has a **study page that accumulates
over the years**: the ayah at the centre, and around it everything the
student gathers about it — tafsir excerpts and مفسر sayings, meaning &
context, related hadith, ʿaqīdah / fiqh / linguistic / تربوي points,
comparisons between مفسرين, questions not yet understood, links to other
ayat / hadith / books, lesson summaries, personal notes, and even a small
phrase the student liked and wants to keep.

The internal concept is **`AyahStudyEntry`**, never `AyahNote`. The system
must **never assume every entry is a "فائدة"** in the traditional sense.

### The core UX principle: free writing first

Opening an ayah and tapping **«إضافة إلى دفتر الآية»** drops the cursor
straight into the body field, keyboard up. The student writes what they
want and hits **حفظ**. Type, source, and extra details are **optional,
quick, and completable later** — never an upfront gate. Example: while
listening to a lecture the student types the point only; afterwards they
can add الشيخ / الكتاب / الدرس / التاريخ / الجزء‑الصفحة / الرابط.

### The real goal (acceptance)

> Open البقرة 255 today → *"سمعت اليوم شرح الشيخ فلان لهذه الآية، وذكر أن …"*
> → save. A month later → *"وجدت في تفسير ابن كثير …"*. A year later →
> *"هذه الفائدة ذُكرت في درس كذا …"*. Reopening the ayah shows **the whole
> journey of studying it over time**, ordered chronologically and by
> section — not a single isolated note.

**No AI.** The app only stores, organises, and links what the student
entered. No auto-summary, no rephrasing, no inference, no AI suggestions,
no content generation. The later engine is *deterministic maths* over the
real study data (entry counts, review repetition, sources, linked ayat,
study depth, time, spacing) — the Quran notebook must never become a chat
assistant.

---

## 1. Data model

```sql
CREATE TABLE ayah_study_entries (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,

  -- 2. Ayah identity — numeric, never drifts (no re-anchoring engine needed)
  surah        INTEGER NOT NULL,          -- 1..114, Hafs, matches quran_ayat PK
  ayah         INTEGER NOT NULL,          -- 1-based within the surah
  word_start   INTEGER,                   -- 1-based word_index_in_ayah; NULL = whole ayah
  word_end     INTEGER,                   -- inclusive; NULL = whole ayah

  -- 3. Entry type — the coarse category that drives the "جلسة دراسة الآية"
  --    overview counts and the primary filter. Defaults to 'personal' so
  --    free writing needs no choice. (see §3)
  entry_type   TEXT NOT NULL DEFAULT 'personal',
  -- tafsir | meaning | benefit | linguistic | fiqh | aqeedah | tarbawi
  -- | hadith | comparison | question | link | lesson_summary | personal | review
  topic        TEXT,                      -- optional free sub-tag: "الطهارة" / "بلاغة" … autocompletes from prior use
  -- optional epistemic axis: naql = ما قاله الشيخ/الكتاب, fahm = ما فهمته أنا,
  -- istinbat = فائدة استنبطتها, sual = سؤال. NULL = unspecified. Never forced.
  stance       TEXT,
  color_key    TEXT,                      -- optional; reuse the 5 StudyAnnotationColors, defaulted from entry_type

  -- the content — NO length cap: one line … full tafsir summary
  body         TEXT NOT NULL,

  -- 4. Source of the information — ALL optional, "fill what you have, finish later"
  source_type  TEXT,                      -- tafsir_book | tafsir_lesson | sheikh_lesson | book | hadith | personal | other
  source_name  TEXT,                      -- "تفسير ابن كثير" / "دروس الشيخ فلان في سورة البقرة"
  source_author TEXT,                     -- المؤلف / الشيخ
  source_ref   TEXT,                      -- جزء/صفحة/رقم الدرس/دقيقة … free text
  source_date  TEXT,                      -- when it was said/heard (free text or a date)
  source_detail TEXT,                     -- anything else

  -- lifecycle / engine signals
  status       TEXT NOT NULL DEFAULT 'none',   -- none | open (unanswered question) | resolved
  resolved_at  TEXT,
  sort_order   INTEGER,                    -- NULL = order by created_at desc; set = manual order within the ayah

  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL
);
CREATE INDEX idx_ayah_entries_ayah   ON ayah_study_entries(surah, ayah);
CREATE INDEX idx_ayah_entries_type   ON ayah_study_entries(entry_type);
CREATE INDEX idx_ayah_entries_status ON ayah_study_entries(status);

-- 9. Reserved for future typed cross-links (NOT built now — a `link` entry
--    just holds free text in `body` for v1). Ships empty or in a later
--    migration.
CREATE TABLE ayah_entry_links (
  entry_id     INTEGER NOT NULL,          -- FK ayah_study_entries.id
  target_kind  TEXT NOT NULL,             -- turath_annotation | turath_book_page | hadith | tafsir_source | quran_ayah
  target_id    TEXT NOT NULL,
  rel          TEXT,                       -- explains | supports | contrasts | see_also | asbab
  PRIMARY KEY (entry_id, target_kind, target_id)
);
```

Additive migration (next free version, ~v50). It **does not touch**
`turath_annotations`, `quran_ayat`, `tafsir_entries`, `turath_benefits`.

### Why a sibling table, not `turath_annotations` with a nullable ayah anchor

They are **structurally symmetric** (same lifecycle columns: id, type,
colour, body, status, timestamps) but the anchor is fundamentally
different: a Turath anchor is *fragile text offsets* needing a resolver; an
ayah anchor is *two integers* that never drift. Keeping them
separate-but-parallel now makes the eventual unification (Study
Intelligence priority step 3 — one `StudyItem`/`StudyEvent` model) a clean
**merge**, not a rewrite. This is called out on purpose.

---

## 2. Ayah identity

- Canonical: `(surah, ayah)` — the same key as `quran_ayat`. Stable across
  Mushaf print editions and renderers.
- Optional word range `[word_start, word_end]` (1-based, inclusive; both
  NULL ⇒ the whole ayah). Lets an entry attach to "الكلمات 12–17 من آية
  الكرسي" once MushafDatabase word indexing exists. Until then the UI only
  offers whole-ayah; the columns are ready.
- **No re-anchoring code.** Unlike the Turath side, there is nothing to
  resolve — the ayah is its own identity.

---

## 3. Entry types, topic, stance

**`entry_type`** (required, defaults to `personal`) — the coarse category
the "جلسة دراسة الآية" overview groups by, and the primary filter:

| `entry_type` | UI | meaning |
|---|---|---|
| `tafsir` | 📚 | قول مفسر / نقل من تفسير (book or lesson) |
| `meaning` | 🕮 | معنى الآية، سياقها، شرح كلمة |
| `benefit` | 💡 | فائدة مستخلصة (عامة) |
| `linguistic` | 🔎 | فائدة لغوية / بلاغية |
| `fiqh` | ⚖️ | فائدة فقهية / حكم |
| `aqeedah` | ☾ | فائدة عقدية |
| `tarbawi` | 🌱 | فائدة تربوية / سلوكية |
| `hadith` | 📜 | حديث متعلق بالآية |
| `comparison` | ⚖ | مقارنة بين أقوال المفسرين |
| `question` | ❓ | سؤال / شيء للبحث لاحقًا — `status = open` until answered |
| `link` | 🔗 | رابط بآية / حديث / كتاب / باب — free text now, typed `ayah_entry_links` later |
| `lesson_summary` | 📝 | ملخص درس سمعته |
| `personal` | ✍️ | ملاحظة شخصية / عبارة صغيرة أعجبتني (**the default**) |
| `review` | 🧠 | للحفظ والمراجعة — a review target for the engine |

In the add sheet the primary chips (`personal`, `tafsir`, `meaning`,
`benefit`, `question`, `lesson_summary`, `link`) show first; **«المزيد»**
reveals the rest. Nothing forces a choice — `personal` is pre-selected.

**`topic`** (optional free tag) — finer slicing without a rigid enum, e.g.
`fiqh` + topic `"الطهارة"`, or `linguistic` + `"بلاغة"`. Autocompletes from
the student's previously-used tags.

**`stance`** (optional, `null` = unspecified) — *whose words / epistemic
status*, orthogonal to `entry_type`:

| `stance` | meaning |
|---|---|
| `naql` | نقل — ما قاله الشيخ أو ما وُجد في الكتاب (transmission) |
| `fahm` | فهمي — ما فهمته أنا (my understanding / paraphrase) |
| `istinbat` | استنباط — فائدة استنبطتها (derived) |
| `sual` | سؤال — شيء لم أفهمه |

This is the "**ما قاله الشيخ** ≠ **ما فهمته أنا**" distinction. Optional —
a small toggle in the sheet, never a required step. Rendered as a subtle
label on the card (e.g. «نقل» in muted text).

`color_key` (optional) reuses the five `StudyAnnotationColors` so the Quran
and Turath notebooks read as one system; defaulted from `entry_type` and
overridable.

---

## 4. Source of the information

All source fields are **optional**. Two capture speeds:

- **Quick** (mid-lesson): pick `entry_type`, type the `body`, optionally
  one line in `source_name` ("من تفسير الشيخ فلان"). Save. Done in seconds.
- **Complete later**: reopen the entry, fill `source_type` / `source_author`
  / `source_ref` / `source_date` / `source_detail` as available.

`source_type` is the only enum (for the "الفوائد من التفاسير" style
filters); the rest are free text. Nothing is ever required beyond
`(surah, ayah)`, `entry_type`, `body`.

---

## 5. Search

Full-text `LIKE` over `body` + `source_name` + `source_author` +
`source_detail` (an FTS index is a later optimisation, same as the Turath
notebook). `ابحث في ملاحظاتي عن «الإخلاص»` → every ayah that has a matching
entry, grouped by `(surah, ayah)` in mushaf order, each showing the
matching snippet.

Filters (composable): `entry_type` (multi), `source_type` (multi),
surah / juz, `status` (open questions · to-review), date range.
Sorts: **recent** (default) · **by mushaf order** · **richest**
(`COUNT(*) per (surah,ayah)` desc — "الآيات الأكثر ثراءً بالملاحظات").

---

## 6. One ayah → many entries — "جلسة دراسة الآية"

`SELECT * FROM ayah_study_entries WHERE surah=? AND ayah=? ORDER BY
COALESCE(sort_order, 9e18), created_at ASC` — practically unlimited entries
(20+, different sources, different years). Default order is **chronological
ascending** so the page reads as the study *journey* over time; a "الأحدث
أولًا" toggle flips it.

**`AyahNotebookScreen(surah, ayah)`** is a study session, **not a flat
list**:

1. **Header** — surah name + ayah number + the **ayah text itself**
   (`text_uthmani` from `quran_ayat`, the Uthmani rendering the app already
   uses).
2. **Overview strip** — counts per non-empty `entry_type`, e.g.
   `💡 12 فائدة · 📚 4 أقوال مفسرين · 📜 2 حديث · ❓ 3 سؤال · 📝 5 ملخص درس · 🔗 2 رابط`.
   Tapping a chip filters the list below to that type.
3. **The entries** — cards in chronological order (or grouped by type via a
   toggle): type icon + colour dot, an optional `stance` label («نقل» /
   «فهمي»), a one-line source label (only the present parts of
   `source_name — source_author — source_ref — source_date`), the `body`
   (expand if long), a status chip for `question`/`review`, edit / delete,
   drag-handle for `sort_order`.
4. **`➕ إضافة إلى دفتر الآية`** — the add sheet, body field focused
   immediately (see §3 / the free-writing principle).

---

## 7. Deep-link: entry → ayah

Tapping an entry (in `AyahNotebookScreen` or the cross-ayah home) opens the
ayah. Target: **`AyahStudyScreen(surah, ayah)`** (already exists, Phase 72,
ayah-centred, has prev/next-ayah + tafsir + a reader). Pass
`focusEntryId`; when MushafDatabase word anchoring lands, also scroll/pulse
the exact ayah/word on the real Mushaf page.

## 8. Deep-link: ayah → its notebook

- In `AyahStudyScreen`: a section / tab **«دفتري لهذه الآية (N)»** →
  `AyahNotebookScreen(surah, ayah)`; and a quick **«➕ أضف فائدة لهذه الآية»**.
- In `quran_reading_screen.dart`'s ayah long-press menu (which already has
  "دراسة الآية" / "تسميع" / favourite / share): add **«📓 دفتري لهذه الآية (N)»**
  and **«➕ أضف فائدة»**. `N` = `annotationCountForAyah(surah, ayah)`.

## 9. Future linkability (design now, build later)

`ayah_entry_links` (above) lets a `link` entry hold real typed edges to a
Turath annotation, a book page, a hadith, a tafsir source, or another ayah.
Not built now. Independently, `(surah, ayah)` is already the join key for
the Study Intelligence **Knowledge Graph** (`STUDY_INTELLIGENCE_ENGINE_SPEC.md`
§8): `Ayah → Surah → Juz → Page → Annotation`, `Ayah explains Tafsir`,
`Ayah cross_ref Hadith`. The ayah becomes a central node in the student's
accumulated knowledge without any AI.

## 10. Usable by the Study Intelligence Engine

Projection (later, at Study Intelligence step 1 — nothing to do now):

| this feature | → `study_events` / `study_items` |
|---|---|
| create entry | `StudyItem(kind = quran_ayah` or `quran_word)` if new; `StudyEvent(note)` |
| edit entry body | `StudyEvent(note)` |
| `review` entry marked reviewed | `StudyEvent(review)` + `successful_recall` / `failed_recall` |
| `question` opened / resolved | `StudyEvent(opened)` / `resolved` (open-questions count) |
| `entry_type`, `source_type`, entry count per ayah | feed **DepthScore**, **KnowledgeStrength** per ayah/surah, and the "richest ayat" base indicator |

Every entry therefore ships, from day one and unchangeably, with:
**stable `id` · ayah identity `(surah, ayah[, word range])` · `created_at`
· `updated_at` · `entry_type` (fixed enum) · `stance` (fixed enum | null) ·
source metadata**. The maths engine reads these events/fields later
**without editing any notebook content**. Do not build the model in a way
that forces a redesign when the engine arrives.

---

## Relationship to what already exists

- **`turath_benefits`** — stays for standalone takeaways with no ayah and no
  book source. A benefit *about an ayah* is an `ayah_study_entries` row
  (`entry_type='benefit'`).
- **`AyahStudyScreen` tafsir cards** — *bundled, read-only* tafsir from
  `tafsir_entries`. The notebook is the *student's own* accumulated study.
  The screen gains a "دفتري" surface pointing at `AyahNotebookScreen`.
- **`turath_annotations` (the Turath notebook)** — the sibling system for
  book passages. Same shape, different anchor; merged later, not now.

## Deferred (not in `79-sa-D-ayah`)

- The typed cross-link editor UI (`ayah_entry_links` ships empty).
- MushafDatabase word-precise anchoring + scroll-to-ayah on real art.
- Unifying Quran + Turath notes into one `StudyItem` table (Study
  Intelligence priority step 3).
- Rich text in `body` (v1 = plain text + line breaks; "long text" is enough).
- FTS index (LIKE for v1).

## Acceptance criteria

1. **The journey**: add an entry to البقرة 255 today, another (different
   source) a month later, another a year later → reopening the ayah shows
   all three ordered chronologically, grouped by section, as a study
   *journey* — not one isolated note.
2. **Free writing first**: «إضافة إلى دفتر الآية» → cursor in the body
   field, keyboard up; `حفظ` works with body only (type defaults to
   `personal`, no source).
3. One ayah holds many entries from different sources over time; each keeps
   its own source identity, `stance`, and date.
4. `body` accepts one line or several paragraphs with no truncation.
5. No field is mandatory except `(surah, ayah)` + `body` (type defaults).
6. Search "الإخلاص" returns every ayah with a matching entry.
7. Ayah → «دفتري لهذه الآية (N)» and entry → ayah both navigate correctly.
8. Deleting/editing an entry never touches `quran_ayat`, `tafsir_entries`,
   `turath_annotations`, or the highlight engine.
9. `entry_type` / `stance` / `status` are stored as the fixed enum strings
   above (so the engine can consume them later).

## Build phasing (after approval)

1. Migration + `AyahStudyEntry` model + `AyahStudyRepository` (CRUD, `entriesForAyah`, `search`, `countForAyah`, `notebookEntries({filters})`).
2. `AyahNotebookScreen(surah, ayah)` + add/edit sheet.
3. Entry points: `AyahStudyScreen` section + `quran_reading_screen` ayah menu + deep-link back.
4. `QuranNotebookHomeScreen` (cross-ayah: filters, search, sorts, "richest").
5. All strings in `basic_translations.dart` (13 languages) from the start.

No Study Intelligence wiring — that is a separate later phase.
