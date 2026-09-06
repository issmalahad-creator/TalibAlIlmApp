import '../../models/mushaf_layout.dart';
import '../../models/tajweed_span.dart';
import '../../theme/tajweed_palette.dart';

/// Phase G-t v2 · **glyph-level** tajwīd colouring — colour on the glyph ink,
/// no overlay, no rectangle behind text.
///
/// MushafDatabase's "Ligature-Based" SVG draws 2–10 letters (often a whole
/// word) as **one `<path>`**, and there is no per-letter path. Two
/// mechanisms, both verified in `flutter_svg 2.0.10`:
///
///  1. **Direct `fill`** on the exact `<path id>` — every covered
///     **diacritic** glyph (wasla, shadda, maddah, superscript-alef,
///     tanwīn, sukūn…) and every **single-letter** base ligature. Precise.
///     ≈ 80 % of spans.
///  2. **Clip-path band** — **only for the المدّ category** (Ismail wants the
///     elongation, especially at verse ends, coloured even when it lands on
///     a bare letter inside a word-ligature): a duplicate of that `<path>`
///     clipped to the `<rect>` x-slice of the madd letter (proportional
///     split of the ligature box by base-letter index; the final letter of
///     a word sits at the box edge, so a verse-end madd band is tight).
///     A region of the word, ±1 letter, never the whole word, never a
///     rectangle.
///
/// Non-madd rules that land only inside a whole-word ligature stay black on
/// the page (shown in the knowledge surface + on tap) — those bands read as
/// baseline artefacts and the rules are less visually expected. Every skip
/// is counted (`docs/quran/reports/TAJWEED_GLYPH_COVERAGE.md`).
///
/// A base `fill` on `<g id="md-page">` carries the ink (replaces the night
/// `ColorFilter`). Pure + isolate-safe. The `[cs, ce)` span data is never
/// rewritten.

class TajweedBand {
  final String basePathId; // the multi-letter ligature <path> to duplicate
  final String hex;
  final double x, y, w, h; // clip rect, source viewBox units
  const TajweedBand(this.basePathId, this.hex, this.x, this.y, this.w, this.h);
}

class TajweedGlyphPaint {
  /// `md-path` id → `#RRGGBB` (diacritic + single-letter base — direct fill).
  final Map<String, String> directFills;

  /// Clip-path bands — madd category only.
  final List<TajweedBand> bands;

  final int spansTotal;
  final int spansDirect; // placed a precise fill
  final int spansBand; // placed a madd band
  final int spansSkipped; // multi-letter ligature, no anchor, non-madd — page-black
  final Map<String, ({int direct, int band, int skip})> byRule;
  final List<String> skippedExamples;

  const TajweedGlyphPaint({
    required this.directFills,
    required this.bands,
    required this.spansTotal,
    required this.spansDirect,
    required this.spansBand,
    required this.spansSkipped,
    required this.byRule,
    required this.skippedExamples,
  });

  static const empty = TajweedGlyphPaint(
    directFills: {},
    bands: [],
    spansTotal: 0,
    spansDirect: 0,
    spansBand: 0,
    spansSkipped: 0,
    byRule: {},
    skippedExamples: [],
  );

  bool get isEmpty => directFills.isEmpty && bands.isEmpty;
}

// Arabic combining marks — a "letter" is anything NOT in this set.
bool _isMark(int cp) =>
    (cp >= 0x0610 && cp <= 0x061A) ||
    (cp >= 0x064B && cp <= 0x065F) ||
    cp == 0x0670 ||
    (cp >= 0x06D6 && cp <= 0x06DC) ||
    (cp >= 0x06DF && cp <= 0x06E4) ||
    cp == 0x06E7 ||
    cp == 0x06E8 ||
    (cp >= 0x06EA && cp <= 0x06ED) ||
    (cp >= 0x08D3 && cp <= 0x08FF) ||
    cp == 0x0640;

