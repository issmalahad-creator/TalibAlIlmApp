import '../db/database_helper.dart';
import '../models/medication.dart';
import '../services/medication_schedule.dart';

/// «علاجاتي» storage. Saving a course (re)generates its doses with
/// [buildMedicationDoses]; editing keeps the history — doses already taken
/// or skipped stay as they were, and only the still-pending ones are
/// replaced by the new schedule.
class MedicationRepository {
  Future<int> saveCourse(MedCourse course) async {
    final db = await DatabaseHelper.instance.database;
    return db.transaction((txn) async {
      final row = course.toRow();
      int id;
      var keep = <MedDose>[];
      if (course.id == null) {
        id = await txn.insert('med_courses', {...row, 'created_at': DateTime.now().millisecondsSinceEpoch});
      } else {
        id = course.id!;
        await txn.update('med_courses', row, where: 'id = ?', whereArgs: [id]);
        final old = await txn.query('med_doses', where: 'course_id = ?', whereArgs: [id], orderBy: 'scheduled_at');
        keep = old.map(MedDose.fromRow).where((d) => !d.isPending).toList();
        await txn.delete('med_doses', where: "course_id = ? AND status = 'pending'", whereArgs: [id]);
      }
      // A dose already taken/skipped counts toward the new total: the new
      // schedule continues after the last recorded dose and only fills the
      // doses still owed.
      final lastDone = keep.isEmpty ? null : keep.last.scheduledAt;
      var fresh = buildMedicationDoses(course, courseId: id);
      if (lastDone != null) fresh = fresh.where((d) => d.scheduledAt.isAfter(lastDone)).toList();
      final owed = (medicationDoseCount(course) - keep.length).clamp(0, fresh.length);
      fresh = fresh.take(owed).toList();
      final batch = txn.batch();
      var seq = 0;
      for (final d in keep) {
        batch.update('med_doses', {'seq': ++seq}, where: 'id = ?', whereArgs: [d.id]);
      }
      for (final d in fresh) {
        seq++;
        batch.insert('med_doses', MedDose(courseId: id, seq: seq, scheduledAt: d.scheduledAt).toRow());
      }
      await batch.commit(noResult: true);
      return id;
    });
  }

  Future<void> deleteCourse(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('med_doses', where: 'course_id = ?', whereArgs: [id]);
      await txn.delete('med_courses', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> setRemindersOn(int courseId, bool on) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('med_courses', {'reminders_on': on ? 1 : 0}, where: 'id = ?', whereArgs: [courseId]);
  }

  Future<void> setDoseStatus(int doseId, MedDoseStatus status, {DateTime? at}) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'med_doses',
      {
        'status': status.name,
        'taken_at': status == MedDoseStatus.taken ? (at ?? DateTime.now()).millisecondsSinceEpoch : null,
      },
      where: 'id = ?',
      whereArgs: [doseId],
    );
  }

  /// Moves one dose. With [shiftFollowing], every later pending dose of the
  /// course moves by the same amount — «أخذتها متأخرًا ساعتين، أكمل من هنا»
  /// keeps the 8-hour gaps the prescription asks for.
  Future<void> moveDose(MedDose dose, DateTime to, {bool shiftFollowing = false}) async {
    final db = await DatabaseHelper.instance.database;
    final delta = to.difference(dose.scheduledAt).inMilliseconds;
    await db.transaction((txn) async {
      if (shiftFollowing) {
        await txn.rawUpdate(
          "UPDATE med_doses SET scheduled_at = scheduled_at + ? WHERE course_id = ? AND status = 'pending' AND scheduled_at >= ?",
          [delta, dose.courseId, dose.scheduledAt.millisecondsSinceEpoch],
        );
      } else {
        await txn.update('med_doses', {'scheduled_at': to.millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [dose.id]);
      }
    });
  }

  Future<List<MedCourseWithDoses>> courses() async {
    final db = await DatabaseHelper.instance.database;
    final cs = (await db.query('med_courses', orderBy: 'start_at DESC')).map(MedCourse.fromRow).toList();
    if (cs.isEmpty) return const [];
    final ds = (await db.query('med_doses', orderBy: 'scheduled_at')).map(MedDose.fromRow);
    final byCourse = <int, List<MedDose>>{};
    for (final d in ds) {
      (byCourse[d.courseId] ??= []).add(d);
    }
    return [for (final c in cs) MedCourseWithDoses(c, byCourse[c.id] ?? const [])];
  }

  Future<MedCourseWithDoses?> course(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('med_courses', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final ds = await db.query('med_doses', where: 'course_id = ?', whereArgs: [id], orderBy: 'scheduled_at');
    return MedCourseWithDoses(MedCourse.fromRow(rows.first), ds.map(MedDose.fromRow).toList());
  }

  /// The soonest pending dose across all courses (overdue by under an hour
  /// still counts) — for the companion's «متى دوائي؟» and the screen header.
  Future<(MedCourse, MedDose)?> nextDose(DateTime now) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      "SELECT d.*, c.name AS c_name FROM med_doses d JOIN med_courses c ON c.id = d.course_id "
      "WHERE d.status = 'pending' AND d.scheduled_at >= ? ORDER BY d.scheduled_at LIMIT 1",
      [now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch],
    );
    if (rows.isEmpty) return null;
    final dose = MedDose.fromRow(rows.first);
    final c = await course(dose.courseId);
    return c == null ? null : (c.course, dose);
  }
}
