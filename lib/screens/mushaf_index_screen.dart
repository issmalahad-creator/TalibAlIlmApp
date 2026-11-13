import 'package:flutter/material.dart';

import '../data/madani_page_starts.dart';
import '../data/quran_surah_revelation.dart';
import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../widgets/mushaf/mushaf_chrome_style.dart';
import '../widgets/mushaf/revelation_icon.dart';
import 'mushaf_search_screen.dart';

/// «الفهرس» — the reader's full-screen index: سورة | أجزاء | أرباع, each row
/// with its start page in the edition we draw. The surah list (2026-11-13,
/// Ismail's reference): number strip · the name in the muṣḥaf's script ·
/// «آياتها» · a drawn Kaʿba / green dome · page strip; the surah you are
/// reading is marked and scrolled into view. Pops with the page to open.
class MushafIndexScreen extends StatefulWidget {
  final String lang;
  final bool night;

  /// The page open in the reader — its surah is highlighted (0 = none).
  final int currentPage;
  const MushafIndexScreen({super.key, required this.lang, this.night = false, this.currentPage = 0});

  @override
  State<MushafIndexScreen> createState() => _MushafIndexScreenState();
}

class _MushafIndexScreenState extends State<MushafIndexScreen> {
  final _repo = MushafLayoutRepository();
  int _tab = 0;
  Map<int, int> _surahPages = const {};
  Map<int, int> _juzPages = const {};
  List<(int, int)> _quarters = const [];

  static const _surahRowH = 74.0;

  /// The surah at the top of the reader's page (1-based), or 0.
  int get _currentSurah {
    final p = widget.currentPage;
    if (p < 1 || p > kMadaniPageStarts.length) return 0;
    return kMadaniPageStarts[p - 1].$1;
  }

  late final _surahScroll = ScrollController(
    initialScrollOffset: _currentSurah > 3 ? (_currentSurah - 3) * _surahRowH : 0,
  );

  @override
  void dispose() {
    _surahScroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _repo.surahStartPages().then((m) {
      if (mounted) setState(() => _surahPages = m);
    });
    _repo.juzStartPages().then((m) {
      if (mounted) setState(() => _juzPages = m);
    });
    _repo.quarterBoundaries().then((q) {
      if (mounted) setState(() => _quarters = q);
    });
  }

  /// Page of an ayah in the drawn edition — no query (`kMadaniPageStarts`).
  static int _pageOf(int surah, int ayah) {
    var page = 1;
    for (var i = 1; i < kMadaniPageStarts.length; i++) {
      final (s, a) = kMadaniPageStarts[i];
      if (s > surah || (s == surah && a > ayah)) break;
      page = i + 1;
    }
    return page;
  }

