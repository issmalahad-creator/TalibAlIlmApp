import 'dart:convert';

import 'checklist_item.dart';

/// A single day's task — separate from the monthly [Goal]. Optionally has a
/// time + reminder, and a completion checklist ("تأكد من كذا وكذا") the
/// student reviews when marking it done.
class DailyTask {
  final int? id;
  final String title;
  final String date; // Hijri YYYY-MM-DD
  final String? time; // "HH:mm", null = no specific time
  final bool reminderEnabled;
  final bool completed;
  final List<ChecklistItem> checklist;

  DailyTask({
    this.id,
    required this.title,
    required this.date,
    this.time,
    this.reminderEnabled = false,
    this.completed = false,
    this.checklist = const [],
  });

  DailyTask copyWith({bool? completed, List<ChecklistItem>? checklist}) => DailyTask(
        id: id,
        title: title,
        date: date,
        time: time,
        reminderEnabled: reminderEnabled,
        completed: completed ?? this.completed,
        checklist: checklist ?? this.checklist,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'date': date,
        'time': time,
        'reminder_enabled': reminderEnabled ? 1 : 0,
        'completed': completed ? 1 : 0,
        'checklist_json': jsonEncode(checklist.map((c) => c.toJson()).toList()),
      };

  factory DailyTask.fromMap(Map<String, Object?> map) => DailyTask(
        id: map['id'] as int?,
        title: map['title'] as String,
        date: map['date'] as String,
        time: map['time'] as String?,
        reminderEnabled: (map['reminder_enabled'] as int) == 1,
        completed: (map['completed'] as int) == 1,
        checklist: ((jsonDecode(map['checklist_json'] as String? ?? '[]')) as List)
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
