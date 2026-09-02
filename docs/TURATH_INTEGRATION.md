# Turath Library Integration ("المكتبة التراثية")

Real integration of turath.io's public API into طالب العلم as a native Flutter feature — Phase 79 of `TODO.md`. Written so another developer can understand the system without asking the person who built it.

## Architecture

Strict one-way layering, never skipped:

```
Screens (Presentation)
    ↓
TurathRepository
    ↓
TurathApiClient  ──(network)──►  api.turath.io / files.turath.io
    ↓
DatabaseHelper (SQLite, local-only: favorites/notes/last-read/cache)
```

No screen ever imports `TurathApiClient` or makes an HTTP call directly. `TurathRepository` is the only class that talks to both the network and the local database — it's what makes the "online-first + cache fallback" strategy possible in one place instead of scattered across screens.

Files:
- `lib/services/turath_api_client.dart` — raw HTTP: requests, retry, throttling, JSON parsing quirks.
- `lib/repositories/turath_repository.dart` — everything a screen actually calls: search, book/page fetch with cache fallback, favorites, last-read, notes, and the canonical-catalog reads (`categories`, `categoryBookCount`, `booksInCategory`, `catalogAuthors`, `booksByAuthor`).
- `lib/repositories/turath_catalog_sync.dart` — builds/refreshes the local canonical catalog from `files.turath.io/data-v3.json` (validate → single transaction → wholesale rebuild); called once from `main.dart` startup.
- `lib/models/turath_models.dart` — `TurathSearchResult`, `TurathBook`, `TurathIndexEntry`, `TurathPage`, `TurathAuthor`, `TurathFavorite`, `TurathLastRead`, `TurathNote`. Deliberately independent of any widget.
- `lib/screens/turath_*.dart` — `turath_library_screen` (search + topic shortcuts + entry to "مكتبتي"), `turath_topic_books_screen` (topic → grouped book results), `turath_book_screen` (book detail: read/index/search-in-book/favorite), `turath_book_search_screen` (in-book search), `turath_index_screen` (table of contents), `turath_reader_screen` (the actual page reader), `turath_my_library_screen` (favorites/recently-read/notes, tabbed).

## API client

