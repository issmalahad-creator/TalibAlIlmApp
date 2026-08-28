import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/turath_models.dart';

class TurathApiException implements Exception {
  final String message;
  final int? statusCode;
  const TurathApiException(this.message, {this.statusCode});
  @override
  String toString() => 'TurathApiException: $message';
}

/// Raw HTTP layer for turath.io's real public API (Phase 79) — this class's
/// only job is requests/parsing/errors/timeout/retry (Ismail's explicit
/// layering, item 3/4). `TurathRepository` is the layer that turns these
/// into app-shaped data; nothing above this file should know these URLs or
/// query-param names exist.
///
/// Endpoints below are all live-verified 2026-08-27 against the real API
/// (not assumed from the SDK's README) — see `TODO.md` Phase 79 for the
/// exact curl tests run. No API key required today; `TurathConfig`-style
/// fields are kept as constructor params (not hardcoded) so auth can be
/// added later without touching call sites (item 5).
class TurathApiClient {
  final String apiBase;
  final String filesBase;
  final int apiVersion;
  final Duration timeout;
  final int maxRetries;

  /// Minimum gap enforced between any two outgoing requests (Ismail's spec
  /// item 16: "لا ترسل آلاف الطلبات... RateLimiter... لا concurrent requests
  /// بلا حدود"). A real public API with no key is the one most worth being
  /// polite to, not less -- a fast local search-as-you-type shouldn't be
  /// able to fire requests back-to-back with no gap at all.
  final Duration minRequestGap;
  final http.Client _http;
  DateTime? _lastRequestAt;
  Future<void> _requestQueue = Future.value();

  TurathApiClient({
    this.apiBase = 'https://api.turath.io/',
    this.filesBase = 'https://files.turath.io/books/',
    this.apiVersion = 3,
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 2,
    this.minRequestGap = const Duration(milliseconds: 250),
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  Future<Map<String, dynamic>> _getJson(String path, Map<String, String> params) async {
    final uri = Uri.parse(apiBase).replace(path: '/$path', queryParameters: {...params, 'ver': '$apiVersion'});
    return _getWithRetry(uri);
  }

  Future<Map<String, dynamic>> _getFileJson(String path) async {
    final uri = Uri.parse('$filesBase$path');
    return _getWithRetry(uri);
  }

  /// Serializes every real network call through one queue so requests never
  /// fire concurrently, and spaces them by [minRequestGap] -- a real,
  /// simple rate limiter, not a documented intention that isn't enforced.
  Future<Map<String, dynamic>> _getWithRetry(Uri uri) {
    final result = _requestQueue.then((_) => _throttledGet(uri));
    // Swallow errors here so one failed request doesn't poison the queue
    // for requests queued after it; the real error still reaches the
    // caller via the returned `result` future below.
    _requestQueue = result.then((_) => null, onError: (_) => null);
    return result;
  }

  Future<Map<String, dynamic>> _throttledGet(Uri uri) async {
    final last = _lastRequestAt;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < minRequestGap) await Future.delayed(minRequestGap - elapsed);
    }
    _lastRequestAt = DateTime.now();

    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final resp = await _http.get(uri, headers: {'Accept': 'application/json'}).timeout(timeout);
        if (resp.statusCode == 404) {
          throw TurathApiException('Not found', statusCode: 404);
        }
        if (resp.statusCode != 200) {
          throw TurathApiException('Request failed (${resp.statusCode})', statusCode: resp.statusCode);
        }
        return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      } on TurathApiException catch (e) {
        if (e.statusCode == 404) rethrow; // never worth retrying a real 404
        lastError = e;
      } catch (e) {
        lastError = e;
      }
      if (attempt < maxRetries) await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
    }
    throw TurathApiException('Failed after ${maxRetries + 1} attempts: $lastError');
  }

  /// `meta` fields in this API come back as JSON-encoded strings, not
  /// nested objects (confirmed live 2026-08-27 on `/page` and `/search`)
  /// — this helper is the one place that quirk is handled.
  Map<String, dynamic> _decodeMeta(dynamic rawMeta) {
    if (rawMeta is Map<String, dynamic>) return rawMeta;
    if (rawMeta is String && rawMeta.isNotEmpty) {
      final decoded = jsonDecode(rawMeta);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return {};
  }

  /// [bookId] scopes the search to one book -- Ismail's spec item 9
  /// ("البحث داخل الكتاب"), live-verified 2026-08-28 against book 16521
  /// (`?q=...&book_id=16521` returned only that book's real matches, not
  /// guessed from the SDK docs -- `book_id` isn't documented there at all).
  Future<TurathSearchResults> search(String query, {int? categoryId, int? bookId, int? authorId, int? page}) async {
    final json = await _getJson('search', {
      'q': query,
      if (categoryId != null) 'cat_id': '$categoryId',
      if (bookId != null) 'book_id': '$bookId',
      if (authorId != null) 'author_id': '$authorId',
      if (page != null) 'pg': '$page',
    });
    final data = (json['data'] as List?) ?? [];
    return TurathSearchResults(
      count: json['count'] as int? ?? 0,
      results: data
          .map((r) => TurathSearchResult.fromJson(r as Map<String, dynamic>, _decodeMeta(r['meta'])))
          .toList(),
    );
  }

  Future<TurathBook> getBookInfo(int bookId) async {
    final json = await _getJson('book', {'id': '$bookId', 'include': 'indexes'});
    return TurathBook.fromJson(bookId, json);
  }

  Future<TurathPage> getPage(int bookId, int pageNumber) async {
    final json = await _getJson('page', {'book_id': '$bookId', 'pg': '$pageNumber'});
    final meta = _decodeMeta(json['meta']);
    final text = json['text'] as String?;
    if (text == null && meta.isEmpty) {
      throw TurathApiException('Book $bookId, page $pageNumber not found', statusCode: 404);
    }
    return TurathPage.fromJson(bookId, text ?? '', meta);
  }

  Future<TurathAuthor> getAuthor(int authorId) async {
    final json = await _getJson('author', {'id': '$authorId'});
    final info = json['info'] as Map<String, dynamic>?;
    if (info == null) throw TurathApiException('Author $authorId not found', statusCode: 404);
    return TurathAuthor(id: authorId, bio: info['info'] as String? ?? info.toString());
  }

  /// The full raw JSON dump for a book — real but large; only fetch this
  /// when a feature genuinely needs the whole book (e.g. a future offline
  /// download), never for normal page-by-page reading (that's `getPage`).
  Future<Map<String, dynamic>> getBookFile(int bookId) => _getFileJson('$bookId.json');

  void dispose() => _http.close();
}
