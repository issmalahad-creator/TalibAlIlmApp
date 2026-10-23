import 'package:flutter/material.dart';

import '../data/quran_surah_revelation.dart';
import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../widgets/mushaf/mushaf_chrome_style.dart';
import 'mushaf_search_screen.dart';

/// «الفهرس» — the reader's full-screen index: سورة | أجزاء, each row with its
/// MushafDatabase start page. Pops with the page to open (or null).
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

  @override
  void initState() {
    super.initState();
    _repo.surahStartPages().then((m) {
      if (mounted) setState(() => _surahPages = m);
    });
    _repo.juzStartPages().then((m) {
      if (mounted) setState(() => _juzPages = m);
    });
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
              ],
            ),
          ),
          Expanded(child: _tab == 0 ? _surahList(lang, night) : _juzList(lang, night)),
        ]),
      ),
    );
  }

  Widget _row({
    required String title,
    String? subtitle,
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
}
