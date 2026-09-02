import 'dart:async';

import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../models/ayah_study_entry.dart';
import '../repositories/ayah_study_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'ayah_notebook_screen.dart';

/// "دفتر القرآن" — the cross-ayah view over every `ayah_study_entries` row
/// (`79-sa-D-ayah` phase 4). A read-only projection: search all your
/// entries, filter by type / surah / open-questions / for-review, and
/// sort by recency, mushaf order, or "الآيات الأكثر ثراءً". No AI.
class QuranNotebookHomeScreen extends StatefulWidget {
  const QuranNotebookHomeScreen({super.key});

  @override
  State<QuranNotebookHomeScreen> createState() => _QuranNotebookHomeScreenState();
}

enum _Sort { recent, mushaf, richest }

class _QuranNotebookHomeScreenState extends State<QuranNotebookHomeScreen> {
  final _repo = AyahStudyRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};
  final _searchController = TextEditingController();
  Timer? _debounce;

  final Set<String> _typeFilter = {};
  String? _statusFilter; // 'open' | 'review-marker' | null
  _Sort _sort = _Sort.recent;
  String _query = '';

  List<AyahStudyEntry>? _entries;
  List<AyahEntryCount>? _richest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_sort == _Sort.richest && _typeFilter.isEmpty && _statusFilter == null && _query.isEmpty) {
      final r = await _repo.ayatWithEntries(sort: 'richest');
      if (!mounted) return;
      setState(() {
        _richest = r;
        _entries = null;
      });
      return;
    }
    final list = await _repo.notebookEntries(
      entryTypes: _typeFilter.isEmpty ? null : _typeFilter.toList(),
      status: _statusFilter == 'open' ? AyahEntryStatus.open : null,
      query: _query.isEmpty ? null : _query,
      sort: _sort == _Sort.mushaf ? 'mushaf' : 'recent',
    );
    final filtered = _statusFilter == 'review-marker'
        ? list.where((e) => e.entryType == AyahEntryTypes.review).toList()
        : list;
    if (!mounted) return;
    setState(() {
      _entries = filtered;
      _richest = null;
    });
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _query = v.trim();
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(basicText('quran_notebook_title', lang)),
          actions: [
            PopupMenuButton<_Sort>(
              icon: const Icon(Icons.sort_rounded),
              onSelected: (s) {
                setState(() => _sort = s);
                _load();
              },
              itemBuilder: (_) => [
                for (final s in _Sort.values)
                  PopupMenuItem(
                    value: s,
                    child: Text(basicText(
                        s == _Sort.recent
                            ? 'quran_notebook_sort_recent'
                            : s == _Sort.mushaf
                                ? 'quran_notebook_sort_mushaf'
                                : 'quran_notebook_sort_richest',
                        lang)),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: basicText('quran_notebook_search_hint', lang),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip(basicText('ayah_entry_question_open', lang), _statusFilter == 'open', () {
                    setState(() => _statusFilter = _statusFilter == 'open' ? null : 'open');
                    _load();
                  }),
                  _filterChip(basicText('ayah_entry_for_review', lang), _statusFilter == 'review-marker', () {
                    setState(() => _statusFilter = _statusFilter == 'review-marker' ? null : 'review-marker');
                    _load();
                  }),
                  for (final t in AyahEntryTypes.all)
                    _filterChip(basicText('ayah_type_$t', lang), _typeFilter.contains(t), () {
                      setState(() => _typeFilter.contains(t) ? _typeFilter.remove(t) : _typeFilter.add(t));
                      _load();
                    }),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _body(lang)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: FilterChip(
          visualDensity: VisualDensity.compact,
          label: Text(label, style: const TextStyle(fontSize: 11)),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );

  Widget _body(String lang) {
    if (_richest != null) {
      final r = _richest!;
      if (r.isEmpty) return _empty(lang);
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: r.length,
        itemBuilder: (context, i) {
          final row = r[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text('${row.count}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
              ),
              title: Text('${_surahNames[row.surah] ?? row.surah} : ${row.ayah}', textDirection: TextDirection.rtl),
              onTap: () => _openAyah(row.surah, row.ayah),
            ),
          );
        },
      );
    }
    final e = _entries;
    if (e == null) return const Center(child: CircularProgressIndicator());
    if (e.isEmpty) return _empty(lang);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: e.length,
      itemBuilder: (context, i) => _entryCard(e[i], lang),
    );
  }

  Widget _empty(String lang) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(basicText('quran_notebook_empty', lang),
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
        ),
      );

  Widget _entryCard(AyahStudyEntry e, String lang) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _openAyah(e.surah, e.ayah),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${_surahNames[e.surah] ?? e.surah} : ${e.ayah}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(width: 8),
                  Text(basicText('ayah_type_${e.entryType}', lang),
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  if ((e.topic ?? '').isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text('· ${e.topic}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(e.body, textDirection: TextDirection.rtl, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.7)),
              if (e.hasSource) ...[
                const SizedBox(height: 4),
                Text(e.sourceLine, textDirection: TextDirection.rtl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAyah(int surah, int ayah) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AyahNotebookScreen(surah: surah, ayah: ayah)));
    _load();
  }
}
