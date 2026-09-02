import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../screens/companion_chat_screen.dart';
import '../screens/knowledge_review_screen.dart';
import '../screens/mushaf_semantic_reader_screen.dart';
import '../services/companion_context_service.dart';
import '../services/companion_engine.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// "رفيق طالب العلم" home-screen card — Ismail's 2026-08-17 request (Phase
/// B of the plan). Gathers a `CompanionContext` from repositories that
/// already exist (no new tracking tables), hands it to the pure
/// `companionMessageFor()` rule engine, and renders nothing at all
/// (`SizedBox.shrink()`) if no rule matched — per Ismail's explicit "لا
/// يظهر إلا عندما لديه شيء مفيد ليقوله" instruction. This is the ONE of
/// the 4 companion placements from the plan built as a standalone
/// reusable widget; the other three (guided-session instruction line,
/// celebration-overlay gap, end-of-day summary) are small enough to stay
/// inline where they're used rather than sharing this widget.
class CompanionCard extends StatefulWidget {
  const CompanionCard({super.key});

  @override
  State<CompanionCard> createState() => _CompanionCardState();
}

class _CompanionCardState extends State<CompanionCard> {
  CompanionMessage? _message;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final context = await buildCompanionContext();
    final message = companionMessageFor(context);
    if (!mounted) return;
    setState(() {
      _message = message;
      _loading = false;
    });
  }

  void _onStart() {
    final target = _message?.state == CompanionState.dailyInvite
        ? const MushafSemanticReaderScreen()
        : const KnowledgeReviewScreen();
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  void _onChat() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanionChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    if (_loading || message == null) return const SizedBox.shrink();
    final lang = LanguagePreferenceService.currentLanguage;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.premium,
      curve: AppMotion.entranceCurve,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${basicText('companion_caption_prefix', lang)} ${message.icon}', style: AppTextStyles.caption),
            const SizedBox(height: 6),
            Text(message.title, style: AppTextStyles.headline),
            const SizedBox(height: 4),
            Text(message.body, style: AppTextStyles.body),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _onStart,
                    child: Text(basicText('companion_start_now', lang)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onChat,
                    child: Text(basicText('companion_chat_with_him', lang)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
