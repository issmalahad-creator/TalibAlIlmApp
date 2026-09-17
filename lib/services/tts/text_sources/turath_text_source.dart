/// منفِّذ `ReadableTextSource` لكتب تراث — يقرأ/يكتب `TurathLastRead`
/// الموجودة أصلًا (لا جدول تتبّع جديد). `docs/audio-reader/TEXT_SOURCE_ADAPTERS.md` §1.
library;

import '../../../repositories/turath_repository.dart';
import '../../../utils/study_annotation_anchor.dart' show normalizePageText;
import 'readable_text_source.dart';

class TurathTextSource implements ReadableTextSource {
  TurathTextSource(this.bookId, this.bookName, {TurathRepository? repository})
      : _repo = repository ?? TurathRepository();

  final int bookId;
  final String bookName;
  final TurathRepository _repo;

  @override
  String get sourceId => 'turath:$bookId';

  @override
  String get title => bookName;

  @override
  Future<List<String>> paragraphsForUnit(int unitIndex) async {
    final page = await _repo.getPage(bookId, unitIndex);
    return _splitParagraphs(page.text);
  }

  @override
  Future<int> get totalUnits async {
    final catalog = await _repo.catalogBook(bookId);
    // بعض كتب تراث ليس لها page_count مُخزَّن في الفهرس المحلي (عمود اختياري
    // — انظر TurathCatalogBook.pageCount) — لا نفترض قيمة، 0 يعني "غير معروف"
    // حتى يُحسَم لاحقًا (فجوة موثَّقة، لا افتراض صامت).
    return catalog?.pageCount ?? 0;
  }

  @override
  Future<int?> get lastReadUnit async {
    final last = await _repo.lastRead(bookId);
    return last?.pageNumber;
  }

  @override
  Future<void> saveLastListenedUnit(int unitIndex) {
    return _repo.saveLastRead(bookId, bookName, unitIndex);
  }

  /// فقرات مفصولة بسطر فارغ فأكثر؛ صفحة بلا فواصل فقرات تُعامَل كفقرة واحدة
  /// (طبقة التخزين المؤقت في المرحلة 3 هي من ستُقسِّم الفقرات الطويلة جدًا
  /// عند الحاجة، لا هذه الطبقة).
  static List<String> _splitParagraphs(String rawText) {
    final normalized = normalizePageText(rawText);
    if (normalized.isEmpty) return const [];
    return normalized
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }
}
