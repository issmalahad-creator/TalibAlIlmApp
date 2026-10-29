import 'recitation_text.dart';

/// How one word of the *expected* ayah text compares to what the student
/// actually said, after alignment.
enum RecitationWordStatus { correct, missing, wrong }

class RecitationWordResult {
  final String expectedWord;
  final String? saidWord;
  final RecitationWordStatus status;
  const RecitationWordResult({required this.expectedWord, this.saidWord, required this.status});
}

class RecitationAlignmentResult {
  final List<RecitationWordResult> words;
  final int extraWordCount;

  /// Where each extra (said-but-not-expected) word falls, in forward
  /// reading order, as an index into [words] — value `k` means "this
  /// extra was said immediately before the word at `words[k]`" (or, if
  /// `k == words.length`, "after the last expected word"). Lets a page-
  /// level caller (76.3-redesign) attribute each extra word to the right
  /// ayah when slicing one page-wide alignment back into per-ayah rows —
  /// without this, extras from a whole page could only be dumped
  /// arbitrarily onto one ayah, which would be fabricated data, not a
  /// real per-ayah count.
  final List<int> extraWordPositions;

  const RecitationAlignmentResult({required this.words, required this.extraWordCount, this.extraWordPositions = const []});

  int get correctCount => words.where((w) => w.status == RecitationWordStatus.correct).length;
  int get totalExpected => words.length;
  double get score => totalExpected == 0 ? 1.0 : correctCount / totalExpected;
}

/// Aligns what the student recited against the real expected ayah text,
/// word by word — the actual comparison engine behind "تسميع" (Phase
/// 76.3). Deterministic, no AI judging correctness: a word-level edit-
/// distance alignment (Needleman-Wunsch style dynamic programming), using
/// [recitationWordsMatch] as the per-word equality check: both sides are
/// reduced to the same plain key first (Uthmani tashkeel vs. the
/// recognizer's modern spelling — ت1), then a single mis-transcribed letter
/// is tolerated by the shared fuzzy matcher.
///
/// Deliberately scoped like Tarteel's own real shipped feature (verified
/// against their screenshots, TODO.md 76.3): flags missing/extra/wrong
/// words only. Never claims to grade tajweed or makharij — that's a real,
/// separate, much harder problem this function does not attempt.
RecitationAlignmentResult alignRecitation({required List<String> expectedWords, required List<String> saidWords}) {
  final m = expectedWords.length;
  final n = saidWords.length;

  // dp[i][j] = min edit operations to align expected[0..i) with said[0..j)
  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final match = recitationWordsMatch(expectedWords[i - 1], saidWords[j - 1]);
      final substitutionOrMatch = dp[i - 1][j - 1] + (match ? 0 : 1);
      final deletion = dp[i - 1][j] + 1; // expected word missing from recitation
      final insertion = dp[i][j - 1] + 1; // extra word said that isn't in the ayah
      dp[i][j] = [substitutionOrMatch, deletion, insertion].reduce((a, b) => a < b ? a : b);
    }
  }

  // Backtrack to recover the actual alignment, not just the distance.
  final words = <RecitationWordResult>[];
  final extraPositions = <int>[]; // raw backward `i` values; reversed below
  var i = m, j = n;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + (recitationWordsMatch(expectedWords[i - 1], saidWords[j - 1]) ? 0 : 1)) {
      final match = recitationWordsMatch(expectedWords[i - 1], saidWords[j - 1]);
      words.add(RecitationWordResult(
        expectedWord: expectedWords[i - 1],
        saidWord: saidWords[j - 1],
        status: match ? RecitationWordStatus.correct : RecitationWordStatus.wrong,
      ));
      i--;
      j--;
    } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
      words.add(RecitationWordResult(expectedWord: expectedWords[i - 1], status: RecitationWordStatus.missing));
      i--;
    } else {
      // `i` here is the forward index (0-based, out of m) of the next
      // not-yet-placed expected word -- i.e. this extra was said
      // immediately before words[i] in forward order (or after the last
      // expected word, if i == m). See extraWordPositions' doc comment.
      extraPositions.add(i);
      j--;
    }
  }

  return RecitationAlignmentResult(
    words: words.reversed.toList(),
    extraWordCount: extraPositions.length,
    extraWordPositions: extraPositions.reversed.toList(),
  );
}

/// One recognizer segment aligned against what is still left to recite (ت2).
///
/// Unlike [alignRecitation], the expected words the student has not reached
/// yet cost nothing: the student pausing after three ayat must not turn the
/// rest of the page into "missing". [consumed] is how many expected words the
/// segment actually covered — the caller commits only those; the rest stay
/// pending for the next segment.
class RecitationSegmentResult {
  /// Results for `expected[0 .. consumed)` only.
  final List<RecitationWordResult> words;
  final int extraWordCount;
  int get consumed => words.length;
  const RecitationSegmentResult({required this.words, required this.extraWordCount});
}

RecitationSegmentResult alignRecitationSegment({required List<String> expectedWords, required List<String> saidWords}) {
  final m = expectedWords.length;
  final n = saidWords.length;
  if (n == 0 || m == 0) return RecitationSegmentResult(words: const [], extraWordCount: n);

  final match = List.generate(m, (i) => List<bool>.generate(n, (j) => recitationWordsMatch(expectedWords[i], saidWords[j])));
  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final sub = dp[i - 1][j - 1] + (match[i - 1][j - 1] ? 0 : 1);
      final del = dp[i - 1][j] + 1;
      final ins = dp[i][j - 1] + 1;
      dp[i][j] = sub < del ? (sub < ins ? sub : ins) : (del < ins ? del : ins);
    }
  }

  // Free trailing expected words: end at the row with the lowest cost once
  // every said word is used. Ties go to the furthest row whose last step is a
  // real match, so a correct segment always advances fully.
  var bestI = 0;
  for (var i = 1; i <= m; i++) {
    if (dp[i][n] < dp[bestI][n] || (dp[i][n] == dp[bestI][n] && match[i - 1][n - 1])) bestI = i;
  }

  final words = <RecitationWordResult>[];
  var extras = 0;
  var i = bestI, j = n;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + (match[i - 1][j - 1] ? 0 : 1)) {
      words.add(RecitationWordResult(
        expectedWord: expectedWords[i - 1],
        saidWord: saidWords[j - 1],
        status: match[i - 1][j - 1] ? RecitationWordStatus.correct : RecitationWordStatus.wrong,
      ));
      i--;
      j--;
    } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
      words.add(RecitationWordResult(expectedWord: expectedWords[i - 1], status: RecitationWordStatus.missing));
      i--;
    } else {
      extras++;
      j--;
    }
  }
  final forward = words.reversed.toList();

  // Never end a segment on a guess: trailing non-matches stay pending (the
  // student usually repeats them after the pause); the said words they used
  // count as extra for this segment only.
  while (forward.isNotEmpty && forward.last.status != RecitationWordStatus.correct) {
    final dropped = forward.removeLast();
    if (dropped.status == RecitationWordStatus.wrong) extras++;
  }
  return RecitationSegmentResult(words: forward, extraWordCount: extras);
}
