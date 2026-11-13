// Arabic diacritization (tashkeel) before the reading voice speaks — so
// espeak-ng is given vowels instead of guessing them, for every voice
// (Kareem today, Ismail's own voice once trained). Study and measurements:
// docs/audio-reader/MY_VOICE_PLAN_2026-11-13.md §10.
//
// Model: ichkil v0.3.0 (MIT, huggingface.co/ichkil/ichkil, pinned + sha256 in
// tool/fetch_tashkeel_model.sh), 22 MB ONNX, run through `ort_ffi.dart` on the
// onnxruntime sherpa_onnx already ships. The text pipeline below mirrors
// ichkil's own `pipeline.py` exactly (normalize → strip → encode → argmax →
// attach); test/arabic_diacritizer_test.dart holds it to the Python output.
import 'dart:convert';
import 'dart:typed_data';

import 'ort_ffi.dart';

/// label id → diacritic combination (ichkil `LABEL_TO_COMBO`).
const kIchkilCombos = <String>[
  '', '', // 0 non-letter, 1 no diacritic
  'َ', 'ُ', 'ِ', 'ْ', 'ّ', // fatha damma kasra sukun shadda
  'َّ', 'ُّ', 'ِّ', // shadda + vowel
  'ً', 'ٌ', 'ٍ', // tanwin
  'ًّ', 'ٌّ', 'ٍّ', // shadda + tanwin
];

final _letter = RegExp('[ء-غف-ي]');
final _diacritic = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭ]');
final _harakat = RegExp('[ً-ْ]');
final _zeroWidth = RegExp('[​-‏﻿]');
final _ws = RegExp(r'\s+');

bool isArabicLetter(String ch) => ch.length == 1 && _letter.hasMatch(ch);

/// The Arabic part of Unicode NFC that matters here (Dart has no NFC):
/// a base letter followed by a combining maddah/hamza becomes the composed letter.
String _composeArabic(String s) => s
    .replaceAll('آ', 'آ')
    .replaceAll('أ', 'أ')
    .replaceAll('إ', 'إ')
    .replaceAll('ؤ', 'ؤ')
    .replaceAll('ئ', 'ئ');

/// ichkil `normalize_text`.
String normalizeForTashkeel(String text) {
  var t = _composeArabic(text);
  t = t
      .replaceAll('ٱ', 'ا')
      .replaceAll('ی', 'ي')
      .replaceAll('ک', 'ك')
      .replaceAll('ہ', 'ه')
      .replaceAll(' ', ' ');
  t = t.replaceAll(_zeroWidth, '');
  return t.replaceAll(_ws, ' ').trim();
}

/// ichkil `strip_diacritics`.
String stripForTashkeel(String text) => normalizeForTashkeel(text).replaceAll(_diacritic, '').replaceAll('ـ', '');

/// Share of Arabic letters already carrying a haraka/shadda/tanwin/sukun.
double voweledShare(String text) {
  var letters = 0;
  for (final r in text.runes) {
    if (isArabicLetter(String.fromCharCode(r))) letters++;
  }
  if (letters == 0) return 0;
  return _harakat.allMatches(text).length / letters;
}

/// ichkil `decode`: attach the argmax label of each letter.
String attachLabels(String base, Float32List logits, int numLabels) {
  final out = StringBuffer();
  var i = 0;
  for (final r in base.runes) {
    final ch = String.fromCharCode(r);
    out.write(ch);
    if (isArabicLetter(ch)) {
      final off = i * numLabels;
      var best = 0;
      var bestV = logits[off];
      for (var k = 1; k < numLabels; k++) {
        if (logits[off + k] > bestV) {
          bestV = logits[off + k];
          best = k;
        }
      }
      out.write(kIchkilCombos[best]);
    }
    i++;
  }
  return out.toString();
}

/// Splits a long text into pieces the model accepts (it was trained up to
/// 1024 characters), at sentence ends, else at spaces.
List<String> splitForTashkeel(String text, {int maxLen = 600}) {
  final pieces = <String>[];
  for (final sentence in text.split(RegExp(r'(?<=[.!؟?؛\n])\s+'))) {
    var rest = sentence;
    while (rest.length > maxLen) {
      var cut = rest.lastIndexOf(' ', maxLen);
      if (cut <= 0) cut = maxLen;
      pieces.add(rest.substring(0, cut));
      rest = rest.substring(cut).trimLeft();
    }
    if (rest.isNotEmpty) pieces.add(rest);
  }
  return pieces;
}

class ArabicDiacritizer {
  ArabicDiacritizer._(this._session, this._sym2id, this._unk, this._numLabels);

  final OrtSession _session;
  final Map<String, int> _sym2id;
  final int _unk;
  final int _numLabels;

  /// Already-voweled text (a voweled book like Madārij) keeps its own marks.
  static const keepIfVoweledShare = 0.6;

  /// Null if the runtime or the model can't be loaded — the caller reads
  /// the text as it is, as before.
  static ArabicDiacritizer? load({required Uint8List model, required String configJson, OrtRuntime? runtime}) {
    final rt = runtime ?? OrtRuntime.open();
    if (rt == null) return null;
    final config = jsonDecode(configJson) as Map<String, dynamic>;
    final sym2id = (config['sym2id'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt()));
    final session = rt.createSession(model);
    return ArabicDiacritizer._(session, sym2id, sym2id['<unk>'] ?? 1, (config['num_tags'] as num?)?.toInt() ?? 16);
  }

  /// One piece (≤ ~1000 characters), always re-diacritized.
  String diacritizePiece(String text) {
    final base = stripForTashkeel(text);
    if (!base.runes.any((r) => isArabicLetter(String.fromCharCode(r)))) return base;
    final ids = [for (final r in base.runes) _sym2id[String.fromCharCode(r)] ?? _unk];
    final (logits, shape) = _session.runInt64ToFloat('input_ids', ids, 'logits');
    if (shape.length != 3 || shape[1] != ids.length || shape[2] != _numLabels) {
      throw OrtException('unexpected logits shape $shape for ${ids.length} chars');
    }
    return attachLabels(base, logits, _numLabels);
  }

  /// A page or paragraph for the voice: voweled text is left alone,
  /// anything else is diacritized piece by piece.
  String diacritize(String text) {
    if (voweledShare(text) >= keepIfVoweledShare) return text;
    return splitForTashkeel(text).map(diacritizePiece).join(' ');
  }

  void dispose() => _session.dispose();
}
