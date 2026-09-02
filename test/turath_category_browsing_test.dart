import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/turath_models.dart';
import 'package:talib_alilm_app/repositories/turath_catalog_sync.dart';
import 'package:talib_alilm_app/repositories/turath_repository.dart';
import 'package:talib_alilm_app/services/turath_api_client.dart';

/// Phase 79 — Category Browsing + Search Integration. Real SQLite + the real
/// bundled catalog, with a fake `TurathApiClient` for the search paths so no
/// network is touched.
///
/// The invariants Ismail asked for:
///  - العقيدة = 808, unaffected by the PDF filter or any search.
///  - search inside a category never returns a book from another category.
///  - global search stays category-agnostic.
///  - browsing works with no network at all.

class _FakeApiClient extends TurathApiClient {
  List<TurathSearchResult> next = [];
  int? lastCategoryId;
  int searchCalls = 0;
  bool throwOnSearch = false;

  @override
  Future<TurathSearchResults> search(String query, {int? categoryId, int? bookId, int? authorId, int? page}) async {
    searchCalls++;
    lastCategoryId = categoryId;
    if (throwOnSearch) throw const TurathApiException('offline');
    return TurathSearchResults(count: next.length, results: next);
  }
}

TurathSearchResult _hit(int bookId, {String name = 'كتاب', int page = 3}) => TurathSearchResult(
      bookId: bookId,
      catId: 0,
      authorId: 0,
      bookName: name,
      authorName: 'مؤلف',
      page: page,
      volume: '1',
      headings: const [],
      snippet: 'مقتطف فيه كلمة شرح',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_catbrowse_test.db';
    final dbFile = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (dbFile.existsSync()) dbFile.deleteSync();

    final gz = File(join('assets', 'turath', 'catalog-v3.json.gz'));
    final manifest = jsonDecode(utf8.decode(gzip.decode(gz.readAsBytesSync()))) as Map<String, dynamic>;
    final res = await TurathCatalogSync().ingestFromJson(manifest);
    expect(res.outcome, 'seeded');
  });

  group('category count is filter-proof', () {
    test('العقيدة = 808 regardless of the PDF filter', () async {
      final repo = TurathRepository();
      expect(await repo.categoryBookCount(1), 808);

      final pdfCount = await repo.categoryPdfBookCount(1);
      expect(pdfCount, greaterThan(0));
      expect(pdfCount, lessThanOrEqualTo(808));

      // The canonical count does not budge when we browse the PDF-only view.
      final pdfPage = await repo.booksInCategory(1, limit: 50, offset: 0, pdfOnly: true);
      expect(pdfPage.every((b) => b.hasPdf), isTrue);
      expect(await repo.categoryBookCount(1), 808);
    });

    test('paging the PDF-only view yields exactly categoryPdfBookCount distinct books', () async {
      final repo = TurathRepository();
      final expected = await repo.categoryPdfBookCount(1);
      final seen = <int>{};
      var offset = 0;
      while (true) {
        final page = await repo.booksInCategory(1, limit: 100, offset: offset, pdfOnly: true);
        if (page.isEmpty) break;
        for (final b in page) {
          expect(b.hasPdf, isTrue);
          expect(seen.add(b.bookId), isTrue);
        }
        offset += 100;
      }
      expect(seen.length, expected);
    });
  });

  group('search inside a category', () {
    test('drops any result whose book is not a member of the category', () async {
      final repo0 = TurathRepository();
      final aqeedah = (await repo0.categoryMemberIds(1)).toList()..sort();
      final tafsir = (await repo0.categoryMemberIds(3)).toList()..sort();
      final outsider = tafsir.firstWhere((id) => !aqeedah.contains(id));

      final fake = _FakeApiClient()
        ..next = [
          _hit(aqeedah[0], name: 'من كتب العقيدة'),
          _hit(outsider, name: 'من كتب التفسير'),
          _hit(aqeedah[1], name: 'من كتب العقيدة'),
        ];
      final repo = TurathRepository(client: fake);

      final results = await repo.searchInCategory('شرح', 1);
      expect(results.map((r) => r.bookId), [aqeedah[0], aqeedah[1]]);
      expect(fake.lastCategoryId, 1, reason: 'the API cat_id filter must also be applied');
    });

    test('global search does not scope to any category', () async {
      final fake = _FakeApiClient()..next = [_hit(999999)];
      final repo = TurathRepository(client: fake);
      await repo.search('شرح');
      expect(fake.lastCategoryId, isNull);
    });
  });

  group('offline', () {
    test('browsing a category needs no network — the api client is never called', () async {
      final fake = _FakeApiClient()..throwOnSearch = true;
      final repo = TurathRepository(client: fake);

      final cats = await repo.categories();
      expect(cats.length, 40);
      expect(await repo.categoryBookCount(1), 808);

      final page1 = await repo.booksInCategory(1, limit: 30, offset: 0);
      final page2 = await repo.booksInCategory(1, limit: 30, offset: 30);
      expect(page1, hasLength(30));
      expect(page2, hasLength(30));
      expect(page1.map((b) => b.bookId).toSet().intersection(page2.map((b) => b.bookId).toSet()), isEmpty);

      expect(fake.searchCalls, 0, reason: 'browse must never hit the network');
    });
  });
}
