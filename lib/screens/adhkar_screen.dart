import 'package:flutter/material.dart';

import '../repositories/adhkar_repository.dart';
import '../theme/app_theme.dart';
import 'adhkar_category_screen.dart';
import '../widgets/loading_view.dart';

const _occasionLabels = {
  'travel': ('السفر', Icons.luggage_outlined),
  'funeral': ('الجنازة والمرض', Icons.local_florist_outlined),
  'hajj': ('الحج والعمرة', Icons.mosque_outlined),
  'food': ('الطعام والصيام', Icons.restaurant_outlined),
};

/// Per-category icon for the أذكارك/أدعية/أخرى rows — Ismail's 2026-08-16
/// request after sharing a reference app's dhikr list, where every row has
/// its own meaningful icon instead of a bare chevron. Keyword-matched
/// against the real Hisn al-Muslim titles rather than a 134-entry exact-title
/// map (fragile, and this is presentation-only — no data correctness rides
/// on it) — falls back to a sensible icon per `content_type` when nothing
/// matches.
const _categoryKeywordIcons = <String, IconData>{
  'النوم': Icons.bedtime_outlined,
  'اليقظة': Icons.bedtime_outlined,
  'الاستيقاظ': Icons.wb_twilight_outlined,
  'الصباح': Icons.wb_sunny_outlined,
  'المساء': Icons.nightlight_round,
  'البيت': Icons.home_outlined,
  'المنزل': Icons.home_outlined,
  'الطهارة': Icons.water_drop_outlined,
  'الوضوء': Icons.water_drop_outlined,
  'المسجد': Icons.mosque_outlined,
  'الأذان': Icons.campaign_outlined,
  'الصلاة': Icons.mosque_outlined,
  'الطعام': Icons.restaurant_outlined,
  'الأكل': Icons.restaurant_outlined,
  'الشرب': Icons.local_cafe_outlined,
  'السفر': Icons.luggage_outlined,
  'المريض': Icons.healing_outlined,
  'الجنازة': Icons.local_florist_outlined,
  'الميت': Icons.local_florist_outlined,
  'الحج': Icons.mosque_outlined,
  'العمرة': Icons.mosque_outlined,
  'المطر': Icons.water_outlined,
  'الريح': Icons.air_outlined,
  'السوق': Icons.storefront_outlined,
  'الركوب': Icons.directions_car_outlined,
  'اللباس': Icons.checkroom_outlined,
  'الرؤيا': Icons.nights_stay_outlined,
  'الغضب': Icons.mood_bad_outlined,
  'الدَّين': Icons.payments_outlined,
  'القرآن': Icons.menu_book_outlined,
  'الهم': Icons.sentiment_neutral_outlined,
  'الحزن': Icons.sentiment_neutral_outlined,
  'الاستخارة': Icons.explore_outlined,
};

IconData _iconForCategory(AdhkarCategory c) {
  for (final entry in _categoryKeywordIcons.entries) {
    if (c.title.contains(entry.key)) return entry.value;
  }
  switch (c.contentType) {
    case 'dua':
      return Icons.front_hand_outlined;
    case 'other':
      return Icons.info_outline;
    default:
      return Icons.spa_outlined;
  }
}

