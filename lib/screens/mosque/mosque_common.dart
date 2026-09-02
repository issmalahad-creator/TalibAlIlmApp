import 'package:flutter/material.dart';

import '../../models/mosque.dart';

/// Shared bits for the «مساجدنا» screens — one place for the per-kind icon
/// and the verified badge, so the reusable template never special-cases a
/// mosque.
IconData mosqueKindIcon(MosqueContentKind k) => switch (k) {
      MosqueContentKind.lesson => Icons.menu_book_outlined,
      MosqueContentKind.khutbah => Icons.mosque_outlined,
      MosqueContentKind.announcement => Icons.campaign_outlined,
      MosqueContentKind.recording => Icons.headphones_outlined,
      MosqueContentKind.library => Icons.local_library_outlined,
      MosqueContentKind.need => Icons.volunteer_activism_outlined,
      MosqueContentKind.activity => Icons.event_outlined,
    };

class VerifiedChip extends StatelessWidget {
  final String label;
  const VerifiedChip({super.key, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2FAE60).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF2FAE60)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2FAE60))),
          ],
        ),
      );
}
