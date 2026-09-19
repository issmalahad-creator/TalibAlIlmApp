/// غلاف Dart لقناة OCR الأصلية (`MainActivity.kt`، Tesseract4Android عبر
/// JitPack) — كُتِبت يدويًا بعد أن فشلت فعليًا حزمتا Flutter الجاهزتين
/// (flutter_tesseract_ocr، tesseract_ocr) في البناء على AGP 9 في هذا
/// المشروع (وحدة Gradle قديمة لا تُطبِّق `com.android.library`، تحقّقتُ
/// ببناء حقيقي لكلتيهما، لا تخمينًا). Android فقط اليوم — لا مقابل iOS.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TesseractOcr {
  TesseractOcr._();
  static final TesseractOcr instance = TesseractOcr._();

  static const _channel = MethodChannel('talib_alilm/tesseract_ocr');
  static const String _language = 'ara';

  Future<String>? _dataPathReady;

  /// ينسخ `assets/tessdata/ara.traineddata` إلى مجلد ملفات التطبيق مرة واحدة
  /// فقط — Tesseract4Android يحتاج مسارًا حقيقيًا على القرص (`datapath` يجب
  /// أن يحوي مجلدًا فرعيًا `tessdata`)، لا يقرأ من bundle الأصول مباشرة.
  Future<String> _ensureDataPath() {
    return _dataPathReady ??= _copyTrainedData().catchError((Object e) {
      _dataPathReady = null;
      throw e;
    });
  }

  Future<String> _copyTrainedData() async {
    final supportDir = await getApplicationSupportDirectory();
    final tessRoot = Directory(p.join(supportDir.path, 'tesseract'));
    final tessDataDir = Directory(p.join(tessRoot.path, 'tessdata'));
    final target = File(p.join(tessDataDir.path, '$_language.traineddata'));

    // 1.4 م.ب من `rootBundle` كل تشغيل تطبيق لهدر بلا داعٍ — نسخة واحدة تكفي
    // لعمر تثبيت التطبيق، نتحقّق من الحجم لا الوجود فقط (يكتشف نسخة منقوصة
    // من تنزيل/نسخ سابق فشل في المنتصف).
    const expectedMinBytes = 1000000;
    if (await target.exists() && await target.length() > expectedMinBytes) {
      return tessRoot.path;
    }

    await tessDataDir.create(recursive: true);
    final bytes = await rootBundle.load('assets/tessdata/$_language.traineddata');
    await target.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
    return tessRoot.path;
  }

  /// يستخرج النص من صورة صفحة PNG/JPEG عبر Tesseract (العربية). قد يستغرق
  /// ثوانٍ — نُفِّذ في خيط Android أصلي منفصل عن واجهة المستخدم (`MainActivity.kt`).
  Future<String> extractText(File imageFile) async {
    final dataPath = await _ensureDataPath();
    final result = await _channel.invokeMethod<String>('extractText', {
      'imagePath': imageFile.path,
      'dataPath': dataPath,
      'language': _language,
    });
    return result ?? '';
  }
}
