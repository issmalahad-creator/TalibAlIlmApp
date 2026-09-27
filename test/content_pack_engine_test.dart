import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_alilm_app/services/packs/content_pack_engine.dart';
import 'package:talib_alilm_app/services/packs/pack_downloader.dart';
import 'package:talib_alilm_app/services/packs/pack_manifest.dart';
import 'package:talib_alilm_app/services/packs/pack_state.dart';

/// CP1 (CONTENT_PACKS_ARCHITECTURE.md §3.4): resumable, verified, atomic.
List<int> _bytes(int n, [int seed = 7]) =>
    List<int>.generate(n, (i) => (i * 31 + seed) % 251);
String _sha(List<int> b) => sha256.convert(b).toString();

/// A tiny fake GitHub: serves [files] by name, honours `Range` unless
/// [ignoreRange], records every request.
class _FakeServer {
  _FakeServer(this.files, {this.ignoreRange = false, this.manifest});
  final Map<String, List<int>> files;
  final bool ignoreRange;
  final String? manifest;
  final requests = <http.BaseRequest>[];

  http.Client client() => MockClient.streaming(handle);

  Future<http.StreamedResponse> handle(
    http.BaseRequest req,
    Stream<List<int>> _,
  ) async {
    requests.add(req);
    final name = req.url.pathSegments.last;
    if (name == 'packs_manifest.json') {
      return manifest == null
          ? http.StreamedResponse(const Stream.empty(), 404)
          : http.StreamedResponse(Stream.value(utf8.encode(manifest!)), 200);
    }
    final body = files[name];
    if (body == null) return http.StreamedResponse(const Stream.empty(), 404);
    final range = req.headers['Range'];
    if (range != null && !ignoreRange) {
      final from = int.parse(range.substring(6, range.length - 1));
      final rest = body.sublist(from);
      return http.StreamedResponse(
        Stream.fromIterable([rest]),
        206,
        contentLength: rest.length,
      );
    }
    final chunks = [
      for (var i = 0; i < body.length; i += 1000)
        body.sublist(i, (i + 1000).clamp(0, body.length)),
    ];
    return http.StreamedResponse(
      Stream.fromIterable(chunks),
      200,
      contentLength: body.length,
    );
  }
}

class _FakeNet implements PackNetwork {
  bool online = true;
  bool wifi = true;
  final _ctl = StreamController<void>.broadcast();
  void change() => _ctl.add(null);
  @override
  Future<bool> isOnline() async => online;
  @override
  Future<bool> isOnWifi() async => wifi;
  @override
  Stream<void> get changes => _ctl.stream;
}

class _RecordingInstaller implements PackInstaller {
  final installed = <String>[];
  final removed = <String>[];
  bool bundled = false;
  @override
  Future<bool> isBundled(PackInfo pack) async => bundled;
  @override
  Future<void> install(PackInfo pack, List<File> files) async =>
      installed.add(pack.id);
  @override
  Future<void> uninstall(PackInfo pack) async => removed.add(pack.id);
}

