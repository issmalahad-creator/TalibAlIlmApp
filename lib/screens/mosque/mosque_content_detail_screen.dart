import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/basic_translations.dart';
import '../../models/mosque.dart';
import '../../repositories/mosque_repository.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';
import 'mosque_common.dart';

/// One mosque content item (a lesson / khutbah / announcement / recording /
/// need / activity). Reusable — driven only by the item's `kind` and
/// fields, never by which mosque it belongs to.
class MosqueContentDetailScreen extends StatefulWidget {
  final String contentId;
  const MosqueContentDetailScreen({super.key, required this.contentId});

  @override
  State<MosqueContentDetailScreen> createState() =>
      _MosqueContentDetailScreenState();
}

class _MosqueContentDetailScreenState extends State<MosqueContentDetailScreen> {
  final _repo = MosqueRepository();
  final _player = AudioPlayer();
  MosqueContent? _item;
  bool _loading = true;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _repo.contentItem(widget.contentId).then((c) {
      if (!mounted) return;
      setState(() {
        _item = c;
        _loading = false;
      });
    });
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String url) async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) {
        final it = _item;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
                it == null ? '' : basicText(it.kind.labelKey, lang),
                style: const TextStyle(fontSize: 15)),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : it == null
                  ? Center(
                      child: Text(basicText('mosque_content_missing', lang),
                          style: const TextStyle(color: AppColors.textMuted)))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Icon(mosqueKindIcon(it.kind),
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(basicText(it.kind.labelKey, lang),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(it.title ?? '',
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        if ((it.eventDate ?? '').isNotEmpty ||
                            (it.location ?? '').isNotEmpty ||
                            (it.organizer ?? '').isNotEmpty)
                          Text(
                            [
                              if ((it.eventDate ?? '').isNotEmpty) it.eventDate,
                              if ((it.startsAt ?? '').isNotEmpty) it.startsAt,
                              if ((it.location ?? '').isNotEmpty) it.location,
                              if ((it.organizer ?? '').isNotEmpty) it.organizer,
                            ].whereType<String>().join(' · '),
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        const SizedBox(height: 14),
                        if ((it.description ?? '').isNotEmpty)
                          Text(it.description!,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(fontSize: 14, height: 1.9)),
                        const SizedBox(height: 18),
                        if (it.isAudio)
                          _AudioTile(
                            enabled: (it.mediaUrl ?? '').isNotEmpty,
                            playing: _playing,
                            label: (it.mediaUrl ?? '').isEmpty
                                ? basicText('mosque_audio_soon', lang)
                                : (_playing
                                    ? basicText('pause_action', lang)
                                    : basicText('mosque_play_audio', lang)),
                            onTap: () => _toggleAudio(it.mediaUrl!),
                          )
                        else if (it.hasMedia)
                          OutlinedButton.icon(
                            onPressed: () => launchUrl(Uri.parse(it.mediaUrl!),
                                mode: LaunchMode.externalApplication),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: Text(basicText('mosque_open_attachment', lang)),
                          ),
                      ],
                    ),
        );
      },
    );
  }
}

class _AudioTile extends StatelessWidget {
  final bool enabled;
  final bool playing;
  final String label;
  final VoidCallback onTap;
  const _AudioTile(
      {required this.enabled,
      required this.playing,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            IconButton.filled(
              onPressed: enabled ? onTap : null,
              icon: Icon(playing
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded),
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ),
          ],
        ),
      );
}
