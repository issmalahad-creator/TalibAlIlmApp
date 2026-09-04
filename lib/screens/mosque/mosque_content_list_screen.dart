import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/mosque.dart';
import '../../repositories/mosque_repository.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';
import 'mosque_common.dart';
import 'mosque_content_detail_screen.dart';

/// "عرض الكل" for one section of one mosque. Reusable — the section `kind`
/// is the only parameter that changes what it shows.
class MosqueContentListScreen extends StatefulWidget {
  final String mosqueId;
  final MosqueContentKind kind;
  const MosqueContentListScreen(
      {super.key, required this.mosqueId, required this.kind});

  @override
  State<MosqueContentListScreen> createState() =>
      _MosqueContentListScreenState();
}

class _MosqueContentListScreenState extends State<MosqueContentListScreen> {
  // hoisted so a language change (which rebuilds via ValueListenableBuilder)
  // doesn't re-run the query and flash a spinner.
  late final Future<List<MosqueContent>> _future =
      MosqueRepository().content(widget.mosqueId, widget.kind);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(basicText(widget.kind.labelKey, lang))),
        body: FutureBuilder<List<MosqueContent>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return Center(
                child: Text(basicText('mosque_section_empty', lang),
                    style: const TextStyle(color: AppColors.textMuted)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  MosqueContentTile(item: items[i], lang: lang),
            );
          },
        ),
      ),
    );
  }
}

class MosqueContentTile extends StatelessWidget {
  final MosqueContent item;
  final String lang;
  final bool dense;
  const MosqueContentTile(
      {super.key, required this.item, required this.lang, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final sub = [
      if ((item.eventDate ?? '').isNotEmpty) item.eventDate,
      if ((item.startsAt ?? '').isNotEmpty) item.startsAt,
      if ((item.location ?? '').isNotEmpty) item.location,
    ].whereType<String>().join(' · ');
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  MosqueContentDetailScreen(contentId: item.id)),
        ),
        child: Padding(
          padding: EdgeInsets.all(dense ? 10 : 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(mosqueKindIcon(item.kind),
                    size: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title ?? basicText(item.kind.labelKey, lang),
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    if (sub.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(sub,
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ),
                  ],
                ),
              ),
              if (item.isAudio)
                const Icon(Icons.headphones_rounded,
                    size: 16, color: AppColors.textMuted),
              const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
