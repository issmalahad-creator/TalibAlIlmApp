import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../models/ayah_study_entry.dart';
import '../repositories/ayah_study_repository.dart';
import '../repositories/quran_reading_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';

/// "دفتر الآية" — the per-ayah study page (`79-sa-D-ayah`,
/// `docs/AYAH_STUDY_NOTEBOOK_DESIGN.md`). A study *journey* over time, not a
/// flat note list: the ayah text on top, an overview strip of counts per
/// entry type, then every entry the student has written about this ayah in
/// chronological order. Free writing first — the add sheet drops straight
/// into the body field. No AI anywhere.
class AyahNotebookScreen extends StatefulWidget {
  final int surah;
  final int ayah;

  /// Open the add sheet immediately (from a "➕ إضافة إلى دفتر الآية" shortcut).
  final bool openAdd;

  const AyahNotebookScreen({super.key, required this.surah, required this.ayah, this.openAdd = false});

  @override
  State<AyahNotebookScreen> createState() => _AyahNotebookScreenState();
}

const _typeIcons = <String, IconData>{
  AyahEntryTypes.personal: Icons.edit_note_rounded,
  AyahEntryTypes.tafsir: Icons.menu_book_rounded,
  AyahEntryTypes.meaning: Icons.subject_rounded,
  AyahEntryTypes.benefit: Icons.lightbulb_outline_rounded,
  AyahEntryTypes.linguistic: Icons.spellcheck_rounded,
  AyahEntryTypes.fiqh: Icons.balance_rounded,
  AyahEntryTypes.aqeedah: Icons.brightness_3_rounded,
  AyahEntryTypes.tarbawi: Icons.spa_outlined,
  AyahEntryTypes.hadith: Icons.format_quote_rounded,
  AyahEntryTypes.comparison: Icons.compare_arrows_rounded,
  AyahEntryTypes.question: Icons.help_outline_rounded,
  AyahEntryTypes.link: Icons.link_rounded,
  AyahEntryTypes.lessonSummary: Icons.school_outlined,
  AyahEntryTypes.review: Icons.psychology_outlined,
};

String _typeLabel(String t, String lang) => basicText('ayah_type_$t', lang);
String _stanceLabel(String s, String lang) => basicText('ayah_stance_$s', lang);

