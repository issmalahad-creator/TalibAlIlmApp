/// حالة/منطق تشغيل القارئ الصوتي — المرحلة 4 من docs/audio-reader/TODO.md.
/// لا تصميم واجهة هنا (ذاك في الودجت المستهلِك) — `ChangeNotifier` بحت
/// يُدير: الفقرة الحالية، التشغيل/الإيقاف، السرعة، التخطّي، الاستئناف من
/// آخر موضع، والاستباق الخلفي عبر `AudioReaderService.prefetch`.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_reader_service.dart';
import 'text_sources/readable_text_source.dart';

enum AudioReaderPlaybackState { idle, loading, playing, paused, finished }

class AudioReaderController extends ChangeNotifier {
  AudioReaderController({
    required this.source,
    required this.voiceId,
    AudioReaderService? service,
    AudioPlayer? player,
  }) : _service = service ?? AudioReaderService(),
       _player = player ?? AudioPlayer() {
    _completeSub = _player.onPlayerComplete.listen((_) => _onParagraphComplete());
  }

  final ReadableTextSource source;
  final String voiceId;
  final AudioReaderService _service;
  final AudioPlayer _player;
  late final StreamSubscription<void> _completeSub;

  int _unitIndex = 1;
  List<String> _paragraphs = const [];
  int _paragraphIndex = 0;
  double _speed = 1.0;
  AudioReaderPlaybackState _state = AudioReaderPlaybackState.idle;
  Object? _lastError;

  int get unitIndex => _unitIndex;
  int get paragraphIndex => _paragraphIndex;
  int get paragraphCount => _paragraphs.length;
  double get speed => _speed;
  AudioReaderPlaybackState get state => _state;
  Object? get lastError => _lastError;
  String get currentParagraphText => _paragraphIndex < _paragraphs.length ? _paragraphs[_paragraphIndex] : '';

  /// يبدأ من آخر موضع استماع مُسجَّل لهذا المصدر (أو الوحدة 1 إن لم يوجد)،
  /// يحمِّل فقرات تلك الوحدة، ويشغِّل الفقرة الحالية فورًا.
  Future<void> start() async {
    _state = AudioReaderPlaybackState.loading;
    notifyListeners();
    try {
      _unitIndex = await source.lastReadUnit ?? 1;
      await _loadUnit(_unitIndex, startParagraph: 0);
      await _playCurrentParagraph();
    } catch (e) {
      _lastError = e;
      _state = AudioReaderPlaybackState.idle;
      notifyListeners();
    }
  }

  Future<void> _loadUnit(int unitIndex, {required int startParagraph}) async {
    _unitIndex = unitIndex;
    _paragraphs = await source.paragraphsForUnit(unitIndex);
    _paragraphIndex = startParagraph.clamp(0, _paragraphs.isEmpty ? 0 : _paragraphs.length - 1);
  }

  Future<void> _playCurrentParagraph() async {
    if (_paragraphs.isEmpty) {
      _state = AudioReaderPlaybackState.finished;
      notifyListeners();
      return;
    }
    _state = AudioReaderPlaybackState.loading;
    notifyListeners();

    final file = await _service.fileForParagraph(
      source: source,
      voiceId: voiceId,
      unitIndex: _unitIndex,
      paragraphIndex: _paragraphIndex,
      text: _paragraphs[_paragraphIndex],
    );
    await _player.play(DeviceFileSource(file.path));
    await _player.setPlaybackRate(_speed);
    _state = AudioReaderPlaybackState.playing;
    notifyListeners();

    // استباق خلفي — لا ننتظره، لا يحجب التشغيل الحالي.
    unawaited(
      _service.prefetch(
        source: source,
        voiceId: voiceId,
        unitIndex: _unitIndex,
        paragraphs: _paragraphs,
        fromParagraphIndex: _paragraphIndex,
      ),
    );
  }

  Future<void> _onParagraphComplete() async {
    await source.saveLastListenedUnit(_unitIndex);
    if (_paragraphIndex + 1 < _paragraphs.length) {
      _paragraphIndex++;
      await _playCurrentParagraph();
    } else {
      _state = AudioReaderPlaybackState.finished;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _state = AudioReaderPlaybackState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.resume();
    _state = AudioReaderPlaybackState.playing;
    notifyListeners();
  }

  Future<void> replayParagraph() async {
    await _player.seek(Duration.zero);
    await _player.resume();
    _state = AudioReaderPlaybackState.playing;
    notifyListeners();
  }

  Future<void> skip(Duration delta) async {
    final position = await _player.getCurrentPosition() ?? Duration.zero;
    final target = position + delta;
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  /// 0.75×–1.5× عبر معدّل تشغيل المشغّل نفسه — لا إعادة توليد الصوت
  /// (docs/audio-reader/TODO.md 4.2).
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.75, 1.5);
    await _player.setPlaybackRate(_speed);
    notifyListeners();
  }

  /// القراءة من موضع لمسه المستخدم يدويًا (4.4) — يقفز لفقرة محدَّدة مباشرة.
  Future<void> jumpToParagraph(int index) async {
    if (index < 0 || index >= _paragraphs.length) return;
    _paragraphIndex = index;
    await _playCurrentParagraph();
  }

  @override
  void dispose() {
    _completeSub.cancel();
    _player.dispose();
    super.dispose();
  }
}
