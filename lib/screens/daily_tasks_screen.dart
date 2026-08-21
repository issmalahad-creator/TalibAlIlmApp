import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/checklist_item.dart';
import '../models/daily_task.dart';
import '../repositories/daily_task_repository.dart';
import '../services/language_preference_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/month.dart';
import 'add_task_screen.dart';
import '../widgets/loading_view.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  final _repo = DailyTaskRepository();
  final _notificationService = NotificationService();
  List<DailyTask> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tasks = await _repo.upcoming(todayDate());
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _toggleComplete(DailyTask task) async {
    if (task.completed) {
      await _repo.setCompleted(task.id!, false);
      _load();
      return;
    }
    if (task.checklist.isEmpty) {
      await _repo.setCompleted(task.id!, true);
      await _notificationService.cancelTaskReminder(task.id!);
      _load();
      return;
    }
    await _showCompletionChecklist(task);
  }

  Future<void> _showCompletionChecklist(DailyTask task) async {
    final lang = LanguagePreferenceService.currentLanguage;
    var checklist = List<ChecklistItem>.from(task.checklist);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(basicText('review_checklist_before_complete', lang), style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              ...checklist.asMap().entries.map((entry) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(entry.value.text),
                    value: entry.value.done,
                    onChanged: (v) => setDialogState(() {
                      checklist[entry.key] = entry.value.copyWith(done: v ?? false);
                    }),
                  )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(basicText('cancel', lang))),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(basicText('mark_task_complete', lang))),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await _repo.update(task.copyWith(completed: true, checklist: checklist));
    await _notificationService.cancelTaskReminder(task.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final today = todayDate();
    final todayTasks = _tasks.where((t) => t.date == today).toList();
    final futureTasks = _tasks.where((t) => t.date != today).toList();

    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        appBar: AppBar(title: Text(basicText('tasks_title', lang))),
        body: _loading
            ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_generic', lang))
            : _tasks.isEmpty
                ? Center(child: Text(basicText('no_tasks_yet', lang), style: const TextStyle(color: AppColors.textMuted)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    children: [
                      if (todayTasks.isNotEmpty) ...[
                        Text(basicText('today_label', lang), style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...todayTasks.map((t) => _taskCard(t, lang)),
                        const SizedBox(height: 20),
                      ],
                      if (futureTasks.isNotEmpty) ...[
                        Text(basicText('upcoming_label', lang), style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...futureTasks.map((t) => _taskCard(t, lang)),
                      ],
                    ],
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
            if (added == true) _load();
          },
          icon: const Icon(Icons.add),
          label: Text(basicText('new_task_title', lang)),
        ),
      ),
    );
  }

  Widget _taskCard(DailyTask task, String lang) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(value: task.completed, onChanged: (_) => _toggleComplete(task)),
        title: Text(task.title,
            style: TextStyle(
                decoration: task.completed ? TextDecoration.lineThrough : null,
                color: task.completed ? AppColors.textMuted : AppColors.textDark,
                fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            '${task.date}${task.time != null ? ' · ${task.time}' : ''}',
            if (task.reminderEnabled) '🔔',
            if (task.checklist.isNotEmpty)
              '${task.checklist.where((c) => c.done).length}/${task.checklist.length} ${basicText('checklist_points_suffix', lang)}',
          ].join('  '),
          style: const TextStyle(fontSize: 11.5),
        ),
        onTap: () async {
          final changed =
              await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AddTaskScreen(existing: task)));
          if (changed == true) _load();
        },
      ),
    );
  }
}
