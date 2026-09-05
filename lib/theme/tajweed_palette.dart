import 'package:flutter/material.dart';

/// Phase G-t · the muṣḥaf tajwīd colour set, keyed by **rule family** (six,
/// never the 18 individual rule ids — a page with 18 hues is noise, not a
/// teaching aid). Same shape as [AppColors.studyAnnotationColors]:
/// `(light tint, night tint, solid accent)`.
///
/// - `light` / `night` — translucent tints for chips, the legend strip and
///   the rule rows in the knowledge surface.
/// - `accent` — the solid hue: legend dots, and (Phase G-t3) the on-page
///   wash, drawn as `accent.withValues(alpha: 0.24)` by day / `0.30` by
///   night over the glyph-box run. That opacity is the documented
///   `QURAN_PREMIUM_UI.md` §8-bis carve-out — allowed only inside the
///   opt-in «وضع التجويد», off by default.
///
/// The six families and their member rule ids (see `tajweed_rules_ref.dart`):
///   noon_tanwin      — إخفاء · إقلاب · إدغام بغنّة/بغير غنّة · متجانسين · متقاربين
///   meem_sakina      — إخفاء شفوي · إدغام شفوي
///   madd             — طبيعي · عارض/لين · لازم · متّصل · منفصل
///   ghunnah_qalqalah — غنّة · قلقلة
///   lam_hamza        — لام شمسية · همزة وصل
///   silent           — حرف لا يُنطق
class TajweedPalette {
  const TajweedPalette._();

  static const families = <String, (Color light, Color night, Color accent)>{
    // teal-green — the noon-sākinah / tanwīn group (the largest family)
    'noon_tanwin': (Color(0x3311998E), Color(0x5514B8A6), Color(0xFF0E9384)),
    // cyan — the mīm-sākinah group
    'meem_sakina': (Color(0x330EA5E9), Color(0x550284C7), Color(0xFF0284C7)),
    // warm red — the mudūd (traditional tajwīd masaahif colour madd red)
    'madd': (Color(0x33E11D48), Color(0x55BE123C), Color(0xFFE11D48)),
    // indigo — ghunnah + qalqalah
    'ghunnah_qalqalah': (Color(0x334F46E5), Color(0x554338CA), Color(0xFF4F46E5)),
    // violet — the lām / hamza group
    'lam_hamza': (Color(0x339333EA), Color(0x557E22CE), Color(0xFF9333EA)),
    // muted slate — silent letters
    'silent': (Color(0x2F64748B), Color(0x55475569), Color(0xFF64748B)),
  };

  static (Color light, Color night, Color accent) family(String key) =>
      families[key] ?? families['silent']!;

  /// Just the solid hue for [key] (legend dots, wash base colour).
  static Color accentOf(String key) => family(key).$3;
}
