import 'package:flutter/material.dart';

import '../repositories/wasitiyyah_repository.dart';
import '../theme/app_theme.dart';
import 'wasitiyyah_quiz_screen.dart';

/// "العقيدة الواسطية" — Phase 5ب of QURAN_COMPANION_ROADMAP.md.
class WasitiyyahScreen extends StatefulWidget {
  const WasitiyyahScreen({super.key});

  @override
  State<WasitiyyahScreen> createState() => _WasitiyyahScreenState();
}

class _WasitiyyahScreenState extends State<WasitiyyahScreen> {
  final _repo = WasitiyyahRepository();
  List<WasitiyyahSection> _sections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sections = await _repo.all();
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _loading = false;
    });
  }

  Future<void> _markMemorized(WasitiyyahSection s) async {
    await _repo.markMemorized(s.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final memorizedCount = _sections.where((s) => s.memorized).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('العقيدة الواسطية'),
        actions: [
          IconButton(
            tooltip: 'اختبر نفسك',
            icon: const Icon(Icons.quiz_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const WasitiyyahQuizScreen()));
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('$memorizedCount من ${_sections.length} مقطعًا', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _sections.length,
                    itemBuilder: (context, i) {
                      final s = _sections[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    s.memorized ? Icons.check_circle : Icons.circle_outlined,
                                    color: s.memorized ? AppColors.primary : AppColors.textMuted,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('مقطع ${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(s.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14.5, height: 1.8)),
                              if (!s.memorized) ...[
                                const SizedBox(height: 8),
                                OutlinedButton(onPressed: () => _markMemorized(s), child: const Text('حفظته', style: TextStyle(fontSize: 12))),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
