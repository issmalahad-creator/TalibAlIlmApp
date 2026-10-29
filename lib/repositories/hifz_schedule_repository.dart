import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_surahs.dart';
import '../db/database_helper.dart';
import '../services/hifz/schedule_generator.dart';
import '../utils/calendar_days.dart';
import 'hifz_repository.dart';

/// The student's chosen hifz plan (ح2 of
/// `docs/memorization/HIFZ_SCHEDULE_ARCHITECTURE.md`). Only the choice is
/// stored — the days themselves are always generated from it (§5.1).
class HifzPlanChoice {
  final HifzDirection direction;
  final HifzTimeline timeline;
  final DateTime start;

  /// Surahs already memorized when the plan was made (from «حفظي»); their
  /// ayat are not scheduled again.
  final Set<int> memorizedSurahs;
  const HifzPlanChoice({required this.direction, required this.timeline, required this.start, this.memorizedSurahs = const {}});

  Map<String, Object> toJson() => {
        'direction': direction.name,
        'timeline': timeline.name,
        'start': '${start.year}-${start.month}-${start.day}',
        'memorized': memorizedSurahs.toList(),
      };

  static HifzPlanChoice? fromJson(Map<String, dynamic> j) {
    try {
      final d = (j['start'] as String).split('-').map(int.parse).toList();
      return HifzPlanChoice(
        direction: HifzDirection.values.byName(j['direction'] as String),
        timeline: HifzTimeline.values.byName(j['timeline'] as String),
        start: DateTime(d[0], d[1], d[2]),
        memorizedSurahs: {for (final s in j['memorized'] as List) s as int},
      );
    } catch (_) {
      return null;
    }
  }

  /// 1-based day of the plan today (0 before it starts).
  int dayNumber(DateTime today) => calendarDaysBetween(start, today) + 1;
}

class _GenArgs {
  final List<AyahLines> ayat;
  final HifzDirection direction;
  final HifzTimeline timeline;
  final Set<(int, int)> skip;
  const _GenArgs(this.ayat, this.direction, this.timeline, this.skip);
}

HifzSchedule _generate(_GenArgs a) =>
    generateSchedule(mushafOrder: a.ayat, direction: a.direction, timeline: a.timeline, alreadyMemorized: a.skip);

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

  Set<(int, int)> _skip(List<AyahLines> ayat, Set<int> surahs) => {
        for (final a in ayat)
          if (surahs.contains(a.surah)) (a.surah, a.ayah),
      };

  Future<HifzSchedule> schedule(HifzPlanChoice c) async {
    final ayat = await ayahLines();
    return compute(_generate, _GenArgs(ayat, c.direction, c.timeline, _skip(ayat, c.memorizedSurahs)));
  }

  /// Lines per day each timeline would need — for the plan chooser.
  Future<Map<HifzTimeline, double>> estimates(HifzDirection direction, Set<int> memorizedSurahs) async {
    final ayat = await ayahLines();
    return compute(_estimate, _GenArgs(ayat, direction, HifzTimeline.months24, _skip(ayat, memorizedSurahs)));
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
