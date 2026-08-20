import 'package:flutter/material.dart';

import '../data/adhkar_journey.dart';
import '../repositories/adhkar_repository.dart';
import '../repositories/prayer_times_repository.dart';
import '../screens/adhkar_category_screen.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// "رحلتك اليومية" home-screen card — Ismail's 2026-08-16 request: instead
/// of the student searching "what should I read now," the app suggests it
/// directly based on time of day. Deliberately additive — doesn't touch
/// `DailyCompanionCard`'s existing "الأذكار" done/not-done chip, which
/// stays as-is.
///
/// 2026-08-17: now prefers real prayer times (`dayWindowFromPrayerTimes`,
/// same `adhan_dart` engine `DailyCompanionCard` already uses on this same
/// screen) over the fixed-clock-hour fallback — أذكار الصباح/المساء are
/// genuinely anchored to Fajr/Asr, which shift through the year, not to a
/// fixed "6am/4pm" guess. Falls back to the old clock-based
/// `journeySuggestionFor` silently when location isn't available, so this
/// never regresses a device without a location fix.
class DailyJourneyCard extends StatefulWidget {
  const DailyJourneyCard({super.key});

  @override
  State<DailyJourneyCard> createState() => _DailyJourneyCardState();
}

class _DailyJourneyCardState extends State<DailyJourneyCard> {
  final _repo = AdhkarRepository();
  final _locationService = LocationService();
  final _prayerRepo = PrayerTimesRepository();
  AdhkarCategory? _category;
  JourneySuggestion? _suggestion;
  int _minutes = 0;
  bool _done = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    var suggestion = journeySuggestionFor(now);
    final coords = await _locationService.currentLocation();
    if (coords != null) {
      try {
        final times = await _prayerRepo.prayerTimesFor(coords);
        suggestion = journeySuggestionFromPrayerTimes(now, times);
      } catch (_) {
        // keep the fixed-clock-hour fallback already computed above
      }
    }
    final categories = await _repo.allCategories();
    AdhkarCategory? match;
    for (final c in categories) {
      if (c.title == suggestion.categoryTitle) {
        match = c;
        break;
      }
    }
    final done = match == null ? false : await _repo.isCompletedToday(match.id);
    final minutes = match == null ? 0 : await _repo.estimatedMinutes(match.id);
    if (!mounted) return;
    setState(() {
      _category = match;
      _suggestion = suggestion;
      _minutes = minutes;
      _done = done;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    final suggestion = _suggestion;
    if (_loading || category == null || suggestion == null) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => AdhkarCategoryScreen(category: category)));
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _done ? AppColors.primaryLight : const Color(0xFFD9A441).withValues(alpha: 0.15)),
              child: Icon(suggestion.icon, color: _done ? AppColors.primary : const Color(0xFFB8860B), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('رحلتك اليومية', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(suggestion.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  if (!_done && _minutes > 0) ...[
                    const SizedBox(height: 2),
                    Text('⏱ ~$_minutes دقائق فقط', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            if (_done)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
