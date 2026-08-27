import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_surahs.dart';
import 'ayah_study_screen.dart';
import 'recitation_practice_screen.dart';
import 'tahfeez_session_setup_screen.dart';
import '../l10n/basic_translations.dart';
import '../l10n/reading_encouragement.dart';
import '../repositories/journey_plan_repository.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/quran_reading_session_repository.dart';
import '../repositories/quran_search_repository.dart';
import '../services/companion_context_tracker.dart';
import '../services/language_preference_service.dart';
import '../services/mushaf_page_layout.dart';
import '../services/quran_audio/quran_audio_provider_registry.dart';
import '../services/quran_audio_engine.dart';
import '../services/text_scale_preference_service.dart';
import '../theme/app_theme.dart';
import '../theme/depth.dart';
import '../theme/motion.dart';
import 'journey_screen.dart';
import 'quran_browse_screen.dart';
import 'quran_search_screen.dart';
import '../widgets/loading_view.dart';

/// The rail/frame gold — reuses `DepthPalette.quran.accent`
/// (`lib/theme/depth.dart`), the app's one established Quran-section gold,
/// rather than a second hand-picked color.
final _goldColor = DepthPalette.quran.accent;

const _themeColors = {
  'brown': (Color(0xFF8B5E34), 'بنّي'),
  'teal': (AppColors.primary, 'أخضر'),
  'blue': (Color(0xFF2F80ED), 'أزرق'),
  'red': (Color(0xFFB33951), 'أحمر'),
  'purple': (Color(0xFF6A4C93), 'بنفسجي'),
};

/// "القرآن" hub — QURAN_COMPANION_ROADMAP.md section 4.15, expanded
/// 2026-08-16 per Ismail's explicit request ("اجعل كل متعلقات القرآن في
/// مكان وداخل ايقونة واحدة" — gather everything Quran-related into one
/// place behind one icon) and a reference app's tap-an-ayah context menu
/// + "طريقة عرض المصحف" options sheet he asked to be matched. Page-by-page
/// reading is still the core (position auto-saves on leaving this screen
/// or backgrounding the app while on it, per Ismail's "الخروج من الشاشة
/// يكفي"). Tapping any ayah opens a floating menu right there (تفسير /
/// مفضلة / نشر — real features) alongside الترجمة/الاستماع/المعاني, which
/// stay visibly present but disabled with an honest "لا يوجد مصدر بيانات
/// بعد" — neither translation text nor a licensed per-ayah audio source
/// nor a word-by-word gloss corpus has been sourced into this app yet,
/// and faking any of them would violate this project's sourcing
/// discipline; they're flagged as real follow-up work, not silently
/// dropped or invented.
class QuranReadingScreen extends StatefulWidget {
  const QuranReadingScreen({super.key});

  @override
  State<QuranReadingScreen> createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends State<QuranReadingScreen> with WidgetsBindingObserver {
  final _repo = QuranReadingRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  int _page = 1;
  List<QuranAyahText> _ayat = [];
  bool _loading = true;
  List<_AyahPolygon> _pagePolygons = [];
  _AyahPolygon? _flashedPolygon;
  bool _showTafsir = false;
  String _tafsirSource = QuranSearchRepository.defaultTafsirSource;
  String _tafsirLanguage = 'ar';
  Map<String, String> _tafsirByAyah = {};
  bool _nightMode = false;
  String _themeKey = 'brown';

  /// "خط المصحف" (Ismail's request 2026-08-20) — AmiriQuran stays the only
  /// selectable option for now. DigitalKhattMadina (OFL-1.1,
  /// github.com/DigitalKhatt/madinafont) was added and tried on-device, but
  /// confirmed broken: overlapping/garbled glyphs, matching a real,
  /// still-open upstream issue (github.com/DigitalKhatt/madinafont/issues/21,
  /// "many rendering problems" in Safari — a genuine cross-engine
  /// variable-font/CFF2 bug in the font itself, not a Flutter/Android-only
  /// glitch). A `fonttools` static-instancing attempt to work around it
  /// crashed on a malformed charstring inside the font, confirming it's an
  /// upstream font bug, not something fixable from this app's side. Font
  /// asset + pubspec registration are left in place (harmless, unused) so
  /// re-adding it is a one-line change once it's actually fixed upstream or
  /// King Fahd Complex responds with official font permission instead.
  static const _quranFonts = {
    'AmiriQuran': 'الأميري',
  };
  String _quranFontFamily = 'AmiriQuran';

  /// The currently tapped ayah — highlighted (per-line background, matching
  /// the reference app's boxed-highlight look) while its context menu is
  /// open, cleared once it closes. Ismail's 2026-08-16 "طبق الأصل" request.
  int? _selectedSurah;
  int? _selectedAyah;

  /// "الوقت المتبقي لختم القرآن" (100_IDEAS_FOR_IMPROVEMENT.md #21) —
  /// shown here too, not only inside رحلتي, so it's visible without an
  /// extra tap. Loaded separately from `_load()` (own try/no-op-if-null
  /// path) so a student with no active memorization plan yet sees the
  /// banner's original static text with no error.
  int? _daysLeftToKhatm;

  /// "طابع الـ3D" (quirky-gliding-shell.md's premium-depth plan) — a
  /// living-light effect on the Mushaf page, tied to the phone's real tilt
  /// instead of a mouse (which doesn't exist on a touch device). Values
  /// stay small and are throttled (`_lastTiltUpdate`) so the effect reads
  /// as gentle ambient light, not a distracting gimmick, and so `setState`
  /// doesn't fire on every sensor frame.
  StreamSubscription<OrientationEvent>? _tiltSub;
  double _tiltX = 0;
  double _tiltY = 0;
  DateTime _lastTiltUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  /// "فضّل هذه الصفحة" (الرواق الذهبي، 2026-08-17) — true فقط إن كانت كل
  /// آيات الصفحة الحالية مفضَّلة فعليًا بالفعل (`QuranReadingRepository`
  /// الموجودة، لا آلية جديدة). يُعاد حسابها بعد كل تحميل صفحة.
  bool _pageFavorited = false;

  /// شريط الاستماع (الرواق الذهبي، 2026-08-17) — يبني على `QuranAudioEngine`
  /// الموجود فعليًا (`playAyah`/`stop`/`pause`/`resume`)، يتحكم يدويًا بالتقدّم
  /// آية-بآية بدل `playRange` الأعمى، لأن `stateStream` لا تُغذّى إلا من جلسة
  /// التحفيظ المنفصلة. `_audioPaused` يمنع بدء الآية التالية عبر حلقة الانتظار
  /// وأيضًا يوقف الصوت الجاري فعليًا (`QuranAudioEngine.pause`) — أُصلح
  /// 2026-08-20 بعد أن كان يوقف التسلسل فقط لا الصوت نفسه.
  final _audioEngine = QuranAudioEngine();
  bool _showAudioBar = false;
  bool _audioPlaying = false;
  bool _audioPaused = false;
  int _audioIndex = 0;
  String _audioReciterId = QuranAudioProviderRegistry.reciters().first.id;

  /// "كم دقيقة ستقرأ القرآن اليوم" (2026-08-17, Ismail's "gym coach" idea)
  /// — a simple countdown from a student-picked target, celebrated on
  /// completion by comparing against `_readingSessionRepo.lastCompletedMinutes()`.
  /// Lives entirely in this screen's own lifecycle (matches "عند دخول
  /// القرآن... الدقائق"): starting a session doesn't survive navigating
  /// away, same as the audio bar above.
  final _readingSessionRepo = QuranReadingSessionRepository();
  Timer? _sessionTimer;
  int? _sessionTargetMinutes;
  int _sessionRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNightModePref();
    _loadFontPref();
    _load();
    _loadJourneySummary();
    _initTiltParallax();
  }

  static const _nightModePrefKey = 'quran_reading_night_mode';

