import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint, visibleForTesting;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
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

  /// A commit that holds every bundled book under `assets/quran/corpus/`.
  /// Six books were added to the app after the `corpus-v1` release was
  /// published (2026-09-26 vs 09-18), so the release 404s for them; the
  /// pinned repo copy (raw GitHub, then jsDelivr) serves them — and any
  /// release outage — byte-identical to the full build. Pinned, never a
  /// branch, so a later move or delete can't break old installs.
  static const _pinnedCommit = 'fe5ea7daf626de800f6271997a30e0e687a55cd7';

  /// Where to fetch `category/id`, in order of preference.
  @visibleForTesting
  static List<Uri> sourcesFor(String category, int id) => [
        Uri.parse('$_releaseBase/$id.json.gz'),
        Uri.parse('https://raw.githubusercontent.com/issmalahad-creator/TalibAlIlmApp/$_pinnedCommit/assets/quran/corpus/$category/$id.json.gz'),
        Uri.parse('https://cdn.jsdelivr.net/gh/issmalahad-creator/TalibAlIlmApp@$_pinnedCommit/assets/quran/corpus/$category/$id.json.gz'),
      ];

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

  final Map<String, Future<Uri?>> _asking = {};
  final Map<String, DateTime> _declined = {};
  static const _declineMemory = Duration(minutes: 2);

  /// `(available, bytes)` — only a definite 404/410 (e.g. an edition
  /// excluded from the release for licensing) means "unavailable". A slow or
  /// failed probe (weak network) is NOT proof the book is missing, so the
  /// user is still asked, just without a size.
  ///
  /// A 1-byte ranged GET, not a HEAD: GitHub redirects release assets to a
  /// signed storage URL that answers HEAD with 401, so a HEAD never showed
  /// the size. The total comes from `Content-Range: bytes 0-0/<total>`.
  Future<(bool, int?)> _probe(Uri uri) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', uri)..headers['Range'] = 'bytes=0-0';
      final r = await client.send(req).timeout(const Duration(seconds: 6));
      if (r.statusCode == 404 || r.statusCode == 410) return (false, null);
      final range = r.headers['content-range'];
      final total = range != null
          ? int.tryParse(range.split('/').last)
          : (r.statusCode == 200 ? int.tryParse(r.headers['content-length'] ?? '') : null);
      return (true, total);
    } catch (_) {
      return (true, null);
    } finally {
      client.close();
    }
  }

  /// The first source that has the book, once the user agreed — or null
  /// (declined, or no source has it). Without a confirm callback (tests)
  /// the first source is used unprobed.
  Future<Uri?> _approved(String category, int id, List<Uri> sources) {
    final ask = confirmDownload;
    if (ask == null) return Future.value(sources.first);
    final k = _key(category, id);
    final d = _declined[k];
    if (d != null && DateTime.now().difference(d) < _declineMemory) {
      return Future.value(null);
    }
    return _asking.putIfAbsent(k, () async {
      try {
        for (final uri in sources) {
          final (available, bytes) = await _probe(uri);
          if (!available) continue;
          final ok = await ask(category, id, bytes);
          if (!ok) _declined[k] = DateTime.now();
          return ok ? uri : null;
        }
        return null;
      } finally {
        _asking.remove(k);
      }
    });
  }

  Set<String>? _bundledAssets;

  /// True when `category/id` isn't in this build (lite strips it) and isn't
  /// cached yet — i.e. reading it needs a one-time download. Lets a panel
  /// say «not downloaded yet» instead of the misleading «no data».
  Future<bool> needsDownload(String category, int id) async {
    try {
      _bundledAssets ??= (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();
      if (_bundledAssets!.contains('assets/quran/corpus/$category/$id.json.gz')) return false;
      return !await (await _fileFor(category, id)).exists();
    } catch (_) {
      return false;
    }
  }

  /// An explicit «حمّل الآن» tap: forget an earlier «not now» so the
  /// sheet is shown again right away (the decline memory only exists to
  /// stop a panel re-asking on every rebuild).
  void forgetDecline(String category, int id) => _declined.remove(_key(category, id));

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
    final sources = sourcesFor(category, id);
    final chosen = await _approved(category, id, sources);
    if (chosen == null) return null;
    // The approved source first, then the others: a source that answered
    // the probe can still fail mid-download on a weak network.
    for (final uri in [chosen, ...sources.where((u) => u != chosen)]) {
      final bytes = await _fetch(uri, notifier);
      if (bytes == null) continue;
      // Cached forever, so only a complete, real gzip file is ever kept —
      // write to .part and rename, never leave a half file under the name.
      final part = File('${file.path}.part');
      await part.writeAsBytes(bytes, flush: true);
      await part.rename(file.path);
      return bytes;
    }
    return null;
  }

  /// One GET; null on any failure, a stall (60 s without bytes), a short
  /// body, or bytes that aren't gzip.
  Future<List<int>?> _fetch(Uri uri, ValueNotifier<(int, int?)?> notifier) async {
    final client = http.Client();
    try {
      final streamed = await client.send(http.Request('GET', uri)).timeout(const Duration(seconds: 60));
      if (streamed.statusCode != 200) return null;
      final total = streamed.contentLength;
      final builder = BytesBuilder(copy: false);
      var received = 0;
      notifier.value = (0, total);
      await for (final chunk in streamed.stream.timeout(const Duration(seconds: 60))) {
        builder.add(chunk);
        received += chunk.length;
        notifier.value = (received, total);
      }
      final bytes = builder.takeBytes();
      if (total != null && bytes.length != total) return null;
      if (bytes.length < 2 || bytes[0] != 0x1f || bytes[1] != 0x8b) return null;
      return bytes;
    } catch (_) {
      return null;
    } finally {
      notifier.value = null;
      client.close();
    }
  }
}
