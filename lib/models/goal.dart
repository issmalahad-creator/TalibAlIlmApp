class Goal {
  final int? id;
  final String title;
  final int target;
  final int current;
  final String month; // YYYY-MM

  Goal({
    this.id,
    required this.title,
    required this.target,
    this.current = 0,
    required this.month,
  });

  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1).toDouble();
  bool get isComplete => current >= target;

  Goal copyWith({int? current}) => Goal(
        id: id,
        title: title,
        target: target,
        current: current ?? this.current,
        month: month,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'target': target,
        'current': current,
        'month': month,
      };

  factory Goal.fromMap(Map<String, Object?> map) => Goal(
        id: map['id'] as int?,
        title: map['title'] as String,
        target: map['target'] as int,
        current: map['current'] as int,
        month: map['month'] as String,
      );
}
