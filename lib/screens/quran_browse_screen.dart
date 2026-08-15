import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../repositories/memorization_repository.dart';
import '../theme/app_theme.dart';

/// "القرآن" — Phase 1 of QURAN_COMPANION_ROADMAP.md. Browse all 604 pages
/// grouped by Juz, and mark a page as newly memorized (the entry point into
/// the review engine — without this, `dueToday()` in the review screen has
/// nothing to show).
class QuranBrowseScreen extends StatefulWidget {
  const QuranBrowseScreen({super.key});

  @override
  State<QuranBrowseScreen> createState() => _QuranBrowseScreenState();
}

class _QuranBrowseScreenState extends State<QuranBrowseScreen> {
  final _repo = MemorizationRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  List<MemorizationUnit> _units = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final units = await _repo.allUnitsWithProgress();
    if (!mounted) return;
    setState(() {
      _units = units;
      _loading = false;
    });
  }

  Future<void> _markMemorized(MemorizationUnit unit) async {
    await _repo.markMemorized(unit.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('بارك الله فيك — صفحة ${unit.id} ضمن المراجعة الآن')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('القرآن')), body: const Center(child: CircularProgressIndicator()));
    }

    final byJuz = <int, List<MemorizationUnit>>{};
    for (final u in _units) {
      byJuz.putIfAbsent(u.juzNumber ?? 0, () => []).add(u);
    }
    final juzNumbers = byJuz.keys.toList()..sort();
    final memorizedCount = _units.where((u) => u.status != 'not_started').length;

    return Scaffold(
      appBar: AppBar(title: const Text('القرآن')),
      body: Column(
        children: [
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
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
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
          ? Text(_statusLabel(unit), style: const TextStyle(fontSize: 11, color: AppColors.primaryDark))
          : TextButton(onPressed: () => _markMemorized(unit), child: const Text('حفظتها', style: TextStyle(fontSize: 12))),
    );
  }

  String _statusLabel(MemorizationUnit unit) {
    if (unit.status == 'established') return 'راسخة ✓';
    if (unit.station != null) return 'محطة ${unit.station}';
    return unit.status;
  }
}
