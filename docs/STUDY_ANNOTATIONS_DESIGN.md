# Study Annotations — «علامات الدراسة»

Design reference for the Turath-library annotation system (Phase 79 follow-on).
Approved by Ismail 2026-08-29. Implementation is phased; this doc is the contract.

## Goal

A طالب العلم reading a book page selects text, highlights it in a **meaning-coded
colour**, and optionally attaches a typed note. Months later he reopens the book,
sees the highlight over the **full** span he selected, taps it, reads his note —
and from the notebook he can jump back to the exact spot. Filtering by
colour/type/book/category turns the library into a personal scholarly memory, with
no live AI anywhere.

This **replaces** the three overlapping "keep this" concepts that exist today
(`turath_notes`, `turath_quotes`, `turath_benefits`) with **one** anchored model;
the notebook and "quotes" become *views* over it.

## The one rule that was contested and resolved

The stored highlight is the **entire selection**, first character to last —
`selection.textInside(text)` — never the first word, never a truncated fragment.
The highlight is drawn over the **whole range**, wrapping across as many visual
lines as it covers. A "first word" / head fragment may be stored *in addition*, as
a **locator only** — it is never the selection itself.

Three separated layers:

| Layer | Question | Storage |
|---|---|---|
| **1. selected_text** | ماذا ظللت؟ | the full selection verbatim, untruncated (`TEXT`, no length limit) |
| **2. anchor** | أين ظللت؟ | offsets + checksum + surrounding context + head/tail locators |
| **3. highlight ranges** | كيف أرسمه كاملًا؟ | resolved `[start,end)` → `TextSpan` runs with `backgroundColor` |

## Current engine (inspected 2026-08-29)

- `TurathReaderScreen` shows **one page** in **one `SelectableText`**. Text is
  `_stripHtml(page.text).trim()` — a single Dart `String` (UTF-16).
- Selection → `TextSelection.start/.end` (normalised), `selection.textInside(text)`
  = the full substring. Nothing truncates; `firstWord` exists nowhere.
- Offsets are **logical** (string indices) — unaffected by RTL wrap, font size, or
  screen width; those only change *visual* layout, which Flutter's painter owns.
  → the model is display-independent by construction (satisfies "no x/y").
- The only fragility: offsets are valid **only** against the identical normalised
  string. Mitigated by `norm_version` + `text_checksum` + re-normalise on load,
  then re-anchor by quote → head/tail → fuzzy → orphan.
- No code stores offsets today — clean slate. `turath_notes.selected_text` /
  `turath_quotes.quoted_text` keep the snippet string only.
