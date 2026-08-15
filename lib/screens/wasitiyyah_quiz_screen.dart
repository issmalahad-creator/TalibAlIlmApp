import 'dart:math';

import 'package:flutter/material.dart';

import '../repositories/daily_session_repository.dart';
import '../repositories/wasitiyyah_repository.dart';
import '../theme/app_theme.dart';

/// "اختبر نفسك" for Al-Wasitiyyah — "ما المقطع التالي؟", the same
/// continuation mechanic as the Quran quiz since this is a continuous
/// treatise too, scoped to the student's memorized sections.
class WasitiyyahQuizScreen extends StatefulWidget {
  const WasitiyyahQuizScreen({super.key});

  @override
  State<WasitiyyahQuizScreen> createState() => _WasitiyyahQuizScreenState();
}

class _WasitiyyahQuizScreenState extends State<WasitiyyahQuizScreen> {
  final _repo = WasitiyyahRepository();
  final _sessionRepo = DailySessionRepository();

  WasitiyyahSection? _current;
  WasitiyyahSection? _next;
  bool _revealed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _revealed = false;
    });
    final all = await _repo.all();
    final memorizedIds = (await _repo.memorizedIds()).toSet();
    // Only offer sections that are memorized AND have a next section
    // (skip the very last section — nothing to quiz "what comes after it").
    final candidates = <int>[];
    for (var i = 0; i < all.length - 1; i++) {
      if (memorizedIds.contains(all[i].id)) candidates.add(i);
    }
    if (candidates.isEmpty) {
      if (!mounted) return;
      setState(() {
        _current = null;
        _loading = false;
      });
      return;
    }
    final chosen = candidates[Random().nextInt(candidates.length)];
    if (!mounted) return;
    setState(() {
      _current = all[chosen];
      _next = all[chosen + 1];
      _loading = false;
    });
  }

  Future<void> _selfReport(bool knewIt) async {
    await _sessionRepo.markStep(quiz: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(knewIt ? 'أحسنت 🌱' : 'لا بأس — راجعه اليوم')));
    _loadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختبر نفسك — الواسطية')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }

  Widget _buildBody() {
    final current = _current;
    final next = _next;
    if (current == null || next == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('احفظ مقطعًا واحدًا على الأقل حتى يبني التطبيق لك سؤالًا', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
            child: Text(current.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, height: 1.8)),
          ),
          const SizedBox(height: 16),
          const Text('ما المقطع التالي؟', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (!_revealed)
            OutlinedButton(onPressed: () => setState(() => _revealed = true), child: const Text('أظهر الإجابة'))
          else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
              child: Text(next.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, height: 1.8)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => _selfReport(false), child: const Text('أحتاج مراجعة'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: () => _selfReport(true), child: const Text('كنت أعرفه'))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
