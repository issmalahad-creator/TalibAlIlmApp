import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/akhlaq.dart';
import '../../repositories/akhlaq_repository.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';

/// AKHLAQ · P4 — the training indicator for the الرِّفق slice.
///
/// **Not a verdict on the person.** Per subskill: a descriptive band, the
/// count of times the closest response was chosen, and the response
/// dimension that showed weakness recently. No single number, no overall
/// score, no comparison (`AKHLAQ_SYSTEM_PHILOSOPHY §6/§7`,
/// `AKHLAQ_ARCHITECTURE §5`). The disclaimer is mandatory.
class AkhlaqProfileScreen extends StatefulWidget {
  const AkhlaqProfileScreen({super.key});

  @override
  State<AkhlaqProfileScreen> createState() => _AkhlaqProfileScreenState();
}

class _AkhlaqProfileScreenState extends State<AkhlaqProfileScreen> {
  final _repo = AkhlaqRepository();

  String get _lang => LanguagePreferenceService.currentLanguage;

  bool _loading = true;
  AkhlaqSlice? _slice;
  Map<String, AkhlaqProgress> _progress = const {};
  Map<String, int> _aqrabCount = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final slice = await _repo.slice();
    final progress = await _repo.progressAll();
    final attempts = await _repo.attempts();
    final aqrab = <String, int>{};
    for (final a in attempts) {
      if (a.verdict == 'aqrab') {
        aqrab[a.subskill] = (aqrab[a.subskill] ?? 0) + 1;
      }
    }
    if (!mounted) return;
    setState(() {
      _slice = slice;
      _progress = {for (final p in progress) p.subskill: p};
      _aqrabCount = aqrab;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(basicText('akhlaq_profile_title', _lang))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _body(),
      ),
    );
  }

  Widget _body() {
    final subskills = _slice?.subskills ?? const <AkhlaqSubskill>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(basicText('akhlaq_disclaimer', _lang),
              style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark)),
        ),
        const SizedBox(height: 18),
        for (final s in subskills) _subskillCard(s),
      ],
    );
  }

  Widget _subskillCard(AkhlaqSubskill s) {
    final p = _progress[s.slug];
    final attempts = p?.attempts ?? 0;
    final aqrab = _aqrabCount[s.slug] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(s.titleAr,
                      style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 15,
                          color: AppColors.textDark)),
                ),
                const SizedBox(width: 8),
                _bandChip(p?.band ?? 'beginner'),
              ],
            ),
            const SizedBox(height: 8),
            if (attempts == 0)
              Text(basicText('akhlaq_no_attempts', _lang),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted))
            else ...[
              Text(
                basicText('akhlaq_aqrab_count', _lang)
                    .replaceFirst('{n}', '$attempts')
                    .replaceFirst('{k}', '$aqrab'),
                style: const TextStyle(
                    fontSize: 12.5, height: 1.6, color: AppColors.textDark),
              ),
              if (p?.weakDimension != null && p!.weakDimension!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${basicText('akhlaq_weak_dim', _lang)}: '
                  '${_dimLabel(p.weakDimension!)}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _bandChip(String band) {
    final c = _bandColor(band);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(basicText('akhlaq_band_$band', _lang),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: c)),
    );
  }

  Color _bandColor(String band) {
    switch (band) {
      case 'mastery':
        return const Color(0xFF2E7D32);
      case 'stable':
        return const Color(0xFF3B7DB0);
      case 'practising':
        return const Color(0xFFB07D18);
      case 'review':
        return const Color(0xFFB3261E);
      default:
        return AppColors.textMuted;
    }
  }

  String _dimLabel(String dim) => basicText('akhlaq_dim_$dim', _lang);
}
