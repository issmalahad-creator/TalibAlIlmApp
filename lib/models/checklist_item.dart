class ChecklistItem {
  final String text;
  final bool done;

  ChecklistItem({required this.text, this.done = false});

  ChecklistItem copyWith({bool? done}) => ChecklistItem(text: text, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'text': text, 'done': done};

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      ChecklistItem(text: json['text'] as String? ?? '', done: json['done'] as bool? ?? false);
}