  Future<void> _loadNightModePref() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_nightModePrefKey);
    if (saved != null && mounted) setState(() => _nightMode = saved);
  }

  Future<void> _setNightMode(bool value) async {
    setState(() => _nightMode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_nightModePrefKey, value);
  }

  static const _quranFontPrefKey = 'quran_reading_font_family';

  Future<void> _loadFontPref() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_quranFontPrefKey);
    if (saved != null && _quranFonts.containsKey(saved) && mounted) {
      setState(() => _quranFontFamily = saved);
    }
  }

  Future<void> _setFontFamily(String family) async {
    setState(() => _quranFontFamily = family);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quranFontPrefKey, family);
  }

  /// Same "don't crash if the sensor/platform doesn't support this" spirit
  /// as `qibla_screen.dart`'s `_initFusedHeading` — the page just stays
  /// static (no parallax) rather than throwing, on any device/platform
  /// where the rotation-vector sensor is unavailable.
  void _initTiltParallax() {
    try {
      _tiltSub = RotationSensor.orientationStream.listen(
        (event) {
          final now = DateTime.now();
          if (now.difference(_lastTiltUpdate).inMilliseconds < 150) return;
          _lastTiltUpdate = now;
          if (!mounted) return;
          setState(() {
            _tiltX = (event.eulerAngles.roll / (pi / 4)).clamp(-1.0, 1.0);
            _tiltY = (event.eulerAngles.pitch / (pi / 4)).clamp(-1.0, 1.0);
          });
        },
        onError: (_) {},
      );
    } catch (_) {
      // Rotation sensor unsupported on this platform/device.
    }
  }

  Future<void> _loadJourneySummary() async {
    final status = await JourneyPlanRepository().status();
    if (!mounted || status == null) return;
    setState(() => _daysLeftToKhatm = status.goalStatus.daysLeft);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repo.savePosition(_page);
    _tiltSub?.cancel();
    _audioEngine.stop();
    _audioEngine.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _openReadingSessionSheet() async {
    if (_sessionTimer != null) {
      final stop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('جلسة القراءة جارية'),
          content: Text('باقٍ ${_sessionRemainingSeconds ~/ 60}:${(_sessionRemainingSeconds % 60).toString().padLeft(2, '0')} دقيقة — هل تريد إيقافها؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('استمرار')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إيقاف')),
          ],
        ),
      );
      if (stop == true) {
        setState(() {
          _sessionTimer?.cancel();
          _sessionTimer = null;
          _sessionTargetMinutes = null;
        });
      }
      return;
    }
    const options = [5, 10, 15, 20, 30];
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('كم دقيقة ستقرأ القرآن الآن؟', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('خطوة صغيرة كل يوم، أفضل من محاولة كبيرة لا تستمر', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: options.map((m) => ActionChip(label: Text('$m'), onPressed: () => Navigator.pop(context, m))).toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    await _readingSessionRepo.setTargetMinutes(chosen);
    if (!mounted) return;
    setState(() {
      _sessionTargetMinutes = chosen;
      _sessionRemainingSeconds = chosen * 60;
    });
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionRemainingSeconds <= 1) {
        timer.cancel();
        _completeReadingSession();
        return;
      }
      setState(() => _sessionRemainingSeconds--);
    });
  }

  Future<void> _completeReadingSession() async {
    final minutes = _sessionTargetMinutes;
    if (minutes == null) return;
    final lastCompleted = await _readingSessionRepo.lastCompletedMinutes();
    await _readingSessionRepo.recordCompletion(minutes);
    if (!mounted) return;
    final trend = lastCompleted == null
        ? ReadingTrend.first
        : minutes > lastCompleted
            ? ReadingTrend.improved
            : minutes == lastCompleted
                ? ReadingTrend.same
                : ReadingTrend.less;
    setState(() {
      _sessionTimer = null;
      _sessionTargetMinutes = null;
    });
    await _showReadingSessionCelebration(minutes, trend);
  }

  Future<void> _showReadingSessionCelebration(int minutes, ReadingTrend trend) async {
    final phrase = randomEncouragement(trend, LanguagePreferenceService.currentLanguage);
    final confetti = ConfettiController(duration: const Duration(seconds: 2));
    confetti.play();
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 16,
                gravity: 0.25,
                colors: const [AppColors.primary, AppColors.primaryDark, Color(0xFFB8860B), Colors.white],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_outlined, color: Color(0xFFB8860B), size: 36),
                  const SizedBox(height: 10),
                  Text('$minutes دقيقة', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                  const SizedBox(height: 8),
                  Text(phrase, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => Navigator.pop(context), child: const Text('الحمد لله')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    confetti.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _repo.savePosition(_page);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final page = await _repo.lastPage();
    final ayat = await _repo.ayatForPage(page);
    final polygons = await _loadAyahPolygonsForPage(page);
    if (!mounted) return;
    setState(() {
      _page = page;
      _ayat = ayat;
      _pagePolygons = polygons;
      _loading = false;
    });
    if (_showTafsir) _loadTafsir();
    _refreshPageFavoritedState();
  }

  Future<void> _goToPage(int page) async {
    if (page < 1) return;
    if (page > 604) {
      await _repo.completeKhatmAndRestart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بارك الله فيك — ختمت القرآن 🎉 نبدأ ختمة جديدة')));
      page = 1;
    }
    _audioEngine.stop();
    setState(() {
      _audioPlaying = false;
      _audioPaused = false;
    });
    await _repo.savePosition(page);
    final ayat = await _repo.ayatForPage(page);
    final polygons = await _loadAyahPolygonsForPage(page);
    if (!mounted) return;
    setState(() {
      _page = page;
      _ayat = ayat;
      _pagePolygons = polygons;
    });
    if (_showTafsir) _loadTafsir();
    _refreshPageFavoritedState();
  }

  /// "فضّل هذه الصفحة" (رواق الأيقونات الذهبي) — يبني فوق `isFavorite`/
  /// `addFavorite`/`removeFavorite` الموجودة فعليًا في
  /// `QuranReadingRepository`، لا آلية "مفضلة صفحة" منفصلة جديدة: الصفحة
  /// تُعتبَر مفضَّلة فقط إن كانت كل آياتها مفضَّلة فعليًا.
  Future<void> _refreshPageFavoritedState() async {
    if (_ayat.isEmpty) return;
    final results = await Future.wait(_ayat.map((a) => _repo.isFavorite(a.surah, a.ayah)));
    if (!mounted) return;
    setState(() => _pageFavorited = results.every((f) => f));
  }

  Future<void> _toggleFavoritePage() async {
    if (_ayat.isEmpty) return;
    if (_pageFavorited) {
      for (final a in _ayat) {
        await _repo.removeFavorite(a.surah, a.ayah);
      }
    } else {
      for (final a in _ayat) {
        await _repo.addFavorite(a.surah, a.ayah);
      }
    }
    if (!mounted) return;
    setState(() => _pageFavorited = !_pageFavorited);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_pageFavorited ? 'أُضيفت هذه الصفحة للمفضلة' : 'أُزيلت هذه الصفحة من المفضلة')),
    );
  }

  void _toggleAudioBar() {
    setState(() => _showAudioBar = !_showAudioBar);
    if (!_showAudioBar) {
      _audioEngine.stop();
      setState(() {
        _audioPlaying = false;
        _audioPaused = false;
      });
    }
  }

  /// يشغّل آيات الصفحة الحالية بدءًا من [startIndex] بالتتابع، آية بآية،
  /// عبر `QuranAudioEngine.playAyah` مباشرة (لا `playRange` — نحتاج تتبّع
  /// `_audioIndex` حيًا لتغذية الشريط بمكان التشغيل الفعلي). يتوقف بصمت إن
  /// غادر الطالب الصفحة أو أوقف التشغيل يدويًا أثناء الانتظار.
  Future<void> _playFrom(int startIndex) async {
    setState(() {
      _audioPlaying = true;
      _audioPaused = false;
      _audioIndex = startIndex;
    });
    for (var i = startIndex; i < _ayat.length; i++) {
      if (!mounted || !_audioPlaying) return;
      while (_audioPaused) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted || !_audioPlaying) return;
      }
      setState(() => _audioIndex = i);
      final a = _ayat[i];
      await _audioEngine.playAyah(_audioReciterId, a.surah, a.ayah);
    }
    if (mounted) setState(() => _audioPlaying = false);
  }

  void _playPauseAudio() {
    if (!_audioPlaying) {
      _playFrom(_audioIndex);
    } else {
      final pausing = !_audioPaused;
      setState(() => _audioPaused = pausing);
      if (pausing) {
        _audioEngine.pause();
      } else {
        _audioEngine.resume();
      }
    }
  }

  void _nextAudioAyah() {
    _audioEngine.stop();
    if (_audioIndex < _ayat.length - 1) _playFrom(_audioIndex + 1);
  }

  void _prevAudioAyah() {
    _audioEngine.stop();
    if (_audioIndex > 0) _playFrom(_audioIndex - 1);
  }

  Future<void> _pickReciter() async {
    final reciters = QuranAudioProviderRegistry.reciters();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: reciters
            .map((r) => ListTile(
                  title: Text(r.nameAr, textAlign: TextAlign.right),
                  trailing: r.id == _audioReciterId ? Icon(Icons.check, color: _goldColor) : null,
                  onTap: () => Navigator.pop(context, r.id),
                ))
            .toList(),
      ),
    );
    if (picked == null) return;
    _audioEngine.stop();
    setState(() {
      _audioReciterId = picked;
      _audioPlaying = false;
      _audioPaused = false;
    });
  }

  Future<void> _pickFontSize() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('حجم الخط', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: TextScalePreferenceService.presets.map((scale) {
                  final selected = TextScalePreferenceService.scaleNotifier.value == scale;
                  return ChoiceChip(
                    label: Text(TextScalePreferenceService.presetLabels[scale] ?? '$scale'),
                    selected: selected,
                    onSelected: (_) {
                      TextScalePreferenceService.setScale(scale);
                      setSheetState(() {});
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadTafsir() async {
    final tafsir = await _repo.tafsirForPage(_page, _tafsirSource);
    if (!mounted) return;
    setState(() => _tafsirByAyah = tafsir);
  }

  Future<void> _openSearch() async {
    final page = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const QuranSearchScreen()));
    if (page != null) _goToPage(page);
  }

  void _openBrowseForCurrentPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => QuranBrowseScreen(highlightUnitId: _page)));
  }

  /// نقطة تنقّل سريعة ثانية (أماكن أخرى غير الفهرس): اضغط رقم الصفحة في
  /// الأعلى لقفزة مباشرة، بلا فتح ورقة الفهرس الكاملة.
  Future<void> _quickPageJumpDialog() async {
    final ctrl = TextEditingController(text: '$_page');
    final page = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اذهب إلى صفحة'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          decoration: const InputDecoration(hintText: '1-604'),
          onSubmitted: (v) {
            final p = int.tryParse(v);
            if (p != null && p >= 1 && p <= 604) Navigator.pop(context, p);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(ctrl.text);
              if (p != null && p >= 1 && p <= 604) Navigator.pop(context, p);
            },
            child: const Text('اذهب'),
          ),
        ],
      ),
    );
    if (page != null) _goToPage(page);
  }

  void _openJourney() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const JourneyScreen()));
  }

  void _notAvailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$feature" لا يوجد لها مصدر بيانات موثوق بعد — لم تُضَف حتى لا نخترعها')),
    );
  }

  /// "الفهرس" — تنقّل عبر 3 طرق (Ismail's request 2026-08-16: "أريد
  /// التنقل بين صفحات القرآن وليس السور فقط... من الفهرس ومن أماكن
  /// أخرى"): السور (الأصلي)، الأجزاء (جديد — نفس الفكرة كثيرًا ما تُستخدم
  /// في المصحف الورقي الحقيقي لتصفح الأجزاء)، ورقم صفحة مباشر (جديد —
  /// أسرع طريق لصفحة معيّنة إن كان الطالب يعرف رقمها).
  Future<void> _openIndex() async {
    final pageCtrl = TextEditingController();
    final page = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DefaultTabController(
        length: 3,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (context, scrollController) => Column(
            children: [
              const Padding(padding: EdgeInsets.all(14), child: Text('الفهرس', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
              const TabBar(tabs: [Tab(text: 'السور'), Tab(text: 'الأجزاء'), Tab(text: 'رقم الصفحة')]),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView.builder(
                      controller: scrollController,
                      itemCount: quranSurahs.length,
                      itemBuilder: (context, i) {
                        final s = quranSurahs[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 14, backgroundColor: AppColors.primaryLight, child: Text('${s.number}', style: const TextStyle(fontSize: 10, color: AppColors.primaryDark))),
                          title: Text(s.name),
                          onTap: () async {
                            final p = await _repo.firstPageOfSurah(s.number);
                            if (context.mounted) Navigator.pop(context, p);
                          },
                        );
                      },
                    ),
                    ListView.builder(
                      itemCount: 30,
                      itemBuilder: (context, i) {
                        final juz = i + 1;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 14, backgroundColor: AppColors.primaryLight, child: Text('$juz', style: const TextStyle(fontSize: 10, color: AppColors.primaryDark))),
                          title: Text('الجزء $juz'),
                          onTap: () async {
                            final p = await _repo.firstPageOfJuz(juz);
                            if (context.mounted) Navigator.pop(context, p);
                          },
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('المصحف 604 صفحة — اكتب رقم الصفحة التي تريدها', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: pageCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(hintText: 'مثال: 250', border: OutlineInputBorder()),
                            onSubmitted: (v) {
                              final p = int.tryParse(v);
                              if (p != null && p >= 1 && p <= 604) Navigator.pop(context, p);
                            },
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              final p = int.tryParse(pageCtrl.text);
                              if (p != null && p >= 1 && p <= 604) Navigator.pop(context, p);
                            },
                            child: const Text('اذهب'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (page != null) _goToPage(page);
  }

  Future<void> _openFavorites() async {
    final favorites = await _repo.favoriteAyahs();
    if (!mounted) return;
    final page = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(14), child: Text('المفضلة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
            if (favorites.isEmpty) const Expanded(child: Center(child: Text('لم تُضِف أي آية للمفضلة بعد', style: TextStyle(color: AppColors.textMuted))))
            else Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: favorites.length,
                itemBuilder: (context, i) {
                  final f = favorites[i];
                  return ListTile(
                    title: Text(f.text, textAlign: TextAlign.right, style: TextStyle(fontFamily: _quranFontFamily, fontSize: 16)),
                    subtitle: Text('سورة ${_surahNames[f.surah] ?? f.surah} — آية ${f.ayah}', textAlign: TextAlign.right),
                    onTap: () => Navigator.pop(context, f.pageNumber),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (page != null) _goToPage(page);
  }

  Future<void> _openDisplayOptionsSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('طريقة عرض المصحف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              ListTile(leading: const Icon(Icons.list_alt_outlined), title: const Text('الفهرس'), onTap: () { Navigator.pop(context); _openIndex(); }),
              ListTile(leading: const Icon(Icons.search_rounded), title: const Text('البحث'), onTap: () { Navigator.pop(context); _openSearch(); }),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('حدّد ما حفظته من هذه الصفحة'),
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _openBrowseForCurrentPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.route_outlined),
                title: const Text('رحلتي ومدرب الحفظ'),
                subtitle: Text(
                  _daysLeftToKhatm == null
                      ? 'خطتك، تكليف اليوم، ووتيرتك المتكيفة'
                      : 'بقي ${_daysLeftToKhatm!} يومًا لختم القرآن حفظًا بإذن الله',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _openJourney());
                },
              ),
              ListTile(
                leading: Icon(_sessionTimer != null ? Icons.timer : Icons.timer_outlined),
                title: const Text('جلسة قراءة بوقت محدد'),
                subtitle: Text(
                  _sessionTimer != null
                      ? 'جارية — باقٍ ${_sessionRemainingSeconds ~/ 60}:${(_sessionRemainingSeconds % 60).toString().padLeft(2, '0')}'
                      : 'اختر عدد الدقائق، ونحتفل معك عند الإتمام',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _openReadingSessionSheet());
                },
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.menu_book_outlined),
                title: const Text('التفسير'),
                value: _showTafsir,
                onChanged: (v) {
                  setSheetState(() {});
                  setState(() => _showTafsir = v);
                  if (v) _loadTafsir();
                },
              ),
              ListTile(leading: const Icon(Icons.list, color: AppColors.textMuted), title: const Text('المعاني', style: TextStyle(color: AppColors.textMuted)), onTap: () => _notAvailable('المعاني')),
              ListTile(
                leading: const Icon(Icons.headphones_outlined),
                title: const Text('التحفيظ الصوتي'),
                subtitle: const Text('استماع وتكرار بصوت القارئ لحفظ نطاق آيات', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => Navigator.push(context, MaterialPageRoute(builder: (_) => const TahfeezSessionSetupScreen())),
                  );
                },
              ),
              ListTile(leading: const Icon(Icons.translate_outlined, color: AppColors.textMuted), title: const Text('الترجمة', style: TextStyle(color: AppColors.textMuted)), onTap: () => _notAvailable('الترجمة')),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.nightlight_outlined),
                title: const Text('الوضع الليلي'),
                value: _nightMode,
                onChanged: (v) {
                  setSheetState(() {});
                  _setNightMode(v);
                },
              ),
              // Picker UI only shows once a second real font option exists
              // again (see `_quranFonts`'s own doc comment) — a chip row
              // with a single always-selected entry is just clutter.
              if (_quranFonts.length > 1) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Align(alignment: Alignment.centerRight, child: Text('خط المصحف', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _quranFonts.entries.map((e) {
                    final selected = _quranFontFamily == e.key;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(e.value, style: TextStyle(fontFamily: e.key, fontSize: 15)),
                        selected: selected,
                        onSelected: (_) {
                          setSheetState(() {});
                          _setFontFamily(e.key);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Align(alignment: Alignment.centerRight, child: Text('لون مصحفك', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _themeColors.entries.map((e) {
                  final selected = _themeKey == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: () {
                        setSheetState(() {});
                        setState(() => _themeKey = e.key);
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: e.value.$1,
                        child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(),
              ListTile(leading: const Icon(Icons.bookmark_outline), title: const Text('المفضلة'), onTap: () { Navigator.pop(context); _openFavorites(); }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAyahTap(QuranAyahText a, TapDownDetails details) async {
    CompanionContextTracker.instance.setCurrentAyah(a.surah, a.ayah);
    setState(() {
      _selectedSurah = a.surah;
      _selectedAyah = a.ayah;
    });
    final isFav = await _repo.isFavorite(a.surah, a.ayah);
    if (!mounted) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(details.globalPosition, details.globalPosition),
      Offset.zero & overlay.size,
    );
    final lang = LanguagePreferenceService.currentLanguage;
    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(value: 'tafsir', child: ListTile(leading: const Icon(Icons.menu_book_outlined), title: Text(basicText('ayah_study_title', lang)), dense: true)),
        PopupMenuItem(value: 'recite', child: ListTile(leading: const Icon(Icons.mic_outlined), title: Text(basicText('recitation_practice_title', lang)), dense: true)),
        PopupMenuItem(value: 'translation', child: ListTile(leading: const Icon(Icons.translate_outlined, color: AppColors.textMuted), title: Text(basicText('translate_action', lang), style: const TextStyle(color: AppColors.textMuted)), dense: true)),
        PopupMenuItem(value: 'listen', child: ListTile(leading: const Icon(Icons.headphones_outlined, color: AppColors.textMuted), title: Text(basicText('listen_ayah_action', lang), style: const TextStyle(color: AppColors.textMuted)), dense: true)),
        PopupMenuItem(value: 'favorite', child: ListTile(leading: Icon(isFav ? Icons.bookmark : Icons.bookmark_outline), title: Text(isFav ? basicText('remove_from_favorites_action', lang) : basicText('add_to_favorites_action', lang)), dense: true)),
        PopupMenuItem(value: 'share', child: ListTile(leading: const Icon(Icons.share_outlined), title: Text(basicText('share_action', lang)), dense: true)),
      ],
    );
    if (!mounted) return;
    setState(() {
      _selectedSurah = null;
      _selectedAyah = null;
    });
    if (selected == null) return;
    switch (selected) {
      case 'tafsir':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => AyahStudyScreen(surah: a.surah, ayah: a.ayah)));
        break;
      case 'recite':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => RecitationPracticeScreen(surah: a.surah, ayah: a.ayah)));
        break;
      case 'translation':
        await _pickTranslationLanguage(a);
        break;
      case 'listen':
        _notAvailable('الاستماع للآية');
        break;
      case 'favorite':
        if (isFav) {
          await _repo.removeFavorite(a.surah, a.ayah);
        } else {
          await _repo.addFavorite(a.surah, a.ayah);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFav ? 'أُزيلت من المفضلة' : 'أُضيفت للمفضلة')));
        break;
      case 'share':
        await Share.share('${a.text} (${_surahNames[a.surah] ?? a.surah}: ${a.ayah})');
        break;
    }
  }

  /// "الترجمة" shortcut on the ayah context menu (2026-08-25: Ismail
  /// flagged it was a dead stub) — lists every language this ayah actually
  /// has a stored translation/tafsir in, then jumps straight into
  /// `AyahStudyScreen`'s reader for that language's source instead of
  /// routing through the full source-card list.
  Future<void> _pickTranslationLanguage(QuranAyahText a) async {
    final lang = LanguagePreferenceService.currentLanguage;
    final entries = await _repo.tafsirEntriesForAyah(a.surah, a.ayah);
    if (!mounted) return;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(basicText('no_translation_available_for_ayah', lang))));
      return;
    }
    final sourceOrder = {for (var i = 0; i < QuranSearchRepository.tafsirSources.length; i++) QuranSearchRepository.tafsirSources[i].$1: i};
    entries.sort((x, y) => (sourceOrder[x.source] ?? 999).compareTo(sourceOrder[y.source] ?? 999));
    final seenLanguages = <String>{};
    final choices = <AyahTafsirEntry>[
      for (final e in entries)
        if (seenLanguages.add(e.language)) e,
    ];
    final chosen = await showModalBottomSheet<AyahTafsirEntry>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(basicText('pick_translation_language_title', lang), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: choices
                    .map((e) => ListTile(
                          title: Text(QuranSearchRepository.languageLabels[e.language] ?? e.language),
                          onTap: () => Navigator.pop(context, e),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AyahStudyScreen(surah: a.surah, ayah: a.ayah, initialSource: chosen.source)));
  }

  /// Builds the page as real justified lines — QURAN_COMPANION_ROADMAP.md
  /// Phase 71.2. Words are packed by `computeMushafPageLayout` (own
  /// word/line packer, shrinking font size to fit within a 15-line target;
  /// see `mushaf_page_layout.dart`) into `MushafLine`s, then each line
  /// renders as a `Row` with `MainAxisAlignment.spaceBetween` so it
  /// stretches to fill the page width edge-to-edge like a real printed
  /// Mushaf line, instead of the previous left-ragged flowing paragraphs.
  /// True line-for-line replication of the *official* Madinah Mushaf's
  /// exact 15-lines-per-page breaks would need that print's own
  /// line-break dataset, which isn't sourced into this app (see TODO.md
  /// Phase 71) — this is our own computed approximation of the same
  /// visual result, not a claim of pixel-identical official pagination.
  /// Real Madinah-Mushaf-derived page art (border + the actual justified
  /// Quran text, baked in as vector paths) for the small set of pages we
  /// have real source files for so far (2026-08-23: Ismail wants a direct,
  /// honest proof before scaling to all 604 — see the SVG source's own
  /// licensing notice for the King Fahd Complex's permissive digital-use
  /// grant). Ayah-tap/tafsir isn't available on these pages yet — there's
  /// no hit-region data in the source files — every other page keeps using
  /// the app's own real-text engine unchanged.
  static final _mushafBorderPages = {for (var p = 1; p <= 120; p++) p};

  String? _mushafBorderAssetPath(int page) {
    if (!_mushafBorderPages.contains(page)) return null;
    return 'assets/quran/mushaf_borders/${page.toString().padLeft(3, '0')}.svg';
  }

  /// Pages 1-2 keep a small centered text box inside a much more elaborate
  /// ornamental frame (real Mushaf opening-page convention) — less blank
  /// paper margin to safely zoom into than the ordinary pages (3+), which
  /// are mostly filled edge-to-edge already.
  /// Real per-ayah hit-region viewBox, page → (width, height) — pages 1-2
  /// are the ornate square-framed opening pages, page 3 is a normal
  /// running-text page in this source (2026-08-24, `svg2` sample set:
  /// Ismail's second source after the first one's justification didn't
  /// look real enough — see `svg2/00N.svg`'s own `viewBox`).
  static final _mushafViewBoxes = {
    1: (235.0, 235.0),
    2: (235.0, 235.0),
    for (var p = 3; p <= 120; p++) p: (345.0, 550.0),
  };

  double _mushafAspectRatioFor(int page) {
    final box = _mushafViewBoxes[page];
    if (box == null) return 510.236 / 729.448;
    return box.$1 / box.$2;
  }

  /// Real per-ayah tap regions for [page], parsed from the source's own
  /// polygon metadata (`assets/quran/mushaf_borders/00N.json` —
  /// `svg2/00N.json` in the raw drop Ismail gave, CC0 per its NOTICE.md).
  /// Only pages with a matching `.json` get real on-glyph tapping; a page
  /// asset without one (page 3 in this sample) just returns empty and
  /// falls back to the ayah-picker button.
  Future<List<_AyahPolygon>> _loadAyahPolygonsForPage(int page) async {
    final box = _mushafViewBoxes[page];
    if (box == null) return [];
    final path = 'assets/quran/mushaf_borders/${page.toString().padLeft(3, '0')}.json';
    try {
      final raw = await rootBundle.loadString(path);
      final list = jsonDecode(raw) as List;
      return list.map((e) => _AyahPolygon.fromJson(e as Map<String, dynamic>, box)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Maps a tap on the rendered (scaled/zoomed) SVG box back to the
  /// source's own viewBox space, then finds which ayah polygon contains
  /// it. `boxSize` is the GestureDetector's own render size (the
  /// AspectRatio-locked box, pre-zoom) — `Transform.scale`'s hit-testing
  /// already inverts the zoom for us, so `localPosition` arrives already
  /// in that box's coordinate space.
  void _handleMushafPageTap(TapDownDetails details, Size boxSize) {
    if (_pagePolygons.isEmpty || boxSize.width == 0 || boxSize.height == 0) return;
    final box = _mushafViewBoxes[_page];
    if (box == null) return;
    final vx = details.localPosition.dx / boxSize.width * box.$1;
    final vy = details.localPosition.dy / boxSize.height * box.$2;
    for (final poly in _pagePolygons) {
      if (poly.containsPoint(vx, vy)) {
        final match = _ayat.where((a) => a.surah == poly.surahNumber && a.ayah == poly.ayahNumber).firstOrNull;
        if (match != null) {
          // 2026-08-25 ("أريد عند الضغط أن تلمع الآية"): brief highlight so
          // tapping a real-art page gives the same instant feedback the
          // regular pages' word taps already do, before the menu opens.
          setState(() => _flashedPolygon = poly);
          Future.delayed(const Duration(milliseconds: 550), () {
            if (mounted && _flashedPolygon == poly) setState(() => _flashedPolygon = null);
          });
          _onAyahTap(match, details);
        }
        return;
      }
    }
  }

  /// Picks an ayah on the current (real-art) page, then opens the same
  /// Study screen every other page's ayah-tap opens — the honest stand-in
  /// for tap-on-glyph until these pages have real hit-region data.
  Future<void> _openAyahPickerForPage(BuildContext context) async {
    final lang = LanguagePreferenceService.currentLanguage;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: _ayat.length,
          itemBuilder: (context, i) {
            final a = _ayat[i];
            return ListTile(
              title: Text('${_surahNames[a.surah] ?? a.surah} — ${basicText('ayah_label', lang)} ${a.ayah}', textAlign: TextAlign.right),
              subtitle: Text(a.text, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AyahStudyScreen(surah: a.surah, ayah: a.ayah)));
              },
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContent(Color themeColor, Color textColor, double maxWidth) {
    if (_ayat.isEmpty) return [];

    final ayahByKey = {for (final a in _ayat) '${a.surah}:${a.ayah}': a};
    final layout = computeMushafPageLayout(ayat: _ayat, maxWidth: maxWidth, fontFamily: _quranFontFamily);

    final widgets = <Widget>[];
    for (final line in layout.lines) {
      if (line.words.first.startsNewSurah) {
        widgets.add(_SurahBanner(name: _surahNames[line.words.first.surah] ?? '${line.words.first.surah}', color: themeColor));
      }
      widgets.add(_buildLineRow(line, layout.fontSize, themeColor, textColor, ayahByKey));

      if (_showTafsir) {
        for (final word in line.words) {
          if (!word.isAyahEnd) continue;
          final tafsir = _tafsirByAyah['${word.surah}:${word.ayah}'];
          if (tafsir == null || tafsir.trim().isEmpty) continue;
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _nightMode ? const Color(0xFF1E1E1E) : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
              child: Text(tafsir, textAlign: TextAlign.right, style: TextStyle(fontSize: 13, height: 1.7, color: textColor)),
            ),
          ));
        }
      }
    }
    return widgets;
  }

  Widget _buildLineRow(MushafLine line, double fontSize, Color themeColor, Color textColor, Map<String, QuranAyahText> ayahByKey) {
    final children = <Widget>[];
    for (final word in line.words) {
      final isSelected = _selectedSurah == word.surah && _selectedAyah == word.ayah;
      final a = ayahByKey['${word.surah}:${word.ayah}'];
      Widget wordWidget = Text(
        word.text,
        style: TextStyle(
          fontFamily: _quranFontFamily,
          fontSize: fontSize,
          color: textColor,
          backgroundColor: isSelected ? themeColor.withValues(alpha: 0.18) : null,
        ),
      );
      if (a != null) {
        wordWidget = GestureDetector(onTapDown: (details) => _onAyahTap(a, details), child: wordWidget);
      }
      children.add(wordWidget);
      if (word.isAyahEnd) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: _AyahMedallion(number: word.ayah, color: themeColor, litUp: isSelected),
        ));
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: children.length > 1 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: children,
      ),
    );
  }

  // 2026-08-17: warm ivory/beige tokens pulled from a close read of the
  // reference (the "warmth" Ismail kept naming) — a background gradient
  // instead of one flat tone, and a warm brown ayah-text color instead of
  // the app's cooler blue-gray `AppColors.textDark` (kept as-is everywhere
  // else in the app; this warm tone is specific to the Mushaf page itself).
  static const _warmBgTop = Color(0xFFF5F0E6);
  static const _warmBgBottom = Color(0xFFEFE6D8);
  static const _warmAyahText = Color(0xFF2C221E);
  static const _warmShadowTint = Color(0xFF3A2E2B);

  @override
  Widget build(BuildContext context) {
    final themeColor = _themeColors[_themeKey]!.$1;
    final bgColor = _nightMode ? const Color(0xFF121212) : const Color(0xFFFBF6EE);
    final textColor = _nightMode ? Colors.white : _warmAyahText;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        // 2026-08-17 ("لا تخفِ البحث والهمبرجر"): the header is now ONE
        // compact line — search+menu always visible on the outer edge
        // (left, in this RTL app's `actions`), a single-line surah/juz/page
        // string centered, and the page-nav arrow on the other edge
        // (`leading`). Nothing here was deleted, only shrunk: the big
        // two-line ribbon-badge title became one Text line, and the
        // standalone bookmark button that used to sit next to the arrow was
        // dropped because it's a pure duplicate of the page's own rail
        // bookmark (`Positioned(right: 0, ...)` further down) — same
        // `_toggleFavoritePage`/`_pageFavorited`, still one tap away, just
        // not doubled up in the header too.
        toolbarHeight: 48,
        title: GestureDetector(
          onTap: _quickPageJumpDialog,
          child: Text(
            _ayat.isEmpty
                ? 'صفحة $_page'
                : 'سورة ${_surahNames[_ayat.first.surah] ?? _ayat.first.surah}  •  الجزء ${_ayat.first.juzNumber ?? '-'}  •  الصفحة $_page',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        centerTitle: true,
        // `leading` renders on the visual RIGHT in this RTL app, matching
        // point 12's "يمين الشاشة: أزرار التنقل بين الصفحات" — kept as a
        // second way to reach the next page alongside the swipe, just
        // smaller now that it's alone.
        leadingWidth: 44,
        leading: Padding(
          padding: const EdgeInsets.only(right: 6),
          // `arrow_forward_rounded` renders pointing left on-device in this
          // RTL app — `arrow_back_rounded` is what actually renders
          // pointing right.
          child: _GoldCircleIcon(icon: Icons.arrow_back_rounded, size: 30, onTap: () => _goToPage(_page + 1)),
        ),
        // Point 11/15: search and the ☰ menu (which opens the sheet with
        // الفهرس/البحث/رحلتي/التحفيظ/الوضع الليلي/... — this app's actual
        // "side menu of functions") stay put on the outer left edge, always
        // visible, never collapsed behind anything else.
        actions: [
          _GoldCircleIcon(icon: Icons.search_rounded, size: 30, onTap: _openSearch),
          const SizedBox(width: 6),
          _GoldCircleIcon(icon: Icons.menu_rounded, size: 30, onTap: _openDisplayOptionsSheet),
          const SizedBox(width: 10),
        ],
      ),
      body: _loading
          ? const AppLoadingView(icon: Icons.menu_book_outlined, message: 'جاري تحميل صفحة المصحف...')
          : Container(
              // Warm ivory→beige gradient instead of one flat tone — the
              // "warmth" Ismail kept naming turned out to be a real,
              // fixable background choice, not something abstract.
              decoration: _nightMode
                  ? null
                  : const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_warmBgTop, _warmBgBottom]),
                    ),
              child: Column(
              children: [
                // 2026-08-17 (point 13, "لا تحذف الوظائف — أعد توزيعها"): the
                // full-width "رحلتي" glass banner used to sit right here,
                // stealing a whole row above the Mushaf page. It wasn't
                // deleted — `_openJourney` is still one tap away from the ☰
                // menu's "رحلتي ومدرب الحفظ" entry (now showing the same
                // live day-countdown this banner used to), which is a more
                // efficient spot for something that doesn't need to be
                // visible while actually reading.
                if (_showTafsir)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('اللغة: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            DropdownButton<String>(
                              isDense: true,
                              value: _tafsirLanguage,
                              underline: const SizedBox.shrink(),
                              items: QuranSearchRepository.languageLabels.entries
                                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12.5))))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                final firstForLanguage = QuranSearchRepository.tafsirSources.firstWhere((s) => s.$3 == v);
                                setState(() {
                                  _tafsirLanguage = v;
                                  _tafsirSource = firstForLanguage.$1;
                                });
                                _loadTafsir();
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('التفسير: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Expanded(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                isDense: true,
                                value: _tafsirSource,
                                underline: const SizedBox.shrink(),
                                items: QuranSearchRepository.tafsirSources
                                    .where((s) => s.$3 == _tafsirLanguage)
                                    .map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2, style: const TextStyle(fontSize: 12.5))))
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _tafsirSource = v);
                                  _loadTafsir();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  // 2026-08-17 ("عشان تحصل مساحة أكبر"): swipe replaces the
                  // removed الصفحة التالية/السابقة button row — same
                  // right-to-left reading direction as physically turning a
                  // Mushaf page: a drag toward the left (negative velocity)
                  // advances to the next page, a drag toward the right goes
                  // back. `_goToPage` already handles saving position,
                  // stopping any playing audio, and refreshing the favorite
                  // state — reused as-is, only the trigger changed.
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      // 2026-08-17: reversed per Ismail's feedback — same
                      // direction correction the adhkar screen's swipe
                      // needed earlier this session.
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity > 200) {
                        _goToPage(_page + 1);
                      } else if (velocity < -200) {
                        _goToPage(_page - 1);
                      }
                    },
                    child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 2026-08-17: this used to be a plain (non-positioned)
                      // Stack child — a real regression from adding this
                      // outer Stack for the rails. A non-positioned Stack
                      // child gets LOOSE constraints (sized to its own
                      // content, then centered by `alignment`), whereas
                      // before this page container was `Expanded`'s direct
                      // child and got forced to fill the full height. Since
                      // the page's inner content (`SingleChildScrollView`)
                      // sizes to its own text, not to available space, the
                      // page was shrinking to text height and floating in
                      // the middle of the available area — exactly the
                      // "big empty margins above/below the frame" gap
                      // Ismail caught. `Positioned.fill` forces it back to
                      // filling the Stack completely, like before.
                      Builder(builder: (context) {
                        final borderAsset = _mushafBorderAssetPath(_page);
                        final Widget card = Container(
                        // 2026-08-17 ("وسع الجوانب الى الاخير"): was
                        // `horizontal: 40` — sized to leave room for the
                        // left/right icon rails that used to float beside
                        // the page. Those rails moved into one bottom
                        // toolbar row below (see the row that replaced the
                        // old audio-toggle-only bottom bar), so nothing
                        // needs that side clearance anymore — the page can
                        // use almost the full screen width.
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          // "طابع الـ3D" (quirky-gliding-shell.md) — the page
                          // container's color previously matched the Scaffold's
                          // `backgroundColor` exactly (both `bgColor`), so there
                          // was literally no depth cue besides the thin frame
                          // painter lines. A real layered shadow (soft dark lift
                          // + a warm tint from the current theme color) finally
                          // separates the "page" from its surroundings, the way
                          // a physical Mushaf actually sits above a table.
                          boxShadow: [
                            BoxShadow(color: _warmShadowTint.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // A living-light effect tied to the phone's real
                              // tilt (`_tiltX`/`_tiltY`) instead of a mouse,
                              // which doesn't exist on a touch device — subtle
                              // by design, an ambient cue not a gimmick.
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Align(
                                    alignment: Alignment(_tiltX * 0.6, -0.6 + _tiltY * 0.4),
                                    child: Container(
                                      width: 260,
                                      height: 260,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: _nightMode ? 0.04 : 0.35),
                                            Colors.white.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Same non-positioned-Stack-child sizing issue
                              // as the outer page Container, one level in:
                              // without `Positioned.fill`, `CustomPaint`
                              // sizes itself to its content (the ayah text
                              // block), so the ornate frame it paints would
                              // only wrap the text, not the whole page —
                              // leaving a frame-less gap below on any page
                              // whose text doesn't reach the bottom.
                              Positioned.fill(
                                child: AnimatedSwitcher(
                                duration: AppMotion.premium,
                                switchInCurve: AppMotion.entranceCurve,
                                switchOutCurve: AppMotion.exitCurve,
                                transitionBuilder: (child, animation) => SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
                                  child: FadeTransition(opacity: animation, child: child),
                                ),
                                child: _mushafBorderAssetPath(_page) != null
                                    ? LayoutBuilder(
                                        key: ValueKey(_page),
                                        builder: (context, constraints) => InteractiveViewer(
                                          // 2026-08-25 ("تكبير الصفحه
                                          // بصبعين"): two-finger pinch only —
                                          // `panEnabled: false` so a single-
                                          // finger horizontal drag still
                                          // reaches the outer page-turn
                                          // swipe instead of being eaten by
                                          // panning a zoomed image.
                                          panEnabled: false,
                                          scaleEnabled: true,
                                          minScale: 1,
                                          maxScale: 4,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTapDown: (details) => _handleMushafPageTap(details, constraints.biggest),
                                            child: SizedBox(
                                              width: constraints.maxWidth,
                                              height: constraints.maxHeight,
                                              child: Stack(
                                                children: [
                                                  SvgPicture.asset(
                                                    _mushafBorderAssetPath(_page)!,
                                                    fit: BoxFit.fill,
                                                    width: constraints.maxWidth,
                                                    height: constraints.maxHeight,
                                                  ),
                                                  if (_flashedPolygon != null)
                                                    Positioned.fill(
                                                      child: IgnorePointer(
                                                        child: CustomPaint(
                                                          painter: _AyahFlashPainter(
                                                            polygon: _flashedPolygon!,
                                                            viewBox: _mushafViewBoxes[_page]!,
                                                            color: themeColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : CustomPaint(
                                        key: ValueKey(_page),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) => SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  ..._buildContent(themeColor, textColor, constraints.maxWidth),
                                                  const SizedBox(height: 6),
                                                  Center(child: _PageFooter(page: _page, color: themeColor)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              ),
                            ],
                          ),
                        ),
                      );
                        // 2026-08-23: these real-art pages have no per-ayah
                        // hit-region data (the source SVGs don't include
                        // one), so on-glyph tapping isn't possible yet — this
                        // button is the honest interim: real access to the
                        // same tafsir/translation study view every other
                        // page's ayah-tap opens, just picked by ayah number
                        // instead of by tapping the exact word.
                        return borderAsset != null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AspectRatio(aspectRatio: _mushafAspectRatioFor(_page), child: card),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: () => _openAyahPickerForPage(context),
                                    icon: const Icon(Icons.auto_stories_outlined, size: 18),
                                    label: Text(basicText('study_page_ayat_action', LanguagePreferenceService.currentLanguage)),
                                  ),
                                ],
                              )
                            : Positioned.fill(child: card);
                      }),
                      // شارة العد التنازلي لجلسة القراءة (2026-08-17) — لا
                      // تظهر إلا أثناء جلسة فعلية، ولا تحجز مساحة من الرأس
                      // المضغوط، عائمة فوق زاوية الصفحة نفسها فقط.
                      if (_sessionTimer != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: _openReadingSessionSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _goldColor.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: DepthShadows.soft(_goldColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_sessionRemainingSeconds ~/ 60}:${(_sessionRemainingSeconds % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                    ),
                  ),
                ),
                if (_showAudioBar) _AyahAudioBar(state: this, themeColor: themeColor),
                // 2026-08-17 ("وسع الجوانب الى الاخير — صف الايقونات في
                // الاسفل"): the two vertical icon rails that used to float
                // beside the page (الفهرس/طريقة العرض/الوضع الليلي/حجم
                // الخط/التفسير on the left, المفضلة on the right) moved
                // here, into one horizontal bottom toolbar alongside the
                // existing audio toggle — exactly the "Bottom Toolbar
                // للأدوات" point 14 asked for. Every one of those `onTap`
                // handlers is untouched, just relocated.
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _GoldRail(
                      axis: Axis.horizontal,
                      children: [
                        _GoldCircleIcon(icon: Icons.menu_book_outlined, size: 34, onTap: _openIndex),
                        _GoldCircleIcon(icon: Icons.settings_outlined, size: 34, onTap: _openDisplayOptionsSheet),
                        _GoldCircleIcon(
                          icon: _nightMode ? Icons.nightlight : Icons.nightlight_outlined,
                          size: 34,
                          onTap: () => _setNightMode(!_nightMode),
                        ),
                        _GoldCircleIcon(icon: Icons.text_fields_rounded, size: 34, onTap: _pickFontSize),
                        _GoldCircleIcon(
                          icon: Icons.auto_stories_outlined,
                          size: 34,
                          onTap: () {
                            setState(() => _showTafsir = !_showTafsir);
                            if (_showTafsir) _loadTafsir();
                          },
                        ),
                        _GoldCircleIcon(
                          icon: _pageFavorited ? Icons.bookmark : Icons.bookmark_outline,
                          size: 34,
                          onTap: _toggleFavoritePage,
                        ),
                        _GoldCircleIcon(
                          icon: _showAudioBar ? Icons.headset_off_outlined : Icons.headset_outlined,
                          size: 34,
                          onTap: _toggleAudioBar,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              ),
            ),
    );
  }
}

String _easternArabicDigits(int n) {
  const western = '0123456789';
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) {
    final i = western.indexOf(c);
    return i == -1 ? c : eastern[i];
  }).join();
}

/// Original ornamental ayah-number marker — a small circle ringed with
/// petal-like bumps, drawn from scratch with `CustomPainter` (not traced
/// from any Mushaf font's glyph artwork) — replaces the plain "﴿30﴾"
/// bracket-number the reading screen used before Ismail's 2026-08-16 "طبق
/// الأصل" request for a page that looks like an actual printed Mushaf.
class _AyahMedallion extends StatelessWidget {
  final int number;
  final Color color;
  final bool litUp;
  const _AyahMedallion({required this.number, required this.color, required this.litUp});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _MedallionPainter(color: litUp ? color : color.withValues(alpha: 0.7)),
        child: Center(
          child: Text(_easternArabicDigits(number), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  final Color color;
  const _MedallionPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 2026-08-20 ("i want the style to be like this i didn't like my
    // style"): reverted from the 2026-08-17 richness pass (filled gradient
    // rosette with 8 petal bumps) back toward a plain thin outline ring,
    // matching the reference Mushaf's delicate, mostly-empty ayah-end
    // marks instead of a jeweled badge. Still tinted by the student's own
    // "لون مصحفك" choice, not hardcoded gold.
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(center, r * 0.92, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..color = color);
    canvas.drawCircle(center, r * 0.7, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = color);
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter oldDelegate) => oldDelegate.color != color;
}

/// Hexagonal ribbon-shaped badge (pointed left/right ends via `ClipPath`) —
/// used for the surah-name/juz-page header pills and the in-page surah
/// banner, echoing the reference app's ornate banner shapes with original
/// geometry rather than a copied asset.
class _RibbonBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool large;
  const _RibbonBadge({required this.text, required this.color, this.large = false});

  @override
  Widget build(BuildContext context) {
    // 2026-08-17: was a flat single-tone fill with no outline — the
    // reference's title/juz-page ribbons read as small gold-bordered
    // jewelry pieces (soft gradient + a real gold edge), not a plain tint.
    // 2026-08-23: Ismail wanted this "فخم" (grand) like a traditional
    // Islamic ornament — added an inner hairline border (a real jeweled
    // banner reads as two nested edges, not one) and a small gold diamond
    // stud at each pointed tip.
    return Container(
      decoration: BoxDecoration(boxShadow: DepthShadows.soft(_goldColor)),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: const _RibbonClipper(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: large ? 26 : 18, vertical: large ? 9 : 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.surface, color.withValues(alpha: 0.14)],
                ),
                border: Border.all(color: _goldColor.withValues(alpha: 0.65), width: 1.4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border.all(color: _goldColor.withValues(alpha: 0.32), width: 0.8)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Text(text, style: TextStyle(fontSize: large ? 14 : 13, fontWeight: FontWeight.w800, color: color)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: large ? -4 : -2, child: _RibbonStud(size: large ? 7 : 5)),
          Positioned(right: large ? -4 : -2, child: _RibbonStud(size: large ? 7 : 5)),
        ],
      ),
    );
  }
}

/// Small gold diamond stud marking a ribbon's pointed tip — the jeweled
/// detail that separates a plain hexagon from an ornamental Islamic banner.
class _RibbonStud extends StatelessWidget {
  final double size;
  const _RibbonStud({required this.size});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _goldColor,
          border: Border.all(color: _goldColor.withValues(alpha: 0.5), width: 0.6),
          boxShadow: [BoxShadow(color: _goldColor.withValues(alpha: 0.4), blurRadius: 3)],
        ),
      ),
    );
  }
}

