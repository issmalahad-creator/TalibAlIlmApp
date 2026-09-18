import 'dart:convert' show jsonDecode, utf8;
import 'dart:io' show gzip;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart'
    show compute, debugPrint, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../services/quran_corpus_download_service.dart';

/// Phase 80 / QC2 — on-demand loader for the **bulky per-book Quran text**:
/// the 122 bundled tafsīrs, 138 translations, 12 riwāyāt under
/// `assets/quran/corpus/{tafsir,translations,riwaya}/<id>.json.gz`.
///
/// These are far too large to seed into SQLite (≈ 340 MB). Instead a book is
/// decoded once, off the UI isolate, into an ayah-indexed map and held in a
/// small LRU — a reader stays on one book at a time. The ~27 Supabase-mirror
/// tafsīrs are not on disk; [tafsirEntry] returns a `mirror` marker for them
/// (the Supabase fetch is QC6).
enum QuranBookKind { tafsir, translation, riwaya }

class _Book {
  /// `(surah*1000+ayah) -> row map`  (rows use compact keys: h / t / m).
  final Map<int, Map<String, dynamic>> byAyah;
  const _Book(this.byAyah);
}

class QuranBookCache {
  QuranBookCache._();
  static final QuranBookCache instance = QuranBookCache._();

  static const int _cap = 4;
  final Map<String, _Book?> _books = {};
  final List<String> _lru = [];
  final Map<String, Future<_Book?>> _inflight = {};

  static String _dir(QuranBookKind k) => switch (k) {
        QuranBookKind.tafsir => 'tafsir',
        QuranBookKind.translation => 'translations',
        QuranBookKind.riwaya => 'riwaya',
      };

  static int _k(int surah, int ayah) => surah * 1000 + ayah;

  Future<Map<String, dynamic>?> _row(
      QuranBookKind kind, int id, int surah, int ayah) async {
    final key = '${_dir(kind)}/$id';
    _Book? book;
    if (_books.containsKey(key)) {
      book = _books[key];
      _touch(key);
    } else {
      book = await _inflight.putIfAbsent(key, () async {
        final b = await _load(key);
        _books[key] = b;
        _touch(key);
        _evict();
        _inflight.remove(key);
        return b;
      });
    }
    return book?.byAyah[_k(surah, ayah)];
  }

  /// Tafsīr passage for `(bookId, surah, ayah)`:
  /// `{text}` if bundled, `{mirror: true}` if it's a Supabase-mirror book
  /// (its asset is absent), `null` if the book has nothing for that ayah.
  Future<Map<String, Object?>?> tafsirEntry(
      int bookId, int surah, int ayah) async {
    final row = await _row(QuranBookKind.tafsir, bookId, surah, ayah);
    if (row == null) {
      // distinguish "book not bundled" from "ayah not covered"
      return _books['tafsir/$bookId'] == null ? {'mirror': true} : null;
    }
    return {'text': row['h']};
  }

  /// Translation text for `(editionId, surah, ayah)`, or null.
  Future<String?> translation(int editionId, int surah, int ayah) async =>
      (await _row(QuranBookKind.translation, editionId, surah, ayah))?['t']
          as String?;

  /// Riwāya text + verse marker for `(riwayaId, surah, ayah)`, or null.
  Future<Map<String, Object?>?> riwayaText(
      int riwayaId, int surah, int ayah) async {
    final row = await _row(QuranBookKind.riwaya, riwayaId, surah, ayah);
    return row == null ? null : {'text': row['t'], 'marker': row['m']};
  }

  Future<_Book?> _load(String key) async {
    Uint8List? bytes;
    try {
      final data = await rootBundle.load('assets/quran/corpus/$key.json.gz');
      bytes = data.buffer.asUint8List();
    } catch (e) {
      debugPrint('QuranBookCache: no bundled asset for $key ($e) — trying download.');
      final parts = key.split('/');
      final category = parts[0];
      final id = int.tryParse(parts[1]);
      if (id != null) {
        final downloaded =
            await QuranCorpusDownloadService.instance.ensureCached(category, id);
        if (downloaded != null) bytes = Uint8List.fromList(downloaded);
      }
    }
    if (bytes == null) return null;
    final map = await compute(_decode, bytes);
    return map == null ? null : _Book(map);
  }

  void _touch(String key) {
    _lru
      ..remove(key)
      ..add(key);
  }

  void _evict() {
    while (_lru.length > _cap) {
      _books.remove(_lru.removeAt(0));
    }
  }

  @visibleForTesting
  int get residentCount => _books.length;

  @visibleForTesting
  void clear() {
    _books.clear();
    _lru.clear();
    _inflight.clear();
  }
}

/// Top-level for `compute`: gunzip + parse → `(surah*1000+ayah) -> row`.
Map<int, Map<String, dynamic>>? _decode(Uint8List bytes) {
  final obj = jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
  final rows = (obj['rows'] as List?) ?? const [];
  final out = <int, Map<String, dynamic>>{};
  for (final r in rows) {
    final m = (r as Map).cast<String, dynamic>();
    final s = m['s'] as int?, a = m['a'] as int?;
    if (s == null || a == null) continue;
    out[s * 1000 + a] = m;
  }
  return out;
}
