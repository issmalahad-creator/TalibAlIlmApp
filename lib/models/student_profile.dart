class StudentProfile {
  final String fullName;
  final String residence;
  final String studyTrack; // مسار علمي، بنفس تسميات مسارات IKOS
  final String studySource; // المصدر الذي يدرس منه (مؤسسة أو دراسة ذاتية)
  /// Local file path for an optional photo shown on generated certificates
  /// (Ismail's request 2026-08-16). Chosen once here, reused automatically
  /// by every certificate — not re-picked per certificate.
  final String? photoPath;

  const StudentProfile({
    this.fullName = '',
    this.residence = '',
    this.studyTrack = '',
    this.studySource = '',
    this.photoPath,
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

  Map<String, Object?> toMap() => {
        'full_name': fullName,
        'residence': residence,
        'study_track': studyTrack,
        'study_source': studySource,
        'photo_path': photoPath,
      };

  factory StudentProfile.fromMap(Map<String, Object?> map) => StudentProfile(
        fullName: map['full_name'] as String? ?? '',
        residence: map['residence'] as String? ?? '',
        studyTrack: map['study_track'] as String? ?? '',
        studySource: map['study_source'] as String? ?? '',
        photoPath: map['photo_path'] as String?,
      );
}
