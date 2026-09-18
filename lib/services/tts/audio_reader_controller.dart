/// حالة/منطق تشغيل القارئ الصوتي — المرحلة 4 من docs/audio-reader/TODO.md.
/// لا تصميم واجهة هنا (ذاك في الودجت المستهلِك) — `ChangeNotifier` بحت
/// يُدير: الفقرة الحالية، التشغيل/الإيقاف، السرعة، التخطّي، الاستئناف من
/// آخر موضع، والاستباق الخلفي عبر `AudioReaderService.prefetch`.
///
/// **6 ميزات جديدة (2026-09-18)**: مؤقّت نوم، تقدير الوقت المتبقّي، تخطّي
/// فقرة كاملة — كلها هنا. تفصيل الاستخراج/الترميز (تقسيم الفقرات الطويلة،
/// تشذيب الصمت) في `text_sources`/`tts_engine.dart` — كل تحسين حيث ينتمي
/// معماريًا، لا كل شيء في ملف واحد.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show Endian;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

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

  bool _disposed = false;

  int _unitIndex = 1;
  List<String> _paragraphs = const [];
  int _paragraphIndex = 0;
  double _speed = 1.0;
  AudioReaderPlaybackState _state = AudioReaderPlaybackState.idle;
  Object? _lastError;

  Timer? _sleepTimer;
  Duration? _sleepTimerDuration;

  // ميزة 7 — الانتقال التلقائي للصفحة التالية عند انتهاء الحالية، قابل
  // للتفعيل/الإيقاف (طلب إسماعيل 2026-09-18). مفعَّل افتراضيًا: يناسب روح
  // "القارئ الصوتي المتواصل" أكثر من التوقّف عند كل حد صفحة.
  bool _autoAdvancePage = true;
  int? _totalUnitsCache;

  // متوسط متحرّك بسيط لمدة الفقرة الفعلية — أساس تقدير الوقت المتبقّي
  // (ميزة 3). لا حاجة لدقة عالية، تقدير تقريبي كافٍ لغرضه.
  double? _avgParagraphSeconds;

  int get unitIndex => _unitIndex;
  int get paragraphIndex => _paragraphIndex;
  int get paragraphCount => _paragraphs.length;
  double get speed => _speed;
  AudioReaderPlaybackState get state => _state;
  Object? get lastError => _lastError;
  String get currentParagraphText => _paragraphIndex < _paragraphs.length ? _paragraphs[_paragraphIndex] : '';
  Duration? get sleepTimerDuration => _sleepTimerDuration;
  bool get autoAdvancePage => _autoAdvancePage;

  set autoAdvancePage(bool value) {
    _autoAdvancePage = value;
    notifyListeners();
  }

  /// حارس ضد "استُخدِم بعد dispose()" — `start()`/`_playCurrentParagraph()`
  /// غير متزامنتين، فقد يُغلَق المستخدم الورقة السفلية (يُشغِّل dispose())
  /// أثناء انتظار توليد أول فقرة (2026-09-18، خطأ حقيقي وُجِد على جهاز
  /// حقيقي: "A AudioReaderController was used after being disposed").
  /// `notifyListeners()` العادي يرمي استثناءً إن استُدعِي بعد dispose — هذا
  /// يتجاهله بصمت بدل ذلك (لا فائدة من تحديث واجهة لم تعد موجودة).
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// تقدير تقريبي للوقت المتبقّي حتى نهاية الوحدة الحالية — null حتى تُقاس
  /// أول فقرة فعليًا (لا تخمين قبل وجود بيانات حقيقية).
  Duration? get estimatedTimeRemaining {
    final avg = _avgParagraphSeconds;
    if (avg == null) return null;
    final remainingParagraphs = (_paragraphs.length - _paragraphIndex).clamp(0, _paragraphs.length);
    return Duration(milliseconds: (avg * remainingParagraphs * 1000 / _speed).round());
  }

  /// يبدأ من آخر موضع استماع مُسجَّل لهذا المصدر (أو الوحدة 1 إن لم يوجد)،
  /// يحمِّل فقرات تلك الوحدة، ويشغِّل الفقرة الحالية فورًا.
  Future<void> start() async {
    _state = AudioReaderPlaybackState.loading;
    notifyListeners();
    try {
      _unitIndex = await source.lastReadUnit ?? 1;
      await _loadUnit(_unitIndex, startParagraph: 0);
      await _playCurrentParagraph();
    } catch (e, st) {
      debugPrint('[AudioReader] فشل start(): $e\n$st');
      _lastError = e;
      _state = AudioReaderPlaybackState.idle;
      _safeNotify();
    }
  }

  Future<void> _loadUnit(int unitIndex, {required int startParagraph}) async {
    _unitIndex = unitIndex;
    _paragraphs = await source.paragraphsForUnit(unitIndex);
    _paragraphIndex = startParagraph.clamp(0, _paragraphs.isEmpty ? 0 : _paragraphs.length - 1);
  }

  Future<void> _playCurrentParagraph() async {
    if (_disposed) return;
    if (_paragraphs.isEmpty) {
      _state = AudioReaderPlaybackState.finished;
      _safeNotify();
      return;
    }
    _state = AudioReaderPlaybackState.loading;
    _lastError = null;
    _safeNotify();

    try {
      final file = await _service.fileForParagraph(
        source: source,
        voiceId: voiceId,
        unitIndex: _unitIndex,
        paragraphIndex: _paragraphIndex,
        text: _paragraphs[_paragraphIndex],
      );
      unawaited(_updateAverageDuration(file));
      await _player.play(DeviceFileSource(file.path));
      await _player.setPlaybackRate(_speed);
      _state = AudioReaderPlaybackState.playing;
      _safeNotify();
    } catch (e, st) {
      // كان هذا الخطأ يُبلَع صامتًا (لا طباعة إطلاقًا) رغم تعليق سابق يدّعي
      // أن التفصيل التقني "يذهب لـ debugPrint" — لم يكن يذهب لأي مكان فعليًا،
      // هذا هو سبب عدم ظهور أي أثر عبر 5 محاولات التقاط logcat سابقة
      // (2026-09-18).
      debugPrint('[AudioReader] فشل _playCurrentParagraph() فقرة=$_paragraphIndex وحدة=$_unitIndex: $e\n$st');
      _lastError = e;
      _state = AudioReaderPlaybackState.idle;
      _safeNotify();
      return;
    }

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

  /// يقرأ ترويسة WAV (44 بايت أولى، لا الملف كاملًا) لحساب مدة الفقرة
  /// الفعلية من حجم بيانات PCM ومعدّل العيّنة — أساس تقدير الوقت المتبقّي.
  Future<void> _updateAverageDuration(File wavFile) async {
    try {
      final raf = await wavFile.open();
      final header = await raf.read(44);
      await raf.close();
      if (header.length < 44) return;
      final byteData = header.buffer.asByteData();
      final sampleRate = byteData.getUint32(24, Endian.little);
      final dataBytes = byteData.getUint32(40, Endian.little);
      if (sampleRate == 0) return;
      final seconds = dataBytes / 2 / sampleRate; // 16-bit mono
      _avgParagraphSeconds = _avgParagraphSeconds == null ? seconds : (_avgParagraphSeconds! * 0.7 + seconds * 0.3);
    } catch (_) {
      // تقدير تقريبي غير أساسي — فشل القراءة لا يُوقِف التشغيل.
    }
  }

  Future<void> _onParagraphComplete() async {
    await source.saveLastListenedUnit(_unitIndex);
    if (_paragraphIndex + 1 < _paragraphs.length) {
      _paragraphIndex++;
      await _playCurrentParagraph();
      return;
    }

    if (_autoAdvancePage) {
      _totalUnitsCache ??= await source.totalUnits;
      final total = _totalUnitsCache!;
      if (total > 0 && _unitIndex < total) {
        await _loadUnit(_unitIndex + 1, startParagraph: 0);
        await _playCurrentParagraph();
        return;
      }
    }

    _state = AudioReaderPlaybackState.finished;
    _safeNotify();
  }

  Future<void> pause() async {
    await _player.pause();
    _state = AudioReaderPlaybackState.paused;
    _safeNotify();
  }

  /// **لا يُستدعى بعد فشل** — `_player.resume()` يستأنف مشغِّلًا قد لا يحمل
  /// أي مصدر صالح إطلاقًا إن كان آخر توليد قد فشل قبل الوصول لـ`_player.play()`
  /// أصلًا، فيُنتِج حالة "يُشغِّل" ظاهريًا بلا صوت فعلي ورسالة الخطأ لا تزال
  /// معروضة — خلل حقيقي وُجِد فعليًا (2026-09-18). استخدم [retry] بدلًا منه
  /// حين `lastError != null`.
  Future<void> resume() async {
    await _player.resume();
    _state = AudioReaderPlaybackState.playing;
    _safeNotify();
  }

  /// إعادة محاولة توليد/تشغيل الفقرة الحالية نفسها بعد فشل — المسار
  /// الصحيح للتعافي، لا [resume].
  Future<void> retry() => _playCurrentParagraph();

  Future<void> replayParagraph() async {
    await _player.seek(Duration.zero);
    await _player.resume();
    _state = AudioReaderPlaybackState.playing;
    _safeNotify();
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
    _safeNotify();
  }

  /// القراءة من موضع لمسه المستخدم يدويًا (4.4) — يقفز لفقرة محدَّدة مباشرة.
  Future<void> jumpToParagraph(int index) async {
    if (index < 0 || index >= _paragraphs.length) return;
    _paragraphIndex = index;
    await _playCurrentParagraph();
  }

  /// ميزة 5 — تخطّي فقرة كاملة (لا 10 ثوانٍ فقط)، للأمام أو الخلف.
  Future<void> previousParagraph() => jumpToParagraph(_paragraphIndex - 1);
  Future<void> nextParagraph() => jumpToParagraph(_paragraphIndex + 1);

  /// ميزة 2 — مؤقّت نوم. `null` يُلغي المؤقّت الحالي. عند الانتهاء: إيقاف
  /// مؤقّت للتشغيل (لا إغلاق الورقة السفلية) — المستخدم يقرّر الخطوة التالية.
  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimerDuration = duration;
    if (duration != null) {
      _sleepTimer = Timer(duration, () {
        if (_disposed) return;
        _sleepTimerDuration = null;
        pause();
      });
    }
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _completeSub.cancel();
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
