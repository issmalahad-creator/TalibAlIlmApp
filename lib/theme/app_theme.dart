import 'package:flutter/material.dart';

/// Design tokens for the app — soft sage-green palette, warm off-white
/// background, rounded cards with soft shadows.
///
/// `primary`/`primaryDark`/`background`/`surfaceCard` are pinned to the
/// measured values in `docs/quran/VISUAL_IDENTITY_STYLE_GUIDE.md` §2
/// (real pixel samples from the reference app's video, not invented) —
/// 2026-09-13, Phase 2 of that guide's rollout. `surface` stays the
/// existing pure white (the guide's own `surface.control`, for input
/// fields/the mushaf page itself, deliberately distinct from
/// `surfaceCard`'s warm beige for cards/sheets).
class AppColors {
  static const primary = Color(0xFF4F8D53);
  static const primaryDark = Color(0xFF26402A);
  static const primaryLight = Color(0xFFE6F2EA);
  static const background = Color(0xFFFBF2D9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceCard = Color(0xFFEFE4C8);
  static const textDark = Color(0xFF1F2937);
  static const textMuted = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);

  /// Night-mode counterparts — one source of truth for the dark colours
  /// `mushaf_semantic_reader_screen.dart`'s existing `_night` toggle reads,
  /// replacing that screen's own scattered (and previously inconsistent —
  /// e.g. three slightly different "night text" hexes) local constants.
  /// No app-wide `ThemeMode`/`darkTheme` yet — this only unifies the
  /// values an existing per-screen toggle already needed.
  static const backgroundNight = Color(0xFF14110E);
  static const surfaceNight = Color(0xFF1E1A16);
  static const textDarkNight = Color(0xFFE9E1D2);
  static const dividerNight = Color(0xFF2E2A24);

  // Category pill colors: (background, foreground)
  static const categoryColors = <String, (Color, Color)>{
    'lesson': (Color(0xFFDCF5E5), Color(0xFF1F7A4D)),
    'lecture': (Color(0xFFDCEBFA), Color(0xFF1D5FA8)),
    'sermon': (Color(0xFFE8E0FA), Color(0xFF5B3FA8)),
    'dawahTrip': (Color(0xFFFCE9D6), Color(0xFFB5651D)),
    'newMuslim': (Color(0xFFFCE0EA), Color(0xFFB8386B)),
    'otherActivity': (Color(0xFFE2E8E6), Color(0xFF4B5B57)),
  };

  /// Study-annotation highlight colours (Phase 79 «علامات الدراسة»), keyed by
  /// the semantic `color_key`: (light tint, night tint, solid accent). The
  /// tints are low-saturation and translucent so text stays readable on
  /// both the off-white and the night backgrounds; the accent is for the
  /// colour chips / the dot in the annotation sheet.
  static const studyAnnotationColors = <String, (Color, Color, Color)>{
    'benefit': (Color(0x40F2C200), Color(0x59B8860B), Color(0xFFD97706)), // 🟨 فائدة
    'explain': (Color(0x333B82F6), Color(0x552563EB), Color(0xFF2563EB)), // 🟦 شرح
    'memorize': (Color(0x3322C55E), Color(0x5516A34A), Color(0xFF16A34A)), // 🟩 للحفظ والمراجعة
    'important': (Color(0x33EF4444), Color(0x55B91C1C), Color(0xFFDC2626)), // 🟥 مهم جدًا
    'question': (Color(0x33A855F7), Color(0x557E22CE), Color(0xFF9333EA)), // 🟪 سؤال / إشكال
  };

  static (Color, Color, Color) studyAnnotation(String key) =>
      studyAnnotationColors[key] ?? studyAnnotationColors['benefit']!;
}

/// Shared corner-radius vocabulary — added 2026-08-16 after a grep across
/// `lib/screens`+`lib/widgets` found `BorderRadius.circular(...)` called
/// with 11 different ad-hoc values (2/4/8/10/12/14/16/18/20/22/999), no
/// shared scale. Same problem, same fix as `AppMotion`
/// (`lib/theme/motion.dart`): four tiers derived from the values already
/// dominant in the app (14 and 18 are by far the most common), not
/// invented numbers, for new work to reach for — existing call sites are
/// NOT rewritten as part of this (scope creep beyond "add the vocabulary").
class AppRadius {
  static const sm = 12.0; // inputs, small chips
  static const md = 14.0; // the app's most common value — ordinary cards/buttons
  static const lg = 18.0; // matches CardTheme's own default below — prominent cards
  static const xl = 22.0; // hero/feature cards
  static const pill = 999.0; // fully-rounded badges/chips
}

/// Shared typography vocabulary — added 2026-08-17, same discipline as
/// `AppRadius`/`AppMotion`: a grep across `lib/screens/*.dart` found 432
/// `fontSize:` occurrences using 23 distinct values, no shared scale (the
/// top 8 values already account for ~80% of real usage). Tiers below are
/// named from that real distribution, not invented — for NEW work only;
/// the 432 existing call sites are deliberately not rewritten, exactly as
/// `AppRadius`/`AppMotion` left their own precedents untouched.
///
/// `quranBody`/`duaBody` formalize a split that already exists in practice
/// (Quran ayat use `AmiriQuran`, one hadith block uses `Amiri`, everything
/// else uses the theme's default `Tahoma`) rather than introducing a new
/// font choice.
class AppTextStyles {
  static const caption = TextStyle(fontSize: 11, color: AppColors.textMuted);
  static const label = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 13.5, color: AppColors.textDark);
  static const title = TextStyle(fontSize: 15, fontWeight: FontWeight.w800);
  static const headline = TextStyle(fontSize: 18, fontWeight: FontWeight.w800);
  static const display = TextStyle(fontSize: 22, fontWeight: FontWeight.w800);

  /// Quran ayah recitation text — matches the size/family already used in
  /// `review_screen.dart`/`tahfeez_playback_screen.dart`, not a new choice.
  static const quranBody = TextStyle(fontFamily: 'AmiriQuran', fontSize: 21, height: 1.9);

  /// Hadith/dua recitation text — matches `time_awareness_screen.dart`'s
  /// existing usage.
  static const duaBody = TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.9);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Tahoma',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.divider),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
  );
}
