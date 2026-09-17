// تحقّق مباشر من الطبقة 1 (TtsEngine) على سطح مكتب ويندوز — بلا Android،
// بلا محاكي. يشير مباشرة لملفات النموذج على القرص (تخطّي استخراج الأصول
// الخاص بـFlutter، غير المتاح خارج تطبيق Flutter فعلي).
import 'dart:io';
import 'dart:typed_data';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

void main() {
  sherpa.initBindings();

  const assetsDir = 'assets/tts';
  final config = sherpa.OfflineTtsConfig(
    model: sherpa.OfflineTtsModelConfig(
      vits: sherpa.OfflineTtsVitsModelConfig(
        model: '$assetsDir/ar_JO-kareem-medium.onnx',
        tokens: '$assetsDir/tokens.txt',
        dataDir: '$assetsDir/espeak-ng-data',
      ),
      numThreads: 2,
      debug: true,
    ),
  );

  final tts = sherpa.OfflineTts(config);
  const text =
      'هذا اختبار حقيقي للطبقة الأولى من القارئ الصوتي، يعمل الآن من داخل محرك التطبيق نفسه عبر مكتبة شيربا أونكس، لا من برنامج بايثون خارجي.';
  final audio = tts.generate(text: text, speed: 1.0);

  final wav = _encodeWav(audio.samples, audio.sampleRate);
  File('verify_output.wav').writeAsBytesSync(wav);
  stdout.writeln('OK: wrote verify_output.wav (${wav.length} bytes, sampleRate=${audio.sampleRate}, samples=${audio.samples.length})');
}

Uint8List _encodeWav(Float32List samples, int sampleRate) {
  final pcm = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    final c = samples[i].clamp(-1.0, 1.0);
    pcm[i] = (c * 32767).round();
  }
  final dataBytes = pcm.buffer.asUint8List();
  final byteRate = sampleRate * 2;
  final header = BytesBuilder();
  void ws(String s) => header.add(s.codeUnits);
  void wu32(int v) => header.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
  void wu16(int v) => header.add([v & 0xff, (v >> 8) & 0xff]);
  ws('RIFF');
  wu32(36 + dataBytes.length);
  ws('WAVE');
  ws('fmt ');
  wu32(16);
  wu16(1);
  wu16(1);
  wu32(sampleRate);
  wu32(byteRate);
  wu16(2);
  wu16(16);
  ws('data');
  wu32(dataBytes.length);
  final out = BytesBuilder();
  out.add(header.toBytes());
  out.add(dataBytes);
  return out.toBytes();
}
