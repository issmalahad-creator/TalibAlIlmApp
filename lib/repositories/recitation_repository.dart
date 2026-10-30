import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';
import '../utils/recitation_alignment.dart';
import '../utils/recitation_text.dart';
import 'quran_reading_repository.dart';

/// A previously-recited ayah's real result, for the mistake-history list
/// (76.3e) — mirrors Tarteel's real "Mistake History/Frequency" feature.
class RecurringRecitationMistake {
  final int surah;
  final int ayah;
  final String expectedWord;
  final int timesWrong;
  const RecurringRecitationMistake({required this.surah, required this.ayah, required this.expectedWord, required this.timesWrong});
}

/// One ayah's slice of a whole-page recitation result — see
/// [RecitationRepository.recordPageAttempt].
class AyahRecitationSlice {
  final int surah;
  final int ayah;
  final RecitationAlignmentResult result;
  const AyahRecitationSlice({required this.surah, required this.ayah, required this.result});
}

/// A whole page's continuous recitation, sliced back into its ayat
/// (76.3-redesign — Ismail 2026-08-28: "لا أريد آية بآية"). Each ayah's
/// slice is still a real, independently-scored [RecitationAlignmentResult]
/// -- this just groups them for the page-level UI/session summary.
class PageRecitationResult {
  final List<AyahRecitationSlice> ayat;
  const PageRecitationResult(this.ayat);

  double get overallScore {
    final totalExpected = ayat.fold<int>(0, (s, a) => s + a.result.totalExpected);
    if (totalExpected == 0) return 1.0;
    final totalCorrect = ayat.fold<int>(0, (s, a) => s + a.result.correctCount);
    return totalCorrect / totalExpected;
  }
}

/// One recitable word of a muṣḥaf page, with its real identity (ت3): the
/// page's words come from `mushaf_words` — the same Madinah-muṣḥaf page the
/// reader shows — never from the older Tanzil page numbering.
class RecitationWord {
  final int surah;
  final int ayah;
  final int wordIndex;
  final int line;
  final String text;

  /// Muṣḥaf words this recited word covers: 2 when the layout's standalone
  /// «وَ» was joined to it, else 1 (`wordIndex` is the first of them).
  final int span;
  const RecitationWord({required this.surah, required this.ayah, required this.wordIndex, required this.line, required this.text, this.span = 1});

  /// The `(surah, ayah, wordIndex)` keys of the muṣḥaf words it covers.
  Iterable<(int, int, int)> get keys sync* {
    for (var k = 0; k < span; k++) {
      yield (surah, ayah, wordIndex + k);
    }
  }
}

/// Backs "تسميع" (Phase 76.3) — stores every real recitation-practice
/// attempt and its word-level mistakes, computed by
/// `alignRecitation` (`lib/utils/recitation_alignment.dart`). Never stores
/// a tajweed/pronunciation-quality judgment — only missing/wrong/extra
/// words, the same honest scope documented in TODO.md 76.3g and verified
/// against Tarteel's own real shipped feature.
class RecitationRepository {
  /// Runs the real alignment, persists the session + its word mistakes,
  /// and returns the alignment result for the screen to render immediately
  /// — the caller doesn't need a second query to show the result it just
  /// produced.
  Future<RecitationAlignmentResult> recordAttempt({
    required int surah,
    required int ayah,
    required String mode,
    required List<String> expectedWords,
    required List<String> saidWords,
  }) async {
    final result = alignRecitation(
      expectedWords: expectedWords.where((w) => !isSilentMark(w)).toList(),
      saidWords: splitRecitedTranscript(saidWords.join(' ')),
    );
    final db = await DatabaseHelper.instance.database;
    await _persistSlice(db, surah: surah, ayah: ayah, mode: mode, result: result);
    return result;
  }

