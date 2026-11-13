import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/tts/arabic_diacritizer.dart';
import 'package:talib_alilm_app/services/tts/ort_ffi.dart';

/// The diacritizer before the reading voice (docs/audio-reader/MY_VOICE_PLAN_2026-11-13.md §10).
///
/// The model test runs where the model (tool/fetch_tashkeel_model.sh) and an
/// onnxruntime library are present — on this machine, the Windows build that
/// sherpa_onnx_windows ships; it is skipped elsewhere, the pipeline tests never are.
void main() {
  const modelPath = 'assets/tts/packs/tashkeel-ichkil-v0.3.0.onnx';
  const configPath = 'assets/tts/tashkeel/ichkil_config.json';

  String? ortLibrary() {
    final home = Platform.environment['LOCALAPPDATA'] ?? '';
    final pubCache = Platform.environment['PUB_CACHE'] ?? '$home/Pub/Cache';
    final hosted = Directory('$pubCache/hosted/pub.dev');
    if (!hosted.existsSync()) return null;
    for (final d in hosted.listSync().whereType<Directory>()) {
      final name = d.path.split(RegExp(r'[\\/]')).last;
      if (Platform.isWindows && name.startsWith('sherpa_onnx_windows-')) {
        final f = File('${d.path}/windows/onnxruntime.dll');
        if (f.existsSync()) return f.path;
      }
      if (Platform.isLinux && name.startsWith('sherpa_onnx_linux-')) {
        final f = File('${d.path}/linux/x64/libonnxruntime.so');
        if (f.existsSync()) return f.path;
      }
    }
    return null;
  }

  group('text pipeline (mirror of ichkil pipeline.py)', () {
    test('normalize: composed hamza/madda, alef wasla, nbsp, zero-width, spaces', () {
      expect(normalizeForTashkeel('ٱلْحَمْدُ'), 'الْحَمْدُ');
      expect(normalizeForTashkeel('أ'), 'أ');
      expect(normalizeForTashkeel('الكتاب   على الطاولة​.'), 'الكتاب على الطاولة.');
    });

    test('strip removes every mark and tatweel but keeps letters and punctuation', () {
      expect(stripForTashkeel('وَالرَّاجِحُ - وَاللَّهُ أَعْلَمُ -'), 'والراجح - والله أعلم -');
      expect(stripForTashkeel('كـتـاب'), 'كتاب');
    });

    test('attach puts the argmax label on letters only', () {
      // «بَب ب»: fatha, shadda+kasra, (space = non-letter), sukun
      final logits = Float32List(4 * 16);
      logits[0 * 16 + 2] = 5; // fatha
      logits[1 * 16 + 9] = 5; // shadda + kasra
      logits[2 * 16 + 0] = 5; // space
      logits[3 * 16 + 5] = 5; // sukun
      expect(attachLabels('بب ب', logits, 16), 'بَبِّ بْ');
    });

    test('voweled text is recognised; long text splits at sentence ends then spaces', () {
      expect(voweledShare('وَالرَّاجِحُ هُوَ'), greaterThan(0.6));
      expect(voweledShare('والراجح هو'), 0);
      final long = List.filled(120, 'كلمة').join(' ');
      final pieces = splitForTashkeel('جملة أولى. $long', maxLen: 100);
      expect(pieces.first, 'جملة أولى.');
      expect(pieces.skip(1).every((p) => p.length <= 100), isTrue);
      expect(pieces.skip(1).join(' '), long);
    });
  });

  test('the bound OrtApi indices drive the real library: identical output to ichkil in Python', () {
    final lib = ortLibrary();
    if (lib == null || !File(modelPath).existsSync()) {
      markTestSkipped('needs $modelPath (tool/fetch_tashkeel_model.sh) and an onnxruntime library');
      return;
    }
    final rt = OrtRuntime.open(libraryPath: lib);
    expect(rt, isNotNull, reason: 'OrtGetApiBase / GetApi(16) from $lib');
    final d = ArabicDiacritizer.load(
      model: File(modelPath).readAsBytesSync(),
      configJson: File(configPath).readAsStringSync(),
      runtime: rt,
    )!;
    final golden = jsonDecode(File('test/fixtures/ichkil_golden.json').readAsStringSync()) as Map<String, dynamic>;
    var n = 0;
    for (final row in (golden['rows'] as List).cast<Map<String, dynamic>>()) {
      expect(d.diacritizePiece(row['in'] as String), row['out'], reason: row['in'] as String);
      n++;
    }
    expect(n, greaterThan(20));
    // already-voweled text keeps the book's own marks
    const madarij = 'وَالتَّحْقِيقُ أَنَّ الرُّكُوبَ أَفْضَلُ';
    expect(d.diacritize(madarij), madarij);
    d.dispose();
    rt!.dispose();
  });
}
