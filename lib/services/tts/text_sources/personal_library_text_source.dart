/// منفِّذ `ReadableTextSource` لكتب "مكتبتي" — يقرأ/يكتب `BookBookmark`
/// الموجودة أصلًا (لا جدول تتبّع جديد). `docs/audio-reader/TEXT_SOURCE_ADAPTERS.md` §7/§7.1.
///
/// يستخرج طبقة نص PDF **الموجودة أصلًا** عبر `pdfrx` (MIT، PDFium) أولًا،
/// وإن لم توجد (كتاب مصوَّر ضوئيًا بلا نص حقيقي) يُرسِم الصفحة صورة عبر
/// `PdfPage.render` ثم يُمرِّرها إلى OCR محلي (Tesseract4Android، قناة
/// أصلية مكتوبة يدويًا — انظر `lib/services/ocr/tesseract_ocr.dart`).
/// النتيجة تُخزَّن على القرص (OCR بطيء، ثوانٍ للصفحة) فلا تتكرّر المعالجة.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../models/reading_record.dart';
import '../../../repositories/book_repository.dart';
import '../../../utils/month.dart';
import '../../ocr/tesseract_ocr.dart';
import 'readable_text_source.dart';

/// صفحة مصوَّرة رُسِمت وأُرسِلت لـOCR لكنه لم يستخرج أي نص قابل للاستخدام
/// (صفحة فارغة فعلًا، أو جودة مسح رديئة جدًا) — حالة نادرة حقيقية، لا فجوة
/// معمارية (على خلاف [PersonalLibraryNoTextLayerException] سابقًا، التي
/// كانت تُرمى لكل صفحة مصوَّرة قبل بناء OCR).
class PersonalLibraryOcrEmptyException implements Exception {
  const PersonalLibraryOcrEmptyException({required this.bookKey, required this.pageNumber});
  final String bookKey;
  final int pageNumber;

  @override
  String toString() => 'OCR لم يستخرج نصًا من الصفحة $pageNumber من "$bookKey" — على الأرجح صفحة فارغة أو جودة مسح رديئة جدًا.';
}

class PersonalLibraryTextSource implements ReadableTextSource {
  /// [pdfUrl] يُنزَّل عند أول استخدام إن لم يُمرَّر [localFilePath] — مصادر
  /// مثل `book_viewer_screen.dart` تملك ملفًا محليًا بالفعل (نزَّله `PDFView`
  /// نفسه)، فتُمرِّره مباشرة لتفادي تنزيل مزدوج لنفس الملف.
  PersonalLibraryTextSource(
    this.bookKey,
    this.bookTitle, {
    this.pdfUrl,
    this.localFilePath,
    BookRepository? repository,
  }) : assert(pdfUrl != null || localFilePath != null, 'يجب تمرير pdfUrl أو localFilePath'),
       _repo = repository ?? BookRepository();

  final String bookKey;
  final String bookTitle;
  final String? pdfUrl;
  final String? localFilePath;
  final BookRepository _repo;

  PdfDocument? _document;

  @override
  String get sourceId => 'library:$bookKey';

  @override
  String get title => bookTitle;

  /// يُنزَّل الملف مرة واحدة لكل كتاب ويُخزَّن على القرص — إعادة تنزيله في
  /// كل استدعاء يهدر بيانات المستخدم بلا داعٍ لملف لا يتغيّر بعد نشره.
  /// إن وُجد [localFilePath] (الشاشة نزَّلته أصلًا لعرضه) يُستخدَم مباشرة.
  Future<File> _ensureDownloaded() async {
    final localPath = localFilePath;
    if (localPath != null) return File(localPath);

    final supportDir = await getApplicationSupportDirectory();
    final file = File(p.join(supportDir.path, 'library_pdfs', '${_sanitize(bookKey)}.pdf'));
    if (await file.exists() && await file.length() > 0) return file;

    await file.parent.create(recursive: true);
    final response = await http.get(Uri.parse(pdfUrl!));
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
    var text = raw?.fullText.trim() ?? '';
    if (text.isEmpty) {
      text = await _ocrPage(page, unitIndex);
    }

    return splitIntoPlayableParagraphs(text);
  }

  /// كتاب مصوَّر ضوئيًا بلا طبقة نص — يُرسَم إلى صورة (≈300dpi، كافٍ لدقّة
  /// OCR معقولة بلا تضخيم زمن المعالجة) ثم يُمرَّر لـTesseract العربية.
  /// النتيجة تُخزَّن على القرص فور نجاحها فلا يُعاد OCR لنفس الصفحة مطلقًا.
  Future<String> _ocrPage(PdfPage page, int unitIndex) async {
    final cacheFile = await _ocrCacheFile(unitIndex);
    if (await cacheFile.exists()) {
      final cached = await cacheFile.readAsString();
      if (cached.isNotEmpty) return cached;
    }

    const dpi = 300.0;
    final scale = dpi / 72.0;
    final fullWidth = page.width * scale;
    final fullHeight = page.height * scale;
    final image = await page.render(fullWidth: fullWidth, fullHeight: fullHeight);
    if (image == null) {
      throw PersonalLibraryOcrEmptyException(bookKey: bookKey, pageNumber: unitIndex);
    }

    String text;
    File? tempImageFile;
    try {
      final pngBytes = await _encodePng(image);
      final tempDir = await getTemporaryDirectory();
      tempImageFile = File(p.join(tempDir.path, 'ocr_${_sanitize(bookKey)}_$unitIndex.png'));
      await tempImageFile.writeAsBytes(pngBytes, flush: true);
      text = (await TesseractOcr.instance.extractText(tempImageFile)).trim();
    } finally {
      image.dispose();
      if (tempImageFile != null && await tempImageFile.exists()) {
        await tempImageFile.delete();
      }
    }

    if (text.isEmpty) {
      throw PersonalLibraryOcrEmptyException(bookKey: bookKey, pageNumber: unitIndex);
    }

    await cacheFile.parent.create(recursive: true);
    await cacheFile.writeAsString(text, flush: true);
    return text;
  }

  Future<File> _ocrCacheFile(int unitIndex) async {
    final supportDir = await getApplicationSupportDirectory();
    return File(p.join(supportDir.path, 'ocr_cache', _sanitize(bookKey), '$unitIndex.txt'));
  }

  /// `PdfImage.pixels` بكسلات BGRA8888 خام — `dart:ui` يفكّها ويُرمِّزها PNG
  /// مباشرة، بلا حاجة لحزمة `image` (وما تجرّه من تعارضات إصدارات حقيقية،
  /// راجع TEXT_SOURCE_ADAPTERS.md §7.1 نقطة `dart-pdf`/`archive`).
  Future<Uint8List> _encodePng(PdfImage image) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(image.pixels, image.width, image.height, ui.PixelFormat.bgra8888, completer.complete);
    final uiImage = await completer.future;
    try {
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } finally {
      uiImage.dispose();
    }
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
