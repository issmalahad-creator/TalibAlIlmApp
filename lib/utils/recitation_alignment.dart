import 'fuzzy_match.dart';

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
  const RecitationAlignmentResult({required this.words, required this.extraWordCount});

  int get correctCount => words.where((w) => w.status == RecitationWordStatus.correct).length;
  int get totalExpected => words.length;
  double get score => totalExpected == 0 ? 1.0 : correctCount / totalExpected;
}

/// Aligns what the student recited against the real expected ayah text,
/// word by word — the actual comparison engine behind "تسميع" (Phase
/// 76.3). Deterministic, no AI judging correctness: a word-level edit-
/// distance alignment (Needleman-Wunsch style dynamic programming), using
/// [isFuzzyMatch] (already built for the companion chat / search, reused
/// here rather than a second matcher) as the per-word equality check so a
/// single mis-transcribed letter isn't scored as a real mistake.
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
      final match = isFuzzyMatch(expectedWords[i - 1], saidWords[j - 1]);
      final substitutionOrMatch = dp[i - 1][j - 1] + (match ? 0 : 1);
      final deletion = dp[i - 1][j] + 1; // expected word missing from recitation
      final insertion = dp[i][j - 1] + 1; // extra word said that isn't in the ayah
      dp[i][j] = [substitutionOrMatch, deletion, insertion].reduce((a, b) => a < b ? a : b);
    }
  }

  // Backtrack to recover the actual alignment, not just the distance.
  final words = <RecitationWordResult>[];
  var extraWordCount = 0;
  var i = m, j = n;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + (isFuzzyMatch(expectedWords[i - 1], saidWords[j - 1]) ? 0 : 1)) {
      final match = isFuzzyMatch(expectedWords[i - 1], saidWords[j - 1]);
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
      extraWordCount++;
      j--;
    }
  }

  return RecitationAlignmentResult(words: words.reversed.toList(), extraWordCount: extraWordCount);
}
