import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

/// Phase 80 / QC2 — seeds the **Quran Corpus** (`quran_corpus_*`, migration
/// v54) from the bundled `assets/quran/corpus/` datasets built by
/// `tool/build_quran_corpus.py`.
///
/// Per dataset: compare the bundled `sha256` (from `corpus_manifest.json`)
/// against what's stored in `quran_corpus_meta`; if unchanged, skip. Else
/// bulk-insert inside one transaction and record the new sha. Every failure
/// is swallowed and reported — the reader never breaks because a corpus
/// dataset didn't seed.
///
/// Only the small, per-ayah-queried datasets are seeded here. Tafsīr /
/// translation / riwāya text is loaded on demand from its per-book gz asset
/// (`QuranBookCache`).
class QuranCorpusSync {
  static const _dir = 'assets/quran/corpus';
  static const _manifest = '$_dir/corpus_manifest.json';

  /// Datasets stored as `(surah, ayah) -> JSON` in a same-named table.
  static const _perAyahJson = <String, ({String table, String key})>{
    'align_qac': (table: 'quran_align', key: 'm'),
    'morphology': (table: 'quran_morphology', key: 'morphology'),
    'syntax': (table: 'quran_syntax', key: 'syntax'),
    'meanings': (table: 'quran_word_meaning', key: 'meanings'),
    'notes': (table: 'quran_note', key: 'notes'),
    'qiraat': (table: 'quran_qiraat', key: 'qiraat'),
    'similar': (table: 'quran_similar', key: 'similar'),
    'sayings': (table: 'quran_saying', key: 'sayings'),
    'tajweed': (table: 'quran_tajweed', key: 'spans'), // G-t1 — cpfair rule spans
  };

  /// Heavy datasets that are content packs (`corpus.<name>` on GitHub,
  /// CONTENT_PACKS_ARCHITECTURE.md CP4): the lite build doesn't bundle them,
  /// so boot sync skips them and `CorpusTableInstaller` seeds them from the
  /// downloaded file instead.
  static const _chunkRows = 500;

  static const packDatasets = {'sayings', 'notes', 'similar', 'irab_books', 'fatwas'};

  /// Tables each pack dataset fills — emptied again when the pack is removed.
  static const packTables = <String, List<String>>{
    'sayings': ['quran_saying'],
    'notes': ['quran_note'],
    'similar': ['quran_similar'],
    'irab_books': ['quran_irab_book', 'quran_irab_prose'],
    'fatwas': ['quran_fatwa'],
  };