/// One ayah's real tap region on a `svg2`-sourced mushaf page — the raw
/// `"x1,y1 x2,y2 ..."` polygon string from the source JSON, parsed once
/// and hit-tested via ray casting (the source's polygons are simple but
/// often L-shaped/multi-segment for a justified line that wraps a medallion
/// or a margin note, so a plain bounding-box test would misfire on those).
class _AyahPolygon {
  final int surahNumber;
  final int ayahNumber;
  final List<Offset> points;
  const _AyahPolygon({required this.surahNumber, required this.ayahNumber, required this.points});

  factory _AyahPolygon.fromJson(Map<String, dynamic> json, (double, double) viewBox) {
    final raw = (json['polygon'] as String).trim().split(RegExp(r'\s+'));
    final points = raw.map((pair) {
      final parts = pair.split(',');
      return Offset(double.parse(parts[0]), double.parse(parts[1]));
    }).toList();
    return _AyahPolygon(surahNumber: json['surahNumber'] as int, ayahNumber: json['ayahNumber'] as int, points: points);
  }

  bool containsPoint(double x, double y) {
    var inside = false;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      final pi = points[i], pj = points[j];
      final intersects = (pi.dy > y) != (pj.dy > y) && x < (pj.dx - pi.dx) * (y - pi.dy) / (pj.dy - pi.dy) + pi.dx;
      if (intersects) inside = !inside;
    }
    return inside;
  }
}

