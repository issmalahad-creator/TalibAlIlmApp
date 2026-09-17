import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/completion_goal_repository.dart';
import 'package:talib_alilm_app/utils/hijri_date.dart';

/// KHATM_SYSTEM_AND_STYLE_REFERENCE.md §2.3 field 4, grain "partial range"
/// (Ismail 2026-09-17) — verifies `statusFor()` normalizes an absolute
/// stored mushaf page against a goal's `start_unit`/`end_unit`, so the
/// displayed "X of totalUnits" and % stay within the range's own size
/// rather than reflecting the raw absolute page number. Run against a real
/// sqflite (ffi) database, not mocked, per this project's own testing norm.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final repo = CompletionGoalRepository();
  final targetDate = hijriDateStringForDate(DateTime.now().add(const Duration(days: 30)));

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_khatm_range_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await DatabaseHelper.instance.database; // trigger migrations incl. v67
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('completion_goals');
    await db.delete('completion_goal_progress');
  });

  test('a ranged goal computes total_units from start/end, not the passed default', () async {
    final goal = await repo.create(
      contentType: 'quran_reading',
      totalUnits: 604, // overridden — a range is given
      targetDate: targetDate,
      startUnit: 302,
      endUnit: 421,
    );
    expect(goal.totalUnits, 120); // 421-302+1
    expect(goal.startUnit, 302);
    expect(goal.endUnit, 421);
  });

  test('statusFor() normalizes an absolute stored page to a within-range position/percent', () async {
    final goal = await repo.create(
      contentType: 'quran_reading',
      totalUnits: 604,
      targetDate: targetDate,
      startUnit: 302,
      endUnit: 421,
    );
    // Simulate an absolute mushaf page 20 pages into the range (as a future
    // "أتممت الورد" write, reading the reader's current page, would send).
    await repo.recordProgress(goal.id, 322);
    final status = await repo.statusFor(goal);
    expect(status.currentPosition, 21); // 322-302+1, NOT the raw 322
    expect(status.remaining, 99); // 120-21
    final percent = (status.currentPosition / goal.totalUnits * 100).round();
    expect(percent, 18); // 21/120*100 = 17.5 -> 18, not 322/120=268%
  });

  test('an unranged (legacy/full-mushaf) goal keeps the absolute position unchanged', () async {
    final goal = await repo.create(
      contentType: 'quran_reading',
      totalUnits: 604,
      targetDate: targetDate,
    );
    await repo.recordProgress(goal.id, 47);
    final status = await repo.statusFor(goal);
    expect(status.currentPosition, 47); // no startUnit -> no normalization
    expect(status.remaining, 604 - 47);
  });

  test('a stored page before the range start clamps to 0, never negative', () async {
    final goal = await repo.create(
      contentType: 'quran_reading',
      totalUnits: 604,
      targetDate: targetDate,
      startUnit: 302,
      endUnit: 421,
    );
    await repo.recordProgress(goal.id, 100); // before start_unit
    final status = await repo.statusFor(goal);
    expect(status.currentPosition, 0);
    expect(status.remaining, 120);
  });
}
