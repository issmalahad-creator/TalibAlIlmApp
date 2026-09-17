/// سجلّ أصوات القارئ الصوتي (`docs/audio-reader/TEXT_SOURCE_ADAPTERS.md` §5).
///
/// نفس نمط `reciterId` الموجود أصلًا في `QuranAudioProviderRegistry`
/// (lib/services/quran_audio_engine.dart) — مفتاح نصّي بسيط يُحلّ عبر سجلّ،
/// لا نمط جديد. اليوم صوت واحد فقط، لكن أي صوت مستقبلي (احترافي أو صوت
/// إسماعيل نفسه، طالما صُدِّر لصيغة Piper VITS ONNX متوافقة مع sherpa_onnx)
/// يدخل كصف جديد هنا فقط — بلا تعديل في محرك التوليد أو التخزين المؤقت.
library;

enum TtsVoiceSource { bundled, userRecorded, professional }

class TtsVoiceOption {
  const TtsVoiceOption({
    required this.voiceId,
    required this.displayName,
    required this.modelAssetPath,
    required this.configAssetPath,
    required this.tokensAssetPath,
    required this.espeakDataAssetDir,
    required this.espeakDataFiles,
    required this.source,
  });

  /// مفتاح فريد، مثال: 'piper:ar_JO-kareem-medium'.
  final String voiceId;

  /// يُعرَض لاحقًا في واجهة "اختيار القارئ" (لم تُبنَ بعد).
  final String displayName;

  final String modelAssetPath;
  final String configAssetPath;
  final String tokensAssetPath;

  /// مجلد بيانات espeak-ng (الحد الأدنى: العربية فقط + الملفات المشتركة،
  /// ~1.2 ميجابايت — لا كل اللغات، تحقّق مباشر: 19 ميجابايت لكل اللغات
  /// مقابل 1.2 للعربية وحدها).
  final String espeakDataAssetDir;
  final List<String> espeakDataFiles;

  final TtsVoiceSource source;
}

class TtsVoiceRegistry {
  const TtsVoiceRegistry._();

  static const TtsVoiceOption _kareemMedium = TtsVoiceOption(
    voiceId: 'piper:ar_JO-kareem-medium',
    displayName: 'كريم (عربي أردني)',
    modelAssetPath: 'assets/tts/ar_JO-kareem-medium.onnx',
    configAssetPath: 'assets/tts/ar_JO-kareem-medium.onnx.json',
    tokensAssetPath: 'assets/tts/tokens.txt',
    espeakDataAssetDir: 'assets/tts/espeak-ng-data',
    // القائمة صريحة (لا مسح مجلد وقت التشغيل) — نفس أسلوب bundled assets
    // الثابت أصلًا في هذا المشروع (pubspec.yaml يُدرِج كل ملف بيانات صراحة).
    espeakDataFiles: [
      'ar_dict',
      'intonations',
      'phondata',
      'phondata-manifest',
      'phonindex',
      'phontab',
    ],
    source: TtsVoiceSource.bundled,
  );

  /// اليوم: صف واحد فقط. لا منطق اختيار واجهة بعد (المرحلة 1.3 من
  /// docs/audio-reader/TODO.md) — هذا فقط أساس التخزين.
  static List<TtsVoiceOption> get availableVoices => const [_kareemMedium];

  static TtsVoiceOption get defaultVoice => _kareemMedium;

  static TtsVoiceOption byId(String voiceId) => availableVoices.firstWhere(
    (v) => v.voiceId == voiceId,
    orElse: () => defaultVoice,
  );
}
