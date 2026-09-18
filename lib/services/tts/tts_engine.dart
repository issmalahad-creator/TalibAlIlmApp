/// محرك التوليد الصوتي — Piper (عبر sherpa_onnx) محليًا بالكامل.
///
/// المرحلة 1.2/1.3 من docs/audio-reader/TODO.md. توقيع الدالة يتضمّن
/// [voiceId] من اليوم الأول (مقعد اختيار القارئ، TEXT_SOURCE_ADAPTERS.md §5)
/// حتى مع صوت واحد متاح فقط.
///
/// **معماري مهم (2026-09-18)**: `tts.generate()` من sherpa_onnx استدعاء FFI
/// متزامن (blocking) بالكامل — لا isolate ولا async حقيقي داخل الحزمة نفسها
/// (تحقّقتُ من كود الحزمة مباشرة). استدعاؤه من العزلة الرئيسية (UI isolate)
/// يُجمِّد الواجهة بالكامل طوال مدة التوليد — هذا بالضبط سبب حوارات "isn't
/// responding" (ANR) المُلاحَظة فعليًا على المحاكي والجهاز الحقيقي، وما تلاها
/// من إغلاق النظام للتطبيق كغير مستجيب. الحل هنا: عزلة خلفية واحدة دائمة
/// (`Isolate`) يعيش فيها تحميل النموذج والتوليد بالكامل، لا تُنشَأ من جديد
/// لكل استدعاء (تفاديًا لإعادة تحميل نموذج 63 م.ب في كل مرة).
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show RootIsolateToken;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show BackgroundIsolateBinaryMessenger, rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'tts_voice_registry.dart';

class TtsEngine {
  TtsEngine._();
  static final TtsEngine instance = TtsEngine._();

  Isolate? _worker;
  SendPort? _workerPort;
  Future<SendPort>? _workerStarting;

  Future<SendPort> _ensureWorkerStarted() async {
    final existing = _workerPort;
    if (existing != null) return existing;
    // **خلل حقيقي وُجِد وأُصلِح (2026-09-18)**: `??=` وحده يُخزِّن Future
    // فاشلًا للأبد إن فشل بدء العزلة ولو لمرة واحدة (سبب عابر: ضغط ذاكرة
    // لحظي، إلخ) — كل استدعاء `synthesize` تالٍ كان يعيد نفس الفشل المرفوض
    // فورًا بلا أي محاولة جديدة، مما يبدو "توقّف الصوت نهائيًا" لمستخدم لا
    // يعرف السبب. الآن: امسح الحالة عند الفشل، حتى تُعاد المحاولة فعليًا
    // في الاستدعاء التالي.
    try {
      return await (_workerStarting ??= _startWorker());
    } catch (e) {
      _workerStarting = null;
      _worker = null;
      _workerPort = null;
      rethrow;
    }
  }

  Future<SendPort> _startWorker() async {
    final rootToken = RootIsolateToken.instance;
    if (rootToken == null) {
      throw StateError('RootIsolateToken غير متاح — يجب استدعاء هذا بعد WidgetsFlutterBinding.ensureInitialized().');
    }
    final readyPort = ReceivePort();
    _worker = await Isolate.spawn(_ttsIsolateEntry, _TtsIsolateStart(rootToken, readyPort.sendPort));
    final sendPort = await readyPort.first as SendPort;
    readyPort.close();
    _workerPort = sendPort;
    return sendPort;
  }

