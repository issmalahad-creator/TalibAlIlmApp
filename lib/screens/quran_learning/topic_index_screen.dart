import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/quran_surahs.dart';
import '../../l10n/basic_translations.dart';
import '../../repositories/quran_corpus_repository.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';
import '../ayah_study_screen.dart';

/// Phase 80 / QC4 — the **Quran Knowledge Index** (offline): search or browse
/// the 6100 Quranpedia topics, land on a topic's places across the Quran, tap
/// an ayah → its dedicated study page.
///
/// Two modes on one screen:
///  * no [topicId]  → search / browse (broadest topics first).
///  * with [topicId] → that topic: sub-topics + every ayah it covers.
///
/// The generic `knowledge_links` graph (hadith / book / lesson edges) is a
/// Phase-E concern; here the index is `quran_topic` + `quran_topic_ayah`.
class TopicIndexScreen extends StatefulWidget {
  final int? topicId;
  final String? title;
  const TopicIndexScreen({super.key, this.topicId, this.title});

  @override
  State<TopicIndexScreen> createState() => _TopicIndexScreenState();
}

class _TopicIndexScreenState extends State<TopicIndexScreen> {
  final _repo = QuranCorpusRepository();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String _title = '';

  // search mode
  List<Map<String, Object?>> _results = const [];

  // topic mode
  List<Map<String, Object?>> _children = const [];
  List<({int surah, int ayah})> _ayat = const [];

  bool get _topicMode => widget.topicId != null;
  String get _lang => LanguagePreferenceService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _title = widget.title ?? '';
    _topicMode ? _loadTopic() : _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTopic() async {
    final id = widget.topicId!;
    final row = _title.isEmpty ? await _repo.topicById(id) : null;
    final children = await _repo.topicChildren(id);
    final ayat = await _repo.topicAyat(id);
    if (!mounted) return;
    setState(() {
      if (row != null) _title = '${row['name'] ?? ''}';
      _children = children;
      _ayat = ayat;
      _loading = false;
    });
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final r = await _repo.searchTopics(q);
    if (!mounted) return;
    setState(() {
      _results = r;
      _loading = false;
    });
  }

  void _openTopic(int id, String name) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TopicIndexScreen(topicId: id, title: name),
        ),
      );

  void _openAyah(int surah, int ayah) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AyahStudyScreen(surah: surah, ayah: ayah),
        ),
      );

  static String _surahName(int n) {
    for (final s in quranSurahs) {
      if (s.number == n) return s.name;
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _topicMode
              ? (_title.isEmpty ? basicText('ql_topics', lang) : _title)
              : basicText('ql_topic_index_title', lang),
          textDirection: TextDirection.rtl,
        ),
      ),
      body: _topicMode ? _topicBody(lang) : _searchBody(lang),
    );
  }

  // ── search / browse ──────────────────────────────────────────────────

  Widget _searchBody(String lang) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: TextField(
            controller: _searchCtrl,
            textDirection: TextDirection.rtl,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              hintText: basicText('ql_topic_search_hint', lang),
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_results.isEmpty)
          Expanded(
            child: Center(
              child: Text(basicText('ql_topic_no_results', lang),
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = _results[i];
                final ayat = (t['ayat'] as num?)?.toInt() ?? 0;
                return ListTile(
                  dense: true,
                  title: Text('${t['name'] ?? ''}',
                      textDirection: TextDirection.rtl),
                  subtitle: ayat == 0
                      ? null
                      : Text('$ayat ${basicText('ql_topic_ayah_word', lang)}',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => _openTopic(
                      t['id'] as int, '${t['name'] ?? ''}'),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── one topic ────────────────────────────────────────────────────────

  Widget _topicBody(String lang) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_children.isEmpty && _ayat.isEmpty) {
      return Center(
        child: Text(basicText('ql_no_data_element', lang),
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }

    // group ayat by surah
    final bySurah = <int, List<int>>{};
    for (final a in _ayat) {
      bySurah.putIfAbsent(a.surah, () => []).add(a.ayah);
    }
    final surahs = bySurah.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_children.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Text(basicText('ql_topic_subtopics', lang),
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in _children)
                  ActionChip(
                    label: Text('${c['name'] ?? ''}',
                        style: const TextStyle(fontSize: 11)),
                    onPressed: () =>
                        _openTopic(c['id'] as int, '${c['name'] ?? ''}'),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),
        ],
        if (_ayat.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
            child: Text(
              '${basicText('ql_topic_places', lang)} · ${_ayat.length}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        for (final s in surahs) ...[
          Container(
            width: double.infinity,
            color: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(_surahName(s),
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.primaryDark)),
          ),
          for (final ayah in bySurah[s]!)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.primaryLight,
                child: Text('$ayah',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.primaryDark)),
              ),
              title: Text('${_surahName(s)} : $ayah',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 13)),
              trailing: const Icon(Icons.chevron_left_rounded, size: 20),
              onTap: () => _openAyah(s, ayah),
            ),
        ],
      ],
    );
  }
}