  Future<void> _openSearch() async {
    final page = await Navigator.push<int>(
      context,
      MaterialPageRoute(
          builder: (_) => MushafSearchScreen(lang: widget.lang, night: widget.night)),
    );
    if (page != null && mounted) Navigator.pop(context, page);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final night = widget.night;
    return Scaffold(
      backgroundColor: MushafChrome.bg(night),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(children: [
              Expanded(
                child: Text(basicText('mushaf_index_surahs', lang),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: MushafChrome.fg(night))),
              ),
              MushafSquareButton(
                  icon: Icons.search_rounded,
                  night: night,
                  tooltip: basicText('search_action', lang),
                  onTap: _openSearch),
              const SizedBox(width: 10),
              MushafSquareButton(
                  icon: mushafBackIcon(context),
                  night: night,
                  onTap: () => Navigator.pop(context)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: MushafSegmented(
              night: night,
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
              options: [
                (label: basicText('index_tab_surahs', lang), icon: null),
                (label: basicText('index_tab_juz', lang), icon: null),
                (label: basicText('index_tab_quarters', lang), icon: null),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              0 => _surahList(lang, night),
              1 => _juzList(lang, night),
              _ => _quarterList(lang, night),
            },
          ),
        ]),
      ),
    );
  }

  Widget _row({
    required String title,
    String? subtitle,
    String? badge,
    required int? page,
    required bool night,
    required String lang,
  }) {
    final fg = MushafChrome.fg(night);
    return InkWell(
      onTap: page == null ? null : () => Navigator.pop(context, page),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: MushafChrome.line(night))),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 15, color: MushafChrome.gold),
                  const SizedBox(width: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600, color: MushafChrome.gold)),
                ]),
              ],
            ]),
          ),
          if (badge != null) Padding(padding: const EdgeInsetsDirectional.only(end: 10), child: Text(badge, style: const TextStyle(fontSize: 20))),
          if (page != null)
            Text('${basicText('page_label', lang)} ${mushafDigits(page, lang)}',
                style: TextStyle(fontSize: 13.5, color: fg.withValues(alpha: 0.8))),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }

  Widget _surahList(String lang, bool night) => ListView.builder(
        controller: _surahScroll,
        itemExtent: _surahRowH,
        itemCount: quranSurahs.length,
        itemBuilder: (_, i) => _surahRow(i, lang, night),
      );

  Widget _surahRow(int i, String lang, bool night) {
    final s = quranSurahs[i];
    final page = _surahPages[s.number];
    final meccan = kSurahMeccan[i];
    final fg = MushafChrome.fg(night);
    final here = s.number == _currentSurah;
    final strip = night ? Colors.black.withValues(alpha: 0.35) : MushafChrome.tan;
    final stripFg = night ? MushafChrome.gold : MushafChrome.brownDark;
    final numStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: stripFg);
    final rowBg = here
        ? MushafChrome.gold.withValues(alpha: night ? 0.22 : 0.16)
        : (night ? Colors.transparent : MushafChrome.paper);
    return Material(
      color: rowBg,
      child: InkWell(
        onTap: page == null ? null : () => Navigator.pop(context, page),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: MushafChrome.line(night)))),
          child: Row(children: [
            // surah number
            Container(
              width: 46,
              color: strip,
              alignment: Alignment.center,
              child: Text(mushafDigits(s.number, lang), style: numStyle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // AmiriQuran's tall ascent: a tight line box + a
                      // fixed strut, or the name sits on the line below it
                      strutStyle: const StrutStyle(fontSize: 20, height: 1.2, forceStrutHeight: true),
                      style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 1.2, color: fg)),
                  const SizedBox(height: 6),
                  Text(
                    '${basicText(meccan ? 'surah_meccan' : 'surah_medinan', lang)} · '
                    '${basicText('surah_ayat_count', lang)} ${mushafDigits(s.ayahCount, lang)}',
                    style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.62)),
                  ),
                ],
              ),
            ),
            if (here)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Icon(Icons.bookmark_rounded, size: 18, color: MushafChrome.gold),
              ),
            RevelationIcon(meccan: meccan, size: 32),
            const SizedBox(width: 12),
            // start page
            Container(
              width: 54,
              color: strip,
              alignment: Alignment.center,
              child: Text(page == null ? '' : mushafDigits(page, lang), style: numStyle),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _juzList(String lang, bool night) => ListView.builder(
        itemCount: 30,
        itemBuilder: (_, i) => _row(
          title: '${basicText('juz_label', lang)} ${i + 1}',
          page: _juzPages[i + 1],
          night: night,
          lang: lang,
        ),
      );

  /// The 240 rubʿ al-ḥizb: «الحزب ٣» for its start, then ¼ ½ ¾ — each with
  /// the ayah it opens on.
  Widget _quarterList(String lang, bool night) => ListView.builder(
        itemCount: _quarters.length,
        itemBuilder: (_, i) {
          final (s, a) = _quarters[i];
          final hizb = i ~/ 4 + 1;
          final part = const ['', '¼ ', '½ ', '¾ '][i % 4];
          return _row(
            title: '$part${basicText('hizb_label', lang)} ${mushafDigits(hizb, lang)}',
            subtitle: '${basicText('juz_label', lang)} ${mushafDigits((hizb + 1) ~/ 2, lang)} – ${quranSurahs[s - 1].name} ${mushafDigits(a, lang)}',
            page: _pageOf(s, a),
            night: night,
            lang: lang,
          );
        },
      );
}
