/// Quran Ayah Study Notebook (`79-sa-D-ayah`,
/// `docs/AYAH_STUDY_NOTEBOOK_DESIGN.md`). One entry the student wrote about
/// an ayah — a tafsir excerpt, a meaning, a benefit, a question, a lesson
/// summary, a link, a personal note. NOT a Quran highlight and NOT a copy
/// of the Turath annotation model (a sibling, merged later).
///
/// Anchor is numeric `(surah, ayah[, wordStart..wordEnd])` — it never
/// drifts, so there is no re-anchoring engine here. Every field except
/// `surah`/`ayah`/`body` is optional; `entryType` defaults to `personal`
/// so free writing needs no choice.
library;

class AyahStudyEntry {
  final int id;
  final int surah;
  final int ayah;
  final int? wordStart; // 1-based word_index_in_ayah; null = whole ayah
  final int? wordEnd; // inclusive; null = whole ayah

  final String entryType; // one of AyahEntryTypes
  final String? topic; // free sub-tag ("الطهارة", "بلاغة", ...)
  final String? stance; // one of AyahEntryStances, or null
  final String? colorKey; // reuse StudyAnnotationColors keys; null = derive from type

  final String body;

  final String? sourceType; // one of AyahSourceTypes
  final String? sourceName;
  final String? sourceAuthor;
  final String? sourceRef;
  final String? sourceDate;
  final String? sourceDetail;

  final String status; // none | open | resolved
  final String? resolvedAt;
  final int? sortOrder;

  final String createdAt;
  final String updatedAt;

  const AyahStudyEntry({
    required this.id,
    required this.surah,
    required this.ayah,
    this.wordStart,
    this.wordEnd,
    required this.entryType,
    this.topic,
    this.stance,
    this.colorKey,
    required this.body,
    this.sourceType,
    this.sourceName,
    this.sourceAuthor,
    this.sourceRef,
    this.sourceDate,
    this.sourceDetail,
    required this.status,
    this.resolvedAt,
    this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasSource =>
      [sourceName, sourceAuthor, sourceRef, sourceDate, sourceDetail].any((s) => (s ?? '').trim().isNotEmpty);

  bool get hasWordRange => wordStart != null && wordEnd != null;

  /// A one-line citation from whatever source parts are present.
  String get sourceLine =>
      [sourceName, sourceAuthor, sourceRef, sourceDate].map((s) => (s ?? '').trim()).where((s) => s.isNotEmpty).join(' — ');

  factory AyahStudyEntry.fromRow(Map<String, Object?> r) => AyahStudyEntry(
        id: r['id'] as int,
        surah: r['surah'] as int,
        ayah: r['ayah'] as int,
        wordStart: r['word_start'] as int?,
        wordEnd: r['word_end'] as int?,
        entryType: r['entry_type'] as String? ?? AyahEntryTypes.personal,
        topic: r['topic'] as String?,
        stance: r['stance'] as String?,
        colorKey: r['color_key'] as String?,
        body: r['body'] as String? ?? '',
        sourceType: r['source_type'] as String?,
        sourceName: r['source_name'] as String?,
        sourceAuthor: r['source_author'] as String?,
        sourceRef: r['source_ref'] as String?,
        sourceDate: r['source_date'] as String?,
        sourceDetail: r['source_detail'] as String?,
        status: r['status'] as String? ?? 'none',
        resolvedAt: r['resolved_at'] as String?,
        sortOrder: r['sort_order'] as int?,
        createdAt: r['created_at'] as String? ?? '',
        updatedAt: r['updated_at'] as String? ?? '',
      );
}

/// What the student is about to write — used by add and edit. Only `body`
/// is really required; everything else has a sane default / stays null.
class AyahStudyEntryInput {
  final String body;
  final String entryType;
  final String? topic;
  final String? stance;
  final String? colorKey;
  final int? wordStart;
  final int? wordEnd;
  final String? sourceType;
  final String? sourceName;
  final String? sourceAuthor;
  final String? sourceRef;
  final String? sourceDate;
  final String? sourceDetail;

  const AyahStudyEntryInput({
    required this.body,
    this.entryType = AyahEntryTypes.personal,
    this.topic,
    this.stance,
    this.colorKey,
    this.wordStart,
    this.wordEnd,
    this.sourceType,
    this.sourceName,
    this.sourceAuthor,
    this.sourceRef,
    this.sourceDate,
    this.sourceDetail,
  });

  factory AyahStudyEntryInput.from(AyahStudyEntry e) => AyahStudyEntryInput(
        body: e.body,
        entryType: e.entryType,
        topic: e.topic,
        stance: e.stance,
        colorKey: e.colorKey,
        wordStart: e.wordStart,
        wordEnd: e.wordEnd,
        sourceType: e.sourceType,
        sourceName: e.sourceName,
        sourceAuthor: e.sourceAuthor,
        sourceRef: e.sourceRef,
        sourceDate: e.sourceDate,
        sourceDetail: e.sourceDetail,
      );
}

/// The coarse category the "جلسة دراسة الآية" overview groups by. Stored as
/// these exact strings so the future maths engine can consume them.
class AyahEntryTypes {
  static const personal = 'personal';
  static const tafsir = 'tafsir';
  static const meaning = 'meaning';
  static const benefit = 'benefit';
  static const linguistic = 'linguistic';
  static const fiqh = 'fiqh';
  static const aqeedah = 'aqeedah';
  static const tarbawi = 'tarbawi';
  static const hadith = 'hadith';
  static const comparison = 'comparison';
  static const question = 'question';
  static const link = 'link';
  static const lessonSummary = 'lesson_summary';
  static const review = 'review';

  /// Shown as chips first in the add sheet; the rest are under «المزيد».
  static const primary = [personal, tafsir, meaning, benefit, question, lessonSummary, link];
  static const secondary = [linguistic, fiqh, aqeedah, tarbawi, hadith, comparison, review];
  static const all = [...primary, ...secondary];
}

/// Optional epistemic axis: whose words / what kind of knowing.
class AyahEntryStances {
  static const naql = 'naql'; // ما قاله الشيخ / الكتاب
  static const fahm = 'fahm'; // ما فهمته أنا
  static const istinbat = 'istinbat'; // فائدة استنبطتها
  static const sual = 'sual'; // شيء لم أفهمه
  static const all = [naql, fahm, istinbat, sual];
}

class AyahSourceTypes {
  static const tafsirBook = 'tafsir_book';
  static const tafsirLesson = 'tafsir_lesson';
  static const sheikhLesson = 'sheikh_lesson';
  static const book = 'book';
  static const hadith = 'hadith';
  static const personal = 'personal';
  static const other = 'other';
  static const all = [tafsirBook, tafsirLesson, sheikhLesson, book, hadith, personal, other];
}

class AyahEntryStatus {
  static const none = 'none';
  static const open = 'open'; // an unanswered question
  static const resolved = 'resolved';
}

/// (surah, ayah, entry count) for the cross-ayah "الآيات الأكثر ثراءً" list.
class AyahEntryCount {
  final int surah;
  final int ayah;
  final int count;
  const AyahEntryCount(this.surah, this.ayah, this.count);
}
