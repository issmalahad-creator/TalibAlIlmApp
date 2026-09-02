import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/turath_repository.dart';

/// Real, database-backed proof for the Turath local features added
/// 2026-08-28 (favorites, last-read position, notes, page/book cache) --
/// same rigor as `recitation_repository_test.dart`: a real SQLite database
/// via `sqflite_common_ffi`, not mocks.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    final dbDir = join('.dart_tool', 'sqflite_common_ffi', 'databases');
    final dbFile = File(join(dbDir, 'talib_alilm.db'));
    // Best-effort: another DB-backed suite may hold this file open when
    // `flutter test` runs suites in parallel. Per-table cleanup in setUp is
    // what actually isolates this suite, so a locked file here is fine.
    try {
      if (dbFile.existsSync()) dbFile.deleteSync();
    } on FileSystemException catch (_) {}
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('turath_favorites');
    await db.delete('turath_last_read');
    await db.delete('turath_notes');
    await db.delete('turath_book_cache');
    await db.delete('turath_page_cache');
    await db.delete('turath_quotes');
    await db.delete('turath_benefits');
  });

  group('TurathRepository favorites', () {
    test('toggling a book favorite on then off round-trips correctly', () async {
      final repo = TurathRepository();
      expect(await repo.isFavoriteBook(137), isFalse);

      await repo.toggleFavoriteBook(137, 'صحيح البخاري');
      expect(await repo.isFavoriteBook(137), isTrue);
      final list = await repo.favorites();
      expect(list.length, 1);
      expect(list.first.isBook, isTrue);
      expect(list.first.bookName, 'صحيح البخاري');

      await repo.toggleFavoriteBook(137, 'صحيح البخاري');
      expect(await repo.isFavoriteBook(137), isFalse);
      expect(await repo.favorites(), isEmpty);
    });

    test('a book favorite and a page favorite for the same book are independent', () async {
      final repo = TurathRepository();
      await repo.toggleFavoriteBook(137, 'صحيح البخاري');
      await repo.toggleFavoritePage(137, 'صحيح البخاري', 42);

      expect(await repo.isFavoriteBook(137), isTrue);
      expect(await repo.isFavoritePage(137, 42), isTrue);
      expect(await repo.isFavoritePage(137, 99), isFalse);

      final list = await repo.favorites();
      expect(list.length, 2);

      await repo.toggleFavoritePage(137, 'صحيح البخاري', 42);
      expect(await repo.isFavoritePage(137, 42), isFalse);
      expect(await repo.isFavoriteBook(137), isTrue, reason: 'removing the page favorite must not touch the book favorite');
    });
  });

  group('TurathRepository last-read position', () {
    test('saving last-read twice for the same book overwrites, not duplicates', () async {
      final repo = TurathRepository();
      await repo.saveLastRead(137, 'صحيح البخاري', 10);
      await repo.saveLastRead(137, 'صحيح البخاري', 25);

      final lr = await repo.lastRead(137);
      expect(lr!.pageNumber, 25);

      final recent = await repo.recentlyRead();
      expect(recent.length, 1, reason: 'one row per book, overwritten, not appended');
    });

    test('recentlyRead tracks multiple different books independently', () async {
      final repo = TurathRepository();
      await repo.saveLastRead(137, 'صحيح البخاري', 10);
      await repo.saveLastRead(9500, 'رياض الصالحين', 5);

      final recent = await repo.recentlyRead();
      expect(recent.length, 2);
      expect(recent.map((r) => r.bookId).toSet(), {137, 9500});
    });
  });

  group('TurathRepository notes', () {
    test('a note persists with its selected text and page, and can be deleted', () async {
      final repo = TurathRepository();
      await repo.addNote(bookId: 137, bookName: 'صحيح البخاري', pageNumber: 12, selectedText: 'إنما الأعمال بالنيات', note: 'حديث محوري');

      final notes = await repo.notesForPage(137, 12);
      expect(notes.length, 1);
      expect(notes.first.selectedText, 'إنما الأعمال بالنيات');
      expect(notes.first.note, 'حديث محوري');

      final all = await repo.allNotes();
      expect(all.length, 1);

      await repo.deleteNote(notes.first.id);
      expect(await repo.notesForPage(137, 12), isEmpty);
    });

    test('notes on different pages of the same book stay separate', () async {
      final repo = TurathRepository();
      await repo.addNote(bookId: 137, bookName: 'صحيح البخاري', pageNumber: 1, note: 'أولى');
      await repo.addNote(bookId: 137, bookName: 'صحيح البخاري', pageNumber: 2, note: 'ثانية');

      expect(await repo.notesForPage(137, 1), hasLength(1));
      expect(await repo.notesForPage(137, 2), hasLength(1));
      expect(await repo.allNotes(), hasLength(2));
    });

    test('editing a note changes its text in place, keeping the same id and created date', () async {
      final repo = TurathRepository();
      final id = await repo.addNote(bookId: 137, bookName: 'صحيح البخاري', pageNumber: 1, note: 'أولى');
      await repo.updateNote(id, 'نسخة معدَّلة');

      final notes = await repo.notesForPage(137, 1);
      expect(notes.length, 1, reason: 'editing must not create a second row');
      expect(notes.first.id, id);
      expect(notes.first.note, 'نسخة معدَّلة');
    });
  });

  group('TurathRepository quotes', () {
    test('a quote persists its full citation and can be deleted', () async {
      final repo = TurathRepository();
      await repo.addQuote(bookId: 137, bookName: 'صحيح البخاري', authorName: 'البخاري', volume: '1', pageNumber: 5, quotedText: 'إنما الأعمال بالنيات', note: 'حديث محوري');

      final quotes = await repo.allQuotes();
      expect(quotes.length, 1);
      expect(quotes.first.authorName, 'البخاري');
      expect(quotes.first.volume, '1');
      expect(quotes.first.pageNumber, 5);
      expect(quotes.first.quotedText, 'إنما الأعمال بالنيات');

      await repo.deleteQuote(quotes.first.id);
      expect(await repo.allQuotes(), isEmpty);
    });
  });

  group('TurathRepository benefits', () {
    test('a standalone benefit (no source) persists and can be edited', () async {
      final repo = TurathRepository();
      final id = await repo.addBenefit(text: 'فائدة عامة', topic: 'العقيدة');

      var benefits = await repo.allBenefits();
      expect(benefits.length, 1);
      expect(benefits.first.sourceBookId, isNull);
      expect(benefits.first.topic, 'العقيدة');

      await repo.updateBenefit(id, 'فائدة معدَّلة');
      benefits = await repo.allBenefits();
      expect(benefits.first.text, 'فائدة معدَّلة');
      expect(benefits.first.id, id, reason: 'editing must not create a new row');
    });

    test('a benefit with a real source keeps its citation', () async {
      final repo = TurathRepository();
      await repo.addBenefit(text: 'فائدة من كتاب', sourceBookId: 137, sourceBookName: 'صحيح البخاري', sourcePageNumber: 5);

      final benefits = await repo.allBenefits();
      expect(benefits.first.sourceBookId, 137);
      expect(benefits.first.sourceBookName, 'صحيح البخاري');
      expect(benefits.first.sourcePageNumber, 5);

      await repo.deleteBenefit(benefits.first.id);
      expect(await repo.allBenefits(), isEmpty);
    });
  });
}
