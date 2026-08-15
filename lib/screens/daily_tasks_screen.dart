import 'package:flutter/material.dart';

import '../models/checklist_item.dart';
import '../models/daily_task.dart';
import '../repositories/daily_task_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/month.dart';
import 'add_task_screen.dart';

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
              const Text('راجع النقاط التالية قبل إكمال المهمة:', style: TextStyle(fontSize: 13)),
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
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تم — إكمال المهمة')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('المهام')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(child: Text('لا توجد مهام بعد — اضغط + لإضافة مهمة', style: TextStyle(color: AppColors.textMuted)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  children: [
                    if (todayTasks.isNotEmpty) ...[
                      Text('اليوم', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...todayTasks.map(_taskCard),
                      const SizedBox(height: 20),
                    ],
                    if (futureTasks.isNotEmpty) ...[
                      Text('القادمة', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...futureTasks.map(_taskCard),
                    ],
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
          if (added == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('مهمة جديدة'),
      ),
    );
  }

  Widget _taskCard(DailyTask task) {
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
            if (task.checklist.isNotEmpty) '${task.checklist.where((c) => c.done).length}/${task.checklist.length} نقطة تحقق',
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
