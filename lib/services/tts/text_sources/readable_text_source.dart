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

  final sanitized = _stripTtsUnsafeMarks(_stripIsolatedAsciiPunctuationTokens(_expandHonorificLigatures(normalizedText)));
  final lines = sanitized.split('\n').map((p) => p.trim()).where((p) => p.isNotEmpty);

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

/// علامات اقتباس/قوسين زخرفية لا قيمة صوتية لها — TTS لا يحتاج نطقها أصلًا.
/// حين تصبح "كلمة" معزولة بمسافات على الجانبين (نمط شائع جدًا في كتب
/// التراث حول مصطلح مُقتبَس، مثل اسم "السنة") تُسقِط خلل حقيقي في محرك
/// قاموس espeak-ng (`LookupDict2`) — عنوان عطل ثابت `0x87` تكرّر عبر عدة
/// نصوص حقيقية مختلفة تمامًا، وُجِد بالتشخيص الفعلي
/// (`.claude/skills/native-crash-diagnosis`)، وليس مرتبطًا بترميز HTML كما
/// ظُنَّ أولًا (ذاك كان يُنتِج نفس النمط: علامة اقتباس معزولة). تُحذَف
/// كليًا (لا تُستبدَل بمسافة) — النص المعروض للقارئ في الشاشة لا يتأثر،
/// هذا التنظيف مخصَّص لمسار TTS فقط (`normalizePageText` المُستخدَم للعرض
/// منفصل تمامًا).
const _ttsUnsafeMarks = ['"', '“', '”', '«', '»', '[', ']'];

/// علامات ترقيم لاتينية (ASCII) — على الأرجح آثار OCR/تحويل نص — تُسقِط
/// نفس خلل espeak-ng حين تظهر **معزولة** كـ"كلمة" مستقلة. خلافًا لعلامات
/// الاقتباس/الأقواس في [_ttsUnsafeMarks] — هذه لا تُحذَف أينما وُجِدت، بل
/// فقط حين تكون معزولة، لأن بعضها له معنى حقيقي متّصل بكلمة أو رقم (مثل
/// "3.5" أو "well-known") لا يجب المساس به.
///
// لا '-'/'_' هنا عمدًا: شرطة معزولة نمط عنونة/تعداد عربي مشروع وحقيقي
// (مثال: "- أ -" كعنوان فرعي مرقَّم بحرف) — لا دليل تعطّل عليها.
///
/// **تصحيح جذري (2026-09-19)، محاولتان حقيقيتان**: (١) فاصلة لاتينية `,`
/// معزولة **بمسافات ASCII** أسقطت التطبيق أول مرة (عنوان عطل `0x2f`) —
/// أُصلِحت بتقسيم كل سطر على المسافة وإسقاط أي "كلمة" تتكوّن بالكامل من
/// هذه الرموز. (٢) نفس الخلل تكرّر (عنوان عطل `0x93`) رغم ذلك الإصلاح:
/// الفاصلة هذه المرة لم تكن محاطة بمسافة ASCII، بل ملاصقة لرمز ترقيم آخر
/// (عربي على الأرجح) — فتخطّاها التقسيم بالمسافة بالكامل رغم كونها
/// "معزولة" فعليًا من منظور espeak-ng، الذي يعتبر أي رمز غير حرفي (عربيًا
/// كان أم لاتينيًا) حدًّا لكلمة، لا المسافة ASCII تحديدًا. التعريف
/// الصحيح إذن: أي رمز من هذه المجموعة غير ملاصق لحرف/رقم (بأي لغة، عبر
/// `\p{L}`/`\p{N}`) على أي من الجانبين، بغضّ النظر عمّا يجاوره تحديدًا.
/// Lookaround بحرف واحد ثابت الطول على كل جانب لا خطر تراجع
/// (backtracking) منه حتى على صفحات OCR طويلة.
final RegExp _isolatedAsciiPunctuationPattern = RegExp(
  r'(?<![\p{L}\p{N}])[,.;:!?(){}<>=*/\\|~^+](?![\p{L}\p{N}])',
  unicode: true,
);
final RegExp _repeatedSpaces = RegExp(' {2,}');

String _stripIsolatedAsciiPunctuationTokens(String text) {
  if (!_isolatedAsciiPunctuationPattern.hasMatch(text)) return text;
  return text.replaceAll(_isolatedAsciiPunctuationPattern, '').replaceAll(_repeatedSpaces, ' ');
}

