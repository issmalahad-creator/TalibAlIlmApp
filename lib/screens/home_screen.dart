import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../models/activity_entry.dart';
import '../models/book_content.dart';
import '../models/daily_task.dart';
import '../models/goal.dart';
import '../repositories/activity_repository.dart';
import '../repositories/daily_task_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/hifz_repository.dart';
import '../repositories/memorization_repository.dart';
import '../l10n/basic_translations.dart';
import '../repositories/profile_repository.dart';
import '../services/book_content_service.dart';
import '../services/language_preference_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/depth.dart';
import '../utils/month.dart';
import '../widgets/animated_banner.dart';
import '../widgets/category_pill.dart';
import '../widgets/companion_card.dart';
import '../widgets/daily_companion_card.dart';
import '../widgets/daily_journey_card.dart';
import '../widgets/knowledge_review_entry_card.dart';
import '../widgets/nav_tile.dart';
import '../widgets/time_accountability_dashboard.dart';
import '../widgets/worship_coach_card.dart';
import 'worship_coach_screen.dart';
import 'add_task_screen.dart';
import 'daily_tasks_screen.dart';
import 'hifz_screen.dart';
import 'onboarding_screen.dart';
import 'adhkar_screen.dart';
import 'daily_session_screen.dart';
import 'prayer_times_screen.dart';
import 'tasbih_screen.dart';
import 'turath_library_screen.dart';
import 'profile_screen.dart';
import 'qibla_screen.dart';
import 'salah_tracker_screen.dart';
import 'audio_library_screen.dart';
import 'quran_reading_screen.dart';
import 'review_screen.dart';
import 'time_awareness_screen.dart';
import 'curriculum_map_screen.dart';
import '../widgets/loading_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _activityRepo = ActivityRepository();
  final _goalRepo = GoalRepository();
  final _profileRepo = ProfileRepository();
  final _taskRepo = DailyTaskRepository();
  final _notificationService = NotificationService();
  final _bookContentService = BookContentService();
  final _hifzRepo = HifzRepository();
  final _memorizationRepo = MemorizationRepository();
  List<ActivityEntry> _recentActivities = [];
  List<Goal> _goals = [];
  List<DailyTask> _todayTasks = [];
  String _fullName = '';
  bool _loading = true;
  int _hifzMemorizedCount = 0;
  int _reviewDueCount = 0;
  BannerInfo? _banner;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _activityRepo.forMonth(currentMonth());
    final goals = await _goalRepo.forMonth(currentMonth());
    final profile = await _profileRepo.get();
    final todayTasks = await _taskRepo.forDate(todayDate());
    final hifzMemorized = await _hifzRepo.memorizedSurahNumbers();
    final reviewDue = await _memorizationRepo.dueToday();
    if (!mounted) return;
    setState(() {
      _recentActivities = entries.take(5).toList();
      _goals = goals;
      _todayTasks = todayTasks;
      _fullName = profile.fullName;
      _hifzMemorizedCount = hifzMemorized.length;
      _reviewDueCount = reviewDue.length;
      _loading = false;
    });
    // Best-effort, non-blocking: the banner is a nice-to-have and must never
    // delay/hide the rest of the home screen if the network is unavailable.
    _bookContentService.fetch().then((feed) {
      if (!mounted) return;
      final b = feed.banner;
      final hasBanner = b != null && b.url.isNotEmpty;
      setState(() => _banner = hasBanner ? b : null);
    });
  }

  Future<void> _quickToggleTask(DailyTask task) async {
    if (task.checklist.isNotEmpty && !task.completed) {
      // Has a review checklist — open the full tasks screen instead of
      // silently completing without letting the student see it.
      final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const DailyTasksScreen()));
      if (changed == true) _load();
      return;
    }
    await _taskRepo.setCompleted(task.id!, !task.completed);
    if (!task.completed) await _notificationService.cancelTaskReminder(task.id!);
    _load();
  }

  double get _overallProgress {
    if (_goals.isNotEmpty) {
      final sum = _goals.fold<double>(0, (s, g) => s + g.progress);
      return sum / _goals.length;
    }
    // No goals set: fall back to a soft activity-count target so the ring
    // still means something.
    return (_recentActivities.length / 10).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_overallProgress * 100).round();
    // 2026-08-17 (Ismail: "أرى في الصفحة الرئيسية كلمات عربية بعد تغير
    // اللغة") — this `ValueListenableBuilder` used to wrap only the nav-grid
    // section; now wraps the ENTIRE page body so every widget below reads
    // the live `lang`, not just the ones that happened to be inside the old
    // narrower wrapper.
    return Scaffold(
      body: ValueListenableBuilder<String>(
        valueListenable: LanguagePreferenceService.languageNotifier,
        builder: (context, lang, _) => _loading
          ? AppLoadingView(icon: Icons.wb_sunny_outlined, message: basicText('home_loading_message', lang))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  _GreetingHeader(
                    name: _fullName.isEmpty ? basicText('default_user_name', lang) : _fullName,
                    greetingPrefix: basicText('home_greeting_prefix', lang),
                    subtitle: basicText('home_greeting_subtitle', lang),
                    helpTooltip: basicText('app_help_tooltip', lang),
                    onAvatarTap: () async {
                      await Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      _load();
                    },
                    onHelpTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const OnboardingScreen(reviewMode: true))),
                  ),
                  const SizedBox(height: 16),
                  _QuranHeroCard(
                    memorizedCount: _hifzMemorizedCount,
                    lang: lang,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranReadingScreen()));
                      _load();
                    },
                  ),
                  const SizedBox(height: 12),
                  const CompanionCard(),
                  DailyCompanionCard(
                    onOpenPrayerTimes: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
                    onOpenQibla: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
                  ),
                  const SizedBox(height: 12),
                  const DailyJourneyCard(),
                  const SizedBox(height: 12),
                  const KnowledgeReviewEntryCard(),
                  const SizedBox(height: 12),
                  WorshipCoachCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorshipCoachScreen())),
                  ),
                  const SizedBox(height: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const DailySessionScreen()));
                            _load();
                          },
                          icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                          label: Text(basicText('daily_session', lang)),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                        const SizedBox(height: 6),
                        NavGrid(items: [
                          NavTileData(
                            icon: Icons.access_time_outlined,
                            label: basicText('prayer_times', lang),
                            color: NavColors.blue,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
                          ),
                          NavTileData(
                            icon: Icons.explore_outlined,
                            label: basicText('qibla', lang),
                            color: NavColors.purple,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
                          ),
                          NavTileData(
                            icon: Icons.nights_stay_outlined,
                            label: basicText('adhkar', lang),
                            color: NavColors.indigo,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdhkarScreen())),
                          ),
                    NavTileData(
                      icon: Icons.mosque_outlined,
                      label: basicText('salah_companion', lang),
                      color: NavColors.teal,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahTrackerScreen())),
                    ),
                    NavTileData(
                      icon: Icons.podcasts_outlined,
                      label: basicText('audio_library', lang),
                      color: NavColors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioLibraryScreen())),
                    ),
                    NavTileData(
                      icon: Icons.map_rounded,
                      label: basicText('curriculum_map', lang),
                      color: NavColors.gold,
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const CurriculumMapScreen()));
                        _load();
                      },
                    ),
                    NavTileData(
                      icon: Icons.touch_app_outlined,
                      label: basicText('tasbih', lang),
                      color: NavColors.cyan,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbihScreen())),
                    ),
                    NavTileData(
                      icon: Icons.local_library_outlined,
                      label: basicText('turath_library_title', lang),
                      color: NavColors.brown,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TurathLibraryScreen())),
                    ),
                        ]),
                      ],
                    ),
                  if (_banner != null) ...[
                    const SizedBox(height: 16),
                    AnimatedBanner(imageUrl: _banner!.url, caption: _banner!.caption),
                  ],
                  const SizedBox(height: 16),
                  TimeAccountabilityDashboard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeAwarenessScreen())),
                  ),
                  _EndOfDayCompanionCard(
                    lang: lang,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeAwarenessScreen())),
                  ),
                  const SizedBox(height: 20),
                  _ProgressCard(percent: percent, month: monthLabel(currentMonth()), goals: _goals, lang: lang),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(basicText('today_tasks_label', lang), style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final changed = await Navigator.push<bool>(
                              context, MaterialPageRoute(builder: (_) => const DailyTasksScreen()));
                          if (changed == true) _load();
                        },
                        child: Text(basicText('view_all', lang)),
                      ),
                    ],
                  ),
                  if (_todayTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: TextButton.icon(
                        onPressed: () async {
                          final added = await Navigator.push<bool>(
                              context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
                          if (added == true) _load();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(basicText('add_task_today', lang)),
                      ),
                    )
                  else
                    ..._todayTasks.map((t) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            leading: Checkbox(value: t.completed, onChanged: (_) => _quickToggleTask(t)),
                            title: Text(t.title,
                                style: TextStyle(
                                    decoration: t.completed ? TextDecoration.lineThrough : null,
                                    color: t.completed ? AppColors.textMuted : AppColors.textDark,
                                    fontWeight: FontWeight.w600)),
                            subtitle: t.time != null ? Text(t.time!, style: const TextStyle(fontSize: 11)) : null,
                          ),
                        )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(basicText('recent_activities_label', lang), style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_recentActivities.isEmpty)
                    _EmptyHint(text: basicText('no_activities_this_month', lang))
                  else
                    ..._recentActivities.map((e) => _ActivityRow(entry: e)),
                  const SizedBox(height: 16),
                  _HifzCard(
                    memorizedCount: _hifzMemorizedCount,
                    lang: lang,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const HifzScreen()));
                      _load();
                    },
                  ),
                  const SizedBox(height: 10),
                  _ReviewCard(
                    dueCount: _reviewDueCount,
                    lang: lang,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen()));
                      _load();
                    },
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

