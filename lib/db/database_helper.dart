import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/arabic_normalize.dart';
import 'turath_annotations_migration.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  /// Overrides the on-disk database filename. Tests set this (before the
  /// first `database` access) so a DB-heavy suite gets its own file and
  /// doesn't race other DB-backed suites for the shared one when
  /// `flutter test` runs suites in parallel. Never set in production.
  @visibleForTesting
  static String databaseName = 'talib_alilm.db';

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);
    return openDatabase(
      path,
      version: 53,
      // 2026-08-18: مُعطَّل بشكل دائم — مؤكَّد بالاختبار الحي، لا افتراض.
      // (100_IDEAS #69) سبَّب تعليق الصفحة الرئيسية بالتحميل فورًا عند
      // تفعيله على جهاز إسماعيل الفعلي؛ تعطيله وحده (دون أي تغيير آخر) هو
      // ما أعاد التطبيق للعمل. الأرجح: تبديل قاعدة بيانات SQLite قائمة
      // فعليًا (لا قاعدة جديدة) من وضع rollback-journal الافتراضي إلى WAL
      // عبر PRAGMA حيّة قد يتعطّل على بعض أجهزة أندرويد/إصدارات SQLite
      // المرفقة. لا تُعِد تفعيل هذا دون اختبار حقيقي على جهاز حقيقي أولًا.
      // onConfigure: (db) async {
      //   await db.execute('PRAGMA journal_mode = WAL');
      //   await db.execute('PRAGMA synchronous = NORMAL');
      // },
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
        await _createV12Tables(db);
        await _createV13Tables(db);
        await _createV14Tables(db);
        await _createV15Tables(db);
        await _createV16Tables(db);
        await _createV17Tables(db);
        await _createV18Tables(db);
        await _createV19Tables(db);
        await _createV20Tables(db);
        await _createV21Tables(db);
        await _createV22Tables(db);
        await _createV23Tables(db);
        await _createV25Tables(db);
        await _createV26Tables(db);
        await _createV28Tables(db);
        await _createV29Tables(db);
        await _createV30Tables(db);
        await _createV31Tables(db);
        await _createV32Tables(db);
        await _createV33Tables(db);
        await _createV34Tables(db);
        await _createV35Tables(db);
        await _createV36Tables(db);
        await _createV37Tables(db);
        await _createV38Tables(db);
        await _createV39Tables(db);
        await _createV40Tables(db);
        await _createV41Tables(db);
        await _createV42Tables(db);
        await _createV43Tables(db);
        await _createV44Tables(db);
        await _createV45Tables(db);
        await _createV46Tables(db);
        await _createV47Tables(db);
        await _createV48Tables(db);
        await _createV49Tables(db);
        await _createV50Tables(db);
        await _createV51Tables(db);
        await _createV52Tables(db);
        await _createV53Tables(db);
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
        if (oldVersion < 12) await _createV12Tables(db);
        if (oldVersion < 13) await _createV13Tables(db);
        if (oldVersion < 14) await _createV14Tables(db);
        if (oldVersion < 15) await _createV15Tables(db);
        if (oldVersion < 16) await _createV16Tables(db);
        if (oldVersion < 17) await _createV17Tables(db);
        if (oldVersion < 18) await _createV18Tables(db);
        if (oldVersion < 19) await _createV19Tables(db);
        if (oldVersion < 20) await _createV20Tables(db);
        if (oldVersion < 21) await _createV21Tables(db);
        if (oldVersion < 22) await _createV22Tables(db);
        if (oldVersion < 23) await _createV23Tables(db);
        if (oldVersion < 24) await _fixQuranNormalizedTextV24(db);
        if (oldVersion < 25) await _createV25Tables(db);
        if (oldVersion < 26) await _createV26Tables(db);
        if (oldVersion < 27) await _fixQuranNormalizedTextV27(db);
        if (oldVersion < 28) await _createV28Tables(db);
        if (oldVersion < 29) await _createV29Tables(db);
        if (oldVersion < 30) await _createV30Tables(db);
        if (oldVersion < 31) await _createV31Tables(db);
        if (oldVersion < 32) await _createV32Tables(db);
        if (oldVersion < 33) await _createV33Tables(db);
        if (oldVersion < 34) await _createV34Tables(db);
        if (oldVersion < 35) await _createV35Tables(db);
        if (oldVersion < 36) await _createV36Tables(db);
        if (oldVersion < 37) await _createV37Tables(db);
        if (oldVersion < 38) await _createV38Tables(db);
        if (oldVersion < 39) {
          await _createV39Tables(db);
          await _backfillHizbNumbersV39(db);
        }
        if (oldVersion < 40) await _createV40Tables(db);
        if (oldVersion < 41) await _createV41Tables(db);
        if (oldVersion < 42) await _createV42Tables(db);
        if (oldVersion < 43) await _createV43Tables(db);
        if (oldVersion < 44) await _createV44Tables(db);
        if (oldVersion < 45) await _createV45Tables(db);
        if (oldVersion < 46) await _createV46Tables(db);
        if (oldVersion < 47) await _createV47Tables(db);
        if (oldVersion < 48) await _createV48Tables(db);
        if (oldVersion < 49) {
          await _createV49Tables(db);
          // Copying legacy notes/quotes into the new table is best-effort:
          // the old rows are untouched, so a hiccup here must not fail the
          // whole upgrade (and brick every DB-backed screen).
          try {
            await migrateLegacyToAnnotations(db);
          } catch (_) {/* legacy copy can be retried later */}
        }
        if (oldVersion < 50) await _createV50Tables(db);
        if (oldVersion < 51) await _createV51Tables(db);
        if (oldVersion < 52) await _createV52Tables(db);
        if (oldVersion < 53) await _createV53Tables(db);
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

  /// Phase 5ح — Madarij As-Salikin (Ibn al-Qayyim), source: ar.wikisource.org
  /// raw wikitext, same verbatim-fetch discipline as every other classical
  /// text here. **Advanced tier ONLY** per the roadmap's explicit scoping —
  /// this is the deepest, hardest text in the whole app; the UI must always
  /// carry that warning (no level-lock system exists yet to enforce it
  /// technically, so the warning is the only safeguard for now). Part 1 of
  /// (typically 3 printed parts) only, for now.
  Future<void> _createV12Tables(Database db) async {
    await db.execute('''
      CREATE TABLE madarij_sections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        part INTEGER NOT NULL,
        section_order INTEGER NOT NULL,
        section_title TEXT NOT NULL,
        text_excerpt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE madarij_progress (
        section_id INTEGER PRIMARY KEY REFERENCES madarij_sections(id),
        read_done INTEGER NOT NULL DEFAULT 0,
        read_date TEXT
      )
    ''');
  }

  /// Phase 4.15 of QURAN_COMPANION_ROADMAP.md — "خطة الختم": a single
  /// generalized completion-planner shared by Quran reading, Quran
  /// memorization, and every book, plus the genuinely new "قراءة القرآن"
  /// concept (periodic full read-through, distinct from memorization —
  /// `quran_reading_progress` didn't exist before this).
  Future<void> _createV13Tables(Database db) async {
    await db.execute('''
      CREATE TABLE completion_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_type TEXT NOT NULL,
        book_ref TEXT,
        total_units INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        target_date TEXT NOT NULL,
        daily_target REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'active'
      )
    ''');
    await db.execute('''
      CREATE TABLE quran_reading_progress (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        last_page INTEGER NOT NULL DEFAULT 0,
        last_read_date TEXT,
        khatm_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Adds a "did they touch this book today" signal to the existing
  /// `book_bookmarks` table (shared by admin books, other Telegram content,
  /// and personal-library books) — needed so per-goal daily reminders
  /// (section 4.15's "لم تقرأ اليوم" notifications) can detect today's
  /// personal-book progress the same way the other content types already
  /// can via their own *_progress tables' date columns.
  Future<void> _createV14Tables(Database db) async {
    await db.execute('ALTER TABLE book_bookmarks ADD COLUMN last_updated_date TEXT');
  }

  /// Phase 4 of QURAN_COMPANION_ROADMAP.md (roadmap §4.7/§4.14) — "رحلتي"
  /// journey dashboard + the certificate/celebration system. `journey_plan`
  /// is a single settings row (SMART-wizard output: target pace + an
  /// optional trial week at a lighter pace before the full computed pace
  /// kicks in) and an optional non-enforced `personal_commitment_text`
  /// (roadmap §4.7 — shown only as a self-reminder, the app never acts on
  /// it). `achievement_milestones` is seeded up front with EVERY possible
  /// certificate (locked, achieved_date NULL) by `MilestoneRepository` so
  /// the "شهاداتي" gallery can show the full unlock map from day one —
  /// this migration only creates the empty table.
  Future<void> _createV15Tables(Database db) async {
    await db.execute('''
      CREATE TABLE journey_plan (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        start_date TEXT,
        target_years REAL,
        level TEXT,
        daily_new_pages REAL,
        trial_week_active INTEGER NOT NULL DEFAULT 1,
        personal_commitment_text TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE achievement_milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pillar TEXT NOT NULL,
        milestone_type TEXT NOT NULL,
        reference_id INTEGER,
        title TEXT NOT NULL,
        achieved_date TEXT,
        certificate_shared INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Phase 5هـ of QURAN_COMPANION_ROADMAP.md — Hisn al-Muslim daily adhkar
  /// (Sa'id Al-Qahtani; the whole book, 134 chapters/298 duas, verified
  /// verbatim against `rn0x/hisn_almuslim_json` — see the import service's
  /// doc comment). `adhkar_categories.is_daily_core` flags the ~17 routine
  /// everyday-life chapters (waking up, wudu, mosque, morning/evening,
  /// sleep, istighfar, etc.) pinned to the top of the adhkar screen; the
  /// rest of the book (funerals, hajj, travel, ...) stays browsable below.
  /// `adhkar_completion` is deliberately category+date only (not per-item) —
  /// a category counts as done for the day once every item in it has been
  /// tapped through, which is all a streak needs to know.
  Future<void> _createV16Tables(Database db) async {
    await db.execute('''
      CREATE TABLE adhkar_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_order INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_daily_core INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE adhkar_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL REFERENCES adhkar_categories(id),
        item_order INTEGER NOT NULL,
        text TEXT NOT NULL,
        footnote TEXT,
        repeat_count INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX idx_adhkar_items_category ON adhkar_items(category_id)');
    await db.execute('''
      CREATE TABLE adhkar_completion (
        category_id INTEGER NOT NULL REFERENCES adhkar_categories(id),
        completed_date TEXT NOT NULL,
        PRIMARY KEY (category_id, completed_date)
      )
    ''');
  }

  /// "الورد اليومي" — QURAN_COMPANION_ROADMAP.md §4.17. The templates
  /// themselves are a fixed curated list in `data/wird_templates.dart`
  /// (not DB-driven); only the student's current selection and the new
  /// istighfar tally need storage — every other item in a wird template
  /// (Quran, adhkar, scholar-content reading) reuses a *_progress table
  /// that already exists.
  Future<void> _createV17Tables(Database db) async {
    await db.execute('''
      CREATE TABLE wird_selection (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        template_key TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE istighfar_log (
        log_date TEXT PRIMARY KEY,
        count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// "دليل المسلم الجديد" — QURAN_COMPANION_ROADMAP.md §4.9 (5د, expanded
  /// 2026-08-15). Content (Wudu/Ghusl/Istinja/Salah steps, ar/en/am) is a
  /// fixed const list in `data/new_muslim_guide.dart`, same pattern as the
  /// wird templates — this migration only creates the "has this topic been
  /// opened" tracker, kept separate from the rest of the app's
  /// `*_progress` tables since this content isn't memorized/reviewed, just
  /// read once as onboarding.
  Future<void> _createV18Tables(Database db) async {
    await db.execute('''
      CREATE TABLE guide_progress (
        topic_key TEXT PRIMARY KEY,
        first_read_date TEXT
      )
    ''');
  }

  /// Arabic-learning curriculum for non-native speakers — QURAN_COMPANION_ROADMAP.md
  /// Phase 10b (Ismail's request 2026-08-15: "منهج وكل شيء متكامل لتعلم
  /// العربية لغير الألسنة العربية"). A DIFFERENT audience from 5و's planned
  /// Noorani Qaida (children learning to read) — this is staged for adult
  /// non-native learners (alphabet → vocabulary → grammar → Quranic-Arabic
  /// comprehension). Lesson content is a fixed const list
  /// (`data/arabic_curriculum.dart`), same pattern as the wird templates
  /// and new-Muslim guide — this migration only tracks per-lesson
  /// completion, needed for the stage-completion certificates Ismail
  /// explicitly asked every pillar to have.
  Future<void> _createV19Tables(Database db) async {
    await db.execute('''
      CREATE TABLE arabic_curriculum_progress (
        lesson_key TEXT PRIMARY KEY,
        learned_date TEXT
      )
    ''');
  }

  /// Tajweed curriculum, 3 tiers — QURAN_COMPANION_ROADMAP.md Phase 11
  /// (Ismail's request 2026-08-15). Rule content is a fixed const list
  /// (`data/tajweed_curriculum.dart`), same pattern as the Arabic
  /// curriculum — this migration only tracks per-rule "learned" marks,
  /// needed for the per-tier completion certificates Ismail explicitly
  /// asked every pillar to have.
  Future<void> _createV20Tables(Database db) async {
    await db.execute('''
      CREATE TABLE tajweed_progress (
        rule_key TEXT PRIMARY KEY,
        learned_date TEXT
      )
    ''');
  }

  /// "إقامة الصلاة" — a full Salah-establishment companion, Ismail's request
  /// 2026-08-16: not just prayer times, but daily non-judgmental tracking,
  /// a weekly self-assessment (7 dimensions — critically, khushu is always
  /// SELF-rated; the app never claims to measure a worshipper's inward
  /// state), a curated lesson library, and well-known Salaf khushu stories.
  /// `salah_log` deliberately has no "streak breaking" concept — a missed
  /// prayer is just a missed row, never a shamed/reset counter, matching
  /// this app's non-punitive principle throughout.
  Future<void> _createV21Tables(Database db) async {
    await db.execute('''
      CREATE TABLE salah_log (
        log_date TEXT NOT NULL,
        prayer TEXT NOT NULL,
        status TEXT NOT NULL,
        PRIMARY KEY (log_date, prayer)
      )
    ''');
    await db.execute('''
      CREATE TABLE salah_self_assessment (
        week_start TEXT NOT NULL,
        dimension TEXT NOT NULL,
        rating INTEGER NOT NULL,
        PRIMARY KEY (week_start, dimension)
      )
    ''');
    await db.execute('''
      CREATE TABLE salah_library_progress (
        lesson_key TEXT PRIMARY KEY,
        read_date TEXT
      )
    ''');
  }

  /// "كتب صوتية من اليوتيوب" (Phase 13, Ismail's request 2026-08-16) —
  /// audio-lecture series streamed via YouTube's own official embedded
  /// player (youtube_player_iframe), never downloaded/rehosted. This app
  /// only stores metadata (series/video/playlist IDs) and the user's own
  /// resume position + written reflections — never the audio/video itself.
  Future<void> _createV22Tables(Database db) async {
    await db.execute('''
      CREATE TABLE audio_progress (
        series_id TEXT PRIMARY KEY,
        video_id TEXT NOT NULL,
        position_seconds INTEGER NOT NULL,
        updated_date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE audio_reflection_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        series_id TEXT NOT NULL,
        video_id TEXT,
        reflection_text TEXT NOT NULL,
        created_date TEXT NOT NULL
      )
    ''');
    // User's own added series — self-service, unlike the curated
    // `audioSeries` const list. Same "مكتبتي" pattern as personal PDFs:
    // clearly separated from app-curated content, no review/approval flow.
    await db.execute('''
      CREATE TABLE custom_audio_series (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title_ar TEXT NOT NULL,
        playlist_id TEXT,
        video_id TEXT,
        created_date TEXT NOT NULL
      )
    ''');
  }

  /// Phase 14 Sub-phase B — the time-budgeted guided session
  /// (`guided_session_screen.dart`). Extends `daily_session_log` (not a
  /// new table) since this is still "today's session" data, just with an
  /// optional end-of-session self-reflection when the student uses the
  /// guided flow specifically (plain checklist use leaves these null).
  Future<void> _createV23Tables(Database db) async {
    await db.execute('ALTER TABLE daily_session_log ADD COLUMN session_minutes_planned INTEGER');
    await db.execute('ALTER TABLE daily_session_log ADD COLUMN session_difficulty TEXT');
    await db.execute('ALTER TABLE daily_session_log ADD COLUMN session_note TEXT');
  }

  /// Data-only migration, no schema change: `arabic_normalize.dart`'s
  /// search-normalization regex was missing a whole family of Quranic
  /// combining marks (madda above, hamza above/below, and the Quranic
  /// small-mark/waqf-annotation block) — confirmed against the real
  /// Tanzil Uthmani text, e.g. "فقراء" is spelled with a combining madda
  /// (U+0653) that was never stripped, so a plain-typed "الفقراء" query
  /// could never match it (Ismail's report 2026-08-16). `quran_ayat.
  /// text_normalized` is computed once at import time, not live per
  /// search — existing installs already have the stale, under-stripped
  /// values baked in, so the regex fix alone doesn't help them. This
  /// recomputes every row with the corrected function. Not needed in
  /// `onCreate`: a fresh install populates `quran_ayat` afterward via
  /// `QuranImportService`, already using the fixed function.
  Future<void> _fixQuranNormalizedTextV24(Database db) async {
    final rows = await db.query('quran_ayat', columns: ['surah', 'ayah', 'text_uthmani']);
    final batch = db.batch();
    for (final row in rows) {
      batch.update(
        'quran_ayat',
        {'text_normalized': normalizeArabicForSearch(row['text_uthmani'] as String)},
        where: 'surah = ? AND ayah = ?',
        whereArgs: [row['surah'], row['ayah']],
      );
    }
    await batch.commit(noResult: true);
  }

  /// "أضف للمفضلة" on the per-ayah context menu (Ismail's request
  /// 2026-08-16, matching the reference app's tap-an-ayah popup) — a
  /// simple personal bookmark list, independent of `book_bookmarks`
  /// (that's for PDF reading position, this is specific ayat the student
  /// wants to find again quickly).
  Future<void> _createV25Tables(Database db) async {
    await db.execute('''
      CREATE TABLE quran_favorites (
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        added_date TEXT NOT NULL,
        PRIMARY KEY (surah, ayah)
      )
    ''');
  }

  /// "محاسبة الوقت" — Ismail's request 2026-08-16, grounded in the real
  /// hadith (Tirmidhi 2417) that a servant will be asked on the Day of
  /// Judgment how they spent their life/time. Purely self-reported, like
  /// every other subjective self-rating in this app (khushu, session
  /// difficulty) — the app never infers or measures how someone's hours
  /// were actually spent, only records what they say about it.
  Future<void> _createV26Tables(Database db) async {
    await db.execute('''
      CREATE TABLE time_awareness_log (
        log_date TEXT PRIMARY KEY,
        hours_well_spent REAL,
        note TEXT
      )
    ''');
  }

  /// Follow-up to `_fixQuranNormalizedTextV24`: that fix stripped the
  /// combining madda/hamza marks but still deleted the dagger alef
  /// (U+0670) outright. Deleting it is wrong for most words — in the
  /// Uthmani rasm it usually stands in for a real, omitted "ا" letter
  /// (e.g. ٱلظَّـٰلِمِينَ = "الظالمين"), so a plain-typed search for
  /// "الظالمين" still returned nothing (Ismail's report 2026-08-16,
  /// second screenshot after the v24 fix). Same reasoning as v24: this
  /// column is computed once at import time, so already-installed
  /// devices need every row recomputed with the corrected function.
  Future<void> _fixQuranNormalizedTextV27(Database db) async {
    final rows = await db.query('quran_ayat', columns: ['surah', 'ayah', 'text_uthmani']);
    final batch = db.batch();
    for (final row in rows) {
      batch.update(
        'quran_ayat',
        {'text_normalized': normalizeArabicForSearch(row['text_uthmani'] as String)},
        where: 'surah = ? AND ayah = ?',
        whereArgs: [row['surah'], row['ayah']],
      );
    }
    await batch.commit(noResult: true);
  }

  /// "محاسبة الوقت" v2 (Ismail's request 2026-08-16): replaces the single
  /// self-rated "hours well spent" slider with structured, independent
  /// entries (slept/wasted/studied/worked) that the app computes benefit
  /// vs. loss FROM, instead of asking the student to self-judge a summary
  /// number. `hours_well_spent` is kept (now written as a derived value)
  /// so the existing recent-days trend view keeps working unchanged.
  Future<void> _createV28Tables(Database db) async {
    await db.execute('ALTER TABLE time_awareness_log ADD COLUMN hours_slept REAL');
    await db.execute('ALTER TABLE time_awareness_log ADD COLUMN hours_wasted REAL');
    await db.execute('ALTER TABLE time_awareness_log ADD COLUMN hours_studied REAL');
    await db.execute('ALTER TABLE time_awareness_log ADD COLUMN hours_worked REAL');
  }

  /// "دفتر الفوائد" resume-point safety net (Ismail's request 2026-08-16):
  /// some YouTube videos in the audio library fail to embed entirely
  /// (Error 152, embedding disabled by the uploader) — when that happens
  /// the automatic position-tracking never gets a chance to run either,
  /// since it depends on the player actually loading. A manual free-text
  /// "where did you stop" field (a timestamped link, or just "دقيقة 15")
  /// saved together with the reflection note is a fallback that survives
  /// a broken embed.
  Future<void> _createV29Tables(Database db) async {
    await db.execute('ALTER TABLE audio_reflection_log ADD COLUMN resume_note TEXT');
  }

  /// Optional certificate photo (Ismail's request 2026-08-16) — chosen once
  /// on the profile screen, reused automatically on every generated
  /// certificate rather than re-picked each time.
  Future<void> _createV30Tables(Database db) async {
    await db.execute('ALTER TABLE profile ADD COLUMN photo_path TEXT');
  }

  /// "كم مرة كررتها؟" — repetition counter for today's new سبق (Ismail's
  /// request 2026-08-16, one of 4 new coach features: researched real
  /// repetition guidance first — 10-40 repeats depending on method
  /// [segmented-then-linked vs. whole-page vs. spaced], not invented).
  /// Purely a self-reported tally per (page, day), same non-inferring
  /// spirit as every other self-tracked count in this app.
  Future<void> _createV31Tables(Database db) async {
    await db.execute('''
      CREATE TABLE sabaq_repetition_log (
        unit_id INTEGER NOT NULL,
        log_date TEXT NOT NULL,
        rep_count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (unit_id, log_date)
      )
    ''');
  }

  /// Session-position for the redesigned continuous adhkar reader (Ismail's
  /// 2026-08-16 "تجربة عبادة متصلة" request) — deliberately stores only
  /// which item the student was viewing, not the in-memory repeat counters
  /// (those stay exactly as they already worked: reset to full count on
  /// reopen, unless the category is already completed today). `updated_date`
  /// gates resume to the same Hijri day; a stale row from a previous day is
  /// ignored rather than deleted, since the next save overwrites it anyway.
  Future<void> _createV32Tables(Database db) async {
    await db.execute('''
      CREATE TABLE adhkar_session_position (
        category_id INTEGER PRIMARY KEY REFERENCES adhkar_categories(id),
        item_index INTEGER NOT NULL,
        updated_date TEXT NOT NULL
      )
    ''');
  }

  /// "دفتر الفوائد" + application log for any PDF book opened via
  /// `BookViewerScreen` (personal library or the Telegram-fed `BookScreen`)
  /// — Ismail's 2026-08-16 request, explicitly mirroring the audio
  /// library's existing `audio_reflection_log` pattern rather than
  /// inventing a new one. `book_key` matches whatever key
  /// `BookViewerScreen` already uses (a URL for fed content, `personal_<id>`
  /// for library picks), so no changes were needed to how books identify
  /// themselves. Reflections carry `page` instead of audio's `resume_note`
  /// — books already have a robust auto-saved page bookmark
  /// (`book_bookmarks`), so there's no dead-video-link problem to hedge
  /// against the way audio's manual resume note was for.
  Future<void> _createV33Tables(Database db) async {
    await db.execute('''
      CREATE TABLE book_reflection_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_key TEXT NOT NULL,
        page INTEGER,
        reflection_text TEXT NOT NULL,
        created_date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_book_reflection_log_key ON book_reflection_log(book_key)
    ''');
    await db.execute('''
      CREATE TABLE book_application_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_key TEXT NOT NULL,
        application_text TEXT NOT NULL,
        created_date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_book_application_log_key ON book_application_log(book_key)
    ''');
  }

  /// Content-type/occasion classification for the 134 `adhkar_categories`
  /// rows — Ismail's 2026-08-16 request after critiquing an external
  /// content-ontology proposal he sent, scoped down to what's real for a
  /// single-book dataset (no LOCATION/ACTIVITY trigger engine, no hadith-
  /// authenticity grading — see the roadmap for why those were excluded).
  ///
  /// Purely additive: `content_type` defaults to `'dhikr'` for every
  /// existing row, so nothing that reads `adhkar_categories`/`is_daily_core`
  /// today changes behavior — in particular the three places that hardcode
  /// the exact title "أذكار الصباح والمساء"
  /// (`adhkar_category_screen.dart`'s `_streakTrackedCategoryTitle`,
  /// `adhkar_journey.dart`'s journey suggestions, `wird_repository.dart`'s
  /// raw title lookup) keep working unmodified, since no title is renamed.
  ///
  /// The classification below was done by hand against every one of the
  /// 134 actual titles (not a blind prefix heuristic — several titles like
  /// "التشهد" or "الاستغفار والتوبة" don't carry an obvious دعاء/ذكر
  /// prefix and needed real judgment) — this list *is* the "human review"
  /// step an automated import pipeline would otherwise need.
  Future<void> _createV34Tables(Database db) async {
    await db.execute("ALTER TABLE adhkar_categories ADD COLUMN content_type TEXT NOT NULL DEFAULT 'dhikr'");
    await db.execute('ALTER TABLE adhkar_categories ADD COLUMN occasion TEXT');

    const duaTitles = [
      'دعاء لبس الثوب',
      'دعاء لبس الثوب الجديد',
      'الدعاء لمن لبس ثوباً جديداً',
      'دعاء دخول الخلاء',
      'دعاء الخروج من الخلاء',
      'دعاء الذهاب إلى المسجد',
      'دعاء دخول المسجد',
      'دعاء الخروج من المسجد',
      'دعاء الاستفتاح',
      'دعاء الركوع',
      'دعاء الرفع من الركوع',
      'دعاء السجود',
      'دعاء الجلسة بين السجدتين',
      'دعاء سجود التلاوة',
      'الدعاء بعد التشهد الأخير وقبل السلام',
      'دعاء صلاة الاستخارة',
      'الدعاء إذا تقلب ليلاً',
      'دعاء القلق والفزع في النوم ومن بلي بالوحشة',
      'دعاء قنوت الوتر',
      'دعاء الهم والحزن',
      'دعاء الكرب',
      'دعاء لقاء العدو وذي السلطان',
      'دعاء من خاف ظلم السلطان',
      'الدعاء على العدو',
      'دعاء من أصابه شك في الإيمان',
      'الدعاء قضاء الدين',
      'دعاء الوسوسة في الصلاة والقراءة',
      'دعاء من استصعب عليه أمر',
      'دعاء طرد الشيطان ووساوسه',
      'الدعاء حينما يقع مالا يرضاه أو غلب على أمره',
      'ما يعوذ به الأولاد',
      'الدعاء للمريض في عيادته',
      'دعاء المريض الذي يئس من حياته',
      'دعاء من أصيب بمصيبة',
      'الدعاء عند إغماض الميت',
      'الدعاء للميت في الصلاة عليه',
      'الدعاء للفرط في الصلاة عليه',
      'دعاء التعزية',
      'الدعاء عند إدخال الميت القبر',
      'الدعاء بعد دفن الميت',
      'دعاء زيارة القبور',
      'دعاء الريح',
      'دعاء الرعد',
      'من أدعية الاستسقاء',
      'الدعاء إذا نزل المطر',
      'من أدعية الاستصحاء',
      'دعاء رؤية الهلال',
      'الدعاء عند إفطار الصائم',
      'الدعاء قبل الطعام',
      'الدعاء عند الفراغ من الطعام',
      'دعاء الضيف لصاحب الطعام',
      'الدعاء لمن سقاه أو إذا أراد ذلك',
      'الدعاء إذا أفطر عند أهل بيت',
      'دعاء الصائم إذا حضر الطعام ولم يفطر',
      'الدعاء عند رؤية باكورة الثمر',
      'دعاء العطاس',
      'الدعاء للمتزوج',
      'دعاء المتزوج لنفسه ودعاء شراء الدابة',
      'الدعاء قبل إتيان الزوجة',
      'دعاء الغضب',
      'دعاء من رأى مبتلى',
      'الدعاء لمن قال غفر الله لك',
      'الدعاء لمن صنع إليك معروفاً',
      'ما يعصم به من الدجال',
      'الدعاء لمن قال إني أحبك في الله',
      'الدعاء لمن عرض عليك ماله',
      'الدعاء لمن أقرض عند القضاء',
      'دعاء الخوف من الشرك',
      'الدعاء لمن قال بارك الله فيك',
      'دعاء كراهية الطيرة',
      'دعاء ركوب الدابة',
      'دعاء السفر',
      'دعاء دخول القرية أو البلدة',
      'دعاء دخول السوق',
      'الدعاء إذا تعس المركوب',
      'دعاء المسافر للمقيم',
      'دعاء المقيم للمسافر',
      'دعاء المسافر إذا أسحر',
      'الدعاء إذا نزل منزلا في سفر أو غيره',
      'دعاء صياح الديك ونهيق الحمار',
      'دعاء نباح الكلاب بالليل',
      'الدعاء لمن سببته',
      'الدعاء بين الركن اليماني والحجر الأسود',
      'دعاء الوقوف على الصفا والمروة',
      'الدعاء يوم عرفة',
      'دعاء من خشي أن يصيب شيئاً بعينه',
    ];

    const otherTitles = [
      'المقدمة',
      'فضل الذكر',
      'ما يفعل من رأى الرؤيا أو الحلم',
      'تهنئة المولود له وجوابه',
      'فضل عيادة المريض',
      'تلقين المحتضر',
      'فضل الصلاة على النبي صلى الله عليه وسلم',
      'إفشاء السلام',
      'كيف يرد السلام على الكافر إذا سلم',
      'ما يفعل من أتاه أمر يسره',
      'كيف كان النبي صلى الله عليه وسلم يسبح ؟',
      'من أنواع الخير والآداب الجامعة',
    ];

    const occasionTitles = {
      'travel': [
        'دعاء ركوب الدابة',
        'دعاء السفر',
        'دعاء دخول القرية أو البلدة',
        'دعاء دخول السوق',
        'الدعاء إذا تعس المركوب',
        'دعاء المسافر للمقيم',
        'دعاء المقيم للمسافر',
        'التكبير والتسبيح في سير السفر',
        'دعاء المسافر إذا أسحر',
        'الدعاء إذا نزل منزلا في سفر أو غيره',
        'ذكر الرجوع من السفر',
      ],
      'funeral': [
        'دعاء المريض الذي يئس من حياته',
        'تلقين المحتضر',
        'دعاء من أصيب بمصيبة',
        'الدعاء عند إغماض الميت',
        'الدعاء للميت في الصلاة عليه',
        'الدعاء للفرط في الصلاة عليه',
        'دعاء التعزية',
        'الدعاء عند إدخال الميت القبر',
        'الدعاء بعد دفن الميت',
        'دعاء زيارة القبور',
      ],
      'hajj': [
        'كيف يلبي المحرم في الحج أو العمرة',
        'التكبيرة إذا أتي الركن الأسود',
        'الدعاء بين الركن اليماني والحجر الأسود',
        'دعاء الوقوف على الصفا والمروة',
        'الدعاء يوم عرفة',
        'الذكر عند المشعر الحرام',
        'التكبيرة عند رمي الجمار مع كل حصاة',
      ],
      'food': [
        'الدعاء عند إفطار الصائم',
        'الدعاء قبل الطعام',
        'الدعاء عند الفراغ من الطعام',
        'دعاء الضيف لصاحب الطعام',
        'الدعاء لمن سقاه أو إذا أراد ذلك',
        'الدعاء إذا أفطر عند أهل بيت',
        'دعاء الصائم إذا حضر الطعام ولم يفطر',
        'ما يقول الصائم إذا سابه أحد',
        'الدعاء عند رؤية باكورة الثمر',
      ],
    };

    final batch = db.batch();
    for (final t in duaTitles) {
      batch.update('adhkar_categories', {'content_type': 'dua'}, where: 'title = ?', whereArgs: [t]);
    }
    for (final t in otherTitles) {
      batch.update('adhkar_categories', {'content_type': 'other'}, where: 'title = ?', whereArgs: [t]);
    }
    for (final entry in occasionTitles.entries) {
      for (final t in entry.value) {
        batch.update('adhkar_categories', {'occasion': entry.key}, where: 'title = ?', whereArgs: [t]);
      }
    }
    await batch.commit(noResult: true);
  }

  /// Generalized spaced-repetition table for pillars beyond Quran
  /// memorization — Ismail's 2026-08-16 "الدماغ الذي يربط" request, Batch 1
  /// (`spaced_repetition_engine.dart`/`KnowledgeReviewRepository`). Deliberately
  /// a separate table from `memorization_progress` rather than a shared one:
  /// the Quran engine and its 604-row table stay completely untouched (zero
  /// migration risk to existing data), and `item_type` disambiguates which
  /// pillar's items this generalized table is reviewing (`'hadith'` →
  /// `hadith_progress.hadith_id`, `'wasitiyyah'` → `wasitiyyah_progress.section_id`).
  /// Same station/date columns as `memorization_progress` by design, so the
  /// pure `spaced_repetition_engine.dart` logic (extracted from
  /// `MemorizationRepository.recordReview`) applies unchanged to both tables.
  Future<void> _createV35Tables(Database db) async {
    await db.execute('''
      CREATE TABLE knowledge_review_progress (
        item_type TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'not_started',
        station INTEGER,
        last_review_date TEXT,
        next_review_date TEXT,
        consecutive_good_count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (item_type, item_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_knowledge_review_next ON knowledge_review_progress(next_review_date)');
  }

  /// "التسبيح" free-tap dhikr counter — Ismail's 2026-08-16 request after
  /// reviewing a reference app's design: a genuinely missing feature, not
  /// decoration (grep-confirmed zero existing tasbih/counter screen —
  /// adhkar's per-item tap-counters are structured/scripted content, not a
  /// free-form "count any phrase toward any target" tool). One row per
  /// (date, phrase) so switching phrase mid-day keeps each count separate,
  /// same "count resets are just a fresh date-keyed row" pattern as every
  /// other daily-completion table in this app (`adhkar_completion` etc.).
  Future<void> _createV36Tables(Database db) async {
    await db.execute('''
      CREATE TABLE tasbih_log (
        log_date TEXT NOT NULL,
        phrase_key TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (log_date, phrase_key)
      )
    ''');
  }

  /// "رسالتي" (إيكيغاي طالب العلم) — Ismail's 2026-08-17 request, an
  /// expansion of the already-approved-but-unbuilt "اختبار تحديد المستوى"
  /// (Batch 2 of the "الدماغ الذي يربط" plan) to also capture interest
  /// ("ماذا تحب") and a one-year mission, not just a bare skill rating.
  /// `placement_ratings` is re-assessable (upsert by area, no history row
  /// pile-up, same pattern as `journey_plan`'s singleton row).
  Future<void> _createV37Tables(Database db) async {
    await db.execute('''
      CREATE TABLE placement_ratings (
        area TEXT PRIMARY KEY,
        rating INTEGER NOT NULL,
        interest INTEGER NOT NULL DEFAULT 0,
        assessed_date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE student_mission (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        daily_minutes INTEGER,
        one_year_goal TEXT,
        assessed_date TEXT NOT NULL
      )
    ''');
  }

  /// Custom per-category adhkar reminders — Ismail's 2026-08-17 request to
  /// go beyond the 3 fixed morning/evening/sleep notifications and let him
  /// pick ANY dhikr category (from either the category's own reading
  /// screen, or the notification settings screen) and give it its own
  /// reminder. `category_id` is the primary key — one reminder per
  /// category, re-adding just updates the hour (upsert).
  Future<void> _createV38Tables(Database db) async {
    await db.execute('''
      CREATE TABLE custom_adhkar_reminders (
        category_id INTEGER PRIMARY KEY,
        hour INTEGER NOT NULL
      )
    ''');
  }

  /// "عرض الحزب" (100_IDEAS_FOR_IMPROVEMENT.md #17) — additive column only;
  /// existing installs get it backfilled below, fresh installs get it
  /// filled directly by `QuranImportService` during its normal import pass
  /// (same as `juz_number`/`page_number`), so this ALTER is safe to run
  /// unconditionally in both onCreate and onUpgrade.
  Future<void> _createV39Tables(Database db) async {
    await db.execute('ALTER TABLE quran_ayat ADD COLUMN hizb_number INTEGER');
  }

  /// Backfill for installs that already had `quran_ayat` populated before
  /// this column existed. Reuses `assets/quran/quran-data.js`'s
  /// `QuranData.HizbQaurter` boundaries (same bundled Tanzil data
  /// `QuranImportService` already parses for Juz/Page) — 240 quarter-hizb
  /// (ربع الحزب) boundaries in Mushaf order; a Hizb is 4 quarters, so
  /// `hizb = ((quarterIndex - 1) ~/ 4) + 1`. No-op on a fresh install
  /// (`quran_ayat` still empty at this point — `QuranImportService` runs
  /// after the DB opens, not during this migration).
  Future<void> _backfillHizbNumbersV39(Database db) async {
    final existing = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM quran_ayat'));
    if (existing == null || existing == 0) return;

    final raw = await rootBundle.loadString('assets/quran/quran-data.js');
    final start = raw.indexOf('QuranData.HizbQaurter = [');
    final end = raw.indexOf('];', start);
    final block = raw.substring(start, end);
    final pairRegex = RegExp(r'\[\s*(\d+)\s*,\s*(\d+)\s*\]');
    final quarters = pairRegex.allMatches(block).map((m) => (int.parse(m.group(1)!), int.parse(m.group(2)!))).toList();

    final rows = await db.query('quran_ayat', columns: ['surah', 'ayah']);
    final batch = db.batch();
    for (final row in rows) {
      final surah = row['surah'] as int;
      final ayah = row['ayah'] as int;
      var quarterIndex = 1;
      for (var i = 0; i < quarters.length; i++) {
        final (qSurah, qAyah) = quarters[i];
        if (qSurah < surah || (qSurah == surah && qAyah <= ayah)) quarterIndex = i + 1;
      }
      final hizb = (quarterIndex - 1) ~/ 4 + 1;
      batch.update('quran_ayat', {'hizb_number': hizb}, where: 'surah = ? AND ayah = ?', whereArgs: [surah, ayah]);
    }
    await batch.commit(noResult: true);
  }

  /// Multi-language tafsir/translation library, batch 1 (Amharic + English)
  /// — quirky-gliding-shell.md's "مكتبة التفسير/الترجمة متعددة اللغات" plan.
  /// Additive column only; the 4 existing Arabic editions all default to
  /// `'ar'`, which is already correct for them — no backfill needed.
  Future<void> _createV40Tables(Database db) async {
    await db.execute("ALTER TABLE tafsir_entries ADD COLUMN language TEXT NOT NULL DEFAULT 'ar'");
  }

  /// CUSTOMIZATION_IDEAS.md #1 — the tasbih counter only ever offered 6
  /// fixed phrases; students who want to count a dhikr not on that list
  /// (or a personal supplication) had no way to. `text` stores the phrase
  /// itself as the identifier (no separate key needed — nothing else
  /// references custom phrases by id).
  Future<void> _createV43Tables(Database db) async {
    await db.execute('''
      CREATE TABLE custom_tasbih_phrases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// QURAN_COMPANION_ROADMAP.md §4.36 — "اريد ان يتذكره ويكون صديقه"
  /// (Ismail, 2026-08-18): the companion chat engine was stateless (every
  /// reply picked fresh, nothing carried over). `companion_memory` is a
  /// tiny key-value store for durable facts (currently just the student's
  /// name, once they introduce themselves); `companion_chat_log` keeps a
  /// rolling history of what was said and which intent matched, so the
  /// engine can reference "what we talked about last time" instead of
  /// greeting the student as a stranger every single message.
  Future<void> _createV44Tables(Database db) async {
    await db.execute('''
      CREATE TABLE companion_memory (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE companion_chat_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        user_text TEXT NOT NULL,
        intent_id TEXT
      )
    ''');
  }

  /// "تسميع" — Phase 76.3 of TODO.md, the recitation-practice checker.
  /// `recitation_sessions` is one row per practice attempt (student recites
  /// one ayah, gets scored); `recitation_mistakes` is the per-word detail
  /// behind that score — real, timestamped data the mistake-history/
  /// frequency view (76.3e, mirroring Tarteel's real shipped feature) reads
  /// from. Deliberately separate from `memorization_review_log` — a
  /// recitation mistake (said the wrong word) and a memorization-quality
  /// self-rating are different concepts, not the same table reused.
  Future<void> _createV45Tables(Database db) async {
    await db.execute('''
      CREATE TABLE recitation_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        mode TEXT NOT NULL,
        score REAL NOT NULL,
        extra_word_count INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE recitation_mistakes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        word_index INTEGER NOT NULL,
        expected_word TEXT NOT NULL,
        said_word TEXT,
        status TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES recitation_sessions (id)
      )
    ''');
  }

  /// Local persistence for the Turath library (Phase 79 spec items 10-14,
  /// 17-19: favorites, last-read position, personal notes, and an
  /// offline-capable page/book cache limited to what's actually been
  /// visited -- never the whole library). All keyed by `book_id`/
  /// `page_number` from the real turath.io API, never invented IDs.
  Future<void> _createV46Tables(Database db) async {
    await db.execute('''
      CREATE TABLE turath_favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        book_id INTEGER NOT NULL,
        book_name TEXT NOT NULL,
        page_number INTEGER,
        created_at TEXT NOT NULL,
        UNIQUE(type, book_id, page_number)
      )
    ''');
    await db.execute('''
      CREATE TABLE turath_last_read (
        book_id INTEGER PRIMARY KEY,
        book_name TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE turath_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        book_name TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        selected_text TEXT,
        note TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE turath_book_cache (
        book_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        info TEXT,
        volumes_json TEXT NOT NULL,
        indexes_json TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE turath_page_cache (
        book_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        volume TEXT NOT NULL,
        text TEXT NOT NULL,
        headings_json TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        PRIMARY KEY (book_id, page_number)
      )
    ''');
  }

  /// Quotes and benefits (Ismail 2026-08-29: "أين نظام الاقتباسات؟... هذا
  /// مهم جدًا لطالب العلم") -- deliberately separate tables from
  /// `turath_notes` (v46): a quote is a saved excerpt with its real
  /// citation (book/author/volume/page), a benefit is a standalone
  /// learning takeaway that may or may not have a source. Different data,
  /// different screens, not the same concept reused.
  Future<void> _createV47Tables(Database db) async {
    await db.execute('''
      CREATE TABLE turath_quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        book_name TEXT NOT NULL,
        author_name TEXT,
        volume TEXT,
        page_number INTEGER NOT NULL,
        quoted_text TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE turath_benefits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        topic TEXT,
        source_book_id INTEGER,
        source_book_name TEXT,
        source_page_number INTEGER,
        source_quote_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (source_quote_id) REFERENCES turath_quotes (id)
      )
    ''');
  }

  /// Phase 79 `79-membership-index` — the local canonical catalog of the
  /// turath.io library, seeded from `assets/turath/catalog-v3.json.gz`
  /// (turath.io's own `files.turath.io/data-v3.json` manifest) and later
  /// refreshed from the network by `TurathCatalogSync`. This is what makes a
  /// category's book count *deterministic*: the count is read straight from
  /// `total_books` / the `turath_catalog_category_books` join table, never
  /// counted from full-text search results (Ismail 2026-08-29: "Stop
  /// treating full-text search as the source of truth for category
  /// membership"). Kept entirely separate from the local user-data tables
  /// (`turath_favorites`/`turath_notes`/…) — this holds only the upstream
  /// library index, rebuilt wholesale on each sync.
  Future<void> _createV48Tables(Database db) async {
    await db.execute('''
      CREATE TABLE turath_catalog_categories (
        cat_id INTEGER PRIMARY KEY,
        name_ar TEXT NOT NULL,
        total_books INTEGER NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE turath_catalog_authors (
        author_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        death_year INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE turath_catalog_books (
        book_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        author_id INTEGER,
        cat_id INTEGER NOT NULL,
        has_pdf INTEGER NOT NULL DEFAULT 0,
        page_count INTEGER,
        size INTEGER
      )
    ''');
    await db.execute('CREATE INDEX idx_turath_catalog_books_cat ON turath_catalog_books(cat_id, name)');
    await db.execute('CREATE INDEX idx_turath_catalog_books_author ON turath_catalog_books(author_id)');
    // Explicit membership relation with a unique (cat_id, book_id) key --
    // redundant with turath_catalog_books.cat_id while every book sits in
    // exactly one category (true in the 2026-02-03 manifest), but kept as a
    // real join table so multi-category membership needs no schema change
    // later (Ismail's explicit instruction).
    await db.execute('''
      CREATE TABLE turath_catalog_category_books (
        cat_id INTEGER NOT NULL,
        book_id INTEGER NOT NULL,
        PRIMARY KEY (cat_id, book_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE turath_catalog_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Phase 79 «علامات الدراسة» / Study Annotations
  /// (`docs/STUDY_ANNOTATIONS_DESIGN.md`). One anchored model that replaces
  /// the three overlapping "keep this" tables (`turath_notes`,
  /// `turath_quotes`, and sourced `turath_benefits`). Three layers in one
  /// row: `selected_text` = the FULL selection verbatim (never a first-word
  /// fragment); the anchor columns = where it is / how to re-find it after
  /// the page text drifts; `color_key` + `note_*` = the highlight and its
  /// note. Legacy rows are copied in by `migrateLegacyToAnnotations` on
  /// upgrade; the old tables stay as a read-only safety net for one release.
  Future<void> _createV49Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS turath_annotations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        span_group_id TEXT,
        book_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        volume TEXT,
        selected_text TEXT,
        selected_len INTEGER,
        char_start INTEGER,
        char_end INTEGER,
        norm_version INTEGER NOT NULL DEFAULT 0,
        text_checksum TEXT,
        text_length INTEGER,
        prefix_context TEXT,
        suffix_context TEXT,
        head_anchor TEXT,
        tail_anchor TEXT,
        occurrence_index INTEGER NOT NULL DEFAULT 0,
        color_key TEXT NOT NULL DEFAULT 'benefit',
        note_type TEXT,
        note_body TEXT,
        anchor_status TEXT NOT NULL DEFAULT 'exact',
        source_kind TEXT NOT NULL DEFAULT 'annotation',
        legacy_id INTEGER,
        book_name TEXT NOT NULL,
        author_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_turath_annotations_page ON turath_annotations(book_id, page_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_turath_annotations_color ON turath_annotations(color_key)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_turath_annotations_group ON turath_annotations(span_group_id)');
    // Standalone benefits leave this NULL; a benefit promoted from a
    // highlight points back at its annotation. Guarded: SQLite has no
    // "ADD COLUMN IF NOT EXISTS", and a partial earlier run of this
    // migration may have already added it — a duplicate-column error here
    // must not fail the whole database open.
    try {
      await db.execute('ALTER TABLE turath_benefits ADD COLUMN annotation_id INTEGER');
    } catch (_) {/* column already present */}
  }

  /// Phase 79 `79-sa-D-ayah` — Quran Ayah Study Notebook
  /// (`docs/AYAH_STUDY_NOTEBOOK_DESIGN.md`). A per-ayah study page that
  /// accumulates the student's own tafsir excerpts, meanings, benefits,
  /// questions, lesson summaries and links over the years. Anchor is
  /// numeric `(surah, ayah[, word range])` — never drifts, so no
  /// re-anchoring engine. Structurally symmetric to `turath_annotations`
  /// (stable id, timestamps, typed) but a separate table on purpose:
  /// unification into one `StudyItem` model is a later, clean merge. Does
  /// NOT touch `turath_annotations`, `quran_ayat`, `tafsir_entries`.
  Future<void> _createV50Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ayah_study_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        word_start INTEGER,
        word_end INTEGER,
        entry_type TEXT NOT NULL DEFAULT 'personal',
        topic TEXT,
        stance TEXT,
        color_key TEXT,
        body TEXT NOT NULL,
        source_type TEXT,
        source_name TEXT,
        source_author TEXT,
        source_ref TEXT,
        source_date TEXT,
        source_detail TEXT,
        status TEXT NOT NULL DEFAULT 'none',
        resolved_at TEXT,
        sort_order INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ayah_entries_ayah ON ayah_study_entries(surah, ayah)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ayah_entries_type ON ayah_study_entries(entry_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ayah_entries_status ON ayah_study_entries(status)');
    // Reserved for future typed cross-links; ships empty (a `link` entry
    // just holds free text in `body` for v1).
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ayah_entry_links (
        entry_id INTEGER NOT NULL,
        target_kind TEXT NOT NULL,
        target_id TEXT NOT NULL,
        rel TEXT,
        PRIMARY KEY (entry_id, target_kind, target_id)
      )
    ''');
  }

  /// Phase 79 `79-mushaf` — the **Semantic Layer** of the 604-page Madani
  /// Mushaf (`docs/MUSHAF_DATABASE_INTEGRATION_DESIGN.md`). Every word is
  /// addressable `page → line → word → ayah → surah`, keeping its Uthmani
  /// (`hafs`) and simplified (`imlaey`) forms, its `word_index` within the
  /// ayah (verbatim from the MushafDatabase dataset) and a geometric bbox in
  /// the source `viewBox`. Purely structural data — **not coupled to any
  /// rendering method**: the box columns are only a hit-test / highlight aid
  /// a renderer may use or ignore. Seeded once from the bundled
  /// `assets/mushaf/mushaf_layout.json.gz` by `MushafLayoutSync`, after
  /// internal validation (604 pages, contiguous per-ayah word_index, 6236
  /// ayah marks, per-surah counts vs the canonical list). Independent of
  /// `quran_ayat`, the polygon-JSON reader, and the Phase 71 own-engine
  /// renderer — those stay untouched until this layer is verified on device.
  Future<void> _createV51Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mushaf_pages (
        page INTEGER PRIMARY KEY,
        rect_x REAL, rect_y REAL, rect_w REAL, rect_h REAL,
        vb_w REAL NOT NULL,
        vb_h REAL NOT NULL,
        line_count INTEGER NOT NULL,
        surah_first INTEGER NOT NULL,
        surah_last INTEGER NOT NULL,
        ayah_first INTEGER NOT NULL,
        ayah_last INTEGER NOT NULL,
        word_count INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mushaf_lines (
        page INTEGER NOT NULL,
        line INTEGER NOT NULL,
        line_type TEXT NOT NULL,
        PRIMARY KEY (page, line)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mushaf_words (
        page INTEGER NOT NULL,
        line INTEGER NOT NULL,
        word_order INTEGER NOT NULL,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        word_index INTEGER NOT NULL,
        word_type TEXT NOT NULL DEFAULT 'text',
        text_uthmani TEXT NOT NULL,
        text_imlaey TEXT NOT NULL,
        bbox_x REAL NOT NULL, bbox_y REAL NOT NULL, bbox_w REAL NOT NULL, bbox_h REAL NOT NULL,
        PRIMARY KEY (page, word_order)
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mushaf_words_ayah ON mushaf_words(surah, ayah)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mushaf_words_page ON mushaf_words(page)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mushaf_aya_marks (
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        page INTEGER NOT NULL,
        line INTEGER NOT NULL,
        bbox_x REAL, bbox_y REAL, bbox_w REAL, bbox_h REAL,
        PRIMARY KEY (surah, ayah)
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mushaf_aya_marks_page ON mushaf_aya_marks(page)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mushaf_markers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        page INTEGER NOT NULL,
        kind TEXT NOT NULL,
        line INTEGER,
        surah INTEGER,
        bbox_x REAL, bbox_y REAL, bbox_w REAL, bbox_h REAL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mushaf_markers_page ON mushaf_markers(page)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mushaf_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Phase 79 `79-ql` — the **Quran Learning Layer** (`docs/quran/QURAN_LEARNING_LAYER.md`).
  /// The mushaf becomes an entry point to organised study: a tapped word
  /// resolves to sourced ṣarf / naḥw / tajwīd facts, "تعلّم هذا" opens a
  /// concept lesson in the student's notebook, and "طبّق" returns to the
  /// same `(surah, ayah, word_index)`. Deterministic — every fact carries a
  /// `source_ref_id`; nothing is AI-generated. Additive only: `mushaf_*`,
  /// `quran_ayat`, `tafsir_entries`, `ayah_study_entries` structure are all
  /// untouched (one guarded `ALTER` adds `ayah_study_entries.concept_id`).
  Future<void> _createV52Tables(Database db) async {
    // Provenance registry — nothing scholarly is stored/shown without one.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS source_references (
        id TEXT PRIMARY KEY,
        source_type TEXT NOT NULL,
        name TEXT NOT NULL,
        author TEXT,
        book TEXT,
        edition TEXT,
        volume TEXT,
        page TEXT,
        reference TEXT,
        url TEXT,
        license TEXT NOT NULL,
        license_use TEXT NOT NULL DEFAULT 'unknown',
        authority TEXT,
        retrieved_at TEXT,
        confidence REAL NOT NULL DEFAULT 0.0,
        classification TEXT NOT NULL DEFAULT 'UNKNOWN',
        notes TEXT
      )
    ''');
    // One verified scholarly fact, anchored to a word / range / ayah.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_facts (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        word_start INTEGER,
        word_end INTEGER,
        char_start INTEGER,
        char_end INTEGER,
        scope TEXT NOT NULL DEFAULT 'word',
        segmentation TEXT NOT NULL DEFAULT 'mushafdb-v1.01',
        mapping_status TEXT NOT NULL DEFAULT 'mapped',
        payload_json TEXT NOT NULL,
        source_ref_id TEXT NOT NULL,
        data_state TEXT NOT NULL DEFAULT 'local'
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_knowledge_facts_anchor ON knowledge_facts(surah, ayah, word_start)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_knowledge_facts_domain ON knowledge_facts(domain)');
    // Organised teaching material — a concept and its lesson blocks.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_concepts (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        title_ar TEXT NOT NULL,
        short_def_ar TEXT,
        blocks_json TEXT NOT NULL,
        source_ref_ids_json TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'authored'
      )
    ''');
    // A concept the student chose to learn, originating from a mushaf spot.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS learning_path_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        concept_id TEXT NOT NULL,
        origin_surah INTEGER NOT NULL,
        origin_ayah INTEGER NOT NULL,
        origin_word_start INTEGER,
        origin_word_end INTEGER,
        state TEXT NOT NULL DEFAULT 'learning',
        first_opened_at TEXT NOT NULL,
        last_touched_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_learning_path_concept ON learning_path_items(concept_id)');
    // Append-only interaction log — feeds the future maths engine.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts TEXT NOT NULL,
        verb TEXT NOT NULL,
        target_kind TEXT NOT NULL,
        target_id TEXT NOT NULL,
        surah INTEGER,
        ayah INTEGER,
        word_start INTEGER,
        layer TEXT,
        dwell_ms INTEGER,
        meta_json TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_study_events_target ON study_events(target_kind, target_id)');
    // HYBRID/ONLINE providers cache here, per each source's terms.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_cache (
        cache_key TEXT PRIMARY KEY,
        payload_json TEXT NOT NULL,
        source_ref_id TEXT NOT NULL,
        source_version TEXT,
        fetched_at TEXT NOT NULL,
        expires_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quran_learning_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    // Link a notebook entry to a concept it's about (nullable; SQLite has
    // no "ADD COLUMN IF NOT EXISTS", so guard against a partial re-run).
    try {
      await db.execute('ALTER TABLE ayah_study_entries ADD COLUMN concept_id TEXT');
    } catch (_) {/* column already present */}
  }

  /// «مساجدنا» (Phase 74) — the local layer of the mosque platform. Kept
  /// deliberately lean (`docs/MOSQUE_PLATFORM_VISION.md`: "do NOT create
  /// 15 tables up front"): one row per mosque, its data-driven sections,
  /// one polymorphic content table (lessons / khutbahs / announcements /
  /// recordings / library / needs / activities — `kind` + optional event
  /// columns), and a separate media table so photos never mix with text
  /// content. Offline-first: these are the read-cache of whatever backend
  /// Phase 4 picks; `synced_at` marks server-sourced rows, and a single
  /// seeded demo mosque lets the UI work before any backend exists. The
  /// backend, not `chat_id`, owns mosque identity — `id` is permanent.
  Future<void> _createV53Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mosques (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        imam_name TEXT,
        description TEXT,
        city TEXT,
        area TEXT,
        lat REAL,
        lng REAL,
        phone TEXT,
        image_url TEXT,
        verified INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        is_mine INTEGER NOT NULL DEFAULT 0,
        is_demo INTEGER NOT NULL DEFAULT 0,
        synced_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mosque_sections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mosque_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        icon TEXT,
        enabled INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        UNIQUE(mosque_id, type)
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mosque_sections_mosque ON mosque_sections(mosque_id)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mosque_content (
        id TEXT PRIMARY KEY,
        mosque_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        title TEXT,
        description TEXT,
        media_url TEXT,
        media_kind TEXT,
        event_date TEXT,
        starts_at TEXT,
        ends_at TEXT,
        location TEXT,
        organizer TEXT,
        status TEXT NOT NULL DEFAULT 'published',
        pinned INTEGER NOT NULL DEFAULT 0,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mosque_content_mosque_kind ON mosque_content(mosque_id, kind, status)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mosque_media (
        id TEXT PRIMARY KEY,
        mosque_id TEXT NOT NULL,
        category TEXT NOT NULL,
        content_id TEXT,
        url TEXT NOT NULL,
        caption TEXT,
        date TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mosque_media_mosque ON mosque_media(mosque_id, category)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mosque_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// 100_IDEAS_FOR_IMPROVEMENT.md #70 — `quran_ayat.page_number` is queried
  /// on every single page turn (`QuranReadingRepository.ayatForPage`) but
  /// had no index, forcing a full scan of all 6236 rows each time. Real,
  /// verified gap (checked the actual query, not guessed), not a blind
  /// "index everything" pass.
  Future<void> _createV42Tables(Database db) async {
    await db.execute('CREATE INDEX idx_quran_ayat_page ON quran_ayat(page_number)');
  }

  /// Daily Quran-reading minutes target/countdown — Ismail's 2026-08-17
  /// "gym coach" request: the student sets how many minutes they'll read
  /// today, the app counts down on the reading screen itself, and on
  /// completion compares against yesterday's `completed_minutes` to decide
  /// which encouragement pool (`reading_encouragement.dart`) to draw from.
  /// One row per day (`date` is the primary key), same upsert pattern as
  /// `daily_session_log`.
  Future<void> _createV41Tables(Database db) async {
    await db.execute('''
      CREATE TABLE quran_reading_minutes_log (
        date TEXT PRIMARY KEY,
        target_minutes INTEGER NOT NULL,
        completed_minutes INTEGER NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
