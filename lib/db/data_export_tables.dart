/// Classification of every table for the user-data backup (Stabilization M3,
/// `UserDataExportService`). Two disjoint sets that must together cover
/// every table a fresh `onCreate` builds — `test/user_data_export_test.dart`
/// fails if a new table is added without being classified here.
///
///  * [kUserOwnedTables] — the student's own data (progress, notes,
///    bookmarks, hifz, logs, settings, custom entries). **Exported.**
///  * [kSeededOrCacheTables] — content re-seeded from bundled assets by the
///    `*Sync` / import services, or caches rebuilt on demand. **Not
///    exported** — a restore re-seeds them.
///
/// Rule of thumb: if losing the row on a device change would lose something
/// the user *did*, it is user-owned.
library;

/// The student's own data. A backup contains exactly these tables.
const Set<String> kUserOwnedTables = {
  // identity / settings
  'profile',
  'student_mission', // رسالتي (ikigai text)
  // memorization + review (the core value)
  'memorization_progress',
  'review_log',
  'mistake_log',
  'sabaq_repetition_log',
  'recitation_mistakes',
  'recitation_sessions',
  'hifz_surah_status',
  'hifz_daily_log',
  'hifz_students',
  'hifz_student_fields',
  'placement_ratings',
  // daily flow / planning / accountability
  'daily_session_log',
  'daily_tasks',
  'journey_plan',
  'completion_goals',
  'personal_accountability',
  'time_awareness_log',
  'study_events',
  'learning_path_items', // verify: user-arranged path items
  // understanding / application / practical
  'understanding_progress',
  'application_log',
  'book_application_log',
  // notebooks / notes / links (Quran + books + turath)
  'ayah_study_entries',
  'ayah_entry_links',
  'book_bookmarks',
  'book_reflection_log',
  'quran_favorites',
  'turath_annotations',
  'turath_notes',
  'turath_quotes',
  'turath_benefits',
  'turath_favorites',
  'turath_last_read',
  // reading progress
  'quran_reading_progress',
  'quran_reading_minutes_log',
  // adhkar / dhikr / wird / salah
  'adhkar_completion',
  'adhkar_session_position',
  'wird_selection',
  'istighfar_log',
  'tasbih_log',
  'custom_tasbih_phrases',
  'custom_adhkar_reminders',
  'salah_log',
  'salah_self_assessment',
  'salah_library_progress',
  // curriculum / text-library progress
  'arabic_curriculum_progress',
  'tajweed_progress',
  'guide_progress',
  'hadith_progress',
  'wasitiyyah_progress',
  'zad_almaad_progress',
  'madarij_progress',
  'knowledge_review_progress',
  // audio
  'audio_progress',
  'audio_reflection_log',
  'custom_audio_series',
  // companion
  'companion_memory',
  'companion_chat_log',
  // achievements
  'achievement_milestones', // carries achieved_date; re-seed does not re-run after a wipe
  // personal library (metadata rows; the PDF files themselves are on disk, not in the DB)
  'personal_books',
  'personal_book_categories',
  // life plan (Ismail's personal data)
  'life_meta',
  'life_pillars',
  'life_slots',
  'life_day_slots',
  'life_day_notes',
  // mosque — only the "my mosque" choice is user state
  'mosque_meta',
  // added after the first version of this list (2026-11-12, schema v73)
  'akhlaq_attempt', 'akhlaq_progress', 'akhlaq_sr_state',
  'akhlaq_meta', // the virtue the student chose to focus on
  'completion_goal_sessions', 'completion_goal_progress', // khatma plans + their log
  'life_tasks', 'life_task_log', 'life_day_mit', // life engine tasks + «أهمّ 3»
  'med_courses', 'med_doses', // «علاجاتي»
  'activities', 'goals', // «الأنشطة» / «الأهداف» tabs
  'reading_progress', 'quiz_results', // book reading position + quiz scores
};

