import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/memorization_repository.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../repositories/quran_reading_repository.dart';
import '../services/language_preference_service.dart';
import '../services/quran_audio_engine.dart';
import '../theme/app_theme.dart';
import '../utils/month.dart';
import '../widgets/mushaf/mushaf_chrome_style.dart';
import 'quran_browse_screen.dart';

String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);

/// «احفظ هذه الصفحة» — Ismail (2026-10-13): «حدد ما حفظته ليس له هدف واضح،
/// اجعله فعالًا: ٣ سماع للصفحة من الحصري أو المنشاوي، ٣ قراءات، ٣ تكرار».
/// Three stages, three times each, then «حفظتُها» starts the page in the
/// existing 6-station review engine (`MemorizationRepository.markMemorized`
/// — station 1, reviewed tomorrow). It's the first four steps of the 9-step
/// protocol (docs/memorization/00-MEMORY-SYSTEM-MASTER.md §3: listen, read,
/// recite looking, recite without looking) at page scale.
///
/// Advisory, never a lock (the engine's standing rule): every stage is open
/// at any time; the next one is only highlighted. Counts survive leaving
/// the screen for the rest of the day.
class PageHifzSessionScreen extends StatefulWidget {
  /// MushafDatabase page (the reader's numbering).
  final int page;
  const PageHifzSessionScreen({super.key, required this.page});

  @override
  State<PageHifzSessionScreen> createState() => _PageHifzSessionScreenState();
}

class _PageHifzSessionScreenState extends State<PageHifzSessionScreen> {
  static const _times = 3;
  static const _reciters = [
    ('Husary_Muallim_128kbps', 'hz3_reciter_husary'),
    ('Minshawy_Murattal_128kbps', 'hz3_reciter_minshawi'),
  ];

  final _layout = MushafLayoutRepository();
  final _reading = QuranReadingRepository();
  final _memo = MemorizationRepository();
  final _audio = QuranAudioEngine();

  List<({int surah, int ayah, String text})> _ayat = [];
  int? _unit;
  bool _alreadyMemorized = false;
  bool _loading = true;

  // listen / read / recite counts, 0..3
  final _count = [0, 0, 0];
  String _reciter = _reciters.first.$1;
  bool _listening = false;
  int _listenAyah = -1;
  final Set<int> _revealed = {};