Real, live-verified endpoints (curl-tested against `api.turath.io`, not assumed from the reference SDK's README):

| Call | Endpoint | Notes |
|---|---|---|
| `search(q, catId?, bookId?, authorId?, page?)` | `GET /search` | `book_id` and `author_id` filters verified live 2026-08-28 — not documented in the reference SDK at all, but real. |
| `getBookInfo(bookId)` | `GET /book?id=&include=indexes` | Returns `{meta, indexes: {volumes, headings}}`. |
| `getPage(bookId, pageNumber)` | `GET /page?book_id=&pg=` | |
| `getAuthor(authorId)` | `GET /author?id=` | |
| `getBookFile(bookId)` | `GET files.turath.io/books/{id}.json` | Full book dump — only for a future whole-book download feature, never used for normal reading. |

**No API key required today.** `TurathApiClient`'s constructor still takes `apiBase`/`timeout`/`maxRetries` as real parameters (not hardcoded), so auth can be added later without touching call sites.

**Known quirk**: the `meta` field in `/page` and `/search` responses is a JSON-encoded *string*, not a nested object — `_decodeMeta()` is the one place that's handled.

## Caching

`turath_book_cache` / `turath_page_cache` (SQLite) store only what's actually been fetched — never the whole library. Strategy is **online-first**: every `getBookInfo`/`getPage` call hits the network first; only on a network *failure* does it fall back to whatever's cached for that exact book/page. A student who's never opened a book has nothing cached for it, by design (spec explicitly forbids pre-downloading the library).

## Rate limiting

`TurathApiClient` serializes every request through one queue (`_requestQueue`) and enforces a minimum 250ms gap between requests (`minRequestGap`). No two requests ever fire concurrently, and search-as-you-type can't flood the API even if debounce were somehow bypassed. Search itself is debounced 500ms client-side (`turath_library_screen.dart`/`turath_book_search_screen.dart`) — one request per pause in typing, not per keystroke.

## Error handling

`TurathApiException` carries a real HTTP status when available. A real 404 is never retried (retrying `maxRetries` times on a genuine 404 is documented as intentionally-not-worth-it); other failures retry with 300ms×attempt backoff. Every screen maps failure states to an honest, non-technical message (`turath_network_error`/`turath_page_load_error`) with a retry button — never a raw stack trace shown to the student.

## Catalog (canonical membership index)

`turath_catalog_*` tables (migration v48), seeded by `TurathCatalogSync` from
**`https://files.turath.io/data-v3.json`** — turath.io's own complete manifest,
the same file `app.turath.io` downloads on startup. A dated snapshot ships as
`assets/turath/catalog-v3.json.gz` so browsing works offline on first launch;
the network copy is pulled in the background when the local one is stale
(> 14 days) *and* reports a newer `version`.

The manifest has three parts: `cats` (40 categories, each `{id, name, books:[bookId…]}`),
`books` (8,593 `{id, name, author_id, cat_id, has_pdf, page_count, size}`), and
`authors` (3,188 `{id, name, death, books:[…]}`).

Tables:
- `turath_catalog_categories(cat_id, name_ar, total_books, sort_order)` — `total_books` is **authoritative**.
- `turath_catalog_category_books(cat_id, book_id, PRIMARY KEY(cat_id, book_id))` — the explicit membership relation. Every query for "which books are in this category" goes through here, not `turath_catalog_books.cat_id`, so multi-category membership needs no query change later.
- `turath_catalog_books(book_id, name, author_id, cat_id, has_pdf, page_count, size)`.
- `turath_catalog_authors(author_id, name, death_year)`.
- `turath_catalog_meta(key, value)` — `version`, `date`, `synced_at`, `synced_at_ms`, `source`.

**A category's book count is never counted from search results.** `TurathCategoriesScreen`
reads `total_books`; `TurathTopicBooksScreen` pages `booksInCategory(catId, limit, offset)`
straight from the join table, so the count (808 for العقيدة) is identical whether you
just opened the category, scrolled to the end, or searched inside it.

**Validation before any write** (`TurathCatalogSync.validate`): a `GET` succeeding is
not proof the data is good. The parsed payload must have exactly 40 categories,
8,593 books, 3,188 authors, membership rows summing to 8,593, zero books with no
category, zero dangling memberships, zero duplicate `(cat_id, book_id)` pairs — plus
a post-insert cross-check inside the transaction. Any failure **rejects the sync and
keeps the existing catalog**; it never half-writes.

> **Note — the `8593` / `3188` totals are a `version: 1` baseline, not a permanent
> truth.** Today only one catalog version is published, so exact-match on the totals
> is a fine corruption check. When turath.io ships a newer catalog (`version: 2` with,
> say, 8,700 books; `version: 3` with 9,000; …) `validate()` must be reworked to gate
> on the payload's **internal consistency + `version`/`date`**, not to reject a new
> version just because the book count changed. The invariants that always hold:
> every membership references an existing book, every book has a valid category, no
> duplicate `(cat_id, book_id)`, and `sum(membership) == distinct member books ==
> books.length` with zero orphans/dangling. The absolute totals then become
> "expected for this version" (log a warning on mismatch), not a hard reject. This
> is a deliberate future step — see `TODO.md` `79-mi-future-validation`.

`lib/data/turath_categories.dart` remains only as an offline fallback (the 40 names +
a dated count snapshot) for the brief window before the catalog is seeded.

## Search

Search is for *finding text*; the catalog is for *membership*. They never mix — a
search result is filtered **by** membership, it never defines it.

1. **Library-wide** (`turath_library_screen.dart`) — `TurathRepository.search(query)`, no `cat_id`, over the whole library. Results are page snippets; tapping one opens the reader at that page.
2. **In a category** (`turath_topic_books_screen.dart`) — `TurathRepository.searchInCategory(query, catId)`: the API's `cat_id` filter narrows server-side, then results are intersected with `categoryMemberIds(catId)` (the local `turath_catalog_category_books` set) so a book from another category can never appear. The screen toggles between *browse* (DB pagination, empty search box) and *search-in-category* (snippet results).
3. **In-book** (`turath_book_search_screen.dart`) — the same search scoped with `book_id`.

The old `_neutralQuery = 'الله'` category-browse hack is gone entirely.

## Category browsing (`turath_topic_books_screen.dart`)

- **Browse**: `booksInCategory(catId, limit, offset, pdfOnly)` — deterministic order (`name`, then `book_id`), paged through the membership join table. Header shows `categoryBookCount` (808 for العقيدة) and it never moves — not for scrolling, not for search, not for the PDF filter.
- **PDF only**: a `FilterChip` in browse mode; narrows the list to `has_pdf = 1` and shows `categoryPdfBookCount(catId) / total`. The canonical count is untouched.
- **Per-book metadata** shown from the catalog with no network call: author name, `page_count`, and a PDF icon when `has_pdf`.

## Reader

`turath_reader_screen.dart`: real page text and headings, page navigation (prev/next/jump-to), font size (shares `TextScalePreferenceService` with the rest of the app, not a parallel setting), night mode, and a custom text-selection menu (copy/select-all plus real "share" and "add note" actions). Text is rendered in the **Amiri** font specifically — the default theme font has no glyph for classical-Arabic presentation-form ligatures (e.g. U+FD4A, found live on a real page during testing, rendered as an empty box `[]`); Amiri is built for this kind of classical typesetting.

Every page that successfully loads is saved as that book's last-read position automatically — not on an explicit "save" action, since a student rarely remembers to do that.

## Offline strategy

Phase one only, matching the spec: **recently-read books, favorited books/pages, and anything already cached from a real visit.** No bulk download, no "download entire book" feature yet — that's explicitly deferred pending a real check of turath.io/Nuqayah's redistribution terms (see Attribution below).

## Attribution

`turath_source_attribution` (shown on every book's detail screen) states the content is from the turath.io library. Any future "download whole book" or offline-package feature must not ship before someone actually reads and confirms the source's redistribution terms — public-domain-looking classical texts are not automatically safe to bulk-redistribute just because they're old.

## Future: unified search / AI

Not built. The intended shape, so it's not designed into a corner:

```
UnifiedSearchService
        ↓
 ┌──────┼──────────┐
 ↓      ↓          ↓
Quran  Hadith    Turath
```

If an "اسأل الكتب" AI feature is ever built on top of this, the flow must stay `Flutter → Search/Repository layer → Turath → verified results → AI` — never `Flutter → AI → Turath` directly, and every AI answer must cite its real source (book/author/page), never inventing one. This matches the app's standing "لا AI حي يواجه الطالب" rule elsewhere in `CLAUDE.md`/`TODO.md`.
