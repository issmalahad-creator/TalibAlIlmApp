/// Real, verified models for turath.io's public API (Phase 79,
/// `TODO.md`). Every field here maps to a real response observed live on
/// 2026-08-27 against `api.turath.io` — none of this is guessed from the
/// SDK's docs alone. Deliberately separate from any UI widget (Ismail's
/// explicit instruction 33: "لا تربط Models الخاصة بـTurath مباشرة بواجهة
/// المستخدم") so a later API change only touches `TurathApiClient`.
library;

import '../utils/study_annotation_anchor.dart';

class TurathSearchResult {
  final int bookId;
  final int catId;
  final int authorId;
  final String bookName;
  final String authorName;
  final int page;
  final String volume;
  final List<String> headings;
  final String snippet;
  const TurathSearchResult({
    required this.bookId,
    required this.catId,
    required this.authorId,
    required this.bookName,
    required this.authorName,
    required this.page,
    required this.volume,
    required this.headings,
    required this.snippet,
  });

  factory TurathSearchResult.fromJson(Map<String, dynamic> json, Map<String, dynamic> meta) {
    return TurathSearchResult(
      bookId: json['book_id'] as int,
      catId: json['cat_id'] as int,
      authorId: json['author_id'] as int,
      bookName: meta['book_name'] as String? ?? '',
      authorName: meta['author_name'] as String? ?? '',
      page: meta['page'] as int? ?? 0,
      volume: meta['vol']?.toString() ?? '',
      headings: (meta['headings'] as List?)?.map((h) => h.toString()).toList() ?? [],
      snippet: json['snip'] as String? ?? '',
    );
  }
}

class TurathSearchResults {
  final int count;
  final List<TurathSearchResult> results;
  const TurathSearchResults({required this.count, required this.results});
}

class TurathBook {
  final int id;
  final String name;
  final String? info;
  final List<String> volumes;
  final List<TurathIndexEntry> indexes;
  const TurathBook({required this.id, required this.name, this.info, required this.volumes, required this.indexes});

  /// Real response shape confirmed live 2026-08-27 against book 137:
  /// `{ meta: {...}, indexes: { volumes: [...], headings: [{title, level, page}] } }`.
  factory TurathBook.fromJson(int id, Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final indexesJson = json['indexes'] as Map<String, dynamic>? ?? {};
    final headings = (indexesJson['headings'] as List?) ?? [];
    return TurathBook(
      id: id,
      name: meta['name'] as String? ?? '',
      info: meta['info'] as String?,
      volumes: ((indexesJson['volumes'] as List?) ?? []).map((v) => v.toString()).toList(),
      indexes: headings
          .map((h) => TurathIndexEntry(
                title: (h as Map<String, dynamic>)['title'] as String? ?? '',
                page: h['page'] as int? ?? 0,
                level: h['level'] as int? ?? 1,
              ))
          .toList(),
    );
  }
}

/// One entry in a book's real table of contents (from `getBookInfo`'s
/// `include=indexes`) — title + the page it starts on, so tapping it can
/// jump `getPage` straight there (Ismail's spec item 11).
class TurathIndexEntry {
  final String title;
  final int page;
  final int level;
  const TurathIndexEntry({required this.title, required this.page, required this.level});
}

class TurathPage {
  final int bookId;
  final int pageNumber;
  final String volume;
  final String text;
  final List<String> headings;
  const TurathPage({required this.bookId, required this.pageNumber, required this.volume, required this.text, required this.headings});

  factory TurathPage.fromJson(int bookId, String text, Map<String, dynamic> meta) {
    return TurathPage(
      bookId: bookId,
      pageNumber: meta['page'] as int? ?? 0,
      volume: meta['vol']?.toString() ?? '',
      text: text,
      headings: (meta['headings'] as List?)?.map((h) => h.toString()).toList() ?? [],
    );
  }
}

class TurathAuthor {
  final int id;
  final String? bio;
  const TurathAuthor({required this.id, this.bio});
}

/// A book-level or page-level favorite (spec item 10) -- `pageNumber` is
/// null for a whole-book favorite, set for one favorited page. `createdAt`
/// is a Hijri date string (`todayDate()`), matching every other saved-date
/// field in this app (e.g. `quran_favorites.added_date`) -- not ISO8601.
class TurathFavorite {
  final int id;
  final int bookId;
  final String bookName;
  final int? pageNumber;
  final String createdAt;
  const TurathFavorite({required this.id, required this.bookId, required this.bookName, this.pageNumber, required this.createdAt});

  bool get isBook => pageNumber == null;
}

