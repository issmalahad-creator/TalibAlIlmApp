/// Damerau-Levenshtein-distance-based fuzzy matching — pure
/// character-comparison arithmetic, no language-specific rules, so it works
/// identically on Arabic, English, or any other script. Extracted from
/// `companion_chat_engine.dart` (2026-08-18) so the same "closest match,
/// not just exact match" capability can be reused by Quran text search,
/// adhkar category lookup, and navigation target matching — "تخيل انه بحث
/// عام... مثل اليوتيوب" (Ismail): never return nothing when something close
/// exists, but never guess wildly either — callers keep their own
/// similarity thresholds.
///
/// Upgraded 2026-08-18 from plain Levenshtein to Damerau-Levenshtein
/// (adjacent-transposition counts as one edit, not two) after Ismail asked
/// to look at how real search engines (his example: YouTube) do typo
/// tolerance — industry sources (Algolia, Meilisearch) confirm
/// Damerau-Levenshtein specifically, citing Damerau's original 1964 finding
/// that transpositions ("teh" for "the") are one of the most common
/// single-edit typos alongside insert/delete/substitute; plain Levenshtein
/// scores a transposition as 2 edits and can miss it. Tolerance thresholds
/// below (exact-only ≤3 chars, 1 edit for 4-7, 2 edits for 8+) mirror the
/// same sources' documented length-adaptive tiers rather than the
/// previously-guessed 5-char cutoff.
library;

/// Same word, or close enough to be a likely typo. Very short words require
/// an exact match — fuzzy-matching 1-3 letter words produces nonsense
/// collisions (too many real words sit within 1 edit of each other at that
/// length).
bool isFuzzyMatch(String a, String b) {
  if (a == b) return true;
  final maxLen = a.length > b.length ? a.length : b.length;
  if (maxLen <= 3) return false;
  final allowedDistance = maxLen <= 7 ? 1 : 2;
  return damerauLevenshteinDistance(a, b) <= allowedDistance;
}

/// Levenshtein distance plus adjacent-transposition as a single edit
/// (Damerau's restricted variant — sufficient for typo tolerance, doesn't
/// need the full unrestricted algorithm's extra complexity).
int damerauLevenshteinDistance(String s, String t) {
  if (s == t) return 0;
  final m = s.length, n = t.length;
  if (m == 0) return n;
  if (n == 0) return m;

  var prev2 = List<int>.filled(n + 1, 0);
  var prev = List<int>.generate(n + 1, (j) => j);
  for (var i = 1; i <= m; i++) {
    final curr = List<int>.filled(n + 1, 0);
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = s[i - 1] == t[j - 1] ? 0 : 1;
      final deletion = prev[j] + 1;
      final insertion = curr[j - 1] + 1;
      final substitution = prev[j - 1] + cost;
      var best = [deletion, insertion, substitution].reduce((x, y) => x < y ? x : y);
      if (i > 1 && j > 1 && s[i - 1] == t[j - 2] && s[i - 2] == t[j - 1]) {
        final transposition = prev2[j - 2] + 1;
        if (transposition < best) best = transposition;
      }
      curr[j] = best;
    }
    prev2 = prev;
    prev = curr;
  }
  return prev[n];
}
