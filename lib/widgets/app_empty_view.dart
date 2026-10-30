import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app's one empty state — the counterpart of [AppLoadingView]
/// (tour 2026-10-29 ج1, `docs/TOUR_2026-10-29.md`). About fifteen screens
/// showed a lone grey sentence in an empty page; this gives each the same
/// calm shape: the screen's icon in a softly raised disc, the sentence, and
/// — when there is an obvious next step — one button that takes it.
class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyView({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFDF7), AppColors.primaryLight],
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8)),
                ],
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.6),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                // The theme stretches buttons full-width; here it's one quiet step.
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 24)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
