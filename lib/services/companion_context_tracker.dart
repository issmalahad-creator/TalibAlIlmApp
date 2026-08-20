import 'package:flutter/foundation.dart';

/// "لو كنا في القرآن وحبينا نسئل عن آية وتفسيرها" (Ismail, 2026-08-18) —
/// tracks the last ayah the student actually tapped/showed interest in
/// while reading, so the companion chat can answer "فسرها" with a real
/// answer instead of "which ayah?". Deliberately global and simple: a
/// single in-memory `ValueNotifier`, not persisted — this is "what are you
/// looking at right now", not a bookmark or history feature (those already
/// exist separately). Set from `quran_reading_screen.dart`'s existing
/// ayah-tap handler; read from `CompanionChatSession`.
class CompanionContextTracker {
  CompanionContextTracker._internal();
  static final instance = CompanionContextTracker._internal();

  final ValueNotifier<(int surah, int ayah)?> currentAyah = ValueNotifier(null);

  void setCurrentAyah(int surah, int ayah) => currentAyah.value = (surah, ayah);
}
