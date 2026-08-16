import 'package:flutter/material.dart';

import '../data/wird_templates.dart';
import '../repositories/wird_repository.dart';
import '../theme/app_theme.dart';
import 'adhkar_screen.dart';
import 'madarij_screen.dart';
import 'quran_reading_screen.dart';
import 'quran_search_screen.dart';
import 'wasitiyyah_screen.dart';
import '../widgets/loading_view.dart';

const _istighfarTarget = 100;

/// "ورد اليوم" — QURAN_COMPANION_ROADMAP.md §4.17. One daily checklist
/// assembled across pillars (Quran, adhkar, istighfar, and — for the
/// scholar-flavored templates — a reading item from content already
/// sourced elsewhere in the app). See `data/wird_templates.dart` for the
/// important honesty note on what the scholar-named templates do and
/// don't claim.
class WirdScreen extends StatefulWidget {
  const WirdScreen({super.key});

  @override
  State<WirdScreen> createState() => _WirdScreenState();
}

class _WirdScreenState extends State<WirdScreen> {
  final _repo = WirdRepository();
  String _selectedKey = wirdTemplates.first.key;
  Map<String, bool> _done = {};
  int _istighfarCount = 0;
  bool _loading = true;

  WirdTemplate get _template => wirdTemplates.firstWhere((t) => t.key == _selectedKey);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final key = await _repo.selectedTemplateKey();
    final template = wirdTemplates.firstWhere((t) => t.key == key, orElse: () => wirdTemplates.first);
    final done = <String, bool>{};
    for (final item in template.items) {
      done[item.key] = switch (item.key) {
        'quran' => await _repo.isQuranDoneToday(),
        'adhkar' => await _repo.isAdhkarDoneToday(),
        'istighfar' => await _repo.istighfarToday() >= _istighfarTarget,
        'reading' => template.readingSource != null && await _repo.isReadingDoneToday(template.readingSource!),
        _ => false,
      };
    }
    final istighfar = await _repo.istighfarToday();
    if (!mounted) return;
    setState(() {
      _selectedKey = key;
      _done = done;
      _istighfarCount = istighfar;
      _loading = false;
    });
  }

  Future<void> _selectTemplate(String key) async {
    await _repo.selectTemplate(key);
    _load();
  }

  Future<void> _incrementIstighfar() async {
    final count = await _repo.incrementIstighfar();
    if (!mounted) return;
    setState(() {
      _istighfarCount = count;
      _done['istighfar'] = count >= _istighfarTarget;
    });
  }

  void _openItem(WirdTemplateItem item) {
    final Widget? target = switch (item.key) {
      'quran' => const QuranReadingScreen(),
      'adhkar' => const AdhkarScreen(),
      'reading' => switch (_template.key) {
          'ibn_kathir' => const QuranSearchScreen(),
          'ibn_qayyim' => const MadarijScreen(),
          _ => const WasitiyyahScreen(),
        },
      _ => null,
    };
    if (target == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => target)).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ورد اليوم')),
      body: _loading
          ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedKey,
                  decoration: const InputDecoration(labelText: 'اختر وردك', border: OutlineInputBorder()),
                  items: wirdTemplates.map((t) => DropdownMenuItem(value: t.key, child: Text(t.title))).toList(),
                  onChanged: (v) {
                    if (v != null) _selectTemplate(v);
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: Text(_template.description, style: const TextStyle(fontSize: 11.5, color: AppColors.primaryDark)),
                ),
                const SizedBox(height: 20),
                ..._template.items.map((item) => _WirdItemCard(
                      item: item,
                      done: _done[item.key] ?? false,
                      istighfarCount: item.key == 'istighfar' ? _istighfarCount : null,
                      istighfarTarget: item.key == 'istighfar' ? _istighfarTarget : null,
                      onTap: item.key == 'istighfar' ? _incrementIstighfar : () => _openItem(item),
                    )),
              ],
            ),
    );
  }
}

class _WirdItemCard extends StatelessWidget {
  final WirdTemplateItem item;
  final bool done;
  final int? istighfarCount;
  final int? istighfarTarget;
  final VoidCallback onTap;
  const _WirdItemCard({
    required this.item,
    required this.done,
    required this.onTap,
    this.istighfarCount,
    this.istighfarTarget,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: done ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: done ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(done ? Icons.check_circle : Icons.circle_outlined, color: done ? AppColors.primary : AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  if (item.subtitle != null)
                    Text(item.subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (istighfarCount != null && istighfarTarget != null)
              Text('$istighfarCount / $istighfarTarget', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ],
        ),
      ),
    );
  }
}