- Cross-page selection is **physically impossible** with a one-page-per-widget
  reader (next page isn't mounted). Not built now; `span_group_id` is the forward
  hook for a future continuous-scroll reader.

## Data model (migration v49)

```sql
CREATE TABLE turath_annotations (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  span_group_id     TEXT,                 -- nullable; stitches multi-row logical highlights (future cross-page). v1: always NULL.
  book_id           INTEGER NOT NULL,     -- turath.io book id
  page_number       INTEGER NOT NULL,     -- turath.io pg
  volume            TEXT,                 -- TurathPage.volume, for citation

  -- LAYER 1 — the full selection, verbatim, never truncated
  selected_text     TEXT,                 -- NULL => page-level note (drawn as a 📌 pin, not a run)
  selected_len      INTEGER,              -- selected_text length in UTF-16 units; drives the acceptance check

  -- LAYER 2 — where it is / how to re-find it
  char_start        INTEGER,              -- UTF-16 offset into normalizePageText(page.text)
  char_end          INTEGER,              -- exclusive; char_end - char_start == selected_len at capture
  norm_version      INTEGER NOT NULL DEFAULT 0,   -- version of normalizePageText() used at capture
  text_checksum     TEXT,                 -- checksum of the whole normalised page text at capture
  text_length       INTEGER,
  prefix_context    TEXT,                 -- ~48 chars immediately before char_start  (locator)
  suffix_context    TEXT,                 -- ~48 chars immediately after  char_end    (locator)
  head_anchor       TEXT,                 -- first ~64 chars of selected_text          (locator, NOT the selection)
  tail_anchor       TEXT,                 -- last  ~64 chars of selected_text          (locator, NOT the selection)
  occurrence_index  INTEGER NOT NULL DEFAULT 0,   -- if selected_text repeats on the page, which hit (0-based)

  -- LAYER 3 — highlight + note (folded in, 1:1)
  color_key         TEXT NOT NULL DEFAULT 'benefit',  -- benefit|explain|memorize|important|question  (semantic, not hex)
  note_type         TEXT,                 -- nullable: benefit|explain|question|correction|review
  note_body         TEXT,                 -- nullable

  -- housekeeping
  anchor_status     TEXT NOT NULL DEFAULT 'exact',    -- exact|shifted|fuzzy|orphan|unanchored
  source_kind       TEXT NOT NULL DEFAULT 'annotation', -- annotation|legacy_note|legacy_quote
  legacy_id         INTEGER,              -- original row id in the old table (traceability / idempotent re-migration)
  book_name         TEXT NOT NULL,        -- denormalised so the notebook renders fully offline
  author_name       TEXT,                 -- denormalised from the catalog at creation time
  created_at        TEXT NOT NULL,
  updated_at        TEXT NOT NULL
);
CREATE INDEX idx_turath_annotations_page  ON turath_annotations(book_id, page_number);
CREATE INDEX idx_turath_annotations_color ON turath_annotations(color_key);
CREATE INDEX idx_turath_annotations_group ON turath_annotations(span_group_id);

ALTER TABLE turath_benefits ADD COLUMN annotation_id INTEGER;   -- standalone benefits leave it NULL
```

`anchor_status = 'unanchored'` = has `selected_text` but never resolved to offsets
(all migrated legacy rows). The resolver upgrades it to exact/shifted/fuzzy/orphan
on the first page visit and persists the result.

### Legacy migration (v49, and re-run guarded in a later version)

- `turath_notes` → annotation, `source_kind='legacy_note'`, `color_key='explain'`,
  `note_type='explain'`, `note_body=note`. `selected_text` NULL ⇒ page-level.
- `turath_quotes` → annotation, `source_kind='legacy_quote'`, `color_key='benefit'`,
  `note_type='benefit'`, `note_body=note`, keeps `volume`/`author_name`.
- Old tables are **kept, read-only**, for one release as a safety net. The read
  path in the UI switches to `turath_annotations` in Phase D; a v50 migration then
  does a `WHERE NOT EXISTS (source_kind, legacy_id)` catch-up for anything created
  via the old flow between A and D, and a later version drops the old tables.

## Re-anchoring (pure, `lib/utils/study_annotation_anchor.dart`)

`normalizePageText(raw)` — the single normalisation, versioned `kNormVersion`.
Strip HTML, CRLF→LF, collapse `[ \t]+`, cap blank runs, trim. **Phase B switches
the reader to render this exact string** so display offsets == anchor offsets.

`resolveAnchor(normalizedPageText, storedAnchor) -> ResolvedAnchor{status,start,end}`:

1. **exact** — `norm_version` current, `text_checksum` matches, offsets in range,
   and `substring(start,end) == selected_text` → use offsets as-is.
2. **shifted** — exact substring search for `selected_text`; 1 hit → adopt it;
   many hits → disambiguate by `prefix_context`/`suffix_context` + `occurrence_index`.
3. **fuzzy (head/tail)** — interior changed: find `head_anchor`, then `tail_anchor`
   after it; span = `[headStart, tailEnd)`.
4. **fuzzy (window)** — slide a `selected_text`-sized window, token-overlap score
   ≥ threshold → take the best window.
5. **orphan** — no acceptable match. The annotation is **kept** (still in the
   notebook with its text + citation), just **not drawn**; the page offers
   "أعد ربطها يدويًا".

The resolved offsets + status are persisted so the next load is O(1).

## Rendering (Phase B)

`SelectableText.rich(TextSpan(children: runs))`. On load: resolve every annotation
for `(book_id, page_number)` → concrete `[start,end)` ranges → split the page
string at all range boundaries → one `TextSpan` per run:

```dart
TextSpan(
  text: sub,
  style: run.covered ? base.copyWith(backgroundColor: colour(colorKey, night)) : base,
  recognizer: run.covered ? (TapGestureRecognizer()..onTap = () => _openAnnotation(run.id)) : null,
)
```

A `TextSpan` with `backgroundColor` tints **behind every glyph, wrapping across
every visual line** the range spans — a continuous marker stroke that follows the
text. No per-line rectangles, no coordinates. Selection still works.

- **Overlap** (v1): split at all boundaries; a sub-run under ≥2 annotations takes
  the newest colour; tapping it opens a small chooser.
- **Night mode**: each `color_key` is a `{light, night}` pair, low saturation, α ≤ 0.25.
- v1 accepts that `backgroundColor` hugs the glyphs (not full line-height); a
  full "marker band" custom painter is deferred (breaks nothing).

## Colours (semantic keys, not hex)

| key | label | |
|---|---|---|
| `benefit` | فائدة | 🟨 |
| `explain` | شرح | 🟦 |
| `memorize` | للحفظ والمراجعة | 🟩 |
| `important` | مهم جدًا | 🟥 |
| `question` | سؤال / إشكال | 🟪 |

`AppColors.studyAnnotation(colorKey, night)` — one place. `note_type` defaults from
`color_key` but may diverge.

## UX flows

- **Create**: select → context menu `{مشاركة, تظليل}` → colour strip (5 labelled) →
  pick = saved immediately → same sheet "أضف فائدة" reveals a field + type chips.
  2 taps to a bare highlight, 4 to highlight + typed note. The old
  `{أضف ملاحظة, اقتباس}` items are folded into this.
- **Return**: open reader → resolve → render colour runs → tap run → bottom sheet
  (view / edit note / recolour / delete / "حوّلها لفائدة").
- **Notebook → spot**: `TurathReaderScreen(..., focusAnnotationId: id)` (new param)
  → after layout, `TextPainter`-computed offset → `ScrollController.animateTo` →
  brief background pulse.
- **Unified «دفتر الفوائد»**: absorbs the Notes tab + Quotes + Benefits screens.
  Filters: colour/type chips · book · **category** ("فوائدي في كتب العقيدة") ·
  free-text over `note_body`+`selected_text` · group by book/type/date.
- **`TurathBookScreen`**: row "فوائدي في هذا الكتاب (N)".

## Phases

- **A — schema + model + repo + anchor unit (no UI).** migration v49; legacy
  migration; `StudyAnnotation` model; repo CRUD + queries; pure
  `study_annotation_anchor.dart`; tests (anchor resolution + repo + legacy migration).
- **B — render highlights read-only.** `SelectableText.rich` colour runs; reader
  switches to `normalizePageText`; tap → view/delete/recolour sheet; night colours.
  Gate: prototype R2 (tap on `TextSpan`) + R3 (scroll-to-run) first.
- **C — create/edit flow.** context menu, colour strip, note + type.
- **D — unified notebook + deep-link-to-spot.** `focusAnnotationId`, filters,
  merge benefits, "فوائدي في هذا الكتاب", redirect old entry points; v50 catch-up
  migration.
- **E — polish.** free-text search, "خريطة الفوائد" counts + plain-text export
  (no AI), manual re-anchor UI, all 13 translations.

## Risks

| # | risk | mitigation |
|---|---|---|
| R1 | upstream page text changes (re-OCR) → offsets rot | quote + head/tail + context + checksum resolver; orphans kept, never deleted |
| R2 | `TapGestureRecognizer` on `TextSpan` in `SelectableText.rich` may lose to selection gestures | prototype in B before commit; fallback = "annotations on this page" chip row + long-press "افتح الملاحظة" |
| R3 | scroll-to-range needs real render width/scale; `ensureVisible` doesn't work on inline spans | `TextPainter` offset with real constraints; v1 = scroll to the run's line + pulse |
| R4 | normalisation mismatch capture vs load → everything looks "shifted" | one versioned `normalizePageText()` everywhere; `norm_version` stored; re-migrate offsets if it changes |
| R5 | overlapping highlights | boundary-split runs; newest colour wins; tap → chooser |
| R6 | legacy notes/quotes with `selected_text = NULL` | page-level note = 📌 pin, not a run; old tables kept one release |
| R7 | thousands of annotations → slow notebook | indexes on `(book_id,page_number)` + `color_key`; paginate; FTS later |
| R8 | night mode + 5 translucent colours legibility | low-saturation palette, α ≤ 0.25; real-device check before shipping B |
| R9 | double source of truth during A→D | old tables read-only after migration; v50 catch-up; drop later |
| R10 | very large selection (whole page) → multi-KB `selected_text`, heavier fuzzy search | fine for storage; fuzzy is offline + rare; head/tail path handles it cheaply |

## Acceptance criteria

1. Select from start of line 1 to end of line 3 → save → close book → reopen → go
   to page → the highlight shows **in full** over every selected word and line.
2. Tap any part of the highlight → the linked note appears.
3. Open the note from the notebook → returns to the same book + page, scrolls the
   range into view + pulses.
4. Stored `selected_text` **==** exactly what the user selected (length + content).
   A highlight covering only the first word / part = **fail**.
5. word / sentence / multi-sentence / multi-line all render as one continuous range.
