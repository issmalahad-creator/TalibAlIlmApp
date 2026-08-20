import 'package:flutter/material.dart';

import '../screens/activities_screen.dart';
import '../screens/book_screen.dart';
import '../screens/completion_goals_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/hadith_screen.dart';
import '../screens/knowledge_review_screen.dart';
import '../screens/personal_library_screen.dart';
import '../screens/prayer_times_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/qibla_screen.dart';
import '../screens/quran_browse_screen.dart';
import '../screens/quran_search_screen.dart';
import '../screens/tajweed_screen.dart';
import '../screens/tasbih_screen.dart';

class CompanionNavigationTarget {
  final List<String> names;
  final String displayName;
  final WidgetBuilder builder;
  const CompanionNavigationTarget({required this.names, required this.displayName, required this.builder});
}

/// "علّمه كل الكلمات المكتوبة في التطبيق... اعطه القدرة للذهاب الى ذلك
/// المكان وبس" (Ismail, 2026-08-18) — a name→screen registry so the
/// companion chat can actually navigate somewhere, not just talk about it.
/// Deliberately scoped to real, named features a student would naturally
/// ask for by name — not every screen in the app (many, like a specific
/// tafsir-source picker, aren't things anyone says "افتح ال..." to).
/// `names` are match candidates (checked via substring after
/// normalization in `companion_chat_session.dart`); `displayName` is what
/// gets echoed back in the confirmation reply. Each list mixes Arabic and
/// English names in one place (2026-08-21, universal language layer batch
/// 2) rather than a parallel English-only list — matching intent match
/// happens on whichever the student actually typed, regardless of the
/// app's current UI language.
const companionNavigationTargets = <CompanionNavigationTarget>[
  CompanionNavigationTarget(
    names: ['القبلة', 'القبله', 'اتجاه القبلة', 'qibla', 'qiblah'],
    displayName: 'القبلة',
    builder: _qibla,
  ),
  CompanionNavigationTarget(
    names: ['مواقيت الصلاة', 'مواعيد الصلاة', 'اوقات الصلاة', 'prayer times'],
    displayName: 'مواقيت الصلاة',
    builder: _prayerTimes,
  ),
  CompanionNavigationTarget(
    names: ['التسبيح', 'عداد التسبيح', 'المسبحة', 'tasbih', 'dhikr counter'],
    displayName: 'التسبيح',
    builder: _tasbih,
  ),
  CompanionNavigationTarget(
    names: ['الاحاديث', 'الحديث', 'الأربعين النووية', 'hadith', 'nawawi'],
    displayName: 'الأحاديث',
    builder: _hadith,
  ),
  CompanionNavigationTarget(
    names: ['التجويد', 'احكام التجويد', 'tajweed'],
    displayName: 'التجويد',
    builder: _tajweed,
  ),
  CompanionNavigationTarget(
    names: ['القران', 'المصحف', 'تصفح القران', 'فهرس السور', 'quran', 'mushaf'],
    displayName: 'القرآن',
    builder: _quranBrowse,
  ),
  CompanionNavigationTarget(
    names: ['البحث في القران', 'ابحث في القران', 'بحث القران', 'search quran', 'quran search'],
    displayName: 'البحث في القرآن',
    builder: _quranSearch,
  ),
  CompanionNavigationTarget(
    names: ['المراجعة', 'مراجعتي', 'المستحقات', 'review', 'my review'],
    displayName: 'المراجعة',
    builder: _knowledgeReview,
  ),
  CompanionNavigationTarget(
    names: ['الاهداف', 'أهدافي', 'خطة الختم', 'اهداف الختم', 'goals', 'completion plan'],
    displayName: 'الأهداف',
    builder: _completionGoals,
  ),
  CompanionNavigationTarget(
    names: ['المكتبة', 'مكتبتي', 'كتبي', 'library', 'my books'],
    displayName: 'المكتبة',
    builder: _personalLibrary,
  ),
  CompanionNavigationTarget(
    names: ['ملفي الشخصي', 'الملف الشخصي', 'الاعدادات', 'الإعدادات', 'profile', 'settings'],
    displayName: 'الملف الشخصي',
    builder: _profile,
  ),
  CompanionNavigationTarget(
    names: ['الانشطة', 'أنشطتي', 'activities'],
    displayName: 'الأنشطة',
    builder: _activities,
  ),
  CompanionNavigationTarget(
    names: ['الكتاب', 'الرئيسية للكتاب', 'book'],
    displayName: 'الكتاب',
    builder: _book,
  ),
  CompanionNavigationTarget(
    names: ['اهدافي اليومية', 'الاهداف اليومية', 'daily goals'],
    displayName: 'الأهداف',
    builder: _goals,
  ),
];

Widget _qibla(BuildContext context) => const QiblaScreen();
Widget _prayerTimes(BuildContext context) => const PrayerTimesScreen();
Widget _tasbih(BuildContext context) => const TasbihScreen();
Widget _hadith(BuildContext context) => const HadithScreen();
Widget _tajweed(BuildContext context) => const TajweedScreen();
Widget _quranBrowse(BuildContext context) => const QuranBrowseScreen();
Widget _quranSearch(BuildContext context) => const QuranSearchScreen();
Widget _knowledgeReview(BuildContext context) => const KnowledgeReviewScreen();
Widget _completionGoals(BuildContext context) => const CompletionGoalsScreen();
Widget _personalLibrary(BuildContext context) => const PersonalLibraryScreen();
Widget _profile(BuildContext context) => const ProfileScreen();
Widget _activities(BuildContext context) => const ActivitiesScreen();
Widget _book(BuildContext context) => const BookScreen();
Widget _goals(BuildContext context) => const GoalsScreen();
