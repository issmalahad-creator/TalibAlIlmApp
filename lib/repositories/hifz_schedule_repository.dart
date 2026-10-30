import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_surahs.dart';
import '../db/database_helper.dart';
import '../services/hifz/schedule_generator.dart';
import '../utils/calendar_days.dart';
import 'hifz_repository.dart';

/// The student's chosen hifz plan (ح2/ح4 of
/// `docs/memorization/HIFZ_SCHEDULE_ARCHITECTURE.md`). Only the choice is
/// stored — the days themselves are always generated from it (§5.1).
///
/// What was already memorized when the plan began (or was re-planned) is a
/// **snapshot** ([memorizedSurahs], [memorizedUnits]), so the days don't
/// shift under the student as they memorize; live progress is measured
/// against them separately ([HifzScheduleRepository.progress]).
class HifzPlanChoice {
  final HifzDirection direction;
  final HifzTimeline timeline;
  final DateTime start;

  /// The khatm date the plan aims at (deadline mode).
  final DateTime end;

  /// Lines per day, when the student chose «أبقِ وتيرتي» (ح4): the load is
  /// fixed and the end moves. Null = deadline mode.
  final double? pace;

  /// Surahs memorized in «حفظي» at [start].
  final Set<int> memorizedSurahs;

  /// Pages («حفظتُها» in ٣×٣, `memorization_progress`) memorized at [start].
  final Set<int> memorizedUnits;

  HifzPlanChoice({
    required this.direction,
    required this.timeline,
    required this.start,
    DateTime? end,
    this.pace,
    this.memorizedSurahs = const {},
    this.memorizedUnits = const {},
  }) : end = end ?? addCalendarDays(start, timeline.totalDays - 1);

  static String _ymd(DateTime d) => '${d.year}-${d.month}-${d.day}';
  static DateTime _parse(String s) {
    final d = s.split('-').map(int.parse).toList();
    return DateTime(d[0], d[1], d[2]);
  }

  Map<String, Object> toJson() => {
        'direction': direction.name,
        'timeline': timeline.name,
        'start': _ymd(start),
        'end': _ymd(end),
        'pace': ?pace,
        'memorized': memorizedSurahs.toList(),
        'units': memorizedUnits.toList(),
      };

  static HifzPlanChoice? fromJson(Map<String, dynamic> j) {
    try {
      return HifzPlanChoice(
        direction: HifzDirection.values.byName(j['direction'] as String),
        timeline: HifzTimeline.values.byName(j['timeline'] as String),
        start: _parse(j['start'] as String),
        end: j['end'] == null ? null : _parse(j['end'] as String),
        pace: (j['pace'] as num?)?.toDouble(),
        memorizedSurahs: {for (final s in j['memorized'] as List) s as int},
        memorizedUnits: {for (final s in (j['units'] as List?) ?? const []) s as int},
      );
    } catch (_) {
      return null;
    }
  }

  /// 1-based day of the plan today (0 before it starts).
  int dayNumber(DateTime today) => calendarDaysBetween(start, today) + 1;

  /// Days from [start] to [end], inclusive.
  int get totalDays => calendarDaysBetween(start, end) + 1;

  /// The khatm phase, shortened in proportion when a re-plan leaves less time.
  int get finalPhaseDays {
    final full = timeline.finalPhaseDays;
    if (totalDays >= timeline.totalDays) return full;
    final scaled = (full * totalDays / timeline.totalDays).round();
    return scaled < 7 ? 7 : scaled;
  }
}

class _GenArgs {
  final List<AyahLines> ayat;
  final HifzDirection direction;
  final HifzTimeline timeline;
  final Set<(int, int)> skip;
  final int? totalDays;
  final int? finalDays;
  final double? pace;
  const _GenArgs(this.ayat, this.direction, this.timeline, this.skip, {this.totalDays, this.finalDays, this.pace});
}

