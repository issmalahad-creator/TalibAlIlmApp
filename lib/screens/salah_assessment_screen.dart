import 'package:flutter/material.dart';

import '../repositories/salah_repository.dart';
import '../theme/app_theme.dart';

const _dimensionLabels = {
  'muhafazah': 'المحافظة على الصلوات',
  'onTime': 'الصلاة في الوقت',
  'jamaah': 'الجماعة',
  'khushu': 'الخشوع',
  'rawatib': 'السنن الرواتب',
  'adhkar': 'أذكار الصلاة',
  'understanding': 'فهم ما تقرأ',
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
    if (!mounted) return;
    setState(() {
      _ratings = ratings;
      _weeklyCount = count;
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
    return Scaffold(
      appBar: AppBar(title: const Text('تقييمي الأسبوعي')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: Text('صليت $completed من $total صلاة هذا الأسبوع (في وقتها أو جماعة)', style: const TextStyle(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                const Text('قيّم نفسك بصدق — لا أحد سيراها سواك', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                ..._dimensionLabels.entries.map((entry) {
                  final rating = _ratings[entry.key] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
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
    );
  }
}
