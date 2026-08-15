import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class ZadAlMaadChapter {
  final int id;
  final int volume;
  final String title;
  final String text;
  final bool hasUthaymeenCommentary;
  final bool readDone;
  ZadAlMaadChapter({
    required this.id,
    required this.volume,
    required this.title,
    required this.text,
    required this.hasUthaymeenCommentary,
    required this.readDone,
  });
}

/// Zad al-Ma'ad — Phase 5ج of QURAN_COMPANION_ROADMAP.md. A reading/study
/// text, not a memorization one (unlike Quran/hadith/aqeedah) — tracked as
/// "read" not "memorized", and deliberately has no quiz: "أكمل النص" فيه
/// لا يناسب نصًا فقهيًا/سيريًا طويلًا يُقرأ للفهم، لا للحفظ الحرفي.
class ZadAlMaadRepository {
  Future<List<ZadAlMaadChapter>> all() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.volume, c.chapter_title, c.chapter_text, c.has_uthaymeen_commentary,
             COALESCE(p.read_done, 0) AS read_done
      FROM zad_almaad_chapters c
      LEFT JOIN zad_almaad_progress p ON p.chapter_id = c.id
      ORDER BY c.volume, c.chapter_order
    ''');
    return rows
        .map((r) => ZadAlMaadChapter(
              id: r['id'] as int,
              volume: r['volume'] as int,
              title: r['chapter_title'] as String,
              text: r['chapter_text'] as String,
              hasUthaymeenCommentary: (r['has_uthaymeen_commentary'] as int) == 1,
              readDone: (r['read_done'] as int) == 1,
            ))
        .toList();
  }

  Future<void> markRead(int chapterId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'zad_almaad_progress',
      {'chapter_id': chapterId, 'read_done': 1, 'read_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
