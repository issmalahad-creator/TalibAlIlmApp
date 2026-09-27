import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pack_downloader.dart';
import 'pack_manifest.dart';
import 'pack_state.dart';

/// Turns downloaded files into usable content (a cached file, seeded DB
/// rows…) and back. One per `PackInfo.installer`.
abstract class PackInstaller {
  /// True when this build already ships the pack (the full flavor).
  Future<bool> isBundled(PackInfo pack);
  Future<void> install(PackInfo pack, List<File> files);
  Future<void> uninstall(PackInfo pack);
}

/// Network facts the engine needs — injectable for tests.
abstract class PackNetwork {
  Future<bool> isOnline();
  Future<bool> isOnWifi();
  Stream<void> get changes;
}

class _ConnectivityNetwork implements PackNetwork {
  final _c = Connectivity();
  @override
  Future<bool> isOnline() async => (await _c.checkConnectivity()).any((r) => r != ConnectivityResult.none);
  @override
  Future<bool> isOnWifi() async {
    final r = await _c.checkConnectivity();
    return r.contains(ConnectivityResult.wifi) || r.contains(ConnectivityResult.ethernet);
  }

  @override
  Stream<void> get changes => _c.onConnectivityChanged.map((_) {});
}

/// The content-pack engine (CONTENT_PACKS_ARCHITECTURE.md §3). Features ask
/// [stateOf] / [isUsable]; the UI calls [download], [pause], [cancel],
/// [remove]. One download at a time; the queue survives an app restart and
/// resumes on Wi-Fi ([resumePending], a low-priority boot task).
class ContentPackEngine {
  ContentPackEngine({
    PackDownloader? downloader,
    PackNetwork? network,
    Future<Directory> Function()? rootDir,
    Future<String?> Function()? bundledManifest,
    http.Client Function()? clientFactory,
  })  : _downloader = downloader ?? PackDownloader(clientFactory: clientFactory),
        _network = network ?? _ConnectivityNetwork(),
        _rootDir = rootDir ?? _defaultRoot,
        _bundledManifest = bundledManifest ?? _loadBundledManifest,
        _clientFactory = clientFactory ?? http.Client.new;

  static final instance = ContentPackEngine();

  /// Live manifest location (GitHub Release `packs-v1`).
  static const manifestUrl =
      'https://github.com/issmalahad-creator/TalibAlIlmApp/releases/download/packs-v1/packs_manifest.json';

  final PackDownloader _downloader;
  final PackNetwork _network;
  final Future<Directory> Function() _rootDir;
  final Future<String?> Function() _bundledManifest;
  final http.Client Function() _clientFactory;

  final Map<String, PackInstaller> _installers = {};
  final Map<String, ValueNotifier<PackState>> _states = {};
  final List<_Job> _queue = [];
  final Set<String> _stop = {}; // ids asked to pause/cancel mid-download
  bool _running = false;
  PackManifest? _manifest;
  StreamSubscription<void>? _netSub;

  static const _installedKey = 'packs_installed'; // {id: {v, bytes}}
  static const _pendingKey = 'packs_pending'; // [{id, wifiOnly}]
  static const _etagKey = 'packs_manifest_etag';
  static const _cachedManifestKey = 'packs_manifest_cached';

  void registerInstaller(String name, PackInstaller installer) => _installers[name] = installer;

  // ---------------------------------------------------------------- manifest

  /// Newest manifest we have: remote (ETag-cached) → last cached → bundled.
  /// [refresh] hits the network; otherwise no network at all.
  Future<PackManifest?> manifest({bool refresh = false}) async {
    if (_manifest != null && !refresh) return _manifest;
    final prefs = await SharedPreferences.getInstance();
    if (refresh) {
      final fresh = await _fetchManifest(prefs);
      if (fresh != null) _manifest = fresh;
    }
    _manifest ??= _parse(prefs.getString(_cachedManifestKey)) ?? _parse(await _bundledManifest());
    return _manifest;
  }

