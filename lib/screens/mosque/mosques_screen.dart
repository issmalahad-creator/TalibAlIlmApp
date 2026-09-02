import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/mosque.dart';
import '../../repositories/mosque_repository.dart';
import '../../services/language_preference_service.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _repo.allMosques(query: _query.isEmpty ? null : _query);
    final mine = await _repo.myMosque();
    if (!mounted) return;
    setState(() {
      _mosques = list;
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
  final VoidCallback onTap;
  const _MosqueCard(
      {required this.mosque, required this.lang, required this.onTap});

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
                    if (mosque.locationLabel.isNotEmpty)
                      Text(mosque.locationLabel,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
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
