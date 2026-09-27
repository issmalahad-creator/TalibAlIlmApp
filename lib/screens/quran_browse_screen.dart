import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/memorization_repository.dart';
import '../repositories/milestone_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/loading_view.dart';

/// "القرآن" — Phase 1 of QURAN_COMPANION_ROADMAP.md. Browse all 604 pages
/// grouped by Juz, and mark a page as newly memorized (the entry point into
/// the review engine — without this, `dueToday()` in the review screen has
/// nothing to show).
class QuranBrowseScreen extends StatefulWidget {
  /// When set (e.g. arriving from رحلتي's "تكليف اليوم" card), that page
  /// gets a featured call-out above the Juz list with a one-tap "حفظتها" —
  /// so the student lands directly on their assigned page instead of
  /// having to find it themselves in the full Mushaf browse below.
  final int? highlightUnitId;
  const QuranBrowseScreen({super.key, this.highlightUnitId});

  @override
  State<QuranBrowseScreen> createState() => _QuranBrowseScreenState();
}

class _QuranBrowseScreenState extends State<QuranBrowseScreen> {
  final _repo = MemorizationRepository();
  final _milestoneRepo = MilestoneRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  List<MemorizationUnit> _units = [];
  bool _loading = true;
  String? _error;
  int _repCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// A real bug report (2026-08-16, Ismail) described this screen showing
  /// completely blank instead of the Juz list, with no reliable repro on
  /// my end — this try/catch makes any real failure visible instead of a
  /// silent blank page, so it can actually be diagnosed from a screenshot
  /// if it happens again.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final units = await _repo.allUnitsWithProgress();
      final repCount = widget.highlightUnitId != null ? await _repo.repetitionCountToday(widget.highlightUnitId!) : 0;
      if (!mounted) return;
      setState(() {
        _units = units;
        _repCount = repCount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _incrementRepetition(int unitId) async {
    final count = await _repo.incrementRepetitionToday(unitId);
    if (!mounted) return;
    setState(() => _repCount = count);
  }

  Future<void> _markMemorized(MemorizationUnit unit) async {
    await _repo.markMemorized(unit.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('بارك الله فيك — صفحة ${unit.id} ضمن المراجعة الآن')));
    // 2026-08-17 (Ismail: "عند اكمال الجزء... يجب أن يظهر [الاحتفال] في تلك
    // اللحظة"): marking a page memorized here could just as easily complete
    // a Surah/Juz/the whole Quran as reviewing one on `review_screen.dart`
    // does (same `checkQuranMilestones`) — this screen just never checked,
    // so that exact moment silently went uncelebrated until the student
    // happened to open شهاداتي later.
    final newlyEarned = await _milestoneRepo.checkQuranMilestones();
    for (final milestone in newlyEarned) {
      if (!mounted) return;
      await showCelebration(context, milestone);
    }
    _load();
  }

  Future<void> _confirmReset(MemorizationUnit unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل: إلغاء تسجيل هذه الصفحة؟'),
        content: Text('ستعود صفحة ${unit.id} إلى "لم تُحفظ بعد"، وسيُحذف كل سجل مراجعتها. استخدم هذا فقط إن سجّلتها بالخطأ.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إلغاء التسجيل')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.resetProgress(unit.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أُلغي تسجيل صفحة ${unit.id}')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('القرآن')), body: AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_quran', LanguagePreferenceService.currentLanguage)));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('القرآن')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.textMuted, size: 32),
                const SizedBox(height: 10),
                Text('تعذّر تحميل قائمة الصفحات:\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                const SizedBox(height: 14),
                FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      );
    }
    if (_units.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('القرآن')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('لا توجد بيانات محفوظة بعد — قد يكون استيراد القرآن لم يكتمل بعد.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      );
    }

    final byJuz = <int, List<MemorizationUnit>>{};
    for (final u in _units) {
      byJuz.putIfAbsent(u.juzNumber ?? 0, () => []).add(u);
    }
    final juzNumbers = byJuz.keys.toList()..sort();
    final memorizedCount = _units.where((u) => u.status != 'not_started').length;
    MemorizationUnit? highlighted;
    if (widget.highlightUnitId != null) {
      for (final u in _units) {
        if (u.id == widget.highlightUnitId) {
          highlighted = u;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('القرآن')),
      body: Column(
        children: [
          if (highlighted != null && highlighted.status == 'not_started')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag_outlined, color: AppColors.primaryDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تكليف اليوم — سبق', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                              Text(
                                'صفحة ${highlighted.id} — من سورة ${_surahNames[highlighted.surahStart] ?? highlighted.surahStart} آية ${highlighted.ayahStart}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(onPressed: () => _markMemorized(highlighted!), child: const Text('حفظتها')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'كم مرة كررتها اليوم؟ $_repCount — الهدف الإرشادي ${MemorizationRepository.repetitionTargetRange.$1}-${MemorizationRepository.repetitionTargetRange.$2} مرة',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _incrementRepetition(highlighted!.id),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('كررتها', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('$memorizedCount من ${_units.length} صفحة ضمن الحفظ', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: juzNumbers.length,
              itemBuilder: (context, i) {
                final juz = juzNumbers[i];
                final pages = byJuz[juz]!;
                final juzMemorized = pages.where((u) => u.status != 'not_started').length;
                // Auto-expand the Juz containing today's highlighted
                // assignment (or Juz 1 if there's no highlight) so the
                // screen never LOOKS empty at a glance — every other Juz
                // starts collapsed by design, but a first-time visitor
                // shouldn't have to know to tap one open first.
                final isDefaultExpanded = highlighted != null ? juz == highlighted.juzNumber : juz == juzNumbers.first;
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: isDefaultExpanded,
                    title: Text('الجزء $juz', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text('$juzMemorized من ${pages.length} صفحة', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    children: pages.map(_pageRow).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageRow(MemorizationUnit unit) {
    final memorized = unit.status != 'not_started';
    return ListTile(
      dense: true,
      leading: Icon(
        memorized ? Icons.check_circle : Icons.circle_outlined,
        color: memorized ? AppColors.primary : AppColors.textMuted,
        size: 20,
      ),
      title: Text('صفحة ${unit.id}', style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        'من سورة ${_surahNames[unit.surahStart] ?? unit.surahStart} آية ${unit.ayahStart}',
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
      trailing: memorized
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_statusLabel(unit), style: const TextStyle(fontSize: 11, color: AppColors.primaryDark)),
                IconButton(
                  onPressed: () => _confirmReset(unit),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
                  tooltip: 'تعديل',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),
              ],
            )
          : TextButton(onPressed: () => _markMemorized(unit), child: const Text('حفظتها', style: TextStyle(fontSize: 12))),
    );
  }

  static const _hifzCategoryLabels = {
    HifzCategory.sabaq: 'سبق',
    HifzCategory.sabqi: 'سبقي',
    HifzCategory.manzil: 'منزل',
  };

  /// Real hifz-teaching terms (سبق/سبقي/منزل — see
  /// `MemorizationUnit.hifzCategory`, QURAN_COMPANION_ROADMAP.md §4.31)
  /// instead of an abstract "محطة N".
  String _statusLabel(MemorizationUnit unit) {
    if (unit.status == 'established') return 'راسخة (منزل) ✓';
    final category = unit.hifzCategory();
    final label = _hifzCategoryLabels[category];
    if (label == null) return unit.status;
    return unit.station != null ? '$label · محطة ${unit.station}' : label;
  }
}
