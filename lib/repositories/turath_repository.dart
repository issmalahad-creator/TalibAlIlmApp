import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../data/turath_categories.dart';
import '../db/database_helper.dart';
import '../models/turath_models.dart';
import '../services/boot/boot_scheduler.dart';
import '../services/turath_api_client.dart';
import '../utils/month.dart';
import '../utils/study_annotation_anchor.dart';

/// Turns `TurathApiClient`'s raw responses into what the rest of the app
/// (Phase 79) actually needs — the layer Ismail's spec calls for so a
/// widget never talks to `TurathApiClient`/HTTP directly (item 3). Also
/// owns everything that's purely local -- favorites, last-read position,
/// notes, and the online-first/cache-fallback strategy (spec items 10-19)
/// -- so screens only ever depend on this one repository.
class TurathRepository {
  final TurathApiClient _client;
  TurathRepository({TurathApiClient? client}) : _client = client ?? TurathApiClient();

  Future<TurathSearchResults> search(String query, {int? categoryId, int? bookId, int? authorId, int? page}) =>
      _client.search(query, categoryId: categoryId, bookId: bookId, authorId: authorId, page: page);

  Future<TurathAuthor> getAuthor(int authorId) => _client.getAuthor(authorId);

  // ---------- Canonical catalog (Phase 79 `79-membership-index`) ----------
  //
  // Category membership and book counts come from the local catalog tables
  // (`turath_catalog_*`, seeded by `TurathCatalogSync` from turath.io's own
  // `data-v3.json` manifest) — NEVER from counting `search` results. When
  // the catalog hasn't been seeded yet (asset missing on a dev machine,
  // first-ever launch mid-import), these fall back to the static
  // `turathCategories` snapshot so the UI still renders the 40 categories.

  /// True once the local catalog has been populated at least once.
  /// Catalog tables are seeded by a deferred boot task; on a first launch the
  /// library may be opened before it ran — run it now instead of showing an
  /// empty catalog (docs/architecture/ZERO_WAIT_PROGRESSIVE_ARCHITECTURE.md §5).
  Future<Database> _catalogDb() async {
    await BootScheduler.instance.ensure(BootTasks.turathCatalog);
    return DatabaseHelper.instance.database;
  }

  Future<bool> hasCatalog() async {
    final db = await _catalogDb();
    final n = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM turath_catalog_categories')) ?? 0;
    return n > 0;
  }

  /// All 40 categories in display order, each with its authoritative
  /// `total_books`. Falls back to the static snapshot if the catalog is
  /// empty.
  Future<List<TurathCategory>> categories() async {
    final db = await _catalogDb();
    final rows = await db.query('turath_catalog_categories', orderBy: 'sort_order ASC');
    if (rows.isEmpty) {
      return turathCategories
          .map((c) => TurathCategory(catId: c.catId, name: c.name, totalBooks: c.bookCountSnapshot))
          .toList();
    }
    return rows
        .map((r) => TurathCategory(
              catId: r['cat_id'] as int,
              name: r['name_ar'] as String,
              totalBooks: r['total_books'] as int,
            ))
        .toList();
  }