void main() {
  late Directory tmp;
  setUp(() async {
    ContentPackEngine.retryDelays = const [Duration(milliseconds: 1)];
    tmp = await Directory.systemTemp.createTemp('packs_test');
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async => tmp.delete(recursive: true));

  group('PackDownloader', () {
    final data = _bytes(10000);

    test('downloads, verifies and renames atomically', () async {
      final server = _FakeServer({'a.bin': data});
      final target = File('${tmp.path}/a.bin');
      final r = await PackDownloader(clientFactory: server.client).download(
        uri: Uri.parse('https://x/a.bin'),
        target: target,
        expectedBytes: data.length,
        expectedSha256: _sha(data),
      );
      expect(r, isA<DownloadOk>());
      expect(await target.readAsBytes(), data);
      expect(File('${target.path}.part').existsSync(), isFalse);
    });

    test('resumes a .part with a Range request', () async {
      final server = _FakeServer({'a.bin': data});
      final target = File('${tmp.path}/a.bin');
      await File('${target.path}.part').writeAsBytes(data.sublist(0, 4000));
      final r = await PackDownloader(clientFactory: server.client).download(
        uri: Uri.parse('https://x/a.bin'),
        target: target,
        expectedBytes: data.length,
        expectedSha256: _sha(data),
      );
      expect(r, isA<DownloadOk>());
      expect(server.requests.single.headers['Range'], 'bytes=4000-');
      expect(await target.readAsBytes(), data);
    });

    test(
      'server ignoring Range → starts over instead of appending garbage',
      () async {
        final server = _FakeServer({'a.bin': data}, ignoreRange: true);
        final target = File('${tmp.path}/a.bin');
        await File('${target.path}.part').writeAsBytes(data.sublist(0, 4000));
        final r = await PackDownloader(clientFactory: server.client).download(
          uri: Uri.parse('https://x/a.bin'),
          target: target,
          expectedBytes: data.length,
          expectedSha256: _sha(data),
        );
        expect(r, isA<DownloadOk>());
        expect(await target.readAsBytes(), data);
      },
    );

    test(
      'corrupt file → checksum failure, nothing under the final name',
      () async {
        final server = _FakeServer({'a.bin': _bytes(10000, 99)});
        final target = File('${tmp.path}/a.bin');
        final r = await PackDownloader(clientFactory: server.client).download(
          uri: Uri.parse('https://x/a.bin'),
          target: target,
          expectedBytes: data.length,
          expectedSha256: _sha(data),
        );
        expect((r as DownloadFailed).reason, PackFailure.checksum);
        expect(target.existsSync(), isFalse);
        expect(File('${target.path}.part').existsSync(), isFalse);
      },
    );

    test('missing on the server → notFound', () async {
      final server = _FakeServer({});
      final r = await PackDownloader(clientFactory: server.client).download(
        uri: Uri.parse('https://x/a.bin'),
        target: File('${tmp.path}/a.bin'),
        expectedBytes: 1,
        expectedSha256: 'x',
      );
      expect((r as DownloadFailed).reason, PackFailure.notFound);
    });

    test('cancel keeps the .part for a later resume', () async {
      final server = _FakeServer({'a.bin': data});
      final target = File('${tmp.path}/a.bin');
      var seen = 0;
      final r = await PackDownloader(clientFactory: server.client).download(
        uri: Uri.parse('https://x/a.bin'),
        target: target,
        expectedBytes: data.length,
        expectedSha256: _sha(data),
        onProgress: (rec, _) => seen = rec,
        isCancelled: () => seen >= 3000,
      );
      expect((r as DownloadFailed).reason, PackFailure.cancelled);
      expect(File('${target.path}.part').lengthSync(), greaterThan(0));
      expect(target.existsSync(), isFalse);
    });
  });

  group('ContentPackEngine', () {
    final f1 = _bytes(5000, 1);
    final f2 = _bytes(3000, 2);
    String manifestJson() => jsonEncode({
      'schema': 1,
      'base': 'https://gh/packs-v1/',
      'packs': [
        {
          'id': 'corpus.sayings',
          'kind': 'corpus',
          'version': 1,
          'title': {'ar': 'أقوال السلف', 'en': 'Sayings'},
          'installer': 'test',
          'files': [
            {'name': 's1.v1.gz', 'bytes': f1.length, 'sha256': _sha(f1)},
            {'name': 's2.v1.gz', 'bytes': f2.length, 'sha256': _sha(f2)},
          ],
        },
      ],
    });

    ContentPackEngine engine(
      _FakeServer server,
      _FakeNet net,
      _RecordingInstaller inst,
    ) => ContentPackEngine(
      clientFactory: server.client,
      network: net,
      rootDir: () async => tmp,
      bundledManifest: () async => manifestJson(),
    )..registerInstaller('test', inst);

    test('download → installed; remove → frees and uninstalls', () async {
      final server = _FakeServer({
        's1.v1.gz': f1,
        's2.v1.gz': f2,
      }, manifest: manifestJson());
      final inst = _RecordingInstaller();
      final e = engine(server, _FakeNet(), inst);
      await e.download('corpus.sayings');
      await e.idle();
      final s = e.stateOf('corpus.sayings').value as PackInstalled;
      expect(s.bytesOnDisk, f1.length + f2.length);
      expect(inst.installed, ['corpus.sayings']);
      expect(await e.bytesUsed(), f1.length + f2.length);

      await e.remove('corpus.sayings');
      expect(e.stateOf('corpus.sayings').value, isA<PackNotInstalled>());
      expect(inst.removed, ['corpus.sayings']);
      expect(Directory('${tmp.path}/corpus.sayings').existsSync(), isFalse);
      expect(await e.bytesUsed(), 0);
    });

    test(
      'Wi-Fi only on mobile data waits, then runs when Wi-Fi returns',
      () async {
        final server = _FakeServer({
          's1.v1.gz': f1,
          's2.v1.gz': f2,
        }, manifest: manifestJson());
        final net = _FakeNet()..wifi = false;
        final inst = _RecordingInstaller();
        final e = engine(server, net, inst);
        await e.download('corpus.sayings', wifiOnly: true);
        await e.idle();
        expect(e.stateOf('corpus.sayings').value, isA<PackWaitingForWifi>());
        expect(inst.installed, isEmpty);

        net.wifi = true;
        net.change();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await e.idle();
        expect(e.stateOf('corpus.sayings').value, isA<PackInstalled>());
      },
    );

    test('offline → honest failed(offline) state, no crash', () async {
      final server = _FakeServer({}, manifest: manifestJson());
      final e = engine(
        server,
        _FakeNet()..online = false,
        _RecordingInstaller(),
      );
      await e.download('corpus.sayings');
      await e.idle();
      expect(
        (e.stateOf('corpus.sayings').value as PackFailed).reason,
        PackFailure.offline,
      );
    });

    test('bundled in this build → usable without any download', () async {
      final server = _FakeServer({}, manifest: manifestJson());
      final e = engine(
        server,
        _FakeNet(),
        _RecordingInstaller()..bundled = true,
      );
      expect(await e.isUsable('corpus.sayings'), isTrue);
      expect(server.requests, isEmpty);
    });

    test(
      'a bad file fails the pack with checksum and installs nothing',
      () async {
        final server = _FakeServer({
          's1.v1.gz': f1,
          's2.v1.gz': _bytes(3000, 50),
        }, manifest: manifestJson());
        final inst = _RecordingInstaller();
        final e = engine(server, _FakeNet(), inst);
        await e.download('corpus.sayings');
        await e.idle();
        expect(
          (e.stateOf('corpus.sayings').value as PackFailed).reason,
          PackFailure.checksum,
        );
        expect(inst.installed, isEmpty);
      },
    );

    test(
      'a flaky connection is retried and resumes instead of failing',
      () async {
        var calls = 0;
        final inner = _FakeServer({
          's1.v1.gz': f1,
          's2.v1.gz': f2,
        }, manifest: manifestJson());
        http.Client flaky() => MockClient.streaming((req, body) async {
          if (req.url.pathSegments.last == 's1.v1.gz' && calls++ == 0) {
            throw http.ClientException('connection reset');
          }
          return inner.handle(req, body);
        });

        final inst = _RecordingInstaller();
        final e = ContentPackEngine(
          clientFactory: flaky,
          network: _FakeNet(),
          rootDir: () async => tmp,
          bundledManifest: () async => manifestJson(),
        )..registerInstaller('test', inst);
        await e.download('corpus.sayings');
        await e.idle();
        expect(e.stateOf('corpus.sayings').value, isA<PackInstalled>());
        expect(calls, greaterThan(1));
      },
    );

    test('manifest with a newer schema is ignored, never misread', () {
      expect(
        PackManifest.tryParse({'schema': 99, 'base': 'x', 'packs': []}),
        isNull,
      );
    });
  });
}
