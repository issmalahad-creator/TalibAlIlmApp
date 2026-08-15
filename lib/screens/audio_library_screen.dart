import 'package:flutter/material.dart';

import '../data/audio_series_seed.dart';
import '../repositories/audio_library_repository.dart';
import '../theme/app_theme.dart';
import 'audio_player_screen.dart';

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
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أضف سلسلة صوتية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'اسم السلسلة أو الدرس'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'رابط يوتيوب (فيديو أو قائمة تشغيل)'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'يُشغَّل عبر مشغّل يوتيوب الرسمي داخل التطبيق — لا يُحمَّل أي شيء على جهازك',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة')),
        ],
      ),
    );
    if (saved != true) return;
    final parsed = parseYoutubeUrl(urlCtrl.text);
    if (!parsed.isValid || titleCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تأكد من إدخال الاسم ورابط يوتيوب صحيح')),
      );
      return;
    }
    await _repo.addCustomSeries(titleCtrl.text.trim(), parsed);
    _load();
  }

  Future<void> _deleteCustomSeries(CustomAudioSeries s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السلسلة'),
        content: Text('حذف "${s.titleAr}"؟ هذا لا يحذف الفيديو من يوتيوب، فقط من قائمتك هنا.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.deleteCustomSeries(s.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كتب صوتية من اليوتيوب'),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: 'أضف سلسلة', onPressed: _addCustomSeries),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'تُبَث هذه المقاطع مباشرة من يوتيوب عبر مشغّله الرسمي — لا يُحمَّل أو يُعاد استضافة أي صوت داخل التطبيق، ويحتاج التشغيل اتصالًا بالإنترنت.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
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
                  const Text('سلاسلي الخاصة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._custom.map((c) => _SeriesCard(
                        titleAr: c.titleAr,
                        subtitleAr: c.playlistId != null ? 'قائمة تشغيل' : 'فيديو واحد',
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
