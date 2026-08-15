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
/// reflections ("دفتر الفوائد"). On reopening a series with prior
/// progress, resumes the exact video + timestamp the user left off at;
/// otherwise cues the full playlist from the start so YouTube's own
/// native controls handle in-order episode navigation.
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
  late final YoutubePlayerController _controller;
  Timer? _saveTimer;
  StreamSubscription? _valueSub;
  StreamSubscription? _stateSub;
  Duration _lastPosition = Duration.zero;
  String? _currentVideoId;
  String _currentVideoTitle = '';
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
      if (meta.videoId.isNotEmpty && meta.videoId != _currentVideoId) {
        setState(() {
          _currentVideoId = meta.videoId;
          _currentVideoTitle = meta.title;
        });
        _loadReflections();
      }
    });
    _stateSub = _controller.videoStateStream.listen((state) => _lastPosition = state.position);
    _cueContent();
    _saveTimer = Timer.periodic(const Duration(seconds: 15), (_) => _persistProgress());
    _loadReflections();
  }

  Future<void> _cueContent() async {
    final resume = await _repo.resumePointFor(widget.seriesId);
    if (resume != null) {
      _resumedFromSaved = true;
      await _controller.cueVideoById(videoId: resume.videoId, startSeconds: resume.positionSeconds.toDouble());
    } else if (widget.playlistId != null) {
      await _controller.cuePlaylist(list: [widget.playlistId!]);
    } else if (widget.videoId != null) {
      await _controller.cueVideoById(videoId: widget.videoId!);
    }
  }

  Future<void> _restartFromBeginning() async {
    if (widget.playlistId != null) {
      await _controller.cuePlaylist(list: [widget.playlistId!]);
    } else if (widget.videoId != null) {
      await _controller.cueVideoById(videoId: widget.videoId!);
    }
  }

  Future<void> _persistProgress() async {
    if (_currentVideoId == null) return;
    await _repo.saveResumePoint(widget.seriesId, _currentVideoId!, _lastPosition.inSeconds);
  }

  Future<void> _loadReflections() async {
    setState(() => _loadingReflections = true);
    final reflections = await _repo.reflectionsFor(widget.seriesId);
    if (!mounted) return;
    setState(() {
      _reflections = reflections;
      _loadingReflections = false;
    });
  }

  Future<void> _saveReflection() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    await _repo.addReflection(widget.seriesId, _currentVideoId, text);
    _noteCtrl.clear();
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

  Future<void> _openInYoutube() async {
    final uri = Uri.parse(widget.youtubeUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _persistProgress();
    _saveTimer?.cancel();
    _valueSub?.cancel();
    _stateSub?.cancel();
    _controller.close();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titleAr, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          YoutubePlayer(controller: _controller),
          const SizedBox(height: 10),
          if (widget.authorAr != null)
            Text(widget.authorAr!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          if (_currentVideoTitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_currentVideoTitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
          if (_resumedFromSaved) ...[
            const SizedBox(height: 4),
            const Text('استؤنف من حيث توقفت آخر مرة', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openInYoutube,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('افتح في يوتيوب'),
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
          const SizedBox(height: 20),
          const Text('دفتر الفوائد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('اكتب ملخصًا أو فائدة استفدتها من هذا المقطع — لنفسك، لا أحد غيرك سيراها', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
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
            const Text('ملاحظاتك السابقة', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
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
                      const SizedBox(height: 6),
                      Text(r.createdDate, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
