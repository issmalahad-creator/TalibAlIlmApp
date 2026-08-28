import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/turath_models.dart';
import '../services/turath_api_client.dart';
import '../utils/month.dart';

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

  Future<void> addNote({required int bookId, required String bookName, required int pageNumber, String? selectedText, required String note}) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('turath_notes', {
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
}
