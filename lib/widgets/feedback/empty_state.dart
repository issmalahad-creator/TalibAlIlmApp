import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One empty state for the whole app (tour 2026-10-29, C1): an icon in a
/// softly raised circle, one sentence, and — when there is an obvious next
/// step — one button that takes it («احفظ آية الآن», «أضف هدفًا»), instead of
/// a lone grey line in the middle of a white screen.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surface, AppColors.primaryLight],
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8)),
                  const BoxShadow(color: Colors.white, blurRadius: 6, offset: Offset(-2, -2)),
                ],
              ),
              child: Icon(icon, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textMuted)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ]),
        ),
      );
}
