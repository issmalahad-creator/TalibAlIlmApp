import 'package:sqflite/sqflite.dart';

/// Legacy → `turath_annotations` migration (Phase 79 «علامات الدراسة»).
///
/// Kept in its own file (not inline in `DatabaseHelper`) so it can be
/// exercised directly by a test against real rows, rather than only through
/// a full v48→v49 database upgrade.
///
/// Every existing `turath_notes` and `turath_quotes` row becomes a
/// `turath_annotations` row with `anchor_status = 'unanchored'` — it carries
/// its snippet text but no offsets yet; the anchor resolver upgrades it to
/// exact/shifted/fuzzy/orphan on the first page visit. Old rows are left
/// untouched (read-only safety net for one release). `source_kind` +
/// `legacy_id` make a later catch-up pass idempotent.
Future<void> migrateLegacyToAnnotations(DatabaseExecutor db) async {
  final now = DateTime.now().toIso8601String();

  await db.rawInsert('''
    INSERT INTO turath_annotations (
      book_id, page_number, selected_text, selected_len,
      color_key, note_type, note_body,
      anchor_status, source_kind, legacy_id,
      book_name, created_at, updated_at
    )
    SELECT
      book_id, page_number,
      selected_text,
      CASE WHEN selected_text IS NULL THEN NULL ELSE length(selected_text) END,
      'explain', 'explain', note,
      CASE WHEN selected_text IS NULL OR selected_text = '' THEN 'orphan' ELSE 'unanchored' END,
      'legacy_note', id,
      book_name, COALESCE(created_at, ?), COALESCE(created_at, ?)
    FROM turath_notes
    WHERE NOT EXISTS (
      SELECT 1 FROM turath_annotations a
      WHERE a.source_kind = 'legacy_note' AND a.legacy_id = turath_notes.id
    )
  ''', [now, now]);

  await db.rawInsert('''
    INSERT INTO turath_annotations (
      book_id, page_number, volume, selected_text, selected_len,
      color_key, note_type, note_body,
      anchor_status, source_kind, legacy_id,
      book_name, author_name, created_at, updated_at
    )
    SELECT
      book_id, page_number, volume,
      quoted_text,
      CASE WHEN quoted_text IS NULL THEN NULL ELSE length(quoted_text) END,
      'benefit', 'benefit', note,
      CASE WHEN quoted_text IS NULL OR quoted_text = '' THEN 'orphan' ELSE 'unanchored' END,
      'legacy_quote', id,
      book_name, author_name, COALESCE(created_at, ?), COALESCE(created_at, ?)
    FROM turath_quotes
    WHERE NOT EXISTS (
      SELECT 1 FROM turath_annotations a
      WHERE a.source_kind = 'legacy_quote' AND a.legacy_id = turath_quotes.id
    )
  ''', [now, now]);
}
