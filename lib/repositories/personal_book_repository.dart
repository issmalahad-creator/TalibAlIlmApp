import '../db/database_helper.dart';
import '../models/personal_book.dart';

class PersonalBookRepository {
  Future<List<PersonalBook>> all() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('personal_books', orderBy: 'id DESC');
    return rows.map(PersonalBook.fromMap).toList();
  }

  Future<int> add(PersonalBook book) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('personal_books', book.toMap());
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('personal_books', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setCategory(int bookId, int? categoryId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('personal_books', {'category_id': categoryId}, where: 'id = ?', whereArgs: [bookId]);
  }

  Future<List<PersonalBookCategory>> categories() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('personal_book_categories', orderBy: 'name ASC');
    return rows.map(PersonalBookCategory.fromMap).toList();
  }

  Future<int> addCategory(String name) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('personal_book_categories', {'name': name});
  }

  Future<void> renameCategory(int id, String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('personal_book_categories', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes the category only — books that were in it are never deleted,
  /// just fall back to uncategorized (`category_id = NULL`).
  Future<void> deleteCategory(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('personal_books', {'category_id': null}, where: 'category_id = ?', whereArgs: [id]);
    await db.delete('personal_book_categories', where: 'id = ?', whereArgs: [id]);
  }
}
