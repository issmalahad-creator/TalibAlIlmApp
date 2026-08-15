class StudentProfile {
  final String fullName;
  final String residence;
  final String studyTrack; // مسار علمي، بنفس تسميات مسارات IKOS
  final String studySource; // المصدر الذي يدرس منه (مؤسسة أو دراسة ذاتية)

  const StudentProfile({
    this.fullName = '',
    this.residence = '',
    this.studyTrack = '',
    this.studySource = '',
  });

  // Aligned with IKOS's own "المسارات العلمية" track names so a monthly
  // report reads consistently with what's actually tracked in the app.
  static const studyTracks = [
    'القرآن وعلومه',
    'الحديث وعلومه',
    'الفقه وأصوله',
    'العقيدة وأسماء الله',
    'السيرة والتاريخ',
    'الدعوة والأخلاق',
    'اللغة العربية',
    'التراجم والطبقات',
  ];

  bool get isComplete =>
      fullName.trim().isNotEmpty &&
      residence.trim().isNotEmpty &&
      studyTrack.trim().isNotEmpty;

  Map<String, String> toMap() => {
        'full_name': fullName,
        'residence': residence,
        'study_track': studyTrack,
        'study_source': studySource,
      };

  factory StudentProfile.fromMap(Map<String, String> map) => StudentProfile(
        fullName: map['full_name'] ?? '',
        residence: map['residence'] ?? '',
        studyTrack: map['study_track'] ?? '',
        studySource: map['study_source'] ?? '',
      );
}
