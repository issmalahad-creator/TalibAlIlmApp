import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

/// Tracks whether the student has opened each "دليل المسلم الجديد" topic
/// at least once — this content is read once as onboarding, not
/// memorized/reviewed, so there's no station/streak logic, just a
/// first-read marker.
class GuideProgressRepository {
  Future<Set<String>> readTopicKeys() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('guide_progress');
    return rows.map((r) => r['topic_key'] as String).toSet();
  }

  Future<void> markRead(String topicKey) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query('guide_progress', where: 'topic_key = ?', whereArgs: [topicKey], limit: 1);
    if (existing.isNotEmpty) return;
    await db.insert(
      'guide_progress',
      {'topic_key': topicKey, 'first_read_date': todayDate()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