  /// A whole page's continuous recitation (76.3-redesign) in one pass:
  /// concatenates every ayah's expected words, runs [alignRecitation]
  /// ONCE across the full page (the alignment engine doesn't care how
  /// many words it's given), then slices the single result back into
  /// per-ayah [AyahRecitationSlice]s using each ayah's own real word
  /// count as a cumulative boundary -- and persists each slice as its own
  /// row in the exact same `recitation_sessions`/`recitation_mistakes`
  /// tables [recordAttempt] uses, so no schema change was needed for
  /// page-scale sessions.
  Future<PageRecitationResult> recordPageAttempt({
    required List<QuranAyahText> ayat,
    required String mode,
    required List<String> saidWords,
  }) async {
    final expectedWordsPerAyah = ayat.map((a) => a.text.split(' ')).toList();
    final flatExpected = expectedWordsPerAyah.expand((w) => w).toList();
    final pageResult = alignRecitation(expectedWords: flatExpected, saidWords: saidWords);

    final slices = <AyahRecitationSlice>[];
    var wordCursor = 0;
    var extraCursor = 0;
    for (var ayahIdx = 0; ayahIdx < ayat.length; ayahIdx++) {
      final count = expectedWordsPerAyah[ayahIdx].length;
      final sliceEnd = wordCursor + count;
      final sliceWords = pageResult.words.sublist(wordCursor, sliceEnd);

      // Extras said up through the end of this ayah's words (and before
      // the next ayah's first word) are attributed to this ayah -- see
      // RecitationAlignmentResult.extraWordPositions' doc comment.
      var extrasHere = 0;
      while (extraCursor < pageResult.extraWordPositions.length && pageResult.extraWordPositions[extraCursor] <= sliceEnd) {
        extrasHere++;
        extraCursor++;
      }

      slices.add(AyahRecitationSlice(
        surah: ayat[ayahIdx].surah,
        ayah: ayat[ayahIdx].ayah,
        result: RecitationAlignmentResult(words: sliceWords, extraWordCount: extrasHere),
      ));
      wordCursor = sliceEnd;
    }

    final db = await DatabaseHelper.instance.database;
    for (final slice in slices) {
      await _persistSlice(db, surah: slice.surah, ayah: slice.ayah, mode: mode, result: slice.result);
    }

    return PageRecitationResult(slices);
  }

  Future<int> _persistSlice(
    Database db, {
    required int surah,
    required int ayah,
    required String mode,
    required RecitationAlignmentResult result,
    List<int>? wordIndexes,
  }) async {
    final sessionId = await db.insert('recitation_sessions', {
      'surah': surah,
      'ayah': ayah,
      'mode': mode,
      'score': result.score,
      'extra_word_count': result.extraWordCount,
      'created_at': todayDate(),
    });

    final batch = db.batch();
    for (var i = 0; i < result.words.length; i++) {
      final w = result.words[i];
      if (w.status == RecitationWordStatus.correct) continue;
      batch.insert('recitation_mistakes', {
        'session_id': sessionId,
        'surah': surah,
        'ayah': ayah,
        'word_index': wordIndexes != null ? wordIndexes[i] : i,
        'expected_word': w.expectedWord,
        'said_word': w.saidWord,
        'status': w.status.name,
      });
    }
    await batch.commit(noResult: true);
    return sessionId;
  }

