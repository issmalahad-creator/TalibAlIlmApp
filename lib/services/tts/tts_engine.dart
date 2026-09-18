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
import 'dart:typed_data';
import 'dart:ui' show RootIsolateToken;

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

  Future<SendPort> _ensureWorkerStarted() {
    final existing = _workerPort;
    if (existing != null) return Future.value(existing);
    return _workerStarting ??= _startWorker();
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
    final sendPort = await _ensureWorkerStarted();
    final replyPort = ReceivePort();
    sendPort.send(_SynthesizeRequest(text: text, voiceId: voiceId, speed: speed, replyPort: replyPort.sendPort));
    final result = await replyPort.first;
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
  const _SynthesizeRequest({required this.text, required this.voiceId, required this.speed, required this.replyPort});
  final String text;
  final String voiceId;
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

  await for (final message in commandPort) {
    if (message is! _SynthesizeRequest) continue;
    try {
      if (!bindingsInitialized) {
        sherpa.initBindings();
        bindingsInitialized = true;
      }

      var tts = loadedVoices[message.voiceId];
      if (tts == null) {
        final voice = TtsVoiceRegistry.byId(message.voiceId);
        final voiceDir = await _ensureVoiceExtracted(voice);
        final config = sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            vits: sherpa.OfflineTtsVitsModelConfig(
              model: p.join(voiceDir, 'model.onnx'),
              tokens: p.join(voiceDir, 'tokens.txt'),
              dataDir: p.join(voiceDir, 'espeak-ng-data'),
            ),
            numThreads: 2,
            debug: false,
          ),
        );
        tts = sherpa.OfflineTts(config);
        loadedVoices[message.voiceId] = tts;
      }

      final audio = tts.generate(text: message.text, speed: message.speed);
      final trimmed = _trimSilence(audio.samples, sampleRate: audio.sampleRate);
      final wav = _encodeWav(trimmed, audio.sampleRate);
      message.replyPort.send(wav);
    } catch (e) {
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
      return voiceDir.path;
    }
  }

  await voiceDir.create(recursive: true);
  await espeakDir.create(recursive: true);
  await versionFile.writeAsString(voice.assetVersion, flush: true);

  await extract(voice.modelAssetPath, modelFile);
  await extract(voice.tokensAssetPath, tokensFile);
  for (final fileName in voice.espeakDataFiles) {
    await extract(
      '${voice.espeakDataAssetDir}/$fileName',
      File(p.join(espeakDir.path, fileName)),
    );
  }

  return voiceDir.path;
}

/// يُشذِّب الصمت الزائد من بداية/نهاية العيّنات فقط (لا وسط الصوت — لا يمسّ
/// أي وقفة طبيعية داخل الكلام نفسه) مع إبقاء حافة صغيرة (~80 مللي ثانية)
/// بدل قصّ حاد قد يبتر أول/آخر صوت مسموع. الفائدة: تشغيل متتابع للفقرات
/// (auto-advance) بلا فجوات صامتة طويلة غير ضرورية بين فقرة وأخرى — النموذج
/// عادة يُنتِج صمتًا زائدًا في الطرفين، هذا يزيله بلا التأثير على المحتوى
/// المسموع فعليًا.
Float32List _trimSilence(Float32List samples, {double threshold = 0.01, int keepMs = 80, int sampleRate = 22050}) {
  if (samples.isEmpty) return samples;

  var start = 0;
  while (start < samples.length && samples[start].abs() < threshold) {
    start++;
  }
  var end = samples.length;
  while (end > start && samples[end - 1].abs() < threshold) {
    end--;
  }

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
