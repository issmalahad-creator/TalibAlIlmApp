# TEXT_SOURCE_ADAPTERS.md — طبقة التجريد التي تجعل القارئ الصوتي عامًا

**يكمل**: `BOOK_AUDIO_READER_ARCHITECTURE.md` (الجذر). هذا الملف يحل التحدي الذي طرحه إسماعيل صراحة: "أريد الصوت أن يشتغل في تراث وفي أي كتاب في التطبيق."

---

## 0. الاكتشاف الحقيقي (بالفحص المباشر، لا افتراض)

يوجد بالفعل **نظامان منفصلان تمامًا** للكتب في هذا التطبيق، ببيانات ونماذج مختلفة تمامًا:

| النظام | النموذج | الموضع الحالي | تتبّع آخر قراءة |
|---|---|---|---|
| **تراث** (`turath.io` API) | `TurathPage {bookId, pageNumber, volume, text, headings}` (`lib/models/turath_models.dart`) | `TurathApiClient`/`TurathRepository` | **موجود مسبقًا**: `TurathLastRead {bookId, bookName, pageNumber, updatedAt}` — صف واحد لكل كتاب |
| **مكتبتي** (الشخصية) | `BookContent` (`lib/models/book_content.dart`)، عبر `BookContentService` | `BookRepository`/`BookViewerScreen` | `book_bookmarks.last_updated_date` (موجود أصلًا، ذُكِر في محاضر سابقة) |

**لا يوجد نموذج بيانات ثالث موحَّد بينهما** — كل نظام له مصدر حقيقته الخاص. **القرار المعماري الجوهري هنا**: لا نُوحِّد هذين النظامين (مخاطرة كبيرة غير ضرورية)، بل نبني **طبقة تكييف رفيعة** فوقهما.

---

## 1. الواجهة الموحَّدة (العقد الذي يجعل أي مصدر "قابلًا للاستماع")

```dart
abstract class ReadableTextSource {
  String get sourceId;              // مثال: 'turath:137' أو 'library:42'
  String get title;                 // لعرضه في واجهة القارئ الصوتي
  Future<List<String>> paragraphsForUnit(int unitIndex);  // نص الوحدة (صفحة/فقرة) مجزَّأ لفقرات
  Future<int> get totalUnits;       // عدد الصفحات/الوحدات الكلي في هذا الكتاب
  Future<int?> get lastReadUnit;    // القراءة من مصدر التتبّع الأصلي لكل نظام (لا جدول جديد)
  Future<void> saveLastListenedUnit(int unitIndex);  // يكتب لنفس مصدر التتبّع الأصلي
}
```

**لا جدول قاعدة بيانات جديد لتتبّع الموضع** — كل مُنفِّذ (adapter) يكتب لمصدر التتبّع **الموجود أصلًا لنظامه**:

```dart
class TurathTextSource implements ReadableTextSource {
  // paragraphsForUnit → TurathRepository.getPage(bookId, unitIndex).text مُجزَّأ بفواصل الأسطر/النقاط
  // lastReadUnit / saveLastListenedUnit → يقرأ/يكتب TurathLastRead الموجودة أصلًا فعليًا
}

class PersonalLibraryTextSource implements ReadableTextSource {
  // paragraphsForUnit → BookContentService المُستخرَج أصلًا من الملف (PDF/نص)
  // lastReadUnit / saveLastListenedUnit → book_bookmarks.last_updated_date الموجود أصلًا
}
```

**فائدة هذا التصميم**: أي مصدر نصّي ثالث يُضاف مستقبلًا (كتاب مُجمَّع كامل كالواسطية/زاد المعاد/مدارج السالكين إن كان لها نظام تتبّع خاص بها — **يحتاج تحقّقًا مباشرًا من الكود قبل الافتراض، لم يُفحَص في هذه الجولة**) يحتاج فقط تنفيذ هذه الواجهة الأربعة الدوال — لا تعديل في طبقة الصوت (التخزين المؤقت، المشغّل، الواجهة) إطلاقًا.

---

