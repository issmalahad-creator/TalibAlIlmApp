import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import 'speech_recognition_engine.dart';

/// Real Android `SpeechRecognizer` error codes that are routine and
/// expected during a normal continuous session -- most commonly
/// "error_speech_timeout" (no speech detected within the window, e.g. the
/// student pauses to think or hasn't started yet) and "error_no_match"
/// (something was heard but not recognized). The underlying
/// `speech_to_text` Android plugin always reports `permanent: true` for
/// every error (confirmed by reading its real Kotlin source,
/// `SpeechToTextPlugin.kt`'s `sendError` -- it never actually varies), so
/// this engine must classify transient-vs-fatal itself rather than trust
/// the package's `permanent` flag.
const _transientErrors = {'error_speech_timeout', 'error_no_match', 'error_busy', 'error_network_timeout', 'error_server_disconnected'};

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
  void Function(String message, bool permanent)? _onError;
  String? _localeId;
  Duration _listenFor = const Duration(seconds: 30);
  Duration _pauseFor = const Duration(seconds: 5);

  // Real device bug found 2026-08-29 (Ismail: "لا يدخل الصوت"): a segment
  // that ends via a recognizer ERROR rather than a normal final result
  // used to just stop the whole continuous session at the OS level with
  // no restart and no visible message -- the UI kept showing "listening"
  // forever while nothing was actually being captured. A consecutive-
  // error counter caps automatic retries so a genuinely broken state
  // (not just a normal pre-speech silence timeout) still surfaces a real
  // error instead of retrying forever just as silently.
  int _consecutiveErrors = 0;
  static const _maxConsecutiveErrors = 4;

  @override
  bool get isAvailable => _initialized && _speech.isAvailable;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;
    _initialized = await _speech.initialize(onError: (e) => _handleError(e.errorMsg));
    return _initialized;
  }

  void _handleError(String errorMsg) {
    final transient = _transientErrors.contains(errorMsg);
    if (_continuous && transient && _consecutiveErrors < _maxConsecutiveErrors) {
      _consecutiveErrors++;
      _onError?.call(errorMsg, false);
      // The OS-level listen session is already dead at this point (that's
      // what "error" means here) -- must start a fresh one, same as after
      // a normal final result, or the student's next words are never heard.
      _listenOneSegment();
      return;
    }
    _continuous = false;
    _onError?.call(errorMsg, true);
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
    void Function(String message, bool permanent)? onError,
    String? localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 5),
  }) async {
    if (!_initialized) {
      throw StateError('PlatformSpeechRecognitionEngine.initialize() must succeed before startListening()');
    }
    _continuous = true;
    _consecutiveErrors = 0;
    _onPartialResult = onPartialResult;
    _onFinalResult = onFinalResult;
    _onError = onError;
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
        _consecutiveErrors = 0; // a real result means the session is genuinely alive
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
