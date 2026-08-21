import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/checklist_item.dart';
import '../models/daily_task.dart';
import '../repositories/daily_task_repository.dart';
import '../services/language_preference_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/hijri_date.dart';
import '../widgets/premium_modal.dart';

class AddTaskScreen extends StatefulWidget {
  final DailyTask? existing;
  const AddTaskScreen({super.key, this.existing});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _repo = DailyTaskRepository();
  final _notificationService = NotificationService();
  late final _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
  late final _checklistCtrls = (widget.existing?.checklist ?? [])
      .map((c) => TextEditingController(text: c.text))
      .toList();

  DateTime _pickedDate = DateTime.now();
  bool _pickedDateChanged = false;
  TimeOfDay? _pickedTime;
  late bool _reminderEnabled = widget.existing?.reminderEnabled ?? false;

  bool get _isEdit => widget.existing != null;

  String get _hijriDateLabel => _pickedDateChanged
      ? hijriDateStringForDate(_pickedDate)
      : (widget.existing?.date ?? hijriDateStringForDate(_pickedDate));

  @override
  void initState() {
    super.initState();
    final t = widget.existing?.time;
    if (t != null && t.contains(':')) {
      final parts = t.split(':');
      _pickedTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 5)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _pickedDate = picked;
        _pickedDateChanged = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _pickedTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _pickedTime = picked);
  }

  void _addChecklistField() => setState(() => _checklistCtrls.add(TextEditingController()));

  void _removeChecklistField(int i) => setState(() => _checklistCtrls.removeAt(i).dispose());

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(basicText('task_title_required', LanguagePreferenceService.currentLanguage))));
      return;
    }
    final timeStr = _pickedTime == null
        ? null
        : '${_pickedTime!.hour.toString().padLeft(2, '0')}:${_pickedTime!.minute.toString().padLeft(2, '0')}';

    final existingChecklist = widget.existing?.checklist ?? [];
    final checklist = <ChecklistItem>[];
    for (var i = 0; i < _checklistCtrls.length; i++) {
      final text = _checklistCtrls[i].text.trim();
      if (text.isEmpty) continue;
      final wasDone = i < existingChecklist.length ? existingChecklist[i].done : false;
      checklist.add(ChecklistItem(text: text, done: wasDone));
    }

    final task = DailyTask(
      id: widget.existing?.id,
      title: _titleCtrl.text.trim(),
      date: _hijriDateLabel,
      time: timeStr,
      reminderEnabled: _reminderEnabled && timeStr != null,
      completed: widget.existing?.completed ?? false,
      checklist: checklist,
    );

    late int id;
    if (_isEdit) {
      id = task.id!;
      await _repo.update(task);
    } else {
      id = await _repo.add(task);
    }

    if (task.reminderEnabled) {
      await _notificationService.scheduleTaskReminder(
        taskId: id,
        title: task.title,
        dateTime: gregorianFromHijriDateTime(task.date, task.time),
      );
    } else {
      await _notificationService.cancelTaskReminder(id);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final lang = LanguagePreferenceService.currentLanguage;
    final confirmed = await showPremiumModal<bool>(
      context,
      title: basicText('delete_task_title', lang),
      icon: Icons.delete_outline,
      child: Text(basicText('delete_task_confirm', lang), textAlign: TextAlign.center, style: AppTextStyles.body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(basicText('cancel', lang))),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(basicText('delete', lang))),
      ],
    );
    if (confirmed != true) return;
    await _notificationService.cancelTaskReminder(widget.existing!.id!);
    await _repo.delete(widget.existing!.id!);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final c in _checklistCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        appBar: AppBar(
          title: Text(basicText(_isEdit ? 'edit_task_title' : 'new_task_title', lang)),
          actions: [
            if (_isEdit) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: basicText('task_title_label', lang), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${basicText('hijri_date_label_prefix', lang)}: $_hijriDateLabel'),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_pickedTime == null
                  ? basicText('no_time_set', lang)
                  : '${basicText('time_label_prefix', lang)}: ${_pickedTime!.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            if (_pickedTime != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(basicText('reminder_notification_title', lang)),
                subtitle: Text(basicText('reminder_notification_subtitle', lang), style: const TextStyle(fontSize: 11.5)),
                value: _reminderEnabled,
                onChanged: (v) => setState(() => _reminderEnabled = v),
              ),
            const SizedBox(height: 12),
            Text(basicText('completion_checklist_title', lang), style: Theme.of(context).textTheme.titleSmall),
            Text(basicText('completion_checklist_desc', lang),
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            ..._checklistCtrls.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                              hintText: basicText('checklist_item_hint', lang), isDense: true, border: const OutlineInputBorder()),
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.remove_circle_outline), onPressed: () => _removeChecklistField(entry.key)),
                    ],
                  ),
                )),
            TextButton.icon(
                onPressed: _addChecklistField, icon: const Icon(Icons.add), label: Text(basicText('add_checklist_point', lang))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEdit ? Icons.save : Icons.add),
              label: Text(basicText(_isEdit ? 'save_changes_action' : 'add_task_action', lang)),
            ),
          ],
        ),
      ),
    );
  }
}
