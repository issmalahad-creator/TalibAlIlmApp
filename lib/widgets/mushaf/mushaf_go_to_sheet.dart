import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/quran_surahs.dart';
import '../../l10n/basic_translations.dart';
import '../../repositories/mushaf_layout_repository.dart';
import '../../theme/app_theme.dart';
import 'go_to_query.dart';
import 'mushaf_chrome_style.dart';

/// «انتقل إلى» (Ismail 2026-10-22: «بدائي… ابحث وارجع بشيء جديد وجميل»).
/// Three layers, each one gesture from a page:
///  1. one smart field — «٣٢٣», «الكهف», «البقرة ٢٥٥», «جزء ١٧», «2:255»
///     ([parseGoToQuery]); results go on tap;
///  2. the muṣḥaf's pages as a 3D wheel of paper leaves — turn it, the centre
///     leaf shows surah · juzʼ and the page's opening words, then «اذهب»;
///  3. quick jumps — where you were before your last jumps, your bookmarks,
///     and the 30 ajzāʼ, each opening onto its 8 quarters.
/// Typed digits from any keyboard work (an Arabic keyboard types ٠–٩).
/// Returns the MushafDatabase page, or null.
Future<int?> showMushafGoToSheet(
  BuildContext context, {
  required int current,
  required String lang,
  bool night = false,
  Map<int, Color> bookmarks = const {},
}) async {
  final page = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GoToSheet(current: current, lang: lang, night: night, bookmarks: bookmarks),
  );
  if (page != null && page != current) {
    try {
      await GoToRecents.push(current);
    } catch (_) {
      // history is a convenience; the jump itself must never fail on it
    }
  }
  return page;
}

/// The pages the reader jumped *from*, newest first — «ارجع إلى حيث كنت».
class GoToRecents {
  GoToRecents._();
  static const _key = 'mushaf_goto_recent_v1';
  static const _max = 4;

  static Future<List<int>> get() async {
    final raw = (await SharedPreferences.getInstance()).getStringList(_key) ?? const [];
    return [for (final s in raw) ?int.tryParse(s)];
  }

  static Future<void> push(int page) async {
    final p = await SharedPreferences.getInstance();
    final list = [page, ...(p.getStringList(_key) ?? const []).map(int.tryParse).whereType<int>().where((x) => x != page)];
    await p.setStringList(_key, [for (final x in list.take(_max)) '$x']);
  }
}

class _GoToSheet extends StatefulWidget {
  final int current;
  final String lang;
  final bool night;
  final Map<int, Color> bookmarks;
  const _GoToSheet({required this.current, required this.lang, required this.night, required this.bookmarks});

  @override
  State<_GoToSheet> createState() => _GoToSheetState();
}

