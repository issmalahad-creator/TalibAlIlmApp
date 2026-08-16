import 'package:flutter/material.dart';

import '../models/personal_book.dart';
import '../repositories/book_repository.dart';
import '../repositories/completion_goal_repository.dart';
import '../repositories/personal_book_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_display.dart';
import '../utils/hijri_date.dart';

/// "خطط ختمي" — QURAN_COMPANION_ROADMAP.md section 4.15. Create and track
/// completion plans for Quran reading, Quran memorization, or any book —
/// one shared screen, not one per content type.
class CompletionGoalsScreen extends StatefulWidget {
  const CompletionGoalsScreen({super.key});

  @override
  State<CompletionGoalsScreen> createState() => _CompletionGoalsScreenState();
}

/// (content_type, book_ref, label, total_units) — the fixed set of
/// content this planner currently knows how to track. Add a row here when
/// a new book pillar ships. Personal-library books are appended
/// dynamically (see `_openNewGoalSheet`) since they vary per student.
const _fixedGoalOptions = [
  ('quran_reading', null, 'ختمة قراءة القرآن', 604),
  ('quran_memorization', null, 'ختم حفظ القرآن', 604),
  ('book', 'zad_almaad', 'زاد المعاد', 65),
  ('book', 'madarij', 'مدارج السالكين', 71),
  ('book', 'wasitiyyah', 'العقيدة الواسطية', 82),
  ('book', 'nawawi_hadith', 'الأربعين النووية', 42),
];

