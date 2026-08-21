import 'package:flutter/material.dart';

import '../data/audio_series_seed.dart';
import '../l10n/basic_translations.dart';
import '../repositories/audio_library_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'audio_player_screen.dart';
import '../widgets/loading_view.dart';

/// "كتب صوتية من اليوتيوب" (Phase 13, Ismail's request 2026-08-16) —
/// audio-lecture series streamed via YouTube's own official embedded
/// player. Two sections: `audioSeries` (app-curated, verified series added
/// by Claude on request) and the user's own self-added series (same
/// "مكتبتي" pattern as personal PDFs — no curation/review, just a place
/// to paste a link). Neither downloads or rehosts any media.
class AudioLibraryScreen extends StatefulWidget {
  const AudioLibraryScreen({super.key});

  @override
  State<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends State<AudioLibraryScreen> {
  final _repo = AudioLibraryRepository();
  List<CustomAudioSeries> _custom = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final custom = await _repo.listCustomSeries();
    if (!mounted) return;
    setState(() {
      _custom = custom;
      _loading = false;
    });
  }

  Future<void> _addCustomSeries() async {
    final lang = LanguagePreferenceService.currentLanguage;
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('add_audio_series_title', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: basicText('series_or_lesson_name_label', lang)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(labelText: basicText('youtube_link_label', lang)),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                basicText('youtube_no_download_disclaimer', lang),
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(basicText('cancel', lang))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(basicText('add', lang))),
        ],
      ),
    );
    if (saved != true) return;
    final parsed = parseYoutubeUrl(urlCtrl.text);
    if (!parsed.isValid || titleCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(basicText('series_validation_error', lang))),
      );
      return;
    }
    await _repo.addCustomSeries(titleCtrl.text.trim(), parsed);
    _load();
  }

  Future<void> _deleteCustomSeries(CustomAudioSeries s) async {
    final lang = LanguagePreferenceService.currentLanguage;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('delete_series_title', lang)),
        content: Text(
            '${basicText('delete_series_confirm_prefix', lang)} "${s.titleAr}"${basicText('delete_series_confirm_suffix', lang)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(basicText('cancel', lang))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(basicText('delete', lang))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.deleteCustomSeries(s.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(
        title: Text(basicText('audio_library_title', lang)),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: basicText('add_series_tooltip', lang), onPressed: _addCustomSeries),
        ],
      ),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_generic', lang))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  basicText('audio_stream_disclaimer', lang),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                ...audioSeries.map((s) => _SeriesCard(
                      titleAr: s.titleAr,
                      subtitleAr: '${s.authorAr} · ${s.categoryAr}',
                      descriptionAr: s.descriptionAr,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AudioPlayerScreen(
                            seriesId: s.id,
                            titleAr: s.titleAr,
                            authorAr: s.authorAr,
                            playlistId: s.playlistId,
                            videoId: s.firstVideoId,
                            youtubeUrl: s.youtubePlaylistUrl,
                          ),
                        ),
                      ),
                    )),
                if (_custom.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(basicText('my_own_series_header', lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._custom.map((c) => _SeriesCard(
                        titleAr: c.titleAr,
                        subtitleAr: c.playlistId != null ? basicText('playlist_subtitle_label', lang) : basicText('single_video_subtitle_label', lang),
                        descriptionAr: null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AudioPlayerScreen(
                              seriesId: 'custom_${c.id}',
                              titleAr: c.titleAr,
                              playlistId: c.playlistId,
                              videoId: c.videoId,
                              youtubeUrl: c.playlistId != null
                                  ? 'https://www.youtube.com/playlist?list=${c.playlistId}'
                                  : 'https://www.youtube.com/watch?v=${c.videoId}',
                            ),
                          ),
                        ),
                        onDelete: () => _deleteCustomSeries(c),
                      )),
                ],
              ],
            ),
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  final String titleAr;
  final String subtitleAr;
  final String? descriptionAr;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SeriesCard({
    required this.titleAr,
    required this.subtitleAr,
    required this.descriptionAr,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.podcasts_outlined, color: AppColors.primaryDark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleAr, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitleAr, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  if (descriptionAr != null) ...[
                    const SizedBox(height: 4),
                    Text(descriptionAr!, style: const TextStyle(fontSize: 11.5, height: 1.5)),
                  ],
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
