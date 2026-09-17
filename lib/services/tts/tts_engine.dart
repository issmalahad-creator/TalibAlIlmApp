/// محرك التوليد الصوتي — Piper (عبر sherpa_onnx) محليًا بالكامل.
///
/// المرحلة 1.2/1.3 من docs/audio-reader/TODO.md. توقيع الدالة يتضمّن
/// [voiceId] من اليوم الأول (مقعد اختيار القارئ، TEXT_SOURCE_ADAPTERS.md §5)
/// حتى مع صوت واحد متاح فقط.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'tts_voice_registry.dart';

class TtsEngine {
  TtsEngine._();
  static final TtsEngine instance = TtsEngine._();

  bool _bindingsInitialized = false;
  final Map<String, sherpa.OfflineTts> _loadedVoices = {};

  /// يُستخرَج مرة واحدة لكل صوت من حزمة الأصول (assets) إلى مجلد حقيقي على
  /// القرص — sherpa_onnx (FFI أصلي) يحتاج مسار ملف فعلي، لا يقرأ حزمة أصول
  /// Flutter مباشرة.
  Future<String> _ensureVoiceExtracted(TtsVoiceOption voice) async {
    final supportDir = await getApplicationSupportDirectory();
    final voiceDir = Directory(
      p.join(supportDir.path, 'tts_voices', voice.voiceId.replaceAll(':', '_')),
    );
    final espeakDir = Directory(p.join(voiceDir.path, 'espeak-ng-data'));

    final modelFile = File(p.join(voiceDir.path, 'model.onnx'));
    final tokensFile = File(p.join(voiceDir.path, 'tokens.txt'));

    // اكتمال سابق؟ لا إعادة استخراج (النموذج 63 ميجابايت، تكلفة نسخ حقيقية).
    if (await modelFile.exists() && await tokensFile.exists() && await espeakDir.exists()) {
      return voiceDir.path;
    }

    await voiceDir.create(recursive: true);
    await espeakDir.create(recursive: true);

    Future<void> extract(String assetPath, File dest) async {
      final data = await rootBundle.load(assetPath);
      await dest.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }

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

  Future<sherpa.OfflineTts> _loadVoice(String voiceId) async {
    final cached = _loadedVoices[voiceId];
    if (cached != null) return cached;

    if (!_bindingsInitialized) {
      sherpa.initBindings();
      _bindingsInitialized = true;
    }

    final voice = TtsVoiceRegistry.byId(voiceId);
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

    final tts = sherpa.OfflineTts(config);
    _loadedVoices[voiceId] = tts;
    return tts;
  }

  /// يولّد صوتًا من نص عربي، يُعيد بايتات WAV صالحة للتشغيل المباشر
  /// (عبر audioplayers الموجودة أصلًا في هذا المشروع — لا مشغّل جديد).
  Future<Uint8List> synthesize(
    String text, {
    required String voiceId,
    double speed = 1.0,
  }) async {
    final tts = await _loadVoice(voiceId);
    final audio = tts.generate(text: text, speed: speed);
    return _encodeWav(audio.samples, audio.sampleRate);
  }

  /// Float32 PCM (نطاق [-1, 1]) → WAV أحادي 16-bit — ترميز بسيط قياسي،
  /// لا مكتبة خارجية إضافية لهذه الخطوة الصغيرة.
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
}
