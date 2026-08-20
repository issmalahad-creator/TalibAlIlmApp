import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../data/quran_surahs.dart';
import '../models/tahfeez_session_config.dart';
import 'quran_audio/quran_audio_provider_registry.dart';
import 'quran_audio_download_service.dart';
import 'tahfeez_session_prefs.dart';

/// تحفيظ playback engine — Ismail's exact method spec (`playAyah`/
/// `playRange`/`repeatAyah`/`repeatRange`/`setPauseBetweenAyat`/
/// `setRepeatCount`/`playListenAndRepeatSession`/`resumeSession`). Built on
/// `audioplayers` (same package/pattern as `book_screen.dart`'s
/// `_VoicePlayButton`: one `AudioPlayer`, `onPlayerComplete` drives
/// sequencing). Prefers a locally downloaded file over streaming — see
/// `QuranAudioDownloadService.localFileIfExists` — but works even with
/// nothing downloaded, since `UrlSource` streams directly from whichever
/// provider `QuranAudioProviderRegistry` resolves to.
class QuranAudioEngine {
  final _player = AudioPlayer();
  final _downloadService = QuranAudioDownloadService();
  final _sessionPrefs = TahfeezSessionPrefs();
  final _stateController = StreamController<TahfeezPlaybackState>.broadcast();

  Duration _pauseBetweenAyat = const Duration(seconds: 2);
  int _defaultRepeatCount = 1;
  bool _cancelled = false;

  Stream<TahfeezPlaybackState> get stateStream => _stateController.stream;

  void setPauseBetweenAyat(Duration d) => _pauseBetweenAyat = d;
  void setRepeatCount(int n) => _defaultRepeatCount = n;

  void stop() {
    _cancelled = true;
    _player.stop();
  }

  Future<Source> _sourceFor(String reciterId, int surah, int ayah) async {
    final local = await _downloadService.localFileIfExists(reciterId, surah, ayah);
    if (local != null) return DeviceFileSource(local.path);
    final url = QuranAudioProviderRegistry.ayahAudioUrl(reciterId: reciterId, surah: surah, ayah: ayah);
    return UrlSource(url ?? '');
  }

  /// Plays one ayah and waits until it finishes.
  Future<void> playAyah(String reciterId, int surah, int ayah) async {
    final source = await _sourceFor(reciterId, surah, ayah);
    await _player.play(source);
    await _player.onPlayerComplete.first;
  }

  /// Plays every ayah from (surahFrom, ayahFrom) through (surahTo, ayahTo)
  /// once, in order.
  Future<void> playRange(String reciterId, int surahFrom, int ayahFrom, int surahTo, int ayahTo) async {
    for (final pair in _ayahsInRange(surahFrom, ayahFrom, surahTo, ayahTo)) {
      if (_cancelled) return;
      await playAyah(reciterId, pair.$1, pair.$2);
    }
  }

  /// Plays one ayah [times] times (falls back to the count set via
  /// `setRepeatCount` when omitted), with `_pauseBetweenAyat` between
  /// repeats — the pause length used here is `_pauseBetweenAyat` fixed;
  /// `playListenAndRepeatSession` uses the ayah's own duration instead
  /// (per `TahfeezSessionConfig.silenceMultiplier`).
  Future<void> repeatAyah(String reciterId, int surah, int ayah, {int? times}) async {
    final count = times ?? _defaultRepeatCount;
    for (var i = 0; i < count; i++) {
      if (_cancelled) return;
      await playAyah(reciterId, surah, ayah);
      if (i < count - 1) await Future.delayed(_pauseBetweenAyat);
    }
  }

  Future<void> repeatRange(String reciterId, int surahFrom, int ayahFrom, int surahTo, int ayahTo, {int? times}) async {
    final count = times ?? _defaultRepeatCount;
    for (var i = 0; i < count; i++) {
      if (_cancelled) return;
      await playRange(reciterId, surahFrom, ayahFrom, surahTo, ayahTo);
      if (i < count - 1) await Future.delayed(_pauseBetweenAyat);
    }
  }