  /// يولّد صوتًا من نص عربي، يُعيد بايتات WAV صالحة للتشغيل المباشر
  /// (عبر audioplayers الموجودة أصلًا في هذا المشروع — لا مشغّل جديد).
  /// التنفيذ الفعلي (تحميل النموذج + التوليد) يحدث بالكامل داخل العزلة
  /// الخلفية — لا يُجمِّد واجهة المستخدم مهما طالت مدة التوليد.
  Future<Uint8List> synthesize(
    String text, {
    required String voiceId,
    double speed = 1.0,
  }) async {
    // **خلل جذري حقيقي وُجِد بالسجلّ الفعلي على الجهاز (2026-09-18)**: كل
    // محاولة كانت تفشل بالضبط عند `rootBundle.load()` داخل العزلة الخلفية
    // برسالة "Binding has not yet been initialized" — قناة تحميل الأصول
    // (rootBundle) لا تعمل بشكل موثوق من عزلة خلفية حتى مع
    // `BackgroundIsolateBinaryMessenger.ensureInitialized` (ذاك يُهيِّئ قنوات
    // المكوّنات الإضافية العادية فقط، لا قناة الأصول الخاصة). الحل: استخراج
    // الصوت هنا في العزلة الرئيسية (حيث rootBundle يعمل بأمان تام) *قبل*
    // إرسال الطلب — العزلة الخلفية تستقبل مسار مجلد جاهز فقط، لا تلمس
    // rootBundle إطلاقًا.
    final voice = TtsVoiceRegistry.byId(voiceId);
    final voiceDir = await _ensureVoiceExtracted(voice);

    final sendPort = await _ensureWorkerStarted();
    final replyPort = ReceivePort();
    sendPort.send(
      _SynthesizeRequest(text: text, voiceId: voiceId, voiceDir: voiceDir, speed: speed, replyPort: replyPort.sendPort),
    );

    Object? result;
    try {
      // مهلة زمنية: إرسال رسالة لعزلة ماتت (تعطّل أصلي داخلها، مثلًا) لا
      // يُطلِق استثناءً من جهة الإرسال — الرد لا يصل أبدًا، فينتظر الطلب
      // للأبد بلا أي خطأ ظاهر بدل هذه المهلة. 45 ثانية كافية لأطول فقرة
      // متوقَّعة (بعد §4 تقسيم الفقرات الطويلة) مع هامش واسع.
      result = await replyPort.first.timeout(const Duration(seconds: 45));
    } catch (e) {
      replyPort.close();
      // العزلة قد تكون ماتت فعليًا — أعِد تعيين الحالة كي تُبنى عزلة جديدة
      // في المحاولة التالية بدل البقاء عالقة على منفذ لعزلة ميتة للأبد.
      _workerStarting = null;
      _worker = null;
      _workerPort = null;
      rethrow;
    }
    replyPort.close();

    if (result is _SynthesizeError) {
      throw Exception(result.message);
    }
    return result as Uint8List;
  }

  /// إنهاء العزلة الخلفية صراحةً (تحرير النموذج المحمَّل من الذاكرة) — عند
  /// ضغط ذاكرة حقيقي أو إغلاق التطبيق. استدعاء [synthesize] لاحقًا يعيد
  /// إنشاء عزلة جديدة تلقائيًا (تحميل النموذج من جديد، تكلفة لمرة واحدة).
  void dispose() {
    _worker?.kill(priority: Isolate.immediate);
    _worker = null;
    _workerPort = null;
    _workerStarting = null;
  }
}

/// معطيات بدء العزلة — record بسيط (Dart 3)، قابل للنقل بين العزلات.
class _TtsIsolateStart {
  const _TtsIsolateStart(this.rootToken, this.readyPort);
  final RootIsolateToken rootToken;
  final SendPort readyPort;
}

class _SynthesizeRequest {
  const _SynthesizeRequest({
    required this.text,
    required this.voiceId,
    required this.voiceDir,
    required this.speed,
    required this.replyPort,
  });
  final String text;
  final String voiceId;
  final String voiceDir;
  final double speed;
  final SendPort replyPort;
}

class _SynthesizeError {
  const _SynthesizeError(this.message);
  final String message;
}

