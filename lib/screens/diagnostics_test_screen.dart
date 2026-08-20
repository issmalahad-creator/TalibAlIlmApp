import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_self_test_service.dart';
import '../services/claude_diagnostics_service.dart';
import '../theme/app_theme.dart';

/// "اختبار شامل" (Ismail's 2026-08-20 request) — hidden dev/diagnostics
/// screen. Runs `AppSelfTestService`'s real on-device checks, optionally
/// asks Claude to analyze the results (see `ClaudeDiagnosticsService`'s own
/// doc comment for why that's safe only in this dev-only, single-user
/// context), and lets Ismail copy the full report to paste into a future
/// Claude Code session — the practical bridge for a dev environment that
/// has no direct access to Ismail's real device. Reachable only from
/// `CompanionDebugScreen`'s app bar (already a low-visibility dev tool),
/// not from any student-facing navigation.
class DiagnosticsTestScreen extends StatefulWidget {
  const DiagnosticsTestScreen({super.key});

  @override
  State<DiagnosticsTestScreen> createState() => _DiagnosticsTestScreenState();
}

class _DiagnosticsTestScreenState extends State<DiagnosticsTestScreen> {
  final _selfTest = AppSelfTestService();
  final _claude = ClaudeDiagnosticsService();
  List<SelfTestResult> _results = [];
  bool _running = false;
  String? _aiAnalysis;
  bool _analyzing = false;
  String? _aiError;

  Future<void> _runTests() async {
    setState(() {
      _running = true;
      _results = [];
      _aiAnalysis = null;
      _aiError = null;
    });
    final results = await _selfTest.runAll();
    if (!mounted) return;
    setState(() {
      _results = results;
      _running = false;
    });
  }

  String get _reportText {
    final buffer = StringBuffer('تقرير اختبار شامل — طالب العلم\n\n');
    for (final r in _results) {
      buffer.writeln('${r.passed ? "✅" : "❌"} ${r.name}');
      buffer.writeln('   ${r.detail}');
    }
    return buffer.toString();
  }

  Future<void> _copyReport() async {
    await Clipboard.setData(ClipboardData(text: _reportText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نُسخ التقرير')));
  }

  Future<void> _analyzeWithClaude() async {
    setState(() {
      _analyzing = true;
      _aiError = null;
    });
    try {
      final analysis = await _claude.analyzeReport(_reportText);
      if (!mounted) return;
      setState(() => _aiAnalysis = analysis);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiError = '$e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final failedCount = _results.where((r) => !r.passed).length;
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار شامل للتطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _running ? null : _runTests,
            icon: _running ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
            label: Text(_running ? 'جارٍ الاختبار...' : 'تشغيل الاختبار'),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              failedCount == 0 ? 'كل الفحوصات ناجحة (${_results.length})' : '$failedCount فحص فشل من أصل ${_results.length}',
              style: AppTextStyles.title.copyWith(color: failedCount == 0 ? Colors.green.shade700 : Colors.red.shade700),
            ),
            const SizedBox(height: 10),
            ..._results.map((r) => Card(
                  color: r.passed ? null : Colors.red.shade50,
                  child: ListTile(
                    leading: Icon(r.passed ? Icons.check_circle_outline : Icons.error_outline, color: r.passed ? Colors.green : Colors.red),
                    title: Text(r.name, textAlign: TextAlign.right),
                    subtitle: Text(r.detail, textAlign: TextAlign.right),
                  ),
                )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(onPressed: _copyReport, icon: const Icon(Icons.copy_rounded), label: const Text('نسخ التقرير')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _analyzing ? null : _analyzeWithClaude,
                    icon: _analyzing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome_outlined),
                    label: Text(_analyzing ? 'جارٍ التحليل...' : 'تحليل بواسطة Claude'),
                  ),
                ),
              ],
            ),
            if (_aiError != null) ...[
              const SizedBox(height: 12),
              Text(_aiError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.right),
            ],
            if (_aiAnalysis != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
                child: Text(_aiAnalysis!, textAlign: TextAlign.right, style: const TextStyle(height: 1.6)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