  /// The full تحفيظ session: for each pass through the range, each ayah
  /// plays once, then (if `singleAyahRepeatCount > 0`) repeats that many
  /// more times, with a silence gap after every play sized to the ayah's
  /// own duration × `silenceMultiplier` — long enough for the student to
  /// recite it back before the next play. Saves position after every ayah
  /// via `TahfeezSessionPrefs` so `resumeSession()` can pick up here again.
  Future<void> playListenAndRepeatSession(TahfeezSessionConfig config) async {
    _cancelled = false;
    final ayahs = _ayahsInRange(config.surahFrom, config.ayahFrom, config.surahTo, config.ayahTo);

    for (var pass = 1; pass <= config.rangeRepeatCount; pass++) {
      for (final pair in ayahs) {
        if (_cancelled) return;
        final surah = pair.$1;
        final ayah = pair.$2;
        await _sessionPrefs.save(config, surah, ayah);

        final totalRepeats = config.singleAyahRepeatCount > 0 ? config.singleAyahRepeatCount : 1;
        for (var rep = 1; rep <= totalRepeats; rep++) {
          if (_cancelled) return;
          _emit(surah, ayah, TahfeezPlaybackMode.playing, pass, rep);
          final source = await _sourceFor(config.reciterId, surah, ayah);
          await _player.play(source);
          await _player.onPlayerComplete.first;

          if (_cancelled) return;
          _emit(surah, ayah, TahfeezPlaybackMode.silence, pass, rep);
          final duration = await _player.getDuration() ?? const Duration(seconds: 3);
          await Future.delayed(duration * config.silenceMultiplier);
        }
      }
    }
    _emit(config.surahTo, config.ayahTo, TahfeezPlaybackMode.finished, config.rangeRepeatCount, 1);
    await _sessionPrefs.clear();
  }

  /// Resumes the last saved session (if any) from where it left off,
  /// starting the range at the saved (surah, ayah) instead of the
  /// original `surahFrom`/`ayahFrom`.
  Future<bool> resumeSession() async {
    final saved = await _sessionPrefs.load();
    if (saved == null) return false;
    final (config, surah, ayah) = saved;
    final resumeConfig = TahfeezSessionConfig(
      reciterId: config.reciterId,
      surahFrom: surah,
      ayahFrom: ayah,
      surahTo: config.surahTo,
      ayahTo: config.ayahTo,
      rangeRepeatCount: 1,
      singleAyahRepeatCount: config.singleAyahRepeatCount,
      silenceMultiplier: config.silenceMultiplier,
    );
    await playListenAndRepeatSession(resumeConfig);
    return true;
  }

  Future<bool> hasResumableSession() async => (await _sessionPrefs.load()) != null;

  void _emit(int surah, int ayah, TahfeezPlaybackMode mode, int pass, int rep) {
    _stateController.add(TahfeezPlaybackState(surah: surah, ayah: ayah, mode: mode, rangePass: pass, ayahRepeat: rep));
  }

  /// Same (surah, ayah) range-walking logic as
  /// `QuranAudioDownloadService._ayahsInRange` (kept as a separate copy —
  /// one lives in the I/O/download layer, this one in the playback layer —
  /// but both read ayah counts from the same real source, `quranSurahs`
  /// in `lib/data/quran_surahs.dart`, rather than a second hand-typed
  /// table that could drift or contain a transcription error).
  List<(int, int)> _ayahsInRange(int surahFrom, int ayahFrom, int surahTo, int ayahTo) {
    final pairs = <(int, int)>[];
    for (var s = surahFrom; s <= surahTo; s++) {
      final surah = quranSurahs.firstWhere((x) => x.number == s);
      final startAyah = s == surahFrom ? ayahFrom : 1;
      final endAyah = s == surahTo ? ayahTo : surah.ayahCount;
      for (var a = startAyah; a <= endAyah; a++) {
        pairs.add((s, a));
      }
    }
    return pairs;
  }

  void dispose() {
    _stateController.close();
    _player.dispose();
  }
}
