/// Phase 79 `79-mushaf` — the **Semantic Layer** of the Madani Mushaf.
///
/// Plain, immutable, framework-free data: every one of the 604 pages, every
/// word with its full `(surah, ayah, wordIndex)` identity plus the Uthmani
/// (`hafs`) and simplified (`imlaey`) forms, the line it sits on, and a
/// geometric bounding box in the source `viewBox` (382.68 × 547.09).
///
/// This file deliberately imports nothing from Flutter / `dart:ui`. The box
/// is just four doubles; the **Rendering Layer** ([MushafPageView]) is what
/// turns them into `Rect`s on a canvas. The database schema
/// (`mushaf_pages` / `mushaf_words` / …) stores the same fields column by
/// column and is likewise independent of how — or whether — a page is drawn.
///
/// Source: MushafDatabase Ligature-Based SVG V1.01 (license "Sadaqa-e-Jaria",
/// fully open incl. commercial), extracted at build time by
/// `tool/extract_mushaf_svg.py` into `assets/mushaf/mushaf_layout.json.gz`.
library;

/// Canonical source `viewBox` — identical for all 604 pages. Layout
/// coordinates ([MushafBox]) are expressed in this space; the renderer
/// scales it to the widget with `xMidYMid meet` (letterboxed, never
/// distorted).
const double kMushafViewBoxWidth = 382.68;
const double kMushafViewBoxHeight = 547.09;

/// The bump applied to `norm`/schema-style versioning of the bundled layout
/// asset. Bump when `tool/extract_mushaf_svg.py` changes in a way that
/// alters the emitted JSON so a stale seeded copy is rebuilt.
///
/// v2 (Phase 80 / M1, 2026-09-03): the page `rect` (from the source SVG's
/// `md-page-inner data-rect`) is given as `x0,y0,x1,y1` **corner** coords —
/// verified against all 604 bundled `SVG V1.01` pages. It used to be read as
/// `x,y,w,h`, which stored `x_max/y_max` into `mushaf_pages.rect_w/rect_h`
/// for the ~349 pages where that overflows the viewBox. Now converted
/// correctly in [MushafBox.fromCorners]; the stored `rect_*` columns hold
/// true `x,y,w,h`. Pure data fix — nothing renders from `rect` yet.
///
/// Phase G-t2 (2026-09-05): sub-word glyph geometry lives in a **separate**
/// table `mushaf_glyphs` (per ligature + diacritic box + the `[cs, ce)` span
/// of the word's Uthmani text it covers), from
/// `assets/mushaf/mushaf_glyphs.json.gz`, used only by the opt-in tajwīd
/// overlay ([MushafGlyphBox]). It is seeded **independently** by
/// `MushafLayoutSync` when that table is empty — the layout tables
/// themselves did not change, so this version is deliberately NOT bumped
/// (a bump would re-seed ~91k word rows for every existing user for
/// nothing). A missing / oversized glyph asset is logged and skipped.
const int kMushafLayoutVersion = 2;

/// An axis-aligned box in source `viewBox` units. No `dart:ui` dependency.
class MushafBox {
  final double x;
  final double y;
  final double w;
  final double h;
  const MushafBox(this.x, this.y, this.w, this.h);

  double get right => x + w;
  double get bottom => y + h;
  double get centerX => x + w / 2;
  double get centerY => y + h / 2;

  bool contains(double px, double py) =>
      px >= x && px <= x + w && py >= y && py <= y + h;

  /// Smallest box covering both. Used to build an ayah's highlight rect from
  /// its words, line by line.
  MushafBox union(MushafBox o) {
    final nx = x < o.x ? x : o.x;
    final ny = y < o.y ? y : o.y;
    final nr = right > o.right ? right : o.right;
    final nb = bottom > o.bottom ? bottom : o.bottom;
    return MushafBox(nx, ny, nr - nx, nb - ny);
  }

  /// Box grown by [d] on every side (tap-target padding), clamped to ≥ 0 size.
  MushafBox inflate(double d) => MushafBox(x - d, y - d, w + 2 * d, h + 2 * d);

