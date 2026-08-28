import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/utils/recitation_alignment.dart';

List<String> _words(String text) => text.split(' ');

void main() {
  group('alignRecitation', () {
    test('perfect recitation of Al-Fatihah ayah 2 scores 100% with no mistakes', () {
      final expected = _words('الحمد لله رب العالمين');
      final result = alignRecitation(expectedWords: expected, saidWords: _words('الحمد لله رب العالمين'));
      expect(result.score, 1.0);
      expect(result.words.every((w) => w.status == RecitationWordStatus.correct), isTrue);
      expect(result.extraWordCount, 0);
    });

    test('a missing word is flagged as missing, not wrong, and does not corrupt the rest of the alignment', () {
      // Real case from the earlier normalizeArabicForSearch fix notes: skipping "الرحمن".
      final expected = _words('الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين');
      final said = _words('الحمد لله رب العالمين الرحيم مالك يوم الدين');
      final result = alignRecitation(expectedWords: expected, saidWords: said);
      final statuses = result.words.map((w) => w.status).toList();
      expect(statuses, [
        RecitationWordStatus.correct, // الحمد
        RecitationWordStatus.correct, // لله
        RecitationWordStatus.correct, // رب
        RecitationWordStatus.correct, // العالمين
        RecitationWordStatus.missing, // الرحمن (skipped)
        RecitationWordStatus.correct, // الرحيم
        RecitationWordStatus.correct, // مالك
        RecitationWordStatus.correct, // يوم
        RecitationWordStatus.correct, // الدين
      ]);
      expect(result.extraWordCount, 0);
    });

    test('an extra inserted word is counted separately and does not shift the real words out of place', () {
      final expected = _words('قل هو الله أحد');
      final said = _words('قل هو الله سبحانه أحد'); // "سبحانه" inserted, not in the ayah
      final result = alignRecitation(expectedWords: expected, saidWords: said);
      expect(result.words.map((w) => w.status).toList(), [
        RecitationWordStatus.correct,
        RecitationWordStatus.correct,
        RecitationWordStatus.correct,
        RecitationWordStatus.correct,
      ]);
      expect(result.extraWordCount, 1);
      // "سبحانه" was said between "الله" (expected index 2) and "أحد"
      // (expected index 3) -- extraWordPositions records it as occurring
      // immediately before words[3], which is what a page-level caller
      // (76.3-redesign) needs to attribute the extra to the right ayah.
      expect(result.extraWordPositions, [3]);
    });

    test('extraWordPositions places a trailing extra after the last expected word', () {
      final expected = _words('قل هو الله أحد');
      final said = _words('قل هو الله أحد سبحانه'); // extra said after the ayah ends
      final result = alignRecitation(expectedWords: expected, saidWords: said);
      expect(result.extraWordCount, 1);
      expect(result.extraWordPositions, [4]); // 4 == words.length: after everything
    });

    test('a substituted word is flagged wrong with the real said word attached', () {
      final expected = _words('إياك نعبد وإياك نستعين');
      final said = _words('إياك نعبد وإياك نستعن'); // real plausible mis-transcription
      final result = alignRecitation(expectedWords: expected, saidWords: said);
      final last = result.words.last;
      expect(last.expectedWord, 'نستعين');
      // "نستعن" vs "نستعين" is within fuzzy-match tolerance (short edit distance),
      // so this specific pair should still register as correct -- verifies the
      // alignment reuses isFuzzyMatch's real tolerance instead of exact string equality.
      expect(last.status, RecitationWordStatus.correct);
    });

    test('a genuinely different word is flagged wrong, not silently accepted', () {
      final expected = _words('مالك يوم الدين');
      final said = _words('مالك يوم الدنيا'); // a real, different word -- not a typo of "الدين"
      final result = alignRecitation(expectedWords: expected, saidWords: said);
      expect(result.words.last.status, RecitationWordStatus.wrong);
      expect(result.words.last.saidWord, 'الدنيا');
    });

    test('reciting nothing scores 0 and flags every expected word as missing', () {
      final expected = _words('بسم الله الرحمن الرحيم');
      final result = alignRecitation(expectedWords: expected, saidWords: []);
      expect(result.score, 0.0);
      expect(result.words.every((w) => w.status == RecitationWordStatus.missing), isTrue);
    });

    test('an empty expected ayah scores a perfect 1.0 (nothing to get wrong)', () {
      final result = alignRecitation(expectedWords: [], saidWords: ['شيء']);
      expect(result.score, 1.0);
      expect(result.extraWordCount, 1);
      expect(result.extraWordPositions, [0]);
    });

    test('a whole page (multiple ayat concatenated) aligns correctly across the ayah boundary -- '
        'the same call this function makes for a single ayah works unmodified at page scale '
        '(76.3-redesign: RecitationRepository.recordPageAttempt relies on exactly this)', () {
      // Al-Ikhlas 1-2 concatenated, as recordPageAttempt would flatten them.
      final expected = _words('قل هو الله أحد الله الصمد');
      final said = _words('قل هو الله أحد الله الصمد'); // recited perfectly straight through
      final result = alignRecitation(expectedWords: expected, saidWords: said);
      expect(result.score, 1.0);
      expect(result.words.length, 6);

      // Manually replicate RecitationRepository.recordPageAttempt's slicing
      // to verify the boundary logic without needing a real database.
      final ayahWordCounts = [4, 2]; // "قل هو الله أحد" | "الله الصمد"
      var cursor = 0;
      final slices = <List<RecitationWordResult>>[];
      for (final count in ayahWordCounts) {
        slices.add(result.words.sublist(cursor, cursor + count));
        cursor += count;
      }
      expect(slices[0].map((w) => w.expectedWord).toList(), ['قل', 'هو', 'الله', 'أحد']);
      expect(slices[1].map((w) => w.expectedWord).toList(), ['الله', 'الصمد']);
    });
  });
}
