import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/tts/text_sources/readable_text_source.dart';

void main() {
  group('splitIntoPlayableParagraphs', () {
    test('short lines pass through unchanged', () {
      final result = splitIntoPlayableParagraphs('بسم الله الرحمن الرحيم\nالمقدمة');
      expect(result, ['بسم الله الرحمن الرحيم', 'المقدمة']);
    });

    test('empty input returns empty list', () {
      expect(splitIntoPlayableParagraphs(''), isEmpty);
    });

    test('blank lines are dropped', () {
      final result = splitIntoPlayableParagraphs('سطر أول\n\n\nسطر ثانٍ');
      expect(result, ['سطر أول', 'سطر ثانٍ']);
    });

    test('long line splits at sentence boundaries, no chunk exceeds the max', () {
      final sentence = 'الحمد لله رب العالمين والصلاة والسلام على أشرف الأنبياء والمرسلين';
      final longLine = List.filled(6, sentence).join('. ');
      expect(longLine.length, greaterThan(kMaxParagraphChars));

      final result = splitIntoPlayableParagraphs(longLine);

      expect(result.length, greaterThan(1));
      for (final chunk in result) {
        expect(chunk.length, lessThanOrEqualTo(kMaxParagraphChars));
      }
      // لا فقدان محتوى — إعادة التجميع (بمسافة واحدة) يجب أن يحوي نفس الكلمات.
      expect(result.join(' ').replaceAll(RegExp(r'\s+'), ' '), contains('الحمد لله رب العالمين'));
    });

    test('long line with no punctuation still splits, not sent whole', () {
      final noPunctuation = 'كلمة' * 200; // بلا أي علامة ترقيم إطلاقًا
      final result = splitIntoPlayableParagraphs(noPunctuation);
      expect(result.length, greaterThan(1));
      for (final chunk in result) {
        expect(chunk.length, lessThanOrEqualTo(kMaxParagraphChars));
      }
    });

    test('long line with words but no punctuation splits at word boundaries — no word is cut in half', () {
      // خلل حقيقي أبلغ عنه إسماعيل على جهازه الحقيقي (2026-09-18): "الصوت
      // يبلع بعض الأحرف" — سببه قصّ حرفي صارم كان يقع أحيانًا في منتصف
      // كلمة، وكل قطعة تُولَّد كاستدعاء TTS مستقلّ فتخرج مبتورة الصوت.
      final words = List.generate(100, (i) => 'كلمة$i');
      final longLine = words.join(' ');
      expect(longLine.length, greaterThan(kMaxParagraphChars));

      final result = splitIntoPlayableParagraphs(longLine);

      expect(result.length, greaterThan(1));
      final reconstructedWords = result.expand((chunk) => chunk.split(' ')).toList();
      expect(reconstructedWords, words);
    });

    test('short chunks are not dropped by trimming', () {
      final result = splitIntoPlayableParagraphs('- أ -');
      expect(result, ['- أ -']);
    });
  });
}
