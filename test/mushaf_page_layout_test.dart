import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/repositories/quran_reading_repository.dart';
import 'package:talib_alilm_app/services/mushaf_page_layout.dart';

QuranAyahText _ayah(int surah, int ayah, String text) =>
    QuranAyahText(surah: surah, ayah: ayah, text: text, juzNumber: 1);

void main() {
  group('flattenAyatToWords', () {
    test('splits each ayah into words and marks the last word of each ayah', () {
      final words = flattenAyatToWords([_ayah(1, 1, 'بسم الله الرحمن الرحيم')]);
      expect(words.map((w) => w.text).toList(), ['بسم', 'الله', 'الرحمن', 'الرحيم']);
      expect(words.map((w) => w.isAyahEnd).toList(), [false, false, false, true]);
    });

    test('marks only the first word of ayah 1 as starting a new surah', () {
      final words = flattenAyatToWords([_ayah(2, 1, 'الم'), _ayah(2, 2, 'ذلك الكتاب')]);
      expect(words[0].startsNewSurah, isTrue);
      expect(words.skip(1).every((w) => !w.startsNewSurah), isTrue);
    });

    test('an ayah that is not ayah 1 never starts a new surah', () {
      final words = flattenAyatToWords([_ayah(2, 5, 'أولئك على هدى')]);
      expect(words.every((w) => !w.startsNewSurah), isTrue);
    });
  });

  group('packWordsIntoLines', () {
    test('a single short word fits on one line', () {
      final words = flattenAyatToWords([_ayah(1, 1, 'الله')]);
      final lines = packWordsIntoLines(words: words, maxWidth: 400, fontSize: 20, fontFamily: 'Arial');
      expect(lines, hasLength(1));
      expect(lines.first.words, hasLength(1));
    });

    test('a narrow max width forces every word onto its own line', () {
      final words = flattenAyatToWords([_ayah(1, 1, 'بسم الله الرحمن الرحيم')]);
      final lines = packWordsIntoLines(words: words, maxWidth: 1, fontSize: 20, fontFamily: 'Arial');
      // Each line always gets at least one word even if it doesn't
      // technically fit — a narrow width must never drop words.
      expect(lines, hasLength(4));
      final rejoined = lines.expand((l) => l.words).map((w) => w.text).toList();
      expect(rejoined, ['بسم', 'الله', 'الرحمن', 'الرحيم']);
    });

    test('a wide max width fits everything on one line', () {
      final words = flattenAyatToWords([_ayah(1, 1, 'بسم الله الرحمن الرحيم')]);
      final lines = packWordsIntoLines(words: words, maxWidth: 5000, fontSize: 20, fontFamily: 'Arial');
      expect(lines, hasLength(1));
    });

    test('a new surah always starts its own line even if the previous line has room', () {
      final words = flattenAyatToWords([_ayah(1, 7, 'صراط'), _ayah(2, 1, 'الم')]);
      final lines = packWordsIntoLines(words: words, maxWidth: 5000, fontSize: 20, fontFamily: 'Arial');
      expect(lines, hasLength(2));
      expect(lines[0].words.single.text, 'صراط');
      expect(lines[1].words.single.text, 'الم');
    });

    test('no word is ever silently dropped across multiple ayat', () {
      final ayat = [
        _ayah(1, 1, 'بسم الله الرحمن الرحيم'),
        _ayah(1, 2, 'الحمد لله رب العالمين'),
        _ayah(1, 3, 'الرحمن الرحيم'),
      ];
      final words = flattenAyatToWords(ayat);
      final lines = packWordsIntoLines(words: words, maxWidth: 150, fontSize: 20, fontFamily: 'Arial');
      final totalWordsInLines = lines.fold<int>(0, (sum, l) => sum + l.words.length);
      expect(totalWordsInLines, words.length);
    });
  });

  group('computeMushafPageLayout', () {
    test('returns an empty layout for an empty page without throwing', () {
      final layout = computeMushafPageLayout(ayat: [], maxWidth: 300, fontFamily: 'Arial');
      expect(layout.lines, isEmpty);
    });

    test('shrinks the font size until the page fits within targetLines, or stops at minFontSize', () {
      // A long enough ayah at a narrow width will need many lines at the
      // largest font size — the engine should shrink toward minFontSize
      // trying to bring it within the target, never picking a size above
      // maxFontSize or below minFontSize.
      final ayat = [_ayah(1, 1, List.generate(40, (i) => 'كلمة$i').join(' '))];
      final layout = computeMushafPageLayout(
        ayat: ayat,
        maxWidth: 200,
        fontFamily: 'Arial',
        targetLines: 15,
        maxFontSize: 24,
        minFontSize: 14,
      );
      expect(layout.fontSize, greaterThanOrEqualTo(14));
      expect(layout.fontSize, lessThanOrEqualTo(24));
      final totalWords = layout.lines.fold<int>(0, (sum, l) => sum + l.words.length);
      expect(totalWords, 40);
    });

    test('a short page keeps the largest font size since it already fits', () {
      final ayat = [_ayah(1, 1, 'قل هو الله أحد')];
      final layout = computeMushafPageLayout(ayat: ayat, maxWidth: 5000, fontFamily: 'Arial', maxFontSize: 24, minFontSize: 14);
      expect(layout.fontSize, 24);
      expect(layout.lines, hasLength(1));
    });
  });
}
