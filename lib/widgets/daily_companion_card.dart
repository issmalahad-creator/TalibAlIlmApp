import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';

import '../repositories/prayer_times_repository.dart';
import '../repositories/wird_repository.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// "رفيقك اليوم" — QURAN_COMPANION_ROADMAP.md Phase 9's originally-sketched
/// home-screen card: next prayer time + today's Quran/adhkar status
/// together in one glance, with a quick link to the full Qibla compass.
/// Silently hides itself if location isn't available yet — HomeScreen
/// already has a full prayer-times/Qibla flow reachable separately, this
/// is a convenience summary, not the only way in.
class DailyCompanionCard extends StatefulWidget {
  final VoidCallback onOpenPrayerTimes;
  final VoidCallback onOpenQibla;
  const DailyCompanionCard({super.key, required this.onOpenPrayerTimes, required this.onOpenQibla});

  @override
  State<DailyCompanionCard> createState() => _DailyCompanionCardState();
}

class _DailyCompanionCardState extends State<DailyCompanionCard> {
  final _locationService = LocationService();
  final _prayerRepo = PrayerTimesRepository();
  final _wirdRepo = WirdRepository();

  PrayerTimes? _times;
  bool _quranDone = false;
  bool _adhkarDone = false;
  bool _loading = true;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final coords = await _locationService.currentLocation();
    if (coords == null) {
      if (!mounted) return;
      setState(() {
        _available = false;
        _loading = false;
      });
      return;
    }
    final times = await _prayerRepo.prayerTimesFor(coords);
    final quranDone = await _wirdRepo.isQuranDoneToday();
    final adhkarDone = await _wirdRepo.isAdhkarDoneToday();
    if (!mounted) return;
    setState(() {
      _times = times;
      _quranDone = quranDone;
      _adhkarDone = adhkarDone;
      _available = true;
      _loading = false;
    });
  }

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  String _prayerNameAr(Prayer p) => switch (p) {
        Prayer.fajr => 'الفجر',
        Prayer.sunrise => 'الشروق',
        Prayer.dhuhr => 'الظهر',
        Prayer.asr => 'العصر',
        Prayer.maghrib => 'المغرب',
        Prayer.isha => 'العشاء',
        _ => 'الصلاة القادمة',
      };

  @override
  Widget build(BuildContext context) {
    if (_loading || !_available) return const SizedBox.shrink();

    final t = _times!;
    final next = t.nextPrayer();
    final nextTime = t.timeForPrayer(next);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('رفيقك اليوم', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          const SizedBox(height: 10),
          InkWell(
            onTap: widget.onOpenPrayerTimes,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                const Icon(Icons.access_time_outlined, size: 18, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Text('${_prayerNameAr(next)} القادمة', style: const TextStyle(fontSize: 13, color: AppColors.primaryDark)),
                const Spacer(),
                Text(_formatTime(nextTime), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusChip(icon: Icons.menu_book_outlined, label: 'القرآن', done: _quranDone),
              const SizedBox(width: 8),
              _StatusChip(icon: Icons.nights_stay_outlined, label: 'الأذكار', done: _adhkarDone),
              const Spacer(),
              InkWell(
                onTap: widget.onOpenQibla,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.explore_outlined, size: 16, color: AppColors.primaryDark),
                      SizedBox(width: 4),
                      Text('القبلة', style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  const _StatusChip({required this.icon, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: done ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check_circle : icon, size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
