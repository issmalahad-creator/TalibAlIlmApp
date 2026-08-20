import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';
import 'knowledge_review_repository.dart';

class WasitiyyahSection {
  final int id;
  final String text;
  final bool memorized;
  WasitiyyahSection({required this.id, required this.text, required this.memorized});
}

/// Al-Aqidah Al-Wasitiyyah — Phase 5ب of QURAN_COMPANION_ROADMAP.md.
/// Memorized/not-memorized only, same simple treatment as the hadith
/// pillar — no 6-station engine.
class WasitiyyahRepository {
  Future<List<WasitiyyahSection>> all() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT s.id, s.original_text, COALESCE(p.memorized, 0) AS memorized
      FROM wasitiyyah_sections s
      LEFT JOIN wasitiyyah_progress p ON p.section_id = s.id
      ORDER BY s.section_order
    ''');
    return rows
        .map((r) => WasitiyyahSection(id: r['id'] as int, text: r['original_text'] as String, memorized: (r['memorized'] as int) == 1))
        .toList();
  }

  Future<void> markMemorized(int sectionId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'wasitiyyah_progress',
      {'section_id': sectionId, 'memorized': 1, 'memorized_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Seeds the section into spaced review too — see
    // `KnowledgeReviewRepository`'s doc comment for why this sits alongside
    // the flat "memorized" flag rather than replacing it.
    await KnowledgeReviewRepository().startReviewing('wasitiyyah', sectionId);
  }

  Future<List<int>> memorizedIds() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('wasitiyyah_progress', where: 'memorized = 1', columns: ['section_id']);
    return rows.map((r) => r['section_id'] as int).toList();
  }
}
