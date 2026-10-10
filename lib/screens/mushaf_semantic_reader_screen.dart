import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_surahs.dart';
import '../data/tajweed_rules_ref.dart';
import '../l10n/basic_translations.dart';
import '../models/mushaf_layout.dart';
import '../models/quran_selection.dart';
import '../models/tajweed_span.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../repositories/quran_corpus_repository.dart';
import '../services/boot/boot_scheduler.dart';
import '../services/mushaf/tajweed_svg.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/quran_reading_session_repository.dart';
import '../services/language_preference_service.dart';
import '../services/quran_audio/quran_audio_provider_registry.dart';
import '../services/quran_audio_engine.dart';
import '../widgets/completion_goal_list_view.dart';
import '../widgets/mushaf/mushaf_ayah_menu.dart';
import '../widgets/mushaf/mushaf_chrome_style.dart';
import '../widgets/mushaf/pinch_zoom.dart';
import '../widgets/mushaf_page_view.dart';
import '../theme/app_theme.dart';
import '../theme/tajweed_palette.dart';
import 'tajweed_tier_screen.dart';
import 'ayah_notebook_screen.dart';
import 'journey_screen.dart';
import 'mushaf_index_screen.dart';
import 'mushaf_search_screen.dart';
import 'page_recitation_screen.dart';
import 'quran_browse_screen.dart';
import 'quran_notebook_home_screen.dart';
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
  late PageController _controller;
  late int _current;
  bool? _ready;

  // ── view mode + pinch zoom (Ismail 2026-10-10) ─────────────────────
  /// «المصحف الرأسي»: one continuous vertical scroll of pages — scroll down
  /// to the next page. «المصحف الأفقي»: one page at a time, swipe to turn.
  static const _verticalPrefKey = 'mushaf_view_vertical';
  static const _zoomPrefKey = 'mushaf_vertical_zoom';
  bool _vertical = true;

  /// Page size multiplier from a two-finger pinch (1 = fit the width).
  /// Remembered in vertical mode (where reading continues zoomed — for older
  /// eyes); in horizontal mode it is per page and resets on a page turn.
  double _zoom = 1;
  double _pinchStartZoom = 1;
  bool _pinching = false;
  static const _maxZoom = 3.0;
  bool get _zoomed => _zoom > 1.001;

  /// Height ÷ width of each page box in the continuous view. The width is
  /// the fitted content frame (`_kContentRectPad`, uniform on all 604
  /// pages); 1.86 adds the art's own juzʼ/surah header above it and the
  /// printed page number below it (the bare frame is 1.534–1.549). One
  /// fixed extent → an exact page ↔ offset mapping.
  static const _pageAspect = 1.86;
  static const _pageGap = 12.0;
  ScrollController? _vScroll; // vertical mode — down the pages
  final _hScroll = ScrollController(); // vertical mode, zoomed — across
  final _zvScroll = ScrollController(); // horizontal mode, zoomed page
  final _zhScroll = ScrollController();
  double _vExtent = 0;
  double _vTopPad = 0;

  /// The ayah under the long-press menu — highlighted while it is open.
  ({int surah, int ayah})? _menuAyah;


  static const _nightPrefKey = 'quran_reading_night_mode';
  static const _reciterPrefKey = 'quran_reading_reciter';
  static const _tajweedPrefKey = 'mushaf_tajweed_mode';
  bool _night = false;

  /// Phase G-t v2 — the opt-in glyph-level tajwīd colour layer, off by
  /// default. `_paintCache["$page|$night"]` memoises the page's path→hue
  /// map so `MushafPageCache`'s resolver is O(1) after the first turn.
  bool _tajweedMode = false;
  final _paintCache = <String, TajweedGlyphPaint>{};

  /// The one selection on the page — drives the Selection Layer and which
  /// surface is open. Cleared when a surface is dismissed.
  MushafWord? _selWord;
  MushafAyaMark? _selMark;

  /// QC7 — the one-line ṣarf/iʿrāb answer for [_selWord], shown as a small
  /// floating label in the line-gap above the word (never over the ink).
  /// Null until fetched / when there's no aligned QAC data.
  final _corpus = QuranCorpusRepository();
  String? _selWordCaption;

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

  /// Immersive reading — Ismail 2026-09-18: tapping the page (a background
  /// tap, not a word) hides the app bar and bottom bars so the muṣḥaf fills
  /// the whole screen; tapping again brings the chrome back. Resets to
  /// visible on every screen open (not persisted — this is "get the chrome
  /// out of my way right now for this reading", not a saved preference).
  bool _chromeVisible = true;
  void _toggleChrome() => setState(() => _chromeVisible = !_chromeVisible);

  @override
  void initState() {
    super.initState();
    _current = widget.initialPage.clamp(1, _pageCount);
    _controller = PageController(initialPage: _current - 1);
    // The layout may still be seeding on a first launch — jump it to the
    // front of the boot queue instead of reporting "not ready".
    BootScheduler.instance
        .ensure(BootTasks.mushafLayout)
        .then((_) => _repo.isReady())
        .then((r) {
      if (mounted) setState(() => _ready = r);
    });
    // The tajwīd renderer asks this for a page's path→hue map; we memoise.
    MushafPageCache.instance.tajweedPaintResolver = _tajweedPaintFor;

    SharedPreferences.getInstance().then((p) {
      final v = p.getBool(_nightPrefKey);
      if (v != null && mounted) setState(() => _night = v);
      final tj = p.getBool(_tajweedPrefKey);
      if (tj == true && mounted) setState(() => _tajweedMode = true);
      final vert = p.getBool(_verticalPrefKey) ?? true;
      final z = (p.getDouble(_zoomPrefKey) ?? 1).clamp(1.0, _maxZoom);
      if (mounted) {
        setState(() {
          _vertical = vert;
          _zoom = vert ? z : 1;
        });
      }
    });
  }

  Future<void> _setNight(bool v) async {
    setState(() => _night = v);
    (await SharedPreferences.getInstance()).setBool(_nightPrefKey, v);
  }

  Future<void> _setTajweed(bool v) async {
    setState(() => _tajweedMode = v);
    (await SharedPreferences.getInstance()).setBool(_tajweedPrefKey, v);
  }

  /// Phase G-t v2 — resolve which glyph `<path>`s to colour on a page:
  /// its ayāt's rule spans (`quran_tajweed`) × the page's glyph geometry
  /// (`mushaf_glyphs` v2). Memoised per `(page, night)`.
  Future<TajweedGlyphPaint> _tajweedPaintFor(int page) async {
    final key = '$page|$_night';
    final hit = _paintCache[key];
    if (hit != null) return hit;
    final layout = await _layout(page);
    if (layout == null) return TajweedGlyphPaint.empty;
    final byAyah = <String, AyahTajweed>{};
    final seen = <String>{};
    for (final w in layout.words) {
      if (w.type != MushafWordType.text) continue;
      final k = '${w.surah}:${w.ayah}';
      if (!seen.add(k)) continue;
      byAyah[k] = await _corpus.tajweedForAyah(w.surah, w.ayah);
    }
    final glyphs = await _repo.glyphsForPage(page);
    final paint = resolveTajweedPaint(
      pageWords: layout.words,
      tajweedByAyah: byAyah,
      glyphsByWordOrder: glyphs,
      night: _night,
    );
    _paintCache[key] = paint;
    return paint;
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _audio.stop();
    _controller.dispose();
    _vScroll?.dispose();
    _hScroll.dispose();
    _zvScroll.dispose();
    _zhScroll.dispose();
    if (MushafPageCache.instance.tajweedPaintResolver == _tajweedPaintFor) {
      MushafPageCache.instance.tajweedPaintResolver = null;
      MushafPageCache.instance.invalidateTajweed();
    }
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

  /// Bumped by every [_playFrom] — an older loop sees the change and exits,
  /// so «next/previous ayah» never leaves two recitation loops running.
  int _playGen = 0;

  Future<void> _playFrom(int start) async {
    final ayat = _pageAyat;
    if (ayat.isEmpty) return;
    final gen = ++_playGen;
    setState(() {
      _playing = true;
      _paused = false;
      _audioIdx = start.clamp(0, ayat.length - 1);
    });
    for (var i = _audioIdx; i < ayat.length; i++) {
      if (!mounted || !_playing || gen != _playGen) return;
      while (_paused) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!mounted || !_playing || gen != _playGen) return;
      }
      setState(() {
        _audioIdx = i;
        _playingAyah = ayat[i];
      });
      await _audio.playAyah(_reciterId, ayat[i].surah, ayat[i].ayah);
    }
    if (mounted && gen == _playGen) {
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
    if (_selWord != null || _selMark != null || _selWordCaption != null) {
      setState(() {
        _selWord = null;
        _selMark = null;
        _selWordCaption = null;
      });
    }
  }

  /// Fetch the tapped word's one-line ṣarf/iʿrāb (QAC) for the on-page label.
  Future<void> _loadWordCaption(MushafWord w) async {
    String? cap;
    try {
      final m = await _corpus.morphologyForWord(w.surah, w.ayah, w.wordIndex);
      if (m is Map) {
        final segs = (m['segments'] as List? ?? const [])
            .whereType<Map>()
            .toList();
        Map? stem;
        for (final s in segs) {
          if (s['role'] == 'stem') {
            stem = s;
            break;
          }
        }
        stem ??= segs.isNotEmpty ? segs.last : null;
        if (stem != null) {
          final parts = <String>[
            if ('${stem['pos'] ?? ''}'.isNotEmpty) '${stem['pos']}',
            if ('${stem['inflection'] ?? ''}'.isNotEmpty) '${stem['inflection']}',
            if ('${stem['root'] ?? ''}'.isNotEmpty) 'جذر ${stem['root']}',
          ];
          if (parts.isNotEmpty) cap = parts.join(' · ');
        }
      }
    } catch (_) {
      cap = null;
    }
    if (mounted && identical(_selWord, w)) {
      setState(() => _selWordCaption = cap);
    }
  }

  /// «وضع التجويد» — the tapped word's rule names for the on-page label
  /// («التجويد: إخفاء · مدّ متصل»); falls back to the ṣarf line if the word
  /// carries no rule.
  Future<void> _loadTajweedCaption(MushafWord w) async {
    final spans = await _corpus.tajweedForWord(w.surah, w.ayah, w.wordIndex);
    if (!mounted || !identical(_selWord, w)) return;
    if (spans.isEmpty) {
      _loadWordCaption(w);
      return;
    }
    final names = <String>[];
    for (final s in spans) {
      if (!names.contains(s.ruleAr)) names.add(s.ruleAr);
    }
    final label = basicText(
        'ql_domain_tajweed', LanguagePreferenceService.currentLanguage);
    setState(() => _selWordCaption = '$label: ${names.join(' · ')}');
  }

  void _onWord(MushafWord w) {
    setState(() {
      _selWord = w;
      _selMark = null;
      _selWordCaption = null;
    });
    if (_tajweedMode) {
      _loadTajweedCaption(w);
    } else {
      _loadWordCaption(w);
    }
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
    if (target != null) _jumpToPage(target);
  }

  void _jumpToPage(int page) {
    if (page < 1 || page > _pageCount) return;
    if (_vertical) {
      final c = _vScroll;
      if (c != null && c.hasClients && _vExtent > 0) {
        c.jumpTo(
          ((page - 1) * _vExtent).clamp(0.0, c.position.maxScrollExtent),
        );
      }
      _setCurrent(page);
    } else {
      _controller.jumpToPage(page - 1);
    }
  }

  void _setCurrent(int page) {
    if (page == _current) return;
    setState(() {
      _current = page;
      _selWord = null;
      _selMark = null;
    });
    MushafPageCache.instance.preloadAround(_current);
  }

  // ── view mode + pinch zoom ─────────────────────────────────────────

  Future<void> _setVertical(bool v) async {
    if (v == _vertical) return;
    final p = await SharedPreferences.getInstance();
    p.setBool(_verticalPrefKey, v);
    final remembered = (p.getDouble(_zoomPrefKey) ?? 1).clamp(1.0, _maxZoom);
    if (!mounted) return;
    final page = _current;
    setState(() {
      _vertical = v;
      _zoom = v ? remembered : 1;
      if (v) {
        _vScroll?.dispose();
        _vScroll = null; // rebuilt at the current page by _continuousView
      } else {
        _controller.dispose();
        _controller = PageController(initialPage: page - 1);
      }
    });
  }

  void _onPinchStart() => _pinchStartZoom = _zoom;

  void _onPinchActive(bool active) {
    if (active == _pinching) return;
    setState(() => _pinching = active);
    if (!active && _vertical) {
      SharedPreferences.getInstance().then(
        (p) => p.setDouble(_zoomPrefKey, _zoom),
      );
    }
  }

  /// Keep the point under the fingers still while the page grows/shrinks.
  /// Several pointer moves can land between two frames, so the target
  /// offsets accumulate in [_pendingX]/[_pendingY] and are applied once,
  /// after the frame that lays the new size out.
  double? _pendingX, _pendingY;
  bool _jumpScheduled = false;
  double _vViewportW = 0;

  double _extentFor(double zoom) => _vViewportW * zoom * _pageAspect + _pageGap;

  void _onPinchUpdate(double scale, Offset focal) {
    final z = (_pinchStartZoom * scale).clamp(1.0, _maxZoom);
    if ((z - _zoom).abs() < 0.004) return;
    final ratio = z / _zoom;
    final h = _vertical ? _hScroll : _zhScroll;
    final v = _vertical ? _vScroll : _zvScroll;
    double off(ScrollController? c) => (c != null && c.hasClients) ? c.offset : 0;
    final x = _pendingX ?? off(h);
    final y = _pendingY ?? off(v);
    _pendingX = (x + focal.dx) * ratio - focal.dx;
    if (_vertical && _vViewportW > 0) {
      // in page units, so the fixed band between pages doesn't drift
      final pages = (y + focal.dy - _vTopPad) / _extentFor(_zoom);
      _pendingY = pages * _extentFor(z) + _vTopPad - focal.dy;
    } else {
      _pendingY = (y + focal.dy) * ratio - focal.dy;
    }
    setState(() => _zoom = z);
    if (_jumpScheduled) return;
    _jumpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpScheduled = false;
      void jump(ScrollController? c, double? to) {
        if (to == null || c == null || !c.hasClients) return;
        c.jumpTo(to.clamp(0.0, c.position.maxScrollExtent));
      }

      jump(_vertical ? _hScroll : _zhScroll, _pendingX);
      jump(_vertical ? _vScroll : _zvScroll, _pendingY);
      _pendingX = null;
      _pendingY = null;
    });
  }

  void _resetZoom() {
    setState(() => _zoom = 1);
    if (_vertical) {
      SharedPreferences.getInstance().then((p) => p.setDouble(_zoomPrefKey, 1));
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _jumpToPage(_current),
      );
    }
  }

  // ── the long-press ayah menu ────────────────────────────────────────

  Future<void> _onAyahLongPress(
    int page,
    int surah,
    int ayah,
    Rect rect,
  ) async {
    HapticFeedback.selectionClick();
    final lang = LanguagePreferenceService.currentLanguage;
    final quran = QuranReadingRepository();
    final fav = await quran.isFavorite(surah, ayah);
    if (!mounted) return;
    setState(() => _menuAyah = (surah: surah, ayah: ayah));
    final action = await showMushafAyahMenu<String>(
      context: context,
      anchor: rect,
      night: _night,
      items: [
        MushafAyahMenuItem(
          'tafsir',
          Icons.menu_book_rounded,
          basicText('ql_domain_tafsir', lang),
        ),
        MushafAyahMenuItem(
          'translation',
          Icons.translate_rounded,
          basicText('ql_translation', lang),
        ),
        MushafAyahMenuItem(
          'listen',
          Icons.play_circle_fill_rounded,
          basicText('listen_ayah_action', lang),
        ),
        MushafAyahMenuItem(
          'fav',
          fav ? Icons.bookmark_remove_rounded : Icons.bookmark_rounded,
          basicText(
            fav ? 'remove_from_favorites_action' : 'add_to_favorites_action',
            lang,
          ),
        ),
        MushafAyahMenuItem(
          'notebook',
          Icons.edit_note_rounded,
          basicText('ql_add_to_notebook', lang),
        ),
        MushafAyahMenuItem(
          'share',
          Icons.ios_share_rounded,
          basicText('share_action', lang),
        ),
      ],
    );
    if (!mounted) return;
    final sel = QuranSelection(
      page: page,
      surah: surah,
      ayah: ayah,
      type: QuranSelectionType.ayah,
    );
    switch (action) {
      case 'tafsir':
      case 'translation':
        await showAyahKnowledgeSurface(
          context,
          selection: sel,
          lang: lang,
          openTranslation: action == 'translation',
        );
      case 'listen':
        _listenFrom(page, surah, ayah);
      case 'fav':
        if (fav) {
          await quran.removeFavorite(surah, ayah);
        } else {
          await quran.addFavorite(surah, ayah);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                basicText(
                  fav ? 'ayah_removed_favorite' : 'ayah_added_favorite',
                  lang,
                ),
              ),
            ),
          );
        }
      case 'notebook':
        _openAyahNotebook(surah, ayah, openAdd: true);
      case 'share':
        final a = await quran.ayahAt(surah, ayah);
        if (a != null) {
          await Share.share('﴿${a.text}﴾\n[${_surahName(surah)}: $ayah]');
        }
    }
    if (mounted) setState(() => _menuAyah = null);
  }

  /// «الاستماع» from the menu: open the listen bar and recite this page from
  /// the pressed ayah onward.
  Future<void> _listenFrom(int page, int surah, int ayah) async {
    if (page != _current) _setCurrent(page);
    if (!_audioBar) await _toggleAudioBar();
    final layout = await _layout(page);
    if (!mounted || layout == null) return;
    final i = layout.ayat.indexWhere((a) => a.surah == surah && a.ayah == ayah);
    _audio.stop();
    _playFrom(i < 0 ? 0 : i);
  }

  /// «القائمة» — a floating card in the reader's own palette (Ismail's
  /// reference, 2026-10-10): the view-mode toggle on top, then grouped
  /// sections. Switches update in place; navigation rows close it first.
  Future<void> _openMenu(String lang) async {
    void go(Widget screen) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    void then(VoidCallback f) {
      Navigator.pop(context);
      f();
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final night = _night;
          final fg = MushafChrome.fg(night);
          final card = night ? AppColors.surfaceNight : MushafChrome.paper;
          final iconC = night ? MushafChrome.gold : MushafChrome.brown;

          Widget header(String key) => Container(
            width: double.infinity,
            color: (night ? Colors.white : MushafChrome.tan).withValues(
              alpha: night ? 0.05 : 0.55,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text(
              basicText(key, lang),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: fg.withValues(alpha: 0.65),
              ),
            ),
          );
          Widget tile(IconData icon, String label, VoidCallback onTap) =>
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 22, color: iconC),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
          Widget toggle(
            IconData icon,
            String label,
            bool value,
            ValueChanged<bool> onChanged,
          ) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconC),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  activeThumbColor: MushafChrome.brown,
                  onChanged: onChanged,
                ),
              ],
            ),
          );
          final div = Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: MushafChrome.line(night),
          );

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            minChildSize: 0.4,
            maxChildSize: 0.94,
            builder: (_, sc) => Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: MushafChrome.gold.withValues(alpha: 0.35),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                controller: sc,
                padding: EdgeInsets.zero,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      children: [
                        Text(
                          basicText('mushaf_view_mode', lang),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 10),
                        MushafSegmented(
                          night: night,
                          selected: _vertical ? 0 : 1,
                          onChanged: (i) async {
                            await _setVertical(i == 0);
                            setSheet(() {});
                          },
                          options: [
                            (
                              label: basicText('mushaf_view_vertical', lang),
                              icon: Icons.view_day_outlined,
                            ),
                            (
                              label: basicText('mushaf_view_horizontal', lang),
                              icon: Icons.auto_stories_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          basicText('mushaf_zoom_hint', lang),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: fg.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  header('mushaf_section_mushaf'),
                  tile(
                    Icons.format_list_bulleted_rounded,
                    basicText('mushaf_index_surahs', lang),
                    () => then(() => _openIndex(lang)),
                  ),
                  div,
                  tile(
                    Icons.search_rounded,
                    basicText('search_action', lang),
                    () => then(() => _openSearch(lang)),
                  ),
                  div,
                  tile(
                    Icons.tag_rounded,
                    basicText('mushaf_go_to_page', lang),
                    () => then(() => _promptGoToPage(lang)),
                  ),
                  if (_zoomed) ...[
                    div,
                    tile(
                      Icons.zoom_out_map_rounded,
                      basicText('mushaf_zoom_reset', lang),
                      () => then(_resetZoom),
                    ),
                  ],
                  header('mushaf_section_khatma'),
                  tile(
                    Icons.flag_circle_outlined,
                    basicText('khatm_reading_plans_short', lang),
                    () => then(() => _openKhatmSheet(lang)),
                  ),
                  div,
                  tile(
                    Icons.route_outlined,
                    basicText('my_journey', lang),
                    () => go(const JourneyScreen()),
                  ),
                  div,
                  tile(
                    Icons.timer_outlined,
                    basicText('reading_session_prompt', lang),
                    () => then(() => _openSessionSheet(lang)),
                  ),
                  header('mushaf_section_tahfeez'),
                  tile(
                    Icons.record_voice_over_outlined,
                    basicText('tahfeez_audio_action', lang),
                    () => go(const TahfeezSessionSetupScreen()),
                  ),
                  div,
                  tile(
                    Icons.mic_none_rounded,
                    basicText('recite_page_action', lang),
                    () => go(PageRecitationScreen(pageNumber: _current)),
                  ),
                  div,
                  tile(
                    Icons.history_edu_outlined,
                    basicText('recitation_mistakes_title', lang),
                    () => go(const RecitationMistakesScreen()),
                  ),
                  div,
                  tile(
                    Icons.checklist_rounded,
                    basicText('mushaf_mark_memorized', lang),
                    () => go(const QuranBrowseScreen()),
                  ),
                  header('mushaf_section_features'),
                  tile(
                    Icons.headphones_outlined,
                    basicText('listen_ayah_action', lang),
                    () => then(_toggleAudioBar),
                  ),
                  div,
                  toggle(
                    Icons.nightlight_outlined,
                    basicText('night_mode', lang),
                    _night,
                    (v) async {
                      await _setNight(v);
                      setSheet(() {});
                    },
                  ),
                  div,
                  toggle(
                    Icons.brush_outlined,
                    basicText('mushaf_tajweed_mode', lang),
                    _tajweedMode,
                    (v) async {
                      await _setTajweed(v);
                      setSheet(() {});
                    },
                  ),
                  div,
                  tile(
                    Icons.travel_explore_rounded,
                    basicText('ql_topic_index_title', lang),
                    () => go(const TopicIndexScreen()),
                  ),
                  div,
                  tile(
                    Icons.info_outline_rounded,
                    basicText('ql_sources_screen_title', lang),
                    () => go(const SourcesScreen()),
                  ),
                  header('favorites_title'),
                  tile(
                    Icons.bookmark_outline_rounded,
                    basicText('favorites_title', lang),
                    () => then(() => _openFavorites(lang)),
                  ),
                  div,
                  tile(
                    Icons.auto_stories_outlined,
                    basicText('quran_notebook_title', lang),
                    () => go(const QuranNotebookHomeScreen()),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSearch(String lang) async {
    final page = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => MushafSearchScreen(lang: lang, night: _night),
      ),
    );
    if (page != null) _jumpToPage(page);
  }

  /// Persistent "الختمات" entry point (KHATM_SYSTEM_AND_STYLE_REFERENCE.md
  /// §2.2) — a bottom sheet, filtered to `quran_reading` goals only, that
  /// opens *over* this reader screen (the mushaf page stays visible behind
  /// it). Reuses `CompletionGoalListView` — the same list/card widget the
  /// full "خطط ختمي" screen uses — with its opt-in colour-stripe +
  /// percentage decoration turned on. The header's "+" reuses the exact
  /// same creation wizard as the full screen's FAB (Ismail 2026-09-16: the
  /// reader user shouldn't have to leave and come back just to start a
  /// plan) — still no *new* wizard built here, per §2.3 being a later grain.
  Future<void> _openKhatmSheet(String lang) async {
    final listKey = GlobalKey<CompletionGoalListViewState>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(basicText('khatm_reading_plans_short', lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    tooltip: basicText('create_plan_action', lang),
                    icon: const Icon(Icons.add),
                    onPressed: () => openNewCompletionGoalSheet(sheetContext, onCreated: () => listKey.currentState?.reload(), lockedContentType: 'quran_reading'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CompletionGoalListView(
                key: listKey,
                contentTypeFilter: 'quran_reading',
                showStripeAndPercent: true,
                currentPageHint: _current,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A single small pill under the page while «وضع التجويد» is on — `تجويد ▾`
  /// — opens the collapsible legend sheet. Zero permanent screen cost.
  Widget _tajweedLegendPill(String lang) {
    final fg = _night ? AppColors.textDarkNight : AppColors.textDark;
    return Material(
      color: _night ? AppColors.backgroundNight : const Color(0xFFFBF6EE),
      child: SafeArea(
        top: false,
        bottom: !_audioBar,
        minimum: const EdgeInsets.only(bottom: 6),
        child: Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _openTajweedLegend(lang),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: fg.withValues(alpha: 0.25), width: 0.8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (final c in kTajweedCategories) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: c.color(night: _night),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 3),
                ],
                const SizedBox(width: 3),
                Text(basicText('mushaf_tajweed_legend', lang),
                    style: TextStyle(fontSize: 12, color: fg)),
                Icon(Icons.expand_less_rounded, size: 16, color: fg),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  /// The collapsible legend — one row per colour category: swatch · name ·
  /// one-line definition · an example ayah with the rule glyph in its hue ·
  /// «افتح الدرس» where a lesson exists.
  Future<void> _openTajweedLegend(String lang) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          _night ? AppColors.surfaceNight : AppColors.surface,
      builder: (_) {
        final fg = _night ? AppColors.textDarkNight : AppColors.textDark;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            children: [
              Text(basicText('mushaf_tajweed_legend_title', lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
              const SizedBox(height: 4),
              Text(basicText('mushaf_tajweed_mode_hint', lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 14),
              for (final c in kTajweedCategories)
                _tajweedLegendRow(c, lang, fg),
            ],
          ),
        );
      },
    );
  }

  Widget _tajweedLegendRow(TajweedCategory c, String lang, Color fg) {
    // the first rule in this category that has a curriculum lesson
    final ruleWithLesson = kTajweedRules.values.firstWhere(
      (r) => r.categoryKey == c.key && r.tier != null,
      orElse: () => kTajweedRules.values.firstWhere((r) => r.categoryKey == c.key),
    );
    final tier = ruleWithLesson.tier;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: c.color(night: _night), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(c.labelAr,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: fg)),
            const Spacer(),
            if (tier != null)
              TextButton(
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TajweedTierScreen(tier: tier)));
                },
                child: Text(basicText('ql_open_lesson', lang),
                    style: const TextStyle(fontSize: 11)),
              ),
          ]),
          const SizedBox(height: 3),
          Text(c.defAr,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontSize: 11.5, height: 1.6, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Future<void> _openIndex(String lang) async {
    final page = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => MushafIndexScreen(lang: lang, night: _night),
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
          color: _night ? AppColors.surfaceNight : AppColors.surface,
          border: Border(
              top: BorderSide(
                  color: _night
                      ? AppColors.dividerNight
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
                                ? AppColors.textDarkNight
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

  /// The current page's juzʼ + first surah — replaces the old static
  /// "المصحف الدلالي / ص X من 604" title (Ismail 2026-09-18: remove that
  /// label and its details, show the juzʼ/surah where the icons are).
  Future<({int? juz, int surah})?> _headerInfo(int page) async {
    final juz = await _repo.juzForPage(page);
    final bounds = await _repo.ayahBoundsForPage(page);
    if (bounds == null) return null;
    return (juz: juz, surah: bounds.firstSurah);
  }

  @override
  Widget build(BuildContext context) {
    final bg = _night ? AppColors.backgroundNight : const Color(0xFFFBF6EE);
    final onBg = _night ? AppColors.textDarkNight : AppColors.textDark;
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: bg,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // The muṣḥaf always renders at full screen size — the toolbar
            // below floats OVER it as an overlay and never resizes/reflows
            // the page (Ismail 2026-09-18: "القرآن كبير بما فيه أن يصل حتى
            // خلف الـheader" — the page reaches even behind the header).
            Positioned.fill(
              child: _ready == false
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(basicText('mushaf_not_ready', lang),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  : PinchZoomListener(
                      onStart: _onPinchStart,
                      onUpdate: _onPinchUpdate,
                      onPinchActive: _onPinchActive,
                      child: _vertical
                          ? _continuousView(lang)
                          : _readerPageView(lang),
                    ),
            ),
            if (_chromeVisible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    color: bg,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: onBg),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: FutureBuilder<({int? juz, int surah})?>(
                            key: ValueKey(_current),
                            future: _headerInfo(_current),
                            builder: (context, snap) {
                              final info = snap.data;
                              if (info == null) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (info.juz != null)
                                    Text('${basicText('juz_label', lang)} ${info.juz}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: onBg)),
                                  Text(quranSurahs[info.surah - 1].name,
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.textMuted)),
                                ],
                              );
                            },
                          ),
                        ),
                        // A running reading session shows its countdown;
                        // tapping it ends the session (started from the menu).
                        if (_sessionTimer != null)
                          TextButton.icon(
                            onPressed: () => _openSessionSheet(lang),
                            icon: const Icon(Icons.timer_rounded, size: 16, color: AppColors.primary),
                            label: Text(
                              '${_sessionRemaining ~/ 60}:${(_sessionRemaining % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                          ),
                        IconButton(
                          tooltip: basicText('listen_ayah_action', lang),
                          icon: Icon(_audioBar ? Icons.headphones_rounded : Icons.headphones_outlined, color: onBg),
                          onPressed: _toggleAudioBar,
                        ),
                        IconButton(
                          tooltip: basicText('khatm_reading_plans_short', lang),
                          icon: Icon(Icons.flag_circle_outlined, color: onBg),
                          onPressed: () => _openKhatmSheet(lang),
                        ),
                        IconButton(
                          tooltip: basicText('mushaf_index_surahs', lang),
                          icon: Icon(Icons.menu_rounded, color: onBg),
                          onPressed: () => _openMenu(lang),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_chromeVisible && (_tajweedMode || _audioBar))
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (_tajweedMode) _tajweedLegendPill(lang),
                    if (_audioBar) _buildAudioBar(lang),
                  ]),
                ),
              ),
            // Zoomed: the size and a one-tap way back to the fitted page.
            if (_zoomed)
              Positioned(
                bottom: (_chromeVisible && (_audioBar || _tajweedMode))
                    ? 96
                    : 18,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Center(
                    child: Material(
                      color: bg.withValues(alpha: 0.92),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: MushafChrome.gold.withValues(alpha: 0.5),
                        ),
                      ),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: _resetZoom,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.zoom_out_map_rounded,
                                size: 16,
                                color: onBg,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(_zoom * 100).round()}%',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: onBg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // A second, always-available way to toggle the chrome — tapping
            // the empty page background does it too, but a tap can land on
            // a word and open its iʿrāb caption instead (Ismail 2026-09-19:
            // "قد يضغط على حرف... نحتاج إلى أيقونة تظهر وتخفي"). Fixed in a
            // corner so it's never lost regardless of chrome state.
            Positioned(
              bottom: 16,
              left: 16,
              child: SafeArea(
                child: Material(
                  color: bg.withValues(alpha: 0.85),
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggleChrome,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        _chromeVisible ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                        size: 20,
                        color: onBg,
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
  }

  /// One mushaf page (layout loaded on demand) — shared by both view modes.
  /// The selection paints only on the page it belongs to; an ayah highlight
  /// (playing / medallion / long-press menu) is matched by `(surah, ayah)`,
  /// so it shows on every page the ayah spans.
  Widget _page(String lang, int page) {
    // Already loaded → build synchronously: a rebuild (every page change in
    // the continuous view) must never flash a spinner over a visible page.
    if (_cache.containsKey(page)) return _pageBody(lang, page, _cache[page]);
    return FutureBuilder<MushafPageLayout?>(
      future: _layout(page),
      builder: (context, snap) => snap.connectionState != ConnectionState.done
          ? const Center(child: CircularProgressIndicator())
          : _pageBody(lang, page, snap.data),
    );
  }

  Widget _pageBody(String lang, int page, MushafPageLayout? layout) {
    if (layout == null) {
      return Center(
        child: Text(
          basicText('mushaf_not_ready', lang),
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    final word = _selWord?.page == page ? _selWord : null;
    return Container(
      color: _night ? AppColors.surfaceNight : AppColors.surface,
      child: MushafPageView(
        layout: layout,
        selectedWord: word,
        wordCaption: word != null ? _selWordCaption : null,
        tajweed: _tajweedMode,
        selectedAyah:
            _playingAyah ??
            _menuAyah ??
            (_selMark == null || _selMark!.page != page
                ? null
                : (surah: _selMark!.surah, ayah: _selMark!.ayah)),
        artInk: _night ? AppColors.textDarkNight : null,
        onWordTap: _onWord,
        onAyaMarkTap: _onAyaMark,
        onAyahLongPress: (s, a, rect) => _onAyahLongPress(page, s, a, rect),
        onBackgroundTap: _toggleChrome,
      ),
    );
  }

  /// «المصحف الأفقي» — one page at a time, swipe to turn. Pinched in, the
  /// page grows inside a two-axis scroll and the swipe pauses until it is
  /// back to size (a turn would otherwise fight the pan).
  Widget _readerPageView(String lang) {
    const freeze = NeverScrollableScrollPhysics();
    return PageView.builder(
      controller: _controller,
      // Page-turn direction (Ismail 2026-09-03): swipe left→right
      // advances to the next page, like turning the leaf of a
      // physical muṣḥaf held spine-right.
      reverse: false,
      physics: (_pinching || _zoomed) ? freeze : null,
      itemCount: _pageCount,
      onPageChanged: (i) {
        if (_zoomed) setState(() => _zoom = 1);
        _setCurrent(i + 1);
      },
      itemBuilder: (context, i) {
        final page = i + 1;
        final child = _page(lang, page);
        if (!_zoomed || page != _current) return child;
        return LayoutBuilder(
          builder: (context, c) => Directionality(
            // left-based offsets, so the pinch anchor math is direction-free
            textDirection: TextDirection.ltr,
            child: SingleChildScrollView(
              controller: _zvScroll,
              physics: _pinching ? freeze : null,
              child: SingleChildScrollView(
                controller: _zhScroll,
                scrollDirection: Axis.horizontal,
                physics: _pinching ? freeze : null,
                child: SizedBox(
                  width: c.maxWidth * _zoom,
                  height: c.maxHeight * _zoom,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// «المصحف الرأسي» — every page in one vertical scroll (Ismail's reference
  /// screenshots): scroll down and the next page follows. Each page is a
  /// fixed-height box, so page ↔ offset is exact (jumps, the current page,
  /// the pinch anchor). Pinched in, pages widen and the list also scrolls
  /// sideways — reading carries on down the pages at that size.
  Widget _continuousView(String lang) {
    const freeze = NeverScrollableScrollPhysics();
    return LayoutBuilder(
      builder: (context, c) {
        final pageW = c.maxWidth * _zoom;
        final pageH = pageW * _pageAspect;
        _vExtent = pageH + _pageGap;
        _vViewportW = c.maxWidth;
        _vTopPad = MediaQuery.paddingOf(context).top + 52;
        final controller = _vScroll ??= ScrollController(
          initialScrollOffset: (_current - 1) * _vExtent,
        );
        final gapColor = _night
            ? AppColors.backgroundNight
            : const Color(0xFFEDE3D3);

        final Widget list0 = ListView.builder(
          controller: controller,
          physics: _pinching ? freeze : null,
          itemExtent: _vExtent,
          itemCount: _pageCount,
          padding: EdgeInsets.only(
            top: _vTopPad,
            bottom: MediaQuery.paddingOf(context).bottom + 80,
          ),
          itemBuilder: (context, i) => Column(
            children: [
              SizedBox(
                width: pageW,
                height: pageH,
                child: CustomPaint(
                  foregroundPainter: _PageFramePainter(night: _night, scale: _zoom),
                  child: _page(lang, i + 1),
                ),
              ),
              Container(height: _pageGap, color: gapColor),
            ],
          ),
        );
        // Always in the tree (locked while unzoomed): wrapping the list only
        // once zoomed would re-create its scroll position mid-pinch and jump
        // to a far page.
        final list = Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            controller: _hScroll,
            scrollDirection: Axis.horizontal,
            physics: (_pinching || !_zoomed) ? freeze : null,
            child: SizedBox(width: pageW, height: c.maxHeight, child: list0),
          ),
        );
        return NotificationListener<ScrollUpdateNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical && _vExtent > 0) {
              // the page filling the upper-middle of the screen is "current"
              final y = n.metrics.pixels + c.maxHeight * 0.35 - _vTopPad;
              _setCurrent((y / _vExtent).floor().clamp(0, _pageCount - 1) + 1);
            }
            return false;
          },
          child: list,
        );
      },
    );
  }
}

/// Each page of the continuous view as a sheet of paper: a hairline gold
/// edge at the box border (the art's headers sit close to the sides, so
/// nothing is drawn inside the page). Decoration only.
class _PageFramePainter extends CustomPainter {
  final bool night;
  final double scale;
  _PageFramePainter({required this.night, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final c = night ? MushafChrome.gold.withValues(alpha: 0.45) : MushafChrome.brown.withValues(alpha: 0.55);
    canvas.drawRect(
        (Offset.zero & size).deflate(0.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = c);
  }

  @override
  bool shouldRepaint(_PageFramePainter o) => o.night != night || o.scale != scale;
}
