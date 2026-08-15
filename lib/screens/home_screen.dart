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
import '../repositories/profile_repository.dart';
import '../services/book_content_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../utils/month.dart';
import '../widgets/animated_banner.dart';
import '../widgets/category_pill.dart';
import 'add_task_screen.dart';
import 'daily_tasks_screen.dart';
import 'hifz_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSubmitReportTap;
  const HomeScreen({super.key, this.onSubmitReportTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _activityRepo = ActivityRepository();
  final _goalRepo = GoalRepository();
  final _profileRepo = ProfileRepository();
  final _taskRepo = DailyTaskRepository();
  final _notificationService = NotificationService();
  final _syncService = SyncService();
  final _bookContentService = BookContentService();
  final _hifzRepo = HifzRepository();

  List<ActivityEntry> _recentActivities = [];
  List<Goal> _goals = [];
  List<DailyTask> _todayTasks = [];
  String _fullName = '';
  bool _submittedThisMonth = false;
  bool _loading = true;
  int _hifzMemorizedCount = 0;
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
    final submitted = await _syncService.hasSubmittedForMonth(currentMonth());
    final todayTasks = await _taskRepo.forDate(todayDate());
    final hifzMemorized = await _hifzRepo.memorizedSurahNumbers();
    if (!mounted) return;
    setState(() {
      _recentActivities = entries.take(5).toList();
      _goals = goals;
      _todayTasks = todayTasks;
      _fullName = profile.fullName;
      _submittedThisMonth = submitted;
      _hifzMemorizedCount = hifzMemorized.length;
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
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  _GreetingHeader(
                    name: _fullName.isEmpty ? 'الداعية' : _fullName,
                    onAvatarTap: () async {
                      await Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      _load();
                    },
                    onHelpTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const OnboardingScreen(reviewMode: true))),
                  ),
                  if (_banner != null) ...[
                    const SizedBox(height: 16),
                    AnimatedBanner(imageUrl: _banner!.url, caption: _banner!.caption),
                  ],
                  const SizedBox(height: 20),
                  _ProgressCard(percent: percent, month: monthLabel(currentMonth()), goals: _goals),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('مهام اليوم', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final changed = await Navigator.push<bool>(
                              context, MaterialPageRoute(builder: (_) => const DailyTasksScreen()));
                          if (changed == true) _load();
                        },
                        child: const Text('عرض الكل'),
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
                        label: const Text('إضافة مهمة لليوم'),
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
                      Text('آخر الأنشطة', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_recentActivities.isEmpty)
                    _EmptyHint(text: 'لم تُسجَّل أي أنشطة هذا الشهر بعد')
                  else
                    ..._recentActivities.map((e) => _ActivityRow(entry: e)),
                  const SizedBox(height: 16),
                  _HifzCard(
                    memorizedCount: _hifzMemorizedCount,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const HifzScreen()));
                      _load();
                    },
                  ),
                  const SizedBox(height: 24),
                  _SubmitReportCard(
                    submitted: _submittedThisMonth,
                    onTap: widget.onSubmitReportTap,
                  ),
                ],
              ),
            ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final String name;
  final VoidCallback onAvatarTap;
  final VoidCallback? onHelpTap;
  const _GreetingHeader({required this.name, required this.onAvatarTap, this.onHelpTap});

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
              name.isNotEmpty ? name.substring(0, 1) : 'د',
              style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مرحباً 👋 $name',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 2),
              const Text('كل إنجاز جديد يقربك من هدفك!',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
        if (onHelpTap != null)
          IconButton(
            onPressed: onHelpTap,
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.textMuted),
            tooltip: 'شرح استخدام التطبيق',
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int percent;
  final String month;
  final List<Goal> goals;
  const _ProgressCard({required this.percent, required this.month, required this.goals});

  @override
  Widget build(BuildContext context) {
    final completed = goals.where((g) => g.isComplete).length;
    final remaining = goals.length - completed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(22),
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
                Text('تقدم شهر $month',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 6),
                const Text('استمر على الطريق الصحيح لتحقيق أهدافك',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                if (goals.isNotEmpty)
                  Row(
                    children: [
                      _MiniStat(value: '$completed', label: 'مكتملة', icon: Icons.check_circle, color: AppColors.primary),
                      const SizedBox(width: 18),
                      _MiniStat(value: '$remaining', label: 'متبقية', icon: Icons.hourglass_bottom, color: AppColors.textMuted),
                    ],
                  )
                else
                  const Text('أضف أهدافاً لهذا الشهر لمتابعة تقدمك',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
  const _HifzCard({required this.memorizedCount, required this.onTap});

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
                  const Text('حفظ القرآن', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('$memorizedCount من ${quranSurahs.length} سورة ($percent%)',
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

class _SubmitReportCard extends StatelessWidget {
  final bool submitted;
  final VoidCallback? onTap;
  const _SubmitReportCard({required this.submitted, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إرسال التقرير الشهري',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 6),
                const Text('أرسل إنجازاتك لهذا الشهر عند توفر الإنترنت',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('إرسال الآن'),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(submitted ? Icons.check_circle : Icons.circle_outlined,
                        size: 14, color: submitted ? AppColors.primary : AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      submitted ? 'تم إرسال تقرير هذا الشهر' : 'لم يُرسل تقرير هذا الشهر بعد',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.cloud_upload_rounded, size: 44, color: AppColors.primary.withValues(alpha: 0.5)),
        ],
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
