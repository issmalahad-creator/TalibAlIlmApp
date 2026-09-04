import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/basic_translations.dart';
import '../../models/mosque.dart';
import '../../repositories/mosque_repository.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';
import 'mosque_common.dart';
import 'mosque_content_list_screen.dart';

/// **The** mosque page. One reusable template, an instance per [mosqueId].
/// It never hardcodes a mosque's name, sections, content or icons — all of
/// that comes from [MosqueRepository]. A new mosque (created later by the
/// Telegram bot / backend) renders here with zero new Dart.
/// See `docs/MOSQUE_PLATFORM_VISION.md`.
class MosqueProfileScreen extends StatefulWidget {
  final String mosqueId;
  const MosqueProfileScreen({super.key, required this.mosqueId});

  @override
  State<MosqueProfileScreen> createState() => _MosqueProfileScreenState();
}

class _MosqueProfileScreenState extends State<MosqueProfileScreen> {
  final _repo = MosqueRepository();
  MosqueProfile? _p;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final p = await _repo.profile(widget.mosqueId);
    if (!mounted) return;
    setState(() {
      _p = p;
      _loading = false;
    });
  }

  Future<void> _toggleMine(Mosque m) async {
    if (m.isMine) {
      await _repo.clearMyMosque();
    } else {
      await _repo.setMyMosque(m.id);
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) {
        final p = _p;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(p?.mosque.name ?? '',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 15)),
            actions: [
              if (p != null)
                IconButton(
                  tooltip: basicText(
                      p.mosque.isMine ? 'mosque_unset_mine' : 'mosque_set_mine',
                      lang),
                  icon: Icon(p.mosque.isMine
                      ? Icons.star_rounded
                      : Icons.star_border_rounded),
                  onPressed: () => _toggleMine(p.mosque),
                ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : p == null
                  ? Center(
                      child: Text(basicText('mosque_content_missing', lang),
                          style: const TextStyle(color: AppColors.textMuted)))
                  : ListView(
                      children: [
                        _Header(mosque: p.mosque, lang: lang),
                        for (final s in p.sections)
                          if (p.previews[s.type] != null)
                            _SectionPreview(
                              mosqueId: p.mosque.id,
                              section: s,
                              items: p.previews[s.type]!,
                              lang: lang,
                            ),
                        _ServicesGrid(
                            mosqueId: p.mosque.id,
                            sections: p.sections,
                            lang: lang),
                        const SizedBox(height: 24),
                      ],
                    ),
        );
      },
    );
  }
}

/// The section's label follows the app language: `basicText(kind.labelKey)`
/// when a translation exists, else the mosque's own seeded `title`.
String _sectionLabel(MosqueSection section, String lang) {
  final k = section.type.labelKey;
  final v = basicText(k, lang);
  return v == k ? section.title : v;
}

class _Header extends StatelessWidget {
  final Mosque mosque;
  final String lang;
  const _Header({required this.mosque, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((mosque.imageUrl ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(mosque.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.mosque_outlined,
                              size: 48, color: AppColors.primaryDark))),
                ),
              ),
            )
          else
            Container(
              height: 96,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.mosque_outlined,
                  size: 44, color: AppColors.primaryDark),
            ),
          Text(mosque.name,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontFamily: 'Amiri', fontSize: 20, fontWeight: FontWeight.w800)),
          if ((mosque.imamName ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(mosque.imamName!,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (mosque.locationLabel.isNotEmpty) ...[
                const Icon(Icons.place_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(mosque.locationLabel,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
              const Spacer(),
              if (mosque.verified)
                VerifiedChip(label: basicText('mosque_verified', lang)),
            ],
          ),
          if ((mosque.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(mosque.description!,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 13, height: 1.8)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (mosque.hasGeo)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                        Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${mosque.lat},${mosque.lng}'),
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.directions_outlined, size: 16),
                    label: Text(basicText('mosque_directions', lang)),
                  ),
                ),
              if (mosque.hasGeo && (mosque.phone ?? '').isNotEmpty)
                const SizedBox(width: 10),
              if ((mosque.phone ?? '').isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:${mosque.phone}')),
                    icon: const Icon(Icons.call_outlined, size: 16),
                    label: Text(basicText('mosque_contact', lang)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionPreview extends StatelessWidget {
  final String mosqueId;
  final MosqueSection section;
  final List<MosqueContent> items;
  final String lang;
  const _SectionPreview(
      {required this.mosqueId,
      required this.section,
      required this.items,
      required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(mosqueKindIcon(section.type),
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(_sectionLabel(section, lang),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MosqueContentListScreen(
                          mosqueId: mosqueId, kind: section.type)),
                ),
                child: Text(basicText('mosque_view_all', lang),
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: MosqueContentTile(item: it, lang: lang, dense: true),
            ),
        ],
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  final String mosqueId;
  final List<MosqueSection> sections;
  final String lang;
  const _ServicesGrid(
      {required this.mosqueId, required this.sections, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(basicText('mosque_services', lang),
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              for (final s in sections)
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MosqueContentListScreen(
                            mosqueId: mosqueId, kind: s.type)),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(mosqueKindIcon(s.type),
                            color: AppColors.primary, size: 22),
                        const SizedBox(height: 6),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(_sectionLabel(s, lang),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
