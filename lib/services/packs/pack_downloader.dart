import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'pack_state.dart';

/// Outcome of one file download.
sealed class DownloadResult {
  const DownloadResult();
}

class DownloadOk extends DownloadResult {
  const DownloadOk(this.file);
  final File file;
}

class DownloadFailed extends DownloadResult {
  const DownloadFailed(this.reason);
  final PackFailure reason;
}

/// Downloads one pack file the way large apps do (CONTENT_PACKS_ARCHITECTURE.md
/// §3.4): streams to `<target>.part` (never held whole in memory), resumes an
/// existing `.part` with `Range`, checks SHA-256 against the manifest, and
/// only then renames atomically to [target] — a half or corrupt file is
/// never readable under the final name. Never throws.
class PackDownloader {
  PackDownloader({http.Client Function()? clientFactory}) : _clientFactory = clientFactory ?? http.Client.new;

  final http.Client Function() _clientFactory;

  /// Slow links (GitHub's CDN through a weak network can take tens of
  /// seconds to answer) — patience, not failure. Retries live in the engine.
  static const connectTimeout = Duration(seconds: 60);
  static const idleTimeout = Duration(seconds: 60);

  /// Called with `(receivedTotal, expectedTotal)` as bytes arrive.
  Future<DownloadResult> download({
    required Uri uri,
    required File target,
    required int expectedBytes,
    required String expectedSha256,
    void Function(int received, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final part = File('${target.path}.part');
    final client = _clientFactory();
    try {
      await part.parent.create(recursive: true);
      var have = await part.exists() ? await part.length() : 0;
      if (have > expectedBytes) {
        await part.delete();
        have = 0;
      }

      if (have < expectedBytes) {
        final req = http.Request('GET', uri);
        if (have > 0) req.headers['Range'] = 'bytes=$have-';
        final res = await client.send(req).timeout(connectTimeout);
        if (res.statusCode == 404 || res.statusCode == 410) return const DownloadFailed(PackFailure.notFound);
        if (res.statusCode == 200 && have > 0) {
          // Server ignored the range — start over rather than append.
          have = 0;
        } else if (res.statusCode != 200 && res.statusCode != 206) {
          return const DownloadFailed(PackFailure.server);
        }
        final sink = part.openWrite(mode: have > 0 ? FileMode.append : FileMode.write);
        var received = have;
        var cancelled = false;
        onProgress?.call(received, expectedBytes);
        try {
          await for (final chunk in res.stream.timeout(idleTimeout)) {
            if (isCancelled?.call() ?? false) {
              cancelled = true;
              break;
            }
            sink.add(chunk);
            received += chunk.length;
            onProgress?.call(received, expectedBytes);
          }
        } finally {
          await sink.close(); // flushes; the .part is kept for a resume
        }
        if (cancelled) return const DownloadFailed(PackFailure.cancelled);
      }

      if (await part.length() != expectedBytes || !await _matches(part, expectedSha256)) {
        await part.delete();
        return const DownloadFailed(PackFailure.checksum);
      }
      if (await target.exists()) await target.delete();
      await part.rename(target.path);
      return DownloadOk(target);
    } on SocketException {
      return const DownloadFailed(PackFailure.offline);
    } on TimeoutException {
      return const DownloadFailed(PackFailure.offline);
    } on http.ClientException {
      return const DownloadFailed(PackFailure.offline);
    } on FileSystemException catch (e) {
      // ENOSPC (28) — the phone is full. The .part stays for a later resume.
      final noSpace = e.osError?.errorCode == 28 || (e.osError?.message.contains('No space') ?? false);
      return DownloadFailed(noSpace ? PackFailure.noSpace : PackFailure.server);
    } catch (_) {
      return const DownloadFailed(PackFailure.server);
    } finally {
      client.close();
    }
  }

  /// Streams the file through SHA-256 — constant memory for any size.
  static Future<bool> _matches(File f, String expected) async {
    final digest = await sha256.bind(f.openRead()).first;
    return digest.toString() == expected.toLowerCase();
  }
}
