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
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('turath_favorites');
    await db.delete('turath_last_read');
    await db.delete('turath_notes');
    await db.delete('turath_book_cache');
    await db.delete('turath_page_cache');
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
  });
}
