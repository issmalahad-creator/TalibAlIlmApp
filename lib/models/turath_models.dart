/// Real, verified models for turath.io's public API (Phase 79,
/// `TODO.md`). Every field here maps to a real response observed live on
/// 2026-08-27 against `api.turath.io` — none of this is guessed from the
/// SDK's docs alone. Deliberately separate from any UI widget (Ismail's
/// explicit instruction 33: "لا تربط Models الخاصة بـTurath مباشرة بواجهة
/// المستخدم") so a later API change only touches `TurathApiClient`.
library;

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
