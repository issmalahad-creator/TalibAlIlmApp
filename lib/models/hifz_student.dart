class HifzStudent {
  final int? id;
  final String name;
  final String guardianPhone;
  final int? age;
  final String progress;
  final String dateAdded;

  HifzStudent({
    this.id,
    required this.name,
    required this.guardianPhone,
    this.age,
    required this.progress,
    required this.dateAdded,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'guardian_phone': guardianPhone,
        'age': age,
        'progress': progress,
        'date_added': dateAdded,
      };

  factory HifzStudent.fromMap(Map<String, dynamic> map) => HifzStudent(
        id: map['id'] as int?,
        name: map['name'] as String,
        guardianPhone: map['guardian_phone'] as String? ?? '',
        age: map['age'] as int?,
        progress: map['progress'] as String? ?? '',
        dateAdded: map['date_added'] as String,
      );
}

/// A free-form, teacher-defined field specific to one student only — e.g.
/// "الجزء الحالي: عم" or any note the teacher wants to track for that
/// particular student. Not a fixed app-wide schema; every student can end up
/// with a completely different set of these.
class HifzStudentField {
  final int? id;
  final int studentId;
  final String label;
  final String value;

  HifzStudentField({this.id, required this.studentId, required this.label, required this.value});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'student_id': studentId,
        'label': label,
        'value': value,
      };

  factory HifzStudentField.fromMap(Map<String, dynamic> map) => HifzStudentField(
        id: map['id'] as int?,
        studentId: map['student_id'] as int,
        label: map['label'] as String,
        value: map['value'] as String? ?? '',
      );
}
