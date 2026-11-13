import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/qaida.dart';
import '../../repositories/arabic_curriculum_repository.dart';
import '../../services/language_preference_service.dart';
import '../../services/qaida_content.dart';
import '../../theme/app_theme.dart';

String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);

/// One Qaida lesson: the rule in two lines, then a grid of fully vocalized
/// cells. Tap a cell to hear it; «استمع للدرس» plays every recorded cell in
/// order and highlights it. A sound that is not recorded yet is never
/// faked with a synthetic voice — the lesson says so plainly.
class QaidaLessonScreen extends StatefulWidget {
  final List<QaidaLesson> lessons;
  final int index;
  const QaidaLessonScreen({super.key, required this.lessons, required this.index});

  @override
  State<QaidaLessonScreen> createState() => _QaidaLessonScreenState();
}

class _QaidaLessonScreenState extends State<QaidaLessonScreen> {
  final _repo = ArabicCurriculumRepository();
  AudioPlayer? _player;
  StreamSubscription<void>? _completeSub;
  Set<String> _recorded = const {};
  bool _done = false;
  int? _current; // index of the highlighted cell
  bool _playingAll = false;

  QaidaLesson get _lesson => widget.lessons[widget.index];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final recorded = await QaidaContent.instance.recordedAudioIds();
    final learned = await _repo.learnedKeys();
    if (!mounted) return;
    setState(() {
      _recorded = recorded;
      _done = learned.contains(qaidaProgressKey(_lesson.id));
    });
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  AudioPlayer get _audio {
    if (_player == null) {
      _player = AudioPlayer();
      _completeSub = _player!.onPlayerComplete.listen((_) => _onComplete());
    }
    return _player!;
  }

  bool _isRecorded(int i) => _recorded.contains(_lesson.items[i].audioId);

  Future<void> _play(int i) async {
    setState(() => _current = i);
    if (!_isRecorded(i)) return;
    try {
      await _audio.stop();
      await _audio.play(AssetSource(_lesson.items[i].assetPath.substring('assets/'.length)));
    } catch (_) {
      // a missing/unsupported file: stay quiet, the cell stays highlighted
    }
  }

  void _onComplete() {
    if (!mounted || !_playingAll) return;
    final next = _nextRecorded((_current ?? -1) + 1);
    if (next == null) {
      setState(() {
        _playingAll = false;
        _current = null;
      });
      return;
    }
    // a short breath between sounds, like a teacher reading the row
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && _playingAll) _play(next);
    });
  }

  int? _nextRecorded(int from) {
    for (var i = from; i < _lesson.items.length; i++) {
      if (_isRecorded(i)) return i;
    }
    return null;
  }

  Future<void> _togglePlayAll() async {
    if (_playingAll) {
      await _player?.stop();
      setState(() {
        _playingAll = false;
        _current = null;
      });
      return;
    }
    final first = _nextRecorded(0);
    if (first == null) return;
    setState(() => _playingAll = true);
    await _play(first);
  }

  Future<void> _markDone() async {
    await _repo.markLearned(qaidaProgressKey(_lesson.id));
    if (!mounted) return;
    setState(() => _done = true);
  }

  void _openNext() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => QaidaLessonScreen(lessons: widget.lessons, index: widget.index + 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    final sounds = lesson.distinctSounds;
    final recordedCount = sounds.where((s) => _recorded.contains(s.audioId)).length;
    final hasNext = widget.index + 1 < widget.lessons.length;
    final width = MediaQuery.sizeOf(context).width;
    final cols = width < 340 ? (lesson.columns - 1).clamp(1, 9) : lesson.columns;
    final fontSize = lesson.id == 'q02' ? 24.0 : (cols >= 5 ? 30.0 : 34.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_t('qaida_lesson_n').replaceAll('{n}', '${lesson.number}')} · ${_t(lesson.titleKey)}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _NoteCard(text: _t(lesson.noteKey)),
          const SizedBox(height: 10),
          if (recordedCount < sounds.length)
            _AudioStatus(recorded: recordedCount, total: sounds.length)
          else
            Text(_t('qaida_tap_hint'), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lesson.items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: lesson.items.first.ref != null ? 100 : 78,
              ),
              itemBuilder: (_, i) => _Cell(
                item: lesson.items[i],
                fontSize: fontSize,
                active: _current == i,
                recorded: _isRecorded(i),
                onTap: () {
                  if (_playingAll) setState(() => _playingAll = false);
                  _play(i);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              if (recordedCount > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                    onPressed: _togglePlayAll,
                    icon: Icon(_playingAll ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(_t(_playingAll ? 'qaida_stop' : 'qaida_play_all'), overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _done
                    ? (hasNext
                        ? FilledButton.icon(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                            onPressed: _openNext,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(_t('qaida_next'), overflow: TextOverflow.ellipsis),
                          )
                        : FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                            onPressed: null,
                            icon: const Icon(Icons.check_circle_rounded),
                            label: Text(_t('qaida_all_done'), overflow: TextOverflow.ellipsis),
                          ))
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                        onPressed: _markDone,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(_t('qaida_mark_done'), overflow: TextOverflow.ellipsis),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String text;
  const _NoteCard({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 20, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.7, color: AppColors.textDark)),
            ),
          ],
        ),
      );
}

class _AudioStatus extends StatelessWidget {
  final int recorded;
  final int total;
  const _AudioStatus({required this.recorded, required this.total});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(recorded == 0 ? Icons.volume_off_rounded : Icons.volume_down_rounded, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              recorded == 0
                  ? _t('qaida_no_audio')
                  : _t('qaida_audio_partial').replaceAll('{n}', '$recorded').replaceAll('{total}', '$total'),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
            ),
          ),
        ],
      );
}

class _Cell extends StatelessWidget {
  final QaidaItem item;
  final double fontSize;
  final bool active;
  final bool recorded;
  final VoidCallback onTap;
  const _Cell({required this.item, required this.fontSize, required this.active, required this.recorded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFFFF3D6) : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? const Color(0xFFD9A441) : AppColors.divider, width: active ? 2 : 1),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        // AmiriQuran keeps a tall ascent for stacked marks,
                        // so the letter body sits low in its line box; lift
                        // it so the letter looks centred in the cell.
                        child: Transform.translate(
                          offset: Offset(0, -fontSize * 0.14),
                          child: Text(
                            item.text,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: fontSize,
                              height: 1.5,
                              leadingDistribution: TextLeadingDistribution.even,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (item.ref != null) ...[
                      const SizedBox(height: 6),
                      Text(item.ref!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
              if (recorded)
                const PositionedDirectional(
                  top: 4,
                  start: 6,
                  child: Icon(Icons.volume_up_rounded, size: 13, color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