## 2. طبقة الصوت تتعامل مع الواجهة فقط، لا مع أي نظام كتب مباشرة

```
ReadableTextSource (أيًّا كان مصدره)
        ↓
معالج النص العربي (تنظيف + قد يحتاج دمج فقرات قصيرة/تقسيم طويلة)
        ↓
مفتاح التخزين المؤقت = "${source.sourceId}:${unitIndex}:${paragraphIndex}"
        ↓
(بقية خط الأنابيب كما في BOOK_AUDIO_READER_ARCHITECTURE.md دون تغيير)
```

هذا يعني: شاشة "قارئ الصوت" **واحدة فقط**، تُستدعى بتمرير أي `ReadableTextSource` — لا شاشتين منفصلتين لتراث ومكتبتي.

---

## 3. نقاط دخول الواجهة (زر "استماع" في كل شاشة قراءة)

- `turath_reader_screen.dart` — زر جديد يفتح القارئ الصوتي بـ `TurathTextSource(bookId)`.
- `book_viewer_screen.dart` — زر جديد يفتح القارئ الصوتي بـ `PersonalLibraryTextSource(bookId)`.

**لا تعديل على منطق القراءة البصرية الموجود في أيٍّ من الشاشتين** — الزر الجديد يفتح تجربة استماع منفصلة (نفس نمط "الختمات" كنافذة منبثقة إضافية فوق شاشة موجودة، لا استبدال).

---

## 5. مقعد معماري لاختيار "القارئ" الصوتي (طلب إسماعيل 2026-09-17)

**السبب**: الصوت الحالي (`ar_JO-kareem-medium`) ممتاز، لكن مستقبلًا قد يُضاف صوت احترافي مُدرَّب خصيصًا أو صوت إسماعيل نفسه (عبر تدريب Piper على تسجيلات حقيقية — Piper يدعم هذا فعليًا، يحتاج ساعات تسجيل نظيف + نصوص مطابقة، خارج نطاق هذه المبادرة الآن). **يجب ألا يحتاج هذا إعادة بناء الكود** — نبني الآن على أساس التبديل، لا لاحقًا.

**نفس نمط `reciterId` الموجود أصلًا في `QuranAudioProviderRegistry`** (`lib/services/quran_audio_engine.dart`) — لا نمط جديد:

```dart
enum TtsVoiceSource { bundled, userRecorded, professional }

class TtsVoiceOption {
  final String voiceId;          // مثال: 'piper:ar_JO-kareem-medium'
  final String displayName;      // "كريم (عربي أردني)" — يُعرَض في واجهة اختيار القارئ
  final String modelAssetPath;
  final String configAssetPath;
  final TtsVoiceSource source;
}

class TtsVoiceRegistry {
  List<TtsVoiceOption> get availableVoices;   // اليوم: عنصر واحد فقط
  TtsVoiceOption get defaultVoice;
}
```

**نتائج هذا القرار على بقية التصميم (يُطبَّق من الحبة الأولى، لا لاحقًا)**:
- توقيع الدالة النقية من `BOOK_AUDIO_READER_ARCHITECTURE.md` المرحلة 1.2 يصبح: `Future<Uint8List> synthesize(String text, {required String voiceId})` — حتى لو صوت واحد فقط متاح اليوم.
- مفتاح التخزين المؤقت (`TEXT_SOURCE_ADAPTERS.md` §2) يصبح: `"${voiceId}:${sourceId}:${unitIndex}:${paragraphIndex}"` — تبديل القارئ مستقبلًا يُبطِل ذاكرة التخزين المؤقت تلقائيًا (صحيح، لا صوت قديم يُشغَّل باسم صوت جديد).
- واجهة "اختيار القارئ" (قائمة بسيطة، لاحقًا) تُبنى فوق `TtsVoiceRegistry.availableVoices` — تظهر بعنصر واحد اليوم، وتتّسع بلا تعديل منطق حين يُضاف صوت ثانٍ.
- أي صوت احترافي أو صوت إسماعيل نفسه، **طالما صُدِّر لصيغة Piper ONNX المتوافقة**، يدخل النظام كصف جديد في `TtsVoiceRegistry` فقط — لا تعديل في طبقة التوليد أو التخزين أو القارئ الصوتي نفسه.

