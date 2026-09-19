/// Pure text-anchoring for study annotations (Phase 79 «علامات الدراسة»,
/// see `docs/STUDY_ANNOTATIONS_DESIGN.md`). No Flutter, no database — given
/// the current normalised page text plus a stored anchor, it says where (if
/// anywhere) the annotation's **full** range sits in that text now.
///
/// The stored `selected_text` is always the entire selection; `head_anchor`
/// / `tail_anchor` / `prefix_context` / `suffix_context` are locators only,
/// never the selection itself.
library;

import 'arabic_normalize.dart';

/// Bump whenever [normalizePageText] changes. Stored per annotation
/// (`norm_version`) so a resolver can tell a stale-normalisation offset from
/// a genuinely moved one.
const int kNormVersion = 3;

const int _contextLen = 48; // prefix/suffix window
const int _headTailLen = 64; // head/tail locator window
const double _fuzzyThreshold = 0.72;

/// The ONE normalisation applied to raw turath page text before any offset
/// is taken or resolved. Must be byte-identical at capture time and at load
/// time — hence [kNormVersion]. Keeps the text as displayed (this is NOT
/// [normalizeArabicForSearch], which is for match-only and mangles letters).

String normalizePageText(String raw) {
  // Only literal-string replaceAll for the whitespace work (no regex
  // quantifiers): real OCR'd pages carry very long runs of spaces, and a
  // greedy pattern before a required char backtracks O(n^2) on them --
  // seconds of frozen UI. Literal replaceAll is linear; the while loops
  // converge in O(log run-length) passes.
  var s = _stripTags(raw);
  s = _decodeHtmlEntities(s);
  s = s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  s = s.replaceAll('\t', ' ').replaceAll('\u00A0', ' ');
  while (s.contains('  ')) {
    s = s.replaceAll('  ', ' ');
  }
  s = s.replaceAll(' \n', '\n').replaceAll('\n ', '\n');
  while (s.contains('\n\n\n')) {
    s = s.replaceAll('\n\n\n', '\n\n');
  }
  return s.trim();
}

/// Linear HTML-tag strip (no regex): `<[^>]*>` backtracks O(n^2) on a page
/// with many `<` and no matching `>`, which real OCR'd pages have.
String _stripTags(String s) {
  if (!s.contains('<') || !s.contains('>')) return s;
  final b = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final lt = s.indexOf('<', i);
    if (lt == -1) {
      b.write(s.substring(i));
      break;
    }
    b.write(s.substring(i, lt));
    final gt = s.indexOf('>', lt + 1);
    if (gt == -1) {
      b.write(s.substring(lt));
      break;
    }
    if (gt - lt <= 2048) {
      i = gt + 1; // a real tag -- drop it
    } else {
      b.write('<'); // absurdly long -- it's prose, keep the bracket
      i = lt + 1;
    }
  }
  return b.toString();
}

/// `\s{0,3}` (bounded, not `*`) so this can never backtrack catastrophically
/// on the same kind of long OCR'd runs `_stripTags` above guards against.
final RegExp _htmlEntityPattern = RegExp(
  r'&\s{0,3}(amp|quot|apos|lt|gt|nbsp)\s{0,3};'
  r'|&\s{0,3}#\s{0,3}(\d{1,7})\s{0,3};'
  r'|&\s{0,3}#\s{0,3}[xX]\s{0,3}([0-9a-fA-F]{1,6})\s{0,3};',
);

const Map<String, String> _namedHtmlEntities = {
  'amp': '&',
  'quot': '"',
  'apos': "'",
  'lt': '<',
  'gt': '>',
  'nbsp': ' ',
};

