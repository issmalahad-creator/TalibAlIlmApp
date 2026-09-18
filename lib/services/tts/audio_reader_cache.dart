/// طبقة التخزين المؤقت للفقرات المُولَّدة صوتيًا — المرحلة 3 من
/// docs/audio-reader/TODO.md. مفتاح التخزين المؤقت
/// `"${voiceId}:${sourceId}:${unitIndex}:${paragraphIndex}"` كما حدَّدته
/// `TEXT_SOURCE_ADAPTERS.md` §2/§5 — مُطبَّق هنا كمسار مجلَّدات بدل سلسلة
/// نصية واحدة (Windows/بعض أنظمة الملفات لا تقبل ':' في اسم ملف).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioReaderCache {
  Future<Directory> _rootDir() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory(p.join(supportDir.path, 'audio_reader_cache'));
  }

  Future<File> _fileFor({
    required String voiceId,
    required String sourceId,
    required int unitIndex,
    required int paragraphIndex,
  }) async {
    final root = await _rootDir();
    return File(
      p.join(root.path, _sanitize(voiceId), _sanitize(sourceId), '${unitIndex}_$paragraphIndex.wav'),
    );
  }

  /// آخر استخدام يُحدَّث ضمنيًا عبر `read`/`write` (وقت تعديل الملف نفسه —
  /// لا حاجة لعمود/سجل منفصل لهذا الغرض البسيط).
  Future<File?> read({
    required String voiceId,
    required String sourceId,
    required int unitIndex,
    required int paragraphIndex,
  }) async {
    final file = await _fileFor(voiceId: voiceId, sourceId: sourceId, unitIndex: unitIndex, paragraphIndex: paragraphIndex);
    if (!await file.exists() || await file.length() == 0) return null;
    // إعادة كتابة وقت التعديل الحالي تُبقي هذا الملف "حديثًا" لسياسة الإخلاء
    // أدناه دون إعادة توليد الصوت أو نسخ محتواه.
    await file.setLastModified(DateTime.now());
    return file;
  }

  Future<File> write({
    required String voiceId,
    required String sourceId,
    required int unitIndex,
    required int paragraphIndex,
    required Uint8List wavBytes,
  }) async {
    final file = await _fileFor(voiceId: voiceId, sourceId: sourceId, unitIndex: unitIndex, paragraphIndex: paragraphIndex);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(wavBytes, flush: true);
    return file;
  }

  /// سياسة إخلاء بسيطة (§3.3): الاحتفاظ بآخر [keepBooks] كتب نشطة فقط لكل
  /// صوت — "نشط" يُقاس بأحدث وقت تعديل ملف داخل مجلد الكتاب (`sourceId`).
  /// حذف مجلد كتاب كامل، لا حذف انتقائي لفقرات مفردة داخله.
  Future<void> evictExceptRecentBooks({required String voiceId, int keepBooks = 2}) async {
    final root = await _rootDir();
    final voiceDir = Directory(p.join(root.path, _sanitize(voiceId)));
    if (!await voiceDir.exists()) return;

    final bookDirs = await voiceDir.list().where((e) => e is Directory).cast<Directory>().toList();
    if (bookDirs.length <= keepBooks) return;

    final withLatestMtime = <Directory, DateTime>{};
    for (final dir in bookDirs) {
      var latest = DateTime.fromMillisecondsSinceEpoch(0);
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        if (stat.modified.isAfter(latest)) latest = stat.modified;
      }
      withLatestMtime[dir] = latest;
    }

    final sorted = withLatestMtime.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted.skip(keepBooks)) {
      await entry.key.delete(recursive: true);
    }
  }

  static String _sanitize(String key) => key.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
