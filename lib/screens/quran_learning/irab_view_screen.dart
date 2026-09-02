import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../data/quran_surahs.dart';
import '../../l10n/basic_translations.dart';
import '../../models/quran_learning.dart';
import '../../repositories/quran_learning_repository.dart';
import '../../repositories/quran_reading_repository.dart';
import '../../services/language_preference_service.dart';
import '../../services/quran_audio/quran_audio_provider_registry.dart';
import '../../theme/app_theme.dart';
import '../ayah_notebook_screen.dart';
import 'learning_lesson_screen.dart';

/// Phase 79 `79-ql` — **P0: إعراب القرآن من داخل المصحف.** One ayah shown as
/// its words; each word carries its iʿrāb role. Tap a word → its full
/// analysis (النوع / الحالة / العلامة / الوظيفة / السبب / العلاقات + كيف
/// أثّرت العلامة في النطق + استماع). Tap a relation → the linked word
/// lights up. "تعلّم هذا" → a lesson in the notebook; "طبّق" comes back here.
/// Deterministic — every card cites its source. No AI.
class IrabViewScreen extends StatefulWidget {
  final int surah;
  final int ayah;

  /// The word the student tapped in the mushaf (auto-selected on open).
  final int? focusWordIndex;

  const IrabViewScreen({super.key, required this.surah, required this.ayah, this.focusWordIndex});

  @override
  State<IrabViewScreen> createState() => _IrabViewScreenState();
}

class _IrabViewScreenState extends State<IrabViewScreen> {
  final _repo = QuranLearningRepository();
  final _reading = QuranReadingRepository();
  final _audio = AudioPlayer();