class _GoToSheetState extends State<_GoToSheet> {
  static const _pages = 604;
  final _repo = MushafLayoutRepository();
  final _field = TextEditingController();
  late final FixedExtentScrollController _wheel = FixedExtentScrollController(initialItem: widget.current - 1);
  late int _value = widget.current;
  String _query = '';
  List<int> _recents = const [];
  int? _openJuz;
  List<int> _quarters = const [];
  String _opening = '';
  Timer? _openingDebounce;

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
      // No previews, but every page number still works.
    });
    GoToRecents.get().then((r) {
      if (mounted) setState(() => _recents = r.where((p) => p != widget.current).toList());
    }).catchError((Object _) {});
    _loadOpening();
  }

  @override
  void dispose() {
    _openingDebounce?.cancel();
    _field.dispose();
    _wheel.dispose();
    super.dispose();
  }

  String _t(String k) => basicText(k, widget.lang);
  String _n(int n) => mushafDigits(n, widget.lang);

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

  String _where(int page) {
    final s = _containing(_surahStart, page);
    final j = _containing(_juzStart, page);
    return [
      if (s != null) quranSurahs[s - 1].name,
      if (j != null) '${_t('juz_label')} ${_n(j)}',
    ].join('  –  ');
  }

  void _loadOpening() {
    _openingDebounce?.cancel();
    final page = _value;
    _openingDebounce = Timer(const Duration(milliseconds: 140), () {
      _repo.openingWords(page).then((w) {
        if (mounted && page == _value) setState(() => _opening = w);
      }).catchError((Object _) {});
    });
  }

  void _go(int page) {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, page.clamp(1, _pages));
  }

  Future<void> _goHit(GoToHit h) async {
    final page = switch (h.kind) {
      GoToKind.page => h.n,
      GoToKind.juz => _juzStart[h.n] ?? await _repo.pageForJuz(h.n),
      GoToKind.hizb => _hizbStart[h.n] ?? await _repo.pageForHizb(h.n),
      GoToKind.surah => _surahStart[h.n] ?? await _repo.pageForReference(h.n),
      GoToKind.ayah => await _repo.pageForReference(h.n, ayah: h.ayah!),
    };
    if (page != null && mounted) _go(page);
  }

  void _wheelTo(int page) {
    _wheel.animateToItem(page - 1, duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
  }

  Future<void> _toggleJuz(int juz) async {
    if (_openJuz == juz) {
      setState(() => _openJuz = null);
      return;
    }
    setState(() {
      _openJuz = juz;
      _quarters = const [];
    });
    final start = _juzStart[juz];
    if (start != null) _wheelTo(start);
    final q = await _repo.quarterStartPages(juz).catchError((Object _) => <int>[]);
    if (mounted && _openJuz == juz) setState(() => _quarters = q);
  }

  @override
  Widget build(BuildContext context) {
    final night = widget.night;
    final fg = MushafChrome.fg(night);
    final bg = night ? AppColors.surfaceNight : MushafChrome.paper;
    final hits = parseGoToQuery(_query, pages: _pages);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: MushafChrome.gold.withValues(alpha: 0.6), width: 1.2)),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -6))],
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(color: fg.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 10),
            Text(_t('mushaf_go_to_title'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SearchField(
                controller: _field,
                night: night,
                hint: _t('mushaf_go_to_search_hint'),
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (_) {
                  if (hits.isNotEmpty) _goHit(hits.first);
                },
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _query.trim().isNotEmpty ? _results(hits, fg) : _browse(fg, night),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── 1. results ────────────────────────────────────────────────────
  Widget _results(List<GoToHit> hits, Color fg) {
    if (hits.isEmpty) {
      return Padding(
        key: const ValueKey('none'),
        padding: const EdgeInsets.all(28),
        child: Text(_t('mushaf_go_to_no_match'),
            textAlign: TextAlign.center, style: TextStyle(color: fg.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
      );
    }
    return ListView(
      key: const ValueKey('hits'),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        for (final (i, h) in hits.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HitTile(
              icon: switch (h.kind) {
                GoToKind.page => Icons.menu_book_rounded,
                GoToKind.juz => Icons.layers_outlined,
                GoToKind.hizb => Icons.grid_view_rounded,
                GoToKind.surah => Icons.auto_stories_outlined,
                GoToKind.ayah => Icons.format_quote_rounded,
              },
              title: switch (h.kind) {
                GoToKind.page => '${_t('page_label')} ${_n(h.n)}',
                GoToKind.juz => '${_t('juz_label')} ${_n(h.n)}',
                GoToKind.hizb => '${_t('hizb_label')} ${_n(h.n)}',
                GoToKind.surah => quranSurahs[h.n - 1].name,
                GoToKind.ayah => '${quranSurahs[h.n - 1].name}  –  ${_t('ayah_label')} ${_n(h.ayah!)}',
              },
              subtitle: switch (h.kind) {
                GoToKind.page => _where(h.n),
                GoToKind.juz => _juzStart[h.n] == null ? '' : '${_t('page_label')} ${_n(_juzStart[h.n]!)}',
                GoToKind.hizb => _hizbStart[h.n] == null ? '' : '${_t('page_label')} ${_n(_hizbStart[h.n]!)}',
                GoToKind.surah => _surahStart[h.n] == null ? '' : '${_t('page_label')} ${_n(_surahStart[h.n]!)}',
                GoToKind.ayah => '',
              },
              primary: i == 0,
              onTap: () => _goHit(h),
            ),
          ),
      ],
    );
  }

  // ── 2 + 3. the wheel and quick jumps ───────────────────────────────
  Widget _browse(Color fg, bool night) {
    final marks = widget.bookmarks.keys.toList()..sort();
    return SingleChildScrollView(
      key: const ValueKey('browse'),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 150,
          child: RotatedBox(
            // the wheel's top turns to the right: page 1 sits at the right,
            // as in an Arabic muṣḥaf
            quarterTurns: 1,
            child: ListWheelScrollView.useDelegate(
              controller: _wheel,
              itemExtent: 78,
              diameterRatio: 1.5,
              perspective: 0.004,
              squeeze: 0.92,
              useMagnifier: true,
              magnification: 1.12,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _value = i + 1);
                _loadOpening();
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _pages,
                builder: (context, i) => RotatedBox(
                  quarterTurns: 3,
                  child: _Leaf(
                    page: i + 1,
                    label: _n(i + 1),
                    surah: switch (_containing(_surahStart, i + 1)) { final s? => quranSurahs[s - 1].name, _ => '' },
                    bookmark: widget.bookmarks[i + 1],
                    here: i + 1 == widget.current,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(_where(_value),
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.8))),
        SizedBox(
          height: 30,
          child: Center(
            child: Text(
              _opening,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 15, color: MushafChrome.brownDark.withValues(alpha: night ? 0.9 : 1)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: SizedBox(
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: MushafChrome.brown,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _go(_value),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text('${_t('go_action')}  –  ${_t('page_label')} ${_n(_value)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        if (_recents.isNotEmpty || marks.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final p in _recents)
                  _Chip(
                    icon: Icons.history_rounded,
                    label: '${_t('page_label')} ${_n(p)}',
                    sub: switch (_containing(_surahStart, p)) { final s? => quranSurahs[s - 1].name, _ => '' },
                    night: night,
                    onTap: () => _go(p),
                  ),
                for (final p in marks)
                  _Chip(
                    icon: Icons.bookmark_rounded,
                    iconColor: widget.bookmarks[p],
                    label: '${_t('page_label')} ${_n(p)}',
                    sub: switch (_containing(_surahStart, p)) { final s? => quranSurahs[s - 1].name, _ => '' },
                    night: night,
                    onTap: () => _go(p),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(_t('mushaf_go_to_juz_grid'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            crossAxisCount: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 0.92,
            children: [
              for (var j = 1; j <= 30; j++)
                _JuzTile(
                  label: _n(j),
                  open: _openJuz == j,
                  here: _containing(_juzStart, widget.current) == j,
                  night: night,
                  onTap: () => _toggleJuz(j),
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: _openJuz == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: _quarters.isEmpty
                      ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                      : Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final (k, p) in _quarters.indexed)
                              _QuarterTile(
                                // ḥizb number on its opening quarter, then ¼ ½ ¾
                                label: k % 4 == 0
                                    ? '${_t('hizb_label')} ${_n((_openJuz! - 1) * 2 + k ~/ 4 + 1)}'
                                    : const ['', '¼', '½', '¾'][k % 4],
                                page: '${_t('page_label')} ${_n(p)}',
                                night: night,
                                onTap: () => _go(p),
                              ),
                          ],
                        ),
                ),
        ),
      ]),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool night;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  const _SearchField({
    required this.controller,
    required this.night,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.go,
        style: TextStyle(color: MushafChrome.fg(night), fontSize: 15, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: night ? AppColors.backgroundNight : Colors.white,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: MushafChrome.fg(night).withValues(alpha: 0.45)),
          prefixIcon: const Icon(Icons.search_rounded, color: MushafChrome.brown),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, v, _) => v.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: MushafChrome.gold.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: MushafChrome.gold.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: MushafChrome.gold, width: 1.6),
          ),
        ),
      );
}

/// One muṣḥaf leaf on the wheel.
class _Leaf extends StatelessWidget {
  final int page;
  final String label;
  final String surah;
  final Color? bookmark;
  final bool here;
  const _Leaf({required this.page, required this.label, required this.surah, required this.bookmark, required this.here});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: page.isOdd ? Alignment.centerRight : Alignment.centerLeft,
                end: page.isOdd ? Alignment.centerLeft : Alignment.centerRight,
                colors: const [Color(0xFFFFFCF5), Color(0xFFF1E6D0)],
              ),
              border: Border.all(color: here ? MushafChrome.brown : MushafChrome.gold.withValues(alpha: 0.7), width: here ? 2 : 1),
              boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.fromLTRB(5, 8, 5, 6),
            child: Column(children: [
              Text(surah,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: MushafChrome.brown)),
              const Spacer(),
              // faint «lines of text»
              for (var i = 0; i < 4; i++)
                Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 4),
                  color: MushafChrome.brown.withValues(alpha: 0.12),
                ),
              const Spacer(),
              Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MushafChrome.brownDark)),
            ]),
          ),
          if (bookmark != null)
            Positioned(top: -2, left: 8, child: Icon(Icons.bookmark_rounded, size: 18, color: bookmark)),
        ]),
      );
}

