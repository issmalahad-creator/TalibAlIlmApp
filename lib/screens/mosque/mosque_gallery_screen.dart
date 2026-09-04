import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/mosque.dart';
import '../../repositories/mosque_repository.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';

/// «مساجدنا» — the 📸 module. One reusable grid of a mosque's photos, driven
/// only by [mosqueId]; tapping opens a full-screen, pinch-to-zoom viewer.
/// Nothing here is mosque-specific.
class MosqueGalleryScreen extends StatefulWidget {
  final String mosqueId;
  const MosqueGalleryScreen({super.key, required this.mosqueId});

  @override
  State<MosqueGalleryScreen> createState() => _MosqueGalleryScreenState();
}

class _MosqueGalleryScreenState extends State<MosqueGalleryScreen> {
  late final Future<List<MosqueMediaItem>> _future =
      MosqueRepository().media(widget.mosqueId, limit: 120);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(basicText('mosque_kind_gallery', lang))),
        body: FutureBuilder<List<MosqueMediaItem>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return Center(
                child: Text(basicText('mosque_gallery_empty', lang),
                    style: const TextStyle(color: AppColors.textMuted)),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => _Thumb(
                item: items[i],
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MosquePhotoViewer(items: items, initial: i),
                )),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final MosqueMediaItem item;
  final VoidCallback onTap;
  const _Thumb({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: AppColors.primaryLight,
          child: Image.network(
            item.url,
            fit: BoxFit.cover,
            loadingBuilder: (c, w, p) => p == null
                ? w
                : const Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))),
            errorBuilder: (c, e, s) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    color: AppColors.primaryDark)),
          ),
        ),
      ),
    );
  }
}

/// Full-screen, swipe-between, pinch-to-zoom viewer. Reusable.
class MosquePhotoViewer extends StatefulWidget {
  final List<MosqueMediaItem> items;
  final int initial;
  const MosquePhotoViewer(
      {super.key, required this.items, this.initial = 0});

  @override
  State<MosquePhotoViewer> createState() => _MosquePhotoViewerState();
}

class _MosquePhotoViewerState extends State<MosquePhotoViewer> {
  late final PageController _ctrl =
      PageController(initialPage: widget.initial);
  late int _i = widget.initial;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.items[_i].caption ?? '';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_i + 1} / ${widget.items.length}',
            style: const TextStyle(fontSize: 14)),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              onPageChanged: (v) => setState(() => _i = v),
              itemCount: widget.items.length,
              itemBuilder: (context, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.items[i].url,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48),
                  ),
                ),
              ),
            ),
          ),
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Text(caption,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
