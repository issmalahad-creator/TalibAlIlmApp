import 'package:flutter/material.dart';

import '../screens/activities_screen.dart';
import '../screens/adab_screen.dart';
import '../screens/adhkar_screen.dart';
import '../screens/akhlaq/akhlaq_home_screen.dart';
import '../screens/application_screen.dart';
import '../screens/arabic_curriculum_screen.dart';
import '../screens/audio_library_screen.dart';
import '../screens/certificates_screen.dart';
import '../screens/companion_chat_screen.dart';
import '../screens/completion_goals_screen.dart';
import '../screens/curriculum_map_screen.dart';
import '../screens/daily_session_screen.dart';
import '../screens/daily_tasks_screen.dart';
import '../screens/downloads_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/hadith_screen.dart';
import '../screens/hifz_schedule_screen.dart';
import '../screens/hifz_screen.dart';
import '../screens/journey_screen.dart';
import '../screens/knowledge_review_screen.dart';
import '../screens/life_plan_screen.dart';
import '../screens/madarij_screen.dart';
import '../screens/medications_screen.dart';
import '../screens/mosque/mosques_screen.dart';
import '../screens/mushaf_semantic_reader_screen.dart';
import '../screens/new_muslim_guide_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../screens/personal_accountability_screen.dart';
import '../screens/personal_library_screen.dart';
import '../screens/prayer_times_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/qibla_screen.dart';
import '../screens/quran_browse_screen.dart';
import '../screens/quran_learning/sources_screen.dart';
import '../screens/quran_learning/topic_index_screen.dart';
import '../screens/quran_notebook_home_screen.dart';
import '../screens/quran_search_screen.dart';
import '../screens/reading_stats_screen.dart';
import '../screens/recitation_mistakes_screen.dart';
import '../screens/review_screen.dart';
import '../screens/salah_tracker_screen.dart';
import '../screens/support_screen.dart';
import '../screens/tajweed_screen.dart';
import '../screens/tasbih_screen.dart';
import '../screens/time_awareness_screen.dart';
import '../screens/turath_library_screen.dart';
import '../screens/understanding_screen.dart';
import '../screens/wasitiyyah_screen.dart';
import '../screens/wird_screen.dart';
import '../screens/worship_coach_screen.dart';
import '../screens/zad_almaad_screen.dart';

/// The drawer's sections, in order.
enum AppFeatureGroup { quran, worship, health, knowledge, life, community, settings }

/// One place every feature of the app is listed — read by the side menu
/// (`AppDrawer`) and by the companion's «افتح …» navigation, so a new screen
/// added here is reachable from both at once. The title is the
/// `feat_<id>` key in `basic_translations.dart`; [names] are extra match
/// words for the companion (Arabic and English, checked after
/// normalization, so hamza/ta-marbuta variants need not be listed).
class AppFeature {
  final String id;
  final AppFeatureGroup group;
  final IconData icon;
  final List<String> names;
  final WidgetBuilder builder;
  const AppFeature(this.id, this.group, this.icon, this.names, this.builder);

  String get titleKey => 'feat_$id';
}

