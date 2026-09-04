import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/life_plan.dart';
import '../repositories/life_plan_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';

/// «مُحرّك الحياة» — L3 · «التقدّم» (`docs/LIFE_ENGINE.md`).
///
/// Rolling windows (اليوم / 7 / 30 / منذ البدء), the streak (with its
/// weekly grace day), an **infinite** day‑by‑day heatmap that scrolls back
/// to the start date, and per‑pillar momentum with a slip forecast. Nothing
/// here ends at day 90.
class LifeProgressScreen extends StatefulWidget {
  const LifeProgressScreen({super.key});

  @override
  State<LifeProgressScreen> createState() => _LifeProgressScreenState();
}

class _LifeProgressScreenState extends State<LifeProgressScreen> {
  final _repo = LifePlanRepository();

  bool _loading = true;
  double _today = 0, _w7 = 0, _w30 = 0, _all = 0;
  int _streak = 0, _dayIndex = 0;
  List<LifePillar> _pillars = const [];
  Map<String, ({double now, double prev, bool slipping})> _trend = const {};
  List<({DateTime date, double pct})> _heat = const [];

  String get _lang => LanguagePreferenceService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final di = await _repo.dayIndex();
    final start = await _repo.startDate();
    final pillars = await _repo.pillars();
    final trend = await _repo.pillarMomentumTrend();
    final t = await _repo.rollingAverage(1);
    final w7 = await _repo.rollingAverage(7);
    final w30 = await _repo.rollingAverage(30);
    final all = await _repo.rollingAverage(di + 1);
    final streak = await _repo.streak();
    final pcts = await _repo.dayPercents(
        LifePlanRepository.ymd(start), LifePlanRepository.today());
    final heat = <({DateTime date, double pct})>[];
    for (var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(DateTime.now());
        d = d.add(const Duration(days: 1))) {
      heat.add((date: d, pct: pcts[LifePlanRepository.ymd(d)] ?? 0.0));
    }
    if (!mounted) return;
    setState(() {
      _dayIndex = di;
      _pillars = pillars;
      _trend = trend;
      _today = t;
      _w7 = w7;
      _w30 = w30;
      _all = all;
      _streak = streak;
      _heat = heat;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EE),
      appBar: AppBar(
        title: Text(basicText('life_progress_title', lang),
            textDirection: TextDirection.rtl),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  _windowsRow(lang),
                  const SizedBox(height: 14),
                  _streakCard(lang),
                  const SizedBox(height: 18),
                  _sectionTitle(basicText('life_heatmap_title', lang)),
                  const SizedBox(height: 8),
                  _heatmap(),
                  const SizedBox(height: 18),
                  _sectionTitle(basicText('life_momentum_title', lang)),
                  const SizedBox(height: 8),
                  for (final p in _pillars) _momentumRow(p, lang),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13));

  // ── rolling windows ─────────────────────────────────────────────────

  Widget _windowsRow(String lang) {
    Widget cell(String label, double v) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Text('${(v * 100).round()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFFD9A441))),
                const SizedBox(height: 2),
                Text(label,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        );
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        cell(basicText('life_win_today', lang), _today),
        cell(basicText('life_win_7', lang), _w7),
        cell(basicText('life_win_30', lang), _w30),
        cell(basicText('life_win_all', lang), _all),
      ],
    );
  }

  Widget _streakCard(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0x33D9A441)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_streak ${basicText('life_streak_days', lang)}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textDark),
                ),
                Text(basicText('life_streak_grace', lang),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            '${basicText('life_day_word', lang)} ${_dayIndex + 1}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ── infinite heatmap ────────────────────────────────────────────────

  Widget _heatmap() {
    // group into week columns of 7 (oldest → newest); newest week first
    // because the ListView is reversed.
    final weeks = <List<({DateTime date, double pct})>>[];
    for (var i = 0; i < _heat.length; i += 7) {
      weeks.add(_heat.sublist(i, (i + 7).clamp(0, _heat.length)));
    }
    final todayY = LifePlanRepository.ymd(DateTime.now());
    Color cellColor(double p) {
      if (p <= 0) return const Color(0xFFEDE7DC);
      return Color.lerp(const Color(0xFFF0DDB0), const Color(0xFFD9A441),
          p.clamp(0.0, 1.0))!;
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: weeks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (_, wi) {
          final week = weeks[weeks.length - 1 - wi];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in week)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    color: cellColor(d.pct),
                    borderRadius: BorderRadius.circular(3),
                    border: LifePlanRepository.ymd(d.date) == todayY
                        ? Border.all(color: const Color(0xFF2F5C46), width: 1.4)
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── per-pillar momentum + forecast ──────────────────────────────────

  Widget _momentumRow(LifePillar p, String lang) {
    final t = _trend[p.key];
    final now = t?.now ?? 0.0;
    final slipping = t?.slipping ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: slipping
                ? const Color(0x55D9534F)
                : AppColors.divider),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(p.emoji.isEmpty ? '•' : p.emoji,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        p.label.replaceFirst(RegExp(r'^\S+\s+'), ''),
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (slipping)
                      Text(basicText('life_slipping', lang),
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB5443F))),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: now.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                        slipping
                            ? const Color(0xFFB5443F)
                            : const Color(0xFFD9A441)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${(now * 100).round()}%',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
