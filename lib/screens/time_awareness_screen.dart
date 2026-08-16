import 'package:flutter/material.dart';

import '../data/time_awareness_content.dart';
import '../repositories/time_awareness_repository.dart';
import '../theme/app_theme.dart';

/// "محاسبة الوقت" — Ismail's request 2026-08-16: how many hours are in a
/// year, how to benefit from each one, how many hours were used well
/// today, and the real reminder that every hour is asked about on the Day
/// of Judgment. The daily reflection is entirely self-reported — the app
/// never measures or infers how anyone's time was actually spent, same
/// principle as khushu self-rating and guided-session difficulty rating
/// elsewhere in this app. The hadith is presented as what it honestly is:
/// a real, well-attributed reminder to reflect on, not the app judging.
class TimeAwarenessScreen extends StatefulWidget {
  const TimeAwarenessScreen({super.key});

  @override
  State<TimeAwarenessScreen> createState() => _TimeAwarenessScreenState();
}

class _TimeAwarenessScreenState extends State<TimeAwarenessScreen> {
  final _repo = TimeAwarenessRepository();
  final _noteCtrl = TextEditingController();
  double _hoursWellSpent = 12;
  bool _loading = true;
  List<(String, double?)> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entry = await _repo.todayEntry();
    final recent = await _repo.recentEntries();
    if (!mounted) return;
    setState(() {
      _hoursWellSpent = entry.hoursWellSpent ?? 12;
      _noteCtrl.text = entry.note ?? '';
      _recent = recent;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _repo.saveToday(_hoursWellSpent, _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ — بينك وبين الله')));
  }

  @override
  Widget build(BuildContext context) {
    final daysElapsed = _repo.daysElapsedThisHijriYear();
    final hoursElapsed = daysElapsed * 24;
    final hoursRemaining = TimeAwarenessRepository.hoursPerYear - hoursElapsed;
    final hoursNotAccounted = (24 - _hoursWellSpent).clamp(0, 24);

    return Scaffold(
      appBar: AppBar(title: const Text('محاسبة الوقت')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ساعات سنتك الهجرية', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${TimeAwarenessRepository.hoursPerYear}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('مضى منها تقريبًا $hoursElapsed ساعة — وبقي $hoursRemaining ساعة', style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(timeAccountabilityHadith, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.9, color: AppColors.textDark)),
                      const SizedBox(height: 10),
                      Text(timeAccountabilityHadithSource, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('يومك اليوم', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('بصدق مع نفسك — كم ساعة تقريبًا استفدت منها اليوم فيما ينفعك؟ هذا لك أنت، لا أحد سيحاسبك عليه هنا سوى نفسك.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Slider(
                  value: _hoursWellSpent,
                  min: 0,
                  max: 24,
                  divisions: 24,
                  label: '${_hoursWellSpent.toStringAsFixed(0)} ساعة',
                  onChanged: (v) => setState(() => _hoursWellSpent = v),
                ),
                Text('${_hoursWellSpent.toStringAsFixed(0)} ساعة استفدت منها — ${hoursNotAccounted.toStringAsFixed(0)} ساعة لم تُستثمر بعد', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'ملاحظة (اختياري): بم استفدت؟ وأين ضاع وقتك؟', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: _save, child: const Text('حفظ'))),
                const SizedBox(height: 24),
                const Text('كيف تستفيد من كل ساعة؟', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ...timeAwarenessTips.map((t) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.titleAr, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(t.bodyAr, style: const TextStyle(fontSize: 12.5, height: 1.6, color: AppColors.textMuted)),
                        ],
                      ),
                    )),
                if (_recent.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('آخر أيامك', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._recent.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.$1, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text('${e.$2?.toStringAsFixed(0) ?? '-'} ساعة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
    );
  }
}