  List<KnowledgeFact> _irab = [];
  Map<String, SourceReference> _sources = {};
  String _ayahText = '';
  int? _selected;
  Set<int> _highlighted = {};
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.focusWordIndex;
    _load();
    _audio.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final irab = await _repo.irabForAyah(widget.surah, widget.ayah);
    final t = await _reading.ayahAt(widget.surah, widget.ayah);
    final ids = {for (final f in irab) f.sourceRefId};
    final srcs = <String, SourceReference>{};
    for (final id in ids) {
      final s = await _repo.source(id);
      if (s != null) srcs[id] = s;
    }
    if (!mounted) return;
    setState(() {
      _irab = irab;
      _sources = srcs;
      _ayahText = t?.text ?? '';
    });
    await _repo.logEvent(
      verb: StudyEventVerbs.opened,
      targetKind: 'ayah',
      targetId: '${widget.surah}:${widget.ayah}',
      surah: widget.surah,
      ayah: widget.ayah,
      layer: 'nahw',
    );
  }

  KnowledgeFact? _factFor(int wordIndex) {
    for (final f in _irab) {
      if (f.anchor.covers(wordIndex)) return f;
    }
    return null;
  }

  String _surahName(int n) {
    for (final s in quranSurahs) {
      if (s.number == n) return s.name;
    }
    return '$n';
  }

  Future<void> _playAyah() async {
    final url = QuranAudioProviderRegistry.ayahAudioUrl(
      reciterId: 'Husary_Muallim_128kbps',
      surah: widget.surah,
      ayah: widget.ayah,
    );
    if (url == null) return;
    setState(() => _playing = true);
    try {
      await _audio.play(UrlSource(url));
    } catch (_) {
      if (mounted) setState(() => _playing = false);
    }
  }

  void _selectWord(int wordIndex) {
    setState(() {
      _selected = wordIndex;
      _highlighted = {};
    });
  }

  void _onRelationTap(int toWord) {
    setState(() => _highlighted = {_selected ?? -1, toWord});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            '${basicText('ql_irab_title', lang)} — ${_surahName(widget.surah)} ${widget.ayah}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            IconButton(
              tooltip: basicText('listen_ayah_action', lang),
              icon: Icon(_playing ? Icons.stop_circle_outlined : Icons.volume_up_rounded),
              onPressed: () {
                if (_playing) {
                  _audio.stop();
                  setState(() => _playing = false);
                } else {
                  _playAyah();
                }
              },
            ),
          ],
        ),
        body: _irab.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(basicText('ql_no_verified_data', lang),
                      textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                children: [
                  if (_ayahText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        _ayahText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'Amiri', fontSize: 22, height: 2.0),
                      ),
                    ),
                  const SizedBox(height: 14),
                  // Word row — chip + role label. Tap = select. RTL order.
                  Wrap(
                    alignment: WrapAlignment.center,
                    textDirection: TextDirection.rtl,
                    spacing: 6,
                    runSpacing: 10,
                    children: [
                      for (final f in _irab) _WordChip(
                        fact: f,
                        selected: _selected == f.anchor.wordStart,
                        highlighted: _highlighted.contains(f.anchor.wordStart),
                        onTap: () => _selectWord(f.anchor.wordStart!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selected != null && _factFor(_selected!) != null)
                    _IrabCard(
                      fact: _factFor(_selected!)!,
                      source: _sources[_factFor(_selected!)!.sourceRefId],
                      lang: lang,
                      onRelationTap: _onRelationTap,
                      onLearn: (conceptId) => _learn(conceptId, _selected!),
                      onNote: () => _note(_selected!),
                      onListen: _playAyah,
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _learn(String conceptId, int wordIndex) async {
    await _repo.logEvent(
      verb: StudyEventVerbs.openedLesson,
      targetKind: 'concept',
      targetId: conceptId,
      surah: widget.surah,
      ayah: widget.ayah,
      wordStart: wordIndex,
      layer: 'nahw',
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningLessonScreen(
          conceptId: conceptId,
          originSurah: widget.surah,
          originAyah: widget.ayah,
          originWordStart: wordIndex,
          originWordEnd: wordIndex,
        ),
      ),
    );
  }

  Future<void> _note(int wordIndex) async {
    await _repo.logEvent(
      verb: StudyEventVerbs.linkedAyah,
      targetKind: 'word',
      targetId: '${widget.surah}:${widget.ayah}:$wordIndex',
      surah: widget.surah,
      ayah: widget.ayah,
      wordStart: wordIndex,
      layer: 'nahw',
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AyahNotebookScreen(surah: widget.surah, ayah: widget.ayah, openAdd: true),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final KnowledgeFact fact;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;
  const _WordChip({
    required this.fact,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final roleAr = fact.payload['role_ar'] as String? ?? '';
    final surface = fact.payload['surface'] as String? ?? '';
    final bg = selected
        ? AppColors.primary
        : highlighted
            ? AppColors.primaryLight
            : AppColors.surface;
    final fg = selected ? Colors.white : AppColors.textDark;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: highlighted ? AppColors.primary : AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(surface,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: 'Amiri', fontSize: 18, height: 1.4, color: fg)),
            const SizedBox(height: 2),
            Text(roleAr,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 9.5,
                    color: selected ? Colors.white70 : AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _IrabCard extends StatelessWidget {
  final KnowledgeFact fact;
  final SourceReference? source;
  final String lang;
  final void Function(int toWord) onRelationTap;
  final void Function(String conceptId) onLearn;
  final VoidCallback onNote;
  final VoidCallback onListen;

  const _IrabCard({
    required this.fact,
    required this.source,
    required this.lang,
    required this.onRelationTap,
    required this.onLearn,
    required this.onNote,
    required this.onListen,
  });

  @override
  Widget build(BuildContext context) {
    final p = fact.payload;
    final roleAr = p['role_ar'] as String? ?? '';
    final signAr = p['sign_ar'] as String? ?? '';
    final irab = p['irab_text'] as String? ?? '';
    final relations = (p['relations'] as List? ?? const [])
        .cast<Map>()
        .map((m) => (to: (m['to_word'] as num).toInt(), ar: m['rel_ar'] as String? ?? ''))
        .toList();
    final conceptId = fact.conceptId;

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(k, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
              Expanded(
                child: Text(v,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(basicText('ql_role', lang), roleAr),
          if (signAr.isNotEmpty && signAr != '—') row(basicText('ql_sign', lang), signAr),
          const Divider(height: 18),
          Text(basicText('ql_why', lang),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(irab,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 13.5, height: 1.8, color: AppColors.textDark)),
          if (signAr.isNotEmpty && signAr != '—' && signAr != 'محلّيًّا') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over_rounded, size: 16, color: AppColors.primaryDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${basicText('ql_pron_effect', lang)} $signAr — ${basicText('ql_pron_hint', lang)}',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
                    ),
                  ),
                  TextButton(onPressed: onListen, child: Text(basicText('ql_listen', lang))),
                ],
              ),
            ),
          ],
          if (relations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(basicText('ql_relations', lang),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in relations)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(r.ar, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 11)),
                    onPressed: () => onRelationTap(r.to),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (conceptId != null)
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.school_rounded, size: 16),
                    label: Text(basicText('ql_learn_this', lang)),
                    onPressed: () => onLearn(conceptId),
                  ),
                ),
              if (conceptId != null) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: Text(basicText('ql_add_to_notebook', lang)),
                  onPressed: onNote,
                ),
              ),
            ],
          ),
          if (source != null) ...[
            const SizedBox(height: 10),
            Text(
              '${basicText('ql_source', lang)}: ${source!.name}'
              '${source!.edition != null && source!.edition != '—' ? ' (${source!.edition})' : ''}'
              ' · ${source!.license} · ${source!.badgeAr}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
