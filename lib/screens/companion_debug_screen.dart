import 'package:flutter/material.dart';

import '../services/companion_chat_engine.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';

/// "لماذا فهم كم بقي لي خطأ" — Ismail's 2026-08-18 ask: a way to actually
/// SEE why the engine picked (or didn't pick) an intent, instead of
/// guessing from the outside. Reads `CompanionChatEngine.debugScores()`
/// directly — the exact same scoring `match()` uses internally, not a
/// separate re-implementation that could drift and mislead. Single-device,
/// single-user tool (this app has no server/telemetry to aggregate across
/// users) — reachable from the chat screen for Ismail's own diagnosis, not
/// a multi-tenant analytics dashboard.
class CompanionDebugScreen extends StatefulWidget {
  const CompanionDebugScreen({super.key});

  @override
  State<CompanionDebugScreen> createState() => _CompanionDebugScreenState();
}

class _CompanionDebugScreenState extends State<CompanionDebugScreen> {
  final _engine = CompanionChatEngine();
  final _controller = TextEditingController();
  List<MapEntry<String, double>> _scores = [];
  String _lang = LanguagePreferenceService.currentLanguage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run() {
    setState(() => _scores = _engine.debugScores(_controller.text, lang: _lang));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تشخيص محرك الرفيق')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'اكتب رسالة لاختبارها', border: OutlineInputBorder()),
                    onSubmitted: (_) => _run(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _lang,
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('ar')),
                    DropdownMenuItem(value: 'en', child: Text('en')),
                  ],
                  onChanged: (v) => setState(() => _lang = v ?? 'ar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _run, child: const Text('تحليل')),
            const SizedBox(height: 16),
            if (_scores.isNotEmpty) ...[
              Text('أقوى تطابق: ${_scores.first.key} (${_scores.first.value.toStringAsFixed(2)})', style: AppTextStyles.headline),
              const Divider(height: 24),
              Text('كل النوايا مرتبة حسب القوة:', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _scores.length,
                  itemBuilder: (context, i) {
                    final entry = _scores[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text(entry.value.toStringAsFixed(2), style: AppTextStyles.caption),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
