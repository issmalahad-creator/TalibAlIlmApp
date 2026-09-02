import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/quran_learning.dart';
import '../../repositories/quran_learning_repository.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';
import '../ayah_notebook_screen.dart';

/// Phase 79 `79-ql` — "درس علمي منظّم" for one [LearningConcept]:
/// المفهوم → القاعدة → الشرح → أمثلة → أمثلة قرآنية → التطبيق. Every block
/// carries its source. "طبّق ما تعلمت" returns to the origin `(surah, ayah,
/// word)`; "أضف إلى دفتري" opens the Ayah Notebook pre-scoped to the concept.
class LearningLessonScreen extends StatefulWidget {
  final String conceptId;
  final int originSurah;
  final int originAyah;
  final int? originWordStart;
  final int? originWordEnd;

  const LearningLessonScreen({
    super.key,
    required this.conceptId,
    required this.originSurah,
    required this.originAyah,
    this.originWordStart,
    this.originWordEnd,
  });

  @override
  State<LearningLessonScreen> createState() => _LearningLessonScreenState();
}

class _LearningLessonScreenState extends State<LearningLessonScreen> {
  final _repo = QuranLearningRepository();
  LearningConcept? _concept;
  Map<String, SourceReference> _sources = {};
  int? _pathItemId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _repo.concept(widget.conceptId);
    if (c != null) {
      final srcs = await _repo.conceptSources(c);
      _sources = {for (final s in srcs) s.id: s};
      _pathItemId = await _repo.startLearning(
        conceptId: c.id,
        surah: widget.originSurah,
        ayah: widget.originAyah,
        wordStart: widget.originWordStart,
        wordEnd: widget.originWordEnd,
      );
      await _repo.logEvent(
        verb: StudyEventVerbs.openedLesson,
        targetKind: 'concept',
        targetId: c.id,
        surah: widget.originSurah,
        ayah: widget.originAyah,
        wordStart: widget.originWordStart,
        layer: c.domain,
      );
    }
    if (mounted) setState(() => _concept = c);
  }

  Future<void> _apply() async {
    if (_pathItemId != null) await _repo.setLearningState(_pathItemId!, 'applied');
    await _repo.logEvent(
      verb: StudyEventVerbs.returnedToAyah,
      targetKind: 'concept',
      targetId: widget.conceptId,
      surah: widget.originSurah,
      ayah: widget.originAyah,
      wordStart: widget.originWordStart,
      layer: _concept?.domain,
    );
    if (mounted) Navigator.pop(context, 'applied');
  }

  Future<void> _addNote() async {
    await _repo.logEvent(
      verb: StudyEventVerbs.linkedAyah,
      targetKind: 'concept',
      targetId: widget.conceptId,
      surah: widget.originSurah,
      ayah: widget.originAyah,
      layer: _concept?.domain,
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AyahNotebookScreen(
          surah: widget.originSurah,
          ayah: widget.originAyah,
          openAdd: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _concept;
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(c?.titleAr ?? basicText('ql_lesson_title', lang),
              textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 16)),
        ),
        body: c == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  if (c.status == 'stub' || c.status == 'missing')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(basicText('ql_lesson_stub', lang),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ),
                  if ((c.shortDefAr ?? '').isNotEmpty)
                    _Block(
                      label: basicText('ql_block_short_def', lang),
                      text: c.shortDefAr!,
                      source: _firstSource(c),
                    ),
                  for (final b in c.blocks)
                    _Block(
                      label: _blockLabel(b.kind, lang),
                      text: b.textAr ?? '',
                      source: b.sourceRefId == null ? null : _sources[b.sourceRefId],
                      quranRef: b.quranRef,
                    ),
                  const SizedBox(height: 8),
                  _SourcesFooter(sources: _sources.values.toList(), lang: lang),
                ],
              ),
        bottomNavigationBar: c == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: Text(basicText('ql_add_to_notebook', lang)),
                          onPressed: _addNote,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          label: Text(basicText('ql_apply_in_quran', lang)),
                          onPressed: _apply,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  SourceReference? _firstSource(LearningConcept c) =>
      c.sourceRefIds.isEmpty ? null : _sources[c.sourceRefIds.first];

  String _blockLabel(String kind, String lang) => switch (kind) {
        'definition' => basicText('ql_block_definition', lang),
        'explanation' => basicText('ql_block_explanation', lang),
        'example' => basicText('ql_block_example', lang),
        'quranic_example' => basicText('ql_block_quranic_example', lang),
        'application' => basicText('ql_block_application', lang),
        _ => basicText('ql_block_note', lang),
      };
}

class _Block extends StatelessWidget {
  final String label;
  final String text;
  final SourceReference? source;
  final KnowledgeAnchor? quranRef;
  const _Block({required this.label, required this.text, this.source, this.quranRef});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(text,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 14, height: 1.8, color: AppColors.textDark)),
          if (source != null) ...[
            const SizedBox(height: 8),
            Text('${source!.name}${source!.author != null ? ' — ${source!.author}' : ''}',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _SourcesFooter extends StatelessWidget {
  final List<SourceReference> sources;
  final String lang;
  const _SourcesFooter({required this.sources, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(basicText('ql_sources', lang),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          const SizedBox(height: 6),
          for (final s in sources)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${s.name}${s.edition != null ? ' (${s.edition})' : ''} — ${s.license}',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
