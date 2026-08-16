import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../repositories/hifz_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/hijri_date.dart';
import '../utils/month.dart';
import '../widgets/loading_view.dart';

/// "حفظ القرآن" — deliberately simple, for a self-studying memorizer, not a
/// Hifz-academy management system: mark which Surahs you've memorized, see
/// your percentage toward 100%, and check in daily to build a streak and
/// keep the reminder from firing. No plans, no spaced-repetition scheduler,
/// no teacher dashboard, no audio — Ismail explicitly asked to keep this
/// simple ("بدون تعقيد").
class HifzScreen extends StatefulWidget {
  const HifzScreen({super.key});

  @override
  State<HifzScreen> createState() => _HifzScreenState();
}

class _HifzScreenState extends State<HifzScreen> {
  final _repo = HifzRepository();
  final _notificationService = NotificationService();
  final _searchController = TextEditingController();

  Set<int> _memorized = {};
  List<String> _checkInDates = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final memorized = await _repo.memorizedSurahNumbers();
    final dates = await _repo.allCheckInDates();
    if (!mounted) return;
    setState(() {
      _memorized = memorized;
      _checkInDates = dates;
      _loading = false;
    });
  }

  int get _streak {
    if (_checkInDates.isEmpty) return 0;
    // Hijri date strings ("1447-01-15") sort lexicographically the same as
    // chronologically since every part is zero-padded — safe to compare as
    // plain strings without parsing.
    var streak = 0;
    var expected = todayDate();
    final set = _checkInDates.toSet();
    // If today isn't checked in yet, the streak still counts up through
    // yesterday (so it doesn't reset to 0 the moment a new day starts).
    if (!set.contains(expected)) {
      expected = _dayBefore(expected);
    }
    while (set.contains(expected)) {
      streak++;
      expected = _dayBefore(expected);
    }
    return streak;
  }

  String _dayBefore(String hijriDate) {
    final dt = gregorianFromHijriDateTime(hijriDate, null).subtract(const Duration(days: 1));
    return hijriDateStringForDate(dt);
  }

  double get _percent => quranSurahs.isEmpty ? 0 : _memorized.length / quranSurahs.length;

  String get _motivation {
    final p = _percent;
    if (p == 0) return 'كل حافظ للقرآن بدأ من هنا — ابدأ اليوم! 🌱';
    if (p < 0.25) return 'خطوات ثابتة تصنع الفرق — استمر! 💪';
    if (p < 0.5) return 'أنت في الطريق الصحيح، لا تتوقف!';
    if (p < 0.75) return 'أكثر من النصف! بارك الله فيك، واصل.';
    if (p < 1.0) return 'اقتربت من ختم الحفظ الكامل — لا تستسلم الآن!';
    return 'الحمد لله — أتممت حفظ القرآن كاملاً! 🎉';
  }

  Future<void> _checkIn() async {
    final today = todayDate();
    await _repo.checkIn(today);
    await _notificationService.scheduleHifzReminder();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بارك الله فيك — تم تسجيل اليوم')));
  }

  Future<void> _toggleSurah(QuranSurah surah) async {
    final nowMemorized = !_memorized.contains(surah.number);
    setState(() {
      if (nowMemorized) {
        _memorized = {..._memorized, surah.number};
      } else {
        _memorized = {..._memorized}..remove(surah.number);
      }
    });
    await _repo.setMemorized(surah.number, nowMemorized, todayDate());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('حفظ القرآن')), body: const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...'));
    }
    final checkedInToday = _checkInDates.contains(todayDate());
    final percentValue = (_percent * 100).round();
    final visibleSurahs =
        _search.trim().isEmpty ? quranSurahs : quranSurahs.where((s) => s.name.contains(_search.trim())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('حفظ القرآن')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 84,
                        height: 84,
                        child: CircularProgressIndicator(
                          value: _percent,
                          strokeWidth: 8,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      Text('$percentValue%',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_memorized.length} من ${quranSurahs.length} سورة',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.deepOrange),
                          const SizedBox(width: 4),
                          Text('$_streak يوم متتالي', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_motivation, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: checkedInToday ? null : _checkIn,
              icon: Icon(checkedInToday ? Icons.check_circle_rounded : Icons.check_rounded),
              label: Text(checkedInToday ? 'تم تسجيل اليوم ✓' : 'سجّلت اليوم — حفظت أو راجعت'),
            ),
          ),
          const SizedBox(height: 24),
          Text('السور (اضغط لتعليم ما حفظته)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'ابحث عن سورة...',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          ...visibleSurahs.map((s) {
            final done = _memorized.contains(s.number);
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: CheckboxListTile(
                value: done,
                onChanged: (_) => _toggleSurah(s),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('${s.number}. ${s.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${s.ayahCount} آية', style: const TextStyle(fontSize: 11)),
              ),
            );
          }),
        ],
      ),
    );
  }
}