  /// The words of muṣḥaf page [page] in reading order, waqf signs and other
  /// silent marks left out (they are never pronounced — ت1).
  Future<List<RecitationWord>> pageWords(int page) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'mushaf_words',
      columns: ['surah', 'ayah', 'word_index', 'line', 'text_uthmani'],
      where: "page = ? AND word_type = 'text'",
      whereArgs: [page],
      orderBy: 'word_order',
    );
    final out = <RecitationWord>[];
    String? pendingWaw;
    for (final r in rows) {
      final text = r['text_uthmani'] as String;
      if (isSilentMark(text)) continue;
      // The layout stores the conjunction «وَ» as a word of its own (9,533
      // times); it is always said joined to the next word («ويقيمون»), so it
      // is recited — and judged — as part of that word.
      if (recitationKey(text) == 'و') {
        pendingWaw = (pendingWaw ?? '') + text;
        continue;
      }
      out.add(RecitationWord(
        surah: (r['surah'] as num).toInt(),
        ayah: (r['ayah'] as num).toInt(),
        wordIndex: (r['word_index'] as num).toInt() - (pendingWaw == null ? 0 : 1),
        line: (r['line'] as num).toInt(),
        text: (pendingWaw ?? '') + text,
        span: pendingWaw == null ? 1 : 2,
      ));
      pendingWaw = null;
    }
    return out;
  }

  /// Saves exactly what the student saw (ت2: saved = shown). [statuses] holds
  /// one entry per word of [words]; null means the student never reached it —
  /// it is not a mistake and its ayah is saved only if part of it was
  /// recited. [extras] counts extra said words per ayah.
  Future<PageRecitationResult> recordPageResult({
    required List<RecitationWord> words,
    required List<RecitationWordStatus?> statuses,
    required List<String?> said,
    Map<(int, int), int> extras = const {},
    String mode = 'recite',
  }) async {
    final page = slicePage(words: words, statuses: statuses, said: said, extras: extras);
    final db = await DatabaseHelper.instance.database;
    for (final slice in page.ayat) {
      await _persistSlice(db,
          surah: slice.surah,
          ayah: slice.ayah,
          mode: mode,
          result: slice.result,
          wordIndexes: [
            for (var k = 0; k < words.length; k++)
              if (statuses[k] != null && words[k].surah == slice.surah && words[k].ayah == slice.ayah) words[k].wordIndex,
          ]);
    }
    return page;
  }

  /// Groups per-word statuses into per-ayah results, in page order; ayat with
  /// no reached word are left out. Pure — the screen shows exactly this.
  static PageRecitationResult slicePage({
    required List<RecitationWord> words,
    required List<RecitationWordStatus?> statuses,
    required List<String?> said,
    Map<(int, int), int> extras = const {},
  }) {
    final byAyah = <(int, int), List<int>>{};
    for (var k = 0; k < words.length; k++) {
      if (statuses[k] == null) continue;
      byAyah.putIfAbsent((words[k].surah, words[k].ayah), () => []).add(k);
    }
    return PageRecitationResult([
      for (final entry in byAyah.entries)
        AyahRecitationSlice(
          surah: entry.key.$1,
          ayah: entry.key.$2,
          result: RecitationAlignmentResult(
            words: [
              for (final k in entry.value)
                RecitationWordResult(expectedWord: words[k].text, saidWord: said[k], status: statuses[k]!),
            ],
            extraWordCount: extras[entry.key] ?? 0,
          ),
        ),
    ]);
  }

  /// The ayat a student keeps making real mistakes on, most-frequent
  /// first — the actual data behind a "needs more practice" list.
  Future<List<RecurringRecitationMistake>> recurringMistakes({int limit = 10, int sinceDays = 30}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT surah, ayah, expected_word, COUNT(*) AS times_wrong
      FROM recitation_mistakes
      GROUP BY surah, ayah, expected_word
      ORDER BY times_wrong DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows
        .map((r) => RecurringRecitationMistake(
              surah: r['surah'] as int,
              ayah: r['ayah'] as int,
              expectedWord: r['expected_word'] as String,
              timesWrong: r['times_wrong'] as int,
            ))
        .toList();
  }

  /// Real session history for one ayah, most recent first — the score
  /// trend a student can see improving over time.
  Future<List<(String date, double score)>> sessionHistory(int surah, int ayah, {int limit = 20}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'recitation_sessions',
      columns: ['created_at', 'score'],
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map((r) => (r['created_at'] as String, r['score'] as double)).toList();
  }
}
