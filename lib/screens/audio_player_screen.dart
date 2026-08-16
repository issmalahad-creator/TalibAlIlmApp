import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../repositories/audio_library_repository.dart';
import '../repositories/milestone_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';

const _reflectionPrompts = [
  'ما الفكرة التي لفتت انتباهك في هذا المقطع؟',
  'كيف يمكن أن تطبّق هذا في حياتك اليوم؟',
  'ما سؤال بقي عندك تريد البحث عنه لاحقًا؟',
  'ما عبارة أو موقف أثّر فيك؟',
];

/// Streams audio/video through YouTube's own official embedded player
/// (youtube_player_iframe) — this screen never downloads or caches the
/// media itself, only the user's own resume position and written
/// reflections ("دفتر الفوائد"), scoped per episode not per whole series.
///
/// "قسم ← حلقات" structure (Ismail's request 2026-08-16, after the flat
/// single-player screen proved confusing and a broken episode left him
/// stuck with no way to pick another one): when the series is a playlist,
/// the actual ordered episode-video-ID list is read directly from
/// YouTube's own embedded player via `controller.playlist` after cueing —
/// no YouTube Data API key needed, no scraping. Each episode gets its own
/// "دفتر الفوائد" (filtered by video_id, already supported by the schema),
/// and a broken episode (some videos block third-party embedding — outside
/// this app's control, same boundary as always: never worked around by
/// extracting the stream) is just one tap away from a working one instead
/// of a dead end.
class AudioPlayerScreen extends StatefulWidget {
  final String seriesId;
  final String titleAr;
  final String? authorAr;
  final String? playlistId;
  final String? videoId;
  final String youtubeUrl;

