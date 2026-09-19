import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/tts/text_sources/readable_text_source.dart';

void main() {
  group('splitIntoPlayableParagraphs', () {
    test('short lines pass through unchanged (trailing pause added — no terminal punctuation)', () {
      // إضافة "،" لمقطع بلا ترقيم نهائي (2026-09-18، بحث حقيقي: rhasspy/piper
      // #349 — نص بلا نقطة نهاية يُقرأ بلا وقفة، قد يُسمَع كـ"ابتلاع" الكلمة
      // الأخيرة رغم نطقها كاملة).
      final result = splitIntoPlayableParagraphs('بسم الله الرحمن الرحيم\nالمقدمة');
      expect(result, ['بسم الله الرحمن الرحيم،', 'المقدمة،']);
    });

    test('strips isolated quote/bracket marks that crash espeak-ng as bogus words', () {
      // خلل حقيقي حدث على الجهاز (2026-09-19): علامة اقتباس معزولة بمسافات
      // (نمط شائع في التراث حول مصطلح مُقتبَس) أسقطت التطبيق بتعطّل أصلي في
      // محرك قاموس espeak-ng (`LookupDict2`، عنوان عطل ثابت 0x87) — وُجِد
      // بالتشخيص الفعلي (.claude/skills/native-crash-diagnosis)، غير مرتبط
      // بترميز HTML كما ظُنَّ أولًا.
      final result = splitIntoPlayableParagraphs('أطلق السلف على العقيدة اسم " السنة "');
      expect(result, ['أطلق السلف على العقيدة اسم السنة،']);
    });

    test('expands the ﷺ honorific ligature instead of dropping it', () {
      // خلل حقيقي ثانٍ حدث على الجهاز (2026-09-19) بعد إصلاح علامات
      // الاقتباس: رمز واحد "ﷺ" (U+FDFA) أسقط التطبيق بتعطّل من نمط مختلف
      // تمامًا (عنوان عشوائي ضخم لا صغيرًا كالمرات السابقة) — على الأرجح
      // لا يملك espeak-ng إدخالًا له في جدول الأصوات إطلاقًا. يُستبدَل
      // بالعبارة المنطوقة الكاملة، لا يُحذَف (حذفه يُسقِط معنى الصلاة).
      final result = splitIntoPlayableParagraphs('محمد بن عبد الله ﷺ والذي ما ترك خيرًا');
      expect(result, ['محمد بن عبد الله صلى الله عليه وسلم والذي ما ترك خيرًا،']);
    });

    test('strips isolated ASCII punctuation tokens but keeps embedded ones', () {
      // خلل حقيقي ثالث حدث على الجهاز (2026-09-19): فاصلة لاتينية `,`
      // معزولة بمسافات أسقطت التطبيق (عنوان عطل 0x2f، نفس نمط علامات
      // الاقتباس المعزولة). "3.5" يجب ألا يتأثر — النقطة متّصلة بالرقم لا
      // معزولة.
      final result = splitIntoPlayableParagraphs('كلمة أولى , كلمة ثانية والرقم 3.5 صحيح');
      expect(result, ['كلمة أولى كلمة ثانية والرقم 3.5 صحيح،']);
    });

    test('empty input returns empty list', () {
      expect(splitIntoPlayableParagraphs(''), isEmpty);
    });

    test('blank lines are dropped', () {
      final result = splitIntoPlayableParagraphs('سطر أول\n\n\nسطر ثانٍ');
      expect(result, ['سطر أول،', 'سطر ثانٍ،']);
    });

    test('lines already ending in punctuation are left unchanged', () {
      final result = splitIntoPlayableParagraphs('هل هذا صحيح؟\nنعم، هذا صحيح.');
      expect(result, ['هل هذا صحيح؟', 'نعم، هذا صحيح.']);
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
        // +1: فاصلة الوقفة المُضافة تلقائيًا لمقطع بلا ترقيم قد تتجاوز الحد
        // بحرف واحد فقط — هامش مقبول (الحد أصلًا تقريبي لأغراض زمن الاستجابة،
        // لا قيد تقني صارم).
        expect(chunk.length, lessThanOrEqualTo(kMaxParagraphChars + 1));
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
      // إزالة فاصلة الوقفة المُضافة تلقائيًا لكل مقطع قبل مقارنة الكلمات —
      // هذا الاختبار يتحقّق فقط من سلامة تقسيم الكلمات، لا من الترقيم.
      final reconstructedWords = result
          .map((chunk) => chunk.endsWith('،') ? chunk.substring(0, chunk.length - 1) : chunk)
          .expand((chunk) => chunk.split(' '))
          .toList();
      expect(reconstructedWords, words);
    });

    test('short chunks are not dropped by trimming', () {
      final result = splitIntoPlayableParagraphs('- أ -');
      expect(result, ['- أ -،']);
    });
  });
}
