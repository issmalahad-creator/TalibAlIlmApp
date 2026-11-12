import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_self_test_service.dart';
import '../theme/app_theme.dart';

/// "اختبار شامل" (Ismail's 2026-08-20 request) — hidden dev/diagnostics
/// screen. Runs `AppSelfTestService`'s real on-device checks and lets Ismail
/// copy the full report to paste into a Claude Code session — the practical
/// bridge for a dev environment with no direct access to his real device.
/// (The in-app «تحليل بواسطة Claude» button and its API key were removed on
/// 2026-11-12: Ismail — «لا يحتاج كلاود في التطبيق».) Reachable only from
/// `CompanionDebugScreen`'s app bar (already a low-visibility dev tool),
/// not from any student-facing navigation.
class DiagnosticsTestScreen extends StatefulWidget {
  const DiagnosticsTestScreen({super.key});

  @override
  State<DiagnosticsTestScreen> createState() => _DiagnosticsTestScreenState();
}

class _DiagnosticsTestScreenState extends State<DiagnosticsTestScreen> {
  final _selfTest = AppSelfTestService();
  List<SelfTestResult> _results = [];
  bool _running = false;

  Future<void> _runTests() async {
    setState(() {
      _running = true;
      _results = [];
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
            OutlinedButton.icon(onPressed: _copyReport, icon: const Icon(Icons.copy_rounded), label: const Text('نسخ التقرير')),
          ],
        ],
      ),
    );
  }
}
