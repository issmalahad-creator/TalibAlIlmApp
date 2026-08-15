enum ActivityCategory { lesson, lecture, sermon, dawahTrip, newMuslim, otherActivity }

extension ActivityCategoryLabel on ActivityCategory {
  String get label {
    switch (this) {
      case ActivityCategory.lesson:
        return 'درس علمي';
      case ActivityCategory.lecture:
        return 'محاضرة / موعظة';
      case ActivityCategory.sermon:
        return 'خطبة منبرية';
      case ActivityCategory.dawahTrip:
        return 'جولة دعوية';
      case ActivityCategory.newMuslim:
        return 'مسلم جديد';
      case ActivityCategory.otherActivity:
        return 'نشاط آخر';
    }
  }

  bool get hasBeneficiaries =>
      this == ActivityCategory.lesson || this == ActivityCategory.lecture;
}

class ActivityEntry {
  final int? id;
  final ActivityCategory category;
  final String date; // YYYY-MM-DD
  final String title;
  final int? beneficiaries;
  final String notes;

  ActivityEntry({
    this.id,
    required this.category,
    required this.date,
    required this.title,
    this.beneficiaries,
    this.notes = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'category': category.name,
        'date': date,
        'title': title,
        'beneficiaries': beneficiaries,
        'notes': notes,
      };

  factory ActivityEntry.fromMap(Map<String, Object?> map) => ActivityEntry(
        id: map['id'] as int?,
        category: ActivityCategory.values
            .firstWhere((c) => c.name == map['category']),
        date: map['date'] as String,
        title: map['title'] as String,
        beneficiaries: map['beneficiaries'] as int?,
        notes: (map['notes'] as String?) ?? '',
      );
}