  /// The exact number of books in a category — read directly from the
  /// membership index, cross-checked against the join table. Stable no
  /// matter how far the user has scrolled, what they've searched, or
  /// whether the PDF filter is on.
  Future<int> categoryBookCount(int catId) async {
    final db = await _catalogDb();
    final stored = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT total_books FROM turath_catalog_categories WHERE cat_id = ?',
      [catId],
    ));
    if (stored != null) return stored;
    final snap = turathCategories.where((c) => c.catId == catId);
    return snap.isEmpty ? 0 : snap.first.bookCountSnapshot;
  }

  /// How many of a category's books have a PDF — only for the "PDF only"
  /// view's "N / total" label. Deliberately separate from
  /// [categoryBookCount], which is the canonical, filter-independent count.
  Future<int> categoryPdfBookCount(int catId) async {
    final db = await _catalogDb();
    return Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*)
      FROM turath_catalog_category_books cb
      JOIN turath_catalog_books b ON b.book_id = cb.book_id
      WHERE cb.cat_id = ? AND b.has_pdf = 1
    ''', [catId])) ?? 0;
  }

  /// One page of a category's books, resolved through the explicit
  /// `turath_catalog_category_books` membership relation (not
  /// `turath_catalog_books.cat_id`) so multi-category membership needs no
  /// query change later. Deterministic order (`name`, then `book_id` as a
  /// tie-breaker) so paging with OFFSET never repeats or skips a row.
  /// [pdfOnly] narrows the *view* to books with a PDF; it never changes
  /// [categoryBookCount].
  Future<List<TurathCatalogBook>> booksInCategory(
    int catId, {
    int limit = 30,
    int offset = 0,
    bool pdfOnly = false,
  }) async {
    final db = await _catalogDb();
    final rows = await db.rawQuery('''
      SELECT b.book_id, b.name, b.author_id, b.cat_id, b.has_pdf, b.page_count,
             COALESCE(a.name, '') AS author_name
      FROM turath_catalog_category_books cb
      JOIN turath_catalog_books b ON b.book_id = cb.book_id
      LEFT JOIN turath_catalog_authors a ON a.author_id = b.author_id
      WHERE cb.cat_id = ?${pdfOnly ? ' AND b.has_pdf = 1' : ''}
      ORDER BY b.name ASC, b.book_id ASC
      LIMIT ? OFFSET ?
    ''', [catId, limit, offset]);
    return rows.map(_rowToCatalogBook).toList();
  }

  /// The set of book ids that belong to a category (the raw membership).
  Future<Set<int>> categoryMemberIds(int catId) async {
    final db = await _catalogDb();
    final rows = await db.query(
      'turath_catalog_category_books',
      columns: ['book_id'],
      where: 'cat_id = ?',
      whereArgs: [catId],
    );
    return {for (final r in rows) r['book_id'] as int};
  }

  /// Full-text search scoped to ONE category. Two layers: the API's `cat_id`
  /// filter narrows server-side, and the results are then intersected with
  /// the local membership set so a book from another category can never leak
  /// in. Search consumes membership here — it never defines it. (Global
  /// search stays separate: plain [search] with no `categoryId`, over the
  /// whole library.)
  Future<List<TurathSearchResult>> searchInCategory(String query, int catId, {int? page}) async {
    final res = await _client.search(query, categoryId: catId, page: page);
    final ids = await categoryMemberIds(catId);
    if (ids.isEmpty) return res.results; // catalog not seeded yet — fall back to the server-side cat_id filter alone
    return res.results.where((r) => ids.contains(r.bookId)).toList();
  }

  /// Catalog authors, most-published first, optionally filtered by an
  /// infix name match. `bookCount` is the number of their books in the
  /// library (from the real books table, not a stored guess).
  Future<List<TurathCatalogAuthor>> catalogAuthors({int limit = 40, int offset = 0, String? query}) async {
    final db = await _catalogDb();
    final q = (query ?? '').trim();
    final where = q.isEmpty ? '' : 'WHERE a.name LIKE ?';
    final args = <Object?>[if (q.isNotEmpty) '%$q%', limit, offset];
    final rows = await db.rawQuery('''
      SELECT a.author_id, a.name, a.death_year,
             (SELECT COUNT(*) FROM turath_catalog_books b WHERE b.author_id = a.author_id) AS book_count
      FROM turath_catalog_authors a
      $where
      ORDER BY book_count DESC, a.name ASC
      LIMIT ? OFFSET ?
    ''', args);
    return rows
        .map((r) => TurathCatalogAuthor(
              authorId: r['author_id'] as int,
              name: r['name'] as String,
              deathYear: r['death_year'] as int?,
              bookCount: r['book_count'] as int? ?? 0,
            ))
        .toList();
  }

  /// Every book by one author, from the catalog.
  Future<List<TurathCatalogBook>> booksByAuthor(int authorId) async {
    final db = await _catalogDb();
    final rows = await db.rawQuery('''
      SELECT b.book_id, b.name, b.author_id, b.cat_id, b.has_pdf, b.page_count,
             COALESCE(a.name, '') AS author_name
      FROM turath_catalog_books b
      LEFT JOIN turath_catalog_authors a ON a.author_id = b.author_id
      WHERE b.author_id = ?
      ORDER BY b.name ASC, b.book_id ASC
    ''', [authorId]);
    return rows.map(_rowToCatalogBook).toList();
  }

  /// Catalog metadata a book detail screen can show without a network call.
  Future<TurathCatalogBook?> catalogBook(int bookId) async {
    final db = await _catalogDb();
    final rows = await db.rawQuery('''
      SELECT b.book_id, b.name, b.author_id, b.cat_id, b.has_pdf, b.page_count,
             COALESCE(a.name, '') AS author_name
      FROM turath_catalog_books b
      LEFT JOIN turath_catalog_authors a ON a.author_id = b.author_id
      WHERE b.book_id = ?
      LIMIT 1
    ''', [bookId]);
    return rows.isEmpty ? null : _rowToCatalogBook(rows.first);
  }

  TurathCatalogBook _rowToCatalogBook(Map<String, Object?> r) => TurathCatalogBook(
        bookId: r['book_id'] as int,
        name: r['name'] as String,
        authorId: r['author_id'] as int?,
        authorName: r['author_name'] as String? ?? '',
        catId: r['cat_id'] as int? ?? 0,
        hasPdf: (r['has_pdf'] as int? ?? 0) == 1,
        pageCount: r['page_count'] as int?,
      );

  // ---------- Study annotations (Phase 79 «علامات الدراسة») ----------
  //
  // `docs/STUDY_ANNOTATIONS_DESIGN.md`. `selectedText` is stored in FULL,
  // verbatim, whatever its length — never a first-word fragment. The anchor
  // locator fields are derived by `captureAnchor` from the same normalised
  // page text the reader displays; `resolveAnchor` re-finds the range later.

  /// Save a new highlight over `[charStart, charEnd)` of [normalizedPageText]
  /// (which must be `normalizePageText(page.text)` — the exact string the
  /// reader renders). [selectedText] is the AUTHORITATIVE full text the user
  /// selected — stored verbatim, whatever its length or whitespace.
  /// [charStartHint] is where the reader thinks the selection began; the
  /// real offsets are confirmed against, or re-derived from, [selectedText]
  /// so a hint that's slightly off (or points at the wrong occurrence) can
  /// never truncate the stored text. Returns the new row id.
  Future<int> addAnnotation({
    required int bookId,
    required int pageNumber,
    String? volume,
    required String normalizedPageText,
    required String selectedText,
    int? charStartHint,
    required String colorKey,
    String? noteType,
    String? noteBody,
    required String bookName,
    String? authorName,
    String? spanGroupId,
  }) async {
    final now = todayDate();
    final db = await DatabaseHelper.instance.database;
    return db.insert('turath_annotations', {
      'span_group_id': spanGroupId,
      'book_id': bookId,
      'page_number': pageNumber,
      'volume': volume,
      'color_key': colorKey,
      'note_type': noteType,
      'note_body': (noteBody ?? '').trim().isEmpty ? null : noteBody!.trim(),
      'source_kind': 'annotation',
      'book_name': bookName,
      'author_name': authorName,
      'created_at': now,
      'updated_at': now,
      ..._anchorFields(normalizedPageText, selectedText, charStartHint),
    });
  }

  /// A **page note** — a coloured note attached to a whole page, not to a
  /// text span. The durable alternative to highlighting (Ismail: «إن تعذّر
  /// التضليل... البديل ملاحظات تُرفق للصفحة بالألوان، نفس فكرة التظليل لكن
  /// للصفحة ككل»). Stored in the same `turath_annotations` table with no
  /// anchor columns and `source_kind = 'page_note'`, so it already flows
  /// through the unified notebook, the page-marks bar, and every colour
  /// filter with zero migration.
  Future<int> addPageNote({
    required int bookId,
    required int pageNumber,
    String? volume,
    required String colorKey,
    String? noteBody,
    required String bookName,
    String? authorName,
  }) async {
    final now = todayDate();
    final db = await DatabaseHelper.instance.database;
    return db.insert('turath_annotations', {
      'book_id': bookId,
      'page_number': pageNumber,
      'volume': volume,
      'selected_text': null,
      'selected_len': 0,
      'char_start': null,
      'char_end': null,
      'norm_version': kNormVersion,
      'anchor_status': 'page',
      'color_key': colorKey,
      'note_type': colorKey,
      'note_body': (noteBody ?? '').trim().isEmpty ? null : noteBody!.trim(),
      'source_kind': 'page_note',
      'book_name': bookName,
      'author_name': authorName,
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Every page note on a given page, newest first.
  Future<List<StudyAnnotation>> pageNotesForPage(int bookId, int pageNumber) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'turath_annotations',
      where: "book_id = ? AND page_number = ? AND source_kind = 'page_note'",
      whereArgs: [bookId, pageNumber],
      orderBy: 'updated_at DESC, id DESC',
    );
    return rows.map(StudyAnnotation.fromRow).toList();
  }

  /// Change which text an existing highlight covers (Ismail: "التعديل في
  /// حجم التظليل"). Same authoritative-string rule as [addAnnotation].
  Future<void> updateAnnotationRange(
    int id, {
    required String normalizedPageText,
    required String selectedText,
    int? charStartHint,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'turath_annotations',
      {'updated_at': todayDate(), ..._anchorFields(normalizedPageText, selectedText, charStartHint)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Store [selectedText] verbatim and work out where it sits in [text].
  /// The hint is trusted only if the slice it points at is byte-for-byte
  /// [selectedText]; otherwise the string is located by search (nearest
  /// occurrence to the hint when it repeats). If it genuinely can't be
  /// found the text is still stored, just `unanchored` — the resolver will
  /// place it on the next page visit.
  Map<String, Object?> _anchorFields(String text, String selectedText, int? charStartHint) {
    final sel = selectedText;
    var start = -1;
    if (sel.isNotEmpty) {
      if (charStartHint != null &&
          charStartHint >= 0 &&
          charStartHint + sel.length <= text.length &&
          text.substring(charStartHint, charStartHint + sel.length) == sel) {
        start = charStartHint;
      } else {
        var i = text.indexOf(sel);
        start = i;
        if (i >= 0 && charStartHint != null) {
          while (i != -1) {
            if ((i - charStartHint).abs() < (start - charStartHint).abs()) start = i;
            i = text.indexOf(sel, i + 1);
          }
        }
      }
    }
    final anchored = start >= 0 && sel.isNotEmpty;
    final cap = anchored ? captureAnchor(text, start, start + sel.length) : null;
    return {
      'selected_text': sel,
      'selected_len': sel.length,
      'char_start': anchored ? start : null,
      'char_end': anchored ? start + sel.length : null,
      'norm_version': cap?.normVersion ?? 0,
      'text_checksum': cap?.textChecksum,
      'text_length': cap?.textLength,
      'prefix_context': cap?.prefixContext,
      'suffix_context': cap?.suffixContext,
      'head_anchor': cap?.headAnchor,
      'tail_anchor': cap?.tailAnchor,
      'occurrence_index': cap?.occurrenceIndex ?? 0,
      'anchor_status': anchored ? 'exact' : 'unanchored',
    };
  }

  Future<void> updateAnnotationNote(int id, {String? noteType, String? noteBody}) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'turath_annotations',
      {
        'note_type': noteType,
        'note_body': (noteBody ?? '').trim().isEmpty ? null : noteBody!.trim(),
        'updated_at': todayDate(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> recolorAnnotation(int id, String colorKey) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('turath_annotations', {'color_key': colorKey, 'updated_at': todayDate()}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAnnotation(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('turath_annotations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<StudyAnnotation>> annotationsForPage(int bookId, int pageNumber) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'turath_annotations',
      where: 'book_id = ? AND page_number = ?',
      whereArgs: [bookId, pageNumber],
      orderBy: 'COALESCE(char_start, 0) ASC, id ASC',
    );
    return rows.map(StudyAnnotation.fromRow).toList();
  }

  /// Annotations for a page, each re-anchored against [normalizedPageText]
  /// (which MUST be `normalizePageText(page.text)` — the exact string the
  /// reader renders). A resolution that moved the offsets or changed the
  /// status is persisted, so the next visit takes the O(1) exact path.
  Future<List<ResolvedAnnotation>> resolvedAnnotationsForPage(
    int bookId,
    int pageNumber,
    String normalizedPageText,
  ) async {
    final anns = await annotationsForPage(bookId, pageNumber);
    if (anns.isEmpty) return const [];
    final checksum = pageChecksum(normalizedPageText);
    final out = <ResolvedAnnotation>[];
    for (final a in anns) {
      // Page notes have no text span — never re-anchor them (it would flip
      // their status to "orphan" and churn a write every page load).
      if (a.sourceKind == 'page_note' || a.isPageLevel) {
        out.add(ResolvedAnnotation(a, const ResolvedAnchor(AnchorStatus.orphan, null, null)));
        continue;
      }
      final resolved = resolveAnchor(normalizedPageText, _storedAnchorOf(a));
      final moved = resolved.start != a.charStart || resolved.end != a.charEnd;
      final statusChanged = resolved.status.name != a.anchorStatus;
      final pageMoved = a.textChecksum != checksum || a.normVersion != kNormVersion;
      if (moved || statusChanged || pageMoved) {
        await saveResolvedAnchor(a.id, resolved, normalizedPageText: normalizedPageText);
      }
      out.add(ResolvedAnnotation(a, resolved));
    }
    return out;
  }

  StoredAnchor _storedAnchorOf(StudyAnnotation a) => StoredAnchor(
        selectedText: a.selectedText,
        charStart: a.charStart,
        charEnd: a.charEnd,
        normVersion: a.normVersion,
        textChecksum: a.textChecksum,
        textLength: a.textLength,
        prefixContext: a.prefixContext,
        suffixContext: a.suffixContext,
        headAnchor: a.headAnchor,
        tailAnchor: a.tailAnchor,
        occurrenceIndex: a.occurrenceIndex,
      );

  /// Persist the outcome of re-anchoring a stored annotation against a
  /// freshly loaded page, so the next visit takes the O(1) exact path.
  Future<void> saveResolvedAnchor(
    int id,
    ResolvedAnchor resolved, {
    required String normalizedPageText,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'turath_annotations',
      {
        'anchor_status': resolved.status.name,
        'char_start': resolved.start,
        'char_end': resolved.end,
        'norm_version': kNormVersion,
        'text_checksum': pageChecksum(normalizedPageText),
        'text_length': normalizedPageText.length,
        'updated_at': todayDate(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// The notebook query. Filter by any combination of colour keys, one
  /// book, one category (joins the catalog), and a free-text term over the
  /// note body + selected text.
  Future<List<StudyAnnotation>> allAnnotations({
    List<String>? colorKeys,
    int? bookId,
    int? catId,
    String? query,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final where = <String>[];
    final args = <Object?>[];

    if (colorKeys != null && colorKeys.isNotEmpty) {
      where.add('a.color_key IN (${List.filled(colorKeys.length, '?').join(',')})');
      args.addAll(colorKeys);
    }
    if (bookId != null) {
      where.add('a.book_id = ?');
      args.add(bookId);
    }
    if (catId != null) {
      where.add('a.book_id IN (SELECT book_id FROM turath_catalog_category_books WHERE cat_id = ?)');
      args.add(catId);
    }
    final q = (query ?? '').trim();
    if (q.isNotEmpty) {
      where.add('(a.note_body LIKE ? OR a.selected_text LIKE ?)');
      args
        ..add('%$q%')
        ..add('%$q%');
    }

    final rows = await db.rawQuery('''
      SELECT a.* FROM turath_annotations a
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY a.updated_at DESC, a.id DESC
      LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);
    return rows.map(StudyAnnotation.fromRow).toList();
  }

  Future<int> annotationCountForBook(int bookId) async {
    final db = await DatabaseHelper.instance.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM turath_annotations WHERE book_id = ?', [bookId]),
        ) ??
        0;
  }

  /// `{page → colour_key}` for every page of [bookId] that has at least one
  /// highlight or page note — used to mark those pages in the index. The
  /// colour is the most-recently-touched annotation's, just for the dot.
  Future<Map<int, String>> annotatedPagesForBook(int bookId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT page_number, color_key FROM turath_annotations '
      'WHERE book_id = ? ORDER BY updated_at ASC',
      [bookId],
    );
    return {
      for (final r in rows) (r['page_number'] as int): (r['color_key'] as String? ?? 'benefit'),
    };
  }

  /// The unified notebook (Phase 79 `79-sa-D`) — every study annotation as a
  /// read-only row joined to its book's category. `turath_annotations` stays
  /// the single source of truth; this copies nothing. Filter by any mix of
  /// colour keys, one book, one category, and a free-text term over the note
  /// body + selected text.
  Future<List<NotebookEntry>> notebookEntries({
    List<String>? colorKeys,
    int? bookId,
    int? catId,
    String? query,
    int limit = 300,
    int offset = 0,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final where = <String>[];
    final args = <Object?>[];
    if (colorKeys != null && colorKeys.isNotEmpty) {
      where.add('a.color_key IN (${List.filled(colorKeys.length, '?').join(',')})');
      args.addAll(colorKeys);
    }
    if (bookId != null) {
      where.add('a.book_id = ?');
      args.add(bookId);
    }
    if (catId != null) {
      where.add('cb.cat_id = ?');
      args.add(catId);
    }
    final q = (query ?? '').trim();
    if (q.isNotEmpty) {
      where.add('(a.note_body LIKE ? OR a.selected_text LIKE ?)');
      args
        ..add('%$q%')
        ..add('%$q%');
    }
    // Each book sits in exactly one category (clean partition), so this
    // LEFT JOIN never multiplies rows; it just returns NULLs when the
    // catalog hasn't been seeded.
    final rows = await db.rawQuery('''
      SELECT a.*, cb.cat_id AS _cat_id, c.name_ar AS _cat_name
      FROM turath_annotations a
      LEFT JOIN turath_catalog_category_books cb ON cb.book_id = a.book_id
      LEFT JOIN turath_catalog_categories c ON c.cat_id = cb.cat_id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY a.updated_at DESC, a.id DESC
      LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);
    return rows
        .map((r) => NotebookEntry(
              StudyAnnotation.fromRow(r),
              catId: r['_cat_id'] as int?,
              categoryName: r['_cat_name'] as String?,
            ))
        .toList();
  }

  /// One annotation by id (for a notebook → reader deep-link).
  Future<StudyAnnotation?> annotationById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_annotations', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : StudyAnnotation.fromRow(rows.first);
  }

  /// A plain, deterministic aggregation of the study annotations for the
  /// "خريطة الفوائد" screen (`79-sa-E`). No AI — just `GROUP BY` / `COUNT`.
  Future<StudyAnnotationStats> annotationStats() async {
    final db = await DatabaseHelper.instance.database;
    final total = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM turath_annotations')) ?? 0;
    final withNote = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM turath_annotations WHERE note_body IS NOT NULL AND TRIM(note_body) <> ''"),
        ) ??
        0;
    final orphans = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM turath_annotations WHERE anchor_status = 'orphan'"),
        ) ??
        0;
    final byColor = {
      for (final r in await db.rawQuery('SELECT color_key, COUNT(*) c FROM turath_annotations GROUP BY color_key'))
        r['color_key'] as String: r['c'] as int,
    };
    final byBook = await db.rawQuery('''
      SELECT book_id, book_name, COUNT(*) c
      FROM turath_annotations GROUP BY book_id, book_name ORDER BY c DESC, book_name ASC
    ''');
    final byCategory = await db.rawQuery('''
      SELECT c.name_ar name, COUNT(*) c
      FROM turath_annotations a
      JOIN turath_catalog_category_books cb ON cb.book_id = a.book_id
      JOIN turath_catalog_categories c ON c.cat_id = cb.cat_id
      GROUP BY c.cat_id ORDER BY c DESC
    ''');
    final byAuthor = await db.rawQuery('''
      SELECT COALESCE(NULLIF(TRIM(author_name), ''), '؟') name, COUNT(*) c
      FROM turath_annotations GROUP BY name ORDER BY c DESC
    ''');
    return StudyAnnotationStats(
      total: total,
      withNote: withNote,
      orphans: orphans,
      byColor: byColor,
      byBook: [for (final r in byBook) (id: r['book_id'] as int, name: r['book_name'] as String? ?? '', count: r['c'] as int)],
      byCategory: [for (final r in byCategory) (name: r['name'] as String? ?? '', count: r['c'] as int)],
      byAuthor: [for (final r in byAuthor) (name: r['name'] as String? ?? '؟', count: r['c'] as int)],
    );
  }

  /// A plain-text digest of study annotations, grouped by book, each with
  /// its quote + note + citation. For "تصدير" via the OS share sheet — no
  /// file, no AI, nothing generated.
  Future<String> annotationsDigest({int? bookId, int? catId, List<String>? colorKeys}) async {
    final entries = await notebookEntries(bookId: bookId, catId: catId, colorKeys: colorKeys, limit: 100000);
    if (entries.isEmpty) return '';
    entries.sort((x, y) {
      final b = x.annotation.bookName.compareTo(y.annotation.bookName);
      if (b != 0) return b;
      final p = x.annotation.pageNumber.compareTo(y.annotation.pageNumber);
      return p != 0 ? p : x.annotation.id.compareTo(y.annotation.id);
    });
    final buf = StringBuffer();
    String? currentBook;
    for (final e in entries) {
      final a = e.annotation;
      if (a.bookName != currentBook) {
        currentBook = a.bookName;
        buf.writeln('\n=== ${a.bookName}${(a.authorName ?? '').isNotEmpty ? ' — ${a.authorName}' : ''} ===');
      }
      final cite = ['ص ${a.pageNumber}', if ((a.volume ?? '').isNotEmpty) 'ج ${a.volume}', if ((e.categoryName ?? '').isNotEmpty) e.categoryName!].join(' · ');
      if (!a.isPageLevel) buf.writeln('«${a.selectedText}»');
      if (a.hasNote) buf.writeln('— ${a.noteBody}');
      buf.writeln('[$cite]');
      buf.writeln();
    }
    buf.writeln('— ${entries.length} فائدة، من مكتبة turath.io');
    return buf.toString().trim();
  }

  /// Online-first: always tries the real network call so the student sees
  /// current data. Only falls back to the local cache (spec items 15/17,
  /// "Online-first + Smart cache + Offline-ready") when the network call
  /// itself fails -- e.g. no connection -- and only for a book/page this
  /// student has actually visited before, never the whole library.
  Future<TurathBook> getBookInfo(int bookId) async {
    try {
      final book = await _client.getBookInfo(bookId);
      await _cacheBook(book);
      return book;
    } catch (e) {
      final cached = await _cachedBook(bookId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<TurathPage> getPage(int bookId, int pageNumber) async {
    try {
      final page = await _client.getPage(bookId, pageNumber);
      await _cachePage(page);
      return page;
    } catch (e) {
      final cached = await _cachedPage(bookId, pageNumber);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> _cacheBook(TurathBook book) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('turath_book_cache', {
      'book_id': book.id,
      'name': book.name,
      'info': book.info,
      'volumes_json': jsonEncode(book.volumes),
      'indexes_json': jsonEncode(book.indexes.map((e) => {'title': e.title, 'page': e.page, 'level': e.level}).toList()),
      'cached_at': todayDate(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<TurathBook?> _cachedBook(int bookId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_book_cache', where: 'book_id = ?', whereArgs: [bookId], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final indexesRaw = jsonDecode(r['indexes_json'] as String) as List;
    return TurathBook(
      id: bookId,
      name: r['name'] as String,
      info: r['info'] as String?,
      volumes: (jsonDecode(r['volumes_json'] as String) as List).map((v) => v.toString()).toList(),
      indexes: indexesRaw
          .map((e) => TurathIndexEntry(title: (e as Map)['title'] as String, page: e['page'] as int, level: e['level'] as int))
          .toList(),
    );
  }

  Future<void> _cachePage(TurathPage page) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('turath_page_cache', {
      'book_id': page.bookId,
      'page_number': page.pageNumber,
      'volume': page.volume,
      'text': page.text,
      'headings_json': jsonEncode(page.headings),
      'cached_at': todayDate(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<TurathPage?> _cachedPage(int bookId, int pageNumber) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_page_cache', where: 'book_id = ? AND page_number = ?', whereArgs: [bookId, pageNumber], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return TurathPage(
      bookId: bookId,
      pageNumber: pageNumber,
      volume: r['volume'] as String,
      text: r['text'] as String,
      headings: (jsonDecode(r['headings_json'] as String) as List).map((h) => h.toString()).toList(),
    );
  }

  // -------------------- Favorites (spec item 10) --------------------

  Future<bool> isFavoriteBook(int bookId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_favorites', where: 'type = ? AND book_id = ? AND page_number IS NULL', whereArgs: ['book', bookId], limit: 1);
    return rows.isNotEmpty;
  }

  Future<bool> isFavoritePage(int bookId, int pageNumber) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_favorites', where: 'type = ? AND book_id = ? AND page_number = ?', whereArgs: ['page', bookId, pageNumber], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> toggleFavoriteBook(int bookId, String bookName) async {
    final db = await DatabaseHelper.instance.database;
    if (await isFavoriteBook(bookId)) {
      await db.delete('turath_favorites', where: 'type = ? AND book_id = ? AND page_number IS NULL', whereArgs: ['book', bookId]);
    } else {
      await db.insert('turath_favorites', {'type': 'book', 'book_id': bookId, 'book_name': bookName, 'page_number': null, 'created_at': todayDate()});
    }
  }

  Future<void> toggleFavoritePage(int bookId, String bookName, int pageNumber) async {
    final db = await DatabaseHelper.instance.database;
    if (await isFavoritePage(bookId, pageNumber)) {
      await db.delete('turath_favorites', where: 'type = ? AND book_id = ? AND page_number = ?', whereArgs: ['page', bookId, pageNumber]);
    } else {
      await db.insert('turath_favorites', {'type': 'page', 'book_id': bookId, 'book_name': bookName, 'page_number': pageNumber, 'created_at': todayDate()});
    }
  }

  Future<List<TurathFavorite>> favorites() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_favorites', orderBy: 'id DESC');
    return rows
        .map((r) => TurathFavorite(
              id: r['id'] as int,
              bookId: r['book_id'] as int,
              bookName: r['book_name'] as String,
              pageNumber: r['page_number'] as int?,
              createdAt: r['created_at'] as String,
            ))
        .toList();
  }

  // -------------------- Last-read position (spec item 11) --------------------

  Future<void> saveLastRead(int bookId, String bookName, int pageNumber) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'turath_last_read',
      {'book_id': bookId, 'book_name': bookName, 'page_number': pageNumber, 'updated_at': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TurathLastRead?> lastRead(int bookId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_last_read', where: 'book_id = ?', whereArgs: [bookId], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return TurathLastRead(bookId: bookId, bookName: r['book_name'] as String, pageNumber: r['page_number'] as int, updatedAt: r['updated_at'] as String);
  }

  /// Every book with a saved reading position, most recently read first --
  /// the real data behind a "متابعة القراءة" / recently-read list.
  Future<List<TurathLastRead>> recentlyRead({int limit = 20}) async {
    final db = await DatabaseHelper.instance.database;
    // `turath_last_read` has no autoincrement id -- `book_id` is the
    // primary key (one row per book, overwritten as reading progresses) --
    // so ordering is by `updated_at` (a Hijri date string, zero-padded so
    // string order == chronological order, day granularity).
    final rows = await db.query('turath_last_read', orderBy: 'updated_at DESC', limit: limit);
    return rows
        .map((r) => TurathLastRead(bookId: r['book_id'] as int, bookName: r['book_name'] as String, pageNumber: r['page_number'] as int, updatedAt: r['updated_at'] as String))
        .toList();
  }

  // -------------------- Personal notes (spec item 12) --------------------

  Future<int> addNote({required int bookId, required String bookName, required int pageNumber, String? selectedText, required String note}) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('turath_notes', {
      'book_id': bookId,
      'book_name': bookName,
      'page_number': pageNumber,
      'selected_text': selectedText,
      'note': note,
      'created_at': todayDate(),
    });
  }

  Future<void> deleteNote(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('turath_notes', where: 'id = ?', whereArgs: [id]);
  }

  /// Ismail 2026-08-29: "اريد في الملاحضات التعديل" -- editing a note in
  /// place instead of delete-then-recreate (which would lose its real
  /// `created_at`/id and reorder it in every list).
  Future<void> updateNote(int id, String newText) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('turath_notes', {'note': newText}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TurathNote>> notesForPage(int bookId, int pageNumber) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_notes', where: 'book_id = ? AND page_number = ?', whereArgs: [bookId, pageNumber], orderBy: 'id DESC');
    return _rowsToNotes(rows);
  }

  Future<List<TurathNote>> allNotes() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_notes', orderBy: 'id DESC');
    return _rowsToNotes(rows);
  }

  List<TurathNote> _rowsToNotes(List<Map<String, Object?>> rows) => rows
      .map((r) => TurathNote(
            id: r['id'] as int,
            bookId: r['book_id'] as int,
            bookName: r['book_name'] as String,
            pageNumber: r['page_number'] as int,
            selectedText: r['selected_text'] as String?,
            note: r['note'] as String,
            createdAt: r['created_at'] as String,
          ))
      .toList();

  // -------------------- Quotes (spec item 10) --------------------

  Future<int> addQuote({
    required int bookId,
    required String bookName,
    String? authorName,
    String? volume,
    required int pageNumber,
    required String quotedText,
    String? note,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('turath_quotes', {
      'book_id': bookId,
      'book_name': bookName,
      'author_name': authorName,
      'volume': volume,
      'page_number': pageNumber,
      'quoted_text': quotedText,
      'note': note,
      'created_at': todayDate(),
    });
  }

  Future<void> deleteQuote(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('turath_quotes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TurathQuote>> allQuotes() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_quotes', orderBy: 'id DESC');
    return rows
        .map((r) => TurathQuote(
              id: r['id'] as int,
              bookId: r['book_id'] as int,
              bookName: r['book_name'] as String,
              authorName: r['author_name'] as String?,
              volume: r['volume'] as String?,
              pageNumber: r['page_number'] as int,
              quotedText: r['quoted_text'] as String,
              note: r['note'] as String?,
              createdAt: r['created_at'] as String,
            ))
        .toList();
  }

  // -------------------- Benefits (spec item 14) --------------------

  Future<int> addBenefit({
    required String text,
    String? topic,
    int? sourceBookId,
    String? sourceBookName,
    int? sourcePageNumber,
    int? sourceQuoteId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('turath_benefits', {
      'text': text,
      'topic': topic,
      'source_book_id': sourceBookId,
      'source_book_name': sourceBookName,
      'source_page_number': sourcePageNumber,
      'source_quote_id': sourceQuoteId,
      'created_at': todayDate(),
    });
  }

  Future<void> deleteBenefit(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('turath_benefits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateBenefit(int id, String newText) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('turath_benefits', {'text': newText}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TurathBenefit>> allBenefits() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('turath_benefits', orderBy: 'id DESC');
    return rows
        .map((r) => TurathBenefit(
              id: r['id'] as int,
              text: r['text'] as String,
              topic: r['topic'] as String?,
              sourceBookId: r['source_book_id'] as int?,
              sourceBookName: r['source_book_name'] as String?,
              sourcePageNumber: r['source_page_number'] as int?,
              sourceQuoteId: r['source_quote_id'] as int?,
              createdAt: r['created_at'] as String,
            ))
        .toList();
  }
}
