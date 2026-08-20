import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';
import 'knowledge_review_repository.dart';

class NawawiHadith {
  final int id;
  final String text;
  final String? commentary;
  final bool memorized;
  NawawiHadith({required this.id, required this.text, this.commentary, required this.memorized});
}

/// Al-Arba'in Al-Nawawiyyah — Phase 5أ of QURAN_COMPANION_ROADMAP.md.
/// Deliberately simple (memorized/not-memorized only, no 6-station engine)
/// — see the migration's own doc comment for why.
class HadithRepository {
  Future<List<NawawiHadith>> all() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT h.id, h.hadith_text, h.commentary_text, COALESCE(p.memorized, 0) AS memorized
      FROM nawawi_hadiths h
      LEFT JOIN hadith_progress p ON p.hadith_id = h.id
      ORDER BY h.id
    ''');
    return rows
        .map((r) => NawawiHadith(
              id: r['id'] as int,
              text: r['hadith_text'] as String,
              commentary: r['commentary_text'] as String?,
              memorized: (r['memorized'] as int) == 1,
            ))
        .toList();
  }

  Future<void> markMemorized(int hadithId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'hadith_progress',
      {'hadith_id': hadithId, 'memorized': 1, 'memorized_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Seeds the hadith into spaced review too — see
    // `KnowledgeReviewRepository`'s doc comment for why this sits alongside
    // the flat "memorized" flag rather than replacing it.
    await KnowledgeReviewRepository().startReviewing('hadith', hadithId);
  }

  Future<List<int>> memorizedIds() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('hadith_progress', where: 'memorized = 1', columns: ['hadith_id']);
    return rows.map((r) => r['hadith_id'] as int).toList();
  }
}