/// Real OCR'd/scraped turath pages carry malformed HTML-entity remnants —
/// sometimes well-formed (`&amp;`), sometimes broken up by stray whitespace
/// left over from an earlier, unrelated extraction step (`&amp; quot ; 1
/// &amp; quot ]`). Left undecoded, fragments like a bare "quot" reach the
/// TTS phonemizer as a fake "word" and crash espeak-ng's dictionary lookup
/// (found via `.claude/skills/native-crash-diagnosis`). Two passes: decoding
/// `&amp;` can itself expose a previously-escaped entity underneath.
String _decodeHtmlEntities(String s) {
  if (!s.contains('&')) return s;
  for (var pass = 0; pass < 2 && s.contains('&'); pass++) {
    s = s.replaceAllMapped(_htmlEntityPattern, (m) {
      final name = m.group(1);
      if (name != null) return _namedHtmlEntities[name]!;
      final dec = m.group(2);
      if (dec != null) {
        final code = int.parse(dec);
        return code <= 0x10FFFF ? String.fromCharCode(code) : m.group(0)!;
      }
      final hex = m.group(3);
      if (hex != null) {
        final code = int.parse(hex, radix: 16);
        return code <= 0x10FFFF ? String.fromCharCode(code) : m.group(0)!;
      }
      return m.group(0)!;
    });
  }
  return s;
}

