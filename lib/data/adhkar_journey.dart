import 'package:flutter/material.dart';

/// Time-of-day windows for the "رحلتك اليومية" home-screen card — Ismail's
/// 2026-08-16 request, inspired by Almosaly's "Actions of Day & Night"
/// idea but original: maps the current clock time to whichever existing
/// core adhkar category is most relevant right now, so the app suggests
/// what to read instead of the student having to search for it.
enum DayWindow { earlyMorning, morning, afternoon, evening, night }

DayWindow dayWindowFor(DateTime now) {
  final hour = now.hour;
  if (hour >= 3 && hour < 6) return DayWindow.earlyMorning;
  if (hour >= 6 && hour < 12) return DayWindow.morning;
  if (hour >= 12 && hour < 16) return DayWindow.afternoon;
  if (hour >= 16 && hour < 20) return DayWindow.evening;
  return DayWindow.night;
}

class JourneySuggestion {
  final String categoryTitle;
  final String label;
  final IconData icon;
  const JourneySuggestion({required this.categoryTitle, required this.label, required this.icon});
}

/// Category-title lookup only — deliberately by title, the same idiom
/// `adhkar_category_screen.dart`'s `_streakTrackedCategoryTitle` already
/// uses, not a new ID/type column. Note: "أذكار الصباح والمساء" itself is
/// one undifferentiated 25-item category (not split by time internally),
/// so morning/evening only change the label and framing here, not which
/// items appear — splitting the content itself would be a content-curation
/// task, not a UX one.
const _suggestions = {
  DayWindow.earlyMorning: JourneySuggestion(categoryTitle: 'أذكار الاستيقاظ من النوم', label: 'ابدأ يومك بذكر الاستيقاظ', icon: Icons.bedtime_outlined),
  DayWindow.morning: JourneySuggestion(categoryTitle: 'أذكار الصباح والمساء', label: 'أذكار الصباح', icon: Icons.wb_sunny_outlined),
  DayWindow.afternoon: JourneySuggestion(categoryTitle: 'الاستغفار والتوبة', label: 'استغفر ربك الآن', icon: Icons.brightness_5_outlined),
  DayWindow.evening: JourneySuggestion(categoryTitle: 'أذكار الصباح والمساء', label: 'أذكار المساء', icon: Icons.wb_twighlight),
  DayWindow.night: JourneySuggestion(categoryTitle: 'أذكار النوم', label: 'قبل أن تنام', icon: Icons.nightlight_outlined),
};

JourneySuggestion journeySuggestionFor(DateTime now) => _suggestions[dayWindowFor(now)]!;
