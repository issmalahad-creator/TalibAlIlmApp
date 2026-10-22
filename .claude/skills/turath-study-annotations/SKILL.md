---
name: turath-study-annotations
description: >-
  Load before touching the Turath (Islamic-text) reader's highlights, page
  notes, or the unified study notebook in TalibAlIlmApp — `turath_reader_screen.dart`,
  `annotated_page_text.dart`, `turath_study_notebook_screen.dart`,
  `turath_repository.dart`'s annotation methods, or `turath_annotations` /
  `study_annotation_anchor.dart`. Carries the one-table model, the
  highlight vs page-note distinction, the re-anchoring engine, and the
  selection-interaction architecture.
---

# Turath study annotations

## One table, one source of truth

`turath_annotations` (schema `_createV49Tables` in `database_helper.dart`)
holds **every** study annotation. No copies. `allAnnotations` /
`notebookEntries` / `resolvedAnnotationsForPage` are views over it.
`turath_notes` / `turath_quotes` are legacy read-only after
`migrateLegacyToAnnotations`.

`source_kind` is the discriminator:
- `'annotation'` (default) — a **text highlight**: `selected_text` +
  `char_start/char_end` + the anchor columns (`prefix_context`, `head_anchor`,
  …) locate it and re-find it if the page text drifts.
- `'page_note'` — a **page note**: a colour + a note attached to the whole
  `(book, page)`, **all anchor columns NULL**, `anchor_status = 'page'`.
  Ismail's durable fallback for when text selection breaks on a device.

**No migration was needed for page notes** — every column already existed
and is nullable except `color_key` (default), `book_name`, `created_at/at`.

### Repository (`turath_repository.dart`)
- `addAnnotation(...)` — highlight; runs `_anchorFields(text, selectedText, hint)`.
- `addPageNote({bookId, pageNumber, volume, colorKey, noteBody, bookName, authorName})`
  — inserts with `source_kind:'page_note'`, no `_anchorFields`.
- `pageNotesForPage(bookId, page)` — `WHERE source_kind='page_note'`.
- `recolorAnnotation` / `updateAnnotationNote` / `deleteAnnotation` work by
  id and are `source_kind`-agnostic — **reuse them for page notes** (don't
  add parallel methods).
- `resolvedAnnotationsForPage` **skips re-anchoring** page notes (guarded by
  `a.sourceKind == 'page_note' || a.isPageLevel` → `ResolvedAnchor(orphan,
  null, null)`), otherwise it would flip their status to "orphan" and churn
  a write every page load.

### Model (`StudyAnnotation`, `lib/models/turath_models.dart`)
Already had `sourceKind` + `isPageLevel` (`selectedText == null || empty`)
before page notes existed. `StudyAnnotationColors.all` = benefit / explain /
memorize / important / question. `AppColors.studyAnnotation(key)` → (light,
dark, accent).

## Reader (`turath_reader_screen.dart`)

- Highlights draw via `_pageHighlights()` (excludes `isPageLevel`) →
  `AnnotatedPageText(highlights:)`. Page notes + highlights both surface as
  tappable colour chips via `_pageMarks()` → `PageMarksBar` → `_openAnnotationSheet`.
- `_openAnnotationSheet` handles `isPageLevel` (hides the "selected text"
  box and the "edit range" button).
- `_startHighlight(selectedText, hint, lang)` — the create-highlight sheet
  (colour wrap + optional note). `_openPageNoteSheet(lang, {existing})` —
  same shape minus selected text; `existing != null` routes to
  `_openAnnotationSheet`. AppBar has a `note_add` `IconButton` with a
  `Badge` count of `_pageNotes`.
- Body padding is `EdgeInsets.fromLTRB(12,20,12,20)` (trimmed from 20 for
  the left selection handle — see `flutter-text-selection`).

## One-step highlighting (2026-10-22, Ismail: «جهد في التظليل… أصلح»)

- **Selection toolbar** = `_QuickHighlightBar` (custom `AdaptiveTextSelectionToolbar`
  children): five colour dots — **one tap saves** the highlight in that colour
  (`_quickHighlight`, snackbar «تراجع» → `deleteAnnotation`) — then note · copy ·
  share. «ملاحظة» saves with the pen colour and opens `_quickNote` (one field,
  saved on close via `updateAnnotationNote`). The old colour+note sheet
  (`_startHighlight`) is gone. Edit-range mode keeps the system items + «تحديث النطاق».
- **«قلم التظليل»** (FAB → `_penMode`): the page renders as `PenPageText` (plain
  `RichText` + `GestureDetector`, **no SelectableText**, so no arena fight):
  a sideways stroke = pan → live preview → `snapToWords` → saved; vertical
  swipes still scroll (vertical drag wins its smaller slop); double-tap =
  `sentenceAt`; tap on a highlight opens it. Offsets via the live
  `RenderParagraph.getPositionForOffset`. `_PenBar` picks the colour
  (pref `turath_pen_color`, also the toolbar's default).
- Span drawing is shared: `annotatedSpans(...)` in `annotated_page_text.dart`.
- Tests: `test/turath_pen_highlight_test.dart`.

## `AnnotatedPageText` (`lib/widgets/annotated_page_text.dart`)

Returns `SelectableText.rich` **verbatim** — no per-span `recognizer`, no
`Listener`, no `GestureDetector`, no `TextPainter` hit-test. Highlights are
`TextSpan.backgroundColor` runs (flow across wrapped lines as one marker
stroke). Tap-to-open a highlight is driven ONLY by `onSelectionChanged`
(`cause == SelectionChangedCause.tap` + collapsed → `selection.baseOffset` →
covering run). `magnifierConfiguration` is set. See the `flutter-text-selection`
skill for the full rationale and the RTL handle issue.

## Unified notebook (`turath_study_notebook_screen.dart`)

Rows come from `notebookEntries` (includes page notes automatically).
`_EntryCard` already renders `isPageLevel` (no quoted text, shows note body
+ a "📄 ملاحظة على هذه الصفحة" tag, no re-anchor button). Filters: a kind
row (`الكل / تظليلات / ملاحظات صفحة`, client-side via `_visible`) + the
colour `FilterChip`s. The chip row is `SingleChildScrollView`+`Row` (eager,
so index-based widget tests keep working).
