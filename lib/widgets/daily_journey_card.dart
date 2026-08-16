import 'package:flutter/material.dart';

import '../data/adhkar_journey.dart';
import '../repositories/adhkar_repository.dart';
import '../screens/adhkar_category_screen.dart';
import '../theme/app_theme.dart';

/// "رحلتك اليومية" home-screen card — Ismail's 2026-08-16 request: instead
/// of the student searching "what should I read now," the app suggests it
/// directly based on time of day (`dayWindowFor`). Deliberately additive —
/// doesn't touch `DailyCompanionCard`'s existing "الأذكار" done/not-done
/// chip, which stays as-is.
class DailyJourneyCard extends StatefulWidget {
  const DailyJourneyCard({super.key});

  @override
  State<DailyJourneyCard> createState() => _DailyJourneyCardState();
}

class _DailyJourneyCardState extends State<DailyJourneyCard> {
  final _repo = AdhkarRepository();
  AdhkarCategory? _category;
  bool _done = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final suggestion = journeySuggestionFor(DateTime.now());
    final categories = await _repo.allCategories();
    AdhkarCategory? match;
    for (final c in categories) {
      if (c.title == suggestion.categoryTitle) {
        match = c;
        break;
      }
    }
    final done = match == null ? false : await _repo.isCompletedToday(match.id);
    if (!mounted) return;
    setState(() {
      _category = match;
      _done = done;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    if (_loading || category == null) return const SizedBox.shrink();
    final suggestion = journeySuggestionFor(DateTime.now());

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => AdhkarCategoryScreen(category: category)));
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _done ? AppColors.primaryLight : const Color(0xFFD9A441).withValues(alpha: 0.15)),
              child: Icon(suggestion.icon, color: _done ? AppColors.primary : const Color(0xFFB8860B), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('رحلتك اليومية', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(suggestion.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (_done)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