  const AudioPlayerScreen({
    super.key,
    required this.seriesId,
    required this.titleAr,
    this.authorAr,
    this.playlistId,
    this.videoId,
    required this.youtubeUrl,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _repo = AudioLibraryRepository();
  final _milestoneRepo = MilestoneRepository();
  final _noteCtrl = TextEditingController();
  final _resumeCtrl = TextEditingController();
  late final YoutubePlayerController _controller;
  Timer? _saveTimer;
  StreamSubscription? _valueSub;
  StreamSubscription? _stateSub;
  Duration _lastPosition = Duration.zero;
  String? _currentVideoId;
  String _currentVideoTitle = '';
  List<String> _episodeIds = [];
  bool _loadingEpisodes = false;
  List<AudioReflection> _reflections = [];
  bool _loadingReflections = true;
  bool _resumedFromSaved = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
    _valueSub = _controller.stream.listen((value) {
      final meta = value.metaData;
      if (meta.videoId.isEmpty) return;
      if (meta.videoId != _currentVideoId) {
        _setCurrentVideo(meta.videoId);
      } else if (meta.title.isNotEmpty && meta.title != _currentVideoTitle) {
        setState(() => _currentVideoTitle = meta.title);
      }
    });
    _stateSub = _controller.videoStateStream.listen((state) => _lastPosition = state.position);
    _cueContent();
    _saveTimer = Timer.periodic(const Duration(seconds: 15), (_) => _persistProgress());
  }

  Future<void> _cueContent() async {
    if (widget.playlistId != null) {
      setState(() => _loadingEpisodes = true);
      await _controller.cuePlaylist(list: [widget.playlistId!]);
      await _loadEpisodeList();
    }
    final resume = await _repo.resumePointFor(widget.seriesId);
    if (resume != null) {
      _resumedFromSaved = true;
      await _setCurrentVideo(resume.videoId);
      await _controller.cueVideoById(videoId: resume.videoId, startSeconds: resume.positionSeconds.toDouble());
    } else if (widget.playlistId == null && widget.videoId != null) {
      await _setCurrentVideo(widget.videoId!);
      await _controller.cueVideoById(videoId: widget.videoId!);
    }
  }

  /// Tracks the video we *intended* to cue, independent of the player's
  /// own metadata stream — some videos fail to embed entirely (Error 152,
  /// embedding disabled by the uploader), and when that happens the
  /// stream never fires with a videoId either. Without this, "افتح هذه
  /// الحلقة في يوتيوب" silently did nothing on exactly the broken videos
  /// that need it most (Ismail's report 2026-08-16) — `_currentVideoId`
  /// only ever got set reactively from a stream event that never came.
  Future<void> _setCurrentVideo(String videoId) async {
    if (videoId == _currentVideoId) return;
    setState(() {
      _currentVideoId = videoId;
      _currentVideoTitle = '';
    });
    await _loadReflections();
  }

  /// YouTube's own embedded player exposes the cued playlist's video IDs
  /// via `getPlaylist()`, but it can take a moment after `cuePlaylist` to
  /// populate — short retry loop rather than a fixed guessed delay.
  Future<void> _loadEpisodeList() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final list = await _controller.playlist;
      if (list.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _episodeIds = list;
          _loadingEpisodes = false;
        });
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!mounted) return;
    setState(() => _loadingEpisodes = false);
  }

  Future<void> _playEpisode(String videoId) async {
    await _setCurrentVideo(videoId);
    await _controller.cueVideoById(videoId: videoId);
  }

  void _playRelativeEpisode(int delta) {
    if (_episodeIds.isEmpty || _currentVideoId == null) return;
    final idx = _episodeIds.indexOf(_currentVideoId!);
    if (idx == -1) return;
    final newIdx = idx + delta;
    if (newIdx < 0 || newIdx >= _episodeIds.length) return;
    _playEpisode(_episodeIds[newIdx]);
  }

  Future<void> _restartFromBeginning() async {
    if (_episodeIds.isNotEmpty) {
      await _playEpisode(_episodeIds.first);
    } else if (widget.videoId != null) {
      await _playEpisode(widget.videoId!);
    }
  }

  Future<void> _persistProgress() async {
    if (_currentVideoId == null) return;
    await _repo.saveResumePoint(widget.seriesId, _currentVideoId!, _lastPosition.inSeconds);
  }

  Future<void> _loadReflections() async {
    setState(() => _loadingReflections = true);
    final reflections = await _repo.reflectionsFor(widget.seriesId, videoId: _currentVideoId);
    if (!mounted) return;
    setState(() {
      _reflections = reflections;
      _loadingReflections = false;
    });
  }

  Future<void> _saveReflection() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    final resumeNote = _resumeCtrl.text.trim();
    await _repo.addReflection(widget.seriesId, _currentVideoId, text, resumeNote: resumeNote.isEmpty ? null : resumeNote);
    _noteCtrl.clear();
    _resumeCtrl.clear();
    await _loadReflections();
    if (!mounted) return;
    final total = await _repo.totalReflectionCount();
    final newlyEarned = await _milestoneRepo.checkAudioReflectionMilestones(total);
    if (!mounted) return;
    if (newlyEarned.isNotEmpty) {
      await showCelebration(context, newlyEarned.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ ملاحظتك')));
    }
  }

  /// "تعديل الملاحظة" / "مسح الملاحظة" (Ismail's request 2026-08-16) —
  /// دفتر الفوائد previously only supported adding, never fixing a typo or
  /// removing an entry.
  Future<void> _editReflection(AudioReflection r) async {
    final textCtrl = TextEditingController(text: r.text);
    final resumeCtrl = TextEditingController(text: r.resumeNote ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الملاحظة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                controller: resumeCtrl,
                decoration: const InputDecoration(labelText: 'أين توقفت؟ (رابط أو الوقت)', border: OutlineInputBorder(), isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (saved != true) return;
    final text = textCtrl.text.trim();
    if (text.isEmpty) return;
    final resumeNote = resumeCtrl.text.trim();
    await _repo.updateReflection(r.id, text, resumeNote: resumeNote.isEmpty ? null : resumeNote);
    await _loadReflections();
  }

  Future<void> _deleteReflection(AudioReflection r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح الملاحظة؟'),
        content: const Text('لا يمكن التراجع عن هذا.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('مسح')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.deleteReflection(r.id);
    await _loadReflections();
  }

  Future<void> _openPlaylistInYoutube() async {
    await launchUrl(Uri.parse(widget.youtubeUrl), mode: LaunchMode.externalApplication);
  }

  Future<void> _openEpisodeInYoutube() async {
    if (_currentVideoId == null) return;
    await launchUrl(Uri.parse('https://www.youtube.com/watch?v=$_currentVideoId'), mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _persistProgress();
    _saveTimer?.cancel();
    _valueSub?.cancel();
    _stateSub?.cancel();
    _controller.close();
    _noteCtrl.dispose();
    _resumeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final episodeNumber = _currentVideoId == null ? -1 : _episodeIds.indexOf(_currentVideoId!);
    return Scaffold(
      appBar: AppBar(title: Text(widget.titleAr, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          YoutubePlayer(controller: _controller),
          const SizedBox(height: 10),
          if (widget.authorAr != null)
            Text(widget.authorAr!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          if (episodeNumber >= 0) ...[
            const SizedBox(height: 4),
            Text('الحلقة ${episodeNumber + 1} من ${_episodeIds.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ],
          if (_currentVideoTitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_currentVideoTitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
          if (_resumedFromSaved) ...[
            const SizedBox(height: 4),
            const Text('استؤنف من حيث توقفت آخر مرة', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 10),
          if (_episodeIds.length > 1)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: episodeNumber > 0 ? () => _playRelativeEpisode(-1) : null,
                    icon: const Icon(Icons.skip_previous_outlined, size: 18),
                    label: const Text('السابقة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: episodeNumber >= 0 && episodeNumber < _episodeIds.length - 1 ? () => _playRelativeEpisode(1) : null,
                    icon: const Icon(Icons.skip_next_outlined, size: 18),
                    label: const Text('التالية'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openEpisodeInYoutube,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('افتح هذه الحلقة في يوتيوب'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restartFromBeginning,
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('من البداية'),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: _openPlaylistInYoutube, child: const Text('افتح القائمة كاملة في يوتيوب', style: TextStyle(fontSize: 11.5))),
          ),
          if (_loadingEpisodes) ...[
            const SizedBox(height: 10),
            const Center(child: CircularProgressIndicator()),
          ] else if (_episodeIds.length > 1) ...[
            const SizedBox(height: 12),
            const Text('الحلقات', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...List.generate(_episodeIds.length, (i) {
              final id = _episodeIds[i];
              final isCurrent = id == _currentVideoId;
              return InkWell(
                onTap: () => _playEpisode(id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.primaryLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isCurrent ? AppColors.primary : AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(isCurrent ? Icons.play_circle_fill : Icons.play_circle_outline, size: 20, color: isCurrent ? AppColors.primaryDark : AppColors.textMuted),
                      const SizedBox(width: 10),
                      Text('الحلقة ${i + 1}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: isCurrent ? AppColors.primaryDark : AppColors.textDark)),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 20),
          const Text('دفتر الفوائد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('اكتب ملخصًا أو فائدة استفدتها من هذه الحلقة — لنفسك، لا أحد غيرك سيراها', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _reflectionPrompts
                .map((p) => ActionChip(
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        _noteCtrl.text = _noteCtrl.text.isEmpty ? '$p\n' : '${_noteCtrl.text}\n$p\n';
                        _noteCtrl.selection = TextSelection.collapsed(offset: _noteCtrl.text.length);
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'اكتب ما استفدته هنا...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _resumeCtrl,
            decoration: const InputDecoration(
              labelText: 'أين توقفت؟ (رابط أو الوقت) — احتياطًا إن تعطّل الفيديو',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _saveReflection,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('حفظ الملاحظة'),
            ),
          ),
          const SizedBox(height: 20),
          if (_loadingReflections)
            const Center(child: CircularProgressIndicator())
          else if (_reflections.isNotEmpty) ...[
            const Text('ملاحظاتك على هذه الحلقة', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ..._reflections.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.text, style: const TextStyle(fontSize: 13, height: 1.6)),
                      if (r.resumeNote != null && r.resumeNote!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.bookmark_outline, size: 13, color: AppColors.primaryDark),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('توقفت عند: ${r.resumeNote}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(r.createdDate, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                          const Spacer(),
                          InkWell(
                            onTap: () => _editReflection(r),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.edit_outlined, size: 15, color: AppColors.textMuted),
                            ),
                          ),
                          InkWell(
                            onTap: () => _deleteReflection(r),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.delete_outline, size: 15, color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
