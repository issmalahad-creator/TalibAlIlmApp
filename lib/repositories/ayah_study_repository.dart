import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/ayah_study_entry.dart';

/// Local store for the Quran Ayah Study Notebook (`79-sa-D-ayah`,
/// `docs/AYAH_STUDY_NOTEBOOK_DESIGN.md`). Pure local SQLite; no network, no
/// AI. `created_at`/`updated_at` are ISO-8601 UTC (not the app's Hijri
/// date strings) on purpose: this notebook is a *journey over time* and the
/// future maths engine consumes real timestamps.
class AyahStudyRepository {
  static String _now() => DateTime.now().toUtc().toIso8601String();

  Future<int> addEntry(int surah, int ayah, AyahStudyEntryInput input) async {
    final db = await DatabaseHelper.instance.database;
    final now = _now();
    return db.insert('ayah_study_entries', {
      'surah': surah,
      'ayah': ayah,
      'word_start': input.wordStart,
      'word_end': input.wordEnd,
      'entry_type': input.entryType,
      'topic': _norm(input.topic),
      'stance': _norm(input.stance),
      'color_key': _norm(input.colorKey),
      'body': input.body.trim(),
      'source_type': _norm(input.sourceType),
      'source_name': _norm(input.sourceName),
      'source_author': _norm(input.sourceAuthor),
      'source_ref': _norm(input.sourceRef),
      'source_date': _norm(input.sourceDate),
      'source_detail': _norm(input.sourceDetail),
      'status': input.entryType == AyahEntryTypes.question ? AyahEntryStatus.open : AyahEntryStatus.none,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateEntry(int id, AyahStudyEntryInput input) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'ayah_study_entries',
      {
        'word_start': input.wordStart,
        'word_end': input.wordEnd,
        'entry_type': input.entryType,
        'topic': _norm(input.topic),
        'stance': _norm(input.stance),
        'color_key': _norm(input.colorKey),
        'body': input.body.trim(),
        'source_type': _norm(input.sourceType),
        'source_name': _norm(input.sourceName),
        'source_author': _norm(input.sourceAuthor),
        'source_ref': _norm(input.sourceRef),
        'source_date': _norm(input.sourceDate),
        'source_detail': _norm(input.sourceDetail),
        'updated_at': _now(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setStatus(int id, String status) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'ayah_study_entries',
      {
        'status': status,
        'resolved_at': status == AyahEntryStatus.resolved ? _now() : null,
        'updated_at': _now(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setSortOrder(int id, int? order) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('ayah_study_entries', {'sort_order': order, 'updated_at': _now()}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEntry(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('ayah_study_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<AyahStudyEntry?> entryById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('ayah_study_entries', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : AyahStudyEntry.fromRow(rows.first);
  }

  /// The ayah's whole study journey. Chronological ascending by default so
  /// it reads as it happened; `newestFirst` flips it. `filterType` narrows
  /// to one `entry_type` (from tapping an overview chip).
  Future<List<AyahStudyEntry>> entriesForAyah(
    int surah,
    int ayah, {
    String? filterType,
    bool newestFirst = false,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final where = StringBuffer('surah = ? AND ayah = ?');
    final args = <Object?>[surah, ayah];
    if (filterType != null) {
      where.write(' AND entry_type = ?');
      args.add(filterType);
    }
    final rows = await db.query(
      'ayah_study_entries',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'COALESCE(sort_order, 9223372036854775807) ASC, created_at ${newestFirst ? 'DESC' : 'ASC'}, id ${newestFirst ? 'DESC' : 'ASC'}',
    );
    return rows.map(AyahStudyEntry.fromRow).toList();
  }

  Future<int> countForAyah(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ayah_study_entries WHERE surah = ? AND ayah = ?', [surah, ayah]),
        ) ??
        0;
  }

  /// `{entry_type: count}` for the ayah — feeds the overview strip.
  Future<Map<String, int>> typeCountsForAyah(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT entry_type, COUNT(*) c FROM ayah_study_entries WHERE surah = ? AND ayah = ? GROUP BY entry_type',
      [surah, ayah],
    );
    return {for (final r in rows) r['entry_type'] as String: r['c'] as int};
  }

  /// Cross-ayah notebook (`QuranNotebookHomeScreen`). Any mix of filters.
  /// `sort`: 'recent' (default) | 'mushaf' | 'richest' handled by the
  /// caller for 'richest' via [ayatWithEntries]; here 'recent' / 'mushaf'.
  Future<List<AyahStudyEntry>> notebookEntries({
    List<String>? entryTypes,
    int? surah,
    int? juz,
    String? status,
    String? query,
    String sort = 'recent',
    int limit = 300,
    int offset = 0,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final where = <String>[];
    final args = <Object?>[];
    if (entryTypes != null && entryTypes.isNotEmpty) {
      where.add('e.entry_type IN (${List.filled(entryTypes.length, '?').join(',')})');
      args.addAll(entryTypes);
    }
    if (surah != null) {
      where.add('e.surah = ?');
      args.add(surah);
    }
    if (status != null) {
      where.add('e.status = ?');
      args.add(status);
    }
    final q = (query ?? '').trim();
    if (q.isNotEmpty) {
      where.add('(e.body LIKE ? OR e.source_name LIKE ? OR e.source_author LIKE ? OR e.source_detail LIKE ? OR e.topic LIKE ?)');
      for (var i = 0; i < 5; i++) {
        args.add('%$q%');
      }
    }
    // juz filter needs quran_ayat
    final join = juz != null ? 'JOIN quran_ayat a ON a.surah = e.surah AND a.ayah = e.ayah' : '';
    if (juz != null) {
      where.add('a.juz_number = ?');
      args.add(juz);
    }
    final orderBy = sort == 'mushaf' ? 'e.surah ASC, e.ayah ASC, e.created_at ASC' : 'e.updated_at DESC, e.id DESC';
    final rows = await db.rawQuery('''
      SELECT e.* FROM ayah_study_entries e
      $join
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY $orderBy
      LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);
    return rows.map(AyahStudyEntry.fromRow).toList();
  }

  /// "الآيات الأكثر ثراءً بالملاحظات" — ayat that have entries, richest first.
  Future<List<AyahEntryCount>> ayatWithEntries({String sort = 'richest', int limit = 200}) async {
    final db = await DatabaseHelper.instance.database;
    final orderBy = sort == 'mushaf' ? 'surah ASC, ayah ASC' : 'c DESC, surah ASC, ayah ASC';
    final rows = await db.rawQuery('''
      SELECT surah, ayah, COUNT(*) c FROM ayah_study_entries
      GROUP BY surah, ayah
      ORDER BY $orderBy
      LIMIT ?
    ''', [limit]);
    return rows.map((r) => AyahEntryCount(r['surah'] as int, r['ayah'] as int, r['c'] as int)).toList();
  }

  /// Prior `topic` tags for the add-sheet autocomplete.
  Future<List<String>> distinctTopics() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT topic FROM ayah_study_entries WHERE topic IS NOT NULL AND topic <> '' ORDER BY topic",
    );
    return rows.map((r) => r['topic'] as String).toList();
  }

  static String? _norm(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}
