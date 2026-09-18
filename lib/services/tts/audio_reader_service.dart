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
    int lookahead = 2,
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
}