/// The last page a student read in a given book (spec item 11) -- one row
/// per book, overwritten as reading progresses.
class TurathLastRead {
  final int bookId;
  final String bookName;
  final int pageNumber;
  final String updatedAt;
  const TurathLastRead({required this.bookId, required this.bookName, required this.pageNumber, required this.updatedAt});
}

/// A personal note attached to a specific page, optionally to a selected
/// snippet of its text (spec item 12).
/// A saved excerpt with its real citation (spec item 10: "أين نظام
/// الاقتباسات؟"). Distinct from [TurathNote] -- a quote's whole point is
/// the exact text plus where it came from, not a free-standing comment.
class TurathQuote {
  final int id;
  final int bookId;
  final String bookName;
  final String? authorName;
  final String? volume;
  final int pageNumber;
  final String quotedText;
  final String? note;
  final String createdAt;
  const TurathQuote({
    required this.id,
    required this.bookId,
    required this.bookName,
    this.authorName,
    this.volume,
    required this.pageNumber,
    required this.quotedText,
    this.note,
    required this.createdAt,
  });
}

/// A standalone learning takeaway (spec item 14: "دفتر الفوائد"). May cite
/// a source (book/page, optionally a saved [TurathQuote]) or stand alone
/// as a free note the student wants to remember and revisit by topic.
class TurathBenefit {
  final int id;
  final String text;
  final String? topic;
  final int? sourceBookId;
  final String? sourceBookName;
  final int? sourcePageNumber;
  final int? sourceQuoteId;
  final String createdAt;
  const TurathBenefit({
    required this.id,
    required this.text,
    this.topic,
    this.sourceBookId,
    this.sourceBookName,
    this.sourcePageNumber,
    this.sourceQuoteId,
    required this.createdAt,
  });
}

/// One row of the local canonical catalog (`turath_catalog_categories`,
/// migration v48). `totalBooks` is authoritative — read straight from the
/// membership index, never counted from search results (Phase 79
/// `79-membership-index`).
class TurathCategory {
  final int catId;
  final String name;
  final int totalBooks;
  const TurathCategory({required this.catId, required this.name, required this.totalBooks});
}

/// A book as it appears in the local catalog (`turath_catalog_books` joined
/// to `turath_catalog_authors`). Distinct from [TurathBook], which is the
/// live per-book API response (volumes, indexes) fetched when a book is
/// actually opened.
class TurathCatalogBook {
  final int bookId;
  final String name;
  final int? authorId;
  final String authorName;
  final int catId;
  final bool hasPdf;
  final int? pageCount;
  const TurathCatalogBook({
    required this.bookId,
    required this.name,
    this.authorId,
    required this.authorName,
    required this.catId,
    required this.hasPdf,
    this.pageCount,
  });
}

/// One study annotation (`turath_annotations`, migration v49 — Phase 79
/// «علامات الدراسة», `docs/STUDY_ANNOTATIONS_DESIGN.md`).
///
/// [selectedText] is the FULL text the user selected, verbatim — never a
/// first-word fragment. [headAnchor]/[tailAnchor]/[prefixContext]/
/// [suffixContext] are locators only, used to re-find the range if the page
/// text drifts. [charStart]/[charEnd] are UTF-16 offsets into
/// `normalizePageText(page.text)`; they can be null for a legacy row that
/// has not been resolved to offsets yet ([anchorStatus] `'unanchored'`) or
/// for a page-level note ([selectedText] null).
class StudyAnnotation {
  final int id;
  final String? spanGroupId;
  final int bookId;
  final int pageNumber;
  final String? volume;

  final String? selectedText;
  final int? selectedLen;

  final int? charStart;
  final int? charEnd;
  final int normVersion;
  final String? textChecksum;
  final int? textLength;
  final String? prefixContext;
  final String? suffixContext;
  final String? headAnchor;
  final String? tailAnchor;
  final int occurrenceIndex;

  final String colorKey;
  final String? noteType;
  final String? noteBody;

  final String anchorStatus;
  final String sourceKind;
  final int? legacyId;
  final String bookName;
  final String? authorName;
  final String createdAt;
  final String updatedAt;

