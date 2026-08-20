import 'package:flutter/material.dart';

import 'app_theme.dart';

/// "نظام التصميم ثلاثي الأبعاد" — the app's GLOBAL depth/materials
/// language (quirky-gliding-shell.md's "Global 3D Design Language" plan,
/// 2026-08-17. Ismail was explicit: this is not a Quran-reader-only
/// effect, it's meant to become the visual language of the whole app,
/// with each section free to pick its own accent color rather than one
/// palette forced everywhere). Started concretely on the Quran reading
/// screen (`quran_reading_screen.dart`'s layered page shadow + tilt
/// parallax) and `premium_modal.dart`; this file generalizes those into a
/// reusable token layer any screen can build on.
///
/// Same discipline as `AppMotion`/`AppRadius`/`AppTextStyles`: a named
/// vocabulary for NEW work. Existing screens migrate opportunistically
/// when touched for another reason anyway, not a forced rewrite of all
/// 71+ screens in one pass — see `DESIGN_SYSTEM_3D.md` for the rollout
/// status and per-section intensity plan.
class DepthShadows {
  /// Ordinary lift — list rows, small secondary cards. Barely-there depth.
  static List<BoxShadow> soft(Color tint) => [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        BoxShadow(color: tint.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1)),
      ];

  /// A surface meant to feel genuinely raised — feature cards, hero
  /// elements, the Mushaf page itself.
  static List<BoxShadow> floating(Color tint) => [
        BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 22, offset: const Offset(0, 10)),
        BoxShadow(color: tint.withValues(alpha: 0.14), blurRadius: 5, offset: const Offset(0, 2)),
      ];

  /// The deepest tier — modals/panels floating above a blurred backdrop
  /// (matches `premium_modal.dart`'s own shadow values exactly).
  static List<BoxShadow> modal(Color tint) => [
        BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 40, offset: const Offset(0, 20)),
        BoxShadow(color: tint.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 2)),
      ];
}

/// A per-section accent. Every section keeps `AppColors.surface`/`textDark`
/// as its text/base (so reading stays consistent app-wide) but supplies
/// its own tint for shadows/borders/highlights — Ismail's explicit "لا
/// تفرض نفس الألوان بكل مكان... اختر الألوان حسب غرض كل شاشة" request.
/// What makes screens feel like "one product" is the shared shadow
/// MECHANICS above, not identical colors.
class DepthPalette {
  final Color accent;
  final String labelAr;
  const DepthPalette({required this.accent, required this.labelAr});

  /// القرآن/التفسير/المكتبة — warm gold, the same `0xFFD9A441` already used
  /// in `qibla_screen.dart`'s glow and the home hero card, not a new gold
  /// invented here.
  static const quran = DepthPalette(accent: Color(0xFFD9A441), labelAr: 'القرآن والمكتبة');

  /// الرئيسية/لوحة القيادة — the app's own primary green.
  static const dashboard = DepthPalette(accent: AppColors.primaryDark, labelAr: 'الرئيسية');

  /// الحديث والعقيدة — a cooler, distinct accent so this content type
  /// reads visually different from the Quran's gold.
  static const knowledge = DepthPalette(accent: Color(0xFF5C6BC0), labelAr: 'الحديث والعقيدة');

  /// الإعدادات وما شابه — deliberately calm/minimal per Ismail's own note
  /// that some sections should stay lighter, not everything maximal.
  static const calm = DepthPalette(accent: Color(0xFF9CA3AF), labelAr: 'الإعدادات');
}
