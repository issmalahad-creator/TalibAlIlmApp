import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';

import '../repositories/prayer_times_repository.dart';
import '../repositories/wird_repository.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// "رفيقك اليوم" — QURAN_COMPANION_ROADMAP.md Phase 9's home-screen card,
/// redesigned 2026-08-16 into a richer gradient hero (Ismail's explicit
/// request for a livelier, less plain-white visual language, matching a
/// reference app's style — countdown, gradient, decorative silhouette —
/// without copying that app's actual artwork/branding, which stays an
/// original simple geometric dome-and-minarets shape drawn here). Next
/// prayer time + a live ticking countdown + today's Quran/adhkar status,
/// with a quick link to the full Qibla compass. Silently hides itself if
/// location isn't available yet — HomeScreen already has a full
/// prayer-times/Qibla flow reachable separately, this is a convenience
/// summary, not the only way in.
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
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_times == null || !mounted) return;
    final nextTime = _times!.timeForPrayer(_times!.nextPrayer());
    final diff = nextTime.toLocal().difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
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
    _tick();
  }

  /// `adhan_dart` builds prayer times as UTC `DateTime`s internally.
  String _formatTime(DateTime t) {
    final local = t.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  String _countdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.16,
                child: CustomPaint(size: const Size(double.infinity, 64), painter: _MosqueSilhouettePainter()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: widget.onOpenPrayerTimes,
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_prayerNameAr(next)} بعد', style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _countdown(_remaining),
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
                          ),
                          const SizedBox(width: 10),
                          Text('(${_formatTime(nextTime)})', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                            Icon(Icons.explore_outlined, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('القبلة', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        color: done ? Colors.white.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check_circle : icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// A plain original geometric silhouette (dome + two minarets, simple
/// arcs/rectangles) — not traced or copied from any reference app's
/// artwork, just a generic decorative motif for the hero card's footer.
class _MosqueSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final baseY = size.height;
    final centerX = size.width / 2;

    void minaret(double x) {
      canvas.drawRect(Rect.fromLTWH(x - 4, baseY - 46, 8, 46), paint);
      canvas.drawCircle(Offset(x, baseY - 50), 5, paint);
    }

    minaret(centerX - 90);
    minaret(centerX + 90);

    final domePath = Path()
      ..moveTo(centerX - 55, baseY)
      ..lineTo(centerX - 55, baseY - 20)
      ..quadraticBezierTo(centerX - 55, baseY - 55, centerX, baseY - 58)
      ..quadraticBezierTo(centerX + 55, baseY - 55, centerX + 55, baseY - 20)
      ..lineTo(centerX + 55, baseY)
      ..close();
    canvas.drawPath(domePath, paint);
    canvas.drawCircle(Offset(centerX, baseY - 62), 4, paint);

    canvas.drawRect(Rect.fromLTWH(0, baseY - 8, size.width, 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