final appFeatures = <AppFeature>[
  // ---- القرآن
  AppFeature('mushaf', AppFeatureGroup.quran, Icons.auto_stories_rounded, const ['المصحف', 'القران', 'اقرا القران', 'quran', 'mushaf'], (_) => const MushafSemanticReaderScreen()),
  AppFeature('quran_index', AppFeatureGroup.quran, Icons.format_list_numbered_rtl_rounded, const ['فهرس السور', 'تصفح القران', 'السور', 'surah list', 'quran index'], (_) => const QuranBrowseScreen()),
  AppFeature('quran_search', AppFeatureGroup.quran, Icons.manage_search_rounded, const ['البحث في القران', 'ابحث في القران', 'بحث القران', 'search quran', 'quran search'], (_) => const QuranSearchScreen()),
  AppFeature('hifz', AppFeatureGroup.quran, Icons.psychology_alt_outlined, const ['الحفظ', 'حفظ القران', 'حفظي', 'خريطتي', 'hifz', 'memorization'], (_) => const HifzScreen()),
  AppFeature('hifz_schedule', AppFeatureGroup.quran, Icons.calendar_month_outlined, const ['جدول الحفظ', 'خطة الحفظ', 'hifz schedule', 'memorization plan'], (_) => const HifzScheduleScreen()),
  AppFeature('review', AppFeatureGroup.quran, Icons.replay_circle_filled_outlined, const ['مراجعة الحفظ', 'المراجعه', 'review hifz', 'review'], (_) => const ReviewScreen()),
  AppFeature('knowledge_review', AppFeatureGroup.quran, Icons.style_outlined, const ['مراجعتي', 'المستحقات', 'بطاقات المراجعة', 'my review', 'due cards'], (_) => const KnowledgeReviewScreen()),
  AppFeature('recitation_mistakes', AppFeatureGroup.quran, Icons.rule_rounded, const ['سجل الاخطاء', 'اخطاء التسميع', 'اخطائي', 'mistakes log', 'recitation mistakes'], (_) => const RecitationMistakesScreen()),
  AppFeature('tajweed', AppFeatureGroup.quran, Icons.record_voice_over_outlined, const ['التجويد', 'احكام التجويد', 'tajweed'], (_) => const TajweedScreen()),
  AppFeature('understanding', AppFeatureGroup.quran, Icons.lightbulb_outline_rounded, const ['الفهم', 'فهم القران', 'التفسير', 'understanding', 'tafsir'], (_) => const UnderstandingScreen()),
  AppFeature('application', AppFeatureGroup.quran, Icons.volunteer_activism_outlined, const ['التطبيق العملي', 'العمل بالقران', 'application', 'apply'], (_) => const ApplicationScreen()),
  AppFeature('quran_notebook', AppFeatureGroup.quran, Icons.edit_note_rounded, const ['دفتر الايات', 'دفتري', 'ملاحظاتي', 'notebook', 'my notes'], (_) => const QuranNotebookHomeScreen()),
  AppFeature('topics', AppFeatureGroup.quran, Icons.account_tree_outlined, const ['موضوعات القران', 'الموضوعات', 'فهرس المعرفة', 'topics', 'knowledge index'], (_) => const TopicIndexScreen()),
  AppFeature('journey', AppFeatureGroup.quran, Icons.route_outlined, const ['رحلتي', 'الرحلة', 'خطة الرحلة', 'journey', 'my journey'], (_) => const JourneyScreen()),
  AppFeature('daily_session', AppFeatureGroup.quran, Icons.wb_sunny_outlined, const ['جلسة اليوم', 'الجلسة اليومية', 'daily session', 'today session'], (_) => const DailySessionScreen()),
  AppFeature('sources', AppFeatureGroup.quran, Icons.verified_outlined, const ['عن المصادر', 'المصادر', 'sources'], (_) => const SourcesScreen()),
  // ---- العبادة
  AppFeature('prayer_times', AppFeatureGroup.worship, Icons.access_time_outlined, const ['مواقيت الصلاة', 'مواعيد الصلاة', 'اوقات الصلاة', 'الاذان', 'prayer times', 'adhan'], (_) => const PrayerTimesScreen()),
  AppFeature('qibla', AppFeatureGroup.worship, Icons.explore_outlined, const ['القبلة', 'اتجاه القبلة', 'qibla', 'qiblah'], (_) => const QiblaScreen()),
  AppFeature('adhkar', AppFeatureGroup.worship, Icons.nights_stay_outlined, const ['الاذكار', 'اذكار الصباح', 'اذكار المساء', 'حصن المسلم', 'adhkar', 'azkar'], (_) => const AdhkarScreen()),
  AppFeature('tasbih', AppFeatureGroup.worship, Icons.touch_app_outlined, const ['التسبيح', 'عداد التسبيح', 'المسبحة', 'tasbih', 'dhikr counter'], (_) => const TasbihScreen()),
  AppFeature('salah', AppFeatureGroup.worship, Icons.mosque_outlined, const ['رفيق الصلاة', 'متابعة الصلاة', 'صلاتي', 'salah tracker', 'my prayers'], (_) => const SalahTrackerScreen()),
  AppFeature('worship_coach', AppFeatureGroup.worship, Icons.self_improvement_rounded, const ['مدرب العبادة', 'العبادة', 'worship coach'], (_) => const WorshipCoachScreen()),
  AppFeature('wird', AppFeatureGroup.worship, Icons.menu_book_outlined, const ['الورد', 'وردي', 'الختمة', 'ختمتي', 'wird', 'khatma'], (_) => const WirdScreen()),
  // ---- الصحة
  AppFeature('medications', AppFeatureGroup.health, Icons.medication_outlined, const ['علاجاتي', 'العلاج', 'الدواء', 'ادويتي', 'منبه الادوية', 'المضاد الحيوي', 'medicine', 'medications', 'pills'], (_) => const MedicationsScreen()),
  // ---- العلم والمكتبة
  AppFeature('hadith', AppFeatureGroup.knowledge, Icons.format_quote_rounded, const ['الاحاديث', 'الحديث', 'الاربعين النووية', 'hadith', 'nawawi'], (_) => const HadithScreen()),
  AppFeature('turath_library', AppFeatureGroup.knowledge, Icons.local_library_outlined, const ['مكتبة التراث', 'التراث', 'الكتب', 'turath', 'books library'], (_) => const TurathLibraryScreen()),
  AppFeature('personal_library', AppFeatureGroup.knowledge, Icons.collections_bookmark_outlined, const ['مكتبتي', 'كتبي', 'my library', 'my books'], (_) => const PersonalLibraryScreen()),
  AppFeature('audio_library', AppFeatureGroup.knowledge, Icons.podcasts_outlined, const ['المكتبة الصوتية', 'الدروس الصوتية', 'المحاضرات', 'audio library', 'lectures'], (_) => const AudioLibraryScreen()),
  AppFeature('curriculum_map', AppFeatureGroup.knowledge, Icons.map_rounded, const ['خريطة المنهج', 'المنهج', 'curriculum', 'curriculum map'], (_) => const CurriculumMapScreen()),
  AppFeature('arabic', AppFeatureGroup.knowledge, Icons.translate_rounded, const ['العربية', 'تعلم العربية', 'النحو', 'arabic', 'learn arabic'], (_) => const ArabicCurriculumScreen()),
  AppFeature('wasitiyyah', AppFeatureGroup.knowledge, Icons.shield_moon_outlined, const ['العقيدة الواسطية', 'الواسطية', 'العقيدة', 'aqeedah', 'wasitiyyah'], (_) => const WasitiyyahScreen()),
  AppFeature('zad_almaad', AppFeatureGroup.knowledge, Icons.history_edu_outlined, const ['زاد المعاد', 'السيرة', 'zad al maad', 'seerah'], (_) => const ZadAlMaadScreen()),
  AppFeature('madarij', AppFeatureGroup.knowledge, Icons.stairs_outlined, const ['مدارج السالكين', 'مدارج', 'madarij'], (_) => const MadarijScreen()),
  AppFeature('adab', AppFeatureGroup.knowledge, Icons.emoji_people_outlined, const ['الادب', 'باب الادب', 'الاداب', 'adab', 'manners'], (_) => const AdabScreen()),
  AppFeature('akhlaq', AppFeatureGroup.knowledge, Icons.spa_outlined, const ['الاخلاق', 'حسن الخلق', 'akhlaq', 'character'], (_) => const AkhlaqHomeScreen()),
  AppFeature('new_muslim', AppFeatureGroup.knowledge, Icons.waving_hand_outlined, const ['دليل المسلم الجديد', 'المسلم الجديد', 'new muslim'], (_) => const NewMuslimGuideScreen()),
  AppFeature('certificates', AppFeatureGroup.knowledge, Icons.workspace_premium_outlined, const ['الشهادات', 'شهاداتي', 'certificates'], (_) => const CertificatesScreen()),
  // ---- حياتي وخطتي
  AppFeature('life_plan', AppFeatureGroup.life, Icons.eco_outlined, const ['محرك الحياة', 'خطة الحياة', 'يومي', 'life engine', 'life plan'], (_) => const LifePlanScreen()),
  AppFeature('daily_tasks', AppFeatureGroup.life, Icons.task_alt_rounded, const ['المهام', 'مهامي', 'مهام اليوم', 'tasks', 'my tasks'], (_) => const DailyTasksScreen()),
  AppFeature('activities', AppFeatureGroup.life, Icons.checklist_rounded, const ['الانشطة', 'انشطتي', 'activities'], (_) => const ActivitiesScreen()),
  AppFeature('goals', AppFeatureGroup.life, Icons.flag_rounded, const ['الاهداف', 'اهدافي', 'الاهداف الشهرية', 'goals', 'my goals'], (_) => const GoalsScreen()),
  AppFeature('completion_goals', AppFeatureGroup.life, Icons.emoji_events_outlined, const ['خطة الختم', 'اهداف الختم', 'completion plan'], (_) => const CompletionGoalsScreen()),
  AppFeature('time_awareness', AppFeatureGroup.life, Icons.hourglass_bottom_rounded, const ['الوقت', 'وقتي', 'سجل الوقت', 'time', 'time log'], (_) => const TimeAwarenessScreen()),
  AppFeature('accountability', AppFeatureGroup.life, Icons.fact_check_outlined, const ['المحاسبة', 'حاسب نفسك', 'محاسبة النفس', 'accountability'], (_) => const PersonalAccountabilityScreen()),
  AppFeature('reading_stats', AppFeatureGroup.life, Icons.insights_rounded, const ['احصائيات القراءة', 'احصائياتي', 'reading stats', 'statistics'], (_) => const ReadingStatsScreen()),
  // ---- المجتمع والرفيق
  AppFeature('mosques', AppFeatureGroup.community, Icons.location_city_outlined, const ['المساجد', 'مساجدنا', 'مسجدي', 'mosques', 'my mosque'], (_) => const MosquesScreen()),
  AppFeature('companion_chat', AppFeatureGroup.community, Icons.forum_outlined, const ['الرفيق', 'محادثة الرفيق', 'companion', 'chat'], (_) => const CompanionChatScreen()),
  // ---- الإعدادات
  AppFeature('profile', AppFeatureGroup.settings, Icons.person_outline_rounded, const ['ملفي الشخصي', 'الملف الشخصي', 'الاعدادات', 'اللغة', 'profile', 'settings', 'language'], (_) => const ProfileScreen()),
  AppFeature('notification_settings', AppFeatureGroup.settings, Icons.notifications_outlined, const ['اعدادات التنبيهات', 'التنبيهات', 'الاشعارات', 'notifications', 'notification settings'], (_) => const NotificationSettingsScreen()),
  AppFeature('downloads', AppFeatureGroup.settings, Icons.download_for_offline_outlined, const ['التنزيلات', 'التحميلات', 'المساحة', 'downloads', 'storage'], (_) => const DownloadsScreen()),
  AppFeature('support', AppFeatureGroup.settings, Icons.favorite_border_rounded, const ['الدعم', 'تواصل معنا', 'support', 'contact'], (_) => const SupportScreen()),
];