  String get _prefKey => 'hifz3_${widget.page}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _audio.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final refs = await _layout.ayatOnPage(widget.page);
    final ayat = <({int surah, int ayah, String text})>[];
    for (final r in refs) {
      final a = await _reading.ayahAt(r.surah, r.ayah);
      ayat.add((surah: r.surah, ayah: r.ayah, text: a?.text ?? ''));
    }
    final unit = refs.isEmpty ? null : await _memo.unitForAyah(refs.first.surah, refs.first.ayah);
    final memorized = unit != null && await _memo.isMemorized(unit);
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList(_prefKey);
    if (saved != null && saved.length == 4 && saved[0] == todayDate()) {
      for (var i = 0; i < 3; i++) {
        _count[i] = int.tryParse(saved[i + 1]) ?? 0;
      }
    }
    _reciter = p.getString('hifz3_reciter') ?? _reciter;
    if (!mounted) return;
    setState(() {
      _ayat = ayat;
      _unit = unit;
      _alreadyMemorized = memorized;
      _loading = false;
    });
  }

  void _bump(int stage) {
    if (_count[stage] >= _times) return;
    HapticFeedback.mediumImpact();
    setState(() => _count[stage]++);
    if (_count[stage] == _times) HapticFeedback.heavyImpact();
    SharedPreferences.getInstance().then((p) => p.setStringList(
        _prefKey, [todayDate(), for (final c in _count) '$c']));
  }

  int get _stage => _count.indexWhere((c) => c < _times);
  int get _done => _count.fold(0, (s, c) => s + c);

  Future<void> _listen() async {
    if (_listening) {
      _audio.stop();
      setState(() {
        _listening = false;
        _listenAyah = -1;
      });
      return;
    }
    setState(() => _listening = true);
    for (var i = 0; i < _ayat.length; i++) {
      if (!mounted || !_listening) return;
      setState(() => _listenAyah = i);
      if (i + 1 < _ayat.length) _audio.prefetch(_reciter, _ayat[i + 1].surah, _ayat[i + 1].ayah);
      final ok = await _audio.playAyah(_reciter, _ayat[i].surah, _ayat[i].ayah);
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _listenAyah = -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('mushaf_audio_offline'))));
        return;
      }
    }
    if (!mounted || !_listening) return;
    setState(() {
      _listening = false;
      _listenAyah = -1;
    });
    _bump(0); // one full listen of the page
  }

  Future<void> _finish() async {
    final unit = _unit;
    if (unit == null) return;
    await _memo.markMemorized(unit);
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _alreadyMemorized = true);
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 44),
        title: Text(_t('hz3_done_title'), textAlign: TextAlign.center),
        content: Text(_t('hz3_done_body'), textAlign: TextAlign.center),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(_t('hz3_done_ok')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final first = _ayat.isEmpty ? null : _ayat.first;
    return Scaffold(
      backgroundColor: MushafChrome.paper,
      appBar: AppBar(
        backgroundColor: MushafChrome.paper,
        title: Text('${_t('hz3_title')} · ${_t('page_label')} ${mushafDigits(widget.page, lang)}'),
        actions: [
          IconButton(
            tooltip: _t('hz3_all_memorized'),
            icon: const Icon(Icons.checklist_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranBrowseScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _Header(
                  surah: first == null ? '' : quranSurahs[first.surah - 1].name,
                  done: _done,
                  total: _times * 3,
                  memorized: _alreadyMemorized,
                  lang: lang,
                ),
                const SizedBox(height: 14),
                _StageCard(
                  index: 0,
                  active: _stage == 0,
                  icon: Icons.headphones_rounded,
                  title: _t('hz3_listen_title'),
                  hint: _t('hz3_listen_hint'),
                  count: _count[0],
                  lang: lang,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                      for (final (id, key) in _reciters)
                        ChoiceChip(
                          label: Text(_t(key)),
                          selected: _reciter == id,
                          onSelected: _listening
                              ? null
                              : (_) {
                                  setState(() => _reciter = id);
                                  SharedPreferences.getInstance().then((p) => p.setString('hifz3_reciter', id));
                                },
                        ),
                    ]),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: _audio.loading,
                      builder: (context, loading, _) => FilledButton.icon(
                        onPressed: _count[0] >= _times && !_listening ? null : _listen,
                        icon: loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(_listening ? Icons.stop_rounded : Icons.play_arrow_rounded),
                        label: Text(loading
                            ? _t('mushaf_audio_loading')
                            : _listening
                                ? '${_t('hz3_listening')} ${_listenAyah >= 0 ? mushafDigits(_ayat[_listenAyah].ayah, lang) : ''}'
                                : _t('hz3_listen_action').replaceAll('{n}', mushafDigits(_count[0] + 1, lang))),
                      ),
                    ),
                  ]),
                ),
                _StageCard(
                  index: 1,
                  active: _stage == 1,
                  icon: Icons.menu_book_rounded,
                  title: _t('hz3_read_title'),
                  hint: _t('hz3_read_hint'),
                  count: _count[1],
                  lang: lang,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _PageText(ayat: _ayat, highlight: _listenAyah, hidden: false, revealed: const {}, onReveal: (_) {}, lang: lang),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: _count[1] >= _times ? null : () => _bump(1),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(_t('hz3_read_action').replaceAll('{n}', mushafDigits((_count[1] + 1).clamp(1, _times), lang))),
                    ),
                  ]),
                ),
                _StageCard(
                  index: 2,
                  active: _stage == 2,
                  icon: Icons.psychology_alt_rounded,
                  title: _t('hz3_recite_title'),
                  hint: _t('hz3_recite_hint'),
                  count: _count[2],
                  lang: lang,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _PageText(
                      ayat: _ayat,
                      highlight: -1,
                      hidden: true,
                      revealed: _revealed,
                      onReveal: (i) => setState(() => _revealed.contains(i) ? _revealed.remove(i) : _revealed.add(i)),
                      lang: lang,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: _count[2] >= _times
                          ? null
                          : () {
                              setState(_revealed.clear);
                              _bump(2);
                            },
                      icon: const Icon(Icons.record_voice_over_rounded),
                      label: Text(_t('hz3_recite_action').replaceAll('{n}', mushafDigits((_count[2] + 1).clamp(1, _times), lang))),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: MushafChrome.brown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _unit == null || _alreadyMemorized ? null : _finish,
                    icon: Icon(_alreadyMemorized ? Icons.verified_rounded : Icons.bookmark_added_rounded),
                    label: Text(
                      _alreadyMemorized ? _t('hz3_memorized_already') : _t('hz3_finish'),
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                if (!_alreadyMemorized && _stage != -1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_t('hz3_advisory'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ),
              ],
            ),
    );
  }
}