  /// Parse `[x, y, w, h]` — the form used by every word / aya-mark / marker
  /// `bbox` in the layout asset (`tool/extract_mushaf_svg.py` `bbox_of`).
  static MushafBox? fromList(Object? v) {
    if (v is List && v.length == 4) {
      return MushafBox(
        (v[0] as num).toDouble(),
        (v[1] as num).toDouble(),
        (v[2] as num).toDouble(),
        (v[3] as num).toDouble(),
      );
    }
    return null;
  }

  /// Parse `[x0, y0, x1, y1]` — the **corner** form the source SVG uses for
  /// `md-page-inner data-rect` (the page's 15-line content frame). Returns a
  /// normal `x,y,w,h` box, or null if the 4 numbers aren't a valid,
  /// positive-area rectangle. See [kMushafLayoutVersion] v2.
  static MushafBox? fromCorners(Object? v) {
    if (v is List && v.length == 4) {
      final x0 = (v[0] as num).toDouble();
      final y0 = (v[1] as num).toDouble();
      final x1 = (v[2] as num).toDouble();
      final y1 = (v[3] as num).toDouble();
      if (x1 > x0 && y1 > y0) return MushafBox(x0, y0, x1 - x0, y1 - y0);
    }
    return null;
  }

  @override
  String toString() => 'MushafBox($x, $y, $w, $h)';
}

/// A word's kind in the mushaf's own segmentation. Besides ordinary
/// [text] words the dataset indexes two ornament glyphs *inside* the ayah
/// word sequence, each with a real `word_index`:
/// [juzStar] = ۞ (rub' el-hizb), [sajdaMehrab] = ۩ (sajdat al-tilawah).
enum MushafWordType {
  text,
  juzStar,
  sajdaMehrab;

  static MushafWordType fromKey(String? k) => switch (k) {
        'juz-star' => MushafWordType.juzStar,
        'sajda-mehrab' => MushafWordType.sajdaMehrab,
        _ => MushafWordType.text,
      };

  String get key => switch (this) {
        MushafWordType.juzStar => 'juz-star',
        MushafWordType.sajdaMehrab => 'sajda-mehrab',
        MushafWordType.text => 'text',
      };

  bool get isOrnament => this != MushafWordType.text;
}

/// One addressable word on a page.
class MushafWord {
  final int page;
  final int line; // 1-based, 1..15
  final int wordOrder; // 1-based reading order within the page
  final int surah;
  final int ayah;
  final int wordIndex; // 1-based within the ayah (verbatim from the dataset)
  final MushafWordType type;
  final String textUthmani; // data-hafs
  final String textImlaey; // data-imlaey
  final MushafBox box;

  const MushafWord({
    required this.page,
    required this.line,
    required this.wordOrder,
    required this.surah,
    required this.ayah,
    required this.wordIndex,
    required this.type,
    required this.textUthmani,
    required this.textImlaey,
    required this.box,
  });

  /// `(surah, ayah)` key — the anchor the ayah notebook uses.
  ({int surah, int ayah}) get ayahKey => (surah: surah, ayah: ayah);

  factory MushafWord.fromJson(int page, Map<String, dynamic> j) => MushafWord(
        page: page,
        line: (j['ln'] as num?)?.toInt() ?? 0,
        wordOrder: (j['o'] as num).toInt(),
        surah: (j['s'] as num).toInt(),
        ayah: (j['a'] as num).toInt(),
        wordIndex: (j['w'] as num).toInt(),
        type: MushafWordType.fromKey(j['t'] as String?),
        textUthmani: j['hafs'] as String? ?? '',
        textImlaey: j['iml'] as String? ?? '',
        box: MushafBox.fromList(j['b']) ?? const MushafBox(0, 0, 0, 0),
      );

  Map<String, Object?> toRow() => {
        'page': page,
        'line': line,
        'word_order': wordOrder,
        'surah': surah,
        'ayah': ayah,
        'word_index': wordIndex,
        'word_type': type.key,
        'text_uthmani': textUthmani,
        'text_imlaey': textImlaey,
        'bbox_x': box.x,
        'bbox_y': box.y,
        'bbox_w': box.w,
        'bbox_h': box.h,
      };

