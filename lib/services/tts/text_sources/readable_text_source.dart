/// الواجهة الموحَّدة التي تجعل أي نظام كتب "قابلًا للاستماع" — طبقة الصوت لا
/// تتعامل مع تراث أو مكتبتي مباشرة، فقط مع هذا العقد.
/// `docs/audio-reader/TEXT_SOURCE_ADAPTERS.md` §1.
library;

abstract class ReadableTextSource {
  /// مثال: 'turath:137' أو 'library:bookKey'. مفتاح فريد يدخل في مفتاح
  /// التخزين المؤقت المستقبلي (§2 من نفس الملف).
  String get sourceId;

  /// لعرضه في واجهة القارئ الصوتي (لم تُبنَ بعد — المرحلة 4).
  String get title;

  /// نص الوحدة (صفحة عادةً) مجزَّأ لفقرات جاهزة للتوليد فقرة فقرة.
  Future<List<String>> paragraphsForUnit(int unitIndex);

  /// عدد الصفحات/الوحدات الكلي في هذا الكتاب.
  Future<int> get totalUnits;

  /// يُقرَأ من مصدر التتبّع الأصلي لهذا النظام — لا جدول جديد.
  Future<int?> get lastReadUnit;

  /// يُكتَب لنفس مصدر التتبّع الأصلي لهذا النظام.
  Future<void> saveLastListenedUnit(int unitIndex);
}

/// حد أقصى تقريبي لطول الفقرة الواحدة المُرسَلة للتوليد — فقرة أطول تُقسَّم
/// عند حدود الجمل (§4 من AUDIO_100_ROADMAP.md: فقرات أقصر = زمن انتظار أول
/// صوت أقلّ، ومدة أقصر لاستدعاء `generate()` المتزامن داخل العزلة الخلفية).
const int kMaxParagraphChars = 280;

/// يُقسِّم نصًا خامًا (صفحة/وحدة) إلى فقرات قابلة للتوليد: أولًا عند أسطر
/// فارغة (بنية الفقرات الطبيعية للنص)، ثم أي فقرة أطول من [kMaxParagraphChars]
/// تُقسَّم إضافيًا عند علامات نهاية الجملة العربية بدل إرسالها كاملة لاستدعاء
/// توليد واحد طويل. مشترك بين كل منفِّذي `ReadableTextSource` — منطق تقسيم
/// واحد، لا تكرار لكل مصدر.
List<String> splitIntoPlayableParagraphs(String normalizedText) {
  if (normalizedText.isEmpty) return const [];

  final lines = normalizedText.split('\n').map((p) => p.trim()).where((p) => p.isNotEmpty);

  final result = <String>[];
  for (final line in lines) {
    if (line.length <= kMaxParagraphChars) {
      result.add(_ensureTrailingPause(line));
      continue;
    }
    result.addAll(_splitLongLine(line));
  }
  return result;
}

/// علامات ترقيم يعتمد عليها Piper/VITS فعليًا لتوليد وقفة طبيعية في نهاية
/// المقطع — بحث حقيقي (GitHub rhasspy/piper #349: نص بلا نقطة نهاية يُقرأ
/// كجملة واحدة متصلة بلا وقفة). أي مقطع يُرسَل للتوليد بلا إحداها ينتهي
/// صوتيًا بشكل مفاجئ/مبتور، قد يُسمَع كـ"ابتلاع" آخر كلمة رغم أن النموذج
/// نطقها كاملة فعليًا — المشكلة في غياب الوقفة بعدها لا في النطق نفسه.
const _terminalPunctuation = ['.', '،', '؛', '!', '؟', ':', ')', '"', '”', '»'];

/// يضيف فاصلة عربية "،" لأي مقطع لا ينتهي أصلًا بعلامة ترقيم معروفة —
/// يحدث هذا حين يُقطَع مقطع في منتصف جملة أطول (المسار الاحتياطي في
/// [_splitLongLine]، أو حتى فقرة مصدر لا تنتهي بترقيم أصلًا). فاصلة لا نقطة
/// لأن المقطع فعليًا "يستمر" (ليس نهاية جملة حقيقية) — إشارة صوتية ونصية
/// صحيحة دلاليًا، لا مجرد حيلة تقنية.
String _ensureTrailingPause(String text) {
  if (text.isEmpty) return text;
  if (_terminalPunctuation.contains(text[text.length - 1])) return text;
  return '$text،';
}

/// يُقسِّم سطرًا طويلًا عند أول علامة نهاية جملة بعد تجاوز الحد، لا عند حد
/// حرفي صارم — يحافظ على جمل كاملة صالحة للنطق، لا قطعًا عشوائيًا في المنتصف.
List<String> _splitLongLine(String line) {
  const sentenceEnders = ['. ', '، ', '؛ ', '! ', '؟ '];
  final chunks = <String>[];
  var start = 0;

  while (start < line.length) {
    if (line.length - start <= kMaxParagraphChars) {
      chunks.add(_ensureTrailingPause(line.substring(start).trim()));
      break;
    }

    var cut = -1;
    for (final ender in sentenceEnders) {
      final idx = line.indexOf(ender, start + kMaxParagraphChars ~/ 2);
      if (idx != -1 && idx < start + kMaxParagraphChars && (cut == -1 || idx < cut)) {
        cut = idx + ender.length;
      }
    }
    // لا علامة نهاية جملة مناسبة ضمن النطاق؟ قصّ عند آخر مسافة قبل الحد
    // الأقصى بدل قصّ حرفي صارم قد يقع في منتصف كلمة — كل قطعة تُولَّد
    // كاستدعاء TTS مستقلّ، فقصّ كلمة نصفين يُنتِج "ابتلاع حروف" حقيقي عند
    // حدود القطع (النموذج لا يملك بقية أصوات الكلمة، خلل حقيقي أبلغ عنه
    // إسماعيل على جهازه الحقيقي 2026-09-18). لا مسافة قريبة كافية؟ اقصّ عند
    // الحد نفسه فقط كملاذ أخير (كلمة واحدة أطول من الحد بأكمله — نادر جدًا).
    if (cut == -1) {
      final limit = start + kMaxParagraphChars;
      final lastSpace = line.lastIndexOf(' ', limit);
      cut = (lastSpace > start) ? lastSpace : limit;
    }

    chunks.add(_ensureTrailingPause(line.substring(start, cut).trim()));
    start = cut;
  }

  return chunks.where((c) => c.isNotEmpty).toList();
}
