import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/basic_translations.dart';
import '../../repositories/quran_corpus_repository.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';

/// Phase 80 / QC5a — «عن المصادر». Every dataset, book and edition the app
/// bundles, with its attribution and licence. Licence-mandatory for the
/// GPL morphology (visible "corpus.quran.com" credit + link) and the
/// per-edition author/publisher IP on the translations.
class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  final _repo = QuranCorpusRepository();

  bool _loading = true;
  List<Map<String, Object?>> _tafsirs = const [];
  List<Map<String, Object?>> _editions = const [];
  List<Map<String, Object?>> _riwayat = const [];
  List<Map<String, Object?>> _reciters = const [];
  String _dumpVersion = '';

  String get _lang => LanguagePreferenceService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tafsirs = await _repo.tafsirBooks();
    final editions = await _repo.translationEditions();
    final riwayat = await _repo.riwayat();
    final reciters = await _repo.reciters();
    final meta = await _repo.corpusMeta();
    String dump = '';
    for (final m in meta) {
      final v = '${m['source_version'] ?? ''}';
      if (v.isNotEmpty) {
        dump = v;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _tafsirs = tafsirs;
      _editions = editions;
      _riwayat = riwayat;
      _reciters = reciters;
      _dumpVersion = dump;
      _loading = false;
    });
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    return Scaffold(
      appBar: AppBar(
        title: Text(basicText('ql_sources_screen_title', lang),
            textDirection: TextDirection.rtl),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                _group(
                  basicText('ql_sources_quran_text', lang),
                  [
                    _line('تنزيل (Tanzil) — رواية حفص عن عاصم · 6236 آية',
                        basicText('ql_sources_primary_text_note', lang)),
                  ],
                ),
                _group(
                  basicText('ql_sources_grammar', lang),
                  [
                    _line(
                      'المدوّنة القرآنية · Quranic Arabic Corpus — '
                      'د. كايس دوكس (رحمه الله)',
                      'GNU GPL — ${basicText('ql_sources_gpl_note', lang)}',
                      link: 'https://corpus.quran.com',
                    ),
                    _line(
                      'شجرة الإعراب القرآني · The Quranic Treebank — NoorBayan',
                      'MIT',
                    ),
                  ],
                ),
                _expandGroup(
                  '${basicText('ql_sources_tafsir', lang)} · '
                  '${_tafsirs.length} · '
                  '${_tafsirs.where((b) => b['bundled'] == 1).length} '
                  '${basicText('ql_sources_bundled', lang)}',
                  [
                    for (final b in _tafsirs)
                      _bookTile(
                        '${b['name'] ?? b['short'] ?? ''}',
                        [
                          if ('${b['author'] ?? ''}'.isNotEmpty) '${b['author']}',
                          if ('${b['year'] ?? ''}'.isNotEmpty) '${b['year']}',
                          if ('${b['nasher'] ?? ''}'.isNotEmpty) '${b['nasher']}',
                        ].join(' · '),
                        bundled: b['bundled'] == 1,
                        lang: lang,
                      ),
                  ],
                ),
                _expandGroup(
                  '${basicText('ql_sources_translations', lang)} · '
                  '${_editions.length}',
                  [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(basicText('ql_sources_ip_note', lang),
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ),
                    for (final e in _editions)
                      _bookTile(
                        '${e['name'] ?? e['short'] ?? ''}',
                        '${e['lang'] ?? e['locale'] ?? ''}',
                        lang: lang,
                      ),
                  ],
                ),
                _group(
                  '${basicText('ql_sources_riwayat', lang)} · ${_riwayat.length}',
                  [
                    for (final r in _riwayat)
                      _line(
                        '${r['name'] ?? ''}'
                        '${'${r['rawi'] ?? ''}'.isNotEmpty ? ' — ${r['rawi']}' : ''}',
                        r['is_primary'] == 1
                            ? basicText('ql_sources_primary', lang)
                            : '',
                      ),
                  ],
                ),
                _expandGroup(
                  '${basicText('ql_sources_reciters', lang)} · '
                  '${_reciters.length} · ${basicText('ql_online', lang)}',
                  [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text('mp3quran.net',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ),
                    for (final r in _reciters)
                      _bookTile(
                        '${r['name_ar'] ?? r['name_en'] ?? ''}',
                        '${r['riwaya_ar'] ?? ''}',
                        lang: lang,
                      ),
                  ],
                ),
                _group(
                  basicText('ql_sources_quranpedia_layers', lang),
                  [
                    _line(
                      'Quranpedia.net — ${basicText('ql_sources_quranpedia_list', lang)}',
                      _dumpVersion.isEmpty
                          ? ''
                          : '${basicText('ql_sources_dump_version', lang)}: $_dumpVersion',
                      link: 'https://quranpedia.net',
                    ),
                  ],
                ),
                _group(
                  basicText('ql_sources_mushaf_art', lang),
                  [
                    _line(
                      'MushafDatabase — Ligature-Based SVG V1.01 · 604 '
                      '${basicText('turath_page_short', lang)}',
                      basicText('ql_sources_sadaqa_note', lang),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // ── building blocks ──────────────────────────────────────────────────

  Widget _group(String title, List<Widget> rows) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(title),
            ...rows,
            const Divider(height: 20),
          ],
        ),
      );

  Widget _expandGroup(String title, List<Widget> rows) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.primaryDark)),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: rows,
        ),
      );

  Widget _header(String title) => Container(
        width: double.infinity,
        color: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Text(title,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: AppColors.primaryDark)),
      );

  Widget _line(String main, String sub, {String? link}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(main,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 12.5, height: 1.6)),
            if (sub.isNotEmpty)
              Text(sub,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textMuted, height: 1.6)),
            if (link != null)
              InkWell(
                onTap: () => _open(link),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(link,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline)),
                ),
              ),
          ],
        ),
      );

  Widget _bookTile(String name, String sub,
          {bool? bundled, required String lang}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 3, 16, 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 12)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (bundled != null) ...[
              const SizedBox(width: 8),
              Text(
                bundled
                    ? basicText('ql_sources_bundled', lang)
                    : basicText('ql_online', lang),
                style: TextStyle(
                    fontSize: 9.5,
                    color: bundled ? AppColors.primary : AppColors.textMuted),
              ),
            ],
          ],
        ),
      );
}
