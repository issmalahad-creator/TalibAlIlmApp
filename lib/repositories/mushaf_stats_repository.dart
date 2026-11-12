import '../db/database_helper.dart';
import '../services/boot/boot_scheduler.dart';
import '../services/mushaf_stats.dart';

/// What part of the muṣḥaf to count.
enum StatsScopeKind { all, surah, juz, hizb, page }

class StatsScope {
  final StatsScopeKind kind;
  final int value; // surah / juz / hizb / page number; ignored for [all]
  const StatsScope(this.kind, [this.value = 0]);
  static const all = StatsScope(StatsScopeKind.all);

  @override
  bool operator ==(Object other) => other is StatsScope && other.kind == kind && other.value == value;
  @override
  int get hashCode => Object.hash(kind, value);
}

/// Counts plus where they sit in the printed muṣḥaf.
class ScopedStats {
  final StatsScope scope;
  final MushafStats stats;
  final int pages;
  final int lines;
  final AyahRef first;
  final AyahRef last;
  const ScopedStats({required this.scope, required this.stats, required this.pages, required this.lines, required this.first, required this.last});
}

/// «إحصاءات المصحف» data: reads the Uthmani text for a scope from
/// `quran_ayat` and counts it with [countMushaf]. Results are kept in memory
/// for the session (the text never changes); the whole muṣḥaf is counted on
/// a background isolate.
class MushafStatsRepository {
  MushafStatsRepository._();
  static final instance = MushafStatsRepository._();

  final _cache = <StatsScope, ScopedStats>{};

  Future<ScopedStats> stats(StatsScope scope) async {
    final hit = _cache[scope];
    if (hit != null) return hit;
    await BootScheduler.instance.ensure(BootTasks.quranImport);
    final db = await DatabaseHelper.instance.database;
    final (where, args) = switch (scope.kind) {
      StatsScopeKind.all => (null, null),
      StatsScopeKind.surah => ('surah = ?', [scope.value]),
      StatsScopeKind.juz => ('juz_number = ?', [scope.value]),
      StatsScopeKind.hizb => ('hizb_number = ?', [scope.value]),
      StatsScopeKind.page => ('page_number = ?', [scope.value]),
    };
    final rows = await db.query('quran_ayat',
        columns: ['surah', 'ayah', 'text_uthmani', 'page_number'], where: where, whereArgs: args, orderBy: 'surah, ayah');
    if (rows.isEmpty) throw StateError('no ayat for $scope');
    final texts = [
      for (final r in rows) (surah: r['surah'] as int, ayah: r['ayah'] as int, text: r['text_uthmani'] as String),
    ];
    final counted = scope.kind == StatsScopeKind.all ? await computeMushafStats(texts) : countMushaf(texts);
    final pages = rows.map((r) => r['page_number']).toSet().length;
    final first = (surah: texts.first.surah, ayah: texts.first.ayah);
    final last = (surah: texts.last.surah, ayah: texts.last.ayah);
    // Printed text lines the scope's ayat occupy (a line shared with a
    // neighbouring surah counts for both).
    final lineRows = await db.rawQuery(
      'SELECT COUNT(DISTINCT page * 100 + line) AS n FROM mushaf_words '
      'WHERE surah * 1000 + ayah BETWEEN ? AND ?',
      [first.surah * 1000 + first.ayah, last.surah * 1000 + last.ayah],
    );
    final lines = (lineRows.first['n'] as num?)?.toInt() ?? 0;
    return _cache[scope] = ScopedStats(scope: scope, stats: counted, pages: pages, lines: lines, first: first, last: last);
  }
}
