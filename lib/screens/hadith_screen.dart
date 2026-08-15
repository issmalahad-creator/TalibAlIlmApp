import 'package:flutter/material.dart';

import '../repositories/hadith_repository.dart';
import '../theme/app_theme.dart';
import 'hadith_quiz_screen.dart';

/// "الأربعين النووية" — Phase 5أ of QURAN_COMPANION_ROADMAP.md. Browse all
/// 42 hadith with their commentary, mark memorized, and a quick-access
/// button to the recall quiz.
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final _repo = HadithRepository();
  List<NawawiHadith> _hadiths = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final hadiths = await _repo.all();
    if (!mounted) return;
    setState(() {
      _hadiths = hadiths;
      _loading = false;
    });
  }

  Future<void> _markMemorized(NawawiHadith h) async {
    await _repo.markMemorized(h.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final memorizedCount = _hadiths.where((h) => h.memorized).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأربعين النووية'),
        actions: [
          IconButton(
            tooltip: 'اختبر نفسك',
            icon: const Icon(Icons.quiz_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithQuizScreen()));
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
                  child: Text('$memorizedCount من ${_hadiths.length} حديثًا', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _hadiths.length,
                    itemBuilder: (context, i) {
                      final h = _hadiths[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Icon(
                              h.memorized ? Icons.check_circle : Icons.circle_outlined,
                              color: h.memorized ? AppColors.primary : AppColors.textMuted,
                              size: 20,
                            ),
                            title: Text('الحديث ${h.id}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(h.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, height: 1.8)),
                                    const SizedBox(height: 12),
                                    if (!h.memorized)
                                      OutlinedButton(onPressed: () => _markMemorized(h), child: const Text('حفظته', style: TextStyle(fontSize: 12))),
                                  ],
                                ),
                              ),
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
