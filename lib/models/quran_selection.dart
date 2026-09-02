import 'mushaf_layout.dart';

/// The one thing the user has selected on the mushaf — the central handle
/// every knowledge/lesson surface reads instead of re-deriving identity.
///
/// Plain, immutable, framework-free (only [MushafBox]). Produced by the
/// single page-level hit-test in [MushafPageView] from real `mushaf_*`
/// geometry — never from proximity, never from splitting text visually.
///
/// Layer separation (خطة «قارئ مصحف موحّد» §فصل الطبقات):
///   Visual (SVG) → Geometry (`mushaf_*`) → Interaction (`MushafPageLayout`)
///   → **Selection (`QuranSelection`)** → Knowledge (`KnowledgeGateway`)
///   → Presentation (Word / Ayah surfaces).
enum QuranSelectionType { word, ayah }

class QuranSelection {
  final int page; // 1..604
  final int surah;
  final int ayah;

  /// 1-based within the ayah. Non-null iff [type] == word.
  final int? wordIndex;

  final QuranSelectionType type;

  /// The selected word's box in source viewBox units (382.68 × 547.09) —
  /// non-null for word selections, drives the Selection Layer highlight and
  /// the "surface emerges from the word" motion.
  final MushafBox? wordBox;

  /// The word's Uthmani form, for the surface header. Word selections only.
  final String? textUthmani;

  const QuranSelection({
    required this.page,
    required this.surah,
    required this.ayah,
    required this.type,
    this.wordIndex,
    this.wordBox,
    this.textUthmani,
  });

  factory QuranSelection.word(MushafWord w) => QuranSelection(
        page: w.page,
        surah: w.surah,
        ayah: w.ayah,
        type: QuranSelectionType.word,
        wordIndex: w.wordIndex,
        wordBox: w.box,
        textUthmani: w.textUthmani,
      );

  factory QuranSelection.ayah(MushafAyaMark m) => QuranSelection(
        page: m.page,
        surah: m.surah,
        ayah: m.ayah,
        type: QuranSelectionType.ayah,
      );

  bool get isWord => type == QuranSelectionType.word;
  bool get isAyah => type == QuranSelectionType.ayah;

  ({int surah, int ayah}) get ayahKey => (surah: surah, ayah: ayah);

  /// Same `(surah, ayah, wordIndex, type)` — identity carried across
  /// surfaces so "طبّق" returns to the exact spot.
  bool sameAs(QuranSelection? o) =>
      o != null &&
      o.surah == surah &&
      o.ayah == ayah &&
      o.wordIndex == wordIndex &&
      o.type == type;

  @override
  String toString() => type == QuranSelectionType.word
      ? 'QuranSelection.word($surah:$ayah #$wordIndex p$page)'
      : 'QuranSelection.ayah($surah:$ayah p$page)';
}
