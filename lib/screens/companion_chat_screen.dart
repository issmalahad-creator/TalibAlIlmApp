import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../widgets/companion_chat_body.dart';
import 'companion_debug_screen.dart';
import 'diagnostics_test_screen.dart';

/// "محادثة الرفيق" — QURAN_COMPANION_ROADMAP.md §4.36 step 2. Full-page
/// wrapper around `CompanionChatBody` (pure keyword matching + real
/// progress data + persisted memory, no real AI). Kept deliberately simple
/// — no typing indicators, no rich media — since the entire point is that
/// this is honest, inspectable keyword-matching, not a chatbot UI dressed
/// up to look smarter than it is.
class CompanionChatScreen extends StatelessWidget {
  const CompanionChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    return Scaffold(
      appBar: AppBar(
        title: Text(basicText('companion_chat_title', lang)),
        actions: [
          IconButton(
            tooltip: basicText('companion_debug_tooltip', lang),
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanionDebugScreen())),
          ),
          IconButton(
            tooltip: basicText('app_self_test_tooltip', lang),
            icon: const Icon(Icons.health_and_safety_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticsTestScreen())),
          ),
        ],
      ),
      body: const CompanionChatBody(),
    );
  }
}
