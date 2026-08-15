import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/reading_record.dart';

class BookRepository {
  Future<ReadingProgress> getProgress(String month) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('reading_progress', where: 'month = ?', whereArgs: [month]);
    if (rows.isEmpty) return ReadingProgress(month: month, percent: 0);
    return ReadingProgress.fromMap(rows.first);
  }

  Future<void> setProgress(String month, int percent) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('reading_progress', {'month': month, 'percent': percent},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<QuizResult?> getQuizResult(String month) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quiz_results', where: 'month = ?', whereArgs: [month]);
    if (rows.isEmpty) return null;
    return QuizResult.fromMap(rows.first);
  }

  Future<void> saveQuizResult(QuizResult result) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('quiz_results', result.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<BookBookmark?> getBookmark(String bookKey) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('book_bookmarks', where: 'book_key = ?', whereArgs: [bookKey]);
    if (rows.isEmpty) return null;
    return BookBookmark.fromMap(rows.first);
  }

  Future<void> saveBookmark(BookBookmark bookmark) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('book_bookmarks', bookmark.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Every book the student has opened in-app, across admin books, other
  /// Telegram content, and their own personal library — used for the
  /// reading-stats view.
  Future<List<BookBookmark>> allBookmarks() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('book_bookmarks');
    return rows.map(BookBookmark.fromMap).toList();
  }

  Future<List<QuizResult>> allQuizResults() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quiz_results');
    return rows.map(QuizResult.fromMap).toList();
  }
}