/// Content seeded from bundled assets, or caches. A restore re-seeds these
/// (via the `*Sync` classes on next launch) rather than importing them.
const Set<String> kSeededOrCacheTables = {
  // Quran text + tafsir (Tanzil / Ibn Kathir)
  'quran_ayat', 'tafsir_entries', 'quran_surah_info',
  // Quran Corpus (QuranCorpusSync)
  'quran_align', 'quran_asbab', 'quran_asbab_book', 'quran_book',
  'quran_corpus_meta', 'quran_fatwa', 'quran_irab_book', 'quran_irab_prose',
  'quran_learning_meta', 'quran_reciter', 'quran_riwaya', 'quran_tafsir_book',
  'quran_tajweed', 'quran_topic', 'quran_topic_ayah',
  'quran_translation_edition',
  'quran_morphology', 'quran_syntax', 'quran_word_meaning', 'quran_note',
  'quran_qiraat', 'quran_similar', 'quran_saying', 'quran_nasekh',
  // Mushaf semantic layer (MushafLayoutSync)
  'mushaf_meta', 'mushaf_pages', 'mushaf_lines', 'mushaf_words',
  'mushaf_markers', 'mushaf_aya_marks', 'mushaf_glyphs',
  // seeded reference texts
  'nawawi_hadiths', 'wasitiyyah_sections', 'zad_almaad_chapters',
  'madarij_sections', 'practical_lessons', 'adhkar_categories', 'adhkar_items',
  'source_references',
  // knowledge index (derived from the corpus) + the usul tree's relations
  'knowledge_concepts', 'knowledge_facts', 'knowledge_cache', 'knowledge_relations',
  // memorization units — 604 fixed pages, auto-generated
  'memorization_units',
  // turath.io catalog (TurathCatalogSync) + on-demand page/book caches
  'turath_catalog_meta', 'turath_catalog_authors', 'turath_catalog_books',
  'turath_catalog_categories', 'turath_catalog_category_books',
  'turath_book_cache', 'turath_page_cache',
  // mosque platform content (synced / demo)
  'mosques', 'mosque_content', 'mosque_media', 'mosque_sections',
};

/// Tables that only ever exist on the upgrade path (see
/// `db_migration_test.dart`) — never created by a current `onCreate`, so
/// never part of a fresh install's schema and never exported.
const Set<String> kMigrationOnlyTables = {
  'report_drafts',
  'submission_queue',
};

/// Tables built on a fresh install that hold nothing worth backing up.
/// Empty: the four DawahReport-era tables once listed here (`activities`,
/// `goals`, `reading_progress`, `quiz_results`) turned out to be live —
/// «الأنشطة» and «الأهداف» tabs, book progress and quiz scores — so they
/// moved to [kUserOwnedTables] (2026-11-12).
const Set<String> kLegacyUnusedTables = {};

/// The person's own choices kept in SharedPreferences (not the database):
/// language, text size, mushaf view, prayer method, reminder settings, the
/// hifz plan, menu pins… A backup carries exactly these. Internal markers
/// (`seed_version`, `packs_*`, schedule ledgers, caches, the last GPS fix)
/// are deliberately absent: restoring one onto a fresh install could make
/// it think content is already imported. A new user-facing preference must
/// be added here to survive a phone change.
const Set<String> kBackupPrefKeys = {
  'app_ui_language', 'app_text_scale', 'use_gregorian_calendar',
  'has_seen_onboarding', 'student_name', 'hidden_home_cards', 'hidden_book_ids',
  'drawer_pinned', 'drawer_recent', 'start_screen',
  // mushaf / reading
  'mushaf_view_vertical', 'mushaf_vertical_zoom', 'mushaf_paper_tone', 'mushaf_tajweed_mode',
  'mushaf_auto_speed', 'mushaf_repeat_ayah', 'mushaf_last_page', 'mushaf_bookmarks_v1',
  'mushaf_goto_recent_v1', 'keep_screen_on_reading', 'quran_reading_night_mode',
  'quran_reading_reciter', 'companion_preferred_tafsir_source', 'turath_pen_color',
  'audio_reader_speed', 'adhkar_reading_dark', 'adhkar_reading_font_scale', 'adhkar_session_mode',
  // hifz
  'hifz_schedule_plan_v1', 'tahfeez_last_session_config', 'tahfeez_last_position_surah',
  'tahfeez_last_position_ayah',
  // prayer + reminders
  'manual_location_lat', 'manual_location_lng', 'prayer_calculation_method', 'prayer_madhab',
  'prayer_high_latitude_rule', 'prayer_notifications_enabled', 'prayer_notifications_adhan_sound',
  'quiet_hours_enabled', 'quiet_hours_start', 'quiet_hours_end', 'notif_encouragement_cap',
};

/// Preference families keyed by a name: per adhkar category
/// (`adhkar_notif_<category>_enabled/_hour`) and per encouragement kind
/// (`notif_enc_<kind>_enabled`).
const List<String> kBackupPrefPrefixes = ['adhkar_notif_', 'notif_enc_'];

bool isBackupPrefKey(String key) => kBackupPrefKeys.contains(key) || kBackupPrefPrefixes.any(key.startsWith);