## 6. فجوة مفتوحة صريحة (لا افتراض)

هل الكتب المُجمَّعة أصلًا في مكتبة "باب النصوص" (الأربعين، الواسطية، زاد المعاد، مدارج السالكين — Phase 5 من `QURAN_COMPANION_ROADMAP.md`) تُقرَأ عبر نظام تراث نفسه، أم لها جداول/شاشات مستقلة تمامًا؟ **يحتاج فحصًا مباشرًا للكود عند الوصول لحبة "تعميم المصادر"** — لا يُفترَض الجواب هنا.

## 7. تصحيح حقيقي لـ§1 — "مكتبتي" لا يوجد لها نص مُستخرَج إطلاقًا (اكتُشِف 2026-09-17)

**§1 أعلاه افترض خطأً** أن `PersonalLibraryTextSource.paragraphsForUnit` تقرأ "نصًا مُستخرَجًا أصلًا من الملف (PDF/نص)" — تحقّق مباشر من الكود يُثبِت أن هذا **غير صحيح**:

- `BookEntry` (`lib/models/book_content.dart`) = `{id, title, url, date, quiz}` فقط — `url` رابط PDF مباشر من تيليجرام، **لا حقل نص إطلاقًا**.
- `BookContentService.fetch()` يجلب هذا الـ JSON فقط، لا يستخرج شيئًا من الملف نفسه.
- `book_viewer_screen.dart` يعرض الملف عبر `flutter_pdfview` (`PDFView`) — عارض PDFium أصلي، **بلا أي واجهة API لاستخراج نص** (يُرسِم الصفحة كصورة، هذا كل ما يفعله).
- `BookBookmark` (`lib/models/reading_record.dart`) يتتبّع `lastPage`/`totalPages` فقط لأغراض شريط تقدّم القراءة — لا علاقة له بنص الصفحة.
- بحث شامل في `lib/` عن أي استخراج نص/OCR لملفات PDF (لا لصفحات تراث، تلك OCR من طرف turath.io نفسه) **لم يجد شيئًا** — لا مسار موجود اليوم لتحويل PDF إلى نص قابل للتوليد الصوتي.

**الأثر**: `PersonalLibraryTextSource` **لا يمكن بناؤه اليوم بصدق** — أي تنفيذ الآن سيكون إما فارغًا أو وهميًا. هذا قرار معماري حقيقي يحتاج اختيارًا مستقبليًا قبل المتابعة:

1. **استخراج طبقة نص من PDF** (إن وُجدت أصلًا في الملفات المرفوعة) — عبر حزمة مثل `syncfusion_flutter_pdf` (`PdfTextExtractor`؛ يحتاج تحقّق ترخيص Syncfusion Community قبل الاستخدام) أو بديل مفتوح المصدر. **يعمل فقط إذا كانت ملفات المكتبة الشخصية PDF مُنضَّدة رقميًا (typeset) لا صورًا ممسوحة (scanned)** — لم يُتحقَّق أيّهما بعد.
2. **OCR على مستوى الصفحة المُرسَّمة** (مثل Google ML Kit Text Recognition، يعمل على الجهاز، يدعم العربية) — يعمل حتى مع الصور الممسوحة، لكنه أثقل (وقت معالجة + دقة متغيّرة حسب جودة المسح).

**لا قرار هنا** — يحتاج فحصًا مباشرًا لعيّنة حقيقية من ملفات "مكتبتي" الفعلية (هل نصها قابل للتحديد/النسخ داخل عارض PDF عادي؟) قبل اختيار المسار. حتى يُحسَم هذا: **`TurathTextSource` وحدها هي القابلة للبناء اليوم** من طبقة `ReadableTextSource` — `PersonalLibraryTextSource` مُعلَّق رسميًا، ليس تأجيلًا كسولًا بل لأن بناءه الآن يعني نصًا مزيَّفًا.