/// "حصن المسلم" — QURAN_COMPANION_ROADMAP.md Phase 5هـ, sectioned
/// 2026-08-16 per Ismail's content-taxonomy request (after he critiqued an
/// external ontology proposal and asked for the scoped-down real version —
/// see `database_helper.dart`'s `_createV34Tables` doc comment). Instead of
/// a binary "أذكاري اليومية / كل الكتاب" split, the ~117 non-core
/// categories are now grouped by what they actually are — this is exactly
/// the "عبادتك اليوم / أذكارك / أدعية / مناسبات" structure Ismail sketched
/// himself, built on the `content_type`/`occasion` columns added this same
/// session rather than a fixed hand-maintained list.
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
  Map<int, int> _minutes = {};
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
    final minutes = <int, int>{};
    for (final c in core) {
      completed[c.id] = await _repo.isCompletedToday(c.id);
      streaks[c.id] = await _repo.currentStreak(c.id);
      minutes[c.id] = await _repo.estimatedMinutes(c.id);
    }
    if (!mounted) return;
    setState(() {
      _all = all;
      _completedToday = completed;
      _streaks = streaks;
      _minutes = minutes;
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
      return const Scaffold(body: AppLoadingView(icon: Icons.spa_outlined, message: 'جاري تحميل الأذكار...'));
    }
    final core = _all.where((c) => c.isDailyCore).toList();
    final rest = _all.where((c) => !c.isDailyCore).toList();
    final withOccasion = rest.where((c) => c.occasion != null).toList();
    final dhikr = rest.where((c) => c.occasion == null && c.contentType == 'dhikr').toList();
    final dua = rest.where((c) => c.occasion == null && c.contentType == 'dua').toList();
    final other = rest.where((c) => c.occasion == null && c.contentType == 'other').toList();

    final occasionGroups = <String, List<AdhkarCategory>>{};
    for (final c in withOccasion) {
      occasionGroups.putIfAbsent(c.occasion!, () => []).add(c);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('حصن المسلم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(icon: Icons.wb_sunny_outlined, title: 'عبادتك اليوم'),
          const SizedBox(height: 10),
          ...core.map((c) => _CoreCard(
                category: c,
                completedToday: _completedToday[c.id] ?? false,
                streak: _streaks[c.id] ?? 0,
                minutes: _minutes[c.id] ?? 0,
                onTap: () => _open(c),
              )),
          if (dhikr.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionHeader(icon: Icons.spa_outlined, title: 'أذكارك'),
            const SizedBox(height: 10),
            ...dhikr.map((c) => _PlainRow(category: c, onTap: () => _open(c))),
          ],
          if (dua.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionHeader(icon: Icons.front_hand_outlined, title: 'أدعية'),
            const SizedBox(height: 10),
            ...dua.map((c) => _PlainRow(category: c, onTap: () => _open(c))),
          ],
          if (occasionGroups.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionHeader(icon: Icons.event_note_outlined, title: 'مناسبات وأعمال'),
            const SizedBox(height: 4),
            const Text('السفر، الجنازة والمرض، الحج، الطعام والصيام', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 10),
            for (final key in _occasionLabels.keys)
              if (occasionGroups[key] != null) ...[
                _OccasionSubheader(occasion: key),
                ...occasionGroups[key]!.map((c) => _PlainRow(category: c, onTap: () => _open(c))),
                const SizedBox(height: 8),
              ],
          ],
          if (other.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionHeader(icon: Icons.info_outline, title: 'أخرى'),
            const SizedBox(height: 4),
            const Text('فضائل وآداب عامة، ليست أذكارًا أو أدعية بعينها', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 10),
            ...other.map((c) => _PlainRow(category: c, onTap: () => _open(c))),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryDark),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _OccasionSubheader extends StatelessWidget {
  final String occasion;
  const _OccasionSubheader({required this.occasion});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = _occasionLabels[occasion]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _PlainRow extends StatelessWidget {
  final AdhkarCategory category;
  final VoidCallback onTap;
  const _PlainRow({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primaryLight,
        child: Icon(_iconForCategory(category), size: 16, color: AppColors.primaryDark),
      ),
      title: Text(category.title, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}

class _CoreCard extends StatelessWidget {
  final AdhkarCategory category;
  final bool completedToday;
  final int streak;
  final int minutes;
  final VoidCallback onTap;
  const _CoreCard({required this.category, required this.completedToday, required this.streak, required this.minutes, required this.onTap});

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  if (minutes > 0) ...[
                    const SizedBox(height: 2),
                    Text('⏱ ~$minutes دقائق', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
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