/// نقطة دخول العزلة الخلفية — كل ما بعد `BackgroundIsolateBinaryMessenger`
/// يعمل هنا بمعزل كامل عن عزلة الواجهة. الحالة (النماذج المحمَّلة) محلية
/// لهذه الدالة، لا حقول صنف (العزلات لا تتشارك الذاكرة).
void _ttsIsolateEntry(_TtsIsolateStart start) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(start.rootToken);

  final commandPort = ReceivePort();
  start.readyPort.send(commandPort.sendPort);

  var bindingsInitialized = false;
  final loadedVoices = <String, sherpa.OfflineTts>{};
  final generationsSinceLoad = <String, int>{};
  // **خلل حقيقي وُجِد على جهاز حقيقي (2026-09-18)**: العملية كاملة انهارت
  // بتعطّل أصلي (SIGSEGV، لا استثناء Dart قابل للالتقاط) بعد سلسلة طويلة من
  // استدعاءات generate() المتتالية الناجحة على نفس جلسة OfflineTts الأصلية
  // — لا تسريب مؤكَّد من ناحية Dart (كل مخزَّن مؤقَّت أصلي يُحرَّر فور كل
  // استدعاء عبر tts.dart نفسها)، لكن مخزَّن ONNX Runtime الأصلي (arena)
  // معروف بأنه ينمو عبر الاستدعاءات المتتالية ولا يتقلَّص بينها ضمن نفس
  // الجلسة. لا يوجد tombstone يؤكّد السبب الدقيق (النظام نفسه كان
  // مُحمَّلًا وقتها). إجراء احترازي معقول: إعادة إنشاء جلسة OfflineTts من
  // الصفر دوريًا بدل تركها تتراكم للأبد — يحدّ من أسوأ احتمال نمو ذاكرة
  // أصلية غير محدود خلال جلسة استماع طويلة.
  const kMaxGenerationsPerSession = 25;

  await for (final message in commandPort) {
    if (message is! _SynthesizeRequest) continue;
    // تشخيص مؤقّت (2026-09-18) — الخلل السابق: كل استثناء هنا كان يُلتقَط
    // ويُرسَل كبيانات (_SynthesizeError) بلا أي طباعة، فلا يظهر إطلاقًا في
    // logcat مهما بحثنا (هذا بالضبط سبب عدم وجود أي أثر عبر 5 محاولات
    // التقاط سابقة). الآن: كل مرحلة مطبوعة صراحة عبر debugPrint (وسم
    // "flutter" في logcat).
    debugPrint('[TTS] طلب: voiceId=${message.voiceId} طول النص=${message.text.length}');
    try {
      if (!bindingsInitialized) {
        sherpa.initBindings();
        bindingsInitialized = true;
        debugPrint('[TTS] initBindings تم');
      }

      var tts = loadedVoices[message.voiceId];
      if (tts == null) {
        // الاستخراج (rootBundle) يحدث الآن في العزلة الرئيسية قبل الإرسال —
        // هذه العزلة تستقبل مسارًا جاهزًا فقط (message.voiceDir).
        final voiceDir = message.voiceDir;
        debugPrint('[TTS] بناء صوت من مسار جاهز: $voiceDir');
        final config = sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            vits: sherpa.OfflineTtsVitsModelConfig(
              model: p.join(voiceDir, 'model.onnx'),
              tokens: p.join(voiceDir, 'tokens.txt'),
              dataDir: p.join(voiceDir, 'espeak-ng-data'),
            ),
            // **خلل حقيقي وُجِد على جهاز حقيقي (2026-09-18)**: تعطّل أصلي
            // SIGSEGV متكرّر (fault addr صغير جدًا — إشارة نموذجية لمؤشّر
            // فارغ تقريبًا) في خيط "DartWorker" تحديدًا — ليس خيط تنفيذ
            // العزلة نفسه. `numThreads: 2` يجعل ONNX Runtime ينشئ خيوطه
            // الأصلية الخاصة للاستدلال المتوازي؛ تعطّل ضمن خيط Dart داخلي
            // مع سباق زمني (أحيانًا فور أول generate()، أحيانًا بعد عشرات
            // النداءات الناجحة — عدم انتظام نموذجي لسباق تزامن لا لتراكم
            // ذاكرة تدريجي) يوافق تمامًا نمط سباق تعدّد خيوط أصلي حقيقي.
            // خيط واحد فقط يُزيل هذا النوع من الأخطاء بالكامل عند التكلفة
            // (تأخّر توليد طفيف، مقبول لفقرات قصيرة).
            numThreads: 1,
            debug: false,
          ),
        );
        debugPrint('[TTS] بناء OfflineTts من config...');
        tts = sherpa.OfflineTts(config);
        debugPrint('[TTS] OfflineTts جاهز');
        loadedVoices[message.voiceId] = tts;
        generationsSinceLoad[message.voiceId] = 0;
      }

      debugPrint('[TTS] استدعاء generate()...');
      final audio = tts.generate(text: message.text, speed: message.speed);
      debugPrint('[TTS] generate() انتهى: samples=${audio.samples.length} sampleRate=${audio.sampleRate}');
      final trimmed = _trimSilence(audio.samples, sampleRate: audio.sampleRate);
      final wav = _encodeWav(trimmed, audio.sampleRate);
      message.replyPort.send(wav);
      debugPrint('[TTS] نجح، أُرسِلت ${wav.length} بايت');

      final count = (generationsSinceLoad[message.voiceId] ?? 0) + 1;
      if (count >= kMaxGenerationsPerSession) {
        debugPrint('[TTS] إعادة تدوير جلسة ${message.voiceId} وقائيًا بعد $count توليدة');
        tts.free();
        loadedVoices.remove(message.voiceId);
        generationsSinceLoad.remove(message.voiceId);
      } else {
        generationsSinceLoad[message.voiceId] = count;
      }
    } catch (e, st) {
      debugPrint('[TTS] فشل فعلي: $e\n$st');
      message.replyPort.send(_SynthesizeError(e.toString()));
    }
  }
}

