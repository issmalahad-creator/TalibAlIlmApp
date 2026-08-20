/// A تحفيظ (memorization playback) session's settings — mirrors the
/// reference screenshot's fields exactly (قارئ، نطاق آيات من/إلى، تكرار
/// نطاق الآيات، تكرار الآية الواحدة، طول السكتة).
class TahfeezSessionConfig {
  final String reciterId;
  final int surahFrom;
  final int ayahFrom;
  final int surahTo;
  final int ayahTo;

  /// "تكرار نطاق الآيات" — how many times to loop the whole range.
  final int rangeRepeatCount;

  /// "تكرار الآية الواحدة" — 0 means "بدون" (play each ayah once per range
  /// pass); N>0 repeats each ayah N times before moving to the next.
  final int singleAyahRepeatCount;

  /// "طول السكتة (بقدر الآية)" — silence length as a multiple of the
  /// ayah's own playback duration, so a longer ayah gets a longer pause to
  /// repeat it in, not a fixed number of seconds.
  final double silenceMultiplier;

  const TahfeezSessionConfig({
    required this.reciterId,
    required this.surahFrom,
    required this.ayahFrom,
    required this.surahTo,
    required this.ayahTo,
    this.rangeRepeatCount = 1,
    this.singleAyahRepeatCount = 0,
    this.silenceMultiplier = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'reciterId': reciterId,
        'surahFrom': surahFrom,
        'ayahFrom': ayahFrom,
        'surahTo': surahTo,
        'ayahTo': ayahTo,
        'rangeRepeatCount': rangeRepeatCount,
        'singleAyahRepeatCount': singleAyahRepeatCount,
        'silenceMultiplier': silenceMultiplier,
      };

  factory TahfeezSessionConfig.fromJson(Map<String, dynamic> j) => TahfeezSessionConfig(
        reciterId: j['reciterId'] as String,
        surahFrom: j['surahFrom'] as int,
        ayahFrom: j['ayahFrom'] as int,
        surahTo: j['surahTo'] as int,
        ayahTo: j['ayahTo'] as int,
        rangeRepeatCount: j['rangeRepeatCount'] as int,
        singleAyahRepeatCount: j['singleAyahRepeatCount'] as int,
        silenceMultiplier: (j['silenceMultiplier'] as num).toDouble(),
      );
}

enum TahfeezPlaybackMode { idle, playing, silence, paused, finished }

class TahfeezPlaybackState {
  final int surah;
  final int ayah;
  final TahfeezPlaybackMode mode;
  final int rangePass; // current pass through the range, 1-based
  final int ayahRepeat; // current repeat of this ayah, 1-based
  const TahfeezPlaybackState({
    required this.surah,
    required this.ayah,
    required this.mode,
    required this.rangePass,
    required this.ayahRepeat,
  });
}
