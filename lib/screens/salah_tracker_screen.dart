import 'package:flutter/material.dart';

import '../data/salah_content.dart';
import '../repositories/salah_repository.dart';
import '../theme/app_theme.dart';
import 'salah_assessment_screen.dart';
import 'salah_library_screen.dart';
import 'salah_stories_screen.dart';
import 'salah_resources_screen.dart';
import '../widgets/loading_view.dart';

const _prayerLabels = {
  'fajr': 'الفجر',
  'dhuhr': 'الظهر',
  'asr': 'العصر',
  'maghrib': 'المغرب',
  'isha': 'العشاء',
};

const _statusLabels = {
  PrayerStatus.onTime: ('صليتها في وقتها', Icons.check_circle_outline),
  PrayerStatus.jamaah: ('صليتها جماعة', Icons.groups_outlined),
  PrayerStatus.late: ('صليتها متأخرًا', Icons.schedule_outlined),
  PrayerStatus.missed: ('لم أصلها', Icons.remove_circle_outline),
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
    final chosen = await showModalBottomSheet<PrayerStatus>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${_prayerLabels[prayer]} — هل صليت؟', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            for (final status in PrayerStatus.values)
              ListTile(
                leading: Icon(_statusLabels[status]!.$2, color: AppColors.primaryDark),
                title: Text(_statusLabels[status]!.$1),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('إقامة الصلاة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'تقييمي الأسبوعي',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahAssessmentScreen())),
          ),
        ],
      ),
      body: _loading
          ? const AppLoadingView(icon: Icons.mosque_outlined, message: 'جاري تحميل سجل صلاتك...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TodaysMissionCard(onOpenLibrary: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahLibraryScreen()))),
                const SizedBox(height: 16),
                const Text('صلواتي اليوم', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('سجّل بصدق — هذا لك أنت، لا حكم عليك من أحد', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 14),
                ..._prayerLabels.entries.map((entry) {
                  final status = _statuses[entry.key];
                  final labelInfo = status == null ? null : _statusLabels[status];
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
                          Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
                          Text(labelInfo?.$1 ?? 'لم يُسجَّل بعد', style: TextStyle(fontSize: 12, color: status != null ? AppColors.primaryDark : AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahLibraryScreen())),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('مكتبة إقامة الصلاة'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahStoriesScreen())),
                  icon: const Icon(Icons.auto_stories_outlined),
                  label: const Text('قصص الأولين في الصلاة'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahResourcesScreen())),
                  icon: const Icon(Icons.library_books_outlined),
                  label: const Text('مصادر موصى بها'),
                ),
              ],
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.today_outlined, size: 16, color: AppColors.primaryDark),
              SizedBox(width: 6),
              Text('مهمة اليوم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text(lesson.titleAr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(lesson.bodyAr, style: const TextStyle(fontSize: 12.5, height: 1.7)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onOpenLibrary, child: const Text('عرض المكتبة كاملة', style: TextStyle(fontSize: 12))),
          ),
        ],
      ),
    );
  }
}
