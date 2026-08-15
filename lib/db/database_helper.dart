import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'talib_alilm.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createV1Tables(db);
        await _createV2Tables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createV2Tables(db);
      },
    );
  }

  Future<void> _createV1Tables(Database db) async {
    await db.execute('''
          CREATE TABLE profile (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            full_name TEXT DEFAULT '',
            residence TEXT DEFAULT '',
            study_track TEXT DEFAULT '',
            study_source TEXT DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE activities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            title TEXT NOT NULL,
            beneficiaries INTEGER,
            notes TEXT DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            target INTEGER NOT NULL,
            current INTEGER NOT NULL DEFAULT 0,
            month TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE reading_progress (
            month TEXT PRIMARY KEY,
            percent INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE quiz_results (
            month TEXT PRIMARY KEY,
            score_percent INTEGER NOT NULL,
            taken_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE book_bookmarks (
            book_key TEXT PRIMARY KEY,
            last_page INTEGER NOT NULL DEFAULT 0,
            total_pages INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE daily_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            date TEXT NOT NULL,
            time TEXT,
            reminder_enabled INTEGER NOT NULL DEFAULT 0,
            completed INTEGER NOT NULL DEFAULT 0,
            checklist_json TEXT NOT NULL DEFAULT '[]'
          )
        ''');
        await db.execute('''
          CREATE TABLE personal_books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            file_path TEXT NOT NULL,
            added_at TEXT NOT NULL,
            category_id INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE personal_book_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE hifz_surah_status (
            surah_number INTEGER PRIMARY KEY,
            memorized INTEGER NOT NULL DEFAULT 0,
            memorized_date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE hifz_daily_log (
            date TEXT PRIMARY KEY
          )
        ''');
        await db.execute('''
          CREATE TABLE hifz_students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            guardian_phone TEXT DEFAULT '',
            age INTEGER,
            progress TEXT DEFAULT '',
            date_added TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE hifz_student_fields (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            label TEXT NOT NULL,
            value TEXT DEFAULT ''
          )
        ''');
  }

  /// Phase 0 of QURAN_COMPANION_ROADMAP.md — Quran text + tafsir reference
  /// data. Additive only; every v1 table/row is untouched by this migration.
  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE quran_ayat (
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        text_uthmani TEXT NOT NULL,
        text_normalized TEXT NOT NULL,
        page_number INTEGER,
        juz_number INTEGER,
        PRIMARY KEY (surah, ayah)
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_quran_ayat_normalized ON quran_ayat(text_normalized)
    ''');
    await db.execute('''
      CREATE TABLE tafsir_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah INTEGER NOT NULL,
        ayah_from INTEGER NOT NULL,
        ayah_to INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'ibn_kathir',
        text TEXT NOT NULL,
        asbab_nuzul_excerpt TEXT
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_tafsir_surah_ayah ON tafsir_entries(surah, ayah_from, ayah_to)
    ''');
  }
}
