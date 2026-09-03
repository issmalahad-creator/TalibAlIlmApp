import 'dart:convert' show utf8;
import 'dart:io' show gzip;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart' show compute, debugPrint, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

/// Phase 80 / M4 — the one place MushafDatabase page SVGs are decoded and kept.
///
/// * **Decode off the UI isolate.** `gunzip + utf8.decode` of a ~150–800 KB
///   page runs in a background isolate (`compute`), so a page turn never
///   janks the raster thread.
/// * **Preload ±1.** When a page is shown, its neighbours are decoded ahead
///   of time — a forward/back turn is then instant.
/// * **Bounded LRU.** At most [_cap] decoded pages are held; the
///   least‑recently‑used is dropped. A long reading session stays flat in
///   memory instead of accumulating every visited page.
///
/// Value per page: the decoded `<svg …>` string, or `null` (no bundled art /
/// decode failed — the widget then uses its text fallback).
class MushafPageCache {
  MushafPageCache._();
  static final MushafPageCache instance = MushafPageCache._();

  /// How many decoded pages to keep. Current + a couple each side + slack.
  static const int _cap = 7;

  final Map<int, String?> _entries = {};
  final List<int> _lru = []; // least‑recent first, most‑recent last
  final Map<int, Future<String?>> _inflight = {};

  bool has(int page) => _entries.containsKey(page);

  /// The decoded SVG if already resident (does not trigger a load). Marks it
  /// most‑recently‑used.
  String? peek(int page) {
    if (!_entries.containsKey(page)) return null;
    _touch(page);
    return _entries[page];
  }

  /// Decode [page] (or return the resident value). Concurrent calls for the
  /// same page share one decode.
  Future<String?> load(int page) {
    if (_entries.containsKey(page)) {
      _touch(page);
      return Future<String?>.value(_entries[page]);
    }
    return _inflight.putIfAbsent(page, () async {
      final svg = await _decode(page);
      _entries[page] = svg;
      _touch(page);
      _evict();
      _inflight.remove(page);
      return svg;
    });
  }

  /// Fire‑and‑forget decode of the pages within [radius] of [page]. Skips
  /// pages already resident or already decoding.
  void preloadAround(int page, {int radius = 1}) {
    for (var d = -radius; d <= radius; d++) {
      final p = page + d;
      if (p < 1 || p > 604) continue;
      if (_entries.containsKey(p) || _inflight.containsKey(p)) continue;
      load(p); // ignore the future
    }
  }

  void _touch(int page) {
    _lru
      ..remove(page)
      ..add(page);
  }

  void _evict() {
    while (_lru.length > _cap) {
      _entries.remove(_lru.removeAt(0));
    }
  }

  static Future<String?> _decode(int page) async {
    if (page < 1 || page > 604) return null;
    try {
      final key =
          'assets/mushaf/pages_svg/${page.toString().padLeft(3, '0')}.svg.gz';
      final data = await rootBundle.load(key);
      final svg = await compute(_gunzipUtf8, data.buffer.asUint8List());
      return svg.contains('<svg') ? svg : null;
    } catch (e) {
      debugPrint('MushafPageCache: no art for page $page ($e) — text fallback.');
      return null;
    }
  }

  @visibleForTesting
  int get residentCount => _entries.length;

  @visibleForTesting
  List<int> get residentPages => List.unmodifiable(_lru);

  @visibleForTesting
  void clear() {
    _entries.clear();
    _lru.clear();
    _inflight.clear();
  }
}

/// Top‑level so it can run in a `compute` isolate.
String _gunzipUtf8(Uint8List bytes) =>
    utf8.decode(gzip.decode(bytes), allowMalformed: true);
