import 'dart:convert' show utf8, jsonDecode;
import 'dart:io' show gzip;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart'
    show compute, debugPrint, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../../models/akhlaq.dart';

/// AKHLAQ — the read-only content layer, one instance shared by every
/// virtue slice (`al-rifq`, `iyadat-almarid`, …).
///
/// Each slice ships as one small gzipped asset and is parsed **once per
/// slice** in a background isolate, then cached. User state (attempts,
/// spaced-repetition, progress) lives in SQLite v61 — see
/// `AkhlaqRepository`, which takes a `sliceId` and stays agnostic to how
/// many slices exist. Subskill slugs are namespaced per virtue
/// (`rifq_*`, `iy_*`, …) so they never collide across slices sharing the
/// same `akhlaq_attempt`/`akhlaq_sr_state` tables.
///
/// > Deviation from `AKHLAQ_ARCHITECTURE §7` (which seeds content into
/// > SQLite via `AkhlaqSync`): for a handful of small slices, an
/// > in-memory parse is simpler and preserves the intent (offline-first,
/// > no runtime network, bundled seed). Move to SQLite + FTS when there
/// > are many virtues / search is built.
class AkhlaqContent {
  AkhlaqContent._();
  static final AkhlaqContent instance = AkhlaqContent._();

  /// slice id → bundled asset path. Add one entry per vertical slice.
  static const Map<String, String> assets = {
    'al-rifq': 'assets/akhlaq/ar-rifq.json.gz',
    'iyadat-almarid': 'assets/akhlaq/ar-iyadah.json.gz',
  };
  static const defaultSliceId = 'al-rifq';
  static const arSource = 'ar-source';

  final Map<String, AkhlaqSlice> _slices = {};
  final Map<String, Future<AkhlaqSlice?>> _inflight = {};

  bool isLoaded([String sliceId = defaultSliceId]) =>
      _slices.containsKey(sliceId);
  AkhlaqSlice? sliceOrNull([String sliceId = defaultSliceId]) =>
      _slices[sliceId];

  /// Load + parse [sliceId] (idempotent, cached). Safe to call from many
  /// places. Returns null for an unknown id or a load failure — never
  /// throws, never fabricates content.
  Future<AkhlaqSlice?> load({String sliceId = defaultSliceId}) {
    final cached = _slices[sliceId];
    if (cached != null) return Future.value(cached);
    final asset = assets[sliceId];
    if (asset == null) return Future.value(null);
    return _inflight[sliceId] ??= () async {
      try {
        final data = await rootBundle.load(asset);
        _slices[sliceId] = await compute(_parse, data.buffer.asUint8List());
      } catch (e) {
        debugPrint('AkhlaqContent: failed to load $asset ($e).');
      }
      _inflight.remove(sliceId);
      return _slices[sliceId];
    }();
  }

  // ── translations ────────────────────────────────────────────────────

  /// The best translation of one layer of one unit for [lang], or null.
  /// Never fabricates: a missing/`pending`/blank row → null, and the UI
  /// then shows the Arabic original only.
  AkhlaqTranslation? translation({
    required String refKind,
    required String refId,
    required String layer,
    required String lang,
    String sliceId = defaultSliceId,
  }) {
    final s = _slices[sliceId];
    if (s == null || lang == arSource) return null;
    for (final t in s.translations) {
      if (t.refKind == refKind &&
          t.refId == refId &&
          t.layer == layer &&
          t.lang == lang) {
        return t.isShowable ? t : null;
      }
    }
    return null;
  }

  /// Languages that actually have at least one showable translation.
  Set<String> availableLanguages([String sliceId = defaultSliceId]) {
    final s = _slices[sliceId];
    if (s == null) return const {};
    return {
      for (final t in s.translations)
        if (t.isShowable) t.lang,
    };
  }

  static AkhlaqSlice _parse(Uint8List gz) {
    final json = jsonDecode(utf8.decode(gzip.decode(gz), allowMalformed: true))
        as Map<String, dynamic>;
    return AkhlaqSlice.fromJson(json);
  }

  /// Parse a raw (un-gzipped) JSON string — used by the seed builder /
  /// asset tests that read a slice's `.json` directly.
  static AkhlaqSlice parseJsonString(String s) =>
      AkhlaqSlice.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @visibleForTesting
  void debugSetSlice(AkhlaqSlice? s, [String sliceId = defaultSliceId]) {
    if (s == null) {
      _slices.remove(sliceId);
    } else {
      _slices[sliceId] = s;
    }
    _inflight.remove(sliceId);
  }
}
