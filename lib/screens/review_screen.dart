import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../db/database_helper.dart';
import '../models/personal_accountability.dart';
import '../repositories/memorization_repository.dart';
import '../repositories/milestone_repository.dart';
import '../repositories/personal_accountability_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/loading_view.dart';

const _hifzCategoryLabels = {
  HifzCategory.sabaq: ('سبق', AppColors.primaryDark),
  HifzCategory.sabqi: ('سبقي', AppColors.primary),
  HifzCategory.manzil: ('منزل', Color(0xFFB8860B)),
  HifzCategory.notStarted: ('', AppColors.textMuted),
};

/// "المراجعة" — Phase 2 of QURAN_COMPANION_ROADMAP.md. Today's due reviews,
/// one page at a time, rated ممتاز/جيد/يحتاج مراجعة against the 6-station
/// algorithm in `MemorizationRepository`. Each page is also labeled with
/// its real سبق/سبقي/منزل category (`MemorizationUnit.hifzCategory`,
/// QURAN_COMPANION_ROADMAP.md §4.31) so the student sees WHY they're
/// reviewing what they're reviewing — a real hifz-teacher's structure,
/// not an abstract "station number."
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _repo = MemorizationRepository();
  final _accountabilityRepo = PersonalAccountabilityRepository();
  final _milestoneRepo = MilestoneRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  List<MemorizationUnit> _queue = [];
  String? _startAyahPreview;
  bool _loading = true;
  bool _rating = false;
  int _completedToday = 0;
  PersonalAccountability? _accountability;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final due = await _repo.dueToday();
    final accountability = await _accountabilityRepo.get();
    if (!mounted) return;
    setState(() {
      _queue = due;
      _accountability = accountability;
      _loading = false;
    });
    await _loadPreviewForCurrent();
  }

  Future<void> _loadPreviewForCurrent() async {
    if (_queue.isEmpty) {
      setState(() => _startAyahPreview = null);
      return;
    }
    final unit = _queue.first;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'quran_ayat',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [unit.surahStart, unit.ayahStart],
      limit: 1,
    );
    if (!mounted) return;
    setState(() => _startAyahPreview = rows.isEmpty ? null : rows.first['text_uthmani'] as String);
  }

  Future<void> _rate(ReviewQuality quality) async {
    if (_queue.isEmpty || _rating) return;
    setState(() => _rating = true);

    String? note;
    if (quality == ReviewQuality.needsReview) {
      note = await _askForNote();
    }

    await _repo.recordReview(_queue.first.id, quality, note: note);
    if (!mounted) return;
    setState(() {
      _queue = _queue.skip(1).toList();
      _completedToday++;
      _rating = false;
    });
    await _loadPreviewForCurrent();

    // Only 'excellent' can advance a page past station 6 -> checking every
    // time would be wasted work for the other two ratings.
    if (quality == ReviewQuality.excellent) {
      final newlyEarned = await _milestoneRepo.checkQuranMilestones();
      for (final milestone in newlyEarned) {
        if (!mounted) return;
        await showCelebration(context, milestone);
      }
    }
  }

  Future<String?> _askForNote() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أي خطأ بالذات؟ (اختياري)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'مثلًا: تعثرت بآية ٥'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('تسجيل')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المراجعة')),
      body: _loading ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...') : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_queue.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                _completedToday > 0 ? 'أحسنت — أنجزت كل مراجعات اليوم' : 'لا توجد مراجعات مستحقة اليوم',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              if (_completedToday > 0 && (_accountability?.rewardEnabled ?? false) && _accountability!.rewardText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    'قلت لنفسك: "${_accountability!.rewardText}" — اذهب ونفّذها 🎉',
                    style: const TextStyle(fontSize: 13, color: AppColors.primaryDark),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final unit = _queue.first;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('باقي ${_queue.length}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('صفحة ${unit.id}', style: const TextStyle(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                      if (unit.hifzCategory() != HifzCategory.notStarted) ...[
                        const SizedBox(width: 8),
                        Builder(builder: (context) {
                          final (label, color) = _hifzCategoryLabels[unit.hifzCategory()]!;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800)),
                          );
                        }),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'من سورة ${_surahNames[unit.surahStart] ?? unit.surahStart} آية ${unit.ayahStart} '
                    'إلى سورة ${_surahNames[unit.surahEnd] ?? unit.surahEnd} آية ${unit.ayahEnd}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  if (_startAyahPreview != null) ...[
                    const SizedBox(height: 16),
                    Text(_startAyahPreview!, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 21, height: 2.0)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('قيّم مراجعتك:', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _RateButton(label: 'يحتاج مراجعة', color: AppColors.textMuted, onTap: _rating ? null : () => _rate(ReviewQuality.needsReview))),
              const SizedBox(width: 8),
              Expanded(child: _RateButton(label: 'جيد', color: AppColors.primary, onTap: _rating ? null : () => _rate(ReviewQuality.good))),
              const SizedBox(width: 8),
              Expanded(child: _RateButton(label: 'ممتاز', color: AppColors.primaryDark, onTap: _rating ? null : () => _rate(ReviewQuality.excellent))),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _RateButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14)),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