int _baseCount(String s, int from, int to) {
  var n = 0;
  for (var i = from; i < to && i < s.length; i++) {
    if (!_isMark(s.codeUnitAt(i))) n++;
  }
  return n;
}

TajweedGlyphPaint resolveTajweedPaint({
  required List<MushafWord> pageWords,
  required Map<String, AyahTajweed> tajweedByAyah,
  required Map<int, MushafWordGlyphs> glyphsByWordOrder,
  required bool night,
  int maxExamples = 8,
}) {
  final direct = <String, String>{};
  final bands = <TajweedBand>[];
  final seenBand = <String>{};
  var total = 0, nDirect = 0, nBand = 0, nSkip = 0;
  final byRule = <String, ({int direct, int band, int skip})>{};
  final examples = <String>[];

  void bump(String r, {int d = 0, int b = 0, int s = 0}) {
    final c = byRule[r] ?? (direct: 0, band: 0, skip: 0);
    byRule[r] = (direct: c.direct + d, band: c.band + b, skip: c.skip + s);
  }

  for (final w in pageWords) {
    if (w.type != MushafWordType.text) continue;
    final at = tajweedByAyah['${w.surah}:${w.ayah}'];
    if (at == null || at.isEmpty) continue;
    final spans = at.forWord(w.wordIndex);
    if (spans.isEmpty) continue;
    final wg = glyphsByWordOrder[w.wordOrder];
    if (wg == null || wg.glyphs.isEmpty) {
      for (final sp in spans) {
        total++;
        nSkip++;
        bump(sp.ruleId, s: 1);
      }
      continue;
    }
    final hafs = w.textUthmani;

    for (final sp in spans) {
      total++;
      final hex = TajweedPalette.hexForRule(sp.ruleId, night: night);
      final isMadd = TajweedPalette.categoryForRule(sp.ruleId).key == 'madd';
      final covered =
          wg.glyphs.where((g) => g.coversRange(sp.cs, sp.ce)).toList();

      // lām shamsiyyah: also colour the shadda on the following letter.
      if (sp.ruleId == 'lam_shamsiyyah') {
        for (final g in wg.glyphs) {
          if (g.kind == 1 &&
              g.text.contains('shad') &&
              g.charStart >= sp.ce &&
              g.charStart <= sp.ce + 3 &&
              !covered.contains(g)) {
            covered.add(g);
          }
        }
      }

      if (covered.isEmpty) {
        nSkip++;
        bump(sp.ruleId, s: 1);
        continue;
      }

      var placed = false;
      final multi = <MushafGlyphBox>[];
      for (final g in covered) {
        if (g.pathId.isEmpty) continue;
        if (g.kind == 1 || g.baseLen == 1) {
          direct[g.pathId] = hex;
          placed = true;
        } else {
          multi.add(g);
        }
      }

      var banded = false;
      if (!placed && isMadd && multi.isNotEmpty) {
        for (final mb in multi) {
          final b = _band(mb, hafs, sp.cs, sp.ce);
          if (b == null) continue;
          final key = '${mb.pathId}|${b.$1.toStringAsFixed(1)}|$hex';
          if (seenBand.add(key)) {
            bands.add(TajweedBand(mb.pathId, hex, b.$1, b.$2, b.$3, b.$4));
          }
          banded = true;
        }
      }

      if (placed) {
        nDirect++;
        bump(sp.ruleId, d: 1);
      } else if (banded) {
        nBand++;
        bump(sp.ruleId, b: 1);
      } else {
        nSkip++;
        bump(sp.ruleId, s: 1);
        if (examples.length < maxExamples) {
          examples.add('${w.surah}:${w.ayah} w${w.wordIndex} — '
              '«${w.textUthmani}» (${sp.ruleId})');
        }
      }
    }
  }

  return TajweedGlyphPaint(
    directFills: direct,
    bands: bands,
    spansTotal: total,
    spansDirect: nDirect,
    spansBand: nBand,
    spansSkipped: nSkip,
    byRule: byRule,
    skippedExamples: examples,
  );
}

