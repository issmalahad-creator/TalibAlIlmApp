import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/turath_catalog_sync.dart';
import 'package:talib_alilm_app/repositories/turath_repository.dart';

/// Phase 79 `79-membership-index` — real proof that the local canonical
/// catalog (`turath_catalog_*`, migration v48) is deterministic, against a
/// real SQLite database and the real bundled `data-v3.json` snapshot (not a
/// mock, not a trimmed fixture).
///
/// Ismail 2026-08-29: العقيدة → 808, and it must stay 808 whichever way the
/// screen is driven; a payload that fails validation must be rejected, not
/// allowed to replace good data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Map<String, dynamic> manifest;

  setUpAll(() async {
    // Own db file, so this (DB-heavy) suite never races another DB-backed
    // suite for the shared one under `flutter test`'s parallel runner.
    DatabaseHelper.databaseName = 'talib_catalog_test.db';
    final dbFile = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (dbFile.existsSync()) dbFile.deleteSync();

    final gz = File(join('assets', 'turath', 'catalog-v3.json.gz'));
    expect(gz.existsSync(), isTrue, reason: 'bundled catalog asset must be present');
    manifest = jsonDecode(utf8.decode(gzip.decode(gz.readAsBytesSync()))) as Map<String, dynamic>;
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    for (final t in const [
      'turath_catalog_category_books',
      'turath_catalog_books',
      'turath_catalog_authors',
      'turath_catalog_categories',
      'turath_catalog_meta',
    ]) {
      await db.delete(t);
    }
  });

  group('validation (before anything is written)', () {
    test('the bundled manifest passes every structural + snapshot check', () {
      final v = TurathCatalogSync().validate(manifest);
      expect(v.categories, 40);
      expect(v.books, 8593);
      expect(v.authors, 3188);
      expect(v.membershipRows, 8593, reason: 'sum of every category\'s books[]');
      expect(v.distinctMemberBooks, 8593);
      expect(v.booksWithoutCategory, 0);
      expect(v.danglingMemberships, 0);
      expect(v.duplicateMemberships, 0);
      expect(v.ok, isTrue, reason: v.toString());
    });

    test('a truncated payload (5 books dropped) fails validation', () {
      final broken = jsonDecode(jsonEncode(manifest)) as Map<String, dynamic>;
      final books = (broken['books'] as Map);
      for (final k in books.keys.take(5).toList()) {
        books.remove(k);
      }
      final v = TurathCatalogSync().validate(broken);
      expect(v.ok, isFalse);
      expect(v.failures, isNotEmpty);
    });
  });

  group('ingest → deterministic membership', () {
    test('العقيدة resolves to exactly 808 books, and total_books == the join table', () async {
      final res = await TurathCatalogSync().ingestFromJson(manifest);
      expect(res.outcome, 'seeded');

      final repo = TurathRepository();
      final cats = await repo.categories();
      expect(cats.length, 40);

      final aqeedah = cats.firstWhere((c) => c.catId == 1);
      expect(aqeedah.name, 'العقيدة');
      expect(aqeedah.totalBooks, 808);

      expect(await repo.categoryBookCount(1), 808);

      final db = await DatabaseHelper.instance.database;
      final joinCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM turath_catalog_category_books WHERE cat_id = 1',
      ));
      expect(joinCount, 808, reason: 'stored total_books must match the real membership rows');
    });

    test('paging from 0 to 808 yields 808 distinct books and never changes the count', () async {
      await TurathCatalogSync().ingestFromJson(manifest);
      final repo = TurathRepository();

      final seen = <int>{};
      var offset = 0;
      const pageSize = 30;
      while (true) {
        final page = await repo.booksInCategory(1, limit: pageSize, offset: offset);
        if (page.isEmpty) break;
        for (final b in page) {
          expect(seen.add(b.bookId), isTrue, reason: 'book ${b.bookId} returned twice across pages');
        }
        // The reported total is stable on every single page turn.
        expect(await repo.categoryBookCount(1), 808);
        offset += pageSize;
      }
      expect(seen.length, 808);
    });

    test('every category total_books sums to 8593 and matches its join rows', () async {
      await TurathCatalogSync().ingestFromJson(manifest);
      final db = await DatabaseHelper.instance.database;

      final sumTotals = Sqflite.firstIntValue(
        await db.rawQuery('SELECT SUM(total_books) FROM turath_catalog_categories'),
      );
      expect(sumTotals, 8593);

      final mismatches = await db.rawQuery('''
        SELECT c.cat_id
        FROM turath_catalog_categories c
        WHERE c.total_books <> (
          SELECT COUNT(*) FROM turath_catalog_category_books cb WHERE cb.cat_id = c.cat_id
        )
      ''');
      expect(mismatches, isEmpty);

      final orphans = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM turath_catalog_books b
        WHERE NOT EXISTS (SELECT 1 FROM turath_catalog_category_books cb WHERE cb.book_id = b.book_id)
      '''));
      expect(orphans, 0);
    });
  });

  group('rejection keeps the old data', () {
    test('a failing payload does not replace an already-good catalog', () async {
      await TurathCatalogSync().ingestFromJson(manifest);
      final repo = TurathRepository();
      expect(await repo.categoryBookCount(1), 808);

      final broken = jsonDecode(jsonEncode(manifest)) as Map<String, dynamic>;
      (broken['books'] as Map).remove((broken['books'] as Map).keys.first);
      final res = await TurathCatalogSync().ingestFromJson(broken);

      expect(res.outcome, 'rejected');
      expect(await repo.categoryBookCount(1), 808, reason: 'old catalog must survive a rejected sync');
      final db = await DatabaseHelper.instance.database;
      expect(
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM turath_catalog_books')),
        8593,
      );
    });
  });

  group('authors', () {
    test('author browse is ordered by book count and carries a real count', () async {
      await TurathCatalogSync().ingestFromJson(manifest);
      final repo = TurathRepository();
      final authors = await repo.catalogAuthors(limit: 5);
      expect(authors.length, 5);
      for (var i = 1; i < authors.length; i++) {
        expect(authors[i - 1].bookCount >= authors[i].bookCount, isTrue);
      }
      final top = authors.first;
      final books = await repo.booksByAuthor(top.authorId);
      expect(books.length, top.bookCount);
    });
  });
}