class _CompletionGoalsScreenState extends State<CompletionGoalsScreen> {
  final _repo = CompletionGoalRepository();
  final _notificationService = NotificationService();
  List<CompletionGoalStatus> _statuses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final goals = await _repo.activeGoals();
    final statuses = await Future.wait(goals.map(_repo.statusFor));
    await _syncReminders(statuses);
    if (!mounted) return;
    setState(() {
      _statuses = statuses;
      _loading = false;
    });
  }

  /// Keeps each active goal's daily reminder in sync with real progress:
  /// cancels it the moment today's target is already met (or the goal is
  /// fully done), otherwise (re)schedules it with the current KPI so the
  /// wording never goes stale after a reschedule. Safe to call on every
  /// load — scheduling is idempotent (cancel-then-schedule under the same id).
  Future<void> _syncReminders(List<CompletionGoalStatus> statuses) async {
    for (final s in statuses) {
      final doneToday = s.remaining == 0 || await _repo.hasProgressedToday(s.goal);
      if (doneToday) {
        await _notificationService.cancelGoalReminder(s.goal.id);
      } else {
        final target = s.recalculatedDailyTarget.ceil().clamp(1, 1 << 30);
        await _notificationService.scheduleGoalReminder(
          goalId: s.goal.id,
          goalTitle: s.goal.displayLabel,
          dailyTargetLabel: '$target ${s.goal.unitLabel} اليوم',
        );
      }
    }
  }

  /// Personal-library books that have a known page count (from having been
  /// opened at least once — `book_bookmarks` is populated by
  /// `BookViewerScreen`'s existing flutter_pdfview callbacks, not built new
  /// here). Books never opened yet are silently excluded rather than shown
  /// with a guessed page count.
  Future<List<(String, String?, String, int)>> _personalBookOptions() async {
    final books = await PersonalBookRepository().all();
    final bookRepo = BookRepository();
    final options = <(String, String?, String, int)>[];
    for (final book in books) {
      if (book.id == null) continue;
      final bookmark = await bookRepo.getBookmark('personal_${book.id}');
      if (bookmark != null && bookmark.totalPages > 0) {
        options.add(('personal_book', book.id.toString(), 'من مكتبتي: ${book.title}', bookmark.totalPages));
      }
    }
    return options;
  }

  Future<void> _openNewGoalSheet() async {
    final personalOptions = await _personalBookOptions();
    final allOptions = [..._fixedGoalOptions, ...personalOptions];
    var selected = allOptions.first;
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('خطة ختم جديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              DropdownButton<(String, String?, String, int)>(
                isExpanded: true,
                value: selected,
                items: allOptions
                    .map((o) => DropdownMenuItem(value: o, child: Text(o.$3, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setSheetState(() => selected = v!),
              ),
              if (personalOptions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'لإضافة كتاب من مكتبتك: افتحه مرة واحدة من "مكتبتي" أولًا حتى يُعرف عدد صفحاته',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text('الموعد المستهدف: ${formatDateForDisplay(hijriDateStringForDate(targetDate))}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setSheetState(() => targetDate = picked);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final (contentType, bookRef, _, totalUnits) = selected;
                  await _repo.create(
                    contentType: contentType,
                    bookRef: bookRef,
                    totalUnits: totalUnits,
                    targetDate: hijriDateStringForDate(targetDate),
                  );
                  if (context.mounted) Navigator.pop(context);
                  _load();
                },
                child: const Text('إنشاء الخطة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reschedule(CompletionGoalStatus s) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    await _repo.reschedule(s.goal.id, hijriDateStringForDate(picked));
    _load();
  }

  /// "مسح الخطة" (Ismail's request 2026-08-16) — `CompletionGoalRepository
  /// .abandon()` already existed (used nowhere in the UI until now). Marks
  /// the goal 'abandoned' rather than deleting the row, so past progress on
  /// the underlying content (pages memorized, book position, etc.) is
  /// untouched — only the plan/target itself goes away. Confirmed first
  /// since there's no UI path back to an abandoned goal.
  Future<void> _confirmAndDelete(CompletionGoalStatus s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح الخطة؟'),
        content: Text('سيُمسح "${s.goal.displayLabel}" ولن تُذكَّر بها بعد الآن. تقدّمك المُسجَّل لن يتأثر — يمكنك إنشاء خطة جديدة في أي وقت.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('مسح')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.abandon(s.goal.id);
    await _notificationService.cancelGoalReminder(s.goal.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطط ختمي')),
      floatingActionButton: FloatingActionButton(onPressed: _openNewGoalSheet, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _statuses.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('لا توجد خطط نشطة — أنشئ خطة جديدة بالزر أسفل الشاشة', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _statuses.length,
                  itemBuilder: (context, i) => _GoalCard(
                    status: _statuses[i],
                    onReschedule: () => _reschedule(_statuses[i]),
                    onDelete: () => _confirmAndDelete(_statuses[i]),
                  ),
                ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final CompletionGoalStatus status;
  final VoidCallback onReschedule;
  final VoidCallback onDelete;
  const _GoalCard({required this.status, required this.onReschedule, required this.onDelete});

  (Color, String) get _badge => switch (status.scheduleStatus) {
        ScheduleStatus.ahead => (AppColors.primary, 'متقدم عن الخطة 🌱'),
        ScheduleStatus.onTrack => (AppColors.primaryDark, 'بالضبط حسب الخطة'),
        ScheduleStatus.behind => (AppColors.textMuted, 'متأخر قليلًا عن الخطة'),
      };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _badge;
    final g = status.goal;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _GoalTitle(goal: g)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${status.currentPosition} من ${g.totalUnits} — باقي ${status.remaining}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            status.daysLeft > 0
                ? 'باقي ${status.daysLeft} يومًا — بمعدل ${status.recalculatedDailyTarget.toStringAsFixed(1)} يوميًا لإتمامها بالموعد'
                : 'انتهى الموعد المستهدف',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: onReschedule, child: const Text('أعِد جدولة الخطة', style: TextStyle(fontSize: 12))),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                label: const Text('مسح الخطة', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Resolves the real title for 'personal_book' goals (looked up live, since
/// `CompletionGoal` deliberately doesn't cache a title that could go stale
/// if the book is renamed/deleted) — every other content type already has
/// a fixed label via `CompletionGoal.displayLabel`.
class _GoalTitle extends StatelessWidget {
  final CompletionGoal goal;
  const _GoalTitle({required this.goal});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.w800, fontSize: 14);
    if (goal.contentType != 'personal_book') {
      return Text(goal.displayLabel, style: style);
    }
    return FutureBuilder<List<PersonalBook>>(
      future: PersonalBookRepository().all(),
      builder: (context, snapshot) {
        final books = snapshot.data;
        if (books == null) return Text(goal.displayLabel, style: style);
        final match = books.where((b) => b.id.toString() == goal.bookRef);
        final title = match.isEmpty ? 'كتاب محذوف من مكتبتي' : match.first.title;
        return Text('من مكتبتي: $title', style: style, overflow: TextOverflow.ellipsis);
      },
    );
  }
}
