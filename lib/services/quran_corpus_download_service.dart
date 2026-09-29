import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;
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

  /// `(received, total)` for an in-flight download, keyed by `"category/id"`.
  /// `total` is null when the server didn't send a content-length. Absent
  /// from the map (not just null-valued) when nothing is downloading for
  /// that key — [progressOf] creates the notifier lazily so a picker screen
  /// can listen before any download has started.
  final Map<String, ValueNotifier<(int, int?)?>> _progress = {};

  String _key(String category, int id) => '$category/$id';

  /// Asks the user before any network fetch — wired once from `main.dart`
  /// (needs the navigator). Receives the download size in bytes (null when
  /// unknown). No callback set (tests) → downloads proceed unasked.
  Future<bool> Function(String category, int id, int? bytes)? confirmDownload;

  final Map<String, Future<bool>> _asking = {};
  final Map<String, DateTime> _declined = {};
  static const _declineMemory = Duration(minutes: 2);

  /// `(available, bytes)` — only a definite 404/410 (e.g. an edition
  /// excluded from the release for licensing) means "unavailable". A slow or
  /// failed probe (weak network) is NOT proof the book is missing, so the
  /// user is still asked, just without a size.
  Future<(bool, int?)> _probe(Uri uri) async {
    try {
      final r = await http.head(uri).timeout(const Duration(seconds: 6));
      if (r.statusCode == 404 || r.statusCode == 410) return (false, null);
      return (true, int.tryParse(r.headers['content-length'] ?? ''));
    } catch (_) {
      return (true, null);
    }
  }

  Future<bool> _approved(String category, int id, Uri uri) {
    final ask = confirmDownload;
    if (ask == null) return Future.value(true);
    final k = _key(category, id);
    final d = _declined[k];
    if (d != null && DateTime.now().difference(d) < _declineMemory) {
      return Future.value(false);
    }
    return _asking.putIfAbsent(k, () async {
      try {
        final (available, bytes) = await _probe(uri);
        if (!available) return false;
        final ok = await ask(category, id, bytes);
        if (!ok) _declined[k] = DateTime.now();
        return ok;
      } finally {
        _asking.remove(k);
      }
    });
  }

  /// The live progress notifier for `(category, id)` — `null` value means
  /// "not currently downloading" (either not started, cached already, or
  /// just finished/failed). UI disposes nothing here; these notifiers are
  /// process-lifetime and cheap (one per book ever downloaded this run).
  ValueNotifier<(int, int?)?> progressOf(String category, int id) =>
      _progress.putIfAbsent(_key(category, id), () => ValueNotifier(null));

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
  /// should degrade to "no data" in the UI, not crash the reader. Reports
  /// real byte progress via [progressOf] while a network fetch is in flight
  /// (not set at all for a plain cache-hit — there's nothing to show).
  Future<List<int>?> ensureCached(String category, int id) async {
    // The "never throws" promise includes locating the cache: a failing
    // path_provider (tests, a broken storage mount) must degrade to "no
    // data", not crash the tafsir panel.
    final File file;
    try {
      file = await _fileFor(category, id);
      if (await file.exists()) return await file.readAsBytes();
    } catch (e) {
      debugPrint('QuranCorpusDownloadService: cache unavailable for $category/$id ($e)');
      return null;
    }

    final notifier = progressOf(category, id);
    final uri = Uri.parse('$_releaseBase/$id.json.gz');
    if (!await _approved(category, id, uri)) return null;
    final client = http.Client();
    try {
      final req = http.Request('GET', uri);
      final streamed = await client.send(req).timeout(const Duration(seconds: 60));
      if (streamed.statusCode != 200) return null;
      final total = streamed.contentLength;
      final builder = BytesBuilder(copy: false);
      var received = 0;
      notifier.value = (0, total);
      await for (final chunk in streamed.stream) {
        builder.add(chunk);
        received += chunk.length;
        notifier.value = (received, total);
      }
      final bytes = builder.takeBytes();
      await file.writeAsBytes(bytes, flush: true);
      return bytes;
    } catch (_) {
      return null;
    } finally {
      notifier.value = null;
      client.close();
    }
  }
}