HifzSchedule _generate(_GenArgs a) => a.pace != null
    ? generateScheduleAtPace(mushafOrder: a.ayat, direction: a.direction, linesPerDay: a.pace!, finalPhaseDays: a.finalDays ?? a.timeline.finalPhaseDays, alreadyMemorized: a.skip)
    : generateSchedule(mushafOrder: a.ayat, direction: a.direction, timeline: a.timeline, alreadyMemorized: a.skip, totalDays: a.totalDays, finalPhaseDays: a.finalDays);

Map<HifzTimeline, double> _estimate(_GenArgs a) => {
      for (final t in HifzTimeline.values)
        t: generateSchedule(mushafOrder: a.ayat, direction: a.direction, timeline: t, alreadyMemorized: a.skip).linesPerDay,
    };

List<AyahLines> _measure((List<(int, int, int, int)>, Map<(int, int), int>) a) =>
    ayahLinesFromWords(a.$1, (s, ayah) => a.$2[(s, ayah)] ?? 1);

class HifzScheduleRepository {
  static const _prefKey = 'hifz_schedule_plan_v1';

  /// Average text lines on a muṣḥaf page (8,820 / 604) — for «≈ N pages».
  static const linesPerPage = 14.6;

  static List<AyahLines>? _ayatCache;

  /// Every ayah's share of muṣḥaf lines, from `mushaf_words` (no new asset),
  /// with its juzʼ from `quran_ayat`. Measured once off the UI isolate.
  Future<List<AyahLines>> ayahLines() async {
    if (_ayatCache != null) return _ayatCache!;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('SELECT page, line, surah, ayah FROM mushaf_words ORDER BY page, word_order');
    final juzRows = await db.rawQuery('SELECT surah, ayah, juz_number FROM quran_ayat WHERE juz_number IS NOT NULL');
    final words = [
      for (final r in rows) ((r['page'] as num).toInt(), (r['line'] as num).toInt(), (r['surah'] as num).toInt(), (r['ayah'] as num).toInt()),
    ];
    final juz = {for (final r in juzRows) ((r['surah'] as num).toInt(), (r['ayah'] as num).toInt()): (r['juz_number'] as num).toInt()};
    final measured = await compute(_measure, (words, juz));
    _ayatCache = measured;
    return measured;
  }

