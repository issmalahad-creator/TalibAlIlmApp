import 'dart:convert';
import 'dart:io';

/// Tiny local HTTP endpoint so n8n (running inside a Docker container that
/// can't see this Windows host's filesystem or Dart toolchain) can trigger
/// the actual `tool/fetch_quranenc_translations.dart` fetch on the host
/// itself, with a real exit code/output n8n can retry against.
///
/// 2026-08-18 — Ismail's request to wire n8n into the tafsir-fetch
/// reliability workflow discussed earlier. Not meant to be exposed beyond
/// localhost/the Docker bridge network; no auth, on purpose (matches the
/// "just make my own local automation work" scope, not a public service).
Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8765);
  stdout.writeln('fetch_runner_server listening on http://0.0.0.0:8765 (POST /run)');

  await for (final request in server) {
    if (request.method != 'POST' || request.uri.path != '/run') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      continue;
    }

    stdout.writeln('Received /run trigger — starting dart run tool/fetch_quranenc_translations.dart');
    final result = await Process.run(
      'dart',
      ['run', 'tool/fetch_quranenc_translations.dart'],
      workingDirectory: Directory.current.path,
      runInShell: true,
    );

    final success = result.exitCode == 0;
    stdout.writeln('Fetch finished — exitCode=${result.exitCode}');

    request.response
      ..statusCode = success ? HttpStatus.ok : HttpStatus.internalServerError
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'success': success,
        'exitCode': result.exitCode,
        'stdout': result.stdout.toString(),
        'stderr': result.stderr.toString(),
      }));
    await request.response.close();
  }
}
