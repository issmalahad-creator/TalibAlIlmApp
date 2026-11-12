import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/hifz_schedule_repository.dart';
import '../repositories/life_plan_repository.dart';
import '../repositories/medication_repository.dart';
import '../repositories/memorization_repository.dart';
import '../repositories/prayer_times_repository.dart';
import '../screens/hifz_schedule_screen.dart';
import '../screens/life_plan_screen.dart';
import '../screens/medications_screen.dart';
import '../screens/prayer_times_screen.dart';
import '../screens/review_screen.dart';
import '../services/language_preference_service.dart';
import '../services/location_service.dart';
import '../services/medication_schedule.dart';
import '../theme/app_theme.dart';

/// «اليوم» — one answer to "what now?", at the top of the side menu
/// (docs/PRODUCT_ANALYSIS_2026-11-12.md §4.2). At most five lines, each from
/// data the app already has, each opening its place; a line that doesn't
/// apply to this person (no medicines, no hifz plan, nothing due) is not
/// shown. Cheap reads only — it loads every time the menu opens.
class TodayCard extends StatefulWidget {
  /// Closes the menu and opens [screen].
  final void Function(WidgetBuilder screen) onOpen;
  const TodayCard({super.key, required this.onOpen});

  @override
  State<TodayCard> createState() => _TodayCardState();
}

class _TodayLine {
  final IconData icon;
  final String text;
  final String? trailing;
  final bool urgent;
  final WidgetBuilder open;
  const _TodayLine(this.icon, this.text, this.open, {this.trailing, this.urgent = false});
}

class _TodayCardState extends State<TodayCard> {
  List<_TodayLine>? _lines;

  @override
  void initState() {
    super.initState();
    _load();
  }

  static String _prayerKey(Prayer p) => switch (p) {
        Prayer.fajr || Prayer.fajrAfter => 'prayer_fajr',
        Prayer.sunrise => 'prayer_sunrise',
        Prayer.dhuhr => 'prayer_dhuhr',
        Prayer.asr => 'prayer_asr',
        Prayer.maghrib => 'prayer_maghrib',
        Prayer.isha || Prayer.ishaBefore => 'prayer_isha',
      };

  Future<void> _load() async {
    final lang = LanguagePreferenceService.currentLanguage;
    final now = DateTime.now();
    final lines = <_TodayLine>[];

    // Each source is independent and time-boxed: one failing or slow (a cold
    // GPS fix) must not hide or hold back the others.
    const limit = Duration(seconds: 3);
    try {
      final coords = await LocationService().currentLocation(mayAskPermission: false).timeout(limit);
      if (coords != null) {
        final t = await PrayerTimesRepository().prayerTimesFor(coords).timeout(limit);
        var next = t.nextPrayer();
        var at = t.timeForPrayer(next).toLocal();
        if (next == Prayer.sunrise) {
          next = Prayer.dhuhr; // sunrise is not a prayer to go to
          at = t.timeForPrayer(next).toLocal();
        }
        if (at.isAfter(now)) {
          lines.add(_TodayLine(Icons.access_time_rounded,
              '${basicText(_prayerKey(next), lang)} ${medTimeOf(at)}', (_) => const PrayerTimesScreen(),
              trailing: medCountdown(at, lang), urgent: at.difference(now).inMinutes <= 20));
        }
      }
    } catch (_) {}

    try {
      final dose = await MedicationRepository().nextDose(now).timeout(limit);
      if (dose != null) {
        final (course, d) = dose;
        if (d.scheduledAt.difference(now).inHours < 24) {
          lines.add(_TodayLine(Icons.medication_outlined, '${course.name} ${medTimeOf(d.scheduledAt)}', (_) => const MedicationsScreen(),
              trailing: medCountdown(d.scheduledAt, lang), urgent: d.isPending && d.scheduledAt.difference(now).inMinutes <= 15));
        }
      }
    } catch (_) {}

    try {
      final plan = await HifzScheduleRepository().choice().timeout(limit);
      if (plan != null && plan.dayNumber(now) >= 1) {
        lines.add(_TodayLine(Icons.auto_stories_outlined,
            basicText('today_hifz_day', lang).replaceAll('{n}', '${plan.dayNumber(now)}'), (_) => const HifzScheduleScreen()));
      }
    } catch (_) {}

    try {
      final due = await MemorizationRepository().dueToday().timeout(limit);
      if (due.isNotEmpty) {
        lines.add(_TodayLine(Icons.replay_rounded, basicText('today_reviews_due', lang).replaceAll('{n}', '${due.length}'), (_) => const ReviewScreen()));
      }
    } catch (_) {}

    try {
      final today = LifePlanRepository.today();
      final mits = await LifePlanRepository().mitFor(today).timeout(limit);
      final open = mits.where((m) => !m.done && m.text.trim().isNotEmpty).toList();
      if (open.isNotEmpty) {
        lines.add(_TodayLine(Icons.star_outline_rounded, open.first.text, (_) => const LifePlanScreen()));
      }
    } catch (_) {}

    if (mounted) setState(() => _lines = lines);
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final lines = _lines;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 4),
          child: Text(basicText('today_title', lang), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
        ),
        if (lines == null)
          const SizedBox(height: 28) // loading: the title is already there
        else if (lines.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 2, 12, 6),
            child: Text(basicText('today_nothing', lang), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          )
        else
          for (final l in lines)
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(l.icon, color: l.urgent ? Colors.deepOrange : AppColors.primaryDark, size: 20),
              title: Text(l.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, color: l.urgent ? Colors.deepOrange : null)),
              trailing: l.trailing == null ? null : Text(l.trailing!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              onTap: () => widget.onOpen(l.open),
            ),
      ]),
    );
  }
}
