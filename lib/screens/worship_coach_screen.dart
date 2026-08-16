import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../repositories/memorization_repository.dart';
import '../repositories/worship_coach_repository.dart';
import '../theme/app_theme.dart';
import 'adhkar_screen.dart';
import 'quran_browse_screen.dart';
import 'review_screen.dart';
import 'salah_tracker_screen.dart';

/// "مدرب العبادة" — Ismail's request 2026-08-16: a rule-based (no AI)
/// coaching engine across Salah/Quran/Dhikr. This screen is the detail
/// view behind `WorshipCoachCard` — shows the one current stage, the one
/// recommended task with a direct button into the relevant screen, and an
/// honest breakdown of the 3 consistency numbers driving the
/// recommendation (transparency instead of an opaque "AI suggests..."),
/// per his explicit "no AI, plain rules" instruction.
class WorshipCoachScreen extends StatefulWidget {
  const WorshipCoachScreen({super.key});

  @override
  State<WorshipCoachScreen> createState() => _WorshipCoachScreenState();
}

class _WorshipCoachScreenState extends State<WorshipCoachScreen> {
  final _repo = WorshipCoachRepository();
  final _memoRepo = MemorizationRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};
  WorshipCoachStatus? _status;
  int _manzilPortion = 0;
  List<(MemorizationUnit unit, int mistakeCount)> _weakSpots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _repo.status();
    final manzilPortion = await _memoRepo.manzilDailyPortionSize();
    final weakSpots = await _memoRepo.recurringWeakSpots();
    if (!mounted) return;
    setState(() {
      _status = status;
      _manzilPortion = manzilPortion;
      _weakSpots = weakSpots;
    });
  }

  void _openTaskScreen() {
    final status = _status;
    if (status == null) return;
    Widget? screen;
    switch (status.taskArea) {
      case CoachFocusArea.prayer:
        screen = const SalahTrackerScreen();
        break;
      case CoachFocusArea.quran:
        screen = status.quranTaskIsReview ? const ReviewScreen() : const QuranBrowseScreen();
        break;
      case CoachFocusArea.dhikr:
        screen = const AdhkarScreen();
        break;
      case CoachFocusArea.stable:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!)).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('مدرب العبادة')),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status.stageLabel, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(status.taskLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      if (status.taskArea != CoachFocusArea.stable) ...[
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _openTaskScreen,
                          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
                          child: const Text('ابدأ الآن'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('كيف نحدد مهمتك؟', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'قاعدة بسيطة وواضحة، بلا ذكاء اصطناعي: نحسب مدى انتظامك في آخر 7 أيام لكل مجال، ونركّز على أول مجال أقل من 70% — الصلاة أولًا، ثم القرآن، ثم الأذكار. إن كانت الثلاثة مستقرة، نقترح المرحلة التالية بدل إزعاجك بما هو متقن أصلًا.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.6),
                ),
                const SizedBox(height: 16),
                _ConsistencyRow(label: 'الصلاة', value: status.prayerConsistency, isFocus: status.focus == CoachFocusArea.prayer),
                const SizedBox(height: 10),
                _ConsistencyRow(label: 'القرآن', value: status.quranConsistency, isFocus: status.focus == CoachFocusArea.quran),
                const SizedBox(height: 10),
                _ConsistencyRow(label: 'الأذكار', value: status.dhikrConsistency, isFocus: status.focus == CoachFocusArea.dhikr),
                if (_manzilPortion > 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                    child: Row(
                      children: [
                        const Icon(Icons.replay_circle_filled_outlined, color: AppColors.primaryDark, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('منزل — حصتك الأسبوعية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(
                                'لتغطية كل محفوظك الراسخ مرة كل أسبوع، راجع نحو $_manzilPortion صفحة يوميًا',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_weakSpots.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('نقاط تحتاج تركيزًا إضافيًا', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('الصفحات التي تكرر فيها "يحتاج مراجعة" مؤخرًا — آخر 30 يومًا', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  ..._weakSpots.map((w) {
                    final (unit, mistakeCount) = w;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'صفحة ${unit.id} — من سورة ${_surahNames[unit.surahStart] ?? unit.surahStart}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text('$mistakeCount مرات', style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أعمال إضافية — قريبًا', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text(
                        'قيام الليل والوتر والصدقة وصيام التطوع لم تُضَف بعد لأنها تحتاج تتبعًا جديدًا لم يُبنَ في التطبيق حتى الآن — ستُضاف تدريجيًا بعد استقرار الصلاة والقرآن والأذكار، بنفس مبدأ عدم البدء بكل شيء دفعة واحدة.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ConsistencyRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isFocus;
  const _ConsistencyRow({required this.label, required this.value, required this.isFocus});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    final color = isFocus ? const Color(0xFFB8860B) : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: isFocus ? color : AppColors.divider, width: isFocus ? 1.5 : 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  if (isFocus) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('التركيز الآن', style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
              Text('$percent%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 8, backgroundColor: AppColors.divider, valueColor: AlwaysStoppedAnimation(color)),
          ),
          const SizedBox(height: 4),
          const Text('آخر 7 أيام', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
