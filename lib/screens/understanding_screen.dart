import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../db/database_helper.dart';
import '../repositories/understanding_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

/// "الفهم" — Phase 3 of QURAN_COMPANION_ROADMAP.md. Shows the tafsir for a
/// memorized-but-not-yet-understood page and lets the student mark
/// "فهمت" — deliberately separate from memorization status (see section 1's
/// "حفظت الآية ≠ فهمتها" principle).
class UnderstandingScreen extends StatefulWidget {
  const UnderstandingScreen({super.key});

  @override
  State<UnderstandingScreen> createState() => _UnderstandingScreenState();
}

class _UnderstandingScreenState extends State<UnderstandingScreen> {
  final _repo = UnderstandingRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};
  static const _defaultSource = 'almukhtasar';

  List<int> _queue = [];
  Map<String, Object?>? _currentUnit;
  List<Map<String, Object?>> _tafsirParagraphs = [];
  final _notesController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final queue = await _repo.memorizedNotYetUnderstood();
    if (!mounted) return;
    setState(() => _queue = queue);
    await _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    if (_queue.isEmpty) {
      setState(() {
        _currentUnit = null;
        _tafsirParagraphs = [];
        _loading = false;
      });
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final unitId = _queue.first;
    final unitRows = await db.query('memorization_units', where: 'id = ?', whereArgs: [unitId], limit: 1);
    final tafsirRows = await db.rawQuery('''
      SELECT DISTINCT t.ayah_from, t.ayah_to, t.text FROM tafsir_entries t
      JOIN memorization_units u ON u.id = ?
      WHERE t.source = ? AND t.surah BETWEEN u.surah_start AND u.surah_end
      ORDER BY t.surah, t.ayah_from
      LIMIT 20
    ''', [unitId, _defaultSource]);
    if (!mounted) return;
    setState(() {
      _currentUnit = unitRows.isEmpty ? null : unitRows.first;
      _tafsirParagraphs = tafsirRows;
      _loading = false;
    });
  }

  Future<void> _markUnderstood() async {
    if (_queue.isEmpty) return;
    await _repo.markUnderstood(_queue.first, notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim());
    _notesController.clear();
    setState(() => _queue = _queue.skip(1).toList());
    await _loadCurrent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفهم')),
      body: _loading ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...') : _buildBody(),
    );
  }

  Widget _buildBody() {
    final unit = _currentUnit;
    if (unit == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'لا توجد صفحات محفوظة بانتظار الفهم حاليًا — احفظ صفحة جديدة أولًا، أو أحسنت إن كنت فهمت كل ما حفظته 🌱',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final surahStart = unit['surah_start'] as int;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('باقي ${_queue.length} صفحة', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text('صفحة ${unit['id']} — سورة ${_surahNames[surahStart] ?? surahStart}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _tafsirParagraphs.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, i) {
                final p = _tafsirParagraphs[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(p['text'] as String, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, height: 1.8)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'ملاحظتك الخاصة (اختياري)', isDense: true),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: _markUnderstood, icon: const Icon(Icons.check), label: const Text('فهمتها')),
        ],
      ),
    );
  }
}
