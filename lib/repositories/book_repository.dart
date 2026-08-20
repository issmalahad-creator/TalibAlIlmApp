import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/reading_record.dart';
import '../utils/month.dart';

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

  /// "دفتر الفوائد" for a PDF book — mirrors
  /// `AudioLibraryRepository.reflectionsFor`'s pattern (Ismail's explicit
  /// 2026-08-16 "اجعل هذي الخاصية نفس المكتبة الصوتية" request).
  Future<List<BookReflection>> reflectionsFor(String bookKey) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('book_reflection_log', where: 'book_key = ?', whereArgs: [bookKey], orderBy: 'id DESC');
    return rows.map(BookReflection.fromMap).toList();
  }

  Future<void> addReflection(String bookKey, String text, {int? page}) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('book_reflection_log', {
      'book_key': bookKey,
      'page': page,
      'reflection_text': text,
      'created_date': todayDate(),
    });
  }

  Future<void> updateReflection(int id, String text) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('book_reflection_log', {'reflection_text': text}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteReflection(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('book_reflection_log', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> totalReflectionCount() async {
    final db = await DatabaseHelper.instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM book_reflection_log')) ?? 0;
  }

  /// "سجل التطبيق" — "ما الخُلق الذي طبّقته اليوم؟" — distinct from a
  /// reading reflection (this is real-life application, not a note about
  /// the text), same shape as the Quran pillar's existing
  /// `application_log`/`practical_lessons` concept but book-scoped instead
  /// of ayah-scoped since a scanned book has no addressable lesson units.
  Future<List<BookApplicationEntry>> applicationsFor(String bookKey) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('book_application_log', where: 'book_key = ?', whereArgs: [bookKey], orderBy: 'id DESC');
    return rows.map(BookApplicationEntry.fromMap).toList();
  }

  Future<void> addApplication(String bookKey, String text) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('book_application_log', {
      'book_key': bookKey,
      'application_text': text,
      'created_date': todayDate(),
    });
  }

  Future<void> updateApplication(int id, String text) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('book_application_log', {'application_text': text}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteApplication(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('book_application_log', where: 'id = ?', whereArgs: [id]);
  }
}