  Future<void> sync() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final man = jsonDecode(await rootBundle.loadString(_manifest))
          as Map<String, dynamic>;
      final datasets = (man['datasets'] as Map).cast<String, dynamic>();
      for (final entry in datasets.entries) {
        final name = entry.key;
        final meta = entry.value as Map<String, dynamic>;
        final sha = meta['sha256'] as String? ?? '';
        final stored = await _meta(db, name);
        if (stored == sha && sha.isNotEmpty) continue;
        if (packDatasets.contains(name) && !await _bundled(name)) continue; // lite: a pack
        try {
          await _seedOne(db, name, meta);
        } catch (e) {
          debugPrint('QuranCorpusSync: "$name" skipped ($e).');
        }
      }
    } catch (e) {
      debugPrint('QuranCorpusSync: sync skipped ($e).');
    }
  }

  static String _path(String name) =>
      packDatasets.contains(name) ? '$_dir/packs/$name.json.gz' : '$_dir/$name.json.gz';

  Future<Map<String, dynamic>> _load(String name) async {
    final bytes = await rootBundle.load(_path(name));
    // Off the UI isolate — `sayings` alone is ~15 MB gzipped.
    return compute(_decodeGzJson, bytes.buffer.asUint8List());
  }

  static Set<String>? _assets;

  /// Whether this build ships `<name>.json.gz` (the full flavor). Reads the
  /// asset manifest, never the (up to 15 MB) file itself.
  static Future<bool> _bundled(String name) async {
    try {
      _assets ??= (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();
      return _assets!.contains(_path(name));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBundled(String name) => _bundled(name);

  /// Seeds a pack dataset from its downloaded `.json.gz` (CP4 installer).
  Future<void> seedFromFile(String name, List<int> gz) async {
    final db = await DatabaseHelper.instance.database;
    final man = jsonDecode(await rootBundle.loadString(_manifest)) as Map<String, dynamic>;
    final meta = ((man['datasets'] as Map)[name] as Map?)?.cast<String, dynamic>() ?? {'sha256': ''};
    await _seedOne(db, name, meta, preloaded: await compute(_decodeGzJson, gz));
  }

  /// Empties a pack dataset's tables and forgets it was seeded.
  Future<void> clearDataset(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final t in packTables[name] ?? const <String>[]) {
        await txn.delete(t);
      }
      await txn.delete('quran_corpus_meta', where: 'dataset = ?', whereArgs: [name]);
    });
  }

  Future<void> _seedOne(
      Database db, String name, Map<String, dynamic> meta, {Map<String, dynamic>? preloaded}) async {
    final obj = preloaded ?? await _load(name);
    final rows = (obj['rows'] as List?) ?? const [];
    final sha = meta['sha256'] as String? ?? '';

    if (_perAyahJson.containsKey(name)) {
      // ZW-5: per-ayah datasets (up to ~6,000 heavy rows) go in in chunks,
      // so reader/Home queries on the single connection aren't queued
      // behind one long transaction. The meta row below is the completion
      // marker: it's removed first and written last, so an interrupted seed
      // simply runs again on the next launch (the table is cleared first).
      final spec = _perAyahJson[name]!;
      await db.transaction((txn) async {
        await txn.delete('quran_corpus_meta', where: 'dataset = ?', whereArgs: [name]);
        await txn.delete(spec.table);
      });
      for (var i = 0; i < rows.length; i += _chunkRows) {
        final batch = db.batch();
        for (final r in rows.skip(i).take(_chunkRows)) {
          final m = r as Map<String, dynamic>;
          batch.insert(spec.table, {
            'surah': m['s'],
            'ayah': m['a'],
            'data': jsonEncode(m[spec.key]),
          });
        }
        await batch.commit(noResult: true);
      }
    }

    await db.transaction((txn) async {
      final batch = txn.batch();
      // Index datasets are small multi-table sets — kept atomic.
      if (!_perAyahJson.containsKey(name)) await _seedIndex(txn, batch, name, rows);
      await batch.commit(noResult: true);
      await txn.insert(
        'quran_corpus_meta',
        {
          'dataset': name,
          'source': meta['source'],
          'source_version': meta['source_version'],
          'sha256': sha,
          'licence': meta['licence'],
          'rows': meta['rows'],
          'seeded_at_ms': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    debugPrint('QuranCorpusSync: seeded "$name" (${rows.length}).');
  }

  Future<void> _seedIndex(
      Transaction txn, Batch batch, String name, List rows) async {
    // Index datasets wrap a single object: rows = [ { <coll>: [...] } ].
    final inner = rows.isEmpty ? const <String, dynamic>{} : rows.first as Map;

    switch (name) {
      case 'nasekh':
        await txn.delete('quran_nasekh');
        for (final r in (inner['entries'] as List? ?? const [])) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_nasekh', {
            'surah': m['s'],
            'ayah': m['a'],
            'data': jsonEncode({'html': m['html']}),
          });
        }
      case 'irab_books':
        await txn.delete('quran_irab_book');
        await txn.delete('quran_irab_prose');
        for (final b in (inner['books'] as List? ?? const [])) {
          final m = b as Map<String, dynamic>;
          batch.insert('quran_irab_book', {
            'id': m['id'], 'name': m['name'], 'short': m['short'],
            'author': m['author'], 'year': m['year']?.toString(),
          });
        }
        for (final e in (inner['entries'] as List? ?? const [])) {
          final m = e as Map<String, dynamic>;
          batch.insert('quran_irab_prose', {
            'book_id': m['b'], 'surah': m['s'], 'ayah': m['a'], 'html': m['html'],
          });
        }
      case 'asbab_books':
        await txn.delete('quran_asbab_book');
        await txn.delete('quran_asbab');
        for (final b in (inner['books'] as List? ?? const [])) {
          final m = b as Map<String, dynamic>;
          batch.insert('quran_asbab_book', {
            'id': m['id'], 'name': m['name'], 'short': m['short'],
            'author': m['author'], 'year': m['year']?.toString(),
          });
        }
        for (final e in (inner['entries'] as List? ?? const [])) {
          final m = e as Map<String, dynamic>;
          batch.insert('quran_asbab', {
            'book_id': m['b'], 'surah': m['s'], 'ayah': m['a'], 'html': m['html'],
          });
        }
      case 'topics':
        await txn.delete('quran_topic');
        await txn.delete('quran_topic_ayah');
        for (final t in (inner['topics'] as List? ?? const [])) {
          final m = t as Map<String, dynamic>;
          batch.insert('quran_topic',
              {'id': m['id'], 'name': m['name'], 'parent_id': m['parent']});
        }
        for (final l in (inner['links'] as List? ?? const [])) {
          final m = l as Map<String, dynamic>;
          batch.insert('quran_topic_ayah', {
            'topic_id': m['t'], 'surah': m['s'],
            'ayah_from': m['a1'], 'ayah_to': m['a2'],
          });
        }
      case 'tafsir_index':
        await txn.delete('quran_tafsir_book');
        for (final b in (inner['books'] as List? ?? const [])) {
          final m = b as Map<String, dynamic>;
          batch.insert('quran_tafsir_book', {
            'id': m['id'], 'name': m['name'], 'short': m['short'],
            'author': m['author'], 'year': m['year']?.toString(),
            'nasher': m['nasher'],
            'bundled': (m['bundled'] == true) ? 1 : 0, 'ayat': m['ayat'],
          });
        }
      case 'translations_index':
        await txn.delete('quran_translation_edition');
        for (final e in (inner['editions'] as List? ?? const [])) {
          final m = e as Map<String, dynamic>;
          batch.insert('quran_translation_edition', {
            'id': m['id'], 'name': m['name'], 'short': m['short'],
            'lang': m['lang'], 'locale': m['locale'], 'direction': m['dir'],
            'licence': 'author-ip', 'ayat': m['ayat'],
          });
        }
      case 'riwaya_index':
        await txn.delete('quran_riwaya');
        for (final r in (inner['riwayat'] as List? ?? const [])) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_riwaya', {
            'id': m['id'], 'name': m['name'], 'rawi': m['rawi'],
            'is_primary': (m['primary'] == true) ? 1 : 0, 'ayat': m['ayat'],
          });
        }
      case 'reciters':
        await txn.delete('quran_reciter');
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_reciter', {
            'id': m['id'], 'name_ar': m['name_ar'], 'name_en': m['name_en'],
            'riwaya_ar': m['riwaya_ar'], 'audio_base': m['audio_base'],
          });
        }
      case 'book_catalog':
        await txn.delete('quran_book');
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_book', {
            'id': m['id'], 'type': m['type'], 'name': m['name'],
            'short': m['short'], 'author': m['author'],
            'year': m['year']?.toString(), 'lang': m['lang'],
          });
        }
      case 'surah_info':
        await txn.delete('quran_surah_info');
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_surah_info',
              {'surah': m['s'], 'intro_html': m['intro_html']});
        }
      case 'fatwas':
        await txn.delete('quran_fatwa');
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_fatwa', {
            'id': m['id'], 'title': m['title'], 'question': m['q'],
            'answer': m['a'], 'ref': m['ref']?.toString(),
          });
        }
      default:
        throw StateError('no seeder for corpus dataset "$name"');
    }
  }

  Future<String?> _meta(DatabaseExecutor db, String dataset) async {
    final rows = await db.query('quran_corpus_meta',
        columns: ['sha256'], where: 'dataset = ?', whereArgs: [dataset], limit: 1);
    return rows.isEmpty ? null : rows.first['sha256'] as String?;
  }
}

Map<String, dynamic> _decodeGzJson(List<int> gz) =>
    jsonDecode(utf8.decode(gzip.decode(gz))) as Map<String, dynamic>;
