import '../db/database_helper.dart';
import '../utils/hijri_date.dart';

/// The kind of one logged mistake, named after the taxonomy of
/// `docs/memorization/09-ERROR-REPAIR-ENGINE.md` §1 where one applies.
enum MistakeKind {
  /// A word the student skipped (`omission`).
  omission,

  /// A word said differently (`substitution`).
  substitution,

  /// Words said that are not in the ayah.
  addition,

  /// The student's own «يحتاج مراجعة» rating of a page review, with its note.
  selfRated,
}

class MistakeEntry {
  final MistakeKind kind;
  final int surah;
  final int ayah;

  /// The muṣḥaf word (omission / substitution), else null.
  final String? word;

  /// What the recognizer heard instead (substitution), else null.
  final String? said;

  /// Extra words said (addition), else null.
  final int? count;
  final String? note;
  final String date;
  const MistakeEntry({required this.kind, required this.surah, required this.ayah, required this.date, this.word, this.said, this.count, this.note});
}

/// One page of the log: its mistakes grouped by ayah (a self-rated page
/// review has no single ayah and is kept apart).
class PageMistakes {
  final int page;
  final Map<(int, int), List<MistakeEntry>> byAyah;
  final List<MistakeEntry> pageLevel;
  const PageMistakes({required this.page, required this.byAyah, required this.pageLevel});

  int get total => byAyah.values.fold(0, (s, l) => s + l.length) + pageLevel.length;
  String get lastDate => [
        for (final l in byAyah.values) ...l.map((e) => e.date),
        ...pageLevel.map((e) => e.date),
      ].reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
}

/// «سجل الأخطاء» as one log (ت5 of `RECITATION_REBUILD_PLAN.md`).
///
/// The app had two separate logs: word-level recitation mistakes
/// (`recitation_mistakes` + `recitation_sessions`) and self-rated page reviews
/// (`mistake_log`). Both stay where they are — this reads them together, by
/// the reader's Madinah-muṣḥaf page, so no stored progress is migrated or
/// touched.
class MistakeLogRepository {
  /// Every page with a mistake in the last [sinceDays] days, in muṣḥaf order;
  /// inside a page, ayat in order and each ayah's entries newest first.
  Future<List<PageMistakes>> pages({int sinceDays = 90}) async {
    final db = await DatabaseHelper.instance.database;
    // Stored dates are the app's Hijri «yyyy-MM-dd» strings (`todayDate()`).
    final since = hijriDateStringForDate(DateTime.now().subtract(Duration(days: sinceDays)));
    const pageOf = '(SELECT MIN(page) FROM mushaf_words w WHERE w.surah = %s AND w.ayah = %s)';

    final words = await db.rawQuery('''
      SELECT m.surah, m.ayah, m.expected_word, m.said_word, m.status, s.created_at AS d,
             ${pageOf.replaceFirst('%s', 'm.surah').replaceFirst('%s', 'm.ayah')} AS page
      FROM recitation_mistakes m JOIN recitation_sessions s ON s.id = m.session_id
      WHERE s.created_at >= ?
    ''', [since]);
    final extras = await db.rawQuery('''
      SELECT s.surah, s.ayah, s.extra_word_count AS n, s.created_at AS d,
             ${pageOf.replaceFirst('%s', 's.surah').replaceFirst('%s', 's.ayah')} AS page
      FROM recitation_sessions s
      WHERE s.extra_word_count > 0 AND s.created_at >= ?
    ''', [since]);
    final rated = await db.rawQuery('''
      SELECT u.surah_start AS surah, u.ayah_start AS ayah, l.note, l.logged_date AS d,
             ${pageOf.replaceFirst('%s', 'u.surah_start').replaceFirst('%s', 'u.ayah_start')} AS page
      FROM mistake_log l JOIN memorization_units u ON u.id = l.unit_id
      WHERE l.logged_date >= ?
    ''', [since]);

    final byPage = <int, PageMistakes>{};
    PageMistakes pageFor(Object? p) {
      final page = (p as num?)?.toInt() ?? 0;
      return byPage.putIfAbsent(page, () => PageMistakes(page: page, byAyah: {}, pageLevel: []));
    }

    void add(Object? page, MistakeEntry e) => pageFor(page).byAyah.putIfAbsent((e.surah, e.ayah), () => []).add(e);

    for (final r in words) {
      add(
        r['page'],
        MistakeEntry(
          kind: r['status'] == 'missing' ? MistakeKind.omission : MistakeKind.substitution,
          surah: r['surah'] as int,
          ayah: r['ayah'] as int,
          word: r['expected_word'] as String?,
          said: r['said_word'] as String?,
          date: r['d'] as String,
        ),
      );
    }
    for (final r in extras) {
      add(
        r['page'],
        MistakeEntry(kind: MistakeKind.addition, surah: r['surah'] as int, ayah: r['ayah'] as int, count: r['n'] as int, date: r['d'] as String),
      );
    }
    for (final r in rated) {
      pageFor(r['page']).pageLevel.add(MistakeEntry(
            kind: MistakeKind.selfRated,
            surah: r['surah'] as int,
            ayah: r['ayah'] as int,
            note: r['note'] as String?,
            date: r['d'] as String,
          ));
    }

    final out = byPage.values.where((p) => p.page > 0).toList()..sort((a, b) => a.page.compareTo(b.page));
    for (final p in out) {
      final sorted = p.byAyah.keys.toList()..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
      final ordered = {for (final k in sorted) k: p.byAyah[k]!..sort((a, b) => b.date.compareTo(a.date))};
      p.byAyah
        ..clear()
        ..addAll(ordered);
      p.pageLevel.sort((a, b) => b.date.compareTo(a.date));
    }
    return out;
  }
}