/// يُستخرَج مرة واحدة لكل صوت من حزمة الأصول (assets) إلى مجلد حقيقي على
/// القرص — sherpa_onnx (FFI أصلي) يحتاج مسار ملف فعلي، لا يقرأ حزمة أصول
/// Flutter مباشرة. يعمل داخل العزلة الخلفية (BackgroundIsolateBinaryMessenger
/// مُهيَّأ مسبقًا يجعل rootBundle/path_provider يعملان هنا بأمان).
Future<String> _ensureVoiceExtracted(TtsVoiceOption voice) async {
  final supportDir = await getApplicationSupportDirectory();
  final voiceDir = Directory(
    p.join(supportDir.path, 'tts_voices', voice.voiceId.replaceAll(':', '_')),
  );
  final espeakDir = Directory(p.join(voiceDir.path, 'espeak-ng-data'));

  final modelFile = File(p.join(voiceDir.path, 'model.onnx'));
  final tokensFile = File(p.join(voiceDir.path, 'tokens.txt'));
  final versionFile = File(p.join(voiceDir.path, '.asset_version'));

  Future<void> extract(String assetPath, File dest) async {
    final data = await rootBundle.load(assetPath);
    await dest.parent.create(recursive: true);
    await dest.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  }

  // اكتمال سابق **ومطابق فعليًا للأصل الحالي**؟ لا إعادة استخراج (النموذج
  // 63 ميجابايت، تكلفة نسخ حقيقية). التحقّق عبر ملف نسخة صغير
  // (`voice.assetVersion`، سلسلة يدوية يرفعها المطوّر عند تغيير النموذج) —
  // لا تحميل الأصل الكامل (63 م.ب) في الذاكرة فقط لمقارنة حجمه. فحص الوجود
  // وحده غير كافٍ: تحديث `voiceId` لنفس الملف (تصحيح نموذج، إلخ) بعد تثبيت
  // سابق يترك نسخة قديمة على القرص بلا هذا الفحص، وهذا بالضبط ما سبَّب
  // عطلًا حقيقيًا هنا (نموذج مُصحَّح جديد يُبنى في الحزمة، لكن النسخة
  // القديمة المُستخرَجة سابقًا على الجهاز تبقى مُستخدَمة صامتًا).
  if (await modelFile.exists() && await tokensFile.exists() && await espeakDir.exists() && await versionFile.exists()) {
    final storedVersion = await versionFile.readAsString();
    if (storedVersion == voice.assetVersion) {
      debugPrint('[TTS] استخراج سابق مطابق موجود ($storedVersion) — لا إعادة استخراج');
      return voiceDir.path;
    }
    debugPrint('[TTS] نسخة قديمة على القرص ($storedVersion) != ${voice.assetVersion} — إعادة استخراج');
  } else {
    debugPrint('[TTS] لا استخراج سابق — استخراج أول مرة إلى ${voiceDir.path}');
  }

  await voiceDir.create(recursive: true);
  await espeakDir.create(recursive: true);
  await versionFile.writeAsString(voice.assetVersion, flush: true);

  debugPrint('[TTS] استخراج model.onnx من ${voice.modelAssetPath}...');
  await extract(voice.modelAssetPath, modelFile);
  debugPrint('[TTS] استخراج tokens.txt من ${voice.tokensAssetPath}...');
  await extract(voice.tokensAssetPath, tokensFile);
  for (final fileName in voice.espeakDataFiles) {
    debugPrint('[TTS] استخراج $fileName...');
    await extract(
      '${voice.espeakDataAssetDir}/$fileName',
      File(p.join(espeakDir.path, fileName)),
    );
  }
  debugPrint('[TTS] استخراج مكتمل: ${voiceDir.path}');

  return voiceDir.path;
}