/// Brief translucent fill over the tapped ayah's real polygon — the visual
/// feedback Ismail asked for (2026-08-25: "أريد عند الضغط أن تلمع الآية")
/// so tapping a real-art page confirms which ayah registered before the
/// menu opens, the same instant feedback regular pages' word taps give.
class _AyahFlashPainter extends CustomPainter {
  final _AyahPolygon polygon;
  final (double, double) viewBox;
  final Color color;
  const _AyahFlashPainter({required this.polygon, required this.viewBox, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / viewBox.$1;
    final sy = size.height / viewBox.$2;
    final path = Path()..addPolygon(polygon.points.map((p) => Offset(p.dx * sx, p.dy * sy)).toList(), true);
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.28));
  }

  @override
  bool shouldRepaint(covariant _AyahFlashPainter oldDelegate) => oldDelegate.polygon != polygon || oldDelegate.color != color;
}

class _RibbonClipper extends CustomClipper<Path> {
  const _RibbonClipper();

  @override
  Path getClip(Size size) {
    final notch = size.height * 0.28;
    return Path()
      ..moveTo(notch, 0)
      ..lineTo(size.width - notch, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - notch, size.height)
      ..lineTo(notch, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SurahBanner extends StatelessWidget {
  final String name;
  final Color color;
  const _SurahBanner({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(child: _RibbonBadge(text: 'سورة $name', color: color, large: true)),
    );
  }
}

/// The page-foot ornament: a dotted rule on either side of the page-number
/// cartouche, echoing the dotted "leader lines" real printed Mushaf pages
/// use to lead the eye to the folio number — Ismail asked for this
/// specifically (2026-08-23: "رقم الصفحه لديها نقاط لمعرفه مكان التواجد").
class _PageFooter extends StatelessWidget {
  final int page;
  final Color color;
  const _PageFooter({required this.page, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DottedRule(color: color),
        const SizedBox(width: 10),
        _PageNumberCartouche(page: page, color: color),
        const SizedBox(width: 10),
        _DottedRule(color: color),
      ],
    );
  }
}

class _DottedRule extends StatelessWidget {
  final Color color;
  const _DottedRule({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 60, height: 6, child: CustomPaint(painter: _DottedRulePainter(color: color)));
  }
}

class _DottedRulePainter extends CustomPainter {
  final Color color;
  const _DottedRulePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.5);
    const dotRadius = 1.6;
    const gap = 8.0;
    for (var x = dotRadius; x < size.width; x += gap) {
      canvas.drawCircle(Offset(x, size.height / 2), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedRulePainter oldDelegate) => oldDelegate.color != color;
}

/// Double-ring page-number cartouche at the bottom of the page frame, with
/// a small gold sun-rosette of studs around the rim for a richer, more
/// jeweled read (2026-08-23: Ismail wanted the page number itself more
/// "فخم" — the plain double ring alone read as too bare).
class _PageNumberCartouche extends StatelessWidget {
  final int page;
  final Color color;
  const _PageNumberCartouche({required this.page, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 8; i++)
            Transform.rotate(
              angle: i * (pi / 4),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _goldColor.withValues(alpha: 0.75)),
                ),
              ),
            ),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.3)),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.5), width: 1)),
              child: Text(_easternArabicDigits(page), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A richer gold circular button, specific to this screen (not the shared
/// `DepthIconButton`, which stays calm/neutral for the rest of the app —
/// `DESIGN_SYSTEM_3D.md` itself says القرآن gets the deepest treatment of
/// any section). 2026-08-17: Ismail compared against the reference and
/// called the plain flat-tinted circles out directly — this replaces them
/// with a real radial highlight (light source top-left, like the
/// reference's embossed look), a warmer two-stop gold ring instead of a
/// single flat stroke, and a stronger layered shadow so it reads as
/// polished metal/jewelry, not a flat icon with a gold tint.
class _GoldCircleIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _GoldCircleIcon({required this.icon, required this.onTap, this.size = 40});

  @override
  State<_GoldCircleIcon> createState() => _GoldCircleIconState();
}

class _GoldCircleIconState extends State<_GoldCircleIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // 2026-08-17 crash fix: the gold ring used to be a custom `BoxBorder`
    // subclass set on this `AnimatedContainer`'s `decoration`. Flutter's
    // implicit-animation machinery calls the STATIC `BoxDecoration.lerp`
    // on every rebuild (even when nothing actually changed), and that
    // only knows how to interpolate the built-in `Border`/`BorderDirectional`
    // types — any other `BoxBorder` subclass throws
    // ("BoxBorder.lerp can only interpolate Border and BorderDirectional
    // classes"), which crashed this exact screen on-device. Fixed by
    // moving the gradient ring out of the animated `decoration` entirely
    // and drawing it with a `CustomPaint` `foregroundPainter` instead —
    // painting isn't subject to that interpolation restriction at all.
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.stateCurve,
        width: widget.size,
        height: widget.size,
        transform: _pressed ? (Matrix4.identity()..scaleByDouble(0.94, 0.94, 0.94, 1.0)) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.1,
            colors: [AppColors.surface, const Color(0xFFF6E9CE)],
          ),
          boxShadow: _pressed
              ? DepthShadows.soft(_goldColor)
              : [
                  ...DepthShadows.floating(_goldColor),
                  BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 1, offset: const Offset(-1, -1)),
                ],
        ),
        child: CustomPaint(
          painter: _GoldRingPainter(),
          child: Center(child: Icon(widget.icon, color: _goldColor, size: widget.size * 0.46)),
        ),
      ),
    );
  }
}

