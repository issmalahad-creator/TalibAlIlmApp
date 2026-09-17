/// الواجهة الموحَّدة التي تجعل أي نظام كتب "قابلًا للاستماع" — طبقة الصوت لا
/// تتعامل مع تراث أو مكتبتي مباشرة، فقط مع هذا العقد.
/// `docs/audio-reader/TEXT_SOURCE_ADAPTERS.md` §1.
library;

abstract class ReadableTextSource {
  /// مثال: 'turath:137' أو 'library:bookKey'. مفتاح فريد يدخل في مفتاح
  /// التخزين المؤقت المستقبلي (§2 من نفس الملف).
  String get sourceId;

  /// لعرضه في واجهة القارئ الصوتي (لم تُبنَ بعد — المرحلة 4).
  String get title;

  /// نص الوحدة (صفحة عادةً) مجزَّأ لفقرات جاهزة للتوليد فقرة فقرة.
  Future<List<String>> paragraphsForUnit(int unitIndex);

  /// عدد الصفحات/الوحدات الكلي في هذا الكتاب.
  Future<int> get totalUnits;

  /// يُقرَأ من مصدر التتبّع الأصلي لهذا النظام — لا جدول جديد.
  Future<int?> get lastReadUnit;

  /// يُكتَب لنفس مصدر التتبّع الأصلي لهذا النظام.
  Future<void> saveLastListenedUnit(int unitIndex);
}