  Future<HifzPlanChoice?> choice() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefKey);
    if (raw == null) return null;
    return HifzPlanChoice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(HifzPlanChoice c) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefKey, jsonEncode(c.toJson()));
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefKey);
  }

  /// Surahs marked memorized in «حفظي».
  Future<Set<int>> memorizedSurahs() => HifzRepository().memorizedSurahNumbers();

  /// Pages with a `memorization_progress` row — «حفظتُها» in ٣×٣ (read-only).
  Future<Set<int>> memorizedUnits() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('SELECT unit_id FROM memorization_progress');
    return {for (final r in rows) (r['unit_id'] as num).toInt()};
  }

  /// The ayat covered by [surahs] and by the pages [units].
  Future<Set<(int, int)>> _ayatOf(List<AyahLines> ayat, Set<int> surahs, Set<int> units) async {
    final out = <(int, int)>{
      for (final a in ayat)
        if (surahs.contains(a.surah)) (a.surah, a.ayah),
    };
    if (units.isEmpty) return out;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT surah_start, ayah_start, surah_end, ayah_end FROM memorization_units WHERE id IN (${List.filled(units.length, '?').join(',')})',
      units.toList(),
    );
    final index = {for (var k = 0; k < ayat.length; k++) (ayat[k].surah, ayat[k].ayah): k};
    for (final r in rows) {
      final a = index[((r['surah_start'] as num).toInt(), (r['ayah_start'] as num).toInt())];
      final b = index[((r['surah_end'] as num).toInt(), (r['ayah_end'] as num).toInt())];
      if (a == null || b == null) continue;
      for (var k = a; k <= b; k++) {
        out.add((ayat[k].surah, ayat[k].ayah));
      }
    }
    return out;
  }

  Future<HifzSchedule> schedule(HifzPlanChoice c) async {
    final ayat = await ayahLines();
    final skip = await _ayatOf(ayat, c.memorizedSurahs, c.memorizedUnits);
    return compute(
      _generate,
      _GenArgs(ayat, c.direction, c.timeline, skip, totalDays: c.totalDays, finalDays: c.finalPhaseDays, pace: c.pace),
    );
  }

  /// Where the student really is today (ح4): every ayah memorized so far —
  /// pages from ٣×٣ and surahs from «حفظي» — against the plan's days.
  Future<HifzProgress> progress(HifzPlanChoice c, HifzSchedule s) async {
    final ayat = await ayahLines();
    final live = await _ayatOf(ayat, await memorizedSurahs(), await memorizedUnits());
    return measureProgress(s, live, c.dayNumber(DateTime.now()));
  }

  /// A fresh plan from today over what is still left, never a penalty (ح4,
  /// `12-RESEARCH-BACKED-ADDENDUM.md` §c): «أدرِك» keeps the khatm date
  /// (more per day), «أبقِ وتيرتي» keeps today's load (the date moves).
  Future<HifzPlanChoice> replan(HifzPlanChoice c, HifzSchedule s, {required bool keepPace}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return HifzPlanChoice(
      direction: c.direction,
      timeline: c.timeline,
      start: today,
      end: keepPace || !c.end.isAfter(today) ? null : c.end,
      pace: keepPace ? (c.pace ?? s.linesPerDay) : null,
      memorizedSurahs: await memorizedSurahs(),
      memorizedUnits: await memorizedUnits(),
    );
  }

  /// Lines per day each timeline would need — for the plan chooser.
  Future<Map<HifzTimeline, double>> estimates(HifzDirection direction, Set<int> memorizedSurahs) async {
    final ayat = await ayahLines();
    return compute(_estimate, _GenArgs(ayat, direction, HifzTimeline.months24, await _ayatOf(ayat, memorizedSurahs, const {})));
  }

  /// A surah's name for display.
  static String surahName(int n) => quranSurahs.firstWhere((s) => s.number == n, orElse: () => quranSurahs.first).name;
}

/// The four tracks of one plan day (§3.1): today's new portion (sabaq), the
/// link from yesterday's ending (rabṭ), the last [sabqiWindow] new portions
/// (sabqī), and the manzil — everything older, a [manzilCycle]-th per day.
class HifzToday {
  final DayPlan plan;
  final DayPlan? previousNew;
  final List<DayPlan> sabqi;
  final double manzilLines;
  const HifzToday({required this.plan, required this.previousNew, required this.sabqi, required this.manzilLines});

  /// Minutes, by the §3.4 model (2 min/line new, 2.5 min/page review) —
  /// `INFERENCE` until calibrated on real use.
  int get minutes {
    final newMin = plan.kind == DayKind.newPortion ? plan.lines * 2 : 0;
    final reviewPages = (sabqi.fold<double>(0, (s, d) => s + d.lines) + manzilLines) / HifzScheduleRepository.linesPerPage;
    return (newMin + reviewPages * 2.5).round();
  }

  static const sabqiWindow = 7;
  static const manzilCycle = 30;

  static HifzToday? of(HifzSchedule s, int dayNumber) {
    if (dayNumber < 1 || dayNumber > s.days.length) return null;
    final idx = dayNumber - 1;
    final before = s.days.take(idx).where((d) => d.kind == DayKind.newPortion).toList();
    final sabqi = before.length <= sabqiWindow ? before : before.sublist(before.length - sabqiWindow);
    final older = before.length <= sabqiWindow ? <DayPlan>[] : before.sublist(0, before.length - sabqiWindow);
    final olderLines = older.fold<double>(0, (t, d) => t + d.lines);
    return HifzToday(
      plan: s.days[idx],
      previousNew: before.isEmpty ? null : before.last,
      sabqi: sabqi,
      manzilLines: olderLines / manzilCycle,
    );
  }
}