/// رموز تشكيلية (ligatures) بحرف واحد لألقاب/عبارات دينية شائعة — لا علاقة
/// لها بخلل قاموس espeak-ng السابق (نمط عطل مختلف تمامًا: عنوان عشوائي ضخم
/// لا `0x87` الصغير المتكرر). حالتان حقيقيتان مختلفتان وُجِدتا 2026-09-19
/// بنفس الآلية بالضبط: «ﷺ» بعد اسم النبي ﷺ، ثم «﵀» بعد اسم الشيخ ابن باز
/// رحمه الله في ترجمة مؤلف — على الأرجح لا يملك جدول تحويل الأصوات في
/// espeak-ng إدخالًا لكتلة Unicode "Arabic Presentation Forms-A" التوافقية
/// هذه إطلاقًا. بما أن هذا نمط متكرر (تراجم علماء تحوي أدعية مشابهة كثيرة)
/// أُضيفت المجموعة الشائعة كاملة استباقًا لا فقط الحالتين المُكتشَفتين.
/// تُستبدَل بالعبارة الكاملة المنطوقة، لا تُحذَف — حذفها يُسقِط معنًى
/// مقصودًا (الصلاة على النبي، الترحّم، إلخ)، لا مجرد زخرفة كعلامات الاقتباس.
const _honorificLigatures = {
  'ﷺ': ' صلى الله عليه وسلم ', // U+FDFA
  'ﷻ': ' عز وجل ', // U+FDFB
  '﷽': ' بسم الله الرحمن الرحيم ', // U+FDFD
  'ﷲ': ' الله ', // U+FDF2
  'ﷳ': ' أكبر ', // U+FDF3 (أكبر)
  'ﷴ': ' محمد ', // U+FDF4
  'ﷵ': ' صلعم ', // U+FDF5 (اختصار الصلاة والسلام)
  'ﷶ': ' رسول ', // U+FDF6
  'ﷷ': ' عليه ', // U+FDF7
  'ﷸ': ' وسلم ', // U+FDF8
  'ﷹ': ' صلى ', // U+FDF9
  '﵀': ' رحمه الله ', // U+FD40 — الحالة الحقيقية الثانية (ابن باز)
  '﵁': ' رحمها الله ', // U+FD41
  '﵂': ' رحمهم الله ', // U+FD42
  '﵃': ' رضي الله عنه ', // U+FD43
  '﵄': ' رضي الله عنها ', // U+FD44
  '﵅': ' رضي الله عنهم ', // U+FD45
  '﵆': ' رضي الله عنهما ', // U+FD46
  '﵇': ' رحمهما الله ', // U+FD47
  '﵈': ' جل جلاله ', // U+FD48
  '﵉': ' جل جلاله ', // U+FD49
  '﵊': ' رحمه الله ', // U+FD4A
};

String _expandHonorificLigatures(String text) {
  if (!_honorificLigatures.keys.any(text.contains)) return text;
  var s = text;
  _honorificLigatures.forEach((ligature, expansion) {
    s = s.replaceAll(ligature, expansion);
  });
  return s;
}

String _stripTtsUnsafeMarks(String text) {
  var s = text;
  for (final mark in _ttsUnsafeMarks) {
    s = s.replaceAll(mark, '');
  }
  while (s.contains('  ')) {
    s = s.replaceAll('  ', ' ');
  }
  return s;
}

/// علامات ترقيم يعتمد عليها Piper/VITS فعليًا لتوليد وقفة طبيعية في نهاية
/// المقطع — بحث حقيقي (GitHub rhasspy/piper #349: نص بلا نقطة نهاية يُقرأ
/// كجملة واحدة متصلة بلا وقفة). أي مقطع يُرسَل للتوليد بلا إحداها ينتهي
/// صوتيًا بشكل مفاجئ/مبتور، قد يُسمَع كـ"ابتلاع" آخر كلمة رغم أن النموذج
/// نطقها كاملة فعليًا — المشكلة في غياب الوقفة بعدها لا في النطق نفسه.
// لا '"'/'"'/'»' هنا — [_stripTtsUnsafeMarks] يحذفها قبل وصول أي سطر إلى
// هذا الفحص، فلن تكون آخر حرف في نص وصل إلى هنا أبدًا.
const _terminalPunctuation = ['.', '،', '؛', '!', '؟', ':', ')'];

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
