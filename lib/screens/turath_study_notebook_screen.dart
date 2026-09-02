import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'study_benefits_map_screen.dart';
import 'turath_reader_screen.dart';

/// "دفتر الفوائد" — the unified notebook (Phase 79 `79-sa-D`). The single
/// primary surface for every Study Annotation: the full highlighted text,
/// its note, colour, type, book, author, category and page — all read
/// straight from `turath_annotations` (no copy, no new table). Migrated
/// legacy notes/quotes appear here automatically. Tapping a row deep-links
/// to the exact spot in the reader.
class TurathStudyNotebookScreen extends StatefulWidget {
  /// When set, the notebook opens pre-scoped to one book ("فوائدي في هذا الكتاب").
  final int? bookId;
  final String? bookTitle;

  const TurathStudyNotebookScreen({super.key, this.bookId, this.bookTitle});

  @override
  State<TurathStudyNotebookScreen> createState() => _TurathStudyNotebookScreenState();
}

class _TurathStudyNotebookScreenState extends State<TurathStudyNotebookScreen> {
  final _repo = TurathRepository();
  final _searchController = TextEditingController();
  Timer? _debounce;

  final Set<String> _colorFilter = {};
  String _query = '';
  /// '' = all · 'highlight' = text highlights only · 'page_note' = page notes only
  String _kindFilter = '';
  List<NotebookEntry>? _entries;

  List<NotebookEntry> get _visible {
    final all = _entries ?? const <NotebookEntry>[];
    return switch (_kindFilter) {
      'page_note' => [for (final e in all) if (e.annotation.isPageLevel) e],
      'highlight' => [for (final e in all) if (!e.annotation.isPageLevel) e],
      _ => all,
    };
  }

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
    final entries = await _repo.notebookEntries(
      bookId: widget.bookId,
      colorKeys: _colorFilter.isEmpty ? null : _colorFilter.toList(),
      query: _query.isEmpty ? null : _query,
    );
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = v.trim();
      _load();
    });
  }

  String _typeLabel(String? type, String lang) {
    switch (type) {
      case 'explain':
        return basicText('turath_annotation_type_explain', lang);
      case 'memorize':
        return basicText('turath_annotation_type_memorize', lang);
      case 'important':
        return basicText('turath_annotation_type_important', lang);
      case 'question':
        return basicText('turath_annotation_type_question', lang);
      case 'correction':
        return basicText('turath_annotation_type_correction', lang);
      default:
        return basicText('turath_annotation_type_benefit', lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.bookTitle ?? basicText('turath_notebook_title', lang),
              textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 16)),
          actions: [
            IconButton(
              tooltip: basicText('study_map_title', lang),
              icon: const Icon(Icons.insights_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudyBenefitsMapScreen(bookId: widget.bookId, bookTitle: widget.bookTitle),
                ),
              ),
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
                  hintText: basicText('turath_notebook_search_hint', lang),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  for (final (k, labelKey) in const [
                    ('', 'turath_notebook_kind_all'),
                    ('highlight', 'turath_highlight_action'),
                    ('page_note', 'turath_page_note_action'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(basicText(labelKey, lang),
                            style: const TextStyle(fontSize: 11)),
                        selected: _kindFilter == k,
                        onSelected: (_) => setState(() => _kindFilter = k),
                      ),
                    ),
                  const SizedBox(width: 6),
                  for (final key in StudyAnnotationColors.all)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        visualDensity: VisualDensity.compact,
                        avatar: CircleAvatar(backgroundColor: AppColors.studyAnnotation(key).$3, radius: 6),
                        label: Text(_typeLabel(key, lang), style: const TextStyle(fontSize: 11)),
                        selected: _colorFilter.contains(key),
                        onSelected: (on) {
                          setState(() => on ? _colorFilter.add(key) : _colorFilter.remove(key));
                          _load();
                        },
                      ),
                    ),
                ]),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _body(lang)),
          ],
        ),
      ),
    );
  }

  Widget _body(String lang) {
    if (_entries == null) return const Center(child: CircularProgressIndicator());
    final entries = _visible;
    if (entries.isEmpty) {
      return Center(child: Text(basicText('turath_notebook_empty', lang), style: const TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, i) => _EntryCard(
        entry: entries[i],
        typeLabel: _typeLabel(entries[i].annotation.noteType, lang),
        lang: lang,
        onTap: () => _openReader(entries[i].annotation, reanchor: false),
        onReanchor: () => _openReader(entries[i].annotation, reanchor: true),
      ),
    );
  }

  Future<void> _openReader(StudyAnnotation a, {required bool reanchor}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TurathReaderScreen(
          bookId: a.bookId,
          bookName: a.bookName,
          pageNumber: a.pageNumber,
          focusAnnotationId: reanchor ? null : a.id,
          editRangeAnnotationId: reanchor ? a.id : null,
        ),
      ),
    );
    _load(); // reflect edits/deletes/re-anchors made in the reader
  }
}

class _EntryCard extends StatelessWidget {
  final NotebookEntry entry;
  final String typeLabel;
  final String lang;
  final VoidCallback onTap;
  final VoidCallback onReanchor;
  const _EntryCard({required this.entry, required this.typeLabel, required this.lang, required this.onTap, required this.onReanchor});

  @override
  Widget build(BuildContext context) {
    final a = entry.annotation;
    final (_, _, accent) = AppColors.studyAnnotation(a.colorKey);
    final source = [
      a.bookName,
      if ((a.authorName ?? '').isNotEmpty) a.authorName!,
      if ((entry.categoryName ?? '').isNotEmpty) entry.categoryName!,
      '${basicText('turath_page_short', lang)} ${a.pageNumber}',
    ].join(' — ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(typeLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  if (a.isPageLevel) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.sticky_note_2_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(basicText('turath_page_note_action', lang),
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                  if (a.anchorStatus == 'orphan' && !a.isPageLevel) ...[
                    const SizedBox(width: 6),
                    Text('· ${basicText('turath_annotation_orphan', lang)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ],
              ),
              if (!a.isPageLevel) ...[
                const SizedBox(height: 6),
                Text(
                  a.selectedText!,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 14, height: 1.7),
                ),
              ],
              if (a.hasNote) ...[
                const SizedBox(height: 6),
                Text(a.noteBody!, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 12.5, color: AppColors.textDark)),
              ],
              const SizedBox(height: 8),
              Text(source, textDirection: TextDirection.rtl, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.primary)),
              if (a.anchorStatus == 'orphan' && !a.isPageLevel) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 10)),
                    icon: const Icon(Icons.my_location_rounded, size: 14),
                    label: Text(basicText('turath_reanchor_action', lang), style: const TextStyle(fontSize: 11)),
                    onPressed: onReanchor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
