import 'dart:convert' show utf8, jsonDecode;
import 'dart:io' show gzip;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart'
    show compute, debugPrint, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../../models/akhlaq.dart';

/// AKHLAQ — the read-only content layer for a virtue slice.
///
/// The content spec (`docs/akhlaq/alrifq/ar-rifq.json`) ships as one small
/// gzipped asset and is parsed **once** in a background isolate. User state
/// (attempts, spaced-repetition, progress) lives in SQLite v61 — see
/// `AkhlaqRepository`.
///
/// > Deviation from `AKHLAQ_ARCHITECTURE §7` (which seeds content into
/// > SQLite via `AkhlaqSync`): for a single ~85 KB slice, an in-memory
/// > parse is simpler and preserves the intent (offline-first, no runtime
/// > network, bundled seed). Move to SQLite + FTS when there are many
/// > virtues / search is built.
class AkhlaqContent {
  AkhlaqContent._();
  static final AkhlaqContent instance = AkhlaqContent._();

  static const _asset = 'assets/akhlaq/ar-rifq.json.gz';
  static const arSource = 'ar-source';

  AkhlaqSlice? _slice;
  Future<AkhlaqSlice?>? _inflight;

  bool get isLoaded => _slice != null;
  AkhlaqSlice? get sliceOrNull => _slice;

  /// Load + parse (idempotent). Safe to call from many places.
  Future<AkhlaqSlice?> load() {
    if (_slice != null) return Future.value(_slice);
    return _inflight ??= () async {
      try {
        final data = await rootBundle.load(_asset);
        _slice = await compute(_parse, data.buffer.asUint8List());
      } catch (e) {
        debugPrint('AkhlaqContent: failed to load $_asset ($e).');
        _slice = null;
      }
      _inflight = null;
      return _slice;
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
  }) {
    final s = _slice;
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
  Set<String> get availableLanguages {
    final s = _slice;
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
  /// asset tests that read `ar-rifq.json` directly.
  static AkhlaqSlice parseJsonString(String s) =>
      AkhlaqSlice.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @visibleForTesting
  void debugSetSlice(AkhlaqSlice? s) {
    _slice = s;
    _inflight = null;
  }
}
