import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../data/turath_categories.dart';
import '../db/database_helper.dart';
import '../utils/month.dart';

/// Outcome of a [TurathCatalogSync] run, so callers (and tests) can see
/// exactly what happened and the real validation numbers.
class CatalogSyncResult {
  final bool changed;
  final String outcome; // 'seeded' | 'refreshed' | 'up-to-date' | 'offline' | 'rejected' | 'skipped'
  final CatalogValidation? validation;
  const CatalogSyncResult(this.outcome, {this.changed = false, this.validation});
  @override
  String toString() => 'CatalogSyncResult($outcome, changed=$changed, ${validation ?? "no validation"})';
}

/// Structural + snapshot validation of a `data-v3.json` payload, run BEFORE
/// anything is written. Ismail 2026-08-29: "لا تفترض أن نجاح GET يعني أن
/// البيانات صحيحة" — a truncated or malformed download must never replace a
/// good local catalog.
class CatalogValidation {
  // Expected totals for the current published catalog (version 1,
  // 2026-02-03). A genuine upstream growth is a deliberate app update
  // (re-bundle the asset + bump these); until then, a payload that doesn't
  // match exactly is treated as corrupt and rejected.
  static const expectedCategories = 40;
  static const expectedBooks = 8593;
  static const expectedAuthors = 3188;

  final int categories;
  final int books;
  final int authors;
  final int membershipRows; // sum of every category's books[] length
  final int distinctMemberBooks; // books referenced by >=1 category (deduped)
  final int booksWithoutCategory; // in books{} but in no category
  final int danglingMemberships; // referenced by a category but absent from books{}
  final int duplicateMemberships; // same (cat_id, book_id) listed more than once
  final List<String> failures;

  const CatalogValidation({
    required this.categories,
    required this.books,
    required this.authors,
    required this.membershipRows,
    required this.distinctMemberBooks,
    required this.booksWithoutCategory,
    required this.danglingMemberships,
    required this.duplicateMemberships,
    required this.failures,
  });

  bool get ok => failures.isEmpty;

  @override
  String toString() => 'CatalogValidation(cats=$categories, books=$books, authors=$authors, '
      'membershipRows=$membershipRows, distinctMemberBooks=$distinctMemberBooks, '
      'booksWithoutCategory=$booksWithoutCategory, danglingMemberships=$danglingMemberships, '
      'duplicateMemberships=$duplicateMemberships, ok=$ok'
      '${failures.isEmpty ? "" : ", failures=$failures"})';
}

/// Builds and maintains the local canonical catalog of the turath.io library
/// (`turath_catalog_*` tables, migration v48).
///
/// Phase 79 `79-membership-index`. Ismail 2026-08-29: "Stop treating
/// full-text search as the source of truth for category membership." The
/// count and the book list for a category must be deterministic, so they
/// come from a real membership index (`turath_catalog_category_books`), not
/// from counting search hits.
///
/// `https://files.turath.io/data-v3.json` is turath.io's own official
/// manifest — the same file `app.turath.io` downloads on startup — with a
/// `cats` map (`{id, name, books:[bookId…]}`), a `books` map, and an
/// `authors` map. A dated snapshot ships as `assets/turath/catalog-v3.json.gz`
/// so the feature works offline on first launch; the network copy is pulled
/// in the background when it's stale and genuinely newer.
///
/// The catalog is rebuilt wholesale on each ingest (it's ~8.6k tiny rows) —
/// simpler and safer than diffing — inside a single transaction, and only
/// after validation passes. It never touches the local user-data tables
/// (`turath_favorites`/`turath_notes`/…), a separate concern.
class TurathCatalogSync {
  static const _assetPath = 'assets/turath/catalog-v3.json.gz';
  static const _manifestUrl = 'https://files.turath.io/data-v3.json';

  /// How old the local catalog may get before a network refresh is
  /// attempted. The upstream manifest changes rarely, so a fortnight keeps
  /// launches cheap while staying reasonably current.
  static const _maxAge = Duration(days: 14);