class _HitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool primary;
  final VoidCallback onTap;
  const _HitTile({required this.icon, required this.title, required this.subtitle, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: primary ? MushafChrome.brown : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: primary ? 3 : 0,
        shadowColor: MushafChrome.brown.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(icon, color: primary ? Colors.white : MushafChrome.brown),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: primary ? Colors.white : MushafChrome.brownDark)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: primary ? Colors.white70 : AppColors.textMuted)),
                ]),
              ),
              Icon(Icons.arrow_back_rounded, size: 18, color: primary ? Colors.white : MushafChrome.brown),
            ]),
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String sub;
  final bool night;
  final VoidCallback onTap;
  const _Chip({required this.icon, this.iconColor, required this.label, required this.sub, required this.night, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Material(
          color: night ? AppColors.backgroundNight : Colors.white,
          shape: StadiumBorder(side: BorderSide(color: MushafChrome.gold.withValues(alpha: 0.45))),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 17, color: iconColor ?? MushafChrome.brown),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: MushafChrome.fg(night))),
                if (sub.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(sub, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ]),
            ),
          ),
        ),
      );
}

class _JuzTile extends StatelessWidget {
  final String label;
  final bool open;
  final bool here;
  final bool night;
  final VoidCallback onTap;
  const _JuzTile({required this.label, required this.open, required this.here, required this.night, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, open ? -3 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: open
                ? const LinearGradient(colors: [MushafChrome.brown, MushafChrome.brownDark])
                : LinearGradient(colors: night ? const [Color(0xFF2B2B2B), Color(0xFF222222)] : const [Colors.white, Color(0xFFF6EEDF)]),
            border: Border.all(color: here ? MushafChrome.brown : MushafChrome.gold.withValues(alpha: 0.35), width: here ? 1.6 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: open ? 0.25 : 0.06),
                blurRadius: open ? 10 : 4,
                offset: Offset(0, open ? 5 : 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w900, color: open ? Colors.white : MushafChrome.fg(night))),
        ),
      );
}

class _QuarterTile extends StatelessWidget {
  final String label;
  final String page;
  final bool night;
  final VoidCallback onTap;
  const _QuarterTile({required this.label, required this.page, required this.night, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: night ? AppColors.backgroundNight : const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MushafChrome.gold.withValues(alpha: 0.5)),
            ),
            child: Column(children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: MushafChrome.brownDark)),
              Text(page, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ]),
          ),
        ),
      );
}
