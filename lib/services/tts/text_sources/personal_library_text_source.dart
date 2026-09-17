/// منفِّذ `ReadableTextSource` لكتب "مكتبتي" — يقرأ/يكتب `BookBookmark`
/// الموجودة أصلًا (لا جدول تتبّع جديد). `docs/audio-reader/TEXT_SOURCE_ADAPTERS.md` §7/§7.1.
///
/// يستخرج طبقة نص PDF **الموجودة أصلًا** عبر `pdfrx` (MIT، PDFium). لا OCR —
/// صفحة بلا طبقة نص (كتاب مصوَّر ممسوح ضوئيًا بلا نص حقيقي) تُبلَّغ صراحةً
/// عبر [PersonalLibraryNoTextLayerException] بدل إرجاع نص فارغ صامت.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../models/reading_record.dart';
import '../../../repositories/book_repository.dart';
import '../../../utils/month.dart';
import 'readable_text_source.dart';

/// صفحة PDF بلا طبقة نص قابلة للاستخراج (على الأرجح كتاب مصوَّر ضوئيًا
/// بلا OCR) — فجوة معمارية حقيقية موثَّقة في TEXT_SOURCE_ADAPTERS.md §7.1،
/// ليست خطأ في هذا المنفِّذ.
class PersonalLibraryNoTextLayerException implements Exception {
  const PersonalLibraryNoTextLayerException({required this.bookKey, required this.pageNumber});
  final String bookKey;
  final int pageNumber;

  @override
  String toString() => 'لا نص مستخرَج للصفحة $pageNumber من "$bookKey" — على الأرجح صفحة مصوَّرة بلا طبقة نص (يحتاج OCR، غير مبني بعد).';
}

class PersonalLibraryTextSource implements ReadableTextSource {
  PersonalLibraryTextSource(this.bookKey, this.bookTitle, this.pdfUrl, {BookRepository? repository})
      : _repo = repository ?? BookRepository();

  final String bookKey;
  final String bookTitle;
  final String pdfUrl;
  final BookRepository _repo;

  PdfDocument? _document;

  @override
  String get sourceId => 'library:$bookKey';

  @override
  String get title => bookTitle;

  /// يُنزَّل الملف مرة واحدة لكل كتاب ويُخزَّن على القرص — إعادة تنزيله في
  /// كل استدعاء يهدر بيانات المستخدم بلا داعٍ لملف لا يتغيّر بعد نشره.
  Future<File> _ensureDownloaded() async {
    final supportDir = await getApplicationSupportDirectory();
    final file = File(p.join(supportDir.path, 'library_pdfs', '${_sanitize(bookKey)}.pdf'));
    if (await file.exists() && await file.length() > 0) return file;

    await file.parent.create(recursive: true);
    final response = await http.get(Uri.parse(pdfUrl));
    if (response.statusCode != 200) {
      throw StateError('تعذّر تنزيل "$bookTitle" (HTTP ${response.statusCode})');
    }
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  Future<PdfDocument> _ensureLoaded() async {
    final cached = _document;
    if (cached != null) return cached;
    final file = await _ensureDownloaded();
    final bytes = await file.readAsBytes();
    final doc = await PdfDocument.openData(Uint8List.fromList(bytes), sourceName: bookKey);
    _document = doc;
    return doc;
  }

  @override
  Future<List<String>> paragraphsForUnit(int unitIndex) async {
    final doc = await _ensureLoaded();
    if (unitIndex < 1 || unitIndex > doc.pages.length) return const [];

    final page = doc.pages[unitIndex - 1];
    final raw = await page.loadText();
    final text = raw?.fullText.trim() ?? '';
    if (text.isEmpty) {
      throw PersonalLibraryNoTextLayerException(bookKey: bookKey, pageNumber: unitIndex);
    }

    return text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
  }

  @override
  Future<int> get totalUnits async => (await _ensureLoaded()).pages.length;

  @override
  Future<int?> get lastReadUnit async {
    final bookmark = await _repo.getBookmark(bookKey);
    return bookmark?.lastPage;
  }

  @override
  Future<void> saveLastListenedUnit(int unitIndex) async {
    final total = await totalUnits;
    await _repo.saveBookmark(
      BookBookmark(bookKey: bookKey, lastPage: unitIndex, totalPages: total, lastUpdatedDate: todayDate()),
    );
  }

  static String _sanitize(String key) => key.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
