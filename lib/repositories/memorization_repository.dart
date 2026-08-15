import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';

enum ReviewQuality { excellent, good, needsReview }

extension on ReviewQuality {
  String get dbValue => switch (this) {
        ReviewQuality.excellent => 'excellent',
        ReviewQuality.good => 'good',
        ReviewQuality.needsReview => 'needs_review',
      };
}

class MemorizationUnit {
  final int id; // = page number
  final int surahStart, ayahStart, surahEnd, ayahEnd;
  final int? juzNumber;
  final String status; // not_started | new | reviewing | established
  final int? station;
  final String? nextReviewDate;
  MemorizationUnit({
    required this.id,
    required this.surahStart,
    required this.ayahStart,
    required this.surahEnd,
    required this.ayahEnd,
    this.juzNumber,
    required this.status,
    this.station,
    this.nextReviewDate,
  });
}

/// The 6-station Ebbinghaus-forgetting-curve review engine —
/// QURAN_COMPANION_ROADMAP.md section 4. Station N's interval is
/// [_stationDays[N-1]] days since the last successful review;
/// `station == null` means "established" (permanent ~30-day rotation).
class MemorizationRepository {
  static const _stationDays = [1, 3, 7, 14, 30, 60];
  static const _establishedRotationDays = 30;
  static const _needsReviewFallbackStation = 2;

  /// Marks a page as newly memorized today — starts it at station 1.
  Future<void> markMemorized(int unitId) async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();
    await db.insert('memorization_progress', {
      'unit_id': unitId,
      'status': 'new',
      'memorized_date': today,
      'last_review_date': today,
      'next_review_date': _addDays(today, _stationDays[0]),
      'station': 1,
      'consecutive_good_count': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Records a review and advances/repeats/regresses the unit's station per
  /// the roadmap's transition rules. `note` is only meaningful for
  /// `needsReview` and is logged to `mistake_log`.
  Future<void> recordReview(int unitId, ReviewQuality quality, {String? note}) async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();

    final reviewId = await db.insert('review_log', {
      'unit_id': unitId,
      'review_date': today,
      'quality': quality.dbValue,
    });

    if (quality == ReviewQuality.needsReview) {
      await db.insert('mistake_log', {
        'unit_id': unitId,
        'review_id': reviewId,
        'note': note,
        'logged_date': today,
      });
    }

    final rows = await db.query('memorization_progress', where: 'unit_id = ?', whereArgs: [unitId], limit: 1);
    final current = rows.isEmpty ? null : rows.first;
    final currentStation = current?['station'] as int?; // null only if already established
    final currentGoodCount = (current?['consecutive_good_count'] as int?) ?? 0;

    switch (quality) {
      case ReviewQuality.needsReview:
        await db.update(
          'memorization_progress',
          {
            'status': 'reviewing',
            'last_review_date': today,
            'next_review_date': _addDays(today, _stationDays[_needsReviewFallbackStation - 1]),
            'station': _needsReviewFallbackStation,
            'consecutive_good_count': 0,
          },
          where: 'unit_id = ?',
          whereArgs: [unitId],
        );
        return;

      case ReviewQuality.good:
        final station = currentStation ?? _stationDays.length; // established units re-anchor at the top station
        await db.update(
          'memorization_progress',
          {
            'last_review_date': today,
            'next_review_date': _addDays(today, _stationDays[station - 1]),
            'consecutive_good_count': currentGoodCount + 1,
          },
          where: 'unit_id = ?',
          whereArgs: [unitId],
        );
        return;

      case ReviewQuality.excellent:
        final station = currentStation ?? _stationDays.length;
        if (station >= _stationDays.length) {
          // Already at the top station and excellent again -> established,
          // joins the permanent rotation pool.
          await db.update(
            'memorization_progress',
            {
              'status': 'established',
              'last_review_date': today,
              'next_review_date': _addDays(today, _establishedRotationDays),
              'station': null,
              'consecutive_good_count': currentGoodCount + 1,
            },
            where: 'unit_id = ?',
            whereArgs: [unitId],
          );
        } else {
          final nextStation = station + 1;
          await db.update(
            'memorization_progress',
            {
              'status': 'reviewing',
              'last_review_date': today,
              'next_review_date': _addDays(today, _stationDays[nextStation - 1]),
              'station': nextStation,
              'consecutive_good_count': currentGoodCount + 1,
            },
            where: 'unit_id = ?',
            whereArgs: [unitId],
          );
        }
        return;
    }
  }

  /// Units due for review today or earlier. Never dumps the whole overdue
  /// backlog at once — QURAN_COMPANION_ROADMAP.md's "بدون عقاب" rule: units
  /// due exactly today are always included; older overdue ones are capped
  /// at [maxExtra] (oldest-first) and the rest simply surface again
  /// tomorrow, spreading a catch-up gradually instead of all at once.
  Future<List<MemorizationUnit>> dueToday({int maxExtra = 5}) async {
    final db = await DatabaseHelper.instance.database;
    final today = todayDate();
    final rows = await db.rawQuery('''
      SELECT u.id, u.surah_start, u.ayah_start, u.surah_end, u.ayah_end, u.juz_number,
             p.status, p.station, p.next_review_date
      FROM memorization_progress p
      JOIN memorization_units u ON u.id = p.unit_id
      WHERE p.next_review_date <= ?
      ORDER BY p.next_review_date ASC
    ''', [today]);

    final dueTodayExact = rows.where((r) => r['next_review_date'] == today).toList();
    final overdue = rows.where((r) => (r['next_review_date'] as String) != today).toList();
    final selected = [...dueTodayExact, ...overdue.take(maxExtra)];
    return selected.map(_toUnit).toList();
  }

  MemorizationUnit _toUnit(Map<String, Object?> row) => MemorizationUnit(
        id: row['id'] as int,
        surahStart: row['surah_start'] as int,
        ayahStart: row['ayah_start'] as int,
        surahEnd: row['surah_end'] as int,
        ayahEnd: row['ayah_end'] as int,
        juzNumber: row['juz_number'] as int?,
        status: row['status'] as String,
        station: row['station'] as int?,
        nextReviewDate: row['next_review_date'] as String?,
      );

  String _addDays(String hijriDate, int days) {
    final dt = gregorianFromHijriDateTime(hijriDate, null).add(Duration(days: days));
    return hijriDateStringForDate(dt);
  }
}
