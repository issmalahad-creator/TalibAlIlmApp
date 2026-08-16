import 'package:flutter/material.dart';

import '../repositories/zad_almaad_repository.dart';
import '../theme/app_theme.dart';
import 'zad_almaad_chapter_screen.dart';
import '../widgets/loading_view.dart';

/// "زاد المعاد" — Phase 5ج of QURAN_COMPANION_ROADMAP.md. Volume 1 only for
/// now (see repository doc comment) — the rest is added incrementally.
class ZadAlMaadScreen extends StatefulWidget {
  const ZadAlMaadScreen({super.key});

  @override
  State<ZadAlMaadScreen> createState() => _ZadAlMaadScreenState();
}

class _ZadAlMaadScreenState extends State<ZadAlMaadScreen> {
  final _repo = ZadAlMaadRepository();
  List<ZadAlMaadChapter> _chapters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final chapters = await _repo.all();
    if (!mounted) return;
    setState(() {
      _chapters = chapters;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final readCount = _chapters.where((c) => c.readDone).length;
    return Scaffold(
      appBar: AppBar(title: const Text('زاد المعاد')),
      body: _loading
          ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...')
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '$readCount من ${_chapters.length} فصلًا — المجلد الأول (السيرة)، وبقية المجلدات تُضاف تباعًا',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _chapters.length,
                    itemBuilder: (context, i) {
                      final c = _chapters[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          c.readDone ? Icons.check_circle : Icons.circle_outlined,
                          color: c.readDone ? AppColors.primary : AppColors.textMuted,
                          size: 20,
                        ),
                        title: Text(c.title, style: const TextStyle(fontSize: 13.5)),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => ZadAlMaadChapterScreen(chapter: c)));
                          _load();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
