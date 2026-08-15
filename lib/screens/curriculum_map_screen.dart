import 'package:flutter/material.dart';

import '../data/curriculum_levels.dart';
import '../repositories/curriculum_repository.dart';
import '../theme/app_theme.dart';
import 'adhkar_screen.dart';
import 'audio_library_screen.dart';
import 'hadith_screen.dart';
import 'madarij_screen.dart';
import 'new_muslim_guide_screen.dart';
import 'quran_browse_screen.dart';
import 'wasitiyyah_screen.dart';
import 'zad_almaad_screen.dart';

const _stateLabels = {
  CurriculumItemState.comingSoon: ('قريبًا', Icons.hourglass_empty, AppColors.textMuted),
  CurriculumItemState.notStarted: ('لم يبدأ', Icons.circle_outlined, AppColors.textMuted),
  CurriculumItemState.inProgress: ('قيد التقدّم', Icons.trending_up, AppColors.primaryDark),
  CurriculumItemState.completed: ('مكتمل', Icons.check_circle, AppColors.primaryDark),
  CurriculumItemState.ongoing: ('مستمر', Icons.autorenew, AppColors.primaryDark),
};

/// "خريطتي التعليمية" — QURAN_COMPANION_ROADMAP.md §4.11 (Phase 7). Links
/// every pillar this app already has into one recommended 3-level path
/// ("يدخل المسلم صفر يخرج دكتور"). Purely a navigation/recommendation
/// layer — tapping any item just opens the real screen for it; nothing
/// here is locked, and a student can open any level directly.
class CurriculumMapScreen extends StatefulWidget {
  const CurriculumMapScreen({super.key});

  @override
  State<CurriculumMapScreen> createState() => _CurriculumMapScreenState();
}

class _CurriculumMapScreenState extends State<CurriculumMapScreen> {
  final _repo = CurriculumRepository();
  final Map<int, List<CurriculumItemStatus>> _statuses = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    for (final level in curriculumLevels) {
      _statuses[level.id] = await _repo.statusesFor(level.items);
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _open(String contentType) {
    Widget? screen;
    switch (contentType) {
      case 'juz_amma':
      case 'quran_memorization':
      case 'full_quran_mastery':
        screen = const QuranBrowseScreen();
        break;
      case 'adhkar':
        screen = const AdhkarScreen();
        break;
      case 'arbain':
        screen = const HadithScreen();
        break;
      case 'wasitiyyah':
        screen = const WasitiyyahScreen();
        break;
      case 'fiqh_taharah_salah':
        screen = const NewMuslimGuideScreen();
        break;
      case 'ajlan_tafsir':
        screen = const AudioLibraryScreen();
        break;
      case 'zad_almaad':
        screen = const ZadAlMaadScreen();
        break;
      case 'madarij':
        screen = const MadarijScreen();
        break;
    }
    if (screen == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا المحتوى قيد التحضير')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!)).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خريطتي التعليمية')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'مسار مقترح يربط كل ما في التطبيق من الصفر إلى التعمّق — توصية لا قفل، افتح ما تشاء بأي ترتيب.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                for (final level in curriculumLevels) _LevelSection(
                  level: level,
                  statuses: _statuses[level.id] ?? [],
                  onTapItem: _open,
                ),
              ],
            ),
    );
  }
}

class _LevelSection extends StatelessWidget {
  final CurriculumLevelDef level;
  final List<CurriculumItemStatus> statuses;
  final void Function(String contentType) onTapItem;

  const _LevelSection({required this.level, required this.statuses, required this.onTapItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(level.titleAr, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(level.descriptionAr, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          ...statuses.map((s) {
            final label = _stateLabels[s.state]!;
            return InkWell(
              onTap: () => onTapItem(s.contentType),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(label.$2, size: 18, color: label.$3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.titleAr, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(s.detailAr, style: TextStyle(fontSize: 11, color: label.$3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