### 7.1 نتائج بحث فعلي عن الخيارين (2026-09-17) — ثلاثة مسارات مُستبعَدة بدليل حقيقي

بحثتُ ثلاثة مسارات مرشَّحة فعليًا (لا تخمينًا) وجرّبتُ إضافتها فعلًا في worktree المعزولة `talib-audio` حيث أمكن — كلها اصطدمت بعائق حقيقي موثَّق:

1. **`google_mlkit_text_recognition`** (خيار OCR الأول المقترَح في §7 أعلاه) — **مُستبعَد**: التوثيق الرسمي يسرد اللغات المدعومة صراحة (صينية، Devanagari، يابانية، كورية، لاتينية) — **العربية غير موجودة في القائمة إطلاقًا**. لا فائدة من محاولته.
2. **`syncfusion_flutter_pdf`** (`PdfTextExtractor`) — يعمل تقنيًا ويدعم العربية لاستخراج طبقة نص موجودة أصلًا (لا OCR للصور الممسوحة)، لكنه **يتطلّب ترخيص Syncfusion** (تجاري أو "Community License" مجاني بشروط: دخل الشركة/الفرد أقل من مليون دولار وأقل من 5 موظفين — هذا التطبيق الشخصي غير التجاري يُرجَّح أنه مؤهَّل، **لكن يحتاج تسجيل حساب وموافقة صريحة من إسماعيل قبل إضافته**، ليس قرارًا تقنيًا بحتًا).
3. **`ben-milanko/dart-pdf`** (`pdf_document`/`pdf_graphics`/`pdf_ocr_ondevice`، Apache-2.0، Dart خالص، بلا رigid native bindings) — كان المرشّح الأفضل معماريًا (نفس نمط استخراج+تخزين مؤقت لمرة واحدة الذي بنيناه بالفعل لصوت Piper)، لكن **مُستبعَد فعليًا بعد تجربة حقيقية**:
   - دعم العربية في نموذج OCR الافتراضي (`PP-OCRv5 mobile`، ~21 م.ب) **غير موثَّق إطلاقًا** في أي مصدر رسمي فحصته — قد يحتاج نموذج PaddleOCR "متعدد اللغات" منفصلًا تمامًا، غير مؤكَّد أن الحزمة تدعم استبداله.
   - **تعارض إصدارات حقيقي مانع**: `pdf_graphics` يحتاج `image ^4.9.1` ← يحتاج `archive ^4.0.9`، بينما `excel` الموجودة أصلًا في هذا التطبيق (لميزة أخرى غير مرتبطة) مثبَّتة على `archive ^3.6.1` ولم تُحدَّث منذ 2024-08-20 لتتبع هذا. **جرّبتُ الإضافة فعليًا** (`flutter pub get`) وفشل حل التبعيات بشكل قاطع — لا حل بتغيير رقم إصدار `pdf_document`/`pdf_graphics` وحده، المشكلة بنيوية عبر كل سلسلة الحزمة. رجعتُ عن الإضافة بالكامل (`pubspec.yaml`/`pubspec.lock` نظيفان، `flutter pub get` نجح بعد التراجع).

**تحديث (2026-09-17، بعد بحث رابع)**: وُجِد مسار رابع لم يكن مفحوصًا — **`pdfrx`** (MIT، مبني على PDFium نفسه الذي يستخدمه Chrome، 344 إعجابًا/443 ألف تنزيل شهريًا، ناشر موثَّق). جُرِّب فعليًا (لا افتراضًا): **بلا تعارض تبعيات** (لا يعتمد على `archive`/`image` إطلاقًا، خلافًا لعائلة `dart-pdf`)، `flutter pub get` نجح مباشرة. `PdfPage.loadText().fullText` API حقيقي تحقَّقتُ منه بقراءة الكود المصدَّري الفعلي المُنزَّل (لا تخمينًا) — يستخرج طبقة نص PDF **الموجودة أصلًا** بنجاح. **`PersonalLibraryTextSource` مبني فعليًا الآن** (`lib/services/tts/text_sources/personal_library_text_source.dart`، `flutter analyze` نظيف، بناء Android ناجح).