/// Draws the two-tone gold ring (brighter top-left, as if lit) as a normal
/// `Canvas` stroke — see `_GoldCircleIconState`'s doc comment for why this
/// replaced a custom `BoxBorder` subclass.
class _GoldRingPainter extends CustomPainter {
  const _GoldRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_goldColor.withValues(alpha: 0.95), _goldColor.withValues(alpha: 0.45)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawCircle(rect.center, (size.shortestSide - 1.3) / 2, paint);
  }

  @override
  bool shouldRepaint(covariant _GoldRingPainter oldDelegate) => false;
}

/// The floating gold icon-rail container (quirky-gliding-shell.md's
/// "الإطار الحقيقي" batch) — a translucent pill holding a vertical stack
/// of `DepthIconButton`s along a page edge, with its own soft depth so it
/// reads as a physically separate floating strip rather than icons glued
/// onto the page.
class _GoldRail extends StatelessWidget {
  final List<Widget> children;
  final Axis axis;
  const _GoldRail({required this.children, this.axis = Axis.vertical});

  @override
  Widget build(BuildContext context) {
    // 2026-08-17: was one pill-shaped container behind all the buttons —
    // the reference actually shows each button as its OWN separate
    // floating circle (individual shadow, visible gaps of page showing
    // through between them), not one connected background strip. Each
    // `DepthIconButton` already draws its own circle + shadow, so this is
    // now just spacing, no shared background.
    //
    // `axis: Axis.horizontal` (added for the bottom toolbar row) reuses the
    // same spacing idea sideways instead of stacking top-to-bottom, wrapped
    // in `Wrap` + `Center` so it still lines up nicely if a narrow screen
    // ever forces it to break into two lines.
    final spaced = [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 14, width: 14), children[i]]];
    if (axis == Axis.vertical) {
      return Column(mainAxisSize: MainAxisSize.min, children: spaced);
    }
    return Center(child: Wrap(alignment: WrapAlignment.center, runSpacing: 10, children: spaced));
  }
}

