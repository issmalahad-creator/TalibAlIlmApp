import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../models/mushaf_layout.dart';
import '../models/quran_selection.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/quran_reading_session_repository.dart';
import '../services/language_preference_service.dart';
import '../services/quran_audio/quran_audio_provider_registry.dart';
import '../services/quran_audio_engine.dart';
import '../widgets/companion_floating_bubble.dart';
import '../widgets/mushaf_page_view.dart';
import '../theme/app_theme.dart';
import 'ayah_notebook_screen.dart';
import 'journey_screen.dart';
import 'page_recitation_screen.dart';
import 'quran_browse_screen.dart';
import 'quran_notebook_home_screen.dart';
import 'quran_search_screen.dart';
import 'recitation_mistakes_screen.dart';
import 'tahfeez_session_setup_screen.dart';
import 'quran_learning/knowledge_surface.dart';
import 'quran_learning/sources_screen.dart';
import 'quran_learning/topic_index_screen.dart';

/// خطة القارئ الموحّد — the one Quran reader, built on the Mushaf **Semantic
/// Layer** (`mushaf_*` → [MushafLayoutRepository] → [MushafPageView]) with
/// real MushafDatabase V1.01 art on all 604 pages.
///
/// P0 scope: browse 604 pages + the central [QuranSelection] + the two
/// Knowledge Surfaces. A single page-level hit-test resolves a tap to a
/// word body or a verse-end medallion — never proximity:
///   * word body  → `QuranSelection.word`  → Word Knowledge Surface
///   * medallion  → `QuranSelection.ayah`  → Ayah Knowledge Surface
///   * long-press → the ayah notebook (future ayah-panel shortcut)
class MushafSemanticReaderScreen extends StatefulWidget {
  final int initialPage; // 1..604

  const MushafSemanticReaderScreen({super.key, this.initialPage = 1});

  @override
  State<MushafSemanticReaderScreen> createState() =>
      _MushafSemanticReaderScreenState();
}

