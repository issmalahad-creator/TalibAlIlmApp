import '../../models/mushaf_layout.dart';
import '../../models/tajweed_span.dart';
import '../../theme/tajweed_palette.dart';

/// Phase G-t v2 · **glyph-level** tajwīd colouring — no overlay, no wash, no
/// rectangle behind text. The colour goes on the exact `<path>` of a glyph.
///
/// MushafDatabase's "Ligature-Based" SVG draws 2–10 letters (often a whole
/// word) as **one `<path>`**, and there is no per-letter path. So v1 colours
/// only what it can colour **precisely**:
///
///  - every covered **diacritic** glyph (wasla, maddah, shadda,
///    superscript-alef, tanwīn, sukūn… — these ARE per-position paths), and
///  - every covered **single-letter** base ligature.
///
/// A rule that lands only inside a multi-letter ligature (no diacritic
/// anchor) is **not coloured on the page** — it stays black, and is shown
/// in the knowledge surface + on tap. Every such span is counted
/// (`spansSkipped`) so the gap is visible, never silent
/// (`docs/quran/reports/TAJWEED_GLYPH_COVERAGE.md`). True per-letter
/// geometry is v3 (a different art source / an in-app shaping renderer).
///
/// A base `fill` on `<g id="md-page">` carries the ink (replaces the night
/// `ColorFilter`). Pure + isolate-safe. The `[cs, ce)` span data is never
/// rewritten.

class TajweedGlyphPaint {
  /// `md-path` id → `#RRGGBB` (diacritic + single-letter base — direct fill).
  final Map<String, String> directFills;

  final int spansTotal;
  final int spansDirect; // placed a precise fill
  final int spansSkipped; // multi-letter ligature, no precise anchor — page-black
  final Map<String, ({int direct, int skip})> byRule;
  final List<String> skippedExamples;

  const TajweedGlyphPaint({
    required this.directFills,
    required this.spansTotal,
    required this.spansDirect,
    required this.spansSkipped,
    required this.byRule,
    required this.skippedExamples,
  });

  static const empty = TajweedGlyphPaint(
    directFills: {},
    spansTotal: 0,
    spansDirect: 0,
    spansSkipped: 0,
    byRule: {},
    skippedExamples: [],
  );

  bool get isEmpty => directFills.isEmpty;
}

TajweedGlyphPaint resolveTajweedPaint({
  required List<MushafWord> pageWords,
  required Map<String, AyahTajweed> tajweedByAyah,
  required Map<int, MushafWordGlyphs> glyphsByWordOrder,
  required bool night,
  int maxExamples = 8,
}) {
  final direct = <String, String>{};
  var total = 0, nDirect = 0, nSkip = 0;
  final byRule = <String, ({int direct, int skip})>{};
  final examples = <String>[];

  void bump(String r, {int d = 0, int s = 0}) {
    final c = byRule[r] ?? (direct: 0, skip: 0);
    byRule[r] = (direct: c.direct + d, skip: c.skip + s);
  }

  for (final w in pageWords) {
    if (w.type != MushafWordType.text) continue;
    final at = tajweedByAyah['${w.surah}:${w.ayah}'];
    if (at == null || at.isEmpty) continue;
    final spans = at.forWord(w.wordIndex);
    if (spans.isEmpty) continue;
    final wg = glyphsByWordOrder[w.wordOrder];

    for (final sp in spans) {
      total++;
      if (wg == null || wg.glyphs.isEmpty) {
        nSkip++;
        bump(sp.ruleId, s: 1);
        continue;
      }
      final hex = TajweedPalette.hexForRule(sp.ruleId, night: night);
      final covered =
          wg.glyphs.where((g) => g.coversRange(sp.cs, sp.ce)).toList();

      // lām shamsiyyah: also colour the shadda on the following letter — that
      // assimilation IS the rule. Render-time only; span data untouched.
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

      var placed = false;
      for (final g in covered) {
        if (g.pathId.isEmpty) continue;
        if (g.kind == 1 || g.baseLen == 1) {
          direct[g.pathId] = hex;
          placed = true;
        }
      }

      if (placed) {
        nDirect++;
        bump(sp.ruleId, d: 1);
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
    spansTotal: total,
    spansDirect: nDirect,
    spansSkipped: nSkip,
    byRule: byRule,
    skippedExamples: examples,
  );
}

final RegExp _pathIdRe = RegExp(r'<path id="(md-path-[0-9A-Za-z-]+)"');

/// Inject the tajwīd colouring into the page SVG string. Pure — safe in a
/// background isolate.
///
/// - one `fill="$baseInkHex"` on `<g id="md-page"` (the default ink for
///   every glyph + header + marker; replaces the night `ColorFilter`);
/// - `fill="#…"` on each `md-path` id in [directFills] (overrides the base).
///
/// Never touches geometry / `viewBox` / `d`; never adds a `fill` to a
/// non-`md-path` element. With no fills it changes exactly one attribute.
String paintTajweedIntoSvg(
  String svg, {
  required Map<String, String> directFills,
  required String baseInkHex,
}) {
  var out =
      svg.replaceFirst('<g id="md-page"', '<g id="md-page" fill="$baseInkHex"');
  if (directFills.isEmpty) return out;
  out = out.replaceAllMapped(_pathIdRe, (m) {
    final id = m.group(1)!;
    final hex = directFills[id];
    return hex == null ? m.group(0)! : '<path fill="$hex" id="$id"';
  });
  return out;
}
