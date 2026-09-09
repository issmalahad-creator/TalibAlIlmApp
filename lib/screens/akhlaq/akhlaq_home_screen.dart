import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/akhlaq.dart';
import '../../repositories/akhlaq_repository.dart';
import '../../services/akhlaq/akhlaq_engine.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';
import 'akhlaq_profile_screen.dart';
import 'akhlaq_scenario_screen.dart';

/// AKHLAQ · P4 — the training home for the الرِّفق slice.
///
/// Shows «تكليف اليوم» (from the spaced-repetition plan), a "focus of the
/// week" picker, and a link to the training indicator. Every item opens a
/// sourced scenario for its subskill.
class AkhlaqHomeScreen extends StatefulWidget {
  const AkhlaqHomeScreen({super.key});

  @override
  State<AkhlaqHomeScreen> createState() => _AkhlaqHomeScreenState();
}

class _AkhlaqHomeScreenState extends State<AkhlaqHomeScreen> {
  final _repo = AkhlaqRepository();

  String get _lang => LanguagePreferenceService.currentLanguage;

  bool _loading = true;
  AkhlaqSlice? _slice;
  List<TrainingItem> _plan = const [];
  String? _focus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final slice = await _repo.slice();
    final plan = await _repo.todayPlan();
    final focus = await _repo.focusSubskill();
    if (!mounted) return;
    setState(() {
      _slice = slice;
      _plan = plan;
      _focus = focus;
      _loading = false;
    });
  }

  String _subskillTitle(String slug) =>
      _slice?.subskillBySlug(slug)?.titleAr ?? slug;

  String _trackLabel(String track) {
    switch (track) {
      case 'K':
        return basicText('akhlaq_track_k', _lang);
      case 'R':
        return basicText('akhlaq_track_r', _lang);
      default:
        return basicText('akhlaq_track_s', _lang);
    }
  }

  Future<void> _openItem(TrainingItem item) async {
    var scenarioId = item.scenarioId;
    final slice = _slice;
    if (scenarioId == null && slice != null) {
      final attempts = await _repo.attempts();
      final prog =
          rollSubskillTrend(subskill: item.subskill, attempts: attempts);
      scenarioId = pickNextScenario(
        subskill: item.subskill,
        difficulty: item.difficulty,
        slice: slice,
        attempts: attempts,
        weakDimension: prog.weakDimension,
      );
    }
    if (scenarioId == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AkhlaqScenarioScreen(scenarioId: scenarioId!)),
    );
    _load();
  }

  Future<void> _setFocus(String? slug) async {
    await _repo.setFocusSubskill(slug);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(basicText('akhlaq_home_title', _lang))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(onRefresh: _load, child: _body()),
      ),
    );
  }

  Widget _body() {
    final v = _slice?.virtue;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        if (v != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.titleAr,
                    style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark)),
                const SizedBox(height: 4),
                Text('${basicText('akhlaq_opposite', _lang)}: ${v.opposite}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Text(basicText('akhlaq_today_plan', _lang),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textDark)),
        const SizedBox(height: 10),
        if (_plan.isEmpty)
          Text(basicText('akhlaq_no_plan', _lang),
              style: const TextStyle(color: AppColors.textMuted))
        else
          for (final item in _plan) _planRow(item),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AkhlaqProfileScreen()),
          ),
          icon: const Icon(Icons.insights_outlined, size: 18),
          label: Text(basicText('akhlaq_open_profile', _lang)),
        ),
        const SizedBox(height: 24),
        Text(basicText('akhlaq_focus_week', _lang),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(basicText('akhlaq_focus_hint', _lang),
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _slice?.subskills ?? const <AkhlaqSubskill>[])
              ChoiceChip(
                label: Text(s.titleAr,
                    style: const TextStyle(fontSize: 12, fontFamily: 'Amiri')),
                selected: _focus == s.slug,
                onSelected: (sel) => _setFocus(sel ? s.slug : null),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(basicText('akhlaq_disclaimer', _lang),
              style: const TextStyle(
                  fontSize: 11.5, height: 1.6, color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Widget _planRow(TrainingItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openItem(item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_trackLabel(item.track),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_subskillTitle(item.subskill),
                    style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 15,
                        color: AppColors.textDark)),
              ),
              const Icon(Icons.chevron_left_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
