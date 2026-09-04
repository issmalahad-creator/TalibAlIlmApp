import 'package:adhan_dart/adhan_dart.dart' show Prayer, PrayerTimes;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/basic_translations.dart';
import '../../models/mosque.dart';
import '../../repositories/mosque_repository.dart';
import '../../repositories/prayer_times_repository.dart';
import '../../services/language_preference_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import 'mosque_common.dart';
import 'mosque_content_list_screen.dart';
import 'mosque_gallery_screen.dart';

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
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView(
                        children: [
                          if (_repo.backendConfigured && !_repo.lastSyncOk)
                            _OfflineNotice(lang: lang),
                          _Header(mosque: p.mosque, lang: lang),
                          if (p.gallery.isNotEmpty)
                            _GalleryStrip(
                                mosqueId: p.mosque.id,
                                items: p.gallery,
                                lang: lang),
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
          if (mosque.hasGeo) ...[
            const SizedBox(height: 12),
            _MosquePrayerCard(
                lat: mosque.lat!, lng: mosque.lng!, lang: lang),
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
          if ((mosque.syncedAt ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${basicText('mosque_last_updated', lang)} · '
              '${_shortWhen(mosque.syncedAt!)}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  static String _shortWhen(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

/// Next jamāʿah near this mosque — computed from the mosque's own
/// coordinates (not the phone's), via the shared `PrayerTimesRepository`.
/// Tap to expand all five. Data-driven, reusable.
class _MosquePrayerCard extends StatefulWidget {
  final double lat;
  final double lng;
  final String lang;
  const _MosquePrayerCard(
      {required this.lat, required this.lng, required this.lang});

  @override
  State<_MosquePrayerCard> createState() => _MosquePrayerCardState();
}

class _MosquePrayerCardState extends State<_MosquePrayerCard> {
  PrayerTimes? _t;
  bool _failed = false;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    PrayerTimesRepository()
        .prayerTimesFor(
            AppCoordinates(latitude: widget.lat, longitude: widget.lng))
        .then((t) {
      if (mounted) setState(() => _t = t);
    }).catchError((_) {
      // Never blocks the rest of the mosque page on a calculation hiccup —
      // the card just quietly doesn't appear instead of spinning forever.
      if (mounted) setState(() => _failed = true);
    });
  }

  String _fmt(DateTime? utc) {
    if (utc == null) return '—';
    final l = utc.toLocal();
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final m = l.minute.toString().padLeft(2, '0');
    final p = basicText(l.hour < 12 ? 'am_period_short' : 'pm_period_short',
        widget.lang);
    return '$h:$m $p';
  }

  String _nameKey(Prayer p) => switch (p) {
        Prayer.fajr => 'prayer_fajr',
        Prayer.sunrise => 'prayer_sunrise',
        Prayer.dhuhr => 'prayer_dhuhr',
        Prayer.asr => 'prayer_asr',
        Prayer.maghrib => 'prayer_maghrib',
        Prayer.isha => 'prayer_isha',
        _ => 'prayer_fajr',
      };

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final lang = widget.lang;
    if (_failed) return const SizedBox.shrink();
    if (t == null) {
      return const SizedBox(
        height: 44,
        child: Center(
            child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final next = t.nextPrayer();
    final nextTime = t.timeForPrayer(next);
    final rows = <(String, DateTime?)>[
      ('prayer_fajr', t.fajr),
      ('prayer_dhuhr', t.dhuhr),
      ('prayer_asr', t.asr),
      ('prayer_maghrib', t.maghrib),
      ('prayer_isha', t.isha),
    ];
    return InkWell(
      onTap: () => setState(() => _open = !_open),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${basicText('mosque_next_prayer', lang)}: '
                    '${basicText(_nameKey(next), lang)} · ${_fmt(nextTime)}',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark),
                  ),
                ),
                Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18, color: AppColors.primaryDark),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 8),
              for (final (k, time) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(basicText(k, lang),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.primaryDark)),
                      const Spacer(),
                      Text(_fmt(time),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(basicText('mosque_prayer_note', lang),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontSize: 9.5, color: AppColors.primaryDark)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "بلا اتصال — تُعرض نسخة محفوظة" — shown only when the backend is
/// configured but the last pull didn't land.
class _OfflineNotice extends StatelessWidget {
  final String lang;
  const _OfflineNotice({required this.lang});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: const Color(0xFFFBEFD6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 14, color: Color(0xFF9A6B12)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(basicText('mosque_offline_cache', lang),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9A6B12))),
            ),
          ],
        ),
      );
}

/// 📸 module preview — a horizontal photo strip. "عرض الكل" → the reusable
/// [MosqueGalleryScreen]. Tap a photo → the full-screen viewer.
class _GalleryStrip extends StatelessWidget {
  final String mosqueId;
  final List<MosqueMediaItem> items;
  final String lang;
  const _GalleryStrip(
      {required this.mosqueId, required this.items, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(basicText('mosque_kind_gallery', lang),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          MosqueGalleryScreen(mosqueId: mosqueId)),
                ),
                child: Text(basicText('mosque_view_all', lang),
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MosquePhotoViewer(
                          items: items, initial: i)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 128,
                    color: AppColors.primaryLight,
                    child: Image.network(
                      items[i].url,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.primaryDark)),
                    ),
                  ),
                ),
              ),
            ),
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
