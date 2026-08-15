import 'package:flutter/material.dart';

import '../repositories/adhkar_repository.dart';
import '../repositories/milestone_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';

/// The book's title for the merged morning+evening chapter — only this
/// category's completions count toward the streak certificates (see
/// `MilestoneRepository.checkAdhkarMilestones`'s doc comment for why it's
/// one combined habit rather than two separate morning/evening ones).
const _streakTrackedCategoryTitle = 'أذكار الصباح والمساء';

/// Tap-to-count-down UI for one adhkar category — QURAN_COMPANION_ROADMAP.md
/// Phase 5هـ. Each dhikr starts at its book-specified repeat count; tapping
/// it decrements. Once every item in the category hits zero, the category
/// is marked done for today (powers the streak on `AdhkarScreen`).
class AdhkarCategoryScreen extends StatefulWidget {
  final AdhkarCategory category;
  const AdhkarCategoryScreen({super.key, required this.category});

  @override
  State<AdhkarCategoryScreen> createState() => _AdhkarCategoryScreenState();
}

class _AdhkarCategoryScreenState extends State<AdhkarCategoryScreen> {
  final _repo = AdhkarRepository();
  final _milestoneRepo = MilestoneRepository();
  List<AdhkarItem> _items = [];
  Map<int, int> _remaining = {};
  bool _loading = true;
  bool _alreadyDoneToday = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.itemsFor(widget.category.id);
    final doneToday = await _repo.isCompletedToday(widget.category.id);
    if (!mounted) return;
    setState(() {
      _items = items;
      _alreadyDoneToday = doneToday;
      _remaining = {for (final i in items) i.id: doneToday ? 0 : i.repeatCount};
      _loading = false;
    });
  }

  Future<void> _tap(AdhkarItem item) async {
    final current = _remaining[item.id] ?? 0;
    if (current <= 0) return;
    setState(() => _remaining[item.id] = current - 1);
    if (!_remaining.values.every((v) => v <= 0)) return;

    await _repo.markCompletedToday(widget.category.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('أحسنت — أتممت هذا الذكر 🌿')),
    );

    if (widget.category.title != _streakTrackedCategoryTitle) return;
    final streak = await _repo.currentStreak(widget.category.id);
    final newlyEarned = await _milestoneRepo.checkAdhkarMilestones(streak);
    for (final milestone in newlyEarned) {
      if (!mounted) return;
      await showCelebration(context, milestone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_alreadyDoneToday)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: const Text('أتممت هذا الذكر اليوم بالفعل — يمكنك مراجعته فقط', style: TextStyle(fontSize: 12, color: AppColors.primaryDark)),
                  ),
                ..._items.map((item) => _AdhkarItemCard(
                      item: item,
                      remaining: _remaining[item.id] ?? 0,
                      onTap: () => _tap(item),
                    )),
              ],
            ),
    );
  }
}

class _AdhkarItemCard extends StatelessWidget {
  final AdhkarItem item;
  final int remaining;
  final VoidCallback onTap;
  const _AdhkarItemCard({required this.item, required this.remaining, required this.onTap});

  bool get _done => remaining <= 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _done ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _done ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, height: 1.9)),
                  if (item.footnote != null) ...[
                    const SizedBox(height: 8),
                    Text(item.footnote!, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: _done ? AppColors.primary : AppColors.primaryLight,
              child: _done
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text('$remaining', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
            ),
          ],
        ),
      ),
    );
  }
}
