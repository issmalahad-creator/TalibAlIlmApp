import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/memorization_repository.dart';
import '../repositories/worship_coach_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'adhkar_screen.dart';
import 'quran_browse_screen.dart';
import 'review_screen.dart';
import 'salah_tracker_screen.dart';
import '../widgets/loading_view.dart';

/// "مدرب العبادة" — Ismail's request 2026-08-16: a rule-based (no AI)
/// coaching engine across Salah/Quran/Dhikr. This screen is the detail
/// view behind `WorshipCoachCard` — shows the one current stage, the one
/// recommended task with a direct button into the relevant screen, and an
/// honest breakdown of the 3 consistency numbers driving the
/// recommendation (transparency instead of an opaque "AI suggests..."),
/// per his explicit "no AI, plain rules" instruction.
class WorshipCoachScreen extends StatefulWidget {
  const WorshipCoachScreen({super.key});

  @override
  State<WorshipCoachScreen> createState() => _WorshipCoachScreenState();
}

class _WorshipCoachScreenState extends State<WorshipCoachScreen> {
  final _repo = WorshipCoachRepository();
  final _memoRepo = MemorizationRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};
  WorshipCoachStatus? _status;
  int _manzilPortion = 0;
  List<(MemorizationUnit unit, int mistakeCount)> _weakSpots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _repo.status();
    final manzilPortion = await _memoRepo.manzilDailyPortionSize();
    final weakSpots = await _memoRepo.recurringWeakSpots();
    if (!mounted) return;
    setState(() {
      _status = status;
      _manzilPortion = manzilPortion;
      _weakSpots = weakSpots;
    });
  }

  void _openTaskScreen() {
    final status = _status;
    if (status == null) return;
    Widget? screen;
    switch (status.taskArea) {
      case CoachFocusArea.prayer:
        screen = const SalahTrackerScreen();
        break;
      case CoachFocusArea.quran:
        screen = status.quranTaskIsReview ? const ReviewScreen() : const QuranBrowseScreen();
        break;
      case CoachFocusArea.dhikr:
        screen = const AdhkarScreen();
        break;
      case CoachFocusArea.stable:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!)).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(title: Text(basicText('worship_coach_title', lang))),
      body: status == null
          ? AppLoadingView(icon: Icons.route_outlined, message: basicText('analyzing_consistency_message', lang))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status.stageLabel, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(status.taskLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      if (status.taskArea != CoachFocusArea.stable) ...[
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _openTaskScreen,
                          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
                          child: Text(basicText('onboarding_start_now', lang)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(basicText('how_we_determine_task_header', lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  basicText('coach_rule_explanation', lang),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.6),
                ),
                const SizedBox(height: 16),
                _ConsistencyRow(label: basicText('consistency_prayer_label', lang), value: status.prayerConsistency, isFocus: status.focus == CoachFocusArea.prayer),
                const SizedBox(height: 10),
                _ConsistencyRow(label: basicText('consistency_quran_label', lang), value: status.quranConsistency, isFocus: status.focus == CoachFocusArea.quran),
                const SizedBox(height: 10),
                _ConsistencyRow(label: basicText('consistency_dhikr_label', lang), value: status.dhikrConsistency, isFocus: status.focus == CoachFocusArea.dhikr),
                if (_manzilPortion > 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                    child: Row(
                      children: [
                        const Icon(Icons.replay_circle_filled_outlined, color: AppColors.primaryDark, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(basicText('manzil_weekly_portion_title', lang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(
                                '${basicText('manzil_weekly_portion_prefix', lang)} $_manzilPortion ${basicText('manzil_weekly_portion_suffix', lang)}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_weakSpots.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(basicText('weak_spots_header', lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(basicText('weak_spots_subtitle', lang), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  ..._weakSpots.map((w) {
                    final (unit, mistakeCount) = w;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${basicText('page_word_prefix', lang)} ${unit.id} — ${basicText('from_surah_prefix', lang)} ${_surahNames[unit.surahStart] ?? unit.surahStart}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text('$mistakeCount ${basicText('times_count_suffix', lang)}', style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(basicText('additional_tasks_soon_title', lang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        basicText('additional_tasks_soon_body', lang),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.6),
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

class _ConsistencyRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isFocus;
  const _ConsistencyRow({required this.label, required this.value, required this.isFocus});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    final color = isFocus ? const Color(0xFFB8860B) : AppColors.primary;
    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: isFocus ? color : AppColors.divider, width: isFocus ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    if (isFocus) ...[
                      const SizedBox(width: 6),
                      _PulsingFocusBadge(color: color),
                    ],
                  ],
                ),
                Text('$percent%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 8, backgroundColor: AppColors.divider, valueColor: AlwaysStoppedAnimation(color)),
            ),
            const SizedBox(height: 4),
            Text(basicText('last_7_days_label', LanguagePreferenceService.currentLanguage), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Gently pulsing "التركيز الآن" badge — Ismail's 2026-08-16 decorative-
/// features request (roadmap §4.34 point 6): a subtle, continuous
/// scale-pulse draws the eye to which domain the coach is actually
/// recommending right now, on top of the existing color highlight.
class _PulsingFocusBadge extends StatefulWidget {
  final Color color;
  const _PulsingFocusBadge({required this.color});

  @override
  State<_PulsingFocusBadge> createState() => _PulsingFocusBadgeState();
}

class _PulsingFocusBadgeState extends State<_PulsingFocusBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(scale: 1.0 + 0.1 * _controller.value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Text(basicText('focus_now_badge_label', LanguagePreferenceService.currentLanguage), style: TextStyle(fontSize: 9.5, color: widget.color, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
