import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The shareable certificate design — QURAN_COMPANION_ROADMAP.md §4.14.
/// Deliberately fixed-size (not responsive) since it's captured as an image
/// via [RepaintBoundary] for sharing, not meant to be laid out on-page.
class CertificateCard extends StatelessWidget {
  final String studentName;
  final String title;
  final String hijriDate;
  final bool grand; // true only for the "ختم القرآن كاملًا" certificate

  const CertificateCard({
    super.key,
    required this.studentName,
    required this.title,
    required this.hijriDate,
    this.grand = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = grand ? const Color(0xFFB8860B) : AppColors.primaryDark;
    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: grand ? [const Color(0xFFFFF9E6), const Color(0xFFFCEFC7)] : [AppColors.surface, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(grand ? Icons.workspace_premium : Icons.emoji_events, color: accent, size: 44),
          const SizedBox(height: 10),
          Text('شهادة تقدير', style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 18),
          Text('تُمنح هذه الشهادة إلى', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            studentName.trim().isEmpty ? 'طالب العلم' : studentName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accent),
          ),
          const SizedBox(height: 18),
          Text(hijriDate, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          const Text('تطبيق طالب العلم', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
