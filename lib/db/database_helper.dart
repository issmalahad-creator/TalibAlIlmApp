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
      version: 11,
      onCreate: (db, version) async {
        await _createV1Tables(db);
        await _createV2Tables(db);
        await _createV3Tables(db);
        await _createV4Tables(db);
        await _createV5Tables(db);
        await _createV6Tables(db);
        await _createV7Tables(db);
        await _createV8Tables(db);
        await _createV9Tables(db);
        await _createV10Tables(db);
        await _createV11Tables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createV2Tables(db);
        if (oldVersion < 3) await _createV3Tables(db);
        if (oldVersion < 4) await _createV4Tables(db);
        if (oldVersion < 5) await _createV5Tables(db);
        if (oldVersion < 6) await _createV6Tables(db);
        if (oldVersion < 7) await _createV7Tables(db);
        if (oldVersion < 8) await _createV8Tables(db);
        if (oldVersion < 9) await _createV9Tables(db);
        if (oldVersion < 10) await _createV10Tables(db);
        if (oldVersion < 11) await _createV11Tables(db);
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

  /// Phase 1/2 of QURAN_COMPANION_ROADMAP.md — the memorization + 6-station
  /// review engine (roadmap section 4). `memorization_units` rows (604,
  /// one per Mushaf page) are generated from `quran_ayat.page_number` by
  /// `QuranImportService`, not here — this migration only creates the empty
  /// tables. Additive only, every earlier table/row is untouched.
  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE memorization_units (
        id INTEGER PRIMARY KEY,
        surah_start INTEGER NOT NULL,
        ayah_start INTEGER NOT NULL,
        surah_end INTEGER NOT NULL,
        ayah_end INTEGER NOT NULL,
        juz_number INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE memorization_progress (
        unit_id INTEGER PRIMARY KEY REFERENCES memorization_units(id),
        status TEXT NOT NULL DEFAULT 'not_started',
        memorized_date TEXT,
        last_review_date TEXT,
        next_review_date TEXT,
        station INTEGER,
        consecutive_good_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_memorization_progress_next_review ON memorization_progress(next_review_date)
    ''');
    await db.execute('''
      CREATE TABLE review_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit_id INTEGER NOT NULL REFERENCES memorization_units(id),
        review_date TEXT NOT NULL,
        quality TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE mistake_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit_id INTEGER NOT NULL REFERENCES memorization_units(id),
        review_id INTEGER REFERENCES review_log(id),
        note TEXT,
        logged_date TEXT NOT NULL
      )
    ''');
  }

  /// Personal, self-declared, non-monetary accountability — QURAN_COMPANION_
  /// ROADMAP.md section 4.7's "الالتزام الشخصي" idea, expanded (2026-08-15)
  /// into a full reward + punishment pair per Ismail's explicit request.
  /// The app only ever *reminds* the student of what they themselves wrote
  /// here — it never enforces, deletes, blocks, or notifies anyone else.
  /// Single row (id=1); `punishment_enabled = 0` is the explicit
  /// "بدون عقاب" choice, not an unset/default state.
  Future<void> _createV4Tables(Database db) async {
    await db.execute('''
      CREATE TABLE personal_accountability (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        reward_enabled INTEGER NOT NULL DEFAULT 0,
        reward_text TEXT,
        punishment_enabled INTEGER NOT NULL DEFAULT 0,
        punishment_text TEXT
      )
    ''');
  }

  /// "جلسة اليوم" — QURAN_COMPANION_ROADMAP.md section 6. Only 3 of the 6
  /// designed steps (قراءة/حفظ جديد/مراجعة) have real data behind them yet;
  /// فهم/تطبيق/اختبار wait on Phase 3 (`understanding_progress`,
  /// `practical_lessons`) and are shown as "قريبًا" in the UI rather than
  /// faked with empty tables here.
  Future<void> _createV5Tables(Database db) async {
    await db.execute('''
      CREATE TABLE daily_session_log (
        date TEXT PRIMARY KEY,
        did_reading INTEGER NOT NULL DEFAULT 0,
        did_new_memorization INTEGER NOT NULL DEFAULT 0,
        did_review INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Phase 3 of QURAN_COMPANION_ROADMAP.md — the "فهم" and "مطبّق" pillars.
  /// `understanding_progress` is keyed by `unit_id` (one row per Mushaf
  /// page, same granularity as `memorization_progress`) rather than the
  /// ayah-range key sketched in the roadmap's early draft — simpler and
  /// consistent with every other unit-scoped table, and "فهمت هذه الصفحة"
  /// is how the daily session actually asks the question.
  Future<void> _createV6Tables(Database db) async {
    await db.execute('''
      CREATE TABLE understanding_progress (
        unit_id INTEGER PRIMARY KEY REFERENCES memorization_units(id),
        understood INTEGER NOT NULL DEFAULT 0,
        user_notes TEXT,
        marked_date TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE practical_lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah INTEGER NOT NULL,
        ayah_from INTEGER NOT NULL,
        ayah_to INTEGER NOT NULL,
        lesson_text TEXT NOT NULL,
        value_tag TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_practical_lessons_surah ON practical_lessons(surah)
    ''');
    await db.execute('''
      CREATE TABLE application_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id INTEGER NOT NULL REFERENCES practical_lessons(id),
        applied_date TEXT NOT NULL,
        user_reflection TEXT
      )
    ''');
  }

  /// Adds the فهم/تطبيق columns to `daily_session_log` now that Phase 3 data
  /// exists to back them — simple additive `ALTER TABLE`, same path for
  /// fresh installs (right after `_createV5Tables` in `onCreate`) and
  /// upgrades.
  Future<void> _createV7Tables(Database db) async {
    await db.execute('ALTER TABLE daily_session_log ADD COLUMN did_understanding INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE daily_session_log ADD COLUMN did_application INTEGER NOT NULL DEFAULT 0');
  }

  /// "اختبر نفسك" — the last of جلسة اليوم's 6 steps. No external question
  /// bank was found for this (searched, nothing structured exists) — the
  /// quiz is instead generated entirely from `quran_ayat` already imported:
  /// "ما الآية التالية؟" within the student's own memorized range, the same
  /// mechanic real Hifz teachers use to test memorization. No new reference
  /// table needed, just this one tracking column.
  Future<void> _createV8Tables(Database db) async {
    await db.execute('ALTER TABLE daily_session_log ADD COLUMN did_quiz INTEGER NOT NULL DEFAULT 0');
  }

  /// Phase 5أ of QURAN_COMPANION_ROADMAP.md — Al-Arba'in Al-Nawawiyyah, the
  /// first extended-library text (Ismail asked to generalize اختبر نفسك
  /// beyond Quran). Deliberately simple compared to the Quran's 6-station
  /// engine (`hadith_progress` is just memorized/not-memorized, no stations)
  /// — a full parallel review engine for every future text is out of scope
  /// for now; this is a lighter, honest first step for a discrete 42-item
  /// text rather than a continuous recited one.
  Future<void> _createV9Tables(Database db) async {
    await db.execute('''
      CREATE TABLE nawawi_hadiths (
        id INTEGER PRIMARY KEY,
        hadith_text TEXT NOT NULL,
        commentary_text TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE hadith_progress (
        hadith_id INTEGER PRIMARY KEY REFERENCES nawawi_hadiths(id),
        memorized INTEGER NOT NULL DEFAULT 0,
        memorized_date TEXT
      )
    ''');
  }

  /// Phase 5ب — Al-Aqidah Al-Wasitiyyah (Ibn Taymiyyah), source: ar.wikisource.org
  /// (verified verbatim via its raw wikitext export, not a summarized
  /// fetch). A continuous treatise like the Quran, so it reuses the same
  /// "reviewing" concept as memorization_progress but — like the hadith
  /// table — kept to memorized/not-memorized only, no 6-station engine.
  Future<void> _createV10Tables(Database db) async {
    await db.execute('''
      CREATE TABLE wasitiyyah_sections (
        id INTEGER PRIMARY KEY,
        section_order INTEGER NOT NULL,
        original_text TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE wasitiyyah_progress (
        section_id INTEGER PRIMARY KEY REFERENCES wasitiyyah_sections(id),
        memorized INTEGER NOT NULL DEFAULT 0,
        memorized_date TEXT
      )
    ''');
  }

  /// Phase 5ج — Zad al-Ma'ad (Ibn al-Qayyim), source: ar.wikisource.org raw
  /// wikitext, same verbatim-fetch discipline as Al-Wasitiyyah. Volume 1
  /// only for now (the Seerah-introduction volume, matching roadmap 5ج's
  /// study-unit 1) — 4 more volumes exist and are added incrementally
  /// later, not all 5 at once. `has_uthaymeen_commentary` stays 0 for every
  /// row here — his "التعليق على فصول من زاد المعاد" text itself hasn't
  /// been sourced yet, this is Ibn al-Qayyim's original only.
  Future<void> _createV11Tables(Database db) async {
    await db.execute('''
      CREATE TABLE zad_almaad_chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        volume INTEGER NOT NULL,
        chapter_order INTEGER NOT NULL,
        chapter_title TEXT NOT NULL,
        chapter_text TEXT NOT NULL,
        has_uthaymeen_commentary INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE zad_almaad_progress (
        chapter_id INTEGER PRIMARY KEY REFERENCES zad_almaad_chapters(id),
        read_done INTEGER NOT NULL DEFAULT 0,
        read_date TEXT
      )
    ''');
  }
}
