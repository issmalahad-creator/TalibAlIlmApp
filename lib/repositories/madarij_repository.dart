import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class MadarijSection {
  final int id;
  final String title;
  final String text;
  final bool readDone;
  MadarijSection({required this.id, required this.title, required this.text, required this.readDone});
}

/// Madarij As-Salikin — Phase 5ح of QURAN_COMPANION_ROADMAP.md. **Advanced
/// tier only** — the deepest text in this app, see the migration's doc
/// comment. Tracked as "read" (like Zad al-Ma'ad), with a lighter
/// continuation quiz reused from the Wasitiyyah pattern since it's also a
/// continuous treatise.
class MadarijRepository {
  Future<List<MadarijSection>> all() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT s.id, s.section_title, s.text_excerpt, COALESCE(p.read_done, 0) AS read_done
      FROM madarij_sections s
      LEFT JOIN madarij_progress p ON p.section_id = s.id
      ORDER BY s.section_order
    ''');
    return rows
        .map((r) => MadarijSection(
              id: r['id'] as int,
              title: r['section_title'] as String,
              text: r['text_excerpt'] as String,
              readDone: (r['read_done'] as int) == 1,
            ))
        .toList();
  }

  Future<void> markRead(int sectionId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'madarij_progress',
      {'section_id': sectionId, 'read_done': 1, 'read_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> readIds() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('madarij_progress', where: 'read_done = 1', columns: ['section_id']);
    return rows.map((r) => r['section_id'] as int).toList();
  }
}
