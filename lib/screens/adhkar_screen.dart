import 'package:flutter/material.dart';

import '../repositories/adhkar_repository.dart';
import '../theme/app_theme.dart';
import 'adhkar_category_screen.dart';

/// "حصن المسلم" — QURAN_COMPANION_ROADMAP.md Phase 5هـ. The ~17 routine
/// everyday-life chapters (waking up, wudu, mosque, morning/evening, sleep,
/// istighfar...) pinned at the top with today's completion + streak; the
/// rest of the book stays one tap away, browsable, below.
class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  final _repo = AdhkarRepository();
  List<AdhkarCategory> _all = [];
  Map<int, bool> _completedToday = {};
  Map<int, int> _streaks = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _repo.allCategories();
    final core = all.where((c) => c.isDailyCore).toList();
    final completed = <int, bool>{};
    final streaks = <int, int>{};
    for (final c in core) {
      completed[c.id] = await _repo.isCompletedToday(c.id);
      streaks[c.id] = await _repo.currentStreak(c.id);
    }
    if (!mounted) return;
    setState(() {
      _all = all;
      _completedToday = completed;
      _streaks = streaks;
      _loading = false;
    });
  }

  Future<void> _open(AdhkarCategory c) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AdhkarCategoryScreen(category: c)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final core = _all.where((c) => c.isDailyCore).toList();
    final rest = _all.where((c) => !c.isDailyCore).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('حصن المسلم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('أذكاري اليومية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...core.map((c) => _CoreCard(
                category: c,
                completedToday: _completedToday[c.id] ?? false,
                streak: _streaks[c.id] ?? 0,
                onTap: () => _open(c),
              )),
          const SizedBox(height: 24),
          const Text('كل أذكار حصن المسلم', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('باقي أبواب الكتاب — للسفر، الجنازة، الحج، وغيرها', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          ...rest.map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(c.title, style: const TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
                onTap: () => _open(c),
              )),
        ],
      ),
    );
  }
}

class _CoreCard extends StatelessWidget {
  final AdhkarCategory category;
  final bool completedToday;
  final int streak;
  final VoidCallback onTap;
  const _CoreCard({required this.category, required this.completedToday, required this.streak, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: completedToday ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: completedToday ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              completedToday ? Icons.check_circle : Icons.circle_outlined,
              color: completedToday ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(category.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
            if (streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('🔥 $streak', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              ),
          ],
        ),
      ),
    );
  }
}
