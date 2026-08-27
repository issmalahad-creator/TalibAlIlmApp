/// Recognition provider abstraction for "تسميع" (Phase 76.3) — Ismail's
/// direct instruction 2026-08-26: don't couple the Quran recitation-
/// matching layer to `speech_to_text` specifically. `RecitationRepository`/
/// `alignRecitation` already only ever see plain `List<String>` words, so
/// they're provider-agnostic by construction; this interface is the other
/// half — it lets `PlatformSpeechRecognitionEngine` (today: OS-native
/// speech via the `speech_to_text` package, real and testable immediately,
/// no model download) be swapped later for a Quran-specialized ASR/Whisper
/// engine (TODO.md 76.3b — real Whisper-Quran LoRA fine-tunes exist,
/// verified 2026-08-26) without touching any screen or matching code, only
/// this file plus whichever class implements it next.
abstract class SpeechRecognitionEngine {
  /// Must succeed before [startListening] can be used. Requests the
  /// microphone permission natively as part of initializing.
  Future<bool> initialize();

  bool get isAvailable;
  bool get isListening;

  /// Real Arabic locales this engine can actually recognize on this
  /// device right now — never assume Arabic is available, some devices
  /// genuinely don't have it installed.
  Future<List<String>> availableArabicLocaleIds();

  /// [onPartialResult] fires repeatedly as words are recognized mid-
  /// speech (for live UI feedback); [onFinalResult] fires once when the
  /// session ends with the engine's best final transcript.
  Future<void> startListening({
    required void Function(String text) onPartialResult,
    required void Function(String text) onFinalResult,
    String? localeId,
  });

  Future<void> stopListening();

  void dispose();
}