  static MushafWord fromRow(Map<String, Object?> r) => MushafWord(
        page: (r['page'] as num).toInt(),
        line: (r['line'] as num).toInt(),
        wordOrder: (r['word_order'] as num).toInt(),
        surah: (r['surah'] as num).toInt(),
        ayah: (r['ayah'] as num).toInt(),
        wordIndex: (r['word_index'] as num).toInt(),
        type: MushafWordType.fromKey(r['word_type'] as String?),
        textUthmani: r['text_uthmani'] as String? ?? '',
        textImlaey: r['text_imlaey'] as String? ?? '',
        box: MushafBox(
          (r['bbox_x'] as num).toDouble(),
          (r['bbox_y'] as num).toDouble(),
          (r['bbox_w'] as num).toDouble(),
          (r['bbox_h'] as num).toDouble(),
        ),
      );
}

/// A verse-end marker (the ornamented ۝ with the number). One per ayah.
class MushafAyaMark {
  final int page;
  final int line;
  final int surah;
  final int ayah;
  final MushafBox? box;

  const MushafAyaMark({
    required this.page,
    required this.line,
    required this.surah,
    required this.ayah,
    this.box,
  });

  factory MushafAyaMark.fromJson(int page, Map<String, dynamic> j) =>
      MushafAyaMark(
        page: page,
        line: (j['ln'] as num?)?.toInt() ?? 0,
        surah: (j['s'] as num).toInt(),
        ayah: (j['a'] as num).toInt(),
        box: MushafBox.fromList(j['b']),
      );

  Map<String, Object?> toRow() => {
        'page': page,
        'line': line,
        'surah': surah,
        'ayah': ayah,
        'bbox_x': box?.x,
        'bbox_y': box?.y,
        'bbox_w': box?.w,
        'bbox_h': box?.h,
      };

  static MushafAyaMark fromRow(Map<String, Object?> r) => MushafAyaMark(
        page: (r['page'] as num).toInt(),
        line: (r['line'] as num).toInt(),
        surah: (r['surah'] as num).toInt(),
        ayah: (r['ayah'] as num).toInt(),
        box: r['bbox_x'] == null
            ? null
            : MushafBox(
                (r['bbox_x'] as num).toDouble(),
                (r['bbox_y'] as num).toDouble(),
                (r['bbox_w'] as num).toDouble(),
                (r['bbox_h'] as num).toDouble(),
              ),
      );
}

/// Kinds of non-word page furniture the layer keeps.
enum MushafMarkerKind {
  sajda,
  juzHizb,
  surahHeader,
  bismillah;

  static MushafMarkerKind fromKey(String k) => switch (k) {
        'sajda' => MushafMarkerKind.sajda,
        'juz-hizb' => MushafMarkerKind.juzHizb,
        'surah-header' => MushafMarkerKind.surahHeader,
        'bismillah' => MushafMarkerKind.bismillah,
        _ => MushafMarkerKind.surahHeader,
      };

  String get key => switch (this) {
        MushafMarkerKind.sajda => 'sajda',
        MushafMarkerKind.juzHizb => 'juz-hizb',
        MushafMarkerKind.surahHeader => 'surah-header',
        MushafMarkerKind.bismillah => 'bismillah',
      };
}

class MushafMarker {
  final int page;
  final MushafMarkerKind kind;
  final int? line;
  final int? surah;
  final MushafBox? box;

  const MushafMarker({
    required this.page,
    required this.kind,
    this.line,
    this.surah,
    this.box,
  });

  factory MushafMarker.fromJson(int page, Map<String, dynamic> j) => MushafMarker(
        page: page,
        kind: MushafMarkerKind.fromKey(j['k'] as String),
        line: (j['ln'] as num?)?.toInt(),
        surah: (j['s'] as num?)?.toInt(),
        box: MushafBox.fromList(j['b']),
      );

  Map<String, Object?> toRow() => {
        'page': page,
        'kind': kind.key,
        'line': line,
        'surah': surah,
        'bbox_x': box?.x,
        'bbox_y': box?.y,
        'bbox_w': box?.w,
        'bbox_h': box?.h,
      };

  static MushafMarker fromRow(Map<String, Object?> r) => MushafMarker(
        page: (r['page'] as num).toInt(),
        kind: MushafMarkerKind.fromKey(r['kind'] as String),
        line: (r['line'] as num?)?.toInt(),
        surah: (r['surah'] as num?)?.toInt(),
        box: r['bbox_x'] == null
            ? null
            : MushafBox(
                (r['bbox_x'] as num).toDouble(),
                (r['bbox_y'] as num).toDouble(),
                (r['bbox_w'] as num).toDouble(),
                (r['bbox_h'] as num).toDouble(),
              ),
      );
}

