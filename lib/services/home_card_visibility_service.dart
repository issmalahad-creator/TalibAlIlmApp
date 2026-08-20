import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CUSTOMIZATION_IDEAS.md #4 — lets a student hide home-screen cards they
/// don't personally use (e.g. someone who doesn't track time awareness
/// doesn't need to see that card every day). Only the *optional* cards are
/// listed here — core navigation (the Quran hero card, the nav grid) isn't
/// hideable, matching CUSTOMIZATION_IDEAS.md's own distinction between
/// "reorder/hide extras" and "remove core function" from earlier tonight's
/// Quran-header conversation (same principle, different screen).
class HomeCardIds {
  static const companion = 'companion';
  static const dailyCompanion = 'daily_companion';
  static const dailyJourney = 'daily_journey';
  static const knowledgeReview = 'knowledge_review';
  static const worshipCoach = 'worship_coach';
  static const timeAccountability = 'time_accountability';
  static const endOfDay = 'end_of_day';
  static const progress = 'progress';
  static const tasks = 'tasks';
  static const recentActivities = 'recent_activities';
  static const hifz = 'hifz';
  static const review = 'review';

  static const all = [
    companion,
    dailyCompanion,
    dailyJourney,
    knowledgeReview,
    worshipCoach,
    timeAccountability,
    endOfDay,
    progress,
    tasks,
    recentActivities,
    hifz,
    review,
  ];
}

class HomeCardVisibilityService {
  static const _prefsKey = 'hidden_home_cards';
  static final ValueNotifier<Set<String>> hiddenCardsNotifier = ValueNotifier<Set<String>>(<String>{});

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hiddenCardsNotifier.value = (prefs.getStringList(_prefsKey) ?? const []).toSet();
  }

  static bool isHidden(String cardId) => hiddenCardsNotifier.value.contains(cardId);

  static Future<void> setHidden(String cardId, bool hidden) async {
    final next = {...hiddenCardsNotifier.value};
    if (hidden) {
      next.add(cardId);
    } else {
      next.remove(cardId);
    }
    hiddenCardsNotifier.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, next.toList());
  }
}
