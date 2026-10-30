import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/utils/recitation_alignment.dart';
import 'package:talib_alilm_app/utils/recitation_text.dart';

/// ت1/ت2 of `docs/memorization/RECITATION_REBUILD_PLAN.md`: the muṣḥaf side
/// is the real Uthmani text of page 2 (as stored in `mushaf_words`), the said
/// side is what Android's recognizer writes — plain modern spelling.
const _page2Start = [
  'الٓمٓ', 'ذَٰلِكَ', 'ٱلۡكِتَٰبُ', 'لَا', 'رَيۡبَ', 'فِيهِ', 'هُدٗى', 'لِّلۡمُتَّقِينَ', //
  'ٱلَّذِينَ', 'يُؤۡمِنُونَ', 'بِٱلۡغَيۡبِ', 'وَيُقِيمُونَ', 'ٱلصَّلَوٰةَ', 'وَمِمَّا', 'رَزَقۡنَٰهُمۡ', 'يُنفِقُونَ',
];

List<RecitationWordStatus> _statuses(RecitationSegmentResult r) => r.words.map((w) => w.status).toList();

void main() {
  group('recitationKey / isSilentMark', () {
    test('Uthmani and plain spelling reduce to the same key', () {
      expect(recitationKey('ذَٰلِكَ'), recitationKey('ذلك'));
      expect(recitationKey('ٱلۡكِتَٰبُ'), recitationKey('الكتاب'));
      expect(recitationKey('ٱلصَّلَوٰةَ'), recitationKey('الصلاة'));
      expect(recitationKey('يُؤۡمِنُونَ'), recitationKey('يؤمنون'));
      expect(recitationKey('هُدٗى'), recitationKey('هدى'));
    });

    test('waqf signs are silent, letters are not', () {
      expect(isSilentMark('ۛ'), isTrue);
      expect(isSilentMark('ۖ'), isTrue);
      expect(isSilentMark('ۚ'), isTrue);
      expect(isSilentMark('لَا'), isFalse);
    });
  });

  group('muqattaat', () {
    test('«الم» said as one word or as letter names both match «الٓمٓ»', () {
      expect(recitationWordsMatch('الٓمٓ', 'الم'), isTrue);
      expect(splitRecitedTranscript('الف لام ميم ذلك الكتاب'), ['الفلامميم', 'ذلك', 'الكتاب']);
      expect(recitationWordsMatch('الٓمٓ', 'الفلامميم'), isTrue);
      expect(recitationWordsMatch('صٓ', 'صاد'), isTrue);
    });

    test('ordinary words are never read as letter names', () {
      expect(recitationWordsMatch('مِن', 'ميمنون'), isFalse);
      expect(splitRecitedTranscript('يا أيها الناس'), ['يا', 'أيها', 'الناس']);
    });
  });

  group('alignRecitationSegment', () {
    test('a correct recitation in plain spelling has zero false mistakes', () {
      final said = splitRecitedTranscript('الم ذلك الكتاب لا ريب فيه هدى للمتقين الذين يؤمنون بالغيب ويقيمون الصلاة ومما رزقناهم ينفقون');
      final r = alignRecitationSegment(expectedWords: _page2Start, saidWords: said);
      expect(r.consumed, _page2Start.length);
      expect(r.words.every((w) => w.status == RecitationWordStatus.correct), isTrue);
      expect(r.extraWordCount, 0);
    });

    test('pausing after one ayah commits only that ayah — the rest of the page is not "missing"', () {
      final said = splitRecitedTranscript('الم ذلك الكتاب لا ريب فيه هدى للمتقين');
      final r = alignRecitationSegment(expectedWords: _page2Start, saidWords: said);
      expect(r.consumed, 8);
      expect(r.words.every((w) => w.status == RecitationWordStatus.correct), isTrue);
    });

    test('a skipped word inside the segment is missing; a substituted one is wrong', () {
      // «فيه» skipped, «للمؤمنين» said for «للمتقين».
      final said = splitRecitedTranscript('الم ذلك الكتاب لا ريب هدى للمؤمنين الذين يؤمنون');
      final r = alignRecitationSegment(expectedWords: _page2Start, saidWords: said);
      expect(_statuses(r).take(10), [
        RecitationWordStatus.correct, RecitationWordStatus.correct, RecitationWordStatus.correct,
        RecitationWordStatus.correct, RecitationWordStatus.correct,
        RecitationWordStatus.missing, // فيه
        RecitationWordStatus.correct,
        RecitationWordStatus.wrong, // للمتقين ← للمؤمنين
        RecitationWordStatus.correct, RecitationWordStatus.correct,
      ]);
      expect(r.consumed, 10);
    });

    test('a segment never ends on a guess: trailing unmatched words stay pending', () {
      final said = splitRecitedTranscript('الم ذلك الكتاب شيء');
      final r = alignRecitationSegment(expectedWords: _page2Start, saidWords: said);
      expect(r.consumed, 3);
      expect(r.extraWordCount, 1);
    });

    test('silence commits nothing', () {
      final r = alignRecitationSegment(expectedWords: _page2Start, saidWords: const []);
      expect(r.consumed, 0);
    });
  });
}