/// One line's kind, in reading order top→bottom.
class MushafLineInfo {
  final int line; // 1..15
  final String type; // text | surah-name | bismillah | empty
  const MushafLineInfo(this.line, this.type);

  bool get isText => type == 'text';
}

/// Everything needed to render and address a single page — the unit the
/// [MushafLayoutRepository] hands to the [MushafPageView].
class MushafPageLayout {
  final int page; // 1..604

  /// The page's 15-line content frame — the source SVG's `md-page-inner`
  /// `data-rect`, as a normal `x,y,w,h` box in viewBox units (converted from
  /// the source's `x0,y0,x1,y1` corner form — see [MushafBox.fromCorners]
  /// and [kMushafLayoutVersion] v2). Present for all 604 pages. Not yet
  /// consumed by the renderer (Phase 80 / M3 will centre it).
  final MushafBox? rect;
  final double viewBoxWidth;
  final double viewBoxHeight;
  final List<MushafLineInfo> lines;
  final List<MushafWord> words;
  final List<MushafAyaMark> ayaMarks;
  final List<MushafMarker> markers;

  const MushafPageLayout({
    required this.page,
    required this.rect,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.lines,
    required this.words,
    required this.ayaMarks,
    required this.markers,
  });

  int get surahFirst => words.isEmpty ? 0 : words.first.surah;
  int get surahLast => words.isEmpty ? 0 : words.last.surah;

  /// Distinct `(surah, ayah)` on the page, in reading order.
  List<({int surah, int ayah})> get ayat {
    final seen = <String>{};
    final out = <({int surah, int ayah})>[];
    for (final w in words) {
      final k = '${w.surah}:${w.ayah}';
      if (seen.add(k)) out.add((surah: w.surah, ayah: w.ayah));
    }
    return out;
  }

  /// The verse-end medallion whose box contains the point — the ONLY entry
  /// to an ayah-level selection (the ayah's body is its words). Pure
  /// geometry over [ayaMarks]; [pad] is box tolerance, not a nearest search.
  /// Marks without geometry are skipped.
  MushafAyaMark? ayaMarkAtPoint(double x, double y, {double pad = 2.0}) {
    MushafAyaMark? best;
    double bestDist = double.infinity;
    for (final m in ayaMarks) {
      final b = m.box;
      if (b == null) continue;
      if (b.inflate(pad).contains(x, y)) {
        final dx = x - b.centerX;
        final dy = y - b.centerY;
        final d = dx * dx + dy * dy;
        if (d < bestDist) {
          bestDist = d;
          best = m;
        }
      }
    }
    return best;
  }

  /// The word whose (optionally inflated) box contains the point, searching
  /// in reading order. [pad] widens every box to make tapping forgiving.
  MushafWord? wordAtPoint(double x, double y, {double pad = 1.5}) {
    MushafWord? best;
    double bestDist = double.infinity;
    for (final w in words) {
      if (w.box.inflate(pad).contains(x, y)) {
        final dx = x - w.box.centerX;
        final dy = y - w.box.centerY;
        final d = dx * dx + dy * dy;
        if (d < bestDist) {
          bestDist = d;
          best = w;
        }
      }
    }
    return best;
  }

  /// Per-line highlight boxes for one ayah (one rect per line it occupies),
  /// so a verse spanning several lines lights up fully, not as one big block.
  List<MushafBox> ayahBoxes(int surah, int ayah) {
    final byLine = <int, MushafBox>{};
    for (final w in words) {
      if (w.surah != surah || w.ayah != ayah) continue;
      byLine.update(w.line, (b) => b.union(w.box), ifAbsent: () => w.box);
    }
    final lines = byLine.keys.toList()..sort();
    return [for (final l in lines) byLine[l]!];
  }

