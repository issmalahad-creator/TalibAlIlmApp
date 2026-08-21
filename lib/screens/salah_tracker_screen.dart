import 'package:flutter/material.dart';

import '../data/salah_content.dart';
import '../l10n/basic_translations.dart';
import '../repositories/salah_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'salah_assessment_screen.dart';
import 'salah_library_screen.dart';
import 'salah_stories_screen.dart';
import 'salah_resources_screen.dart';
import '../widgets/loading_view.dart';

const _prayerLabelKeys = {
  'fajr': 'prayer_fajr',
  'dhuhr': 'prayer_dhuhr',
  'asr': 'prayer_asr',
  'maghrib': 'prayer_maghrib',
  'isha': 'prayer_isha',
};

const _statusLabelKeys = {
  PrayerStatus.onTime: ('prayed_on_time_status', Icons.check_circle_outline),
  PrayerStatus.jamaah: ('prayed_jamaah_status', Icons.groups_outlined),
  PrayerStatus.late: ('prayed_late_status', Icons.schedule_outlined),
  PrayerStatus.missed: ('prayer_missed_status', Icons.remove_circle_outline),
};

/// "إقامة الصلاة" — Ismail's request 2026-08-16: not just prayer times,
/// but a gentle daily companion for actually establishing the prayer.
/// Tracking is entirely non-judgmental — a missed prayer is simply
/// recorded, never flagged, shamed, or treated as a "streak broken"
/// event, matching this app's non-punitive principle throughout.
class SalahTrackerScreen extends StatefulWidget {
  const SalahTrackerScreen({super.key});

  @override
  State<SalahTrackerScreen> createState() => _SalahTrackerScreenState();
}

class _SalahTrackerScreenState extends State<SalahTrackerScreen> {
  final _repo = SalahRepository();
  Map<String, PrayerStatus?> _statuses = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final statuses = await _repo.statusesForToday();
    if (!mounted) return;
    setState(() {
      _statuses = statuses;
      _loading = false;
    });
  }

  Future<void> _pickStatus(String prayer) async {
    final lang = LanguagePreferenceService.currentLanguage;
    final chosen = await showModalBottomSheet<PrayerStatus>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${basicText(_prayerLabelKeys[prayer]!, lang)} — ${basicText('prayer_status_question_suffix', lang)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            for (final status in PrayerStatus.values)
              ListTile(
                leading: Icon(_statusLabelKeys[status]!.$2, color: AppColors.primaryDark),
                title: Text(basicText(_statusLabelKeys[status]!.$1, lang)),
                onTap: () => Navigator.pop(context, status),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await _repo.setStatus(prayer, chosen);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(
        title: Text(basicText('salah_tracker_title', lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: basicText('weekly_assessment_tooltip', lang),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahAssessmentScreen())),
          ),
        ],
      ),
      body: _loading
          ? AppLoadingView(icon: Icons.mosque_outlined, message: basicText('loading_salah_log', lang))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TodaysMissionCard(onOpenLibrary: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahLibraryScreen()))),
                const SizedBox(height: 16),
                Text(basicText('todays_prayers_header', lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(basicText('log_honestly_subtitle', lang), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 14),
                ..._prayerLabelKeys.entries.map((entry) {
                  final status = _statuses[entry.key];
                  final labelInfo = status == null ? null : _statusLabelKeys[status];
                  return InkWell(
                    onTap: () => _pickStatus(entry.key),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: status != null ? AppColors.primaryLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: status != null ? AppColors.primary : AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(labelInfo?.$2 ?? Icons.circle_outlined, size: 20, color: status != null ? AppColors.primaryDark : AppColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(child: Text(basicText(entry.value, lang), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
                          Text(labelInfo == null ? basicText('not_recorded_yet_label', lang) : basicText(labelInfo.$1, lang),
                              style: TextStyle(fontSize: 12, color: status != null ? AppColors.primaryDark : AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahLibraryScreen())),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(basicText('salah_library_action', lang)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahStoriesScreen())),
                  icon: const Icon(Icons.auto_stories_outlined),
                  label: Text(basicText('salah_stories_action', lang)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahResourcesScreen())),
                  icon: const Icon(Icons.library_books_outlined),
                  label: Text(basicText('salah_resources_action', lang)),
                ),
              ],
            ),
      ),
    );
  }
}

/// "مهمة اليوم" — a small rotating lesson from the library shown right on
/// the tracker screen, so building understanding happens naturally
/// alongside the daily habit rather than requiring a separate trip to the
/// library. Same lesson content as `SalahLibraryScreen`, just surfaced
/// contextually — no new content, no separate completion tracking.
class _TodaysMissionCard extends StatelessWidget {
  final VoidCallback onOpenLibrary;
  const _TodaysMissionCard({required this.onOpenLibrary});

  @override
  Widget build(BuildContext context) {
    final lesson = todaysSalahMission();
    final lang = LanguagePreferenceService.currentLanguage;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_outlined, size: 16, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Text(basicText('todays_mission_label', lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text(lesson.titleAr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(lesson.bodyAr, style: const TextStyle(fontSize: 12.5, height: 1.7)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onOpenLibrary, child: Text(basicText('view_full_library_action', lang), style: const TextStyle(fontSize: 12))),
          ),
        ],
      ),
    );
  }
}
