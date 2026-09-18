import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// On-demand download/cache for the bulky per-book Quran corpus text
/// (`assets/quran/corpus/{tafsir,translations,riwaya}/<id>.json.gz`) that a
/// "lite" app build ships without bundling — downloaded once from the
/// `corpus-v1` GitHub Release, cached forever on-device, never re-fetched.
/// Mirrors `QuranAudioDownloadService`'s established pattern: same
/// `getApplicationDocumentsDirectory()` + lazily-created subfolder
/// convention, same cache-first `File.exists()` check, no separate DB
/// tracking table (the filesystem is the source of truth for what's cached).
///
/// [QuranBookCache] tries the bundled asset first and falls back to this
/// service only when the asset is absent — so the "full" build (everything
/// bundled) never touches the network, and a future "lite" build (assets
/// stripped) gets the exact same code path for free.
class QuranCorpusDownloadService {
  QuranCorpusDownloadService._();
  static final QuranCorpusDownloadService instance =
      QuranCorpusDownloadService._();

  static const _releaseBase =
      'https://github.com/issmalahad-creator/TalibAlIlmApp/releases/download/corpus-v1';

  Future<Directory> _dir(String category) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/quran_corpus_cache/$category');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(String category, int id) async {
    final dir = await _dir(category);
    return File('${dir.path}/$id.json.gz');
  }

  Future<bool> isCached(String category, int id) async =>
      (await _fileFor(category, id)).exists();

  /// Returns the cached (or freshly downloaded) file's bytes, or null on any
  /// failure — network error, 404 (e.g. an edition excluded from the public
  /// release for licensing reasons), timeout. Never throws: a missing book
  /// should degrade to "no data" in the UI, not crash the reader.
  Future<List<int>?> ensureCached(String category, int id) async {
    final file = await _fileFor(category, id);
    if (await file.exists()) return file.readAsBytes();
    final uri = Uri.parse('$_releaseBase/$id.json.gz');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 60));
      if (resp.statusCode != 200) return null;
      await file.writeAsBytes(resp.bodyBytes, flush: true);
      return resp.bodyBytes;
    } catch (_) {
      return null;
    }
  }
}