class _AyahNotebookScreenState extends State<AyahNotebookScreen> {
  final _repo = AyahStudyRepository();
  final _quran = QuranReadingRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  QuranAyahText? _ayahText;
  List<AyahStudyEntry> _entries = [];
  Map<String, int> _typeCounts = {};
  List<String> _topics = [];
  String? _filterType;
  bool _newestFirst = false;
  bool _loading = true;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (widget.openAdd && mounted) _openEntrySheet();
    });
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _quran.ayahAt(widget.surah, widget.ayah),
      _repo.entriesForAyah(widget.surah, widget.ayah, filterType: _filterType, newestFirst: _newestFirst),
      _repo.typeCountsForAyah(widget.surah, widget.ayah),
      _repo.distinctTopics(),
    ]);
    if (!mounted) return;
    setState(() {
      _ayahText = results[0] as QuranAyahText?;
      _entries = results[1] as List<AyahStudyEntry>;
      _typeCounts = results[2] as Map<String, int>;
      _topics = results[3] as List<String>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(basicText('ayah_notebook_title', lang)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${_surahNames[widget.surah] ?? widget.surah} — ${basicText('ayah_label', lang)} ${widget.ayah}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEntrySheet(),
          icon: const Icon(Icons.add),
          label: Text(basicText('ayah_notebook_add_action', lang)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _ayahHeader(lang),
                  const SizedBox(height: 14),
                  if (_typeCounts.isNotEmpty) _overviewStrip(lang),
                  if (_typeCounts.isNotEmpty) const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _newestFirst = !_newestFirst);
                          _load();
                        },
                        icon: Icon(_newestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 16),
                        label: Text(basicText(_newestFirst ? 'ayah_notebook_newest_first' : 'ayah_notebook_oldest_first', lang),
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(basicText('ayah_notebook_empty', lang),
                            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  else
                    for (final e in _entries) _entryCard(e, lang),
                ],
              ),
      ),
    );
  }

  Widget _ayahHeader(String lang) {
    return Card(
      color: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _ayahText?.text ?? '…',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 20, height: 2.0, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              '${_surahNames[widget.surah] ?? widget.surah} : ${widget.ayah}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewStrip(String lang) {
    final chips = <Widget>[
      ChoiceChip(
        label: Text(basicText('ayah_notebook_all_filter', lang), style: const TextStyle(fontSize: 11)),
        selected: _filterType == null,
        onSelected: (_) {
          setState(() => _filterType = null);
          _load();
        },
      ),
      for (final t in AyahEntryTypes.all)
        if ((_typeCounts[t] ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              avatar: Icon(_typeIcons[t], size: 14),
              label: Text('${_typeCounts[t]} ${_typeLabel(t, lang)}', style: const TextStyle(fontSize: 11)),
              selected: _filterType == t,
              onSelected: (_) {
                setState(() => _filterType = _filterType == t ? null : t);
                _load();
              },
            ),
          ),
    ];
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _entryCard(AyahStudyEntry e, String lang) {
    final accent = AppColors.studyAnnotation(e.colorKey ?? _defaultColorFor(e.entryType)).$3;
    final expanded = _expanded.contains(e.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Icon(_typeIcons[e.entryType], size: 15, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Text(_typeLabel(e.entryType, lang), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                if (e.stance != null) ...[
                  const SizedBox(width: 6),
                  Text('· ${_stanceLabel(e.stance!, lang)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
                if ((e.topic ?? '').isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('· ${e.topic}', style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                ],
                const Spacer(),
                _entryMenu(e, lang),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => expanded ? _expanded.remove(e.id) : _expanded.add(e.id)),
              child: Text(
                e.body,
                textDirection: TextDirection.rtl,
                maxLines: expanded ? null : 6,
                overflow: expanded ? null : TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, height: 1.8),
              ),
            ),
            if (e.hasSource) ...[
              const SizedBox(height: 6),
              Text(e.sourceLine, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 10.5, color: AppColors.primary)),
            ],
            if (e.entryType == AyahEntryTypes.question || e.entryType == AyahEntryTypes.review) ...[
              const SizedBox(height: 8),
              _statusChip(e, lang),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(AyahStudyEntry e, String lang) {
    if (e.entryType == AyahEntryTypes.review) {
      return Chip(
        visualDensity: VisualDensity.compact,
        label: Text(basicText('ayah_entry_for_review', lang), style: const TextStyle(fontSize: 10)),
        backgroundColor: AppColors.primaryLight,
      );
    }
    final resolved = e.status == AyahEntryStatus.resolved;
    return ActionChip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(resolved ? Icons.check_circle_outline : Icons.hourglass_empty_rounded, size: 14),
      label: Text(
        resolved ? basicText('ayah_entry_question_resolved', lang) : basicText('ayah_entry_question_open', lang),
        style: const TextStyle(fontSize: 10),
      ),
      onPressed: () async {
        await _repo.setStatus(e.id, resolved ? AyahEntryStatus.open : AyahEntryStatus.resolved);
        _load();
      },
    );
  }

  Widget _entryMenu(AyahStudyEntry e, String lang) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text(basicText('edit_action', lang))),
        PopupMenuItem(value: 'delete', child: Text(basicText('delete_action', lang))),
      ],
      onSelected: (v) async {
        if (v == 'edit') {
          _openEntrySheet(existing: e);
        } else if (v == 'delete') {
          await _repo.deleteEntry(e.id);
          _load();
        }
      },
    );
  }

  static String _defaultColorFor(String type) {
    switch (type) {
      case AyahEntryTypes.review:
        return 'memorize';
      case AyahEntryTypes.question:
        return 'question';
      case AyahEntryTypes.fiqh:
      case AyahEntryTypes.aqeedah:
        return 'important';
      case AyahEntryTypes.tafsir:
      case AyahEntryTypes.meaning:
      case AyahEntryTypes.comparison:
        return 'explain';
      default:
        return 'benefit';
    }
  }

  Future<void> _openEntrySheet({AyahStudyEntry? existing}) async {
    final lang = LanguagePreferenceService.currentLanguage;
    final draft = existing != null ? AyahStudyEntryInput.from(existing) : const AyahStudyEntryInput(body: '');

    final bodyC = TextEditingController(text: draft.body);
    final nameC = TextEditingController(text: draft.sourceName ?? '');
    final authorC = TextEditingController(text: draft.sourceAuthor ?? '');
    final refC = TextEditingController(text: draft.sourceRef ?? '');
    final dateC = TextEditingController(text: draft.sourceDate ?? '');
    final topicC = TextEditingController(text: draft.topic ?? '');
    var type = draft.entryType;
    String? stance = draft.stance;
    String? sourceType = draft.sourceType;
    var showAllTypes = !AyahEntryTypes.primary.contains(type);
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
        child: StatefulBuilder(
          builder: (sheetContext, setS) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // free writing first
                TextField(
                  controller: bodyC,
                  autofocus: true,
                  minLines: 4,
                  maxLines: null,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: basicText('ayah_entry_body_hint', lang),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => setS(() {}),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in (showAllTypes ? AyahEntryTypes.all : AyahEntryTypes.primary))
                      ChoiceChip(
                        avatar: Icon(_typeIcons[t], size: 14),
                        label: Text(_typeLabel(t, lang), style: const TextStyle(fontSize: 11)),
                        selected: type == t,
                        onSelected: (_) => setS(() => type = t),
                      ),
                    if (!showAllTypes)
                      ActionChip(
                        label: Text(basicText('ayah_entry_more_types', lang), style: const TextStyle(fontSize: 11)),
                        onPressed: () => setS(() => showAllTypes = true),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // optional epistemic stance
                Wrap(
                  spacing: 6,
                  children: [
                    for (final s in AyahEntryStances.all)
                      ChoiceChip(
                        label: Text(_stanceLabel(s, lang), style: const TextStyle(fontSize: 10.5)),
                        selected: stance == s,
                        onSelected: (_) => setS(() => stance = stance == s ? null : s),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: topicC,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: basicText('ayah_entry_topic_hint', lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_topics.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final tag in _topics.take(12))
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(tag, style: const TextStyle(fontSize: 10)),
                          onPressed: () => setS(() => topicC.text = tag),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(sheetContext).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(basicText('ayah_entry_source_section', lang), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    children: [
                      _sheetField(nameC, basicText('ayah_entry_source_name_hint', lang)),
                      _sheetField(authorC, basicText('ayah_entry_source_author_hint', lang)),
                      _sheetField(refC, basicText('ayah_entry_source_ref_hint', lang)),
                      _sheetField(dateC, basicText('ayah_entry_source_date_hint', lang)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final st in AyahSourceTypes.all)
                            ChoiceChip(
                              label: Text(basicText('ayah_source_$st', lang), style: const TextStyle(fontSize: 10)),
                              selected: sourceType == st,
                              onSelected: (_) => setS(() => sourceType = sourceType == st ? null : st),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: saving ? null : () => Navigator.pop(sheetContext),
                        child: Text(basicText('cancel_action', lang)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (saving || bodyC.text.trim().isEmpty)
                            ? null
                            : () async {
                                setS(() => saving = true);
                                final input = AyahStudyEntryInput(
                                  body: bodyC.text,
                                  entryType: type,
                                  topic: topicC.text,
                                  stance: stance,
                                  sourceType: sourceType,
                                  sourceName: nameC.text,
                                  sourceAuthor: authorC.text,
                                  sourceRef: refC.text,
                                  sourceDate: dateC.text,
                                  wordStart: draft.wordStart,
                                  wordEnd: draft.wordEnd,
                                );
                                if (existing != null) {
                                  await _repo.updateEntry(existing.id, input);
                                } else {
                                  await _repo.addEntry(widget.surah, widget.ayah, input);
                                }
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                                await _load();
                                if (mounted && existing == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(basicText('ayah_entry_saved_toast', lang)), duration: const Duration(seconds: 2)),
                                  );
                                }
                              },
                        child: Text(basicText('save_action', lang)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController c, String hint) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: TextField(
          controller: c,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(isDense: true, hintText: hint, border: const OutlineInputBorder()),
        ),
      );
}
