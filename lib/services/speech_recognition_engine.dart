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
  /// speech (for live UI feedback). [onFinalResult] fires once per
  /// detected pause segment (whenever the underlying recognizer decides
  /// the student paused) — it does NOT end the session. The engine keeps
  /// listening automatically after each segment, so a whole page's worth
  /// of continuous recitation across many ayat arrives as a stream of
  /// [onFinalResult] calls, one per natural pause, until the caller
  /// explicitly calls [stopListening]. (76.3-page-redesign, Ismail
  /// 2026-08-28: "لا أريد آية بآية" — a single session-ending final
  /// result per ayah was the old single-ayah model; this is the new one.)
  ///
  /// [listenFor]/[pauseFor] bound each individual segment, not the whole
  /// session — [pauseFor] is the silence length that ends one segment
  /// (kept short so ayah-to-ayah pauses are detected promptly),
  /// [listenFor] is a safety cap per segment before it's force-cut and
  /// automatically restarted.
  Future<void> startListening({
    required void Function(String text) onPartialResult,
    required void Function(String text) onFinalResult,
    String? localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 5),
  });

  Future<void> stopListening();

  void dispose();
}