  const StudyAnnotation({
    required this.id,
    this.spanGroupId,
    required this.bookId,
    required this.pageNumber,
    this.volume,
    this.selectedText,
    this.selectedLen,
    this.charStart,
    this.charEnd,
    required this.normVersion,
    this.textChecksum,
    this.textLength,
    this.prefixContext,
    this.suffixContext,
    this.headAnchor,
    this.tailAnchor,
    required this.occurrenceIndex,
    required this.colorKey,
    this.noteType,
    this.noteBody,
    required this.anchorStatus,
    required this.sourceKind,
    this.legacyId,
    required this.bookName,
    this.authorName,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasNote => (noteBody ?? '').trim().isNotEmpty;

  /// A page-level note (no span) rather than a text highlight.
  bool get isPageLevel => selectedText == null || selectedText!.isEmpty;

  factory StudyAnnotation.fromRow(Map<String, Object?> r) => StudyAnnotation(
        id: r['id'] as int,
        spanGroupId: r['span_group_id'] as String?,
        bookId: r['book_id'] as int,
        pageNumber: r['page_number'] as int,
        volume: r['volume'] as String?,
        selectedText: r['selected_text'] as String?,
        selectedLen: r['selected_len'] as int?,
        charStart: r['char_start'] as int?,
        charEnd: r['char_end'] as int?,
        normVersion: r['norm_version'] as int? ?? 0,
        textChecksum: r['text_checksum'] as String?,
        textLength: r['text_length'] as int?,
        prefixContext: r['prefix_context'] as String?,
        suffixContext: r['suffix_context'] as String?,
        headAnchor: r['head_anchor'] as String?,
        tailAnchor: r['tail_anchor'] as String?,
        occurrenceIndex: r['occurrence_index'] as int? ?? 0,
        colorKey: r['color_key'] as String? ?? 'benefit',
        noteType: r['note_type'] as String?,
        noteBody: r['note_body'] as String?,
        anchorStatus: r['anchor_status'] as String? ?? 'exact',
        sourceKind: r['source_kind'] as String? ?? 'annotation',
        legacyId: r['legacy_id'] as int?,
        bookName: r['book_name'] as String? ?? '',
        authorName: r['author_name'] as String?,
        createdAt: r['created_at'] as String? ?? '',
        updatedAt: r['updated_at'] as String? ?? '',
      );
}

/// The five semantic highlight colours (`color_key`). Stored as the string
/// key, never a hex value, so a palette change needs no data migration and
/// filtering is by meaning.
class StudyAnnotationColors {
  static const benefit = 'benefit'; // 🟨 فائدة
  static const explain = 'explain'; // 🟦 شرح
  static const memorize = 'memorize'; // 🟩 للحفظ والمراجعة
  static const important = 'important'; // 🟥 مهم جدًا
  static const question = 'question'; // 🟪 سؤال / إشكال
  static const all = [benefit, explain, memorize, important, question];
}

/// A [StudyAnnotation] together with where it currently sits on the page,
/// after re-anchoring against the freshly loaded text. `resolved.drawable`
/// is false for an orphan or a page-level note.
class ResolvedAnnotation {
  final StudyAnnotation annotation;
  final ResolvedAnchor resolved;
  const ResolvedAnnotation(this.annotation, this.resolved);
}

/// One row of the unified notebook (Phase 79 `79-sa-D`): a [StudyAnnotation]
/// plus its book's category, resolved by joining the catalog. Nothing is
/// copied — this is a read-only view over `turath_annotations`.
class NotebookEntry {
  final StudyAnnotation annotation;
  final int? catId;
  final String? categoryName;
  const NotebookEntry(this.annotation, {this.catId, this.categoryName});
}

/// Deterministic aggregation of study annotations for the "خريطة الفوائد"
/// screen (`79-sa-E`). Just `GROUP BY` / `COUNT` — no AI.
class StudyAnnotationStats {
  final int total;
  final int withNote;
  final int orphans;
  final Map<String, int> byColor;
  final List<({int id, String name, int count})> byBook;
  final List<({String name, int count})> byCategory;
  final List<({String name, int count})> byAuthor;
  const StudyAnnotationStats({
    required this.total,
    required this.withNote,
    required this.orphans,
    required this.byColor,
    required this.byBook,
    required this.byCategory,
    required this.byAuthor,
  });
}

/// An author in the local catalog (`turath_catalog_authors`), with the
/// number of their books in the library.
class TurathCatalogAuthor {
  final int authorId;
  final String name;
  final int? deathYear;
  final int bookCount;
  const TurathCatalogAuthor({
    required this.authorId,
    required this.name,
    this.deathYear,
    required this.bookCount,
  });
}

class TurathNote {
  final int id;
  final int bookId;
  final String bookName;
  final int pageNumber;
  final String? selectedText;
  final String note;
  final String createdAt;
  const TurathNote({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.pageNumber,
    this.selectedText,
    required this.note,
    required this.createdAt,
  });
}