class _MushafSemanticReaderScreenState
    extends State<MushafSemanticReaderScreen> {
  static const _pageCount = 604;
  final _repo = MushafLayoutRepository();
  final _cache = <int, MushafPageLayout?>{};
  late final PageController _controller;
  late int _current;
  bool? _ready;

  static const _nightPrefKey = 'quran_reading_night_mode';
  static const _reciterPrefKey = 'quran_reading_reciter';
  bool _night = false;

  /// The one selection on the page — drives the Selection Layer and which
  /// surface is open. Cleared when a surface is dismissed.
  MushafWord? _selWord;
  MushafAyaMark? _selMark;

  // ── listen bar (استماع لقارئ — NOT tasmeeʿ / recitation-follow) ──────
  final _audio = QuranAudioEngine();
  bool _audioBar = false;
  bool _playing = false;
  bool _paused = false;
  int _audioIdx = 0;
  String _reciterId = QuranAudioProviderRegistry.reciters().first.id;

  /// The ayah currently being recited — highlighted on the page while it plays.
  ({int surah, int ayah})? _playingAyah;

  // ── timed reading session ──────────────────────────────────────────
  final _sessionRepo = QuranReadingSessionRepository();
  Timer? _sessionTimer;
  int _sessionRemaining = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialPage.clamp(1, _pageCount);
    _controller = PageController(initialPage: _current - 1);
    // Full-bleed reading surface — keep the floating companion bubble off
    // the page and its app bar while we're here.
    CompanionFloatingBubble.suppressed.value++;
    _repo.isReady().then((r) {
      if (mounted) setState(() => _ready = r);
    });
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool(_nightPrefKey);
      if (v != null && mounted) setState(() => _night = v);
    });
  }

  Future<void> _setNight(bool v) async {
    setState(() => _night = v);
    (await SharedPreferences.getInstance()).setBool(_nightPrefKey, v);
  }

  @override
  void dispose() {
    CompanionFloatingBubble.suppressed.value--;
    _sessionTimer?.cancel();
    _audio.stop();
    _controller.dispose();
    super.dispose();
  }

  // ── listen bar ────────────────────────────────────────────────────

  Future<void> _toggleAudioBar() async {
    if (_audioBar) {
      _audio.stop();
      setState(() {
        _audioBar = false;
        _playing = false;
        _paused = false;
        _playingAyah = null;
      });
      return;
    }
    final saved =
        (await SharedPreferences.getInstance()).getString(_reciterPrefKey);
    if (saved != null &&
        QuranAudioProviderRegistry.reciters().any((r) => r.id == saved)) {
      _reciterId = saved;
    }
    if (mounted) setState(() => _audioBar = true);
  }

  List<({int surah, int ayah})> get _pageAyat =>
      _cache[_current]?.ayat ?? const [];

  Future<void> _playFrom(int start) async {
    final ayat = _pageAyat;
    if (ayat.isEmpty) return;
    setState(() {
      _playing = true;
      _paused = false;
      _audioIdx = start.clamp(0, ayat.length - 1);
    });
    for (var i = _audioIdx; i < ayat.length; i++) {
      if (!mounted || !_playing) return;
      while (_paused) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!mounted || !_playing) return;
      }
      setState(() {
        _audioIdx = i;
        _playingAyah = ayat[i];
      });
      await _audio.playAyah(_reciterId, ayat[i].surah, ayat[i].ayah);
    }
    if (mounted) {
      setState(() {
        _playing = false;
        _playingAyah = null;
      });
    }
  }

  void _playPause() {
    if (!_playing) {
      _playFrom(_audioIdx);
    } else {
      setState(() => _paused = !_paused);
      if (_paused) {
        _audio.pause();
      } else {
        _audio.resume();
      }
    }
  }

  void _stepAudio(int delta) {
    _audio.stop();
    final next = _audioIdx + delta;
    if (next >= 0 && next < _pageAyat.length) _playFrom(next);
  }

  Future<void> _pickReciter(String lang) async {
    final reciters = QuranAudioProviderRegistry.reciters();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final r in reciters)
              ListTile(
                dense: true,
                title: Text(r.nameAr, textDirection: TextDirection.rtl),
                trailing: r.id == _reciterId
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, r.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _audio.stop();
    setState(() {
      _reciterId = picked;
      _playing = false;
      _paused = false;
      _playingAyah = null;
    });
    (await SharedPreferences.getInstance()).setString(_reciterPrefKey, picked);
  }

  // ── timed reading session ────────────────────────────────────────

  Future<void> _openSessionSheet(String lang) async {
    if (_sessionTimer != null) {
      setState(() {
        _sessionTimer?.cancel();
        _sessionTimer = null;
        _sessionRemaining = 0;
      });
      return;
    }
    const options = [5, 10, 15, 20, 30];
    final mins = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(basicText('reading_session_prompt', lang),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final m in options)
                    ActionChip(
                        label: Text('$m'),
                        onPressed: () => Navigator.pop(context, m)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (mins == null || !mounted) return;
    await _sessionRepo.setTargetMinutes(mins);
    setState(() => _sessionRemaining = mins * 60);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sessionRemaining <= 1) {
        t.cancel();
        _sessionRepo.recordCompletion(mins);
        if (mounted) {
          setState(() {
            _sessionTimer = null;
            _sessionRemaining = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(basicText('reading_session_done', lang))));
        }
        return;
      }
      setState(() => _sessionRemaining--);
    });
  }

  Future<MushafPageLayout?> _layout(int page) async {
    if (_cache.containsKey(page)) return _cache[page];
    final l = await _repo.pageLayout(page);
    _cache[page] = l;
    return l;
  }

  void _clearSelection() {
    if (_selWord != null || _selMark != null) {
      setState(() {
        _selWord = null;
        _selMark = null;
      });
    }
  }

  void _onWord(MushafWord w) {
    setState(() {
      _selWord = w;
      _selMark = null;
    });
    showWordKnowledgeSurface(
      context,
      selection: QuranSelection.word(w),
      lang: LanguagePreferenceService.currentLanguage,
    ).then((res) {
      // 'applied' → the student came back from a lesson via «طبّق»; keep the
      // word highlighted so they land back on the exact spot.
      if (res != 'applied') _clearSelection();
    });
  }

  void _onAyaMark(MushafAyaMark m) {
    setState(() {
      _selMark = m;
      _selWord = null;
    });
    showAyahKnowledgeSurface(
      context,
      selection: QuranSelection.ayah(m),
      lang: LanguagePreferenceService.currentLanguage,
    ).whenComplete(_clearSelection);
  }

  void _openAyahNotebook(int surah, int ayah, {bool openAdd = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AyahNotebookScreen(surah: surah, ayah: ayah, openAdd: openAdd),
      ),
    );
  }

  Future<void> _promptGoToPage(String lang) async {
    final ctrl = TextEditingController(text: '$_current');
    final target = await showDialog<int>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(basicText('mushaf_go_to_page', lang)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '1 – 604'),
          onSubmitted: (_) => Navigator.pop(dCtx, int.tryParse(ctrl.text)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(basicText('cancel_action', lang))),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, int.tryParse(ctrl.text)),
            child: Text(basicText('go_action', lang)),
          ),
        ],
      ),
    );
    if (target != null && target >= 1 && target <= _pageCount) {
      _controller.jumpToPage(target - 1);
    }
  }

  void _jumpToPage(int page) {
    if (page >= 1 && page <= _pageCount) _controller.jumpToPage(page - 1);
  }

  Future<void> _openMenu(String lang) async {
    void go(Widget screen) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.list_alt_rounded),
                title: Text(basicText('mushaf_index_surahs', lang)),
                onTap: () {
                  Navigator.pop(context);
                  _openIndex(lang);
                },
              ),
              ListTile(
                leading: const Icon(Icons.search_rounded),
                title: Text(basicText('search_action', lang)),
                onTap: () => go(const QuranSearchScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.tag_rounded),
                title: Text(basicText('mushaf_go_to_page', lang)),
                onTap: () {
                  Navigator.pop(context);
                  _promptGoToPage(lang);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded),
                title: Text(basicText('favorites_title', lang)),
                onTap: () {
                  Navigator.pop(context);
                  _openFavorites(lang);
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_stories_outlined),
                title: Text(basicText('quran_notebook_title', lang)),
                onTap: () => go(const QuranNotebookHomeScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.checklist_rounded),
                title: Text(basicText('mushaf_mark_memorized', lang)),
                onTap: () => go(const QuranBrowseScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.route_outlined),
                title: Text(basicText('my_journey', lang)),
                onTap: () => go(const JourneyScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.travel_explore_rounded),
                title: Text(basicText('ql_topic_index_title', lang)),
                onTap: () => go(const TopicIndexScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(basicText('ql_sources_screen_title', lang)),
                onTap: () => go(const SourcesScreen()),
              ),
              const Divider(height: 1),
              // التسميع (recitation-follow) — the deeper engine is deferred,
              // but these existing standalone screens stay reachable here.
              ListTile(
                leading: const Icon(Icons.record_voice_over_outlined),
                title: Text(basicText('tahfeez_audio_action', lang)),
                onTap: () => go(const TahfeezSessionSetupScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.mic_none_rounded),
                title: Text(basicText('recite_page_action', lang)),
                onTap: () =>
                    go(PageRecitationScreen(pageNumber: _current)),
              ),
              ListTile(
                leading: const Icon(Icons.history_edu_outlined),
                title: Text(basicText('recitation_mistakes_title', lang)),
                onTap: () => go(const RecitationMistakesScreen()),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.nightlight_outlined),
                title: Text(basicText('night_mode', lang)),
                value: _night,
                onChanged: (v) {
                  Navigator.pop(context);
                  _setNight(v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openIndex(String lang) async {
    final page = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DefaultTabController(
        length: 2,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          builder: (context, sc) => Column(
            children: [
              const SizedBox(height: 8),
              TabBar(tabs: [
                Tab(text: basicText('index_tab_surahs', lang)),
                Tab(text: basicText('index_tab_juz', lang)),
              ]),
              Expanded(
                child: TabBarView(children: [
                  ListView.builder(
                    controller: sc,
                    itemCount: quranSurahs.length,
                    itemBuilder: (context, i) {
                      final s = quranSurahs[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.primaryLight,
                          child: Text('${s.number}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.primaryDark)),
                        ),
                        title: Text(s.name, textDirection: TextDirection.rtl),
                        onTap: () async {
                          final p = await _repo.pageForReference(s.number);
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
                        leading: CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.primaryLight,
                          child: Text('$juz',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.primaryDark)),
                        ),
                        title: Text('${basicText('juz_label', lang)} $juz',
                            textDirection: TextDirection.rtl),
                        onTap: () async {
                          final p = await _repo.pageForJuz(juz);
                          if (context.mounted) Navigator.pop(context, p);
                        },
                      );
                    },
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
    if (page != null) _jumpToPage(page);
  }

  Future<void> _openFavorites(String lang) async {
    final favs = await QuranReadingRepository().favoriteAyahs();
    if (!mounted) return;
    final surahName = {for (final s in quranSurahs) s.number: s.name};
    final page = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, sc) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(basicText('favorites_title', lang),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            if (favs.isEmpty)
              Expanded(
                child: Center(
                  child: Text(basicText('favorites_empty', lang),
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  itemCount: favs.length,
                  itemBuilder: (context, i) {
                    final f = favs[i];
                    return ListTile(
                      title: Text(f.text,
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'AmiriQuran', fontSize: 15)),
                      subtitle: Text(
                          '${surahName[f.surah] ?? f.surah} · ${f.ayah}',
                          textDirection: TextDirection.rtl),
                      onTap: () async {
                        // MushafDatabase page — NOT f.pageNumber (Tanzil).
                        final p = await _repo.pageForReference(f.surah,
                            ayah: f.ayah);
                        if (context.mounted) Navigator.pop(context, p);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
    if (page != null) _jumpToPage(page);
  }

  Widget _buildAudioBar(String lang) {
    final ayat = _pageAyat;
    final at = (_playingAyah != null)
        ? _playingAyah!
        : (ayat.isEmpty ? null : ayat[_audioIdx.clamp(0, ayat.length - 1)]);
    final reciterName = QuranAudioProviderRegistry.reciters()
        .firstWhere((r) => r.id == _reciterId,
            orElse: () => QuranAudioProviderRegistry.reciters().first)
        .nameAr;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: _night ? const Color(0xFF1E1A16) : AppColors.surface,
          border: Border(
              top: BorderSide(
                  color: _night
                      ? const Color(0xFF2E2A24)
                      : AppColors.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: _audioIdx > 0 ? () => _stepAudio(-1) : null,
            ),
            IconButton.filled(
              style:
                  IconButton.styleFrom(backgroundColor: AppColors.primary),
              icon: Icon((_playing && !_paused)
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded),
              onPressed: ayat.isEmpty ? null : _playPause,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed:
                  _audioIdx < ayat.length - 1 ? () => _stepAudio(1) : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickReciter(lang),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(reciterName,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _night
                                ? const Color(0xFFE9E1D2)
                                : AppColors.textDark)),
                    if (at != null)
                      Text(
                        '${_surahName(at.surah)} · ${at.ayah}',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _toggleAudioBar,
            ),
          ],
        ),
      ),
    );
  }

  String _surahName(int n) {
    for (final s in quranSurahs) {
      if (s.number == n) return s.name;
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final bg = _night ? const Color(0xFF14110E) : const Color(0xFFFBF6EE);
    final onBg = _night ? const Color(0xFFE9E1D2) : AppColors.textDark;
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          foregroundColor: onBg,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(basicText('mushaf_semantic_title', lang),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: onBg)),
              Text('${basicText('turath_page_short', lang)} $_current / $_pageCount',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          actions: [
            if (_sessionTimer != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '${_sessionRemaining ~/ 60}:${(_sessionRemaining % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
              ),
            IconButton(
              tooltip: basicText('reading_session_prompt', lang),
              icon: Icon(_sessionTimer != null
                  ? Icons.timer_rounded
                  : Icons.timer_outlined),
              onPressed: () => _openSessionSheet(lang),
            ),
            IconButton(
              tooltip: basicText('listen_ayah_action', lang),
              icon: Icon(_audioBar
                  ? Icons.headphones_rounded
                  : Icons.headphones_outlined),
              onPressed: _toggleAudioBar,
            ),
            IconButton(
              tooltip: basicText('night_mode', lang),
              icon: Icon(_night
                  ? Icons.wb_sunny_rounded
                  : Icons.nightlight_outlined),
              onPressed: () => _setNight(!_night),
            ),
            IconButton(
              tooltip: basicText('mushaf_index_surahs', lang),
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _openMenu(lang),
            ),
          ],
        ),
        bottomNavigationBar: _audioBar ? _buildAudioBar(lang) : null,
        body: _ready == false
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(basicText('mushaf_not_ready', lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              )
            : PageView.builder(
                controller: _controller,
                // Page-turn direction (Ismail 2026-09-03): swipe left→right
                // advances to the next page, like turning the leaf of a
                // physical muṣḥaf held spine-right.
                reverse: false,
                itemCount: _pageCount,
                onPageChanged: (i) {
                  setState(() {
                    _current = i + 1;
                    _selWord = null;
                    _selMark = null;
                  });
                  MushafPageCache.instance.preloadAround(_current);
                },
                itemBuilder: (context, i) {
                  final page = i + 1;
                  return FutureBuilder<MushafPageLayout?>(
                    future: _layout(page),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final layout = snap.data;
                      if (layout == null) {
                        return Center(
                          child: Text(basicText('mushaf_not_ready', lang),
                              style:
                                  const TextStyle(color: AppColors.textMuted)),
                        );
                      }
                      final onThisPage = page == _current;
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _night
                                ? const Color(0xFF1E1A16)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _night
                                    ? const Color(0xFF2E2A24)
                                    : AppColors.divider),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: MushafPageView(
                            layout: layout,
                            selectedWord: onThisPage ? _selWord : null,
                            selectedAyah: !onThisPage
                                ? null
                                : (_playingAyah ??
                                    (_selMark == null
                                        ? null
                                        : (surah: _selMark!.surah,
                                            ayah: _selMark!.ayah))),
                            artInk: _night
                                ? const Color(0xFFE9E1D2)
                                : null,
                            onWordTap: _onWord,
                            onAyaMarkTap: _onAyaMark,
                            onWordLongPress: (w) => _openAyahNotebook(
                                w.surah, w.ayah,
                                openAdd: true),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
