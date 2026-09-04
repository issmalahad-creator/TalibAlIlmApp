import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/mosque.dart';
import '../../repositories/mosque_repository.dart';
import '../../services/language_preference_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import 'mosque_profile_screen.dart';

/// «مساجدنا» — the directory. Search by name, a pinned "مسجدي" card, and
/// the list of mosques. Each row opens the one reusable
/// [MosqueProfileScreen]. Nothing here is mosque-specific.
class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key});

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen> {
  final _repo = MosqueRepository();
  final _searchCtrl = TextEditingController();
  List<Mosque>? _mosques;
  Mosque? _mine;
  String _query = '';

  /// mosque id → metres from the user, when location is available. Empty
  /// means "no location" — the list keeps its name order untouched.
  Map<String, double> _distanceM = const {};

  @override
  void initState() {
    super.initState();
    _load();
    _locate();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// One-shot: reuses the same location consent flow as Prayer Times/Qibla
  /// ([LocationService.currentLocation] — GPS if granted, else cached/manual,
  /// else null). If a location comes back, measure every geo-tagged mosque
  /// and re-sort by proximity. Runs after the name-sorted list is already
  /// showing, so a slow or denied permission never blocks the directory.
  Future<void> _locate() async {
    try {
      final here = await LocationService().currentLocation();
      if (here == null || !mounted) return;
      final list = _mosques;
      final d = <String, double>{};
      for (final m in list ?? const <Mosque>[]) {
        if (m.lat != null && m.lng != null) {
          d[m.id] = Geolocator.distanceBetween(
              here.latitude, here.longitude, m.lat!, m.lng!);
        }
      }
      if (mounted && d.isNotEmpty) {
        setState(() {
          _distanceM = d;
          if (_mosques != null) _mosques = _sorted(_mosques!);
        });
      }
    } catch (_) {/* location unavailable → name order */}
  }

  List<Mosque> _sorted(List<Mosque> list) {
    if (_distanceM.isEmpty) return list;
    final out = [...list];
    out.sort((a, b) {
      if (a.isMine != b.isMine) return a.isMine ? -1 : 1;
      final da = _distanceM[a.id];
      final db = _distanceM[b.id];
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1;
      if (db != null) return 1;
      return a.name.compareTo(b.name);
    });
    return out;
  }

  Future<void> _load() async {
    final list = await _repo.allMosques(query: _query.isEmpty ? null : _query);
    final mine = await _repo.myMosque();
    if (!mounted) return;
    setState(() {
      _mosques = _sorted(list);
      _mine = mine;
    });
  }

  void _open(String id) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MosqueProfileScreen(mosqueId: id)),
      ).then((_) => _load());

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(basicText('mosques_title', lang))),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: TextField(
                controller: _searchCtrl,
                textDirection: TextDirection.rtl,
                onChanged: (v) {
                  _query = v.trim();
                  _load();
                },
                decoration: InputDecoration(
                  hintText: basicText('mosques_search_hint', lang),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: _mosques == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        if (_mine != null && _query.isEmpty) ...[
                          Text(basicText('mosque_my_mosque', lang),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          _MosqueCard(
                              mosque: _mine!,
                              lang: lang,
                              distanceM: _distanceM[_mine!.id],
                              onTap: () => _open(_mine!.id)),
                          const SizedBox(height: 16),
                          Text(basicText('mosques_all', lang),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                        ],
                        if (_mosques!.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(basicText('mosques_empty', lang),
                                  style: const TextStyle(
                                      color: AppColors.textMuted)),
                            ),
                          ),
                        for (final m in _mosques!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _MosqueCard(
                                mosque: m,
                                lang: lang,
                                distanceM: _distanceM[m.id],
                                onTap: () => _open(m.id)),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MosqueCard extends StatelessWidget {
  final Mosque mosque;
  final String lang;
  final double? distanceM;
  final VoidCallback onTap;
  const _MosqueCard(
      {required this.mosque,
      required this.lang,
      this.distanceM,
      required this.onTap});

  String get _distanceLabel {
    final d = distanceM;
    if (d == null) return '';
    if (d < 950) return '${basicText('mosque_distance_prefix', lang)} ${d.round()} ${basicText('unit_metre', lang)}';
    return '${basicText('mosque_distance_prefix', lang)} ${(d / 1000).toStringAsFixed(1)} ${basicText('unit_km', lang)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mosque_outlined,
                    color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(mosque.name,
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                        ),
                        if (mosque.verified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              size: 14, color: Color(0xFF2FAE60)),
                        ],
                      ],
                    ),
                    if ((mosque.imamName ?? '').isNotEmpty)
                      Text(mosque.imamName!,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textDark)),
                    Row(
                      children: [
                        if (mosque.locationLabel.isNotEmpty)
                          Flexible(
                            child: Text(mosque.locationLabel,
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          ),
                        if (_distanceLabel.isNotEmpty) ...[
                          if (mosque.locationLabel.isNotEmpty)
                            const Text(' · ',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          Text(_distanceLabel,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (mosque.isMine)
                const Icon(Icons.star_rounded,
                    size: 16, color: Color(0xFFB8860B)),
              const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
