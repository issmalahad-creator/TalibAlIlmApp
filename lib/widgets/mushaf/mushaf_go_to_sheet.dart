import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/quran_surahs.dart';
import '../../l10n/basic_translations.dart';
import '../../repositories/mushaf_layout_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/digits.dart';
import 'mushaf_chrome_style.dart';

/// «انتقل إلى»: pick a page, juzʼ or ḥizb and see where it lands before
/// going — a slider across the whole muṣḥaf with a live «سورة · جزء»
/// preview, ± steppers, and an empty number field (the old dialog came
/// pre-filled with the current page, so typing appended to it — «581300» —
/// and silently did nothing). Returns the MushafDatabase page, or null.
Future<int?> showMushafGoToSheet(BuildContext context,
    {required int current, required String lang, bool night = false}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GoToSheet(current: current, lang: lang, night: night),
  );
}

enum _Mode { page, juz, hizb }

class _GoToSheet extends StatefulWidget {
  final int current;
  final String lang;
  final bool night;
  const _GoToSheet({required this.current, required this.lang, required this.night});

  @override
  State<_GoToSheet> createState() => _GoToSheetState();
}

class _GoToSheetState extends State<_GoToSheet> {
  static const _pages = 604;
  final _repo = MushafLayoutRepository();
  final _field = TextEditingController();
  _Mode _mode = _Mode.page;
  late int _value = widget.current;
  bool _invalid = false;

  // first page of every surah / juzʼ / ḥizb — the live preview reads these
  // synchronously while the slider moves.
  Map<int, int> _surahStart = const {};
  Map<int, int> _juzStart = const {};
  Map<int, int> _hizbStart = const {};

  @override
  void initState() {
    super.initState();
    Future.wait([_repo.surahStartPages(), _repo.juzStartPages(), _repo.hizbStartPages()]).then((m) {
      if (!mounted) return;
      setState(() {
        _surahStart = m[0];
        _juzStart = m[1];
        _hizbStart = m[2];
      });
    }).catchError((Object _) {
      // No preview, but the page number still works.
    });
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  String _t(String k) => basicText(k, widget.lang);
  String _n(int n) => mushafDigits(n, widget.lang);

  int get _max => switch (_mode) { _Mode.page => _pages, _Mode.juz => 30, _Mode.hizb => 60 };

  /// The page the current value means.
  int? get _targetPage => switch (_mode) {
        _Mode.page => _value,
        _Mode.juz => _juzStart[_value],
        _Mode.hizb => _hizbStart[_value],
      };

  /// The last key whose start page is ≤ [page].
  static int? _containing(Map<int, int> starts, int page) {
    int? best;
    var bestPage = 0;
    starts.forEach((k, p) {
      if (p <= page && p >= bestPage) {
        best = k;
        bestPage = p;
      }
    });
    return best;
  }

  void _setMode(_Mode m) {
    if (m == _mode) return;
    final page = _targetPage ?? widget.current;
    setState(() {
      _mode = m;
      _value = switch (m) {
        _Mode.page => page,
        _Mode.juz => _containing(_juzStart, page) ?? 1,
        _Mode.hizb => _containing(_hizbStart, page) ?? 1,
      };
      _field.clear();
      _invalid = false;
    });
  }

  void _set(int v, {bool fromField = false}) {
    final clamped = v.clamp(1, _max);
    if (clamped != _value) HapticFeedback.selectionClick();
    setState(() {
      _value = clamped;
      _invalid = false;
      if (!fromField) _field.clear();
    });
  }

  void _onTyped(String s) {
    final v = parseAnyDigits(s);
    if (s.trim().isEmpty) {
      setState(() => _invalid = false);
      return;
    }
    if (v == null || v < 1 || v > _max) {
      setState(() => _invalid = true);
      return;
    }
    _set(v, fromField: true);
  }

  void _go() {
    final p = _targetPage;
    if (p == null || _invalid) return;
    Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final night = widget.night;
    final fg = MushafChrome.fg(night);
    final bg = night ? AppColors.surfaceNight : MushafChrome.paper;
    final page = _targetPage;
    final surah = page == null ? null : _containing(_surahStart, page);
    final juz = page == null ? null : _containing(_juzStart, page);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: MushafChrome.gold.withValues(alpha: 0.6), width: 1.2)),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -6))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: fg.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              Text(_t('mushaf_go_to_title'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
              const SizedBox(height: 12),
              MushafSegmented(
                night: night,
                selected: _mode.index,
                onChanged: (i) => _setMode(_Mode.values[i]),
                options: [
                  (label: _t('page_label'), icon: Icons.menu_book_rounded),
                  (label: _t('juz_label'), icon: Icons.layers_outlined),
                  (label: _t('hizb_label'), icon: Icons.grid_view_rounded),
                ],
              ),
              const SizedBox(height: 18),
              // The number, big, with ± steppers.
              Row(children: [
                _Step(icon: Icons.remove_rounded, night: night, onTap: () => _set(_value - 1)),
                Expanded(
                  child: Column(children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      transitionBuilder: (c, a) => FadeTransition(
                          opacity: a, child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(a), child: c)),
                      child: Text(_n(_value),
                          key: ValueKey('$_mode$_value'),
                          style: TextStyle(fontSize: 44, height: 1.1, fontWeight: FontWeight.w800, color: MushafChrome.brownDark)),
                    ),
                    const SizedBox(height: 4),
                    // Live «where this lands».
                    Text(
                      surah == null
                          ? ' '
                          : '${quranSurahs[surah - 1].name}'
                              '${juz != null ? '  ·  ${_t('juz_label')} ${_n(juz)}' : ''}'
                              '${_mode != _Mode.page && page != null ? '  ·  ${_t('page_label')} ${_n(page)}' : ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.75), fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
                _Step(icon: Icons.add_rounded, night: night, onTap: () => _set(_value + 1)),
              ]),
              const SizedBox(height: 6),
              // Right = 1 in an RTL muṣḥaf.
              Directionality(
                textDirection: TextDirection.rtl,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: MushafChrome.gold,
                    inactiveTrackColor: MushafChrome.gold.withValues(alpha: 0.2),
                    thumbColor: MushafChrome.brown,
                    overlayColor: MushafChrome.gold.withValues(alpha: 0.15),
                    trackHeight: 5,
                  ),
                  child: Slider(
                    min: 1,
                    max: _max.toDouble(),
                    value: _value.toDouble().clamp(1, _max.toDouble()),
                    onChanged: (v) => _set(v.round()),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _field,
                keyboardType: TextInputType.number,
                inputFormatters: [const AnyDigitsFormatter(), LengthLimitingTextInputFormatter(3)],
                textInputAction: TextInputAction.go,
                textAlign: TextAlign.center,
                onChanged: _onTyped,
                onSubmitted: (_) => _go(),
                style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: _t('mushaf_go_to_hint').replaceAll('{max}', _n(_max)),
                  errorText: _invalid ? _t('mushaf_go_to_invalid').replaceAll('{max}', _n(_max)) : null,
                  prefixIcon: Icon(Icons.dialpad_rounded, color: fg.withValues(alpha: 0.6)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: MushafChrome.brown,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: page == null || _invalid ? null : _go,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(
                    page == null ? _t('mushaf_go_to_title') : '${_t('go_action')} · ${_t('page_label')} ${_n(page)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final bool night;
  final VoidCallback onTap;
  const _Step({required this.icon, required this.night, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: night ? AppColors.backgroundNight : Colors.white,
        shape: CircleBorder(side: BorderSide(color: MushafChrome.gold.withValues(alpha: 0.5))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: MushafChrome.brownDark),
          ),
        ),
      );
}
