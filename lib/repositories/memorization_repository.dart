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

/// Real hifz-teaching structure (سبق/سبقي/منزل — Sabaq/Sabqi/Manzil),
/// researched 2026-08-16 at Ismail's request before any code ("ابحث
/// اونلاين اولا"): the traditional three-tier review system used in real
/// hifz institutes, not an invented category scheme. Defined by how long
/// ago a page was memorized, matching how real teachers describe it:
///  - سبق: memorized today — today's brand-new lesson, not yet reviewed.
///  - سبقي: memorized within the last ~15 days — the "recent revision"
///    window (sources cite 7-15 days; 15 used here as the safe upper
///    bound so nothing falls through a gap).
///  - منزل: older than 15 days (or already "established") — long-term
///    rotation review.
/// This is a presentational grouping on top of the existing 6-station
/// engine, not a replacement for it — the due-date scheduling itself is
/// unchanged in this pass; see QURAN_COMPANION_ROADMAP.md §4.31 for the
/// full research and what's still queued (mastery gate before new سبق,
/// true weekly-proportional منزل rotation, real level-based pacing).
enum HifzCategory { sabaq, sabqi, manzil, notStarted }

class MemorizationUnit {
  final int id; // = page number
  final int surahStart, ayahStart, surahEnd, ayahEnd;
  final int? juzNumber;
  final String status; // not_started | new | reviewing | established
  final int? station;
  final String? nextReviewDate;
  final String? memorizedDate;
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
    this.memorizedDate,
  });

  HifzCategory hifzCategory({DateTime? asOf}) {
    if (memorizedDate == null) return HifzCategory.notStarted;
    final memorized = gregorianFromHijriDateTime(memorizedDate!, null);
    final today = asOf ?? DateTime.now();
    final ageDays = DateTime(today.year, today.month, today.day).difference(DateTime(memorized.year, memorized.month, memorized.day)).inDays;
    if (ageDays <= 0) return HifzCategory.sabaq;
    if (ageDays <= 15) return HifzCategory.sabqi;
    return HifzCategory.manzil;
  }
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

  /// "تعديل ما حفظت" (Ismail's request 2026-08-16) — undoes a mistaken
  /// `markMemorized` entirely: removes the page's progress row (back to
  /// the implicit `not_started` state) along with its review/mistake
  /// history, since that history describes reviews of a memorization that
  /// didn't actually happen. Distinct from `recordReview` — this isn't
  /// "rate it lower," it's "I marked the wrong page / this was a
  /// mistake," so partial history would be actively misleading.
  Future<void> resetProgress(int unitId) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    batch.delete('memorization_progress', where: 'unit_id = ?', whereArgs: [unitId]);
    batch.delete('review_log', where: 'unit_id = ?', whereArgs: [unitId]);
    batch.delete('mistake_log', where: 'unit_id = ?', whereArgs: [unitId]);
    await batch.commit(noResult: true);
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
             p.status, p.station, p.next_review_date, p.memorized_date
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

  /// "نقاط تحتاج تركيزًا إضافيًا" (Ismail's request 2026-08-16 — one of 4
  /// new coach features, "ابحث ان لم تكن تعلم"): a real hifz-teaching
  /// technique is drilling a student's actual recurring weak spots
  /// specifically, not just generic review. Reuses `mistake_log` (already
  /// written every time a review is rated "يحتاج مراجعة") — groups by
  /// page and ranks by how often it's been marked as a mistake, most
  /// recent [sinceDays] days only, so an old fixed weakness doesn't stay
  /// flagged forever. No new tracking, purely a different read of
  /// existing data.
  Future<List<(MemorizationUnit unit, int mistakeCount)>> recurringWeakSpots({int limit = 5, int sinceDays = 30}) async {
    final db = await DatabaseHelper.instance.database;
    final since = _addDays(todayDate(), -sinceDays);
    final rows = await db.rawQuery('''
      SELECT u.id, u.surah_start, u.ayah_start, u.surah_end, u.ayah_end, u.juz_number,
             p.status, p.station, p.next_review_date, p.memorized_date,
             COUNT(m.id) AS mistake_count
      FROM mistake_log m
      JOIN memorization_units u ON u.id = m.unit_id
      LEFT JOIN memorization_progress p ON p.unit_id = u.id
      WHERE m.logged_date >= ?
      GROUP BY u.id
      HAVING mistake_count >= 2
      ORDER BY mistake_count DESC, u.id ASC
      LIMIT ?
    ''', [since, limit]);
    return rows.map((r) => (_toUnit(r), r['mistake_count'] as int)).toList();
  }

  /// "كم مرة كررتها؟" (Ismail's request 2026-08-16) — real hifz guidance
  /// found via research (`quranprogress.com`/`aqleeat.co`/`alukah.net`,
  /// see QURAN_COMPANION_ROADMAP.md §4.33): 10-40 repetitions of a newly
  /// memorized page/segment before it's considered solid, depending on
  /// method — a single-point number would misrepresent that range as
  /// precise, so [repetitionTargetRange] is exposed as a range for the UI
  /// to show honestly, not one invented "correct" number.
  static const repetitionTargetRange = (10, 40);

  Future<int> repetitionCountToday(int unitId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('sabaq_repetition_log', where: 'unit_id = ? AND log_date = ?', whereArgs: [unitId, todayDate()], limit: 1);
    return rows.isEmpty ? 0 : rows.first['rep_count'] as int;
  }

  Future<int> incrementRepetitionToday(int unitId) async {
    final db = await DatabaseHelper.instance.database;
    final current = await repetitionCountToday(unitId);
    final next = current + 1;
    await db.insert(
      'sabaq_repetition_log',
      {'unit_id': unitId, 'log_date': todayDate(), 'rep_count': next},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return next;
  }

  /// The real منزل target (Ismail's request — see QURAN_COMPANION_
  /// ROADMAP.md §4.31's research): a real hifz institute divides ALL
  /// established (راسخ) material into 7 roughly equal daily portions so
  /// the whole thing is covered once a week, growing automatically as
  /// more pages become established — not a fixed 30-day rotation. This
  /// is deliberately informational only in this pass (not yet wired into
  /// `recordReview`'s actual scheduling, which stays unchanged) — it
  /// tells the student what their real weekly portion size should be,
  /// without touching the due-date engine every existing user already
  /// relies on.
  Future<int> establishedCount() async {
    final db = await DatabaseHelper.instance.database;
    return Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM memorization_progress WHERE status = 'established'")) ?? 0;
  }

  /// Established pages ÷ 7, rounded up (at least 1 once there's anything
  /// established) — "today's real منزل portion" per the traditional
  /// weekly-cycle rule.
  Future<int> manzilDailyPortionSize() async {
    final established = await establishedCount();
    if (established == 0) return 0;
    return (established / 7).ceil();
  }

  /// The next page to memorize, in plain Mushaf order — the first unit
  /// with no `memorization_progress` row at all (never started). Powers
  /// "تكليف اليوم" so the student gets a concrete assignment instead of
  /// having to browse the whole Mushaf and pick a page themselves.
  /// Deterministic on purpose (no "smart" reordering) — same predictability
  /// principle as `dueToday()`.
  Future<MemorizationUnit?> nextRecommendedUnit() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT u.id, u.surah_start, u.ayah_start, u.surah_end, u.ayah_end, u.juz_number,
             p.status, p.station, p.next_review_date, p.memorized_date
      FROM memorization_units u
      LEFT JOIN memorization_progress p ON p.unit_id = u.id
      WHERE p.unit_id IS NULL
      ORDER BY u.id
      LIMIT 1
    ''');
    if (rows.isEmpty) return null;
    return _toUnit({...rows.first, 'status': 'not_started'});
  }

  /// Whether at least one page was newly marked memorized today — powers
  /// the "حفظ جديد" step of "جلسة اليوم" without a separate tracking table.
  Future<bool> hasMemorizedToday() async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM memorization_progress WHERE memorized_date = ?', [todayDate()]),
    );
    return (count ?? 0) > 0;
  }

  /// Whether at least one review was recorded today — powers the "مراجعة"
  /// step of "جلسة اليوم".
  Future<bool> hasReviewedToday() async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM review_log WHERE review_date = ?', [todayDate()]),
    );
    return (count ?? 0) > 0;
  }

  /// All 604 units with their progress (or the implicit 'not_started'
  /// status for units with no `memorization_progress` row yet) — powers the
  /// "القرآن" browse screen. Ordered by id (= Mushaf page order).
  Future<List<MemorizationUnit>> allUnitsWithProgress() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT u.id, u.surah_start, u.ayah_start, u.surah_end, u.ayah_end, u.juz_number,
             COALESCE(p.status, 'not_started') AS status, p.station, p.next_review_date, p.memorized_date
      FROM memorization_units u
      LEFT JOIN memorization_progress p ON p.unit_id = u.id
      ORDER BY u.id
    ''');
    return rows.map(_toUnit).toList();
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
        memorizedDate: row['memorized_date'] as String?,
      );

  String _addDays(String hijriDate, int days) {
    final dt = gregorianFromHijriDateTime(hijriDate, null).add(Duration(days: days));
    return hijriDateStringForDate(dt);
  }
}
