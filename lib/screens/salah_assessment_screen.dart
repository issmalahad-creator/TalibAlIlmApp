import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/salah_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

const _dimensionLabelKeys = {
  'muhafazah': 'dim_muhafazah',
  'onTime': 'dim_on_time',
  'jamaah': 'dim_jamaah',
  'khushu': 'dim_khushu',
  'rawatib': 'dim_rawatib',
  'adhkar': 'dim_adhkar',
  'understanding': 'dim_understanding',
};

const _prayerShortLabelKeys = {
  'fajr': 'prayer_fajr',
  'dhuhr': 'prayer_dhuhr',
  'asr': 'prayer_asr',
  'maghrib': 'prayer_maghrib',
  'isha': 'prayer_isha',
};

const _dayLabelKeys = [
  'weekday_saturday',
  'weekday_sunday',
  'weekday_monday',
  'weekday_tuesday',
  'weekday_wednesday',
  'weekday_thursday',
  'weekday_friday',
];

Color _statusColor(PrayerStatus? status) => switch (status) {
      PrayerStatus.onTime || PrayerStatus.jamaah => AppColors.primary,
      PrayerStatus.late => const Color(0xFFD9A441),
      PrayerStatus.missed => AppColors.divider,
      null => AppColors.background,
    };

/// Weekly self-assessment — Ismail's explicit condition: khushu (and every
/// other dimension here) is a number the STUDENT picks for themselves.
/// Nothing in this screen infers or claims to measure it; the app is not
/// in a position to judge a worshipper's inward state.
class SalahAssessmentScreen extends StatefulWidget {
  const SalahAssessmentScreen({super.key});

  @override
  State<SalahAssessmentScreen> createState() => _SalahAssessmentScreenState();
}

class _SalahAssessmentScreenState extends State<SalahAssessmentScreen> {
  final _repo = SalahRepository();
  Map<String, int> _ratings = {};
  (int, int) _weeklyCount = (0, 0);
  List<(String, Map<String, PrayerStatus?>)> _grid = [];
  bool _loading = true;
  late final String _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _repo.currentWeekStart();
    _load();
  }

  Future<void> _load() async {
    final ratings = await _repo.assessmentFor(_weekStart);
    final count = await _repo.weeklyCompletionCount(_weekStart);
    final grid = await _repo.weeklyGrid(_weekStart);
    if (!mounted) return;
    setState(() {
      _ratings = ratings;
      _weeklyCount = count;
      _grid = grid;
      _loading = false;
    });
  }

  Future<void> _setRating(String dimension, int rating) async {
    await _repo.setRating(_weekStart, dimension, rating);
    setState(() => _ratings = {..._ratings, dimension: rating});
  }

  @override
  Widget build(BuildContext context) {
    final (completed, total) = _weeklyCount;
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(title: Text(basicText('weekly_assessment_tooltip', lang))),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_generic', lang))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: Text(
                      '${basicText('weekly_progress_prefix', lang)} $completed ${basicText('weekly_progress_middle', lang)} $total ${basicText('weekly_progress_suffix', lang)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                Text(basicText('week_in_detail_header', lang), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (_grid.isNotEmpty) _WeeklyGrid(grid: _grid),
                const SizedBox(height: 20),
                Text(basicText('rate_yourself_honestly_subtitle', lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                ..._dimensionLabelKeys.entries.map((entry) {
                  final rating = _ratings[entry.key] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(basicText(entry.value, lang), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (i) {
                            final starIndex = i + 1;
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                starIndex <= rating ? Icons.star : Icons.star_border,
                                color: AppColors.primaryDark,
                                size: 26,
                              ),
                              onPressed: () => _setRating(entry.key, starIndex),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
      ),
    );
  }
}

/// Read-only 5×7 overview of this week's tracker data — closes the
/// "weekly aggregate report" piece from Ismail's original إقامة الصلاة
/// design (combined with the self-assessment stars above it). Purely
/// descriptive: a grey dot just means "not recorded", never "missed and
/// judged" — matches the tracker's own non-punitive framing.
class _WeeklyGrid extends StatelessWidget {
  final List<(String, Map<String, PrayerStatus?>)> grid;
  const _WeeklyGrid({required this.grid});

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 44),
              ..._dayLabelKeys.map((k) => Expanded(child: Text(basicText(k, lang), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)))),
            ],
          ),
          const SizedBox(height: 6),
          ..._prayerShortLabelKeys.entries.map((prayer) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(width: 44, child: Text(basicText(prayer.value, lang), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))),
                    ...grid.map((day) => Expanded(
                          child: Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: _statusColor(day.$2[prayer.key]), shape: BoxShape.circle, border: Border.all(color: AppColors.divider, width: 0.5)),
                            ),
                          ),
                        )),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