/// Page, surah and a 9-segment progress ring.
class _Header extends StatelessWidget {
  final String surah;
  final int done;
  final int total;
  final bool memorized;
  final String lang;
  const _Header({required this.surah, required this.done, required this.total, required this.memorized, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFFBF3), Color(0xFFF4E7D3)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MushafChrome.gold.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: MushafChrome.brown.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        SizedBox(
          width: 74,
          height: 74,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: done / total),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: v,
                strokeWidth: 7,
                color: memorized ? AppColors.primary : MushafChrome.gold,
                backgroundColor: MushafChrome.gold.withValues(alpha: 0.18),
              ),
              Text('${mushafDigits(done, lang)}/${mushafDigits(total, lang)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MushafChrome.brownDark)),
            ]),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(surah, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MushafChrome.brownDark)),
            const SizedBox(height: 4),
            Text(memorized ? _t('hz3_memorized_already') : _t('hz3_method'),
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}

class _StageCard extends StatelessWidget {
  final int index;
  final bool active;
  final IconData icon;
  final String title;
  final String hint;
  final int count;
  final String lang;
  final Widget child;
  const _StageCard({
    required this.index,
    required this.active,
    required this.icon,
    required this.title,
    required this.hint,
    required this.count,
    required this.lang,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final done = count >= 3;
    final accent = done ? AppColors.primary : MushafChrome.brown;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? MushafChrome.gold : (done ? AppColors.primary.withValues(alpha: 0.35) : MushafChrome.tan),
          width: active ? 1.6 : 1,
        ),
        boxShadow: active
            ? [BoxShadow(color: MushafChrome.gold.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))]
            : const [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(done ? Icons.check_rounded : icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              Text(hint, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            ]),
          ),
          // three dots, filled as each repetition is done
          Row(children: [
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < count ? accent : accent.withValues(alpha: 0.15),
                ),
              ),
          ]),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

/// The page's ayat as text. Hidden mode shows only each ayah's first word
/// (a cue, not the answer); tap an ayah to peek.
class _PageText extends StatelessWidget {
  final List<({int surah, int ayah, String text})> ayat;
  final int highlight;
  final bool hidden;
  final Set<int> revealed;
  final ValueChanged<int> onReveal;
  final String lang;
  const _PageText({
    required this.ayat,
    required this.highlight,
    required this.hidden,
    required this.revealed,
    required this.onReveal,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: MushafChrome.paper, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < ayat.length; i++)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: hidden ? () => onReveal(i) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: i == highlight ? MushafChrome.gold.withValues(alpha: 0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                hidden && !revealed.contains(i)
                    ? '${ayat[i].text.split(' ').first} …  ﴿${mushafDigits(ayat[i].ayah, lang)}﴾'
                    : '${ayat[i].text}  ﴿${mushafDigits(ayat[i].ayah, lang)}﴾',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 19,
                  height: 2.1,
                  color: hidden && !revealed.contains(i) ? MushafChrome.brown : AppColors.textDark,
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
