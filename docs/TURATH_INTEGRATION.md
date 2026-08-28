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
- `lib/repositories/turath_repository.dart` — everything a screen actually calls: search, book/page fetch with cache fallback, favorites, last-read, notes.
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

## Search

Three real search surfaces, all going through the same `TurathRepository.search`:
1. **Library-wide** (`turath_library_screen.dart`) — free text, results are individual page snippets, tapping one jumps straight to that page.
2. **Topic browse** (`turath_topic_books_screen.dart`) — a curated Arabic subject term (العقيدة، التفسير، الحديث...) run as a real search, results **grouped and de-duplicated by book** into a book list. This is *not* turath.io's real category taxonomy — the public API has no endpoint to list categories, verified by reading the real `turath-sdk` source directly. Faking a category ID→name table would mean guessing IDs, which this project's discipline forbids. This is an honest substitute, not a hidden shortcut.
3. **In-book** (`turath_book_search_screen.dart`) — the same search scoped with `book_id`.

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
