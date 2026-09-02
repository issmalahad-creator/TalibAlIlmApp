# Turath PDF Download — offline books

Research + proposed architecture for downloading book PDFs from turath.io for
offline use. Phase `79-pdf` in `TODO.md`. **No code yet — awaiting Ismail's
approval of this design.**

## 1. Research (curl-verified against the real servers, 2026-08-29)

### How a PDF link is obtained
- **Not** a static, guessable URL. You must call `GET https://api.turath.io/book?id={id}&ver=3` and read `meta.pdf_links`:
  ```json
  "pdf_links": {
    "root": "shamela",
    "files": ["1/41557.pdf"]
  }
  ```
- `pdf_links` is `null` for books that have no PDF — **and the catalog's `has_pdf` flag is not reliable**: some books with `has_pdf` in `data-v3.json` return `pdf_links: null`. The real "can I download a PDF?" test is `meta.pdf_links != null && meta.pdf_links.files` non-empty, from `/book`.
- `root` is a folder path. It can be a bare word (`"shamela"`) or a long path with spaces and Arabic (`"شروح الحديث/فتح الباري ... 1-10"`).
- `files` is an array. Multi-volume books have several entries. Each entry is either `"name.pdf"` or `"name.pdf|<display label>"` (pipe splits file path from a human label; book 137 = cover + 10 volume PDFs; book 16521 = 33 labels over 2 physical files).

### The file URL
```
https://files.turath.io/pdf/{percent-encoded root}/{percent-encoded file}
```
- Encode each path segment (`Uri.encodeComponent` per segment, keep the `/` separators). Both `pdf/{root}/{file}` and, for the `shamela` root, `pdf/{file}` resolved — always use `pdf/{root}/{file}`.
- Verified `200 OK`, `Content-Type: application/pdf`, `Content-Length` present, for a single-file book and a multi-volume book.
- No API key, no auth, no cookie. A browser-like `User-Agent` is polite (the JSON API 403s bare bots on some paths).

### Resume / integrity / size
- **`Accept-Ranges: bytes`** on the PDF responses, and a `Range: bytes=0-99` request returned **`206 Partial Content`** with exactly 100 bytes → **HTTP Range resume is fully supported**.
- `Content-Length` gives the expected total per file. **No checksum/ETag hash is provided** — integrity check = (a) bytes received == `Content-Length`, (b) file starts with `%PDF-`, (c) file ends with `%%EOF` (within the last ~1KB).
- The catalog's `size` field is the **text** content size, not the PDF — do not use it for the PDF. Real PDF sizes seen: cover ~370 KB, one volume ~1.5 MB, large multi-volume works tens of MB. Plan for individual files up to ~100 MB and multi-volume sets of several hundred MB.

### Licensing / storage
- turath.io serves these openly; the Nuqayah "تراث" app itself offers PDF view/download. `root: "shamela"` → the PDFs come from **al-Maktaba al-Shamela**. Most are old classical texts (public-domain), but modern critical editions (tahqiq) carry publisher rights. This is the same caveat already in `docs/TURATH_INTEGRATION.md`.
- **Posture**: download for the user's **personal offline use inside this app only**. Do **not** expose the PDF file for share/export/"save to device" from our UI, do not bulk-mirror. Keep the turath.io attribution. A formal terms check with Nuqayah is advisable before shipping this feature publicly.
- Local storage: `getApplicationDocumentsDirectory()/turath_pdf/{bookId}/{index}.pdf` — inside the app sandbox, excluded from device gallery/media scan, removed on uninstall.

## 2. Proposed architecture — `PdfDownloadManager`

Layering unchanged: `Screen → TurathRepository → (TurathApiClient | PdfDownloadManager) → files.turath.io / SQLite`.

```
lib/services/pdf_download_manager.dart   -- queue, HTTP Range download, resume, integrity, cancel
lib/repositories/turath_repository.dart  -- pdfStatus(bookId), startPdfDownload(bookId), cancel, deletePdf, localPdfPaths(bookId)
migration v51: turath_pdf_files
```

