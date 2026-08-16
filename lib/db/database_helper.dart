import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/arabic_normalize.dart';

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
      version: 32,
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
}
