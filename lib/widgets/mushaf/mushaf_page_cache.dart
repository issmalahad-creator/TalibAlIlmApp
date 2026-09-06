import 'dart:convert' show utf8;
import 'dart:io' show gzip;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart' show compute, debugPrint, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../../services/mushaf/tajweed_svg.dart';

/// Phase 80 / M4 — the one place MushafDatabase page SVGs are decoded and kept.
///
/// * **Decode off the UI isolate.** `gunzip + utf8.decode` of a ~150–800 KB
///   page runs in a background isolate (`compute`), so a page turn never
///   janks the raster thread.
/// * **Preload ±1.** When a page is shown, its neighbours are decoded ahead
///   of time — a forward/back turn is then instant.
/// * **Bounded LRU.** At most [_cap] decoded pages are held; the
///   least‑recently‑used is dropped.
/// * **Tajwīd variant (Phase G-t v2).** When «وضع التجويد» is on, the plain
///   SVG string is transformed — `fill` injected on the exact glyph
///   `<path>`s of each rule (`paintTajweedIntoSvg`) — in the same `compute`
///   isolate, and cached separately keyed by `(page, night)`. The path→hue
///   map comes from [tajweedPaintResolver], set by the reader (keeps this
///   cache free of a repository import).
///
/// Value per page: the decoded `<svg …>` string, or `null` (no bundled art /
/// decode failed — the widget then uses its text fallback).
class MushafPageCache {
  MushafPageCache._();
  static final MushafPageCache instance = MushafPageCache._();

  static const int _cap = 7;
  static const int _paintedCap = 4;

  final Map<int, String?> _entries = {};
  final List<int> _lru = [];
  final Map<int, Future<String?>> _inflight = {};

  final Map<String, String?> _painted = {}; // "$page|$night" -> painted svg
  final List<String> _paintedLru = [];
  final Map<String, Future<String?>> _paintedInflight = {};

  /// Set by the reader: resolves the tajwīd colouring for a page. Null
  /// (tests / before wiring) → the tajwīd variant is just the plain SVG.
  Future<TajweedGlyphPaint> Function(int page)? tajweedPaintResolver;

  bool has(int page) => _entries.containsKey(page);

  String? peek(int page) {
    if (!_entries.containsKey(page)) return null;
    _touch(page);
    return _entries[page];
  }

  /// Decode [page] (or return the resident value). With `tajweed`, returns
  /// the glyph‑coloured variant with [baseInkHex] baked into
  /// `<g id="md-page">` (the reader derives it from its night `artInk`, so
  /// day/night keep separate cache entries).
  Future<String?> load(int page,
      {bool tajweed = false, String baseInkHex = '#000000'}) {
    if (!tajweed) return _loadPlain(page);
    final key = '$page|$baseInkHex';
    final cached = _painted[key];
    if (cached != null || _painted.containsKey(key)) {
      _touchPainted(key);
      return Future<String?>.value(cached);
    }
    return _paintedInflight.putIfAbsent(key, () async {
      final plain = await _loadPlain(page);
      String? painted;
      if (plain != null) {
        try {
          final paint = await tajweedPaintResolver?.call(page) ??
              TajweedGlyphPaint.empty;
          painted = paint.isEmpty
              ? plain
              : await compute(
                  _paintIsolate,
                  _PaintArgs(
                      plain, paint.directFills, paint.bands, baseInkHex));
        } catch (e) {
          debugPrint('MushafPageCache: tajwīd paint for $page failed ($e).');
          painted = plain;
        }
      }
      _painted[key] = painted;
      _touchPainted(key);
      _evictPainted();
      _paintedInflight.remove(key);
      return painted;
    });
  }

  Future<String?> _loadPlain(int page) {
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

  void preloadAround(int page, {int radius = 1}) {
    for (var d = -radius; d <= radius; d++) {
      final p = page + d;
      if (p < 1 || p > 604) continue;
      if (_entries.containsKey(p) || _inflight.containsKey(p)) continue;
      _loadPlain(p);
    }
  }

  /// Drop the cached tajwīd variants (e.g. after the palette or the mode
  /// changes). The plain decodes are kept.
  void invalidateTajweed() {
    _painted.clear();
    _paintedLru.clear();
    _paintedInflight.clear();
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

  void _touchPainted(String key) {
    _paintedLru
      ..remove(key)
      ..add(key);
  }

  void _evictPainted() {
    while (_paintedLru.length > _paintedCap) {
      _painted.remove(_paintedLru.removeAt(0));
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
    invalidateTajweed();
  }
}

/// Top‑level so it can run in a `compute` isolate.
String _gunzipUtf8(Uint8List bytes) =>
    utf8.decode(gzip.decode(bytes), allowMalformed: true);

class _PaintArgs {
  final String svg;
  final Map<String, String> directFills;
  final List<TajweedBand> bands;
  final String baseInkHex;
  const _PaintArgs(this.svg, this.directFills, this.bands, this.baseInkHex);
}

String _paintIsolate(_PaintArgs a) => paintTajweedIntoSvg(a.svg,
    directFills: a.directFills, bands: a.bands, baseInkHex: a.baseInkHex);