### `turath_pdf_files` (one row per physical PDF file)
```sql
CREATE TABLE turath_pdf_files (
  book_id       INTEGER NOT NULL,
  file_index    INTEGER NOT NULL,          -- position in meta.pdf_links.files
  label         TEXT,                       -- the "|label" part, if any
  remote_url    TEXT NOT NULL,
  local_path    TEXT NOT NULL,
  bytes_total   INTEGER,                    -- Content-Length once known
  bytes_done    INTEGER NOT NULL DEFAULT 0,
  status        TEXT NOT NULL DEFAULT 'queued', -- queued|downloading|paused|done|error
  error         TEXT,
  updated_at    TEXT NOT NULL,
  PRIMARY KEY (book_id, file_index)
);
```
Book-level status is derived: `done` when every file row is `done`; otherwise the max progress across rows.

### Download flow
1. `startPdfDownload(bookId)` → fetch `/book?id=` (or reuse `turath_book_cache`), read `pdf_links`, build URLs, upsert a `turath_pdf_files` row per file (skip rows already `done` — **offline-first, never re-download**).
2. `PdfDownloadManager` processes one file at a time (serialized queue, same politeness as `TurathApiClient`):
   - `HEAD` (or first `GET`) → `bytes_total`.
   - if `local_path` exists with `bytes_done > 0` → `GET` with `Range: bytes={bytes_done}-`, append; else full `GET`, stream to a `.part` file.
   - update `bytes_done` every ~256 KB (throttled DB writes) so the UI shows live progress and a kill mid-download resumes cleanly.
   - on completion: verify `bytes_done == bytes_total`, `%PDF-` head, `%%EOF` tail → rename `.part` → `.pdf`, mark `done`. On mismatch → `error`, keep the `.part` for a retry.
3. Cancel → stop the stream, keep the `.part` (a later "resume" continues) or discard on explicit "delete".
4. `deletePdf(bookId)` → delete the files + rows; free space.

### UI (in `TurathBookScreen`)
- `pdf_links == null` → **no download control at all**.
- not downloaded → `📥 تحميل الكتاب PDF` (+ volume count if `files.length > 1`).
- downloading → `جاري التحميل  72%  ·  45 MB / 62 MB` + cancel; per-volume rows for multi-file.
- done → `✓ متاح بدون إنترنت` · `📖 فتح PDF` · `🗑 حذف التنزيل`.
- A "التنزيلات" screen lists all downloaded books with total disk use and per-book delete.

### Reader integration — kept separate
Text and PDF are **two independent reading modes** over the same book reference.
The PDF viewer (`📖 فتح PDF`) is its own screen (a Flutter PDF render package, TBD
at build time), opened from the book screen. It does **not** touch
`turath_annotations` / the text reader. Future idea (separate phase): a "النص ↔
صفحة PDF الأصلية" toggle so a student can check the printed page, footnotes, and
original page numbers — needs a text-page ↔ PDF-page mapping we don't have yet.

## 3. Risks

| # | risk | mitigation |
|---|---|---|
| P1 | huge multi-volume sets (100s of MB) fill storage | per-volume download + delete; a downloads screen with total size; warn above a threshold |
| P2 | no server checksum | Content-Length + `%PDF`/`%%EOF` structural check; `.part` until verified |
| P3 | `root`/`file` with spaces & Arabic | percent-encode each segment; verified working |
| P4 | licensing (modern tahqiq editions) | personal-offline only, no export/share of the file, attribution kept, terms check before public release |
| P5 | `has_pdf` unreliable | gate purely on `meta.pdf_links` from `/book` |
| P6 | connection drops mid-download | Range resume from `bytes_done`; `.part` survives an app kill |
| P7 | turath changes URL scheme | one `_pdfUrl(root, file)` builder; `pdf_links` already indirects through the API |
```
