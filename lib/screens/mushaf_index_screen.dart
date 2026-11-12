import 'package:flutter/material.dart';

import '../data/madani_page_starts.dart';
import '../data/quran_surah_revelation.dart';
import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../widgets/mushaf/mushaf_chrome_style.dart';
import 'mushaf_search_screen.dart';

/// «الفهرس» — the reader's full-screen index: سورة | أجزاء | أرباع, each row
/// with its start page in the edition we draw. Surahs carry 🕋 / 🕌 for
/// Meccan / Medinan. Pops with the page to open (or null).
class MushafIndexScreen extends StatefulWidget {
  final String lang;
  final bool night;
  const MushafIndexScreen({super.key, required this.lang, this.night = false});

  @override
  State<MushafIndexScreen> createState() => _MushafIndexScreenState();
}

class _MushafIndexScreenState extends State<MushafIndexScreen> {
  final _repo = MushafLayoutRepository();
  int _tab = 0;
  Map<int, int> _surahPages = const {};
  Map<int, int> _juzPages = const {};
  List<(int, int)> _quarters = const [];

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
        itemCount: quranSurahs.length,
        itemBuilder: (_, i) {
          final s = quranSurahs[i];
          final type = basicText(kSurahMeccan[i] ? 'surah_meccan' : 'surah_medinan', lang);
          return _row(
            title: '${s.number} – ${basicText('surah_word', lang)} ${s.name}',
            subtitle: '$type – ${basicText('surah_ayat_count', lang)} ${s.ayahCount}',
            badge: kSurahMeccan[i] ? '🕋' : '🕌',
            page: _surahPages[s.number],
            night: night,
            lang: lang,
          );
        },
      );

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