  factory MushafPageLayout.fromJson(Map<String, dynamic> j) {
    final page = (j['page'] as num).toInt();
    return MushafPageLayout(
      page: page,
      // `j['rect']` is md-page-inner data-rect as x0,y0,x1,y1 corners (v2).
      rect: MushafBox.fromCorners(j['rect']),
      viewBoxWidth: kMushafViewBoxWidth,
      viewBoxHeight: kMushafViewBoxHeight,
      lines: [
        for (final l in (j['lines'] as List? ?? const []))
          MushafLineInfo((l['n'] as num).toInt(), l['type'] as String? ?? 'text'),
      ],
      words: [
        for (final w in (j['words'] as List? ?? const []))
          MushafWord.fromJson(page, w as Map<String, dynamic>),
      ],
      ayaMarks: [
        for (final m in (j['marks'] as List? ?? const []))
          MushafAyaMark.fromJson(page, m as Map<String, dynamic>),
      ],
      markers: [
        for (final m in (j['markers'] as List? ?? const []))
          MushafMarker.fromJson(page, m as Map<String, dynamic>),
      ],
    );
  }
}

/// Phase G-t2 · one sub-word glyph: a **ligature** (`kind == 0`, the base
/// `<path data-text>` — may cover several letters) or a **diacritic**
/// (`kind == 1`). `charStart..charEnd` is the half-open span of the owning
/// word's own Uthmani (`text_uthmani`) string this glyph renders, so a
/// tajwīd rule's `[cs, ce)` range maps to a run of boxes. Geometry is in
/// source viewBox units (`0 0 382.68 547.09`), same space as
/// [MushafWord.box]. Parsed from `mushaf_glyphs.data` (DB v57) — read only
/// by the opt-in tajwīd overlay.
class MushafGlyphBox {
  final int kind; // 0 = base ligature · 1 = diacritic
  final String text; // data-text ("بسم") or data-diacritic ("kasra")
  final int charStart;
  final int charEnd;

  /// The exact `<path id>` in the page SVG this glyph is drawn by
  /// (`md-path-{word}-{lig}[-{dia}]`) — the tajwīd renderer injects `fill`
  /// on this id. (Phase G-t v2.)
  final String pathId;

  /// How many **base letters** this glyph's path represents (1 for a
  /// diacritic or a single-letter ligature; 2–3 for a multi-letter
  /// ligature). When a rule span is a strict subset of a `baseLen > 1`
  /// path, the renderer colours the whole ligature — the documented v1
  /// fallback, counted in `TAJWEED_GLYPH_COVERAGE.md`.
  final int baseLen;

  final MushafBox box;

  const MushafGlyphBox({
    required this.kind,
    required this.text,
    required this.charStart,
    required this.charEnd,
    required this.pathId,
    required this.baseLen,
    required this.box,
  });

  bool get isBase => kind == 0;

  /// Overlaps the half-open word-char range `[cs, ce)`.
  bool coversRange(int cs, int ce) => charStart < ce && charEnd > cs;

  /// The span `[cs, ce)` covers **only part** of this multi-letter ligature
  /// (the v1 ligature fallback fires — colour the whole path).
  bool isPartialCover(int cs, int ce) =>
      isBase && baseLen > 1 && (cs > charStart || ce < charEnd);

  static MushafGlyphBox fromJson(Map<String, dynamic> j) => MushafGlyphBox(
        kind: (j['k'] as num).toInt(),
        text: j['t'] as String? ?? '',
        charStart: (j['cs'] as num).toInt(),
        charEnd: (j['ce'] as num).toInt(),
        pathId: j['p'] as String? ?? '',
        baseLen: (j['nb'] as num?)?.toInt() ?? 1,
        box: MushafBox.fromList(j['b']) ?? const MushafBox(0, 0, 0, 0),
      );
}

/// The glyphs of one word on a page (`wordOrder` == [MushafWord.order]).
class MushafWordGlyphs {
  final int wordOrder;
  final int hafsLen;
  final List<MushafGlyphBox> glyphs;
  const MushafWordGlyphs(this.wordOrder, this.hafsLen, this.glyphs);

  static MushafWordGlyphs fromJson(Map<String, dynamic> j) => MushafWordGlyphs(
        (j['o'] as num).toInt(),
        (j['n'] as num?)?.toInt() ?? 0,
        [
          for (final g in (j['g'] as List? ?? const []))
            MushafGlyphBox.fromJson(g as Map<String, dynamic>),
        ],
      );

  /// Boxes whose char span overlaps `[cs, ce)` — the run to wash for a
  /// tajwīd rule on this word. Bases first, then their diacritics.
  List<MushafGlyphBox> runForCharRange(int cs, int ce) =>
      [for (final g in glyphs) if (g.coversRange(cs, ce)) g];
}