/// "نهاية اليوم" companion placement — Ismail's 2026-08-17 spec example
/// ("انتهت رحلة اليوم 🌙 ماذا أنجزت اليوم؟"). Time-gated (evening only),
/// not the rule engine (`companion_engine.dart`) — this is about the time
/// of day, not the student's overall state, same "static per-context tip"
/// idiom as `guided_session_screen.dart`'s phase tips.
class _EndOfDayCompanionCard extends StatelessWidget {
  final VoidCallback onTap;
  final String lang;
  const _EndOfDayCompanionCard({required this.onTap, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (DateTime.now().hour < 20) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Row(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(basicText('end_of_day_title', lang), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(basicText('end_of_day_subtitle', lang), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "بطاقة القرآن" — Ismail's 2026-08-17 request: the Quran entry point was
/// a plain small `OutlinedButton` at the very bottom of the home screen,
/// which felt wrong for "أكبر إنجازاتنا" (our biggest achievement). Moved
/// to the top of the page ("صدر الصفحة"), and made deliberately the most
/// ornamented element on the home screen ("أكثر شيء مدلّع في التصميم") —
/// gold ring border, a faint oversized watermark glyph, a pulsing glow,
/// and a slow diagonal shimmer sweep. All driven by the same
/// `AnimationController` (no extra tickers), same "BoxShadow
/// blur/spread oscillating" spirit as the Qibla compass's "light up when
/// facing Qibla" glow built earlier this session, just layered further.
class _QuranHeroCard extends StatefulWidget {
  final VoidCallback onTap;
  final int memorizedCount;
  final String lang;
  const _QuranHeroCard({required this.onTap, required this.memorizedCount, required this.lang});

  @override
  State<_QuranHeroCard> createState() => _QuranHeroCardState();
}

class _QuranHeroCardState extends State<_QuranHeroCard> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD9A441);
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        // Glow pulses on a half-cycle, shimmer sweeps across on the full cycle.
        final pulse = (1 - (2 * _glowController.value - 1).abs());
        final glow = 0.3 + (pulse * 0.35);
        final shimmerX = -1.2 + _glowController.value * 2.4;
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: widget.onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: gold.withValues(alpha: 0.7), width: 2),
              boxShadow: [
                BoxShadow(color: gold.withValues(alpha: glow), blurRadius: 28, spreadRadius: 3),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl - 2),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(Icons.auto_stories_rounded, size: 130, color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(shimmerX, 0),
                      child: Transform.rotate(
                        angle: 0.5,
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
            ),
          ),
        );
      },
      child: Row(
        children: [
          const Icon(Icons.auto_stories_rounded, color: gold, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(basicText('quran_hero_title', widget.lang), style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(basicText('quran_hero_subtitle', widget.lang), style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                if (widget.memorizedCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: gold.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(999)),
                    child: Text('🔥 ${widget.memorizedCount} ${basicText('pages_memorized_so_far', widget.lang)}', style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_left_rounded, color: gold, size: 28),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final String name;
  final String greetingPrefix;
  final String subtitle;
  final String helpTooltip;
  final VoidCallback onAvatarTap;
  final VoidCallback? onHelpTap;
  const _GreetingHeader({
    required this.name,
    required this.greetingPrefix,
    required this.subtitle,
    required this.helpTooltip,
    required this.onAvatarTap,
    this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1) : '؟',
              style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greetingPrefix $name',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
        if (onHelpTap != null)
          IconButton(
            onPressed: onHelpTap,
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.textMuted),
            tooltip: helpTooltip,
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int percent;
  final String month;
  final List<Goal> goals;
  final String lang;
  const _ProgressCard({required this.percent, required this.month, required this.goals, required this.lang});

  @override
  Widget build(BuildContext context) {
    final completed = goals.where((g) => g.isComplete).length;
    final remaining = goals.length - completed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(22),
        // "نظام التصميم ثلاثي الأبعاد" (quirky-gliding-shell.md's global
        // design-language plan) — first real-screen application of the
        // new `DepthShadows` tokens, proving the pattern on the الرئيسية
        // (Dashboard) section before extending to more screens.
        boxShadow: DepthShadows.floating(DepthPalette.dashboard.accent),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 9,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                Text('$percent%',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${basicText('month_progress_label', lang)} $month',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text(basicText('stay_on_track_goals', lang),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                if (goals.isNotEmpty)
                  Row(
                    children: [
                      _MiniStat(value: '$completed', label: basicText('completed_label', lang), icon: Icons.check_circle, color: AppColors.primary),
                      const SizedBox(width: 18),
                      _MiniStat(value: '$remaining', label: basicText('remaining_label', lang), icon: Icons.hourglass_bottom, color: AppColors.textMuted),
                    ],
                  )
                else
                  Text(basicText('add_goals_this_month', lang),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _MiniStat({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text('$value $label', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityEntry entry;
  const _ActivityRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(entry.date, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CategoryPill(category: entry.category),
          ],
        ),
      ),
    );
  }
}

class _HifzCard extends StatelessWidget {
  final int memorizedCount;
  final VoidCallback onTap;
  final String lang;
  const _HifzCard({required this.memorizedCount, required this.onTap, required this.lang});

  @override
  Widget build(BuildContext context) {
    final percent = quranSurahs.isEmpty ? 0 : ((memorizedCount / quranSurahs.length) * 100).round();
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.divider)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(basicText('quran_memorization_label', lang), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('$memorizedCount ${basicText('of_label', lang)} ${quranSurahs.length} ${basicText('surah_unit_label', lang)} ($percent%)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int dueCount;
  final VoidCallback onTap;
  final String lang;
  const _ReviewCard({required this.dueCount, required this.onTap, required this.lang});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.divider)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(basicText('review_label', lang), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(
                    dueCount > 0 ? '$dueCount ${basicText('pages_due_today', lang)}' : basicText('no_reviews_due_today', lang),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
    );
  }
}
