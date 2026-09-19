/// يربط `ReadableTextSource` (أي نظام كتب) بـ`TtsEngine` (التوليد) و
/// `AudioReaderCache` (التخزين المؤقت) — طبقة تنسيق واحدة، لا منطق تشغيل UI
/// هنا (المرحلة 4). المرحلة 3 من docs/audio-reader/TODO.md.
library;

import 'dart:io';

import 'audio_reader_cache.dart';
import 'text_sources/readable_text_source.dart';
import 'tts_engine.dart';

class AudioReaderService {
  AudioReaderService({TtsEngine? engine, AudioReaderCache? cache})
      : _engine = engine ?? TtsEngine.instance,
        _cache = cache ?? AudioReaderCache();

  final TtsEngine _engine;
  final AudioReaderCache _cache;

  /// ملف WAV جاهز للتشغيل لفقرة واحدة — من التخزين المؤقت إن وُجد، وإلا
  /// يُولَّد الآن (بشكل متزامن مع طلب التشغيل الفعلي) ويُخزَّن لأول مرة.
  Future<File> fileForParagraph({
    required ReadableTextSource source,
    required String voiceId,
    required int unitIndex,
    required int paragraphIndex,
    required String text,
  }) async {
    final cached = await _cache.read(
      voiceId: voiceId,
      sourceId: source.sourceId,
      unitIndex: unitIndex,
      paragraphIndex: paragraphIndex,
    );
    if (cached != null) return cached;

    final bytes = await _engine.synthesize(text, voiceId: voiceId);
    return _cache.write(
      voiceId: voiceId,
      sourceId: source.sourceId,
      unitIndex: unitIndex,
      paragraphIndex: paragraphIndex,
      wavBytes: bytes,
    );
  }

  /// يُولِّد استباقيًا الفقرة الحالية + [lookahead] فقرات تالية (بلا تشغيل)،
  /// ثم يُطبِّق سياسة الإخلاء (§3.3). يُستدعى في الخلفية أثناء تشغيل الفقرة
  /// الحالية فعليًا — لا يحجب واجهة التشغيل بانتظاره.
  Future<void> prefetch({
    required ReadableTextSource source,
    required String voiceId,
    required int unitIndex,
    required List<String> paragraphs,
    required int fromParagraphIndex,
    // كان 2 — رُفِع بعد إصلاح تعطّل حقيقي (SIGSEGV) بجعل الاستدلال بخيط
    // واحد فقط (`numThreads: 1` في tts_engine.dart)، وهذا أبطأ من خيطين.
    // لفقرة طويلة (~230 حرفًا، صوت ~20 ثانية) صار التوليد يستغرق نحو 14
    // ثانية — هامش الاستباق بفقرتين فقط أصبح غير كافٍ أحيانًا، فيتوقّف
    // التشغيل لحظات بانتظار الفقرة التالية (أبلغ عنه إسماعيل فعليًا على
    // جهازه 2026-09-18). 4 يمنح هامشًا أكبر يمتصّ هذا التباطؤ.
    int lookahead = 4,
  }) async {
    if (paragraphs.isEmpty) return;
    final end = (fromParagraphIndex + lookahead).clamp(0, paragraphs.length - 1);
    for (var i = fromParagraphIndex.clamp(0, paragraphs.length - 1); i <= end; i++) {
      await fileForParagraph(
        source: source,
        voiceId: voiceId,
        unitIndex: unitIndex,
        paragraphIndex: i,
        text: paragraphs[i],
      );
    }
    await _cache.evictExceptRecentBooks(voiceId: voiceId);
  }

  /// حجم كامل الكاش الصوتي بالبايت — لعرضه في زر "مسح ذاكرة الصوت المؤقتة".
  Future<int> cacheSizeBytes() => _cache.totalSizeBytes();

  /// مسح كامل الكاش الصوتي يدويًا (طلب إسماعيل — "زر حذف التراكم"،
  /// 2026-09-18) — إجراء المستخدم الصريح، منفصل عن سياسة الإخلاء التلقائية.
  Future<void> clearCache() => _cache.clearAll();
}
