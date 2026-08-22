import 'package:flutter/painting.dart';

import '../repositories/quran_reading_repository.dart';

/// One word on a Mushaf page, tagged with the ayah it belongs to so taps
/// and the ayah-end medallion can resolve back to (surah, ayah).
class MushafWord {
  final int surah;
  final int ayah;
  final String text;

  /// True for the last word of an ayah — the medallion renders right after it.
  final bool isAyahEnd;

  /// True only for the very first word of a surah's first ayah — forces a
  /// line break before it so the surah-name banner (inserted by the widget
  /// layer) always sits on its own line rather than mid-line.
  final bool startsNewSurah;

  const MushafWord({
    required this.surah,
    required this.ayah,
    required this.text,
    this.isAyahEnd = false,
    this.startsNewSurah = false,
  });
}

/// One printed line, in reading order (index 0 = first word read, i.e. the
/// rightmost word on an RTL page).
class MushafLine {
  final List<MushafWord> words;
  const MushafLine(this.words);
}

class MushafPageLayout {
  final List<MushafLine> lines;
  final double fontSize;
  const MushafPageLayout({required this.lines, required this.fontSize});
}

/// Splits a page's ayat into words tagged with ayah-end/new-surah markers —
/// the flat input the packer works from. Kept separate from packing so it's
/// independently testable and doesn't depend on any width/font decisions.
List<MushafWord> flattenAyatToWords(List<QuranAyahText> ayat) {
  final words = <MushafWord>[];
  for (final a in ayat) {
    final parts = a.text.trim().split(RegExp(r'\s+'));
    for (var i = 0; i < parts.length; i++) {
      words.add(MushafWord(
        surah: a.surah,
        ayah: a.ayah,
        text: parts[i],
        isAyahEnd: i == parts.length - 1,
        startsNewSurah: i == 0 && a.ayah == 1,
      ));
    }
  }
  return words;
}

/// Extra horizontal space reserved per ayah-end marker (the existing
/// `_AyahMedallion`: a 24x24 `SizedBox` inside `Padding(horizontal: 3)` —
/// see `quran_reading_screen.dart`), used only to decide how many words
/// fit per line. Kept in sync with that widget's actual size by hand,
/// since the layout engine can't inspect widget geometry directly.
const double mushafAyahMedallionWidth = 24 + 3 + 3;

/// Packs [words] into lines that each fit within [maxWidth] at [fontSize],
/// forcing a line break before any word with `startsNewSurah`. Pure
/// measurement via [TextPainter] — no widget tree involved, so this runs
/// the same in a test as in the app.
List<MushafLine> packWordsIntoLines({
  required List<MushafWord> words,
  required double maxWidth,
  required double fontSize,
  required String fontFamily,
}) {
  final style = TextStyle(fontFamily: fontFamily, fontSize: fontSize);
  double measure(String text) {
    final painter = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.rtl)
      ..layout();
    return painter.width;
  }

  final spaceWidth = measure(' ');
  final lines = <MushafLine>[];
  var current = <MushafWord>[];
  var currentWidth = 0.0;

  for (final word in words) {
    final wordWidth = measure(word.text) + (word.isAyahEnd ? mushafAyahMedallionWidth : 0);
    final wouldBeWidth = current.isEmpty ? wordWidth : currentWidth + spaceWidth + wordWidth;
    final forcedBreak = word.startsNewSurah && current.isNotEmpty;
    if (current.isNotEmpty && (wouldBeWidth > maxWidth || forcedBreak)) {
      lines.add(MushafLine(current));
      current = [word];
      currentWidth = wordWidth;
    } else {
      current.add(word);
      currentWidth = wouldBeWidth;
    }
  }
  if (current.isNotEmpty) lines.add(MushafLine(current));
  return lines;
}

/// Finds the largest font size (stepping down from [maxFontSize] toward
/// [minFontSize]) whose greedy packing fits within [targetLines] — bigger
/// text is always preferred as long as it still fits. Smaller font size can
/// only ever produce the same or MORE words per line (fewer or equal
/// lines), so a simple downward scan is enough; no true binary search
/// needed. If even [minFontSize] doesn't fit within [targetLines], returns
/// [minFontSize] anyway — the caller wraps the page in a scroll view, so
/// overflow degrades to "scroll a bit further", not a crash or clipped text.
MushafPageLayout computeMushafPageLayout({
  required List<QuranAyahText> ayat,
  required double maxWidth,
  required String fontFamily,
  int targetLines = 15,
  double maxFontSize = 24,
  double minFontSize = 14,
  double step = 0.5,
}) {
  final words = flattenAyatToWords(ayat);
  if (words.isEmpty) return const MushafPageLayout(lines: [], fontSize: 21);

  var fontSize = maxFontSize;
  var lines = packWordsIntoLines(words: words, maxWidth: maxWidth, fontSize: fontSize, fontFamily: fontFamily);
  while (lines.length > targetLines && fontSize > minFontSize) {
    fontSize = (fontSize - step).clamp(minFontSize, maxFontSize);
    lines = packWordsIntoLines(words: words, maxWidth: maxWidth, fontSize: fontSize, fontFamily: fontFamily);
  }
  return MushafPageLayout(lines: lines, fontSize: fontSize);
}
