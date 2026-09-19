---
name: native-crash-diagnosis
description: >-
  Load when a Flutter/Dart app crashes the whole process with a native
  SIGSEGV/SIGABRT (logcat shows "Fatal signal 11" or similar, tid names like
  "DartWorker", the crash isn't a catchable Dart exception) coming from a
  third-party native (.so) dependency reached via FFI. Covers the real
  workflow that found an exact source-line root cause for such a crash
  without guessing: reading debuggerd's backtrace, symbolizing it against the
  actual shipped library with NDK tools (no rebuild needed for this first
  step), then — only if still unresolved — building a debug-symbol version
  of the native library from source and adding targeted logging to capture
  the exact runtime input that triggers it. Portable to any Android native
  crash investigation, not tied to this project's TTS engine specifically.
---

# تشخيص تعطّل أصلي (native crash) بلا تخمين — منهجية حقيقية نجحت فعليًا

**السياق الذي بُنيت منه هذه المهارة**: تعطّل SIGSEGV متكرّر وغير منتظم في محرّك TTS (sherpa_onnx)، استغرق محاولات تخمين عديدة فاشلة (تبديل عدد الخيوط، تبديل إصدار onnxruntime مرّتين، إعادة إنشاء الكائن/العزلة) قبل اتّباع هذه المنهجية — التي وجدت **موقعًا دقيقًا بالسطر** في كود مصدري لمكتبة طرف ثالث (`espeak-ng`) خلال أقل من ساعة، بلا أي تخمين إضافي.

**الدرس الأهم أولًا**: **لا تُخمِّن حلولًا (تبديل إصدارات، تعديل إعدادات) قبل قراءة التعطّل الفعلي نفسه.** كل تخمين غير مبني على دليل مباشر (fault address، backtrace) هو مقامرة بوقتك — التشخيص المباشر أسرع دائمًا من التخمين المتكرّر مهما بدا "منطقيًا".

---

## 1. اقرأ التعطّل الكامل من logcat أولًا — لا تكتفِ بسطر "Fatal signal"

سطر واحد مثل `Fatal signal 11 (SIGSEGV) ... fault addr 0x89` لا يكفي — التقط **الكتلة الكاملة** التي يطبعها `debuggerd`:

```bash
adb -s <device> logcat -c
adb -s <device> logcat -v time > log.txt &   # قبل إعادة إنتاج العطل
# أعِد إنتاج العطل فعليًا، ثم:
grep -A 60 "Native Crash TIME" log.txt
```

ابحث تحديدًا عن:
- `Cause: ...` — أحيانًا يخبرك النظام صراحة (مثال حقيقي: "null pointer dereference").
- قسم `backtrace:` — كل سطر فيه `#NN pc <عنوان> <مسار>!<مكتبة>.so (BuildId: ...)`.

**إن لم يظهر tombstone في `/data/tombstones/`** (شائع على أجهزة غير rooted بسبب قيود صلاحيات) — لا بأس، `debuggerd` غالبًا يطبع نفس المحتوى مباشرة لـlogcat تحت الوسم `F/DEBUG` حتى لو فشل حفظ الملف. ابحث هناك أولًا قبل افتراض عدم وجود بيانات.

## 2. رمّز الاستدعاءات (backtrace) بالمكتبة **الموجودة فعليًا** — بلا إعادة بناء

هذه الخطوة **لا تحتاج إعادة بناء أي شيء** — فقط أدوات NDK القياسية ضد نفس نسخة `.so` المُشغَّلة فعليًا (من `pub cache` أو مستخرَجة من الـAPK نفسه). الأداة الجاهزة هنا: `tool/diagnose_native_crash.py` (في هذا المشروع) — تنفّذ كل هذه الخطوة تلقائيًا. لإعادة استخدامها يدويًا:

```bash
NDK="$ANDROID_HOME/ndk/<version>"
SO="<مسار .so الفعلي المُستخدَم>"

# تحقّق أولًا أن BuildId يطابق ما في سجلّ التعطّل — إلزامي، لا نتيجة صحيحة بدونه
"$NDK/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-readelf.exe" -n "$SO" | grep "Build ID"

# رمّز كل عنوان من الـbacktrace
"$NDK/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-addr2line.exe" -e "$SO" -f -C -i "0x<العنوان>"

# فكّك التعليمات حول نقطة العطل لرؤية التعليمة المسؤولة فعليًا
"$NDK/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-objdump.exe" -d \
  --start-address=0x<العنوان-32> --stop-address=0x<العنوان+8> "$SO"
```

**في إصدار release عادي (مُجرَّد من الرموز/stripped)**: الدوال العامة المُصدَّرة (exported symbols) فقط سترمَّز بأسمائها، الدوال الداخلية/الثابتة (static) ستظهر `??`. هذا لا يزال مفيدًا — أحيانًا يكفي وحده (كما حدث هنا: رأينا التعطّل يقع بالكامل داخل مكتبة واحدة معيّنة، ولم يعبر أبدًا لمكتبة أخرى، وهذا وحده استبعد نظرية "onnxruntime هو السبب" قبل أي إعادة بناء).

**فخّ حقيقي وقعتُ فيه**: التعليمات المفكَّكة حول عنوان العطل قد تُظهَر تحت اسم دالة عامة **قريبة لكن غير ذات صلة إطلاقًا** (مثال حقيقي: ظهرت دالة "SpeakerDiarization" بعيدة تمامًا عن السياق الفعلي، لأنها ببساطة أقرب رمز عام *قبل* الدالة الثابتة الحقيقية في جدول الرموز). لا تثق باسم الدالة الظاهر في التفكيك وحده — فقط بموقع العنوان + رمز الدالة العامة الأقرب من `addr2line` نفسه.

## 3. إن لم يكفِ ذلك: ابنِ نسخة بـرموز تصحيح فعلية (RelWithDebInfo)، لا Debug كاملة

**لماذا `RelWithDebInfo` لا `Debug`**: تحافظ على نفس التحسينات (سرعة قريبة من الإنتاج) مع إضافة معلومات DWARF الكاملة — أسرع للبناء والتشغيل من Debug الكاملة، وتكفي تمامًا لـ`addr2line` لإعطاء اسم الدالة + الملف + رقم السطر الدقيقين.

خطوات عملية (Android عبر CMake، النمط الشائع لمكتبات C++‎ الأصلية):
1. **بيئة بناء Linux حقيقية إلزامية** — سكربتات البناء (bash) تفترض `make`/`wget` قياسيَّين؛ Git Bash على ويندوز ينقصه كلاهما عادة. WSL Ubuntu مثالي إن توفّر (تحقّق: `which make wget cmake unzip`).
2. **NDK بنكهة Linux منفصلة** — NDK المثبَّت عبر Android Studio على ويندوز ملفاته تنفيذية `.exe`، لا تعمل داخل WSL. نزّل نسخة Linux مطابقة الإصدار من `https://dl.google.com/android/repository/android-ndk-<version>-linux.zip`.
3. **فخّ CRLF حقيقي متكرّر**: أي مستودع Git يُستنسَخ عبر Git Bash على ويندوز (لا WSL) غالبًا يُحوَّل تلقائيًا لنهايات أسطر CRLF (`core.autocrlf`) — سكربتات bash تفشل بأخطاء غامضة (`set: invalid option`، `$'\r': command not found`) حين تُشغَّل من WSL. أصلحه فورًا قبل أي محاولة بناء:
   ```bash
   find /path/to/repo -name '*.sh' -exec sed -i 's/\r$//' {} \;
   ```
4. عدّل `CMAKE_BUILD_TYPE=Release` → `RelWithDebInfo` في سكربت البناء، واحذف/عطِّل خطوة `strip` النهائية (غالبًا `make install/strip` → `make install`).
5. بعد البناء: تحقّق فعليًا من وجود أقسام DWARF قبل المتابعة (لا تفترض):
   ```bash
   llvm-readelf.exe -S lib.so | grep -i debug   # يجب أن تظهر .debug_info، .debug_line، إلخ
   ```
6. **استبدل الملف مباشرة في pub cache** (أسرع للتجربة من نشر حزمة جديدة) — **يجب استبدال أي مكتبة أصلية أخرى تتشارك ABI معها بنفس الإصدار المطابق أيضًا** (درس حقيقي: استبدلتُ `libsherpa-onnx-c-api.so` وحدها أول مرة، فشل التطبيق بخطأ `dlopen: cannot locate symbol` لأن `libonnxruntime.so` المتبقّية من الحزمة القديمة لم تعد متوافقة ABI مع المكتبة الجديدة — استبدال جزئي لمكتبات مترابطة يكسر التحميل الديناميكي).
7. أعد تشغيل `flutter build apk --debug` (لا حاجة لأي تعديل Dart) وثبِّت على الجهاز.

## 4. إن كان السبب لا يزال غامضًا بعد الرموز: أضِف تسجيلًا (logging) داخل الكود المصدري نفسه

حين يُحدِّد الـbacktrace **دالة محدَّدة** كنقطة العطل لكن السبب الجذري يعتمد على **بيانات وقت التشغيل** (مثال حقيقي: تعطّل يعتمد على *أي كلمة* في النص المُدخَل تحديدًا، لا على عدد الاستدعاءات) — أضِف طباعة مباشرة قبل نقطة العطل:

```c
#ifdef __ANDROID__
#include <android/log.h>
#endif
...
#ifdef __ANDROID__
__android_log_print(ANDROID_LOG_ERROR, "MY_CRASH_DEBUG", "about to process: [%.80s]", value);
#endif
```

**إعادة البناء بعد هذا التعديل يمكن أن تكون Release عادية (لا RelWithDebInfo)** — الطباعة تعمل وقت التشغيل بصرف النظر عن وجود رموز تصحيح من عدمه، ومكتبة release أصغر بكثير (تجنّب مشكلة امتلاء مساحة الجهاز — رموز DWARF الكاملة قد تُضخِّم مكتبة من ~5 م.ب إلى ~115 م.ب+، وقد تُنتِج APK بحجم يقترب من 1 جيجابايت).

**بناء تراكمي (incremental) لا بناء كامل من جديد**: بعد أول بناء ناجح، تعديل ملف مصدر واحد وإعادة `make -j4` فقط (لا حذف مجلد البناء) يُعيد ترجمة الملف المتغيّر وما يعتمد عليه فقط — دقائق لا عشرات الدقائق.

## 5. قاعدة عامة: افصل "ماذا حدث" عن "لماذا حدث" — لا تخلطهما

- **"ماذا حدث"** = عنوان الفشل + الدالة + السطر — يُستخرَج بالتشخيص المباشر (القسمان 1-2)، لا تخمين إطلاقًا.
- **"لماذا حدث"** = تلف بيانات؟ خلل حقيقي في مكتبة الطرف الثالث؟ إدخال غير متوقَّع؟ — يحتاج قسمًا 3-4 فقط بعد استنفاد التشخيص المباشر، ويحتاج غالبًا **استبعاد الفرضيات بالمقارنة الفعلية** (مثال حقيقي: قارنّا hash ملفات البيانات المُستخدَمة ضد المصدر الرسمي — تطابق تام، فاستبعدنا فرضية "بيانات غير متوافقة" بدليل قاطع بدل افتراض).

---

## نقل هذه المهارة لمشروع آخر

انسخ هذا المجلد (`native-crash-diagnosis/`) إلى `.claude/skills/` في أي مشروع Flutter/Android آخر يستخدم مكتبات أصلية عبر FFI — المنهجية عامة تمامًا (لا خصوصية لـsherpa_onnx)، فقط استبدل مسارات NDK/أسماء المكتبات بما يخصّ مشروعك. الأداة `tool/diagnose_native_crash.py` نفسها قابلة للتعميم بتعديل `DEFAULT_SO` فقط.