/// شريط الاستماع العائم (quirky-gliding-shell.md's "الإطار الحقيقي" batch)
/// — قارئ حقيقي (`QuranAudioProviderRegistry.reciters()`)، تحكم حقيقي
/// (تشغيل/إيقاف مؤقت/تالٍ/سابق) مبني فوق `QuranAudioEngine.playAyah`،
/// وتسمية موضع حيّة "سورة:آية — سورة:آية" بدل شريط تقدّم نسبي مُخترَع.
/// يقرأ حقول `_QuranReadingScreenState` مباشرة (نفس الملف) بدل تكرار
/// الحالة في ودجت منفصل.
class _AyahAudioBar extends StatelessWidget {
  final _QuranReadingScreenState state;
  final Color themeColor;
  const _AyahAudioBar({required this.state, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final reciters = QuranAudioProviderRegistry.reciters();
    final currentReciter = reciters.firstWhere((r) => r.id == state._audioReciterId, orElse: () => reciters.first);
    final hasAyat = state._ayat.isNotEmpty;
    final currentAyah = hasAyat ? state._ayat[state._audioIndex.clamp(0, state._ayat.length - 1)] : null;
    final lastAyah = hasAyat ? state._ayat.last : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: _goldColor.withValues(alpha: 0.25)),
        boxShadow: DepthShadows.floating(_goldColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              InkWell(
                onTap: state._pickReciter,
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundColor: _goldColor.withValues(alpha: 0.15), child: Icon(Icons.mic_none_rounded, size: 16, color: _goldColor)),
                    const SizedBox(width: 8),
                    Text(currentReciter.nameAr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(icon: Icon(Icons.skip_next_rounded), color: _goldColor, onPressed: hasAyat ? state._nextAudioAyah : null),
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: _goldColor),
                child: IconButton(
                  icon: Icon(state._audioPlaying && !state._audioPaused ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                  onPressed: hasAyat ? state._playPauseAudio : null,
                ),
              ),
              IconButton(icon: Icon(Icons.skip_previous_rounded), color: _goldColor, onPressed: hasAyat ? state._prevAudioAyah : null),
            ],
          ),
          if (currentAyah != null && lastAyah != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_easternArabicDigits(currentAyah.surah)}:${_easternArabicDigits(currentAyah.ayah)}  —  ${_easternArabicDigits(lastAyah.surah)}:${_easternArabicDigits(lastAyah.ayah)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
