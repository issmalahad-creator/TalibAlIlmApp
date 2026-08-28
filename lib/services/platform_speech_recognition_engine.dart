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

  // Held so a finished segment can restart listening automatically —
  // see the class doc and startListening's doc comment for why a single
  // `listen()` call isn't enough for a continuous page-level session.
  bool _continuous = false;
  void Function(String text)? _onPartialResult;
  void Function(String text)? _onFinalResult;
  String? _localeId;
  Duration _listenFor = const Duration(seconds: 30);
  Duration _pauseFor = const Duration(seconds: 5);

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
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 5),
  }) async {
    if (!_initialized) {
      throw StateError('PlatformSpeechRecognitionEngine.initialize() must succeed before startListening()');
    }
    _continuous = true;
    _onPartialResult = onPartialResult;
    _onFinalResult = onFinalResult;
    _localeId = localeId;
    _listenFor = listenFor;
    _pauseFor = pauseFor;
    await _listenOneSegment();
  }

  Future<void> _listenOneSegment() async {
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        partialResults: true,
        listenFor: _listenFor,
        pauseFor: _pauseFor,
      ),
      onResult: (result) {
        if (result.finalResult) {
          _onFinalResult?.call(result.recognizedWords);
          // A "final" result here just means the recognizer detected a
          // pause and closed this segment, not that the student is done
          // reciting — restart automatically so the next ayah is caught
          // too, unless the caller has meanwhile called stopListening().
          if (_continuous) _listenOneSegment();
        } else {
          _onPartialResult?.call(result.recognizedWords);
        }
      },
    );
  }

  @override
  Future<void> stopListening() async {
    _continuous = false;
    await _speech.stop();
  }

  @override
  void dispose() {
    _continuous = false;
    if (_speech.isListening) _speech.cancel();
  }
}