/// Dependency-free 64-bit FNV-1a, hex. Enough to detect "the page text
/// changed" — not a security hash.
String pageChecksum(String normalized) {
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  const mask = 0xFFFFFFFFFFFFFFFF;
  for (final unit in normalized.codeUnits) {
    hash = (hash ^ unit) & mask;
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

enum AnchorStatus { exact, shifted, fuzzy, orphan }

class ResolvedAnchor {
  final AnchorStatus status;

  /// null only when [status] is [AnchorStatus.orphan].
  final int? start;
  final int? end;
  const ResolvedAnchor(this.status, this.start, this.end);

  bool get drawable => start != null && end != null && end! > start!;
}

/// Everything the resolver needs about one stored annotation. Mirrors the
/// `turath_annotations` columns but stays DB-agnostic.
class StoredAnchor {
  final String? selectedText;
  final int? charStart;
  final int? charEnd;
  final int normVersion;
  final String? textChecksum;
  final int? textLength;
  final String? prefixContext;
  final String? suffixContext;
  final String? headAnchor;
  final String? tailAnchor;
  final int occurrenceIndex;

  const StoredAnchor({
    required this.selectedText,
    required this.charStart,
    required this.charEnd,
    required this.normVersion,
    required this.textChecksum,
    required this.textLength,
    required this.prefixContext,
    required this.suffixContext,
    required this.headAnchor,
    required this.tailAnchor,
    this.occurrenceIndex = 0,
  });
}

/// Capture-time locator fields for a fresh selection over [normalizedPageText].
class AnchorCapture {
  final int normVersion;
  final String textChecksum;
  final int textLength;
  final String prefixContext;
  final String suffixContext;
  final String headAnchor;
  final String tailAnchor;
  final int occurrenceIndex;

  const AnchorCapture({
    required this.normVersion,
    required this.textChecksum,
    required this.textLength,
    required this.prefixContext,
    required this.suffixContext,
    required this.headAnchor,
    required this.tailAnchor,
    required this.occurrenceIndex,
  });
}

/// Build the locator fields for a new highlight of `[start, end)` in
/// [normalizedPageText]. `end` is exclusive.
AnchorCapture captureAnchor(String normalizedPageText, int start, int end) {
  assert(start >= 0 && end <= normalizedPageText.length && start < end);
  final selected = normalizedPageText.substring(start, end);
  final prefix = normalizedPageText.substring((start - _contextLen).clamp(0, start), start);
  final suffix = normalizedPageText.substring(end, (end + _contextLen).clamp(end, normalizedPageText.length));
  final head = selected.length <= _headTailLen ? selected : selected.substring(0, _headTailLen);
  final tail = selected.length <= _headTailLen ? selected : selected.substring(selected.length - _headTailLen);

  // Which occurrence of `selected` this is, so a later resolve can pick the
  // right one when the text repeats.
  var occ = 0;
  var idx = normalizedPageText.indexOf(selected);
  while (idx != -1 && idx < start) {
    occ++;
    idx = normalizedPageText.indexOf(selected, idx + 1);
  }

  return AnchorCapture(
    normVersion: kNormVersion,
    textChecksum: pageChecksum(normalizedPageText),
    textLength: normalizedPageText.length,
    prefixContext: prefix,
    suffixContext: suffix,
    headAnchor: head,
    tailAnchor: tail,
    occurrenceIndex: occ,
  );
}

/// Resolve a stored anchor against the current normalised page text.
ResolvedAnchor resolveAnchor(String normalizedPageText, StoredAnchor a) {
  final n = normalizedPageText.length;

  // 1) exact fast path
  if (a.normVersion == kNormVersion &&
      a.textChecksum != null &&
      a.textChecksum == pageChecksum(normalizedPageText) &&
      a.charStart != null &&
      a.charEnd != null &&
      a.charStart! >= 0 &&
      a.charEnd! <= n &&
      a.charStart! < a.charEnd!) {
    if (a.selectedText == null || normalizedPageText.substring(a.charStart!, a.charEnd!) == a.selectedText) {
      return ResolvedAnchor(AnchorStatus.exact, a.charStart, a.charEnd);
    }
  }

  final needle = a.selectedText;
  if (needle == null || needle.isEmpty) {
    return const ResolvedAnchor(AnchorStatus.orphan, null, null);
  }

  // 2) exact substring of the full selection
  final hits = _allIndexes(normalizedPageText, needle);
  if (hits.length == 1) {
    return ResolvedAnchor(AnchorStatus.shifted, hits.first, hits.first + needle.length);
  }
  if (hits.length > 1) {
    final best = _disambiguate(normalizedPageText, hits, needle.length, a);
    return ResolvedAnchor(AnchorStatus.shifted, best, best + needle.length);
  }

  // 3) ends intact, interior changed — reconstruct from a short head + tail
  //    of the selection itself.
  final ht = _headTailSpan(normalizedPageText, needle);
  if (ht != null) return ResolvedAnchor(AnchorStatus.fuzzy, ht.$1, ht.$2);

  // 4) approximate match of the WHOLE selection against the page — returns
  //    a span covering the full (approximate) selection, never a fragment.
  final fz = _fuzzyMatch(normalizedPageText, needle);
  if (fz != null) return ResolvedAnchor(AnchorStatus.fuzzy, fz.$1, fz.$2);

  // 5) keep the annotation, don't draw it (re-anchor manually later)
  return const ResolvedAnchor(AnchorStatus.orphan, null, null);
}

List<int> _allIndexes(String haystack, String needle) {
  final out = <int>[];
  var i = haystack.indexOf(needle);
  while (i != -1) {
    out.add(i);
    i = haystack.indexOf(needle, i + 1);
  }
  return out;
}

int _disambiguate(String text, List<int> hits, int needleLen, StoredAnchor a) {
  // Prefer the hit whose surrounding text best matches the stored context;
  // fall back to occurrence_index, then the first hit.
  final wantPrefix = a.prefixContext ?? '';
  final wantSuffix = a.suffixContext ?? '';
  var bestHit = hits.first;
  var bestScore = -1.0;
  for (final h in hits) {
    final gotPrefix = text.substring((h - wantPrefix.length).clamp(0, h), h);
    final gotSuffix = text.substring(h + needleLen, (h + needleLen + wantSuffix.length).clamp(h + needleLen, text.length));
    final score = _suffixOverlap(wantPrefix, gotPrefix) + _prefixOverlap(wantSuffix, gotSuffix);
    if (score > bestScore) {
      bestScore = score;
      bestHit = h;
    }
  }
  if (bestScore <= 0 && a.occurrenceIndex >= 0 && a.occurrenceIndex < hits.length) {
    return hits[a.occurrenceIndex];
  }
  return bestHit;
}

/// How many trailing chars of [want] match the trailing chars of [got].
double _suffixOverlap(String want, String got) {
  var i = 0;
  final maxI = want.length < got.length ? want.length : got.length;
  while (i < maxI && want[want.length - 1 - i] == got[got.length - 1 - i]) {
    i++;
  }
  return want.isEmpty ? 0 : i / want.length;
}

/// How many leading chars of [want] match the leading chars of [got].
double _prefixOverlap(String want, String got) {
  var i = 0;
  final maxI = want.length < got.length ? want.length : got.length;
  while (i < maxI && want[i] == got[i]) {
    i++;
  }
  return want.isEmpty ? 0 : i / want.length;
}

/// Ends of the selection still present verbatim, interior changed: locate a
/// short literal head and a short literal tail of `needle` and span between
/// them (covering the whole, now-slightly-different, middle).
(int, int)? _headTailSpan(String text, String needle) {
  if (needle.length < 32) return null; // too short to have distinct ends
  final headLen = needle.length < 48 ? 16 : 24;
  final head = needle.substring(0, headLen);
  final tail = needle.substring(needle.length - headLen);
  final hs = text.indexOf(head);
  if (hs == -1) return null;
  final ts = text.indexOf(tail, hs + headLen);
  if (ts == -1) return null;
  final end = ts + tail.length;
  final span = end - hs;
  // Reject a span wildly longer than the original (the ends matched by
  // coincidence far apart, not a real interior edit).
  if (span > needle.length * 2 + 32) return null;
  return (hs, end);
}

/// Approximate match of the ENTIRE selection against the page. Returns a
/// span that covers the whole approximate selection — never a fragment.
/// Candidate starts are seeded from literal occurrences of a short prefix of
/// the selection; each candidate's end is flexed to find the best fit; the
/// winner must clear [_fuzzyThreshold].
(int, int)? _fuzzyMatch(String text, String needle) {
  if (needle.length < 6) return null;

  final candidates = <int>{};
  for (final probeLen in [needle.length < 16 ? needle.length : 16, 10, 6]) {
    if (probeLen > needle.length) continue;
    final probe = needle.substring(0, probeLen);
    var p = text.indexOf(probe);
    while (p != -1 && candidates.length < 60) {
      candidates.add(p);
      p = text.indexOf(probe, p + 1);
    }
    if (candidates.isNotEmpty) break;
  }
  if (candidates.isEmpty) return null;

  final cap = (needle.length * 0.35).ceil() + 8;
  var bestStart = -1;
  var bestEnd = -1;
  var bestScore = 0.0;
  for (final start in candidates) {
    for (final delta in const [0, 2, -2, 4, -4, 8, -8, 12, -12]) {
      final end = (start + needle.length + delta).clamp(start + 1, text.length);
      final cand = text.substring(start, end);
      final d = _boundedLevenshtein(needle, cand, cap);
      if (d > cap) continue;
      final longer = needle.length > cand.length ? needle.length : cand.length;
      final score = 1 - d / longer;
      if (score > bestScore) {
        bestScore = score;
        bestStart = start;
        bestEnd = end;
      }
    }
  }
  return bestScore >= _fuzzyThreshold && bestStart != -1 ? (bestStart, bestEnd) : null;
}

/// Levenshtein distance, bounded: returns `> maxDist` (specifically
/// `maxDist + 1`) as soon as every cell in a row exceeds [maxDist], so a
/// hopeless pair costs O(maxDist·len) not O(len²).
int _boundedLevenshtein(String a, String b, int maxDist) {
  if ((a.length - b.length).abs() > maxDist) return maxDist + 1;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  var curr = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    curr[0] = i;
    var rowMin = curr[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final del = prev[j] + 1;
      final ins = curr[j - 1] + 1;
      final sub = prev[j - 1] + cost;
      curr[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
      if (curr[j] < rowMin) rowMin = curr[j];
    }
    if (rowMin > maxDist) return maxDist + 1;
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[b.length];
}
