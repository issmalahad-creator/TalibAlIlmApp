import 'package:speech_to_text/speech_to_text.dart';

import 'speech_recognition_engine.dart';

/// V1 implementation of [SpeechRecognitionEngine] using the `speech_to_text`
/// package (OS-native Android/iOS speech recognition — Google's on-device
/// engine on Android when an offline language pack is installed, otherwise
/// cloud-based). Deliberately not a Quran-specialized model — real,
/// verified alternatives exist (TODO.md 76.3b: Whisper-Quran LoRA fine-
/// tunes with a reported ≈5.98% WER) and should be evaluated as a second
/// [SpeechRecognitionEngine] implementation later. This class exists only
/// to prove the real end-to-end workflow works today: microphone → real
/// recognized text → real Quran verse comparison → real feedback — not to
/// claim Quran-specialized recognition accuracy.
class PlatformSpeechRecognitionEngine implements SpeechRecognitionEngine {
  final _speech = SpeechToText();
  bool _initialized = false;

  @override
  bool get isAvailable => _initialized && _speech.isAvailable;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  @override
  Future<List<String>> availableArabicLocaleIds() async {
    if (!_initialized) return [];
    final locales = await _speech.locales();
    // Real Arabic locale IDs (ar_SA, ar_EG, etc.) all start with "ar_" —
    // don't hardcode one specific country's locale, accept any Arabic.
    return locales.where((l) => l.localeId.toLowerCase().startsWith('ar')).map((l) => l.localeId).toList();
  }

  @override
  Future<void> startListening({
    required void Function(String text) onPartialResult,
    required void Function(String text) onFinalResult,
    String? localeId,
  }) async {
    if (!_initialized) {
      throw StateError('PlatformSpeechRecognitionEngine.initialize() must succeed before startListening()');
    }
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: localeId, partialResults: true),
      onResult: (result) {
        if (result.finalResult) {
          onFinalResult(result.recognizedWords);
        } else {
          onPartialResult(result.recognizedWords);
        }
      },
    );
  }

  @override
  Future<void> stopListening() => _speech.stop();

  @override
  void dispose() {
    if (_speech.isListening) _speech.cancel();
  }
}