  final http.Client _http;
  TurathCatalogSync({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  /// The single entry point (called once from app startup): seed the
  /// catalog from the bundled asset if it's empty, then refresh from the
  /// network if the local copy is stale and a newer version exists. Every
  /// failure mode is swallowed — offline is normal — and reported via the
  /// returned [CatalogSyncResult].
  Future<CatalogSyncResult> syncCatalog({bool forceNetwork = false}) async {
    final db = await DatabaseHelper.instance.database;

    final have = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM turath_catalog_categories'),
        ) ??
        0;

    if (have == 0) {
      final seeded = await _seedFromAsset(db);
      // Right after a successful seed, check the network once (ignoring the
      // staleness gate) so a fresh install picks up a newer published
      // version instead of sitting on the bundled snapshot for two weeks.
      // The version guard inside still prevents a pointless re-ingest when
      // the network copy is the same version as the asset.
      if (seeded.changed) {
        final refreshed = await _refreshFromNetwork(db, forced: true);
        return refreshed.changed ? refreshed : seeded;
      }
      return seeded;
    }

    return _refreshFromNetwork(db, forced: forceNetwork);
  }

  Future<CatalogSyncResult> _seedFromAsset(Database db) async {
    try {
      final byteData = await rootBundle.load(_assetPath);
      final jsonText = utf8.decode(gzip.decode(byteData.buffer.asUint8List()));
      final json = jsonDecode(jsonText) as Map<String, dynamic>;
      final v = validate(json);
      if (!v.ok) {
        debugPrint('TurathCatalogSync: bundled asset failed validation, keeping static fallback. $v');
        return CatalogSyncResult('rejected', validation: v);
      }
      await _ingest(db, json, source: 'asset', validation: v);
      debugPrint('TurathCatalogSync: seeded from asset. $v');
      return CatalogSyncResult('seeded', changed: true, validation: v);
    } catch (e) {
      debugPrint('TurathCatalogSync: asset seed failed ($e) — static fallback stays in effect.');
      return const CatalogSyncResult('skipped');
    }
  }

  Future<CatalogSyncResult> _refreshFromNetwork(Database db, {required bool forced}) async {
    try {
      final localVersion = int.tryParse(await _meta(db, 'version') ?? '') ?? 0;
      final syncedAtMs = int.tryParse(await _meta(db, 'synced_at_ms') ?? '');
      final everSynced = syncedAtMs != null;
      if (!forced && everSynced && !_olderThan(syncedAtMs)) {
        return const CatalogSyncResult('up-to-date');
      }

      final resp = await _http
          .get(Uri.parse(_manifestUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) return const CatalogSyncResult('offline');
      final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

      final remoteVersion = json['version'] as int? ?? 0;
      // `forced` only skips the age gate above -- a same-or-older version is
      // still never re-ingested.
      if (everSynced && remoteVersion <= localVersion) {
        await _touchSyncedAt(db); // current — don't re-check until the next window
        return const CatalogSyncResult('up-to-date');
      }

      final v = validate(json);
      if (!v.ok) {
        // Reject: keep the old data untouched, log why.
        debugPrint('TurathCatalogSync: network payload REJECTED, local catalog kept. $v');
        return CatalogSyncResult('rejected', validation: v);
      }

      await _ingest(db, json, source: 'network', validation: v);
      debugPrint('TurathCatalogSync: refreshed from network. $v');
      return CatalogSyncResult('refreshed', changed: true, validation: v);
    } catch (e) {
      debugPrint('TurathCatalogSync: network refresh skipped ($e) — local catalog kept.');
      return const CatalogSyncResult('offline');
    }
  }

  /// Validate then ingest an already-parsed manifest, no asset/network.
  /// The one seam tests use to drive a real ingest against a real database.
  @visibleForTesting
  Future<CatalogSyncResult> ingestFromJson(Map<String, dynamic> json, {String source = 'test'}) async {
    final db = await DatabaseHelper.instance.database;
    final v = validate(json);
    if (!v.ok) return CatalogSyncResult('rejected', validation: v);
    await _ingest(db, json, source: source, validation: v);
    return CatalogSyncResult('seeded', changed: true, validation: v);
  }

  /// Structural + snapshot validation of a parsed `data-v3.json` map. Pure
  /// and side-effect free so it can be unit-tested directly.
  CatalogValidation validate(Map<String, dynamic> json) {
    final failures = <String>[];
    final cats = json['cats'];
    final books = json['books'];
    final authors = json['authors'];

    if (cats is! Map || books is! Map || authors is! Map) {
      failures.add('missing/!map top-level keys (cats/books/authors)');
      return CatalogValidation(
        categories: cats is Map ? cats.length : 0,
        books: books is Map ? books.length : 0,
        authors: authors is Map ? authors.length : 0,
        membershipRows: 0,
        distinctMemberBooks: 0,
        booksWithoutCategory: 0,
        danglingMemberships: 0,
        duplicateMemberships: 0,
        failures: failures,
      );
    }

    final bookIds = books.values
        .map((b) => (b as Map)['id'] as int?)
        .whereType<int>()
        .toSet();

    var membershipRows = 0;
    final seenPairs = <String>{};
    var duplicateMemberships = 0;
    final memberBooks = <int>{};
    for (final raw in cats.values) {
      final c = raw as Map;
      final cid = c['id'] as int;
      final list = (c['books'] as List?) ?? const [];
      for (final b in list) {
        final bid = b as int;
        membershipRows++;
        if (!seenPairs.add('$cid:$bid')) duplicateMemberships++;
        memberBooks.add(bid);
      }
    }

    final booksWithoutCategory = bookIds.difference(memberBooks).length;
    final danglingMemberships = memberBooks.difference(bookIds).length;

    if (cats.length != CatalogValidation.expectedCategories) {
      failures.add('categories=${cats.length} (expected ${CatalogValidation.expectedCategories})');
    }
    if (books.length != CatalogValidation.expectedBooks) {
      failures.add('books=${books.length} (expected ${CatalogValidation.expectedBooks})');
    }
    if (authors.length != CatalogValidation.expectedAuthors) {
      failures.add('authors=${authors.length} (expected ${CatalogValidation.expectedAuthors})');
    }
    if (membershipRows != CatalogValidation.expectedBooks) {
      failures.add('sum(category membership)=$membershipRows (expected ${CatalogValidation.expectedBooks})');
    }
    if (booksWithoutCategory != 0) failures.add('booksWithoutCategory=$booksWithoutCategory (expected 0)');
    if (danglingMemberships != 0) failures.add('danglingMemberships=$danglingMemberships (expected 0)');
    if (duplicateMemberships != 0) failures.add('duplicateMemberships=$duplicateMemberships (expected 0)');
    if (memberBooks.length != CatalogValidation.expectedBooks) {
      failures.add('distinct books in membership=${memberBooks.length} (expected ${CatalogValidation.expectedBooks})');
    }

    return CatalogValidation(
      categories: cats.length,
      books: books.length,
      authors: authors.length,
      membershipRows: membershipRows,
      distinctMemberBooks: memberBooks.length,
      booksWithoutCategory: booksWithoutCategory,
      danglingMemberships: danglingMemberships,
      duplicateMemberships: duplicateMemberships,
      failures: failures,
    );
  }

  Future<void> _ingest(
    Database db,
    Map<String, dynamic> json, {
    required String source,
    required CatalogValidation validation,
  }) async {
    final cats = (json['cats'] as Map).cast<String, dynamic>();
    final books = (json['books'] as Map).cast<String, dynamic>();
    final authors = (json['authors'] as Map).cast<String, dynamic>();

    // Keep the curated Arabic category names from `turath_categories.dart`
    // in the UI (the manifest has a typo in cat 9 — "السؤلات" — and Ismail
    // asked the names to stay exactly as he sent them); use the manifest
    // only for the official ids + membership. Fall back to the manifest's
    // own name for any id not in the static list.
    final curatedNames = {for (final c in turathCategories) c.catId: c.name};
    final order = {for (var i = 0; i < turathCategories.length; i++) turathCategories[i].catId: i};

    await db.transaction((txn) async {
      for (final t in const [
        'turath_catalog_category_books',
        'turath_catalog_books',
        'turath_catalog_authors',
        'turath_catalog_categories',
        'turath_catalog_meta',
      ]) {
        await txn.delete(t);
      }

      final batch = txn.batch();

      cats.forEach((_, raw) {
        final c = raw as Map<String, dynamic>;
        final id = c['id'] as int;
        final bookIds = ((c['books'] as List?) ?? const []).cast<int>();
        batch.insert('turath_catalog_categories', {
          'cat_id': id,
          'name_ar': curatedNames[id] ?? (c['name'] as String? ?? ''),
          'total_books': bookIds.length,
          'sort_order': order[id] ?? id,
        });
        for (final bid in bookIds) {
          batch.insert(
            'turath_catalog_category_books',
            {'cat_id': id, 'book_id': bid},
            conflictAlgorithm: ConflictAlgorithm.ignore, // PK(cat_id,book_id) already blocks dupes
          );
        }
      });

      authors.forEach((_, raw) {
        final a = raw as Map<String, dynamic>;
        batch.insert('turath_catalog_authors', {
          'author_id': a['id'] as int,
          'name': a['name'] as String? ?? '',
          'death_year': a['death'] as int?,
        });
      });

      books.forEach((_, raw) {
        final b = raw as Map<String, dynamic>;
        batch.insert('turath_catalog_books', {
          'book_id': b['id'] as int,
          'name': b['name'] as String? ?? '',
          'author_id': b['author_id'] as int?,
          'cat_id': b['cat_id'] as int? ?? 0,
          'has_pdf': (b['has_pdf'] as bool? ?? false) ? 1 : 0,
          'page_count': b['page_count'] as int?,
          'size': b['size'] as int?,
        });
      });

      await batch.commit(noResult: true);

      // Post-insert cross-check against the DB itself. If the rows that
      // actually landed disagree with the validated payload, throw — the
      // transaction rolls back and the previous catalog is restored intact.
      final catRows = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM turath_catalog_categories'));
      final bookRows = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM turath_catalog_books'));
      final memberRows = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM turath_catalog_category_books'));
      final totalOfTotals = Sqflite.firstIntValue(await txn.rawQuery('SELECT COALESCE(SUM(total_books),0) FROM turath_catalog_categories'));
      if (catRows != CatalogValidation.expectedCategories ||
          bookRows != CatalogValidation.expectedBooks ||
          memberRows != CatalogValidation.expectedBooks ||
          totalOfTotals != CatalogValidation.expectedBooks) {
        throw StateError('post-insert cross-check failed: catRows=$catRows bookRows=$bookRows '
            'memberRows=$memberRows sum(total_books)=$totalOfTotals — rolling back, old catalog kept');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      for (final e in {
        'version': '${json['version'] ?? 0}',
        'date': '${json['date'] ?? ''}',
        'synced_at': todayDate(),
        'synced_at_ms': '$now',
        'source': source,
      }.entries) {
        await txn.insert('turath_catalog_meta', {'key': e.key, 'value': e.value});
      }
    });
  }

  Future<void> _touchSyncedAt(Database db) async {
    for (final e in {
      'synced_at': todayDate(),
      'synced_at_ms': '${DateTime.now().millisecondsSinceEpoch}',
    }.entries) {
      await db.insert(
        'turath_catalog_meta',
        {'key': e.key, 'value': e.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<String?> _meta(DatabaseExecutor db, String key) async {
    final rows = await db.query('turath_catalog_meta', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  bool _olderThan(int syncedAtMs) =>
      DateTime.now().millisecondsSinceEpoch - syncedAtMs > _maxAge.inMilliseconds;

  void dispose() => _http.close();
}