/// يُشذِّب الصمت الزائد من بداية/نهاية العيّنات فقط (لا وسط الصوت — لا يمسّ
/// أي وقفة طبيعية داخل الكلام نفسه) مع إبقاء حافة صغيرة (~80 مللي ثانية)
/// بدل قصّ حاد قد يبتر أول/آخر صوت مسموع. الفائدة: تشغيل متتابع للفقرات
/// (auto-advance) بلا فجوات صامتة طويلة غير ضرورية بين فقرة وأخرى — النموذج
/// عادة يُنتِج صمتًا زائدًا في الطرفين، هذا يزيله بلا التأثير على المحتوى
/// المسموع فعليًا.
///
/// **تحسين حقيقي (2026-09-18)، مبني على بحث فعلي**: الإصدار السابق كان
/// يفحص **عيّنة واحدة مفردة** لتحديد بداية/نهاية الصمت — هذا يخاطر بقصّ
/// داخل بداية حرف ساكن هادئ فعليًا (كـ"ه"، "ح") إن صادف أن عيّنته الأولى
/// وحدها تحت الحد، رغم أن الحرف نفسه بدأ فعلًا. الممارسة الموثَّقة (مصدر:
/// `AudioProcessor` في مكتبة Coqui TTS، ونتائج بحث مستقلّة عن قصّ صمت TTS)
/// هي استخدام **متوسط طاقة RMS على نافذة قصيرة (20-30ms)** بدل عيّنة مفردة
/// — يميّز الصمت الحقيقي عن بداية صوت هادئ لكنه فعلي بثبات أكبر.
Float32List _trimSilence(Float32List samples, {double threshold = 0.01, int keepMs = 80, int sampleRate = 22050}) {
  if (samples.isEmpty) return samples;

  const windowMs = 20;
  final windowSize = (windowMs / 1000 * sampleRate).round().clamp(1, samples.length);

  double windowRms(int windowStart) {
    final windowEnd = (windowStart + windowSize).clamp(0, samples.length);
    if (windowEnd <= windowStart) return 0;
    var sumSquares = 0.0;
    for (var i = windowStart; i < windowEnd; i++) {
      sumSquares += samples[i] * samples[i];
    }
    return math.sqrt(sumSquares / (windowEnd - windowStart));
  }

  var start = 0;
  while (start < samples.length && windowRms(start) < threshold) {
    start += windowSize;
  }
  start = start.clamp(0, samples.length);

  var end = samples.length;
  while (end > start && windowRms((end - windowSize).clamp(0, samples.length)) < threshold) {
    end -= windowSize;
  }
  end = end.clamp(start, samples.length);

  final keepSamples = (keepMs / 1000 * sampleRate).round();
  final trimmedStart = (start - keepSamples).clamp(0, samples.length);
  final trimmedEnd = (end + keepSamples).clamp(0, samples.length);

  // الصوت صامت بالكامل (نادر، فقرة فارغة فعليًا بعد التشكيل) — أرجعه كما هو
  // بدل قائمة فارغة قد تُربِك تشغيل الملف.
  if (trimmedStart >= trimmedEnd) return samples;

  return Float32List.sublistView(samples, trimmedStart, trimmedEnd);
}

/// Float32 PCM (نطاق [-1, 1]) → WAV أحادي 16-bit — ترميز بسيط قياسي، لا
/// مكتبة خارجية إضافية لهذه الخطوة الصغيرة.
Uint8List _encodeWav(Float32List samples, int sampleRate) {
  final pcm = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    pcm[i] = (clamped * 32767).round();
  }

  final dataBytes = pcm.buffer.asUint8List();
  final byteRate = sampleRate * 2; // mono, 16-bit
  final header = BytesBuilder();

  void writeString(String s) => header.add(s.codeUnits);
  void writeUint32(int v) => header.add([
    v & 0xff,
    (v >> 8) & 0xff,
    (v >> 16) & 0xff,
    (v >> 24) & 0xff,
  ]);
  void writeUint16(int v) => header.add([v & 0xff, (v >> 8) & 0xff]);

  writeString('RIFF');
  writeUint32(36 + dataBytes.length);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);
  writeUint16(1); // PCM
  writeUint16(1); // mono
  writeUint32(sampleRate);
  writeUint32(byteRate);
  writeUint16(2); // block align
  writeUint16(16); // bits per sample
  writeString('data');
  writeUint32(dataBytes.length);

  final result = BytesBuilder();
  result.add(header.toBytes());
  result.add(dataBytes);
  return result.toBytes();
}
