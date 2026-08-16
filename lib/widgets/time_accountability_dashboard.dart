import 'package:flutter/material.dart';

import '../repositories/time_awareness_repository.dart';
import '../theme/app_theme.dart';

/// "محاسبة الوقت" home-screen dashboard (Ismail's request 2026-08-16: put
/// it on the home screen itself, with a year/month/week/day card each
/// showing a countdown). Pure display + navigation — all the real
/// arithmetic (benefit/waste per period) lives in `TimeAwarenessRepository`.
class TimeAccountabilityDashboard extends StatefulWidget {
  final VoidCallback onTap;
  const TimeAccountabilityDashboard({super.key, required this.onTap});

  @override
  State<TimeAccountabilityDashboard> createState() => _TimeAccountabilityDashboardState();
}

class _TimeAccountabilityDashboardState extends State<TimeAccountabilityDashboard> {
  final _repo = TimeAwarenessRepository();
  bool _loading = true;
  late TimePeriodTotals _day;
  late TimePeriodTotals _week;
  late TimePeriodTotals _month;
  late TimePeriodTotals _year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = await _repo.todayEntry();
    final day = TimePeriodTotals(today.benefitedHours, today.wastedHours);
    final week = await _repo.weekTotals();
    final month = await _repo.monthTotals();
    final year = await _repo.yearTotals();
    if (!mounted) return;
    setState(() {
      _day = day;
      _week = week;
      _month = month;
      _year = year;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        widget.onTap();
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hourglass_bottom_rounded, size: 18, color: AppColors.primaryDark),
                const SizedBox(width: 6),
                const Text('محاسبة الوقت', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const Spacer(),
                const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _PeriodTile(label: 'اليوم', countdown: '${_repo.hoursRemainingToday()} س', totals: _day)),
                const SizedBox(width: 8),
                Expanded(child: _PeriodTile(label: 'الأسبوع', countdown: '${_repo.daysRemainingThisWeek()} ي', totals: _week)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _PeriodTile(label: 'الشهر', countdown: '${_repo.daysRemainingThisMonth()} ي', totals: _month)),
                const SizedBox(width: 8),
                Expanded(child: _PeriodTile(label: 'السنة', countdown: '${_repo.daysRemainingThisYear()} ي', totals: _year)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  final String label;
  final String countdown;
  final TimePeriodTotals totals;
  const _PeriodTile({required this.label, required this.countdown, required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              Text('باقي $countdown', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          if (totals.benefitedHours == 0 && totals.wastedHours == 0)
            const Text('لم تُسجَّل بعد', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))
          else
            Row(
              children: [
                const Icon(Icons.trending_up_rounded, size: 13, color: AppColors.primary),
                Text(' ${totals.benefitedHours.toStringAsFixed(0)}س', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                const SizedBox(width: 8),
                const Icon(Icons.trending_down_rounded, size: 13, color: Colors.redAccent),
                Text(' ${totals.wastedHours.toStringAsFixed(0)}س', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.redAccent)),
              ],
            ),
        ],
      ),
    );
  }
}