**الحد المتبقّي (تم سدّه 2026-09-19)**: `pdfrx` يستخرج طبقة نص **موجودة أصلًا** فقط — لا OCR. إسماعيل طلب صراحةً دعم الكتب المصوَّرة الآن، فبُني مسار OCR فعليًا:

### 7.2 OCR للكتب المصوَّرة — قناة أصلية مكتوبة يدويًا (2026-09-19)

جُرِّبت حزمتا Flutter الجاهزتان لـTesseract فعليًا (لا افتراضًا) في worktree `talib-audio`:

1. **`flutter_tesseract_ocr`** (pub.dev، 0.4.31) — `flutter pub get` نجح (لا تعارض تبعيات)، لكن **البناء الفعلي على Android فشل قطعيًا**: `A problem occurred configuring project ':flutter_tesseract_ocr' ... 'kotlin-android' plugin requires one of the Android Gradle plugins`. وحدة Gradle الخاصة بالحزمة لا تُطبِّق `com.android.library` بالشكل الذي يتوافق مع AGP 9.0.1 المُستخدَم في هذا المشروع (`android.newDsl=false` مُفعَّل أصلًا، ليست هذه المشكلة).
2. **`tesseract_ocr`** (pub.dev، arrrrny، 0.5.0، آخر نشر قبل 15 شهرًا) — **نفس الفشل بالضبط**، نفس رسالة الخطأ، نفس السبب الجذري (وحدة Gradle قديمة بنفس النمط).

كلتا الحزمتين **رُفِعت ثم أُزيلت بالكامل فعليًا** (`git checkout -- pubspec.yaml pubspec.lock`) بعد إثبات الفشل ببناء حقيقي — لا حزمة معطوبة متروكة في `pubspec.yaml`.

**القرار (بطلب إسماعيل الصريح بعد عرض الخيارات)**: بناء قناة Android أصلية بأنفسنا فوق مكتبة **Tesseract4Android** (`cz.adaptech.tesseract4android:tesseract4android:4.9.0`، Apache 2.0، تُنشَر عبر JitPack) مباشرة، بلا أي غلاف Flutter وسيط:

- `android/build.gradle.kts` — أُضيف مستودع JitPack.
- `android/app/build.gradle.kts` — تبعية `tesseract4android` مباشرة.
- `android/app/src/main/kotlin/.../MainActivity.kt` — `MethodChannel` باسم `talib_alilm/tesseract_ocr`، دالة `extractText` واحدة (مسار صورة + مسار بيانات + لغة) تُنفَّذ في خيط منفصل (`TessBaseAPI` غير آمن عبر الخيوط، وOCR بطيء).
- `lib/services/ocr/tesseract_ocr.dart` — يستخرج `assets/tessdata/ara.traineddata` (tessdata_fast، 1.4 م.ب) إلى مجلد ملفات التطبيق مرة واحدة فقط، ثم يستدعي القناة.
- `lib/services/tts/text_sources/personal_library_text_source.dart` — عند عدم وجود طبقة نص: يُرسَم `PdfPage.render()` بدقّة ≈300dpi، يُرمَّز BGRA8888 الخام إلى PNG عبر `dart:ui` مباشرة (بلا حزمة `image`، تفاديًا لتكرار تعارض `archive` السابق)، يُمرَّر لـOCR، والنتيجة تُخزَّن على القرص (`ocr_cache/`) فلا يتكرّر OCR لنفس الصفحة. `PersonalLibraryNoTextLayerException` استُبدلت بـ`PersonalLibraryOcrEmptyException` (تُرمى فقط إن فشل OCR فعليًا في استخراج أي نص، لا لكل صفحة مصوَّرة كالسابق).

**لم يُتحقَّق بعد ميدانيًا**: دقّة OCR الفعلية على عيّنة كتب "مكتبتي" الحقيقية، وزمن معالجة الصفحة الواحدة على جهاز إسماعيل — ينتظر اختبارًا حقيقيًا على كتاب مصوَّر فعلي.