  Future<PackManifest?> _fetchManifest(SharedPreferences prefs) async {
    final client = _clientFactory();
    try {
      final etag = prefs.getString(_etagKey);
      final res = await client
          .get(Uri.parse(manifestUrl), headers: {'If-None-Match': ?etag})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 304) return _parse(prefs.getString(_cachedManifestKey));
      if (res.statusCode != 200) return null;
      final m = _parse(res.body);
      if (m == null) return null;
      await prefs.setString(_cachedManifestKey, res.body);
      final newTag = res.headers['etag'];
      if (newTag != null) await prefs.setString(_etagKey, newTag);
      return m;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static PackManifest? _parse(String? raw) {
    if (raw == null) return null;
    try {
      return PackManifest.tryParse(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _loadBundledManifest() async {
    try {
      return await rootBundle.loadString('assets/packs/packs_manifest.json');
    } catch (_) {
      return null;
    }
  }

  static Future<Directory> _defaultRoot() async =>
      Directory('${(await getApplicationDocumentsDirectory()).path}/packs');

  // ------------------------------------------------------------------ state

  ValueNotifier<PackState> stateOf(String id) =>
      _states.putIfAbsent(id, () => ValueNotifier<PackState>(const PackNotInstalled()));

  /// Reads the real state from disk/prefs into [stateOf]. Cheap; call when a
  /// screen that shows packs opens.
  Future<PackState> refreshState(String id) async {
    final current = stateOf(id).value;
    if (current.isBusy || current is PackWaitingForWifi) return current;
    final m = await manifest();
    final pack = m?.byId(id);
    final installer = pack == null ? null : _installers[pack.installer];
    PackState s;
    if (pack != null && installer != null && await installer.isBundled(pack)) {
      s = const PackBundled();
    } else {
      final rec = (await _installed())[id];
      if (rec != null) {
        s = PackInstalled(
          version: rec.$1,
          bytesOnDisk: rec.$2,
          updateAvailable: pack != null && pack.version > rec.$1,
        );
      } else {
        final part = pack == null ? null : await _partialBytes(pack);
        s = part != null && part > 0 ? PackPaused(received: part, total: pack!.bytes) : const PackNotInstalled();
      }
    }
    stateOf(id).value = s;
    return s;
  }

  Future<bool> isUsable(String id) async => (await refreshState(id)).isUsable;

  Future<Map<String, (int, int)>> _installed() async {
    final raw = (await SharedPreferences.getInstance()).getString(_installedKey);
    if (raw == null) return {};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in m.entries) e.key: ((e.value as List)[0] as int, (e.value as List)[1] as int)};
  }

  Future<void> _setInstalled(String id, (int, int)? rec) async {
    final all = await _installed();
    if (rec == null) {
      all.remove(id);
    } else {
      all[id] = rec;
    }
    await (await SharedPreferences.getInstance())
        .setString(_installedKey, jsonEncode({for (final e in all.entries) e.key: [e.value.$1, e.value.$2]}));
  }

  Future<Directory> _packDir(String id) async => Directory('${(await _rootDir()).path}/$id');

  Future<int?> _partialBytes(PackInfo pack) async {
    final dir = await _packDir(pack.id);
    var sum = 0;
    for (final f in pack.files) {
      final done = File('${dir.path}/${f.name}');
      final part = File('${done.path}.part');
      if (await done.exists()) {
        sum += f.bytes;
      } else if (await part.exists()) {
        sum += await part.length();
      }
    }
    return sum;
  }

  /// Total bytes the installed packs occupy (for «التنزيلات والمساحة»).
  Future<int> bytesUsed() async => (await _installed()).values.fold<int>(0, (s, r) => s + r.$2);

  // ---------------------------------------------------------------- actions

  /// Queue [id]. [wifiOnly] → waits for Wi-Fi when on mobile data. The UI
  /// has already asked the student (size + network) before calling this.
  Future<void> download(String id, {bool wifiOnly = false, bool front = true}) async {
    if (stateOf(id).value.isBusy) return;
    _queue.removeWhere((j) => j.id == id);
    final job = _Job(id, wifiOnly);
    front ? _queue.insert(0, job) : _queue.add(job);
    stateOf(id).value = const PackQueued();
    await _savePending();
    _listenNetwork();
    unawaited(_pump());
  }

  /// Stop now, keep the `.part` for a later resume.
  Future<void> pause(String id) async {
    _queue.removeWhere((j) => j.id == id);
    if (stateOf(id).value is PackDownloading) {
      _stop.add(id);
    } else {
      await refreshState(id);
    }
    await _savePending();
  }

  /// Stop and throw away what was downloaded.
  Future<void> cancel(String id) async {
    await pause(id);
    final dir = await _packDir(id);
    final installed = (await _installed()).containsKey(id);
    if (installed) return; // an update was cancelled — the old version stays
    if (await dir.exists()) await dir.delete(recursive: true);
    stateOf(id).value = const PackNotInstalled();
  }

  /// Delete an installed pack and free its space.
  Future<void> remove(String id) async {
    final pack = (await manifest())?.byId(id);
    final installer = pack == null ? null : _installers[pack.installer];
    if (pack != null && installer != null) await installer.uninstall(pack);
    final dir = await _packDir(id);
    if (await dir.exists()) await dir.delete(recursive: true);
    await _setInstalled(id, null);
    stateOf(id).value = const PackNotInstalled();
  }

  /// Boot task (afterHome, low priority): resume what was queued last time,
  /// on Wi-Fi only.
  Future<void> resumePending() async {
    final raw = (await SharedPreferences.getInstance()).getStringList(_pendingKey) ?? const [];
    if (raw.isEmpty) return;
    for (final r in raw) {
      final job = _Job.decode(r);
      if (job != null && !_queue.any((j) => j.id == job.id)) {
        _queue.add(_Job(job.id, true)); // background resume never uses mobile data
        stateOf(job.id).value = const PackQueued();
      }
    }
    _listenNetwork();
    unawaited(_pump());
  }

  Future<void> _savePending() async => (await SharedPreferences.getInstance())
      .setStringList(_pendingKey, [for (final j in _queue) j.encode()]);

  void _listenNetwork() {
    _netSub ??= _network.changes.listen((_) => unawaited(_pump()));
  }

  // ----------------------------------------------------------------- worker

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    try {
      while (true) {
        final job = await _nextRunnable();
        if (job == null) break;
        _queue.remove(job);
        await _run(job);
        await _savePending();
      }
    } finally {
      _running = false;
    }
  }

  Future<_Job?> _nextRunnable() async {
    if (_queue.isEmpty) return null;
    if (!await _network.isOnline()) {
      for (final j in _queue) {
        stateOf(j.id).value = const PackFailed(PackFailure.offline);
      }
      return null; // network listener retries
    }
    final wifi = await _network.isOnWifi();
    for (final j in _queue) {
      if (!j.wifiOnly || wifi) return j;
      stateOf(j.id).value = const PackWaitingForWifi();
    }
    return null;
  }

  Future<void> _run(_Job job) async {
    final id = job.id;
    final state = stateOf(id);
    final m = await manifest(refresh: true);
    final pack = m?.byId(id);
    final installer = pack == null ? null : _installers[pack.installer];
    if (m == null || pack == null || installer == null) {
      state.value = const PackFailed(PackFailure.notFound);
      return;
    }
    final dir = await _packDir(id);
    final total = pack.bytes;
    var before = 0; // bytes of files already finished
    final files = <File>[];
    final sw = Stopwatch()..start();
    var lastBytes = 0;
    var lastMs = 0;
    double? speed;

    for (final f in pack.files) {
      final target = File('${dir.path}/${f.name}');
      if (await target.exists() && await target.length() == f.bytes) {
        files.add(target);
        before += f.bytes;
        continue;
      }
      final result = await _downloader.download(
        uri: Uri.parse('${m.base}${f.name}'),
        target: target,
        expectedBytes: f.bytes,
        expectedSha256: f.sha256,
        isCancelled: () => _stop.contains(id),
        onProgress: (received, _) {
          final now = before + received;
          final ms = sw.elapsedMilliseconds;
          if (ms - lastMs >= 500) {
            final instant = (now - lastBytes) * 1000 / (ms - lastMs);
            speed = speed == null ? instant : speed! * 0.7 + instant * 0.3; // smoothed
            lastBytes = now;
            lastMs = ms;
          }
          state.value = PackDownloading(received: now, total: total, bytesPerSecond: speed);
        },
      );
      switch (result) {
        case DownloadOk(:final file):
          files.add(file);
          before += f.bytes;
        case DownloadFailed(:final reason):
          if (reason == PackFailure.cancelled) {
            _stop.remove(id);
            state.value = PackPaused(received: await _partialBytes(pack) ?? 0, total: total);
          } else {
            state.value = PackFailed(reason);
          }
          return;
      }
    }

    // Every file was already SHA-256-checked by the downloader.
    state.value = const PackInstalling();
    try {
      await installer.install(pack, files);
    } catch (e) {
      debugPrint('ContentPackEngine: install $id failed: $e');
      state.value = const PackFailed(PackFailure.server);
      return;
    }
    await _setInstalled(id, (pack.version, total));
    state.value = PackInstalled(version: pack.version, bytesOnDisk: total);
  }

  @visibleForTesting
  Future<void> idle() async {
    while (_running) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }
}

class _Job {
  _Job(this.id, this.wifiOnly);
  final String id;
  final bool wifiOnly;

  String encode() => jsonEncode({'id': id, 'w': wifiOnly});
  static _Job? decode(String s) {
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return _Job(m['id'] as String, m['w'] as bool);
    } catch (_) {
      return null;
    }
  }
}
