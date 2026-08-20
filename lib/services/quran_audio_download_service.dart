import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/quran_surahs.dart';
import 'quran_audio/quran_audio_provider_registry.dart';

/// Selective per-ayah download/cache for Quran recitation audio — Ismail's
/// explicit "لا تحمل آلاف الملفات، تنزيل انتقائي فقط" instruction. Mirrors
/// `DownloadedFileService`'s exact established pattern (same
/// `getApplicationDocumentsDirectory()` + lazily-created subfolder
/// convention, same cache-first `File.exists()` check before fetching) —
/// deliberately no separate DB table tracking what's downloaded: checking
/// the filesystem directly can never drift out of sync with itself, same
/// philosophy as `CurriculumRepository`'s "no separate progress table."
class QuranAudioDownloadService {
  Future<Directory> _dir(String reciterId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/quran_audio/$reciterId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(String reciterId, int surah, int ayah) async {
    final dir = await _dir(reciterId);
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return File('${dir.path}/$s$a.mp3');
  }

  Future<bool> isAyahDownloaded(String reciterId, int surah, int ayah) async => (await _fileFor(reciterId, surah, ayah)).exists();

  /// The local file if this ayah is already cached, without downloading it —
  /// used by `QuranAudioEngine` to prefer a local file over streaming.
  Future<File?> localFileIfExists(String reciterId, int surah, int ayah) async {
    final file = await _fileFor(reciterId, surah, ayah);
    return await file.exists() ? file : null;
  }

  /// Downloads one ayah if not already cached; returns null (not throws) on
  /// any failure — network errors, a provider with no URL for this
  /// reciter/ayah, a bad HTTP status — since a single missed ayah in a
  /// range download shouldn't abort the whole batch.
  Future<File?> ensureAyahDownloaded(String reciterId, int surah, int ayah) async {
    final file = await _fileFor(reciterId, surah, ayah);
    if (await file.exists()) return file;
    final url = QuranAudioProviderRegistry.ayahAudioUrl(reciterId: reciterId, surah: surah, ayah: ayah);
    if (url == null) return null;
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) return null;
      await file.writeAsBytes(resp.bodyBytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  /// Downloads a whole (surah, ayah) → (surah, ayah) range, one ayah at a
  /// time — crosses surah boundaries when `surahTo != surahFrom` (Mushaf
  /// pages don't always align to surah boundaries, same reason
  /// `MemorizationUnit` tracks `surahStart`/`surahEnd` separately).
  Future<void> downloadRange({
    required String reciterId,
    required int surahFrom,
    required int ayahFrom,
    required int surahTo,
    required int ayahTo,
    void Function(int done, int total)? onProgress,
  }) async {
    final pairs = _ayahsInRange(surahFrom, ayahFrom, surahTo, ayahTo);
    var done = 0;
    for (final pair in pairs) {
      await ensureAyahDownloaded(reciterId, pair.$1, pair.$2);
      done++;
      onProgress?.call(done, pairs.length);
    }
  }

  Future<int> downloadedAyahCount({required String reciterId, required int surahFrom, required int ayahFrom, required int surahTo, required int ayahTo}) async {
    final pairs = _ayahsInRange(surahFrom, ayahFrom, surahTo, ayahTo);
    var count = 0;
    for (final pair in pairs) {
      if (await isAyahDownloaded(reciterId, pair.$1, pair.$2)) count++;
    }
    return count;
  }

  Future<int> totalSizeBytes({required String reciterId, required int surahFrom, required int ayahFrom, required int surahTo, required int ayahTo}) async {
    final pairs = _ayahsInRange(surahFrom, ayahFrom, surahTo, ayahTo);
    var total = 0;
    for (final pair in pairs) {
      final file = await _fileFor(reciterId, pair.$1, pair.$2);
      if (await file.exists()) total += await file.length();
    }
    return total;
  }

  Future<void> deleteRange({required String reciterId, required int surahFrom, required int ayahFrom, required int surahTo, required int ayahTo}) async {
    final pairs = _ayahsInRange(surahFrom, ayahFrom, surahTo, ayahTo);
    for (final pair in pairs) {
      final file = await _fileFor(reciterId, pair.$1, pair.$2);
      if (await file.exists()) await file.delete();
    }
  }

  List<(int, int)> _ayahsInRange(int surahFrom, int ayahFrom, int surahTo, int ayahTo) {
    final pairs = <(int, int)>[];
    for (var s = surahFrom; s <= surahTo; s++) {
      final surah = quranSurahs.firstWhere((x) => x.number == s);
      final startAyah = s == surahFrom ? ayahFrom : 1;
      final endAyah = s == surahTo ? ayahTo : surah.ayahCount;
      for (var a = startAyah; a <= endAyah; a++) {
        pairs.add((s, a));
      }
    }
    return pairs;
  }
}