/// Clip `<rect>` (x, y, w, h) for the base letters `[cs, ce)` covers inside
/// the multi-letter ligature [mb]. RTL: letter 0 (first) is at the RIGHT
/// edge, so a word-final madd letter maps to the LEFT edge. Null if it
/// can't be placed.
(double, double, double, double)? _band(
    MushafGlyphBox mb, String hafs, int cs, int ce) {
  final l = mb.baseLen;
  if (l < 2) return null;
  var bi0 = _baseCount(hafs, mb.charStart, cs.clamp(mb.charStart, mb.charEnd));
  var bi1 = _baseCount(hafs, mb.charStart, ce.clamp(mb.charStart, mb.charEnd));
  bi0 = bi0.clamp(0, l - 1);
  bi1 = bi1.clamp(bi0 + 1, l);
  final box = mb.box;
  const pad = 0.2; // a hair of bleed so a 1-letter band isn't razor-thin
  final right = box.x + box.w * (l - bi0) / l + pad;
  final left = box.x + box.w * (l - bi1) / l - pad;
  if (right - left <= 0) return null;
  return (left, box.y, right - left, box.h);
}

final RegExp _pathIdRe = RegExp(r'<path id="(md-path-[0-9A-Za-z-]+)"');

/// Inject the tajwīd colouring into the page SVG string. Pure — isolate-safe.
///
/// - one `fill="$baseInkHex"` on `<g id="md-page"` (default ink, replaces the
///   night `ColorFilter`);
/// - `fill="#…"` on each `md-path` id in [directFills];
/// - for each [bands] entry: a `<clipPath><rect/></clipPath>` in `<defs>` +
///   a clipped duplicate of that `<path>` right after the original.
///
/// Never touches geometry / `viewBox`; never fills a non-`md-path` element.
String paintTajweedIntoSvg(
  String svg, {
  required Map<String, String> directFills,
  required List<TajweedBand> bands,
  required String baseInkHex,
}) {
  var out =
      svg.replaceFirst('<g id="md-page"', '<g id="md-page" fill="$baseInkHex"');

  if (directFills.isNotEmpty) {
    out = out.replaceAllMapped(_pathIdRe, (m) {
      final id = m.group(1)!;
      final hex = directFills[id];
      return hex == null ? m.group(0)! : '<path fill="$hex" id="$id"';
    });
  }

  if (bands.isEmpty) return out;

  final byPath = <String, List<TajweedBand>>{};
  for (final b in bands) {
    (byPath[b.basePathId] ??= []).add(b);
  }
  final defs = StringBuffer();
  final extra = <String, StringBuffer>{};
  var n = 0;
  byPath.forEach((pathId, list) {
    final esc = RegExp.escape(pathId);
    final m = RegExp('<path id="$esc"[^>]*?\\bd="([^"]+)"[^>]*?/>').firstMatch(out);
    if (m == null) return;
    final d = m.group(1)!;
    final buf = extra[pathId] = StringBuffer();
    for (final b in list) {
      final cid = 'tjc${n++}';
      defs.write('<clipPath id="$cid"><rect x="${_f(b.x)}" y="${_f(b.y)}" '
          'width="${_f(b.w)}" height="${_f(b.h)}"/></clipPath>');
      buf.write('<path d="$d" fill="${b.hex}" clip-path="url(#$cid)"/>');
    }
  });

  if (defs.isEmpty) return out;
  out = out.replaceFirst('<g id="md-page', '<defs>$defs</defs><g id="md-page');
  extra.forEach((pathId, buf) {
    final esc = RegExp.escape(pathId);
    out = out.replaceFirstMapped(
      RegExp('(<path id="$esc"[^>]*?/>)'),
      (m) => '${m.group(1)}$buf',
    );
  });
  return out;
}

String _f(double v) => v.toStringAsFixed(2);
